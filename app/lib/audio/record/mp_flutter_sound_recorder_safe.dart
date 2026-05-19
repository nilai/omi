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

  /// 仅在 [FlutterSoundRecorder.isPaused] 为 true 且会话仍打开时恢复。
  ///
  /// [recorderOpened] 须与业务侧 `_recorderOpened` 一致；Save/Close 后须先置为 `false` 再
  /// `stopRecorder`，避免 native 已 `release` 而 Dart 仍 `isPaused` 时调用 resume 崩溃。
  static Future<bool> resumeIfPaused(
    FlutterSoundRecorder recorder, {
    required bool recorderOpened,
  }) async {
    if (!recorderOpened) {
      return false;
    }
    // iOS 上 native resumeRecorder 在 audioRec 已释放时仍会 EXC_BAD_ACCESS，无法被 Dart 捕获。
    // 长录音弹窗等场景请用 stop + 新分段 start；此处直接返回 false 避免崩溃。
    if (Platform.isIOS) {
      return false;
    }
    try {
      if (recorder.isStopped) {
        return false;
      }
      if (recorder.isRecording) {
        return true;
      }
      if (!recorder.isPaused) {
        return false;
      }
      await recorder.resumeRecorder();
      return true;
    } catch (e, st) {
      debugPrint('MPFlutterSoundRecorderSafe.resumeIfPaused: $e\n$st');
      return false;
    }
  }
}
