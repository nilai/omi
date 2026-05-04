import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:memo_pin/audio/audio_picker_utils.dart';
import 'package:memo_pin/audio/record/audio_record.dart';
import 'package:memo_pin/audio/record/mp_audio_local_records_util.dart';
import 'package:memo_pin/audio/record/mp_audio_upload_service.dart';
import 'package:memo_pin/common/mp_home_notification.dart';
import 'package:memo_pin/common/mp_memory_notification.dart';
import 'package:memo_pin/http/api/mp_memory.dart';
import 'package:memo_pin/http/schema/mp_memory.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:path/path.dart' as p;

/// 单条文件上传进度（0–100，对应当前第 [batchIndex] 条）；由 **调用方页面** 更新进度条，不在本类内做 UI 模拟。
typedef MPAudioUploadPerFileProgress =
    void Function({required int batchIndex, required int batchTotal, required int progress});

void _emitUploadProgress(
  MPAudioUploadPerFileProgress? onPerFileProgress, {
  required int batchIndex,
  required int batchTotal,
  required int progress,
}) {
  final int p = progress.clamp(0, 100);
  onPerFileProgress?.call(batchIndex: batchIndex, batchTotal: batchTotal, progress: p);
  MPHomeNotification.notifyUploadProgress(
    MPHomeUploadProgressPayload(batchTotal: batchTotal, batchIndex: batchIndex, progress: p),
  );
}

/// 多文件上传进度：[totalFiles] 为当前队列中待处理条数 + 正在上传的 1 条；[currentFileIndex] 为本次 Worker 会话内从 1 开始的序号；[progress] 为当前文件 0–100。
typedef MPAudioUploadMultiProgress =
    void Function({required int totalFiles, required int currentFileIndex, required int progress});

/// 显式批量上传队列中的单条任务（每条可有独立的 [source] / [templateId] / [recordMemoAt]）。
class MPAudioUploadLocalItem {
  const MPAudioUploadLocalItem({
    required this.localFile,
    required this.durationSec,
    required this.createAt,
    required this.source,
    this.templateId,
    this.recordMemoAt = 0,
  });

  final File localFile;
  final int durationSec;

  /// 与 [MPAudioUploadManager.uploadLocalRecord] 的 [createAt] 一致（多为 Unix 秒或本地记录用的毫秒，上传前会结合索引解析）。
  final int createAt;
  final String source;
  final String? templateId;
  final int recordMemoAt;
}

class _MPBatchAwait {
  _MPBatchAwait({required this.remaining, required this.completer});

  int remaining;
  final Completer<MPCreateRecordResponse?> completer;
  MPCreateRecordResponse? lastCreated;
}

class _MPUploadWorkUnit {
  _MPUploadWorkUnit({
    required this.batchId,
    required this.item,
    required this.rightNowTranscribe,
    this.onMultiProgress,
  });

  final int batchId;
  final MPAudioUploadLocalItem item;
  final bool rightNowTranscribe;
  final MPAudioUploadMultiProgress? onMultiProgress;
}

/// 本地录音落盘后，先 [MPAudioUploadService.uploadMPAudio] 上传，再用返回的 **远端 URI** 调 [createRecord]。
///
/// 流程：
/// 1) [MPAudioLocalRecordsUtil.add] 写入当前文件索引
/// 2) 枚举本地存储目录下待上传录音（`omi_record_` 前缀），逐个：读时长 → 上传 → [createRecord]（`record_file` 为上传后的 URI）
/// 3) 若 [rightNowTranscribe] 为 true，每条成功后 [summaryRecord]
/// 4) 成功后删除对应本地文件并 [MPAudioLocalRecordsUtil.removeHard]
class MPAudioUploadManager {
  MPAudioUploadManager._();

  static final MPAudioUploadManager instance = MPAudioUploadManager._();

  final List<_MPUploadWorkUnit> _multiUploadQueue = <_MPUploadWorkUnit>[];
  final Map<int, _MPBatchAwait> _multiBatchAwait = <int, _MPBatchAwait>{};
  int _multiNextBatchId = 1;
  bool _multiWorkerRunning = false;

  /// 本轮 Worker 已连续完成的上传条数（用于 [MPAudioUploadMultiProgress.currentFileIndex]）。
  int _multiSessionUploaded = 0;

