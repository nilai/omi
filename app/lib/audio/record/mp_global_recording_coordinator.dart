/// 全局麦克风录音仲裁：任意入口即将「独占」录音前，先暂停其它持有者；
/// 被暂停的一侧仅能通过用户在本场景的后续手势恢复，不会自动抢回麦克风。
class MPGlobalRecordingCoordinator {
  MPGlobalRecordingCoordinator._();

  /// 单例。
  static final MPGlobalRecordingCoordinator instance =
      MPGlobalRecordingCoordinator._();

  final Map<Object, Future<void> Function()> _interruptHandlers =
      <Object, Future<void> Function()>{};

  /// 系统音频焦点变化时尝试维持采集（与 [registerSystemAudioMaintainHandler] 配对）。
  final Map<Object, Future<void> Function()> _systemAudioMaintainHandlers =
      <Object, Future<void> Function()>{};

  /// 外接 BLE 设备进入「录音中」时：暂停本机采集等（与 [registerBleDeviceRecordingStopHandler] 配对）。
  final Map<Object, Future<void> Function()> _bleDeviceRecordingStopHandlers =
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

  /// 注册：当外接设备开始录音 [notifyBleDeviceRecordingStarted] 时回调（须 [unregisterBleDeviceRecordingStopHandler]）。
  void registerBleDeviceRecordingStopHandler(
    Object token,
    Future<void> Function() onBleDeviceRecordingStarted,
  ) {
    _bleDeviceRecordingStopHandlers[token] = onBleDeviceRecordingStarted;
  }

  /// 解除 [registerBleDeviceRecordingStopHandler]。
  void unregisterBleDeviceRecordingStopHandler(Object token) {
    _bleDeviceRecordingStopHandlers.remove(token);
  }

  /// 外接设备已开始录音：执行已注册的回调（一般为暂停本机采集，不结束会话）。
  ///
  /// 不清除 [_exclusiveOwner]：本机弹窗仍持有会话，仅采集被暂停。
  Future<void> notifyBleDeviceRecordingStarted() async {
    for (final MapEntry<Object, Future<void> Function()> e
        in _bleDeviceRecordingStopHandlers.entries) {
      await _safeInterrupt(e.value);
    }
  }

  /// 注册系统音频焦点变化时的维持采集回调；页面 / 组件 [dispose] 前须 [unregisterSystemAudioMaintainHandler]。
  void registerSystemAudioMaintainHandler(
    Object ownerToken,
    Future<void> Function() onSystemAudioFocusAttemptMaintain,
  ) {
    _systemAudioMaintainHandlers[ownerToken] =
        onSystemAudioFocusAttemptMaintain;
  }

  /// 解除 [registerSystemAudioMaintainHandler]。
  void unregisterSystemAudioMaintainHandler(Object ownerToken) {
    _systemAudioMaintainHandlers.remove(ownerToken);
  }

  /// 解除注册。
  void unregister(Object ownerToken) {
    _interruptHandlers.remove(ownerToken);
    _systemAudioMaintainHandlers.remove(ownerToken);
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

  /// 系统音频焦点被抢占或恢复时调用：通知当前独占持有者尝试维持/恢复采集（不主动暂停）。
  Future<void> notifySystemAudioFocusAttemptMaintainRecording() async {
    if (_exclusiveOwner == null) {
      return;
    }
    final Future<void> Function()? fn =
        _systemAudioMaintainHandlers[_exclusiveOwner];
    if (fn == null) {
      return;
    }
    await _safeInterrupt(fn);
  }
}
