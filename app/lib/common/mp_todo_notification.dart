import 'dart:async';

/// Todo 模块事件通知：统一在此维护 **key**，业务侧监听 [events] 并按 key 分支处理。
class MPTodoNotification {
  MPTodoNotification._();

  // ---------------------------------------------------------------------------
  // Keys（订阅方请与下列常量比对，避免手写魔法字符串）
  // ---------------------------------------------------------------------------

  /// Todo 已通过创建接口成功落库（或接口返回 code == 0）
  static const String keyTodoCreated = 'mp_todo_created';

  // ---------------------------------------------------------------------------

  static final StreamController<String> _bus =
      StreamController<String>.broadcast();

  /// Todo 相关事件流，载荷为与上方静态 key 一致的字符串。
  static Stream<String> get events => _bus.stream;

  static void _emit(String key) {
    if (!_bus.isClosed) {
      _bus.add(key);
    }
  }

  /// 创建 Todo 成功后调用，派发 [keyTodoCreated]。
  static void notifyTodoCreated() => _emit(keyTodoCreated);

  /// 接收「Todo 创建成功」通知。
  ///
  /// 返回 [StreamSubscription]，请在页面/Cubit 销毁时调用 [StreamSubscription.cancel]，
  /// 避免泄漏（例如在 `State.dispose` 或 Cubit `close` 里保存并 cancel）。
  static StreamSubscription<String> listenTodoCreated(
    void Function() onTodoCreated,
  ) {
    return events
        .where((key) => key == keyTodoCreated)
        .listen((_) => onTodoCreated());
  }
}
