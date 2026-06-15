import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS 原生后台执行窗口（[UIApplication.beginBackgroundTask]），避免退后台后 Dart 网络立刻被系统掐断。
class MPAudioUploadBackgroundNative {
  MPAudioUploadBackgroundNative._();

  static const MethodChannel _channel = MethodChannel('mp_audio_upload_background');

  /// 申请 iOS 后台执行时间；非 iOS 恒为 `true`。
  static Future<bool> beginBackgroundExecution() async {
    if (!Platform.isIOS) {
      return true;
    }
    try {
      final bool? ok = await _channel.invokeMethod<bool>('beginBackgroundExecution');
      return ok ?? false;
    } catch (e, st) {
      debugPrint('MPAudioUploadBackgroundNative.beginBackgroundExecution: $e\n$st');
      return false;
    }
  }

  /// 释放 iOS 后台执行时间；非 iOS 无操作。
  static Future<void> endBackgroundExecution() async {
    if (!Platform.isIOS) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('endBackgroundExecution');
    } catch (e, st) {
      debugPrint('MPAudioUploadBackgroundNative.endBackgroundExecution: $e\n$st');
    }
  }
}
