import 'dart:async';

/// 上传过程中广播的进度（供首页状态条订阅）。
class MPHomeUploadProgressPayload {
  const MPHomeUploadProgressPayload({
    required this.batchTotal,
    required this.batchIndex,
    required this.progress,
  });

  final int batchTotal;
  final int batchIndex;
  final int progress;
}

/// 本地录音上传并创建 record 成功后的首页通知载荷。
class MPHomeRecordCreatedPayload {
  const MPHomeRecordCreatedPayload({
    required this.memoryId,
    this.batchTotal = 1,
    this.batchIndex = 1,
  });

  final String memoryId;
  final int batchTotal;
  final int batchIndex;
}

/// Todo 完成通知载荷。
class MPHomeTodoDonePayload {
  const MPHomeTodoDonePayload({
    required this.todoId,
  });

  final String todoId;
}

/// Todo 删除通知载荷。
class MPHomeTodoDeletedPayload {
  const MPHomeTodoDeletedPayload({
    required this.todoId,
  });

  final String todoId;
}

/// MemoPin 设备录音状态变化原因（与 [MPBleMemopinRecordingStateChangedPayload.changeReason] 对应）。
enum MPBleMemopinRecordingChangeReason {
  /// 303 开始录音成功。
  deviceRecordingStarted,

  /// 303 结束录音成功。
  deviceRecordingStopped,

  /// BLE [MPDeviceTransportState.disconnected]。
  bleDisconnected,

  /// [MPBleRecordingWatcher.detach] / 释放背景会话。
  watcherDetached,
}

/// MemoPin 设备录音状态变化（供 UI / 业务订阅）。
class MPBleMemopinRecordingStateChangedPayload {
  /// 创建载荷。
  const MPBleMemopinRecordingStateChangedPayload({
    required this.isRecording,
    this.activeFileName,
    this.sessionModeByte,
    this.changeReason,
    this.lastRealtimeAudioLocalPath,
  });

  /// `true` 表示正在录音。
  final bool isRecording;

  /// 当前录音文件名（未录音时多为 `null`）。
  final String? activeFileName;

  /// 最近一次 `0x01` 成功通知中的 mode：`0x00` memory / `0x01` memo；未知为 `null`。
  final int? sessionModeByte;

  /// 本次状态变化触发原因；快照读取时可为 `null`（仅表示「当前态」，不强调事件）。
  final MPBleMemopinRecordingChangeReason? changeReason;

  /// 最近一次关闭实时落盘后的本地 `.opus` 路径（停止 / 断连 / detach 后仍可读）。
  final String? lastRealtimeAudioLocalPath;
}

/// 首页事件通知：用于跨页面触发首页数据刷新。
class MPHomeNotification {
  MPHomeNotification._();

  static final StreamController<void> _homeRefreshBus =
      StreamController<void>.broadcast();
  static final StreamController<MPHomeUploadProgressPayload> _uploadProgressBus =
      StreamController<MPHomeUploadProgressPayload>.broadcast();
  static final StreamController<MPHomeRecordCreatedPayload> _recordCreatedBus =
      StreamController<MPHomeRecordCreatedPayload>.broadcast();
  static final StreamController<MPHomeTodoDonePayload> _todoDoneBus =
      StreamController<MPHomeTodoDonePayload>.broadcast();
  static final StreamController<MPHomeTodoDeletedPayload> _todoDeletedBus =
      StreamController<MPHomeTodoDeletedPayload>.broadcast();
  static final StreamController<void> _bleConnectedSuccessBus =
      StreamController<void>.broadcast();
  static final StreamController<void> _bleDisconnectedBus =
      StreamController<void>.broadcast();
  static final StreamController<MPBleMemopinRecordingStateChangedPayload> _bleMemopinRecordingBus =
      StreamController<MPBleMemopinRecordingStateChangedPayload>.broadcast();

  static Stream<void> get homeRefreshEvents => _homeRefreshBus.stream;
  static Stream<MPHomeUploadProgressPayload> get uploadProgressEvents =>
      _uploadProgressBus.stream;
  static Stream<MPHomeRecordCreatedPayload> get recordCreatedEvents =>
      _recordCreatedBus.stream;
  static Stream<MPHomeTodoDonePayload> get todoDoneEvents =>
      _todoDoneBus.stream;
  static Stream<MPHomeTodoDeletedPayload> get todoDeletedEvents =>
      _todoDeletedBus.stream;
  static Stream<void> get bleConnectedSuccessEvents =>
      _bleConnectedSuccessBus.stream;
  static Stream<void> get bleDisconnectedEvents => _bleDisconnectedBus.stream;
  static Stream<MPBleMemopinRecordingStateChangedPayload> get bleMemopinRecordingStateEvents =>
      _bleMemopinRecordingBus.stream;

  static void _emitHomeRefresh() {
    if (!_homeRefreshBus.isClosed) {
      _homeRefreshBus.add(null);
    }
  }

  static void _emitUploadProgress(MPHomeUploadProgressPayload payload) {
    if (!_uploadProgressBus.isClosed) {
      _uploadProgressBus.add(payload);
    }
  }

