import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:memo_pin/audio/record/mp_audio_local_records_util.dart';
import 'package:memo_pin/audio/record/mp_audio_upload_manger.dart';
import 'package:memo_pin/common/mp_home_notification.dart';
import 'package:path/path.dart' as p;

/// 首页 import / upload 双队列协调器。
///
/// - **import 队列**：待复制/同步的文件数；有任务时顶栏优先展示 importing。
/// - **upload 队列**：import 完成后逐条入队；import 清空后顶栏展示 syncing 的 x/y。
/// - upload 全部完成后清空 upload 会话并通知首页隐藏状态栏。
class MPHomeAudioTaskQueue {
  MPHomeAudioTaskQueue._();

  static final MPHomeAudioTaskQueue instance = MPHomeAudioTaskQueue._();

  int _importRemaining = 0;
  int _importFileIndex = 0;
  int _importFileTotal = 0;
  int _importProgressPercent = 0;

  int _uploadTotal = 0;
  int _uploadCompleted = 0;
  int _uploadProgressPercent = 0;

  final Set<String> _uploadSessionKeys = <String>{};

  Timer? _uploadSessionClearTimer;

  bool _retryUnfinishedUploadsRunning = false;

  bool get hasImportTasks => _importRemaining > 0;

  bool get hasUploadSession => _uploadTotal > 0;

  bool get isUploadSessionFinished =>
      _uploadTotal > 0 && _uploadCompleted >= _uploadTotal && !MPAudioUploadManager.instance.hasActiveUploads;

  /// upload 队列 x/y 快照。
  ({int currentFile, int totalFiles}) get uploadProgressSnapshot {
    final int total = _uploadTotal < 1 ? 1 : _uploadTotal;
    final int completed = _uploadCompleted.clamp(0, total);
    final int current = completed < total ? (completed + 1).clamp(1, total) : total;
    return (currentFile: current, totalFiles: total);
  }

  /// 开始一批 import（文件数在复制/同步前已知）。
  void beginImportBatch(int fileCount) {
    if (fileCount < 1) {
      return;
    }
    _importRemaining += fileCount;
    _importFileTotal = fileCount;
    _importFileIndex = 0;
    _importProgressPercent = 0;
    debugPrint('MPHomeAudioTaskQueue: beginImportBatch +$fileCount, remaining=$_importRemaining');
    _publishTaskBarState();
  }

  /// 更新当前 import 文件进度。
  void reportImportProgress({
    required int fileIndex,
    required int fileTotal,
    required int progressPercent,
  }) {
    _importFileIndex = fileIndex;
    _importFileTotal = fileTotal;
    _importProgressPercent = progressPercent.clamp(0, 100);
    _publishTaskBarState();
  }

  /// 单条 import 失败或跳过：从 import 队列移除，不入 upload。
  void skipImportFile() {
    if (_importRemaining > 0) {
      _importRemaining--;
    }
    debugPrint('MPHomeAudioTaskQueue: skipImportFile, remaining=$_importRemaining');
    _publishTaskBarState();
  }

  /// 取消整批 import（如 BLE 断连）。
  void cancelAllImportTasks() {
    _importRemaining = 0;
    _importFileIndex = 0;
    _importFileTotal = 0;
    _importProgressPercent = 0;
    _publishTaskBarState();
  }

  /// 单条 import 完成且暂不入 upload 队列（设备批量 sync 整批结束后再上传）。
  void acknowledgeImportFileDone() {
    if (_importRemaining > 0) {
      _importRemaining--;
    }
    debugPrint(
      'MPHomeAudioTaskQueue: acknowledgeImportFileDone, importRemaining=$_importRemaining',
    );
    _publishTaskBarState();
  }

  /// 单条 import 完成：移出 import 队列，upload 队列 +1 并触发上传。
  Future<void> completeImportFile(
    MPAudioLocalRecord record, {
    String? source,
    bool rightNowTranscribe = false,
  }) async {
    if (_importRemaining > 0) {
      _importRemaining--;
    }
    debugPrint(
      'MPHomeAudioTaskQueue: completeImportFile ${_uploadKeyForRecord(record)}, '
      'importRemaining=$_importRemaining',
    );
    await _enqueueUploadRecord(
      record,
      source: source,
      rightNowTranscribe: rightNowTranscribe,
    );
    _publishTaskBarState();
  }

  /// 将单条已落库记录加入 upload 队列（非 import 路径，如录音停录）。
  Future<void> enqueueUploadRecord(
    MPAudioLocalRecord record, {
    String? source,
    bool rightNowTranscribe = false,
  }) async {
    await _enqueueUploadRecord(
      record,
      source: source,
      rightNowTranscribe: rightNowTranscribe,
    );
    _publishTaskBarState();
  }

