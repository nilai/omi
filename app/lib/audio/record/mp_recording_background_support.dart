import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'mp_global_recording_coordinator.dart';

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
  static StreamSubscription<AudioInterruptionEvent>? _interruptionSub;

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
  static Future<void> activateForRecording() async {
    if (_recordingInfrastructureActive) {
      return;
    }
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
    await _interruptionSub?.cancel();
    _interruptionSub = session.interruptionEventStream.listen(
      (AudioInterruptionEvent event) {
        if (!event.begin) {
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
        return;
      }
      final ServiceRequestResult started = await FlutterForegroundTask.startService(
        serviceTypes: const <ForegroundServiceTypes>[ForegroundServiceTypes.microphone],
        notificationTitle: 'MemoPin',
        notificationText: 'Recording in progress…',
        callback: mpRecordingForegroundTaskCallback,
      );
      if (started is ServiceRequestFailure) {
        // 仍保留已激活的 AudioSession；仅后台可能被系统限制。
      }
    }
  }

  /// 录音结束或取消时调用，释放会话并停止前台服务。
  static Future<void> deactivateAfterRecording() async {
    if (!_recordingInfrastructureActive) {
      return;
    }
    _recordingInfrastructureActive = false;
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
