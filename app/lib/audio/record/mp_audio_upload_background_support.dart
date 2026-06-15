import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'mp_audio_upload_background_native.dart';
import 'mp_recording_background_support.dart';

/// Task isolate 入口（Android 上传前台服务）；须为顶层函数以便引擎注册。
@pragma('vm:entry-point')
void mpAudioUploadForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_MPAudioUploadForegroundTaskHandler());
}

/// 仅占位以满足 [FlutterForegroundTask] 生命周期；实际上传仍在主 Isolate 执行。
class _MPAudioUploadForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// 音频上传队列活跃期间：Android 启动 dataSync 前台服务；iOS 申请后台执行窗口；
/// 并在退后台遇到网络中断时阻塞重试直至回到前台（避免无意义失败重试）。
class MPAudioUploadBackgroundSupport with WidgetsBindingObserver {
  MPAudioUploadBackgroundSupport._();

  static final MPAudioUploadBackgroundSupport _instance = MPAudioUploadBackgroundSupport._();

  static bool _installed = false;
  static bool _foregroundTaskInitialized = false;
  static int _uploadSessionCount = 0;
  static bool _uploadForegroundServiceStarted = false;
  static bool _iosBackgroundExecutionActive = false;

  static AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  static final List<VoidCallback> _foregroundWaiters = <VoidCallback>[];

  /// 在 [main] 中调用一次，用于监听前后台切换。
  static void install() {
    if (_installed) {
      return;
    }
    _installed = true;
    WidgetsBinding.instance.addObserver(_instance);
    _lifecycleState = WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
  }

  static bool get isAppInForeground => _lifecycleState == AppLifecycleState.resumed;

  /// 上传 Worker 开始时调用（可嵌套，内部引用计数）。
  static Future<void> activateForUploadSession() async {
    install();
    _uploadSessionCount++;
    if (_uploadSessionCount > 1) {
      return;
    }

    if (Platform.isAndroid) {
      await _ensureForegroundTaskInitialized();
      if (MPRecordingBackgroundSupport.isRecordingInfrastructureActive) {
        debugPrint('MPAudioUploadBackgroundSupport: recording FGS active, reuse process keep-alive');
        return;
      }
      final NotificationPermission notificationPermission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      if (await FlutterForegroundTask.isRunningService) {
        _uploadForegroundServiceStarted = false;
        return;
      }
      final ServiceRequestResult started = await FlutterForegroundTask.startService(
        serviceTypes: const <ForegroundServiceTypes>[ForegroundServiceTypes.dataSync],
        notificationTitle: 'MemoPin',
        notificationText: 'Uploading audio…',
        callback: mpAudioUploadForegroundTaskCallback,
      );
      if (started is ServiceRequestFailure) {
        debugPrint('MPAudioUploadBackgroundSupport: upload foreground service start failed.');
        _uploadForegroundServiceStarted = false;
      } else {
        _uploadForegroundServiceStarted = await FlutterForegroundTask.isRunningService;
      }
      return;
    }

    if (Platform.isIOS) {
      _iosBackgroundExecutionActive = await MPAudioUploadBackgroundNative.beginBackgroundExecution();
      if (!_iosBackgroundExecutionActive) {
        debugPrint('MPAudioUploadBackgroundSupport: iOS beginBackgroundExecution failed.');
      }
    }
  }

  /// 上传队列完全空闲时调用。
  static Future<void> deactivateAfterUploadSession() async {
    if (_uploadSessionCount <= 0) {
      return;
    }
    _uploadSessionCount--;
    if (_uploadSessionCount > 0) {
      return;
    }

    if (Platform.isAndroid) {
      if (_uploadForegroundServiceStarted &&
          !MPRecordingBackgroundSupport.isRecordingInfrastructureActive &&
          await FlutterForegroundTask.isRunningService) {
        try {
          await FlutterForegroundTask.stopService();
        } catch (e, st) {
          debugPrint('MPAudioUploadBackgroundSupport: stop upload FGS failed: $e\n$st');
        }
      }
      _uploadForegroundServiceStarted = false;
      return;
    }

    if (Platform.isIOS && _iosBackgroundExecutionActive) {
      await MPAudioUploadBackgroundNative.endBackgroundExecution();
      _iosBackgroundExecutionActive = false;
    }
  }

  /// 是否为退后台后常见的网络中断（Android/iOS 均可能出现）。
  static bool isLikelyBackgroundNetworkFailure(Object error) {
    final String message = error.toString().toLowerCase();
    return message.contains('connection abort') ||
        message.contains('software caused connection abort') ||
        message.contains('write failed') ||
        message.contains('broken pipe') ||
        message.contains('connection reset');
  }

  /// S3 在后台因网络策略失败时，等待回到前台再重试（默认最多 30 分钟）。
  static Future<void> waitUntilForegroundForRetry({
    Duration timeout = const Duration(minutes: 30),
  }) async {
    if (isAppInForeground) {
      return;
    }
    debugPrint('MPAudioUploadBackgroundSupport: waiting for foreground before S3 retry…');
    final Completer<void> completer = Completer<void>();
    late Timer timer;
    void onForeground() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    timer = Timer(timeout, () {
      _foregroundWaiters.remove(onForeground);
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    _foregroundWaiters.add(onForeground);

    try {
      await completer.future;
    } finally {
      timer.cancel();
      _foregroundWaiters.remove(onForeground);
    }
    if (!isAppInForeground) {
      debugPrint('MPAudioUploadBackgroundSupport: foreground wait timed out.');
    }
  }

  static Future<void> _ensureForegroundTaskInitialized() async {
    if (_foregroundTaskInitialized || MPRecordingBackgroundSupport.isForegroundTaskInitialized) {
      _foregroundTaskInitialized = true;
      return;
    }
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'memo_pin_upload_v1',
        channelName: 'Audio upload',
        channelDescription: 'Keeps audio upload active while the app is in the background.',
        channelImportance: NotificationChannelImportance.LOW,
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state != AppLifecycleState.resumed) {
      return;
    }
    if (_foregroundWaiters.isEmpty) {
      return;
    }
    final List<VoidCallback> waiters = List<VoidCallback>.from(_foregroundWaiters);
    for (final VoidCallback waiter in waiters) {
      waiter();
    }
  }
}