  /// 与 [MPAudioLocalRecordsUtil.copyTempFileToLocalStorage] 生成规则一致，避免把详情下载缓存误当新录音上传。
  static bool _isPendingRecordingFileName(String name) {
    return name.startsWith('omi_record_');
  }

  /// 待上传目录中的音频（与 [audioExtensions] 扩展名一致）。
  static bool _isPendingAudioFilePath(String path) {
    final String lower = path.toLowerCase();
    for (final String ext in audioExtensions) {
      if (lower.endsWith('.$ext')) {
        return true;
      }
    }
    return false;
  }

  static bool _isCompanionTxtFilePath(String path) => path.toLowerCase().endsWith('.txt');

  /// 列出 [MPAudioLocalRecordsUtil.ensureLocalStorageDirectoryPath] 下待上传的录音文件（仅 `omi_record_`）。
  Future<List<File>> _listPendingRecordingFiles() async {
    final String dirPath = await MPAudioLocalRecordsUtil.ensureLocalStorageDirectoryPath();
    final Directory dir = Directory(dirPath);
    if (!await dir.exists()) {
      return <File>[];
    }
    final List<File> out = <File>[];
    await for (final FileSystemEntity e in dir.list(followLinks: false)) {
      if (e is! File) {
        continue;
      }
      final String name = p.basename(e.path);
      if (name.startsWith('.')) {
        continue;
      }
      if (!_isPendingRecordingFileName(name)) {
        continue;
      }
      out.add(e);
    }
    out.sort((File a, File b) => p.basename(a.path).compareTo(p.basename(b.path)));
    return out;
  }

  /// 上传前写入本地记录表；[createAt] 为接口使用的 Unix **秒**，本地 [MPAudioLocalRecord.createAt] 用毫秒。
  Future<MPAudioLocalRecord?> _addLocalRecordBeforeUpload({
    required File localFile,
    required int durationSec,
    required int createAt,
    required String source,
  }) async {
    try {
      final String path = localFile.absolute.path;
      final String name = p.basename(path);
      final int createAtMs = createAt;
      final MPAudioLocalRecord record = MPAudioLocalRecord(
        path: path,
        fileName: name,
        createAt: createAtMs,
        duration: durationSec,
        source: source,
        fileId: '',
      );
      await MPAudioLocalRecordsUtil.instance.load();
      await MPAudioLocalRecordsUtil.instance.add(record);
      return record;
    } catch (e, st) {
      debugPrint('MPAudioLocalRecordsUtil.add failed: $e\n$st');
      return null;
    }
  }

  int _createAtSecondsFromRecord(MPAudioLocalRecord r) {
    if (r.createAt > 2000000000000) {
      return r.createAt ~/ 1000;
    }
    return r.createAt;
  }

  /// [MPAudioUploadLocalItem.createAt] 解析为接口用的 Unix 秒（优先索引记录）。
  int _createAtSecForExplicitItem(MPAudioUploadLocalItem item, MPAudioLocalRecord? meta) {
    if (meta != null) {
      return _createAtSecondsFromRecord(meta);
    }
    final int raw = item.createAt;
    if (raw > 2000000000000) {
      return raw ~/ 1000;
    }
    return raw;
  }

  void _notifyMultiAndHome({
    MPAudioUploadMultiProgress? onMulti,
    required int totalFiles,
    required int currentFileIndex,
    required int progress,
  }) {
    final int p = progress.clamp(0, 100);
    final int tt = totalFiles < 1 ? 1 : totalFiles;
    final int ci = currentFileIndex.clamp(1, tt);
    onMulti?.call(totalFiles: tt, currentFileIndex: ci, progress: p);
    _emitUploadProgress(null, batchIndex: ci, batchTotal: tt, progress: p);
  }

