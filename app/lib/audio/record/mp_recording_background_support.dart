import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'mp_global_recording_coordinator.dart';
import 'mp_recording_session_native.dart';

/// [MPRecordingBackgroundSupport.activateForRecording] 的激活结果。
class MPRecordingBackgroundActivationResult {
  const MPRecordingBackgroundActivationResult({
    required this.audioSessionActive,
    required this.backgroundRecordingReliable,
  });

  /// 系统 AudioSession 是否已成功激活。
  final bool audioSessionActive;

  /// 退后台时是否具备可靠的后台录音能力（Android 前台服务、iOS 会话等）。
  final bool backgroundRecordingReliable;
}

/// Task isolate 入口（Android 麦克风前台服务）；须为顶层函数以便引擎注册。
@pragma('vm:entry-point')
void mpRecordingForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_MPRecordingForegroundTaskHandler());
}

/// 仅占位以满足 [FlutterForegroundTask] 生命周期；实际录音仍在主 Isolate 的 flutter_sound 中执行。
class _MPRecordingForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// 首页等「应用内录音」退后台时：配置系统音频会话（iOS/Android）、在 Android 上启动麦克风前台服务，
/// 并订阅 [AudioSession.interruptionEventStream]：其它 App / 来电抢占音频焦点时尝试重新激活会话并
/// 通知当前持有者维持采集（native 若被系统停掉则由各入口自行恢复）。
class MPRecordingBackgroundSupport {
  MPRecordingBackgroundSupport._();

  static bool _foregroundTaskInitialized = false;
  static bool _recordingInfrastructureActive = false;
  static bool _backgroundRecordingReliable = true;
  static bool _mixWithOthersEnabled = false;
  static StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  static Timer? _mixSessionKeepAliveTimer;

  /// 混音模式下定期补激活原生 AudioSession，对抗微信等 App 抢占。
  static const Duration _kMixSessionKeepAliveInterval = Duration(seconds: 2);

  /// 当前录音会话退后台是否可靠（与 [activateForRecording] 结果一致）。
  static bool get isBackgroundRecordingReliable => _backgroundRecordingReliable;

  /// 当前是否为混音模式（可与系统录音备忘录等并存）。
  static bool get isMixWithOthersEnabled => _mixWithOthersEnabled;