  static void _emitRecordCreated(MPHomeRecordCreatedPayload payload) {
    if (!_recordCreatedBus.isClosed) {
      _recordCreatedBus.add(payload);
    }
  }

  static void _emitTodoDone(MPHomeTodoDonePayload payload) {
    if (!_todoDoneBus.isClosed) {
      _todoDoneBus.add(payload);
    }
  }

  static void _emitTodoDeleted(MPHomeTodoDeletedPayload payload) {
    if (!_todoDeletedBus.isClosed) {
      _todoDeletedBus.add(payload);
    }
  }

  static void _emitBleConnectedSuccess() {
    if (!_bleConnectedSuccessBus.isClosed) {
      _bleConnectedSuccessBus.add(null);
    }
  }

  static void _emitBleDisconnected() {
    if (!_bleDisconnectedBus.isClosed) {
      _bleDisconnectedBus.add(null);
    }
  }

  static void _emitBleMemopinRecordingState(MPBleMemopinRecordingStateChangedPayload payload) {
    if (!_bleMemopinRecordingBus.isClosed) {
      _bleMemopinRecordingBus.add(payload);
    }
  }

  /// 任意页面主动调用：通知首页刷新列表数据。
  static void notifyHomeListRefresh() => _emitHomeRefresh();

  /// 上传侧调用：通知首页更新「同步进度」状态条。
  static void notifyUploadProgress(MPHomeUploadProgressPayload payload) =>
      _emitUploadProgress(payload);

  /// 上传侧调用：通知首页某条 record 已创建完成。
  static void notifyRecordCreated(MPHomeRecordCreatedPayload payload) =>
      _emitRecordCreated(payload);

  /// Todo 操作调用：通知首页某条 todo 已完成。
  static void notifyTodoDone(MPHomeTodoDonePayload payload) =>
      _emitTodoDone(payload);

  /// Todo 操作调用：通知首页某条 todo 已删除。
  static void notifyTodoDeleted(MPHomeTodoDeletedPayload payload) =>
      _emitTodoDeleted(payload);

  /// MemoPin 录音状态监听：在 [MPBleConnectionHelper] 检测到与上次不同后发出。
  static void notifyBleMemopinRecordingStateChanged(MPBleMemopinRecordingStateChangedPayload payload) =>
      _emitBleMemopinRecordingState(payload);

  /// BLE 与其它入口在 **连接成功并可使用 GATT** 后调用：首页订阅以触发设备文件导入等。
  static void notifyBleConnectedSuccess() => _emitBleConnectedSuccess();

  /// 用户主动断开、释放背景会话或设备被动掉线后调用：首页收起 BLE 相关顶栏状态。
  static void notifyBleDisconnected() => _emitBleDisconnected();

  /// 首页监听：收到后执行 `loadData` 刷新。
  static StreamSubscription<void> listenHomeListRefresh(
    void Function() onRefresh,
  ) {
    return homeRefreshEvents.listen((_) => onRefresh());
  }

  /// 首页监听上传进度。
  static StreamSubscription<MPHomeUploadProgressPayload> listenUploadProgress(
    void Function(MPHomeUploadProgressPayload payload) onProgress,
  ) {
    return uploadProgressEvents.listen(onProgress);
  }

  /// 首页监听创建完成事件。
  static StreamSubscription<MPHomeRecordCreatedPayload> listenRecordCreated(
    void Function(MPHomeRecordCreatedPayload payload) onCreated,
  ) {
    return recordCreatedEvents.listen(onCreated);
  }

  /// 首页监听 Todo 完成事件。
  static StreamSubscription<MPHomeTodoDonePayload> listenTodoDone(
    void Function(MPHomeTodoDonePayload payload) onDone,
  ) {
    return todoDoneEvents.listen(onDone);
  }

  /// 首页监听 Todo 删除事件。
  static StreamSubscription<MPHomeTodoDeletedPayload> listenTodoDeleted(
    void Function(MPHomeTodoDeletedPayload payload) onDeleted,
  ) {
    return todoDeletedEvents.listen(onDeleted);
  }

  /// 首页监听：MemoPin 类设备 BLE 连接成功（背景会话已就绪）。
  static StreamSubscription<void> listenBleConnectedSuccess(
    void Function() onBleConnected,
  ) {
    return bleConnectedSuccessEvents.listen((_) => onBleConnected());
  }

  /// 首页监听：MemoPin BLE 已断开（主动断开或链路丢失）。
  static StreamSubscription<void> listenBleDisconnected(
    void Function() onBleDisconnected,
  ) {
    return bleDisconnectedEvents.listen((_) => onBleDisconnected());
  }

  /// 监听 MemoPin 录音中 / 空闲状态变化。
  static StreamSubscription<MPBleMemopinRecordingStateChangedPayload> listenBleMemopinRecordingState(
    void Function(MPBleMemopinRecordingStateChangedPayload payload) onState,
  ) {
    return bleMemopinRecordingStateEvents.listen(onState);
  }
}