  /// 将本地待传记录批量加入 upload 队列（冷/热启动补传）。
  Future<void> seedPendingUploadsFromLocal({String? source}) async {
    try {
      final int totalBefore = _uploadTotal;
      final List<MPAudioLocalRecord> records = await MPAudioLocalRecordsUtil.instance.queryAll(includeRemoved: false);
      for (final MPAudioLocalRecord record in records) {
        if (record.isRemoved || !MPAudioUploadManager.isUploadableAudioRecord(record)) {
          continue;
        }
        final String key = _uploadKeyForRecord(record);
        if (_uploadSessionKeys.contains(key)) {
          continue;
        }
        await _enqueueUploadRecord(record, source: source, rightNowTranscribe: false);
      }
      if (_uploadTotal > totalBefore || hasUploadSession) {
        _publishTaskBarState();
      }
    } catch (e, st) {
      debugPrint('MPHomeAudioTaskQueue: seedPendingUploadsFromLocal failed: $e\n$st');
    }
  }

  /// 上传管理器：单文件进度（0–100）。
  void notifyUploadProgressForRecord(MPAudioLocalRecord record, int progress) {
    final String key = _uploadKeyForRecord(record);
    if (!_uploadSessionKeys.contains(key)) {
      return;
    }
    _uploadProgressPercent = progress.clamp(0, 100);
    _publishTaskBarState();
  }

  /// 上传管理器：单文件处理结束（成功 / 失败 / 跳过）。
  void notifyUploadFileFinished(MPAudioLocalRecord record) {
    final String key = _uploadKeyForRecord(record);
    if (!_uploadSessionKeys.contains(key)) {
      debugPrint('MPHomeAudioTaskQueue: upload finished but key not in session (ignored): $key');
      return;
    }
    _uploadCompleted++;
    debugPrint(
      'MPHomeAudioTaskQueue: upload finished $key, completed=$_uploadCompleted/$_uploadTotal',
    );
    final bool isLast = _uploadCompleted >= _uploadTotal;
    _publishTaskBarState(finishedLastFile: isLast);
    if (_uploadCompleted >= _uploadTotal) {
      _scheduleUploadSessionReset();
    }
  }

  /// upload manager worker 空闲时再次尝试结束会话（最后一条 [notifyUploadFileFinished] 时 worker 可能仍在运行）。
  void onUploadManagerBecameIdle() {
    if (_uploadTotal <= 0) {
      return;
    }
    if (_uploadCompleted >= _uploadTotal) {
      _scheduleUploadSessionReset();
    }
  }

  void _scheduleUploadSessionReset() {
    _uploadSessionClearTimer?.cancel();
    _uploadSessionClearTimer = Timer(const Duration(milliseconds: 1600), () {
      if (_uploadTotal <= 0) {
        return;
      }
      if (_uploadCompleted >= _uploadTotal && !MPAudioUploadManager.instance.hasActiveUploads) {
        _resetUploadSession();
        return;
      }
      if (_uploadCompleted >= _uploadTotal) {
        _scheduleUploadSessionReset();
      }
    });
  }

  Future<void> _enqueueUploadRecord(
    MPAudioLocalRecord record, {
    String? source,
    required bool rightNowTranscribe,
  }) async {
    final String key = _uploadKeyForRecord(record);
    if (_uploadSessionKeys.contains(key)) {
      debugPrint('MPHomeAudioTaskQueue: skip duplicate upload enqueue $key');
      return;
    }

    if (MPAudioUploadManager.instance.isPathQueuedOrUploading(record)) {
      debugPrint('MPHomeAudioTaskQueue: path already in upload manager $key');
      return;
    }

    // 必须先登记 session，再 await 入队：worker 异步启动后可能立刻回调进度/完成。
    _uploadSessionKeys.add(key);
    _uploadTotal++;
    _uploadProgressPercent = 0;
    debugPrint('MPHomeAudioTaskQueue: reserve upload slot $key, total=$_uploadTotal');

    final int enqueuedCount = await MPAudioUploadManager.instance.uploadRecordsReturningEnqueuedCount(
      <MPAudioLocalRecord>[record],
      rightNowTranscribe: rightNowTranscribe,
      source: source,
    );

    if (enqueuedCount <= 0 && !MPAudioUploadManager.instance.isPathQueuedOrUploading(record)) {
      debugPrint('MPHomeAudioTaskQueue: upload manager rejected $key, rollback session');
      _uploadSessionKeys.remove(key);
      _uploadTotal--;
      if (_uploadTotal < 0) {
        _uploadTotal = 0;
      }
    } else {
      debugPrint('MPHomeAudioTaskQueue: enqueued $key count=$enqueuedCount total=$_uploadTotal');
    }
  }