  /// 仅处理 [MPAudioUploadLocalItem] 标识的一条文件（不经由目录枚举合并）。
  Future<MPCreateRecordResponse?> _uploadExplicitLocalItem(
    MPAudioUploadLocalItem item, {
    required bool rightNowTranscribe,
    required int Function() resolveBatchTotal,
    required int currentFileIndex,
    MPAudioUploadMultiProgress? onMultiProgress,
  }) async {
    final File f = item.localFile;
    if (!await f.exists()) {
      MPToastUtils.showMessage('Local file not found.');
      return null;
    }

    final MPAudioLocalRecord? meta = await MPAudioLocalRecordsUtil.instance.queryByPath(f.path);

    int durSec = item.durationSec;
    if (meta != null && meta.duration != null && meta.duration! > 0) {
      durSec = meta.duration!;
    }
    if (durSec <= 0) {
      MPToastUtils.showMessage('Invalid recording duration.');
      return null;
    }

    final int createAtSec = _createAtSecForExplicitItem(item, meta);

    int tt() => resolveBatchTotal().clamp(1, 1 << 30);
    final int idx = currentFileIndex;

    _notifyMultiAndHome(onMulti: onMultiProgress, totalFiles: tt(), currentFileIndex: idx, progress: 0);

    final Duration? duration = await AudioPickerUtils.getAudioDuration(f);
    debugPrint('uploadExplicitLocalItem duration: $duration');
    final String? uri = await MPAudioUploadService().uploadMPAudio(
      f,
      onProgress: (int current, int total) {
        if (total <= 0) {
          return;
        }
        _notifyMultiAndHome(
          onMulti: onMultiProgress,
          totalFiles: tt(),
          currentFileIndex: idx,
          progress: (current * 90 ~/ total).clamp(0, 90),
        );
      },
    );
    if (uri == null || uri.isEmpty) {
      MPToastUtils.showMessage('Failed to upload audio.');
      return null;
    }

    int effectiveDurSec = durSec;
    if (duration != null && duration.inSeconds > 0) {
      effectiveDurSec = duration.inSeconds;
    }

    _notifyMultiAndHome(onMulti: onMultiProgress, totalFiles: tt(), currentFileIndex: idx, progress: 92);

    final MPCreateRecordResponse? created = await createRecord(
      MPCreateRecordRequest(recordFile: uri, createAt: createAtSec, duration: effectiveDurSec, source: item.source),
    );
    if (created == null || created.baseResp.code != 0) {
      MPToastUtils.showMessage(created?.baseResp.message ?? 'Failed to create record.');
      return null;
    }

    if (rightNowTranscribe) {
      _notifyMultiAndHome(onMulti: onMultiProgress, totalFiles: tt(), currentFileIndex: idx, progress: 96);
      final MPSummaryRecordResponse? summary = await summaryRecord(
        MPSummaryRecordRequest(
          memoryId: created.memoryId,
          recordUrl: created.recordUrl,
          recordMemoAt: item.recordMemoAt,
          templateId: item.templateId,
        ),
      );
      if (summary == null || summary.baseResp.code != 0) {
        MPToastUtils.showMessage(summary?.baseResp.message ?? 'Transcription failed.');
        return null;
      }
      MPMemoryNotification.notifyMemoryListRefresh();
    }

    _notifyMultiAndHome(onMulti: onMultiProgress, totalFiles: tt(), currentFileIndex: idx, progress: 100);

    try {
      await f.delete();
    } catch (e) {
      debugPrint('delete local record failed: $e');
    }

    if (meta != null) {
      try {
        await MPAudioLocalRecordsUtil.instance.removeHard(meta);
      } catch (e, st) {
        debugPrint('MPAudioLocalRecordsUtil.removeHard failed: $e\n$st');
      }
    }

    final int notifyTotal = tt();
    final int cap = notifyTotal > 1 ? notifyTotal : 1;
    MPHomeNotification.notifyRecordCreated(
      MPHomeRecordCreatedPayload(memoryId: created.memoryId, batchTotal: cap, batchIndex: idx.clamp(1, cap)),
    );

    return created;
  }

  void _finishMultiBatchUnit(int batchId, MPCreateRecordResponse? created) {
    final _MPBatchAwait? track = _multiBatchAwait[batchId];
    if (track == null) {
      return;
    }
    if (created != null) {
      track.lastCreated = created;
    }
    track.remaining--;
    if (track.remaining <= 0) {
      if (!track.completer.isCompleted) {
        track.completer.complete(track.lastCreated);
      }
      _multiBatchAwait.remove(batchId);
    }
  }

