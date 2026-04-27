import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:memo_pin/audio/audio_picker_utils.dart';
import 'package:memo_pin/audio/record/mp_audio_local_records_util.dart';
import 'package:memo_pin/audio/record/mp_audio_upload_service.dart';
import 'package:memo_pin/common/mp_home_notification.dart';
import 'package:memo_pin/common/mp_memory_notification.dart';
import 'package:memo_pin/http/api/mp_memory.dart';
import 'package:memo_pin/http/schema/mp_memory.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:path/path.dart' as p;

/// 单条文件上传进度（0–100，对应当前第 [batchIndex] 条）；由 **调用方页面** 更新进度条，不在本类内做 UI 模拟。
typedef MPAudioUploadPerFileProgress = void Function({
  required int batchIndex,
  required int batchTotal,
  required int progress,
});

void _emitUploadProgress(
  MPAudioUploadPerFileProgress? onPerFileProgress, {
  required int batchIndex,
  required int batchTotal,
  required int progress,
}) {
  final int p = progress.clamp(0, 100);
  onPerFileProgress?.call(
    batchIndex: batchIndex,
    batchTotal: batchTotal,
    progress: p,
  );
  MPHomeNotification.notifyUploadProgress(
    MPHomeUploadProgressPayload(
      batchTotal: batchTotal,
      batchIndex: batchIndex,
      progress: p,
    ),
  );
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

  /// 与 [MPAudioLocalRecordsUtil.copyTempFileToLocalStorage] 生成规则一致，避免把详情下载缓存误当新录音上传。
  static bool _isPendingRecordingFileName(String name) {
    return name.startsWith('omi_record_');
  }

  /// 列出 [MPAudioLocalRecordsUtil.ensureLocalStorageDirectoryPath] 下待上传的录音文件（仅 `omi_record_`）。
  Future<List<File>> _listPendingRecordingFiles() async {
    final String dirPath =
        await MPAudioLocalRecordsUtil.ensureLocalStorageDirectoryPath();
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
    out.sort(
      (File a, File b) => p.basename(a.path).compareTo(p.basename(b.path)),
    );
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
      final int createAtMs = createAt * 1000;
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
        MPToastUtils.showMessage('本地文件不存在');
        return null;
      }
      if (durationSec <= 0) {
        MPToastUtils.showMessage('录音时长无效');
        return null;
      }

      await _addLocalRecordBeforeUpload(
        localFile: localFile,
        durationSec: durationSec,
        createAt: createAt,
        source: source,
      );

      List<File> files = await _listPendingRecordingFiles();
      final Set<String> seen = <String>{
        for (final File f in files) f.absolute.path,
      };
      if (await localFile.exists() && !seen.contains(localFile.absolute.path)) {
        files = <File>[...files, localFile];
        files.sort(
          (File a, File b) => p.basename(a.path).compareTo(p.basename(b.path)),
        );
      }

      if (files.isEmpty) {
        MPToastUtils.showMessage('没有可上传的本地录音');
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
        final MPAudioLocalRecord? meta =
            await MPAudioLocalRecordsUtil.instance.queryByPath(f.path);

        int durSec = isCurrent ? durationSec : 1;
        if (meta != null &&
            meta.duration != null &&
            meta.duration! > 0) {
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
            createAtSec =
                (await f.lastModified()).millisecondsSinceEpoch ~/ 1000;
          } catch (_) {
            createAtSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          }
        }

        // 每条文件单独一条进度条：新文件开始时从 0 计。
        _emitUploadProgress(
          onPerFileProgress,
          batchIndex: i + 1,
          batchTotal: n,
          progress: 0,
        );

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
          MPToastUtils.showMessage('音频上传失败');
          return lastCreated;
        }

        int effectiveDurSec = durSec;
        if (duration != null && duration.inSeconds > 0) {
          effectiveDurSec = duration.inSeconds;
        }

        _emitUploadProgress(
          onPerFileProgress,
          batchIndex: i + 1,
          batchTotal: n,
          progress: 92,
        );

        final MPCreateRecordResponse? created = await createRecord(
          MPCreateRecordRequest(
            recordFile: uri,
            createAt: createAtSec,
            duration: effectiveDurSec,
            source: source,
          ),
        );
        if (created == null || created.baseResp.code != 0) {
          MPToastUtils.showMessage(created?.baseResp.message ?? '创建记录失败');
          return lastCreated;
        }

        if (rightNowTranscribe) {
          _emitUploadProgress(
            onPerFileProgress,
            batchIndex: i + 1,
            batchTotal: n,
            progress: 96,
          );
          final MPSummaryRecordResponse? summary = await summaryRecord(
            MPSummaryRecordRequest(
              memoryId: created.memoryId,
              recordUrl: created.recordUrl,
              recordMemoAt: recordMemoAt,
              templateId: templateId,
            ),
          );
          if (summary == null || summary.baseResp.code != 0) {
            MPToastUtils.showMessage(summary?.baseResp.message ?? '转写失败');
            return lastCreated;
          }
          MPMemoryNotification.notifyMemoryListRefresh();
        }

        _emitUploadProgress(
          onPerFileProgress,
          batchIndex: i + 1,
          batchTotal: n,
          progress: 100,
        );

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
      MPToastUtils.showMessage('上传失败: $e');
      return null;
    }
  }
}