  void _resetUploadSession() {
    debugPrint('MPHomeAudioTaskQueue: reset upload session');
    _uploadSessionClearTimer?.cancel();
    _uploadSessionClearTimer = null;
    _uploadSessionKeys.clear();
    _uploadTotal = 0;
    _uploadCompleted = 0;
    _uploadProgressPercent = 0;
    MPHomeNotification.notifyAudioTaskBar(
      const MPHomeAudioTaskBarPayload(kind: MPHomeAudioTaskBarKind.clear),
    );
  }

  /// 将已落库但未入 upload 队列的记录补入（如 BLE import 中断连）。
  Future<void> enqueueImportedRecordsForUpload(List<MPAudioLocalRecord> records) async {
    for (final MPAudioLocalRecord record in records) {
      await _enqueueUploadRecord(record, rightNowTranscribe: false);
    }
    _publishTaskBarState();
  }

  void _publishTaskBarState({bool finishedLastFile = false}) {
    if (hasImportTasks) {
      MPHomeNotification.notifyAudioTaskBar(
        MPHomeAudioTaskBarPayload(
          kind: MPHomeAudioTaskBarKind.importing,
          currentFile: _importFileIndex < 1 ? 1 : _importFileIndex,
          totalFiles: _importFileTotal < 1 ? 1 : _importFileTotal,
          progress: _importProgressPercent,
        ),
      );
      return;
    }

    if (!hasUploadSession) {
      if (!finishedLastFile) {
        MPHomeNotification.notifyAudioTaskBar(
          const MPHomeAudioTaskBarPayload(kind: MPHomeAudioTaskBarKind.clear),
        );
      }
      return;
    }

    final int total = _uploadTotal < 1 ? 1 : _uploadTotal;
    final int completed = _uploadCompleted.clamp(0, total);
    final bool uploading = MPAudioUploadManager.instance.hasActiveUploads;
    final int current = completed < total ? (completed + 1).clamp(1, total) : total;
    final int progress = finishedLastFile || (!uploading && completed >= total) ? 100 : _uploadProgressPercent;

    MPHomeNotification.notifyAudioTaskBar(
      MPHomeAudioTaskBarPayload(
        kind: MPHomeAudioTaskBarKind.syncing,
        currentFile: current,
        totalFiles: total,
        progress: progress,
        scheduleClearAfterDisplay: finishedLastFile && completed >= total,
      ),
    );
    _kickStuckUploadsIfNeeded();
  }

  /// upload 会话未完成但 manager 空闲时，补传未入队的记录。
  void _kickStuckUploadsIfNeeded() {
    if (hasImportTasks || !hasUploadSession) {
      return;
    }
    if (_uploadCompleted >= _uploadTotal) {
      return;
    }
    if (MPAudioUploadManager.instance.hasActiveUploads) {
      return;
    }
    unawaited(_retryUnfinishedUploads());
  }

  Future<void> _retryUnfinishedUploads() async {
    if (_retryUnfinishedUploadsRunning) {
      return;
    }
    _retryUnfinishedUploadsRunning = true;
    try {
      debugPrint('MPHomeAudioTaskQueue: retry unfinished uploads completed=$_uploadCompleted total=$_uploadTotal');
      final List<MPAudioLocalRecord> records = await MPAudioLocalRecordsUtil.instance.queryAll(includeRemoved: false);
      for (final MPAudioLocalRecord record in records) {
        if (record.isRemoved || !MPAudioUploadManager.isUploadableAudioRecord(record)) {
          continue;
        }
        final String key = _uploadKeyForRecord(record);
        if (!_uploadSessionKeys.contains(key)) {
          continue;
        }
        if (MPAudioUploadManager.instance.isPathQueuedOrUploading(record)) {
          continue;
        }
        final int enqueued = await MPAudioUploadManager.instance.uploadRecordsReturningEnqueuedCount(
          <MPAudioLocalRecord>[record],
          source: record.source,
          rightNowTranscribe: false,
        );
        debugPrint('MPHomeAudioTaskQueue: retry enqueue $key count=$enqueued');
      }
    } catch (e, st) {
      debugPrint('MPHomeAudioTaskQueue: retry unfinished uploads failed: $e\n$st');
    } finally {
      _retryUnfinishedUploadsRunning = false;
    }
  }

  static String _uploadKeyForRecord(MPAudioLocalRecord record) {
    final String? mp3 = record.mp3Path?.trim();
    if (mp3 != null && mp3.isNotEmpty) {
      return p.normalize(mp3);
    }
    return p.normalize(record.path);
  }
}
