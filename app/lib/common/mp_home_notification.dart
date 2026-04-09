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

  static Stream<void> get homeRefreshEvents => _homeRefreshBus.stream;
  static Stream<MPHomeUploadProgressPayload> get uploadProgressEvents =>
      _uploadProgressBus.stream;
  static Stream<MPHomeRecordCreatedPayload> get recordCreatedEvents =>
      _recordCreatedBus.stream;
  static Stream<MPHomeTodoDonePayload> get todoDoneEvents =>
      _todoDoneBus.stream;
  static Stream<MPHomeTodoDeletedPayload> get todoDeletedEvents =>
      _todoDeletedBus.stream;

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
}