  /// 启动队列消费；若已在跑则由当前 `while` 继续处理，避免并发双 Worker。
  void _scheduleMultiWorker() {
    if (_multiWorkerRunning) {
      return;
    }
    _multiWorkerRunning = true;
    unawaited(_drainMultiUploadQueue());
  }

  Future<void> _drainMultiUploadQueue() async {
    try {
      while (_multiUploadQueue.isNotEmpty) {
        final _MPUploadWorkUnit unit = _multiUploadQueue.removeAt(0);
        final int currentIndex = _multiSessionUploaded + 1;

        MPCreateRecordResponse? created;
        try {
          created = await _uploadExplicitLocalItem(
            unit.item,
            rightNowTranscribe: unit.rightNowTranscribe,
            resolveBatchTotal: () => _multiUploadQueue.length + 1,
            currentFileIndex: currentIndex,
            onMultiProgress: unit.onMultiProgress,
          );
        } catch (e, st) {
          debugPrint('multi upload worker failed: $e\n$st');
          MPToastUtils.showMessage('Upload failed: $e');
          created = null;
        } finally {
          _finishMultiBatchUnit(unit.batchId, created);
        }
        _multiSessionUploaded++;
      }
      _multiSessionUploaded = 0;
    } finally {
      _multiWorkerRunning = false;
      if (_multiUploadQueue.isNotEmpty) {
        _scheduleMultiWorker();
      }
    }
  }

  Future<MPCreateRecordResponse?> _enqueueMultiBatch(
    List<MPAudioUploadLocalItem> items,
    bool rightNowTranscribe,
    MPAudioUploadMultiProgress? onMultiProgress, {
    bool localRecordsAlreadyAdded = false,
  }) async {
    if (items.isEmpty) {
      return null;
    }
    for (final MPAudioUploadLocalItem item in items) {
      if (!await item.localFile.exists()) {
        MPToastUtils.showMessage('Local file not found.');
        return null;
      }
      if (item.durationSec <= 0) {
        MPToastUtils.showMessage('Invalid recording duration.');
        return null;
      }
    }

    final int batchId = _multiNextBatchId++;
    final Completer<MPCreateRecordResponse?> done = Completer<MPCreateRecordResponse?>();
    _multiBatchAwait[batchId] = _MPBatchAwait(remaining: items.length, completer: done);

    for (final MPAudioUploadLocalItem item in items) {
      if (!localRecordsAlreadyAdded) {
        await _addLocalRecordBeforeUpload(
          localFile: item.localFile,
          durationSec: item.durationSec,
          createAt: item.createAt,
          source: item.source,
        );
      }
      _multiUploadQueue.add(
        _MPUploadWorkUnit(
          batchId: batchId,
          item: item,
          rightNowTranscribe: rightNowTranscribe,
          onMultiProgress: onMultiProgress,
        ),
      );
    }

    _scheduleMultiWorker();
    return done.future;
  }

  /// 仅写入本地索引（不上传）。导入流程在同步沙盒后调用，再配合 [uploadMultipleLocalRecords]（[localRecordsAlreadyAdded] 为 true）。
  Future<MPAudioLocalRecord?> registerLocalRecordBeforeUpload({
    required File localFile,
    required int durationSec,
    required int createAt,
    required String source,
  }) => _addLocalRecordBeforeUpload(localFile: localFile, durationSec: durationSec, createAt: createAt, source: source);

  /// 上传多条本地录音（显式列表）；若队列非空则本批排在当前队列之后。
  ///
  /// 进度 [onMultiProgress]：[totalFiles] 含当前正在上传的一条；[currentFileIndex] 为本轮会话内序号。
  ///
  /// [localRecordsAlreadyAdded] 为 true 时跳过入队前的 [MPAudioLocalRecordsUtil.add]（已与导入「先同步再登记」对齐）。
  Future<MPCreateRecordResponse?> uploadMultipleLocalRecords({
    required List<MPAudioUploadLocalItem> items,
    required bool rightNowTranscribe,
    MPAudioUploadMultiProgress? onMultiProgress,
    bool localRecordsAlreadyAdded = false,
  }) => _enqueueMultiBatch(
    items,
    rightNowTranscribe,
    onMultiProgress,
    localRecordsAlreadyAdded: localRecordsAlreadyAdded,
  );

