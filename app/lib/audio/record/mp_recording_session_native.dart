import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS 原生混音录音会话（补充 [audio_session] 插件，启用 overrideMutedMicrophoneInterruption 等选项）。
class MPRecordingSessionNative {
  MPRecordingSessionNative._();

  static const MethodChannel _channel = MethodChannel('mp_recording_session');

  /// 应用原生混音 AVAudioSession；非 iOS 直接返回 `true`。
  static Future<bool> applyMixRecordingSession() async {
    if (!Platform.isIOS) {
      return true;
    }
    try {
      final bool? ok = await _channel.invokeMethod<bool>('applyMixRecordingSession');
      return ok ?? false;
    } catch (e, st) {
      debugPrint('MPRecordingSessionNative.applyMixRecordingSession: $e\n$st');
      return false;
    }
  }
}