  /// 独占录音：与其它 App 互抢麦克风（语音输入、快速捕获等）。
  static AudioSessionConfiguration _exclusiveRecordingSessionConfiguration() {
    return AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
          AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: false,
    );
  }

  /// 混音录音：可与系统录音备忘录、微信等尽量并存（首页 Start Recording）。
  static AudioSessionConfiguration _mixRecordingSessionConfiguration() {
    return AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers |
          AVAudioSessionCategoryOptions.duckOthers |
          AVAudioSessionCategoryOptions.interruptSpokenAudioAndMixWithOthers |
          AVAudioSessionCategoryOptions.allowBluetooth |
          AVAudioSessionCategoryOptions.allowBluetoothA2dp |
          AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.measurement,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      androidWillPauseWhenDucked: false,
    );
  }

  static Future<bool> _applyActiveRecordingSession({required bool activate}) async {
    if (_mixWithOthersEnabled && Platform.isIOS) {
      if (activate) {
        final AudioSession session = await AudioSession.instance;
        await session.configure(_mixRecordingSessionConfiguration());
        await _setRecordingSessionActive(true);
        return MPRecordingSessionNative.applyMixRecordingSession();
      }
      return await _setRecordingSessionActive(false);
    }
    if (activate) {
      final AudioSession session = await AudioSession.instance;
      await session.configure(_activeRecordingSessionConfiguration());
      return _setRecordingSessionActive(true);
    }
    return _setRecordingSessionActive(false);
  }

  static void _startMixSessionKeepAlive() {
    if (!_mixWithOthersEnabled) {
      return;
    }
    _mixSessionKeepAliveTimer?.cancel();
    _mixSessionKeepAliveTimer = Timer.periodic(_kMixSessionKeepAliveInterval, (_) {
      if (!_recordingInfrastructureActive || !_mixWithOthersEnabled) {
        return;
      }
      unawaited(_applyActiveRecordingSession(activate: true));
      unawaited(MPGlobalRecordingCoordinator.instance.notifySystemAudioFocusAttemptMaintainRecording());
    });
  }

  static void _stopMixSessionKeepAlive() {
    _mixSessionKeepAliveTimer?.cancel();
    _mixSessionKeepAliveTimer = null;
  }

  static AudioSessionConfiguration _activeRecordingSessionConfiguration() {
    return _mixWithOthersEnabled
        ? _mixRecordingSessionConfiguration()
        : _exclusiveRecordingSessionConfiguration();
  }

  /// 激活/释放录音 AudioSession；混音模式下激活时不打断其它 App。
  static Future<bool> _setRecordingSessionActive(bool active) async {
    try {
      final AudioSession session = await AudioSession.instance;
      return await session.setActive(
        active,
        avAudioSessionSetActiveOptions: active
            ? (_mixWithOthersEnabled
                ? AVAudioSessionSetActiveOptions.none
                : AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation)
            : AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
      );
    } catch (e, st) {
      debugPrint('MPRecordingBackgroundSupport._setRecordingSessionActive($active): $e\n$st');
      return false;
    }
  }

  static Future<void> _ensureForegroundTaskInitialized() async {
    if (_foregroundTaskInitialized) {
      return;
    }
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        // 新 channelId：已安装设备上旧 channel 的 LOW 无法升级，换 id 以应用更高重要性。
        channelId: 'memo_pin_recording_v2',
        channelName: 'Recording',
        channelDescription: 'Keeps microphone recording active while the app is in the background.',
        channelImportance: NotificationChannelImportance.DEFAULT,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
      ),
    );
    _foregroundTaskInitialized = true;
  }

  /// 首页 Start Recording：混音模式，可与系统录音备忘录同时录制。
  static Future<MPRecordingBackgroundActivationResult> activateForHomeRecording() async {
    _mixWithOthersEnabled = true;
    return _activateRecordingInternal();
  }

  /// 其它入口：独占模式，在打开录音器之前调用。
  static Future<MPRecordingBackgroundActivationResult> activateForRecording() async {
    _mixWithOthersEnabled = false;
    return _activateRecordingInternal();
  }

  static Future<MPRecordingBackgroundActivationResult> _activateRecordingInternal() async {
    bool audioSessionActive = true;
    bool backgroundRecordingReliable = _backgroundRecordingReliable;
    audioSessionActive = await _applyActiveRecordingSession(activate: true);
    if (!audioSessionActive) {
      backgroundRecordingReliable = false;
    }
    if (_mixWithOthersEnabled) {
      _startMixSessionKeepAlive();
    }

    final AudioSession session = await AudioSession.instance;

    if (!_recordingInfrastructureActive) {
      await _interruptionSub?.cancel();
      _interruptionSub = session.interruptionEventStream.listen(
        (AudioInterruptionEvent event) {
          if (!event.begin) {
            if (Platform.isIOS && _recordingInfrastructureActive) {
              unawaited(prepareIosNativeRecorderResume());
            }
            unawaited(_handleSystemAudioInterruptionEnded());
            return;
          }
          unawaited(_handleSystemAudioInterruptionBegin());
        },
      );
      _recordingInfrastructureActive = true;

      if (Platform.isAndroid) {
        await _ensureForegroundTaskInitialized();
        final NotificationPermission notificationPermission =
            await FlutterForegroundTask.checkNotificationPermission();
        if (notificationPermission != NotificationPermission.granted) {
          await FlutterForegroundTask.requestNotificationPermission();
        }
        if (await FlutterForegroundTask.isRunningService) {
          backgroundRecordingReliable = audioSessionActive;
        } else {
          final ServiceRequestResult started = await FlutterForegroundTask.startService(
            serviceTypes: const <ForegroundServiceTypes>[ForegroundServiceTypes.microphone],
            notificationTitle: 'MemoPin',
            notificationText: 'Recording in progress…',
            callback: mpRecordingForegroundTaskCallback,
          );
          if (started is ServiceRequestFailure) {
            backgroundRecordingReliable = false;
            debugPrint('MPRecordingBackgroundSupport: foreground service start failed.');
          } else {
            backgroundRecordingReliable = await FlutterForegroundTask.isRunningService;
          }
        }
      }
    }

    if (!audioSessionActive) {
      backgroundRecordingReliable = false;
    }
    _backgroundRecordingReliable = backgroundRecordingReliable;
    return MPRecordingBackgroundActivationResult(
      audioSessionActive: audioSessionActive,
      backgroundRecordingReliable: backgroundRecordingReliable,
    );
  }

  /// 录音进行中补激活 AudioSession（如从后台回到前台后 native 已停但会话仍应可用）。
  static Future<bool> ensureAudioSessionActiveForRecording() async {
    if (!_recordingInfrastructureActive) {
      return false;
    }
    try {
      return await _applyActiveRecordingSession(activate: true);
    } catch (e, st) {
      debugPrint('MPRecordingBackgroundSupport.ensureAudioSessionActiveForRecording: $e\n$st');
      return false;
    }
  }

  /// iOS：在调用 [FlutterSoundRecorder.resumeRecorder] 之前执行。
  ///
  /// 系统音频打断后 [AudioSession] 可能已被置为非 active，而 Dart 侧仍可能为 `isPaused`，
  /// 此时 native `FlautoRecorder` 内 `audioRec` 为空，直接 resume 会 EXC_BAD_ACCESS。
  static Future<void> prepareIosNativeRecorderResume() async {
    if (!Platform.isIOS || !_recordingInfrastructureActive) {
      return;
    }
    try {
      await _applyActiveRecordingSession(activate: true);
    } catch (e, st) {
      debugPrint('MPRecordingBackgroundSupport.prepareIosNativeRecorderResume: $e\n$st');
    }
  }

  /// 系统音频焦点被抢占：混音模式下立即维持采集，不主动暂停。
  static Future<void> _handleSystemAudioInterruptionBegin() async {
    if (!_recordingInfrastructureActive) {
      return;
    }
    await ensureAudioSessionActiveForRecording();
    await MPGlobalRecordingCoordinator.instance.notifySystemAudioFocusAttemptMaintainRecording();
    if (_mixWithOthersEnabled) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await ensureAudioSessionActiveForRecording();
      await MPGlobalRecordingCoordinator.instance.notifySystemAudioFocusAttemptMaintainRecording();
    }
  }

  /// 系统音频打断结束：再次激活会话并尝试恢复采集。
  static Future<void> _handleSystemAudioInterruptionEnded() async {
    if (!_recordingInfrastructureActive) {
      return;
    }
    await ensureAudioSessionActiveForRecording();
    await MPGlobalRecordingCoordinator.instance.notifySystemAudioFocusAttemptMaintainRecording();
  }

  /// 录音结束或取消时调用，释放会话并停止前台服务。
  static Future<void> deactivateAfterRecording() async {
    if (!_recordingInfrastructureActive) {
      return;
    }
    _stopMixSessionKeepAlive();
    _recordingInfrastructureActive = false;
    _backgroundRecordingReliable = true;
    _mixWithOthersEnabled = false;
    await _interruptionSub?.cancel();
    _interruptionSub = null;
    try {
      if (Platform.isAndroid && await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {}
    try {
      final AudioSession session = await AudioSession.instance;
      await session.setActive(
        false,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
      );
    } catch (_) {}
  }

  /// 退后台时主动补激活 AudioSession，降低 iOS 静默停录概率。
  static Future<void> onAppEnteredBackgroundDuringRecording() async {
    if (!_recordingInfrastructureActive) {
      return;
    }
    await ensureAudioSessionActiveForRecording();
  }

  /// flutter_sound 的 BGService 依赖在部分平台/运行态（尤其 iOS）可能未注册，直接调用会抛 [MissingPluginException]。
  /// 这里做平台判断 + 自动降级，保证“能录音”优先。
  static Future<void> openRecorderSafely(FlutterSoundRecorder recorder) async {
    try {
      await recorder.openRecorder(isBGService: Platform.isAndroid);
    } on MissingPluginException {
      await recorder.openRecorder();
    }
  }
}