  /// 语义同 [uploadMultipleLocalRecords]：队列为空则新开上传会话，有值则追加到队尾。
  Future<MPCreateRecordResponse?> appendMultipleLocalRecords({
    required List<MPAudioUploadLocalItem> items,
    required bool rightNowTranscribe,
    MPAudioUploadMultiProgress? onMultiProgress,
    bool localRecordsAlreadyAdded = false,
  }) => _enqueueMultiBatch(
    items,
    rightNowTranscribe,
    onMultiProgress,
    localRecordsAlreadyAdded: localRecordsAlreadyAdded,
  );

  /// 基于 [MPAudioLocalRecordsUtil.queryAll] 筛出音频与 `.txt`，按 **同名主文件名** 配对；先上传 txt（若有）再上传音频，随后与 [uploadLocalRecord] 一致执行 [createRecord] / [summaryRecord]（后者仅当 [rightNowTranscribe] 为 true）。
  Future<MPCreateRecordResponse?> uploadAllRecordingFiles({
    bool rightNowTranscribe = false,
    String source = 'MobilePhone',
    int recordMemoAt = 0,
    String? templateId,
    MPAudioUploadPerFileProgress? onPerFileProgress,
  }) async {
    try {
      final List<MPAudioLocalRecord> records = await MPAudioLocalRecordsUtil.instance.queryAll(includeRemoved: false);

      final List<MPAudioLocalRecord> audioRecords = records
          .where((MPAudioLocalRecord r) => _isPendingAudioFilePath(r.path))
          .toList();

      if (audioRecords.isEmpty) {
        MPToastUtils.showMessage('No local recordings to upload.');
        return null;
      }
      audioRecords.sort(
        (MPAudioLocalRecord a, MPAudioLocalRecord b) => p.basename(a.path).compareTo(p.basename(b.path)),
      );

      final List<MPAudioLocalRecord> txtRecords = records
          .where((MPAudioLocalRecord r) => _isCompanionTxtFilePath(r.path))
          .toList();

      final Map<String, File> stemToTxt = <String, File>{};
      final Map<String, MPAudioLocalRecord> stemToTxtRecord = <String, MPAudioLocalRecord>{};
      for (final MPAudioLocalRecord tr in txtRecords) {
        final String stem = p.basenameWithoutExtension(tr.path);
        stemToTxt[stem] = File(tr.path);
        stemToTxtRecord[stem] = tr;
      }

      final int n = audioRecords.length;
      MPCreateRecordResponse? lastCreated;
      final MPAudioUploadService uploadService = MPAudioUploadService();

      for (int i = 0; i < n; i++) {
        final MPAudioLocalRecord record = audioRecords[i];
        final File f = File(record.path);
        if (!await f.exists()) {
          continue;
        }

        int durSec = 1;
        if (record.duration != null && record.duration! > 0) {
          durSec = record.duration!;
        }
        if (durSec <= 0) {
          continue;
        }

        final int createAtSec = _createAtSecondsFromRecord(record);

        final String audioStem = p.basenameWithoutExtension(f.path);
        final File? txtCompanion = stemToTxt[audioStem];
        final MPAudioLocalRecord? txtMeta = stemToTxtRecord[audioStem];
        final bool hasTxt = txtCompanion != null && await txtCompanion.exists();

        _emitUploadProgress(onPerFileProgress, batchIndex: i + 1, batchTotal: n, progress: 0);

        if (hasTxt) {
          final String? txtUri = await uploadService.uploadRecordFile(
            txtCompanion,
            contentType: 'text/plain; charset=utf-8',
            onProgress: (int current, int total) {
              if (total <= 0) {
                return;
              }
            },
          );
          if (txtUri == null || txtUri.isEmpty) {
            MPToastUtils.showMessage('Failed to upload text attachment.');
            _emitUploadProgress(onPerFileProgress, batchIndex: i + 1, batchTotal: n, progress: 100);
            continue;
          }
        }

        final String? audioUri = await uploadService.uploadMPAudio(f, onProgress: (int current, int total) {});
        if (audioUri == null || audioUri.isEmpty) {
          MPToastUtils.showMessage('Failed to upload audio.');
          _emitUploadProgress(onPerFileProgress, batchIndex: i + 1, batchTotal: n, progress: 100);
          continue;
        }

        final Duration? duration = await AudioPickerUtils.getAudioDuration(f);
        debugPrint('uploadAllRecordingFiles duration: $duration');
        int effectiveDurSec = durSec;
        if (duration != null && duration.inSeconds > 0) {
          effectiveDurSec = duration.inSeconds;
        }

        final MPCreateRecordResponse? created = await createRecord(
          MPCreateRecordRequest(recordFile: audioUri, createAt: createAtSec, duration: effectiveDurSec, source: source),
        );
        if (created == null || created.baseResp.code != 0) {
          MPToastUtils.showMessage(created?.baseResp.message ?? 'Failed to create record.');
          _emitUploadProgress(onPerFileProgress, batchIndex: i + 1, batchTotal: n, progress: 100);
          continue;
        }

        if (rightNowTranscribe) {
          final MPSummaryRecordResponse? summary = await summaryRecord(
            MPSummaryRecordRequest(
              memoryId: created.memoryId,
              recordUrl: created.recordUrl,
              recordMemoAt: recordMemoAt,
              templateId: templateId,
            ),
          );
          if (summary == null || summary.baseResp.code != 0) {
            MPToastUtils.showMessage(summary?.baseResp.message ?? 'Transcription failed.');
            continue;
          }
          MPMemoryNotification.notifyMemoryListRefresh();
        }

        _emitUploadProgress(onPerFileProgress, batchIndex: i + 1, batchTotal: n, progress: 100);

        try {
          await MPAudioLocalRecordsUtil.instance.removeSoft(record);
        } catch (e, st) {
          debugPrint('MPAudioLocalRecordsUtil.removeHard failed: $e\n$st');
        }

        if (txtMeta != null) {
          try {
            await MPAudioLocalRecordsUtil.instance.removeSoft(txtMeta);
          } catch (e, st) {
            debugPrint('MPAudioLocalRecordsUtil.removeHard(txt) failed: $e\n$st');
          }
        }

        MPHomeNotification.notifyRecordCreated(
          MPHomeRecordCreatedPayload(memoryId: created.memoryId, batchTotal: n, batchIndex: i + 1),
        );

        lastCreated = created;
      }

      return lastCreated;
    } catch (e) {
      MPToastUtils.showMessage('Upload failed: $e');
      return null;
    }
  }

