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
  debugPrint('MPAudioUploadManager: upload progress $batchIndex/$batchTotal → $p%');
  onPerFileProgress?.call(batchIndex: batchIndex, batchTotal: batchTotal, progress: p);
  MPHomeNotification.notifyUploadProgress(
    MPHomeUploadProgressPayload(batchTotal: batchTotal, batchIndex: batchIndex, progress: p),
  );
}

/// 单条上传失败：通知首页 Toast；最后一条时由 [isLastInBatch] 触发状态条收口。
///
/// 失败路径不再追加 `progress: 100` 进度事件，避免首页 [showSyncingStatus] 取消已安排的清除定时器。
void _notifyBatchUploadFailure({
  required int batchIndex,
  required int batchTotal,
}) {
  final bool isLastInBatch = batchIndex >= batchTotal;
  debugPrint(
    'MPAudioUploadManager: upload failed file $batchIndex/$batchTotal, isLastInBatch=$isLastInBatch',
  );
  MPHomeNotification.notifyUploadFailed(
    MPHomeUploadFailedPayload(
      batchTotal: batchTotal,
      batchIndex: batchIndex,
      isLastInBatch: isLastInBatch,
    ),
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

/// 单次批量上传任务（由全局 Worker 串行消费）。
class _MPAudioUploadJob {
  _MPAudioUploadJob({
    required this.audioRecords,
    required this.allRecordsForTxt,
    required this.rightNowTranscribe,
    required this.sourceOverride,
    required this.recordMemoAt,
    required this.templateId,
    this.onPerFileProgress,
  });

  final List<MPAudioLocalRecord> audioRecords;
  final List<MPAudioLocalRecord> allRecordsForTxt;
  final bool rightNowTranscribe;
  final String? sourceOverride;
  final int recordMemoAt;
  final String? templateId;
  final MPAudioUploadPerFileProgress? onPerFileProgress;
  final Completer<MPCreateRecordResponse?> completer = Completer<MPCreateRecordResponse?>();
}

/// 本地录音落盘后，先 [MPAudioUploadService.uploadMPAudio] 上传，再用返回的 **远端 URI** 调 [createRecord]。
///
/// - [uploadAllRecordingFiles]：查询全部未删除本地记录后上传。
/// - [uploadRecords]：按调用方传入的 [MPAudioLocalRecord] 上传（已登记、无需再导入）。
/// - 若 [rightNowTranscribe] 为 true，每条成功后 [summaryRecord]；成功后标记 [MPAudioLocalRecord.isRemoved]。
/// - 全局单 Worker 队列：同一音频路径在「已入队或上传中」时不会重复入队，避免并发 batch 与重复 [createRecord]。
class MPAudioUploadManager {
  MPAudioUploadManager._();

  static final MPAudioUploadManager instance = MPAudioUploadManager._();

  final List<_MPAudioUploadJob> _jobQueue = <_MPAudioUploadJob>[];

  /// 已入队或正在上传的音频绝对路径（规范化后），用于入队去重。
  final Set<String> _queuedOrUploadingPaths = <String>{};

  bool _workerLoopRunning = false;

  Completer<void>? _idleCompleter;

  /// 是否有待处理或进行中的上传任务。
  bool get hasActiveUploads => _workerLoopRunning || _jobQueue.isNotEmpty || _queuedOrUploadingPaths.isNotEmpty;

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

  int _createAtSecondsFromRecord(MPAudioLocalRecord r) {
    if (r.createAt > 2000000000000) {
      return r.createAt ~/ 1000;
    }
    return r.createAt;
  }

  /// 本地是否仍有待上传的音频记录（未逻辑删除且文件路径有效）。
  Future<bool> hasPendingUploadableRecords() async {
    try {
      final List<MPAudioLocalRecord> records = await MPAudioLocalRecordsUtil.instance.queryAll(includeRemoved: false);
      return records.any((MPAudioLocalRecord r) => !r.isRemoved && _isUploadableAudioRecord(r));
    } catch (e) {
      debugPrint('MPAudioUploadManager: hasPendingUploadableRecords failed: $e');
      return false;
    }
  }

  /// 基于 [MPAudioLocalRecordsUtil.queryAll] 筛出待上传音频并上传（含导入后已登记的全量队列）。
  Future<MPCreateRecordResponse?> uploadAllRecordingFiles({
    bool rightNowTranscribe = false,
    String source = 'MobilePhone',
    int recordMemoAt = 0,
    String? templateId,
    MPAudioUploadPerFileProgress? onPerFileProgress,
  }) async {
    try {
      final List<MPAudioLocalRecord> records = await MPAudioLocalRecordsUtil.instance.queryAll(includeRemoved: false);
      return uploadRecords(
        records,
        rightNowTranscribe: rightNowTranscribe,
        source: source,
        recordMemoAt: recordMemoAt,
        templateId: templateId,
        onPerFileProgress: onPerFileProgress,
      );
    } catch (e) {
      debugPrint('MPAudioUploadManager: uploadAllRecordingFiles failed: $e');
      return null;
    }
  }

  /// 按已登记的 [MPAudioLocalRecord] 上传（文件已在本地，**不**再走导入 / 选文件）。
  ///
  /// 从 [records] 中筛出未删除的音频项；[txtPath] 或同批次内同名 stem 的 `.txt` 记录会一并上传。
  /// [source] 非空时覆盖每条 [MPAudioLocalRecord.source]；否则使用记录自身 [MPAudioLocalRecord.source]。
  Future<MPCreateRecordResponse?> uploadRecords(
    List<MPAudioLocalRecord> records, {
    bool rightNowTranscribe = false,
    String? source,
    int recordMemoAt = 0,
    String? templateId,
    MPAudioUploadPerFileProgress? onPerFileProgress,
  }) async {
    try {
      final List<MPAudioLocalRecord> audioRecords = records
          .where((MPAudioLocalRecord r) => !r.isRemoved && _isUploadableAudioRecord(r))
          .toList();

      if (audioRecords.isEmpty) {
        debugPrint('MPAudioUploadManager: no records to upload.');
        return null;
      }
      audioRecords.sort(
        (MPAudioLocalRecord a, MPAudioLocalRecord b) =>
            p.basename(_audioFilePathForUpload(a)).compareTo(p.basename(_audioFilePathForUpload(b))),
      );

      return _enqueueUploadJob(
        audioRecords: audioRecords,
        allRecordsForTxt: records,
        rightNowTranscribe: rightNowTranscribe,
        sourceOverride: source,
        recordMemoAt: recordMemoAt,
        templateId: templateId,
        onPerFileProgress: onPerFileProgress,
      );
    } catch (e) {
      debugPrint('MPAudioUploadManager: uploadRecords failed: $e');
      return null;
    }
  }

  static bool _isUploadableAudioRecord(MPAudioLocalRecord record) {
    if (_isPendingAudioFilePath(record.path)) {
      return true;
    }
    final String? mp3 = record.mp3Path?.trim();
    return mp3 != null && mp3.isNotEmpty && _isPendingAudioFilePath(mp3);
  }

  static String _audioFilePathForUpload(MPAudioLocalRecord record) {
    final String? mp3 = record.mp3Path?.trim();
    if (mp3 != null && mp3.isNotEmpty) {
      return mp3;
    }
    return record.path;
  }

  static String _uploadKeyForPath(String path) => p.normalize(path);

  static String _uploadKeyForRecord(MPAudioLocalRecord record) =>
      _uploadKeyForPath(_audioFilePathForUpload(record));

  void _trackUploadPath(String audioPath) {
    _queuedOrUploadingPaths.add(_uploadKeyForPath(audioPath));
  }

  void _releaseUploadPath(String audioPath) {
    _queuedOrUploadingPaths.remove(_uploadKeyForPath(audioPath));
  }

  /// 构建 txt 伴生文件索引（与 [uploadRecords] 内逻辑一致）。
  static ({Map<String, File> stemToTxt, Map<String, MPAudioLocalRecord> stemToTxtRecord}) _buildTxtCompanionMaps(
    List<MPAudioLocalRecord> records,
  ) {
    final Map<String, File> stemToTxt = <String, File>{};
    final Map<String, MPAudioLocalRecord> stemToTxtRecord = <String, MPAudioLocalRecord>{};
    for (final MPAudioLocalRecord tr in records) {
      if (tr.isRemoved || !_isCompanionTxtFilePath(tr.path)) {
        continue;
      }
      final String stem = p.basenameWithoutExtension(tr.path);
      stemToTxt[stem] = File(tr.path);
      stemToTxtRecord[stem] = tr;
    }
    return (stemToTxt: stemToTxt, stemToTxtRecord: stemToTxtRecord);
  }

  Future<void> _whenWorkerIdle() {
    if (!_workerLoopRunning && _jobQueue.isEmpty) {
      return Future<void>.value();
    }
    _idleCompleter ??= Completer<void>();
    return _idleCompleter!.future;
  }

  void _signalWorkerIdleIfNeeded() {
    if (_workerLoopRunning || _jobQueue.isNotEmpty) {
      return;
    }
    final Completer<void>? idle = _idleCompleter;
    if (idle != null && !idle.isCompleted) {
      idle.complete();
    }
    _idleCompleter = null;
  }

  void _ensureWorkerRunning() {
    if (_workerLoopRunning) {
      return;
    }
    _workerLoopRunning = true;
    unawaited(_runWorkerLoop());
  }

  Future<void> _runWorkerLoop() async {
    try {
      while (_jobQueue.isNotEmpty) {
        final _MPAudioUploadJob job = _jobQueue.removeAt(0);
        MPCreateRecordResponse? lastCreated;
        try {
          lastCreated = await _executeUploadJob(job);
        } catch (e, st) {
          debugPrint('MPAudioUploadManager: job failed: $e\n$st');
        } finally {
          if (!job.completer.isCompleted) {
            job.completer.complete(lastCreated);
          }
        }
      }
    } finally {
      _workerLoopRunning = false;
      _signalWorkerIdleIfNeeded();
      if (_jobQueue.isNotEmpty) {
        _ensureWorkerRunning();
      }
    }
  }

  Future<MPCreateRecordResponse?> _enqueueUploadJob({
    required List<MPAudioLocalRecord> audioRecords,
    required List<MPAudioLocalRecord> allRecordsForTxt,
    required bool rightNowTranscribe,
    required String? sourceOverride,
    required int recordMemoAt,
    required String? templateId,
    MPAudioUploadPerFileProgress? onPerFileProgress,
  }) async {
    final List<MPAudioLocalRecord> toEnqueue = <MPAudioLocalRecord>[];
    for (final MPAudioLocalRecord record in audioRecords) {
      final String key = _uploadKeyForRecord(record);
      if (_queuedOrUploadingPaths.contains(key)) {
        debugPrint('MPAudioUploadManager: skip duplicate enqueue path=$key');
        continue;
      }
      _trackUploadPath(_audioFilePathForUpload(record));
      toEnqueue.add(record);
    }

    if (toEnqueue.isEmpty) {
      debugPrint('MPAudioUploadManager: no new records to enqueue (duplicates skipped).');
      await _whenWorkerIdle();
      return null;
    }

    final _MPAudioUploadJob job = _MPAudioUploadJob(
      audioRecords: toEnqueue,
      allRecordsForTxt: allRecordsForTxt,
      rightNowTranscribe: rightNowTranscribe,
      sourceOverride: sourceOverride,
      recordMemoAt: recordMemoAt,
      templateId: templateId,
      onPerFileProgress: onPerFileProgress,
    );
    _jobQueue.add(job);
    debugPrint(
      'MPAudioUploadManager: enqueued job with ${toEnqueue.length} file(s), queueDepth=${_jobQueue.length}',
    );
    _ensureWorkerRunning();
    return job.completer.future;
  }

  Future<MPCreateRecordResponse?> _executeUploadJob(_MPAudioUploadJob job) async {
    final ({Map<String, File> stemToTxt, Map<String, MPAudioLocalRecord> stemToTxtRecord}) txtMaps =
        _buildTxtCompanionMaps(job.allRecordsForTxt);
    return _uploadAudioRecordBatch(
      audioRecords: job.audioRecords,
      stemToTxt: txtMaps.stemToTxt,
      stemToTxtRecord: txtMaps.stemToTxtRecord,
      rightNowTranscribe: job.rightNowTranscribe,
      sourceOverride: job.sourceOverride,
      recordMemoAt: job.recordMemoAt,
      templateId: job.templateId,
      onPerFileProgress: job.onPerFileProgress,
    );
  }

  Future<MPCreateRecordResponse?> _uploadAudioRecordBatch({
    required List<MPAudioLocalRecord> audioRecords,
    required Map<String, File> stemToTxt,
    required Map<String, MPAudioLocalRecord> stemToTxtRecord,
    required bool rightNowTranscribe,
    required String? sourceOverride,
    required int recordMemoAt,
    required String? templateId,
    MPAudioUploadPerFileProgress? onPerFileProgress,
  }) async {
    final int n = audioRecords.length;
    MPCreateRecordResponse? lastCreated;
    final MPAudioUploadService uploadService = MPAudioUploadService();
    debugPrint('MPAudioUploadManager: batch upload start, total=$n');

    for (int i = 0; i < n; i++) {
      final MPAudioLocalRecord record = audioRecords[i];
      final String audioPath = _audioFilePathForUpload(record);
      final File f = File(audioPath);
      debugPrint('MPAudioUploadManager: batch upload file ${i + 1}/$n path=$audioPath');
      try {
      if (!await f.exists()) {
        record.isRemoved = true;
        try {
          await MPAudioLocalRecordsUtil.instance.update(record);
        } catch (e, st) {
          debugPrint('MPAudioLocalRecordsUtil.update(isRemoved) failed: $e\n$st');
        }
        _emitUploadProgress(onPerFileProgress, batchIndex: i + 1, batchTotal: n, progress: 100);
        continue;
      }

      int durSec = 1;
      if (record.duration != null && record.duration! > 0) {
        durSec = record.duration!;
      }
      if (durSec <= 0) {
        record.isRemoved = true;
        try {
          await MPAudioLocalRecordsUtil.instance.update(record);
        } catch (e, st) {
          debugPrint('MPAudioLocalRecordsUtil.update(isRemoved) failed: $e\n$st');
        }
        _emitUploadProgress(onPerFileProgress, batchIndex: i + 1, batchTotal: n, progress: 100);
        continue;
      }

      final int createAtSec = _createAtSecondsFromRecord(record);
      final String effectiveSource =
          (sourceOverride != null && sourceOverride.isNotEmpty) ? sourceOverride : record.source;

      final String audioStem = p.basenameWithoutExtension(f.path);
      File? txtCompanion;
      MPAudioLocalRecord? txtMeta;
      final String? embeddedTxt = record.txtPath?.trim();
      if (embeddedTxt != null && embeddedTxt.isNotEmpty) {
        final File tf = File(embeddedTxt);
        if (await tf.exists()) {
          txtCompanion = tf;
        }
      }
      if (txtCompanion == null) {
        txtCompanion = stemToTxt[audioStem];
        txtMeta = stemToTxtRecord[audioStem];
      }
      final bool hasTxt = txtCompanion != null && await txtCompanion.exists();

      _emitUploadProgress(onPerFileProgress, batchIndex: i + 1, batchTotal: n, progress: 0);
      String? txtUri;
      if (hasTxt) {
        debugPrint('MPAudioUploadManager: uploading txt companion for file ${i + 1}/$n');
        txtUri = await uploadService.uploadRecordFile(
          txtCompanion,
          contentType: 'text/plain; charset=utf-8',
          onProgress: (int current, int total) {
            if (total <= 0) {
              return;
            }
            debugPrint('MPAudioUploadManager: txt file ${i + 1}/$n step $current/$total');
          },
        );
        if (txtUri == null || txtUri.isEmpty) {
          debugPrint('MPAudioUploadManager: failed to upload txt companion.');
          _notifyBatchUploadFailure(
            batchIndex: i + 1,
            batchTotal: n,
          );
          continue;
        }
      }

      final String? audioUri = await uploadService.uploadMPAudio(
        f,
        onProgress: (int current, int total) {
          debugPrint('MPAudioUploadManager: audio file ${i + 1}/$n step $current/$total');
        },
      );
      if (audioUri == null || audioUri.isEmpty) {
        debugPrint('MPAudioUploadManager: failed to upload audio.');
        _notifyBatchUploadFailure(
          batchIndex: i + 1,
          batchTotal: n,
        );
        continue;
      }

      record.fileId = MPAudioLocalRecordsUtil.getFileIdFromRecordFile(audioUri);

      final Duration? duration = await AudioPickerUtils.getAudioDuration(f);
      debugPrint('MPAudioUploadManager upload duration: $duration');
      int effectiveDurSec = durSec;
      if (duration != null && duration.inSeconds > 0) {
        effectiveDurSec = duration.inSeconds;
      }

      final MPCreateRecordResponse? created = await createRecord(
        MPCreateRecordRequest(
          recordFile: audioUri,
          createAt: createAtSec,
          duration: effectiveDurSec,
          source: effectiveSource,
          txtFile: txtUri,
        ),
      );
      if (created == null || created.baseResp.code != 0) {
        debugPrint('MPAudioUploadManager: failed to create record.');
        _notifyBatchUploadFailure(
          batchIndex: i + 1,
          batchTotal: n,
        );
        continue;
      }

      record.isRemoved = true;

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
          debugPrint('MPAudioUploadManager: transcription failed.');
          continue;
        }
        MPMemoryNotification.notifyMemoryListRefresh();
      }

      _emitUploadProgress(onPerFileProgress, batchIndex: i + 1, batchTotal: n, progress: 100);

      try {
        await MPAudioLocalRecordsUtil.instance.update(record);
      } catch (e, st) {
        debugPrint('MPAudioLocalRecordsUtil.update failed: $e\n$st');
      }

      if (txtMeta != null) {
        try {
          await MPAudioLocalRecordsUtil.instance.update(txtMeta);
        } catch (e, st) {
          debugPrint('MPAudioLocalRecordsUtil.update(txt) failed: $e\n$st');
        }
      }

      MPHomeNotification.notifyRecordCreated(
        MPHomeRecordCreatedPayload(memoryId: created.memoryId, batchTotal: n, batchIndex: i + 1),
      );
      debugPrint(
        'MPAudioUploadManager: upload success file ${i + 1}/$n memoryId=${created.memoryId}',
      );

      lastCreated = created;
      } finally {
        _releaseUploadPath(audioPath);
      }
    }

    debugPrint('MPAudioUploadManager: batch upload end, total=$n');
    return lastCreated;
  }
}
