import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'mp_global_recording_coordinator.dart';

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
/// 并订阅 [AudioSession.interruptionEventStream]：其它 App / 来电抢占音频焦点时通过
/// [MPGlobalRecordingCoordinator.notifySystemAudioFocusShouldPauseCurrentRecording] 暂停当前采集（用户可手动恢复）。
class MPRecordingBackgroundSupport {
  MPRecordingBackgroundSupport._();

  static bool _foregroundTaskInitialized = false;
  static bool _recordingInfrastructureActive = false;
  static bool _backgroundRecordingReliable = true;
  static StreamSubscription<AudioInterruptionEvent>? _interruptionSub;

  /// 当前录音会话退后台是否可靠（与 [activateForRecording] 结果一致）。
  static bool get isBackgroundRecordingReliable => _backgroundRecordingReliable;

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

  /// 在打开录音器之前调用：PlayAndRecord 会话 +（Android）麦克风前台服务。
  static Future<MPRecordingBackgroundActivationResult> activateForRecording() async {
    if (_recordingInfrastructureActive) {
      return MPRecordingBackgroundActivationResult(
        audioSessionActive: true,
        backgroundRecordingReliable: _backgroundRecordingReliable,
      );
    }
    bool audioSessionActive = true;
    bool backgroundRecordingReliable = true;
    final AudioSession session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );
    try {
      await session.setActive(true);
    } catch (e, st) {
      debugPrint('MPRecordingBackgroundSupport.activateForRecording setActive: $e\n$st');
      audioSessionActive = false;
      backgroundRecordingReliable = false;
    }
    await _interruptionSub?.cancel();
    _interruptionSub = session.interruptionEventStream.listen(
      (AudioInterruptionEvent event) {
        if (!event.begin) {
          if (Platform.isIOS && _recordingInfrastructureActive) {
            unawaited(prepareIosNativeRecorderResume());
          }
          return;
        }
        unawaited(
          MPGlobalRecordingCoordinator.instance
              .notifySystemAudioFocusShouldPauseCurrentRecording(),
        );
      },
    );
    _recordingInfrastructureActive = true;

    if (Platform.isAndroid) {
      await _ensureForegroundTaskInitialized();
      final NotificationPermission notificationPermission = await FlutterForegroundTask.checkNotificationPermission();
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
      final AudioSession session = await AudioSession.instance;
      await session.setActive(true);
      return true;
    } catch (e, st) {
      debugPrint('MPRecordingBackgroundSupport.ensureAudioSessionActiveForRecording: $e\n$st');
      return false;
    }
  }

  /// iOS：在调用 [FlutterSoundRecorder.resumeRecorder] 之前执行。
  ///
  /// 系统音频打断后 [AudioSession] 可能已被置为非 active，而 Dart 侧仍可能为 `isPaused`，
  /// 此时 native `FlautoRecorder` 内 `audioRec` 为空，直接 resume 会 EXC_BAD_ACCESS。
  /// 录音基建已激活时 [activateForRecording] 会早退不再 [setActive]，故此处单独补一次激活。
  static Future<void> prepareIosNativeRecorderResume() async {
    if (!Platform.isIOS || !_recordingInfrastructureActive) {
      return;
    }
    try {
      final AudioSession session = await AudioSession.instance;
      await session.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.voiceCommunication,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ),
      );
      await session.setActive(true);
    } catch (e, st) {
      debugPrint('MPRecordingBackgroundSupport.prepareIosNativeRecorderResume: $e\n$st');
    }
  }

  /// 录音结束或取消时调用，释放会话并停止前台服务。
  static Future<void> deactivateAfterRecording() async {
    if (!_recordingInfrastructureActive) {
      return;
    }
    _recordingInfrastructureActive = false;
    _backgroundRecordingReliable = true;
    await _interruptionSub?.cancel();
    _interruptionSub = null;
    try {
      if (Platform.isAndroid && await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {}
    try {
      final AudioSession session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {}
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