  /// 将本地录音同步为服务端 record：先 [add] 索引，再对目录内待上传文件逐个 [createRecord]（`record_file` 为上传后的 URI）。
  ///
  /// - **rightNowTranscribe**: 为 true 时每条 createRecord 成功后继续 summaryRecord。
  /// - **recordMemoAt** / **templateId**: 仅作用于每条转写请求。
  /// - **onPerFileProgress**: 可选；由 **上传页面**（如录音弹窗）传入以更新进度条，本类不实现模拟动画。
  Future<MPCreateRecordResponse?> uploadLocalRecord({
    required File localFile,
    required int durationSec,
    required int createAt,
    bool rightNowTranscribe = false,
    String source = 'mp',
    int recordMemoAt = 0,
    String? templateId,
    int batchTotal = 1,
    int batchIndex = 1,
    MPAudioUploadPerFileProgress? onPerFileProgress,
  }) async {
    try {
      if (!await localFile.exists()) {
        MPToastUtils.showMessage('Local file not found.');
        return null;
      }
      if (durationSec <= 0) {
        MPToastUtils.showMessage('Invalid recording duration.');
        return null;
      }

      await _addLocalRecordBeforeUpload(
        localFile: localFile,
        durationSec: durationSec,
        createAt: createAt,
        source: source,
      );

      List<File> files = await _listPendingRecordingFiles();
      final Set<String> seen = <String>{for (final File f in files) f.absolute.path};
      if (await localFile.exists() && !seen.contains(localFile.absolute.path)) {
        files = <File>[...files, localFile];
        files.sort((File a, File b) => p.basename(a.path).compareTo(p.basename(b.path)));
      }

      if (files.isEmpty) {
        MPToastUtils.showMessage('No local recordings to upload.');
        return null;
      }

      final int n = files.length;
      MPCreateRecordResponse? lastCreated;

      for (int i = 0; i < n; i++) {
        final File f = files[i];
        if (!await f.exists()) {
          continue;
        }

        final bool isCurrent = p.equals(f.absolute.path, localFile.absolute.path);
        final MPAudioLocalRecord? meta = await MPAudioLocalRecordsUtil.instance.queryByPath(f.path);

        int durSec = isCurrent ? durationSec : 1;
        if (meta != null && meta.duration != null && meta.duration! > 0) {
          durSec = meta.duration!;
        }
        if (durSec <= 0) {
          continue;
        }

        int createAtSec;
        if (meta != null) {
          createAtSec = _createAtSecondsFromRecord(meta);
        } else if (isCurrent) {
          createAtSec = createAt;
        } else {
          try {
            createAtSec = (await f.lastModified()).millisecondsSinceEpoch ~/ 1000;
          } catch (_) {
            createAtSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          }
        }

        // 每条文件单独一条进度条：新文件开始时从 0 计。
        _emitUploadProgress(onPerFileProgress, batchIndex: i + 1, batchTotal: n, progress: 0);

        final File file = File(f.path);
        final Duration? duration = await AudioPickerUtils.getAudioDuration(file);
        debugPrint('uploadLocalRecords duration: $duration');
        final String? uri = await MPAudioUploadService().uploadMPAudio(
          file,
          onProgress: (int current, int total) {
            if (total <= 0) {
              return;
            }
            _emitUploadProgress(
              onPerFileProgress,
              batchIndex: i + 1,
              batchTotal: n,
              progress: (current * 90 ~/ total).clamp(0, 90),
            );
          },
        );
        if (uri == null || uri.isEmpty) {
          MPToastUtils.showMessage('Failed to upload audio.');
          return lastCreated;
        }

        int effectiveDurSec = durSec;
        if (duration != null && duration.inSeconds > 0) {
          effectiveDurSec = duration.inSeconds;
        }

        _emitUploadProgress(onPerFileProgress, batchIndex: i + 1, batchTotal: n, progress: 92);

        final MPCreateRecordResponse? created = await createRecord(
          MPCreateRecordRequest(recordFile: uri, createAt: createAtSec, duration: effectiveDurSec, source: source),
        );
        if (created == null || created.baseResp.code != 0) {
          MPToastUtils.showMessage(created?.baseResp.message ?? 'Failed to create record.');
          return lastCreated;
        }

        if (rightNowTranscribe) {
          _emitUploadProgress(onPerFileProgress, batchIndex: i + 1, batchTotal: n, progress: 96);
          final MPSummaryRecordResponse? summary = await summaryRecord(
            MPSummaryRecordRequest(
              memoryId: created.memoryId,
              recordUrl: created.recordUrl,
              recordMemoAt: recordMemoAt,
              templateId: templateId,
            ),
          );
          if (summary == null || summary.baseResp.code != 0) {
            MPToastUtils.showMessage(summary?.baseResp.message ?? 'Transcription failed.');
            return lastCreated;
          }
          MPMemoryNotification.notifyMemoryListRefresh();
        }

        _emitUploadProgress(onPerFileProgress, batchIndex: i + 1, batchTotal: n, progress: 100);

        try {
          await f.delete();
        } catch (e) {
          debugPrint('delete local record failed: $e');
        }

        if (meta != null) {
          try {
            await MPAudioLocalRecordsUtil.instance.removeHard(meta);
          } catch (e, st) {
            debugPrint('MPAudioLocalRecordsUtil.removeHard failed: $e\n$st');
          }
        }

        final int notifyTotal = batchTotal < 1 ? 1 : batchTotal;
        final int notifyIndex = batchIndex.clamp(1, notifyTotal);
        MPHomeNotification.notifyRecordCreated(
          MPHomeRecordCreatedPayload(
            memoryId: created.memoryId,
            batchTotal: n > 1 ? n : notifyTotal,
            batchIndex: n > 1 ? i + 1 : notifyIndex,
          ),
        );

        lastCreated = created;
      }

      return lastCreated;
    } catch (e) {
      MPToastUtils.showMessage('Upload failed: $e');
      return null;
    }
  }
}
