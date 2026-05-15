import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'mp_recording_background_support.dart';

/// [FlutterSoundRecorder] 在 iOS 上若在未真正 paused 时调用 [resumeRecorder]，native 侧可能出现
/// `audioRec == null` 导致 EXC_BAD_ACCESS。此处与插件状态位对齐后再调用 pause/resume，并在 iOS
/// resume 前补 [MPRecordingBackgroundSupport.prepareIosNativeRecorderResume]。
class MPFlutterSoundRecorderSafe {
  MPFlutterSoundRecorderSafe._();

  /// 仅在 [FlutterSoundRecorder.isRecording] 为 true 时暂停；跳过或失败时返回 `false`。
  static Future<bool> pauseIfRecording(FlutterSoundRecorder recorder) async {
    try {
      if (!recorder.isRecording) {
        return false;
      }
      await recorder.pauseRecorder();
      if (Platform.isIOS) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return true;
    } catch (e, st) {
      debugPrint('MPFlutterSoundRecorderSafe.pauseIfRecording: $e\n$st');
      return false;
    }
  }

  /// 仅在 [FlutterSoundRecorder.isPaused] 为 true 时恢复；已在录制中则视为成功（不调用 native）。
  /// 无法恢复（已停止或状态不一致）时返回 `false`，调用方应清除本地「已暂停」UI 状态。
  static Future<bool> resumeIfPaused(FlutterSoundRecorder recorder) async {
    try {
      if (recorder.isRecording) {
        return true;
      }
      if (!recorder.isPaused) {
        return false;
      }
      if (Platform.isIOS) {
        await MPRecordingBackgroundSupport.prepareIosNativeRecorderResume();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      await recorder.resumeRecorder();
      return true;
    } catch (e, st) {
      debugPrint('MPFlutterSoundRecorderSafe.resumeIfPaused: $e\n$st');
      return false;
    }
  }
}
