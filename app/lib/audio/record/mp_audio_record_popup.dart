import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memo_pin/audio/record/mp_native_recorder.dart';
import 'package:memo_pin/audio/record/mp_global_recording_coordinator.dart';
import 'package:memo_pin/audio/record/mp_audio_local_records_util.dart';
import 'package:memo_pin/audio/record/mp_recording_background_support.dart';
import 'package:memo_pin/audio/record/mp_recording_session_native.dart';
import 'package:memo_pin/audio/record/mp_home_audio_task_queue.dart';
import 'package:memo_pin/blu/mp_ble_connection_helper.dart';
import 'package:memo_pin/permission/omi_microphone_manager.dart';
import 'package:memo_pin/utils/mp_time_utils.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 录音结束并保存后的结果（临时文件路径 + 时长）。
class MPAudioRecordResult {
  const MPAudioRecordResult({required this.filePath, required this.duration});

  final String filePath;
  final Duration duration;
}

/// 模态路由默认会插入全屏 [ModalBarrier]，即便透明也会拦截点击；覆盖为不参与命中，下层页面才可操作。
class MPPassThroughBarrierDialogRoute extends RawDialogRoute<MPAudioRecordResult?> {
  MPPassThroughBarrierDialogRoute({required super.pageBuilder, required String super.barrierLabel})
    : super(
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 200),
      );

  @override
  Widget buildModalBarrier() {
    return const IgnorePointer(ignoring: true, child: SizedBox.shrink());
  }
}

/// 展示「Record Audio」流程弹窗：引导 → 计时录音 →（取消时）确认；录音中可最小化为底部胶囊条继续录。
///
/// 返回 [MPAudioRecordResult] 表示用户点击 Save；取消或关闭为 `null`。
Future<MPAudioRecordResult?> showMPAudioRecordPopup(BuildContext context) async {
  if (await MPBleConnectionHelper.showBlockMessageIfMemoPinDeviceIsRecording(context: context)) {
    return null;
  }
  if (!context.mounted) {
    return null;
  }
  final NavigatorState rootNavigator = Navigator.of(context, rootNavigator: true);
  final String barrierLabel = MaterialLocalizations.of(context).modalBarrierDismissLabel;
  return rootNavigator.push<MPAudioRecordResult?>(
    MPPassThroughBarrierDialogRoute(
      barrierLabel: barrierLabel,
      pageBuilder: (BuildContext context, Animation<double> a1, Animation<double> a2) {
        return _MPAudioRecordDialog(rootNavigator: rootNavigator);
      },
    ),
  );
}

enum _MPAudioRecordStep {
  /// 蓝色麦克风，点击开始
  intro,

  /// 计时 + 暂停/继续 + Cancel / Save
  recording,
}

class _MPAudioRecordDialog extends StatefulWidget {
  const _MPAudioRecordDialog({required this.rootNavigator});

  final NavigatorState rootNavigator;

  @override
  State<_MPAudioRecordDialog> createState() => _MPAudioRecordDialogState();
}

