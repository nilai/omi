/// Add / Edit Todo 底部弹层互斥：同一时刻至多展示一个（含 add 与 edit 之间）。
class MPTodoPopupGuard {
  MPTodoPopupGuard._();

  static bool _isShowing = false;

  /// 已有弹层展示中时返回 `false`。
  static bool tryAcquire() {
    if (_isShowing) {
      return false;
    }
    _isShowing = true;
    return true;
  }

  static void release() {
    _isShowing = false;
  }
}
