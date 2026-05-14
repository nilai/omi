/// 全局麦克风录音仲裁：任意入口即将「独占」录音前，先暂停其它持有者；
/// 被暂停的一侧仅能通过用户在本场景的后续手势恢复，不会自动抢回麦克风。
class MPGlobalRecordingCoordinator {
  MPGlobalRecordingCoordinator._();

  /// 单例。
  static final MPGlobalRecordingCoordinator instance =
      MPGlobalRecordingCoordinator._();

  final Map<Object, Future<void> Function()> _interruptHandlers =
      <Object, Future<void> Function()>{};

  Object? _exclusiveOwner;

  /// 注册可被中断的持有者；页面 / 组件 [dispose] 前必须 [unregister]。
  ///
  /// [onInterruptedByOtherOwner]：收到新开录音抢占时应暂停本侧录音并更新 UI（勿释放整个会话）。
  void register(
    Object ownerToken,
    Future<void> Function() onInterruptedByOtherOwner,
  ) {
    _interruptHandlers[ownerToken] = onInterruptedByOtherOwner;
  }

  /// 解除注册。
  void unregister(Object ownerToken) {
    _interruptHandlers.remove(ownerToken);
    if (_exclusiveOwner == ownerToken) {
      _exclusiveOwner = null;
    }
  }

  /// 在本持有者 [startRecorder] / [resumeRecorder] 之前调用，会先暂停其它持有者。
  Future<void> beforeLocalRecordingStarts(Object ownerToken) async {
    final List<Future<void>> pending = <Future<void>>[];
    for (final MapEntry<Object, Future<void> Function()> e
        in _interruptHandlers.entries) {
      if (e.key != ownerToken) {
        pending.add(_safeInterrupt(e.value));
      }
    }
    await Future.wait(pending);
    _exclusiveOwner = ownerToken;
  }

  Future<void> _safeInterrupt(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (_) {}
  }

  /// 本持有者的录音会话已完全结束（停止、取消、成功保存、界面销毁等）。
  void notifyRecordingSessionEnded(Object ownerToken) {
    if (_exclusiveOwner == ownerToken) {
      _exclusiveOwner = null;
    }
  }

  /// 系统音频焦点被抢占（来电、其它 App 播放等）时调用：仅暂停当前独占持有者的采集，
  /// 行为与各入口注册的「被其它录音入口中断」一致，用户可在本场景手动恢复。
  Future<void> notifySystemAudioFocusShouldPauseCurrentRecording() async {
    if (_exclusiveOwner == null) {
      return;
    }
    final Future<void> Function()? fn = _interruptHandlers[_exclusiveOwner];
    if (fn == null) {
      return;
    }
    await _safeInterrupt(fn);
  }
}
