import 'dart:async';

/// 上传过程中广播的进度（供首页等订阅；与录音弹窗 [onPerFileProgress] 同源）。
class MPMemoryRecordUploadProgressPayload {
  const MPMemoryRecordUploadProgressPayload({
    required this.batchTotal,
    required this.batchIndex,
    required this.progress,
  });

  final int batchTotal;
  final int batchIndex;

  /// 当前第 [batchIndex] 条文件自身进度 0–100
  final int progress;
}

/// 本地录音上传并创建 record 成功后的通知载荷。
class MPMemoryRecordCreatedPayload {
  const MPMemoryRecordCreatedPayload({required this.memoryId, this.batchTotal = 1, this.batchIndex = 1});

  /// 新建记录对应的 `memory_id`。
  final String memoryId;

  /// 本批上传文件总数（≥1）。单文件时为 1。
  final int batchTotal;

  /// 当前刚完成的是第几个（1-based，≤ [batchTotal]）。
  final int batchIndex;
}

/// Memory 模块事件通知：录音创建 record 成功后派发，列表/详情可订阅并刷新。
class MPMemoryNotification {
  MPMemoryNotification._();

  static final StreamController<MPMemoryRecordCreatedPayload> _bus =
      StreamController<MPMemoryRecordCreatedPayload>.broadcast();

  static final StreamController<MPMemoryRecordUploadProgressPayload> _progressBus =
      StreamController<MPMemoryRecordUploadProgressPayload>.broadcast();

  /// 首页等完成同步/上传收口后广播，用于 Memory 列表拉取最新数据（无载荷，与 [MPHomeNotification.homeRefreshEvents] 解耦页面）。
  static final StreamController<void> _memoryListRefreshBus = StreamController<void>.broadcast();

  static Stream<MPMemoryRecordCreatedPayload> get events => _bus.stream;

  static Stream<MPMemoryRecordUploadProgressPayload> get progressEvents => _progressBus.stream;

  static Stream<void> get memoryListRefreshEvents => _memoryListRefreshBus.stream;

  static void _emit(MPMemoryRecordCreatedPayload payload) {
    if (!_bus.isClosed) {
      _bus.add(payload);
    }
  }

  static void _emitProgress(MPMemoryRecordUploadProgressPayload payload) {
    if (!_progressBus.isClosed) {
      _progressBus.add(payload);
    }
  }

  static void _emitMemoryListRefresh() {
    if (!_memoryListRefreshBus.isClosed) {
      _memoryListRefreshBus.add(null);
    }
  }

  /// 与 [MPAudioUploadManager] 内上报的进度一致（非 UI 模拟，仅转发）。
  static void notifyUploadProgress(MPMemoryRecordUploadProgressPayload payload) => _emitProgress(payload);

  /// [createRecord]（及可选 [summaryRecord]）全部成功后调用。
  static void notifyMemoryRecordCreated(MPMemoryRecordCreatedPayload payload) => _emit(payload);

  /// 首页上传/同步批次全部完成并触发 [MPHomeCubit.loadData] 收口时调用，通知 Memory 列表刷新。
  static void notifyMemoryListRefresh() => _emitMemoryListRefresh();

  /// 监听「需要刷新 Memory 列表（与首页数据收口对齐）」。
  ///
  /// 返回 [StreamSubscription]，请在 State [dispose] 或 Cubit [close] 里 [cancel]。
  static StreamSubscription<void> listenMemoryListRefresh(void Function() onRefresh) {
    return memoryListRefreshEvents.listen((_) => onRefresh());
  }

  /// 监听「本地录音上传并创建 record 成功」。
  ///
  /// 返回 [StreamSubscription]，请在 Cubit [close] 或 State [dispose] 里 [cancel]。
  static StreamSubscription<MPMemoryRecordCreatedPayload> listenMemoryRecordCreated(
    void Function(MPMemoryRecordCreatedPayload payload) onCreated,
  ) {
    return events.listen(onCreated);
  }

  static StreamSubscription<MPMemoryRecordUploadProgressPayload> listenUploadProgress(
    void Function(MPMemoryRecordUploadProgressPayload payload) onProgress,
  ) {
    return progressEvents.listen(onProgress);
  }
}