class _MPAudioRecordDialogState extends State<_MPAudioRecordDialog>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// 全局录音仲裁持有者标识。
  late final Object _recordingOwnerToken;
  final Object _bleDeviceRecordingStopToken = Object();
  final Object _playbackPauseToken = Object();

  static const Color _kBlue = Color(0xFF007AFF);
  static const Color _kGreyCircleBg = Color(0xFFE8E8E8);
  static const Color _kCancelSheetBg = Color(0xFFF2F2F7);
  static const Color _kWaveGreen = Color(0xFF34C759);
  static const String _kMicBlockedStartMessage =
      'Cannot start recording while a call or another app is using the microphone.';
  static const String _kMicBlockedResumeMessage =
      'Cannot resume recording while a call or another app is using the microphone.';

  _MPAudioRecordStep _step = _MPAudioRecordStep.intro;

  /// 盖在「录音态」上的取消确认层
  bool _showCancelConfirm = false;

  /// `true` 时隐藏大卡与遮罩，仅保留底部胶囊条；录音不中断。
  bool _minimized = false;

  late final AnimationController _waveController;

  final MPNativeRecorder _nativeRecorder = MPNativeRecorder();
  bool _nativeRecorderOpen = false;

  /// 每次 open/释放递增，用于丢弃 Save/Close 进行中的 resume 请求。
  int _recorderSessionId = 0;

  String? _recordPath;

  /// UI 展示的录音时长（来自原生/文件，非墙钟计时）。
  Duration _displayDuration = Duration.zero;
  int _displayDurationSeconds = 0;

  bool _isPaused = false;

  /// 是否因系统打断（腾讯会议/来电等）而暂停。
  bool _pausedBySystemInterruption = false;

  StreamSubscription<MPNativeRecorderEvent>? _nativeRecorderEventsSub;
  int _watchdogTick = 0;

  Timer? _tickTimer;

  /// 最小化胶囊条位置（首次最小化时根据安全区初始化）。
  double? _pillLeft;
  double? _pillBottom;

  bool _busy = false;

  /// 首次 Save 已 finalize 并 close recorder；重试时不再重复 finalize。
  bool _saveRecorderFinalized = false;

  /// finalize 后的临时 AAC（供 Save 重试）。
  String? _finalizedTempAacPath;

  /// 已复制到本地存储的 AAC（供 Save 重试）。
  String? _pendingPersistedAacPath;

  /// 上传阶段进度（`null` 表示未在上传）；由 [MPAudioUploadManager.uploadLocalRecord] 的 [onPerFileProgress] 更新。
  // int? _uploadProgressPct;
  int _uploadBatchIndex = 1;
  int _uploadBatchTotal = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recordingOwnerToken = Object();
    MPGlobalRecordingCoordinator.instance.register(
      _recordingOwnerToken,
      _onInterruptedByOtherOwner,
    );
    MPGlobalRecordingCoordinator.instance.registerMixModeInterruptionHandler(
      _recordingOwnerToken,
      onInterruptionBegan: _onMixModeSystemInterruptionBegan,
      onInterruptionEnded: _onMixModeSystemInterruptionEnded,
    );
    _nativeRecorderEventsSub = _nativeRecorder.recordingEvents.listen(_onNativeRecorderEvent);
    MPGlobalRecordingCoordinator.instance.registerBleDeviceRecordingStopHandler(
      _bleDeviceRecordingStopToken,
      _onBleDeviceRecordingStartedPauseLocal,
    );
    MPGlobalRecordingCoordinator.instance.registerPlaybackPauseHandler(
      _playbackPauseToken,
      _onExternalPlaybackStartedPauseLocal,
    );
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waveController.stop();
    _waveController.dispose();
    _tickTimer?.cancel();
    unawaited(_nativeRecorderEventsSub?.cancel());
    unawaited(_releaseRecorder(deleteFile: true));
    MPGlobalRecordingCoordinator.instance.unregisterMixModeInterruptionHandler(_recordingOwnerToken);
    MPGlobalRecordingCoordinator.instance.unregisterBleDeviceRecordingStopHandler(_bleDeviceRecordingStopToken);
    MPGlobalRecordingCoordinator.instance.unregisterPlaybackPauseHandler(_playbackPauseToken);
    MPGlobalRecordingCoordinator.instance.unregister(_recordingOwnerToken);
    super.dispose();
  }

  Future<void> _releaseRecorder({required bool deleteFile}) async {
    _tickTimer?.cancel();
    _tickTimer = null;
    _recorderSessionId++;
    final bool wasOpen = _nativeRecorderOpen;
    _nativeRecorderOpen = false;
    _isPaused = false;
    if (wasOpen) {
      try {
        if (_recordPath != null) {
          await _nativeRecorder.pauseSegment();
        }
      } catch (_) {}
      try {
        await _nativeRecorder.close();
      } catch (_) {}
    }
    if (deleteFile && _recordPath != null) {
      try {
        final File f = File(_recordPath!);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }
    _recordPath = null;
    _displayDuration = Duration.zero;
    _displayDurationSeconds = 0;
    if (deleteFile) {
      unawaited(_clearSavePendingAudioFiles());
    } else {
      _resetSavePendingState();
    }
    await MPRecordingBackgroundSupport.deactivateAfterRecording(owner: _recordingOwnerToken);
    MPGlobalRecordingCoordinator.instance
        .notifyRecordingSessionEnded(_recordingOwnerToken);
  }

  /// 详情页等开始播放音频：同步暂停 UI（原生层已由 [MPGlobalRecordingCoordinator.notifyExternalPlaybackStarted] 先暂停）。
  Future<void> _onExternalPlaybackStartedPauseLocal() async {
    if (!mounted) {
      return;
    }
    await _applyPausedUiAfterExternalPlayback();
  }

  /// 外部播放触发暂停：不检查 [_busy]，确保 UI 与原生采集状态一致。
  Future<void> _applyPausedUiAfterExternalPlayback() async {
    if (_step != _MPAudioRecordStep.recording || _recordPath == null || !_nativeRecorderOpen) {
      return;
    }
    if (_isPaused) {
      return;
    }
    final bool paused = await _pauseNativeRecording();
    if (!mounted) {
      return;
    }
    if (!paused && _nativeCapturing) {
      return;
    }
    setState(() {
      _isPaused = true;
      _nativeCapturing = false;
    });
    unawaited(_syncDisplayDurationFromFile());
  }

  /// 外接 MemoPin 开始录音：引导态仅提示；录音态则暂停本机采集（须用户手动点播放恢复，不自动续录）。
  Future<void> _onBleDeviceRecordingStartedPauseLocal() async {
    if (!mounted) {
      return;
    }
    if (_step == _MPAudioRecordStep.intro) {
      MPToastUtils.showMessage(
        MPBleConnectionHelper.memoPinDeviceRecordingBlockMessage,
        context: context,
      );
      return;
    }
    final bool didPause = await _pauseRecordingDueToExternalInterruption();
    if (!mounted) {
      return;
    }
    if (didPause) {
      MPToastUtils.showMessage(
        'MemoPin device started recording. Tap the button to resume recording on this phone.',
        context: context,
      );
    }
  }

  Future<void> _startRecorderToPath(String path) async {
    final bool started = await _nativeRecorder.start(path);
    if (!started) {
      throw StateError('Native recorder failed to start');
    }
    _nativeCapturing = true;
  }

  Future<String> _newRecordPath() async {
    final Directory dir = await getTemporaryDirectory();
    return p.join(dir.path, 'omi_focus_${MPTimeUtils.nowUnixMilliseconds()}.m4a');
  }

  /// 整段暂停（iOS [AVAudioRecorder.pause] / Android [MediaRecorder.pause]）。
  ///
  /// 来电等系统打断时 native 可能已停止采集，仍须调用 [pauseSegment] 以同步时长并标记暂停态。
  Future<bool> _pauseNativeRecording() async {
    if (!_nativeRecorderOpen || _recordPath == null) {
      return false;
    }
    try {
      final String? pausedPath = await _nativeRecorder.pauseSegment();
      if (pausedPath != null && pausedPath.isNotEmpty) {
        _recordPath = pausedPath;
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));
      _nativeCapturing = false;
      return pausedPath != null;
    } catch (e, st) {
      debugPrint('_pauseNativeRecording: $e\n$st');
      return false;
    }
  }

  /// native 是否仍在采集。
  bool _nativeCapturing = false;

  Future<bool> _isMicrophoneCaptureBlocked() => _nativeRecorder.isMicrophoneCaptureBlocked();

  /// 会议/通话结束或 App 回到前台后，重新激活会话并刷新麦克风占用状态。
  Future<bool> _prepareBeforeRecordingResume({bool reacquire = false}) async {
    final bool sessionActive;
    if (reacquire) {
      final MPRecordingBackgroundActivationResult activation =
          await MPRecordingBackgroundSupport.activateForHomeRecording(owner: _recordingOwnerToken);
      sessionActive = activation.audioSessionActive;
    } else {
      sessionActive = await MPRecordingBackgroundSupport.ensureAudioSessionActiveForRecording(
        owner: _recordingOwnerToken,
      );
    }
    if (!sessionActive) {
      return false;
    }
    await _nativeRecorder.prepareForRecordingResume();
    if (Platform.isIOS) {
      await MPRecordingSessionNative.applyMixRecordingSession();
    }
    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    unawaited(_onAppResumedDuringRecording());
  }

  Future<void> _onAppResumedDuringRecording() async {
    if (!mounted || _step != _MPAudioRecordStep.recording || !_nativeRecorderOpen) {
      return;
    }
    if (!await _prepareBeforeRecordingResume()) {
      return;
    }
    if (!mounted) {
      return;
    }
    unawaited(_syncDisplayDurationFromFile());
  }

  void _showMicrophoneBlockedMessage({required bool forResume}) {
    MPToastUtils.showMessage(
      forResume ? _kMicBlockedResumeMessage : _kMicBlockedStartMessage,
      context: context,
    );
  }

  /// 从原生/文件同步已写入时长；仅秒数变化时触发 rebuild。
  Future<void> _syncDisplayDurationFromFile() async {
    final int ms = await _nativeRecorder.currentRecordingDurationMs();
    if (!mounted) {
      return;
    }
    final int seconds = math.max(ms ~/ 1000, _displayDurationSeconds);
    if (seconds == _displayDurationSeconds) {
      return;
    }
    setState(() {
      _displayDurationSeconds = seconds;
      _displayDuration = Duration(seconds: seconds);
    });
  }

  /// 保存前解析最终文件时长。
  Future<Duration> _resolveDurationForSave(String filePath) async {
    return MPNativeRecorder.resolveFileDuration(filePath, fallback: _displayDuration);
  }

  /// 同文件 [resumeSegment] 继续录音（仅由 UI 按钮触发）。
  Future<bool> _resumeNativeRecording() async {
    if (!_nativeRecorderOpen || _recordPath == null) {
      return false;
    }
    if (await _nativeRecorder.isRecording()) {
      _nativeCapturing = true;
      return true;
    }
    if (!await _prepareBeforeRecordingResume()) {
      return false;
    }
    try {
      final bool resumed = await _nativeRecorder.resumeSegment();
      if (!resumed) {
        _nativeCapturing = false;
        return false;
      }
      _nativeCapturing = true;
      return true;
    } catch (e, st) {
      debugPrint('_resumeNativeRecording: $e\n$st');
      _nativeCapturing = false;
      return false;
    }
  }

  /// 停止采集并返回整段 m4a。
  Future<String?> _finalizeRecordingFilePath() async {
    final String outputPath = _recordPath ??
        p.join(
          (await getTemporaryDirectory()).path,
          'omi_focus_${MPTimeUtils.nowUnixMilliseconds()}.m4a',
        );
    final String? outPath = await _nativeRecorder.finish(outputPath: outputPath);
    _nativeCapturing = false;
    if (outPath != null && outPath.isNotEmpty) {
      _recordPath = outPath;
    }
    return outPath;
  }

  /// 与 [_onInterruptedByOtherOwner] 共用：暂停当前连续采集段并刷新 UI。
  Future<bool> _pauseRecordingDueToExternalInterruption() async {
    if (_busy || _step != _MPAudioRecordStep.recording || _recordPath == null || !_nativeRecorderOpen) {
      return false;
    }
    if (_isPaused) {
      return false;
    }
    setState(() => _busy = true);
    try {
      final bool paused = await _pauseNativeRecording();
      if (!mounted) {
        return false;
      }
      if (!paused && _nativeCapturing) {
        setState(() => _busy = false);
        return false;
      }
      setState(() {
        _isPaused = true;
        _busy = false;
      });
      unawaited(_syncDisplayDurationFromFile());
      return true;
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
      }
      return false;
    }
  }

  /// 系统混音打断开始：暂停计时与采集（如腾讯会议抢占麦克风）。
  Future<void> _onMixModeSystemInterruptionBegan() async {
    if (!mounted || _step != _MPAudioRecordStep.recording || _isPaused) {
      return;
    }
    _pausedBySystemInterruption = true;
    await _pauseRecordingDueToExternalInterruption();
  }

  /// 系统混音打断结束：刷新会话与计时，保持暂停，须用户手动点继续。
  Future<void> _onMixModeSystemInterruptionEnded() async {
    if (!mounted || _step != _MPAudioRecordStep.recording || !_nativeRecorderOpen) {
      return;
    }
    _pausedBySystemInterruption = false;
    if (!await _prepareBeforeRecordingResume()) {
      return;
    }
    if (!mounted) {
      return;
    }
    unawaited(_syncDisplayDurationFromFile());
  }

  void _onNativeRecorderEvent(MPNativeRecorderEvent event) {
    switch (event.type) {
      case MPNativeRecorderEventType.interruptionBegan:
        unawaited(_onMixModeSystemInterruptionBegan());
      case MPNativeRecorderEventType.interruptionEnded:
        unawaited(_onMixModeSystemInterruptionEnded());
    }
  }

  /// 其它入口开始录音：暂停当前采集（与手动暂停一致）。
  Future<void> _onInterruptedByOtherOwner() async {
    await _pauseRecordingDueToExternalInterruption();
  }

  void _startDurationPoll() {
    _tickTimer?.cancel();
    _watchdogTick = 0;
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      unawaited(_pollRecordingState());
    });
  }

  Future<void> _pollRecordingState() async {
    if (!mounted || _step != _MPAudioRecordStep.recording || _recordPath == null) {
      return;
    }
    await _syncDisplayDurationFromFile();
    if (_step == _MPAudioRecordStep.recording && !_isPaused && !_busy && _nativeRecorderOpen) {
      _watchdogTick++;
      if (_watchdogTick % 3 == 0) {
        await _watchdogCheckNativeRecording();
      }
    }
  }

  /// 检测 native 是否仍在采集；若 UI 显示录音中但已停录，则按系统打断处理。
  Future<void> _watchdogCheckNativeRecording() async {
    if (!mounted ||
        _step != _MPAudioRecordStep.recording ||
        _isPaused ||
        _busy ||
        !_nativeRecorderOpen) {
      return;
    }
    if (await _nativeRecorder.isRecording()) {
      return;
    }
    _pausedBySystemInterruption = true;
    await _pauseRecordingDueToExternalInterruption();
  }

  /// < 60 分钟：MM:SS；>= 60 分钟：HH:MM:SS
  String _formatElapsed(Duration d) {
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    final int s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _minimizeToPillBar() {
    if (_busy) {
      return;
    }
    final MediaQueryData mq = MediaQuery.of(context);
    setState(() {
      _showCancelConfirm = false;
      _minimized = true;
      _pillLeft ??= 16;
      _pillBottom ??= mq.padding.bottom + kBottomNavigationBarHeight + 8;
    });
  }

  void _expandFromPillBar() {
    if (_busy) {
      return;
    }
    setState(() => _minimized = false);
  }

  Future<void> _onTapStartRecording() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      if (!mounted) {
        return;
      }
      final bool ok = await OmiMicrophoneManager.ensureMicrophonePermission();
      if (!ok) {
        if (mounted) {
          setState(() => _busy = false);
        }
        return;
      }
      if (await MPBleConnectionHelper.showBlockMessageIfMemoPinDeviceIsRecording(context: context)) {
        if (mounted) {
          setState(() => _busy = false);
        }
        return;
      }
      if (await _isMicrophoneCaptureBlocked()) {
        if (mounted) {
          _showMicrophoneBlockedMessage(forResume: false);
          setState(() => _busy = false);
        }
        return;
      }
      await MPGlobalRecordingCoordinator.instance
          .beforeLocalRecordingStarts(_recordingOwnerToken);
      final MPRecordingBackgroundActivationResult activation =
          await MPRecordingBackgroundSupport.activateForHomeRecording(owner: _recordingOwnerToken);
      if (!activation.audioSessionActive) {
        if (mounted) {
          setState(() => _busy = false);
        }
        return;
      }
      final bool nativeOpen = await _nativeRecorder.open(mixWithOthers: true);
      if (!nativeOpen) {
        if (mounted) {
          setState(() => _busy = false);
        }
        return;
      }
      MPRecordingBackgroundSupport.setNativeRecorderHandlesInterruptions(
        owner: _recordingOwnerToken,
        enabled: true,
      );
      final String path = await _newRecordPath();
      _recorderSessionId++;
      final int sessionId = _recorderSessionId;
      _nativeRecorderOpen = true;
      await _startRecorderToPath(path);
      if (!mounted || sessionId != _recorderSessionId) {
        await _releaseRecorder(deleteFile: true);
        return;
      }
      setState(() {
        _recordPath = path;
        _step = _MPAudioRecordStep.recording;
        _displayDuration = Duration.zero;
        _displayDurationSeconds = 0;
        _isPaused = false;
        _busy = false;
      });
      _startDurationPoll();
      unawaited(_syncDisplayDurationFromFile());
    } catch (e) {
      if (mounted) {
        MPToastUtils.showMessage('Couldn\'t start recording: $e');
      }
      await _releaseRecorder(deleteFile: true);
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _togglePauseResume() async {
    if (_busy || _recordPath == null || !_nativeRecorderOpen) {
      return;
    }
    final int sessionId = _recorderSessionId;
    setState(() => _busy = true);
    try {
      if (_isPaused) {
        if (await MPBleConnectionHelper.showBlockMessageIfMemoPinDeviceIsRecording(context: context)) {
          if (mounted) {
            setState(() => _busy = false);
          }
          return;
        }
        await MPGlobalRecordingCoordinator.instance
            .beforeLocalRecordingStarts(_recordingOwnerToken);
        if (!await _prepareBeforeRecordingResume(reacquire: true)) {
          if (mounted) {
            setState(() => _busy = false);
          }
          return;
        }
        if (!mounted || sessionId != _recorderSessionId || !_nativeRecorderOpen) {
          return;
        }
        if (await _isMicrophoneCaptureBlocked()) {
          if (mounted) {
            _showMicrophoneBlockedMessage(forResume: true);
            setState(() => _busy = false);
          }
          return;
        }
        if (!mounted || sessionId != _recorderSessionId || !_nativeRecorderOpen) {
          return;
        }
        final bool resumed = await _resumeNativeRecording();
        if (!mounted || sessionId != _recorderSessionId) {
          return;
        }
        if (!resumed) {
          setState(() {
            _busy = false;
            if (_nativeRecorderOpen && _nativeCapturing) {
              _isPaused = false;
            } else {
              _isPaused = true;
            }
          });
          MPToastUtils.showMessage(
            'Couldn\'t resume recording. Tap again or save your recording.',
            context: context,
          );
          return;
        }
        setState(() {
          _isPaused = false;
          _pausedBySystemInterruption = false;
          _busy = false;
        });
        unawaited(_syncDisplayDurationFromFile());
      } else {
        final bool paused = await _pauseNativeRecording();
        if (!mounted) {
          return;
        }
        if (!paused && _nativeCapturing) {
          setState(() => _busy = false);
          MPToastUtils.showMessage('Couldn\'t pause recording.', context: context);
          return;
        }
        setState(() {
          _isPaused = true;
          _pausedBySystemInterruption = false;
          _busy = false;
        });
        unawaited(_syncDisplayDurationFromFile());
      }
    } catch (e) {
      if (mounted) {
        MPToastUtils.showMessage('Action failed: $e');
        setState(() => _busy = false);
      }
    }
  }

  void _openCancelConfirm() {
    setState(() => _showCancelConfirm = true);
  }

  void _closeCancelConfirm() {
    setState(() => _showCancelConfirm = false);
  }

  Future<void> _onConfirmDiscard() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    _showCancelConfirm = false;
    await _releaseRecorder(deleteFile: true);
    if (mounted) {
      widget.rootNavigator.pop();
    }
  }

  void _resetSavePendingState() {
    _saveRecorderFinalized = false;
    _finalizedTempAacPath = null;
    _pendingPersistedAacPath = null;
  }

  Future<void> _clearSavePendingAudioFiles() async {
    for (final String? path in <String?>[_finalizedTempAacPath, _pendingPersistedAacPath]) {
      if (path == null || path.isEmpty) {
        continue;
      }
      try {
        final File f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }
    _resetSavePendingState();
  }

  Future<void> _onSave() async {
    if (_busy || _recordPath == null) {
      return;
    }
    setState(() => _busy = true);
    _recorderSessionId++;
    _tickTimer?.cancel();
    _tickTimer = null;
    Duration total = _displayDuration;
    try {
      if (!_saveRecorderFinalized) {
        // 须在 close 之前 finalize：先 stop/合并全部分段，再关会话（勿提前置 _nativeRecorderOpen=false）。
        final String? outPath = await _finalizeRecordingFilePath();
        if (outPath != null && outPath.isNotEmpty) {
          total = await _resolveDurationForSave(outPath);
        }
        if (_nativeRecorderOpen) {
          try {
            await _nativeRecorder.close();
          } catch (_) {}
          _nativeRecorderOpen = false;
        }
        _isPaused = false;
        await MPRecordingBackgroundSupport.deactivateAfterRecording(owner: _recordingOwnerToken);
        MPGlobalRecordingCoordinator.instance
            .notifyRecordingSessionEnded(_recordingOwnerToken);
        if (outPath == null || outPath.isEmpty) {
          if (mounted) {
            setState(() => _busy = false);
          }
          return;
        }
        _finalizedTempAacPath = outPath;
        _saveRecorderFinalized = true;
      }
    } catch (e) {
      if (mounted) {
        MPToastUtils.showMessage('Couldn\'t save: $e');
        setState(() => _busy = false);
      }
      await _releaseRecorder(deleteFile: false);
      return;
    }

    final String? persistedAac = _pendingPersistedAacPath?.trim();
    final bool hasPersistedAac =
        persistedAac != null && persistedAac.isNotEmpty && await File(persistedAac).exists();
    final String? tempAac = _finalizedTempAacPath?.trim();
    final bool hasTempAac = tempAac != null && tempAac.isNotEmpty && await File(tempAac).exists();
    if (!hasPersistedAac && !hasTempAac) {
      if (mounted) {
        MPToastUtils.showMessage('Recording file not found.');
        setState(() => _busy = false);
      }
      return;
    }

    String? savedPath;
    if (hasPersistedAac) {
      savedPath = persistedAac;
    } else {
      final String? copiedAacPath = await MPAudioLocalRecordsUtil.copyTempFileToLocalStorage(
        File(tempAac!),
        deleteAfterCopy: false,
      );
      if (copiedAacPath == null || copiedAacPath.isEmpty) {
        if (mounted) {
          MPToastUtils.showMessage('Couldn\'t save locally. Please try again.');
          setState(() => _busy = false);
        }
        return;
      }
      _pendingPersistedAacPath = copiedAacPath;
      savedPath = copiedAacPath;
    }
    if (hasTempAac) {
      try {
        final File tempFile = File(tempAac);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    }
    _resetSavePendingState();
    final createAt = MPTimeUtils.nowUnixSeconds();
    await MPAudioLocalRecordsUtil.instance.add(
      MPAudioLocalRecord(
        path: savedPath,
        fileName: 'record_$createAt',
        createAt: createAt,
        duration: total.inSeconds,
        source: 'MobilePhone',
        isRemoved: false,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      // _uploadProgressPct = 0;
      _uploadBatchIndex = 1;
      _uploadBatchTotal = 1;
    });

    widget.rootNavigator.pop(MPAudioRecordResult(filePath: savedPath, duration: total));

    MPHomeAudioTaskQueue.instance.seedPendingUploadsFromLocal();

    if (!mounted) {
      return;
    }

    setState(() => _busy = false);
    // setState(() => _uploadProgressPct = null);
    _recordPath = null;
  }

  void _onCloseIntro() {
    widget.rootNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final bool showDimAndCard = !_minimized || _step == _MPAudioRecordStep.intro;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (_step == _MPAudioRecordStep.recording && _minimized)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: Colors.transparent, child: SizedBox.expand()),
              ),
            ),
          if (showDimAndCard)
            Positioned.fill(
              child: IgnorePointer(child: ColoredBox(color: Colors.black.withValues(alpha: 0.45))),
            ),
          if (!_minimized)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: <Widget>[_buildMainSheet()],
                ),
              ),
            ),
          if (_showCancelConfirm && !_minimized) Positioned.fill(child: _buildCancelConfirmLayer()),
          if (_step == _MPAudioRecordStep.recording && _minimized)
            Positioned(
              left: _pillLeft ?? 16,
              right: 16,
              bottom: _pillBottom ?? mq.padding.bottom + kBottomNavigationBarHeight + 8,
              child: GestureDetector(
                onPanUpdate: (DragUpdateDetails d) {
                  final double screenW = mq.size.width;
                  final double screenH = mq.size.height;
                  const double margin = 8;
                  const double minInnerWidth = 220;
                  final double maxLeft = math.max(margin, screenW - margin - 16 - minInnerWidth);
                  final double defaultBottom = mq.padding.bottom + kBottomNavigationBarHeight + 8;
                  setState(() {
                    final double curLeft = _pillLeft ?? 16;
                    final double curBottom = _pillBottom ?? defaultBottom;
                    double nextLeft = curLeft + d.delta.dx;
                    double nextBottom = curBottom - d.delta.dy;
                    nextLeft = nextLeft.clamp(margin, maxLeft);
                    final double maxBottom = screenH - mq.padding.top - 56;
                    nextBottom = nextBottom.clamp(margin, math.max(margin, maxBottom));
                    _pillLeft = nextLeft;
                    _pillBottom = nextBottom;
                  });
                },
                child: _buildMinimizedRecordingBar(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMinimizedRecordingBar() {
    return Material(
      color: Colors.transparent,
      elevation: 10,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFB8D4FF), Color(0xFFD8E4FF), Color(0xFFE8DDF8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _expandFromPillBar,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: SizedBox(
                          height: 28,
                          child: _MPMinimizedWaveform(
                            animation: _waveController,
                            active: !_isPaused,
                            color: _kWaveGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatElapsed(_displayDuration),
                        style: OmiTextStyle.create(
                          color: mainTextColor,
                          fontSize: OmiFontSize.t7_16,
                          fontWeight: OmiFontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _busy ? null : _togglePauseResume,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: redColor, shape: BoxShape.circle),
                child: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white, size: 22),
              ),
            ),
            if (!_isPaused) ...<Widget>[
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: redColor, shape: BoxShape.circle),
              ),
            ] else
              const SizedBox(width: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSheet() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: _step == _MPAudioRecordStep.intro ? _buildIntroBody() : _buildRecordingBody(),
        ),
      ),
    );
  }

  Widget _buildIntroBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(width: 36),
            Expanded(
              child: Text(
                'Record Audio',
                textAlign: TextAlign.center,
                style: OmiTextStyle.create(
                  color: mainTextColor,
                  fontSize: OmiFontSize.t8_17,
                  fontWeight: OmiFontWeight.bold,
                ),
              ),
            ),
            _circleIconButton(icon: Icons.close, onTap: _busy ? () {} : _onCloseIntro),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _busy ? null : _onTapStartRecording,
          child: Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle),
            child: const Icon(Icons.mic, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to start recording',
          style: OmiTextStyle.create(
            color: secondTextColor,
            fontSize: OmiFontSize.t5_14,
            fontWeight: OmiFontWeight.regular,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            _circleIconButton(icon: Icons.fullscreen_exit, onTap: _busy ? () {} : _minimizeToPillBar),
            Expanded(
              child: Text(
                'Record Audio',
                textAlign: TextAlign.center,
                style: OmiTextStyle.create(
                  color: mainTextColor,
                  fontSize: OmiFontSize.t8_17,
                  fontWeight: OmiFontWeight.bold,
                ),
              ),
            ),
            _circleIconButton(icon: Icons.close, onTap: _busy ? () {} : _openCancelConfirm),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _formatElapsed(_displayDuration),
          style: OmiTextStyle.create(
            color: mainTextColor,
            fontSize: OmiFontSize.t33_42,
            fontWeight: OmiFontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _busy ? null : _togglePauseResume,
          child: Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(color: redColor, shape: BoxShape.circle),
            child: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isPaused ? 'Paused' : 'Recording...',
          style: OmiTextStyle.create(
            color: secondTextColor,
            fontSize: OmiFontSize.t5_14,
            fontWeight: OmiFontWeight.regular,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: _sheetButton(
                label: 'Cancel',
                foreground: mainTextColor,
                background: _kCancelSheetBg,
                onTap: _busy ? () {} : _openCancelConfirm,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _sheetButton(
                label: 'Save',
                foreground: Colors.white,
                background: _kBlue,
                onTap: _busy ? () {} : _onSave,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCancelConfirmLayer() {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned.fill(
          child: IgnorePointer(child: ColoredBox(color: Colors.black.withValues(alpha: 0.35))),
        ),
        Center(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const SizedBox(width: 36),
                        Expanded(
                          child: Text(
                            'Cancel Recording',
                            textAlign: TextAlign.center,
                            style: OmiTextStyle.create(
                              color: mainTextColor,
                              fontSize: OmiFontSize.t8_17,
                              fontWeight: OmiFontWeight.bold,
                            ),
                          ),
                        ),
                        _circleIconButton(icon: Icons.close, onTap: _busy ? () {} : _closeCancelConfirm),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Are you sure you want to cancel this recording? All progress will be lost.',
                      textAlign: TextAlign.center,
                      style: OmiTextStyle.create(
                        color: secondTextColor,
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.regular,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: _sheetButton(
                            label: 'No, Keep\nRecording',
                            foreground: mainTextColor,
                            background: _kCancelSheetBg,
                            height: 52,
                            onTap: _busy ? () {} : _closeCancelConfirm,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _sheetButton(
                            label: 'Yes, Cancel',
                            foreground: Colors.white,
                            background: redColor,
                            height: 52,
                            onTap: _busy ? () {} : _onConfirmDiscard,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: _kGreyCircleBg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 20, color: secondTextColor)),
      ),
    );
  }

  Widget _sheetButton({
    required String label,
    required Color foreground,
    required Color background,
    required VoidCallback onTap,
    double height = 48,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: height,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: OmiTextStyle.create(
                color: foreground,
                fontSize: OmiFontSize.t5_14,
                fontWeight: OmiFontWeight.medium,
                height: 1.15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 底部胶囊条内的简易波形（非真实电平，仅示意）。
class _MPMinimizedWaveform extends StatelessWidget {
  const _MPMinimizedWaveform({required this.animation, required this.active, required this.color});

  final Animation<double> animation;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double phase = active ? animation.value * 2 * math.pi : 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List<Widget>.generate(7, (int i) {
            final double h = active ? 4 + (math.sin(phase + i * 0.82) + 1) * 7 : 5.0 + (i % 3) * 1.5;
            return Padding(
              padding: EdgeInsets.only(right: i == 6 ? 0 : 3),
              child: Container(
                width: 3,
                height: h.clamp(4.0, 18.0),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1.5)),
              ),
            );
          }),
        );
      },
    );
  }
}
