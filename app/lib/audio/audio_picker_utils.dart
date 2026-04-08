import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// 读取本地音频时长（与 [MPAudioImportUtils] 内联逻辑对齐）
class AudioPickerUtils {
  AudioPickerUtils._();

  /// 返回 [file] 的时长；失败为 `null`
  static Future<Duration?> getAudioDuration(File file) async {
    if (!await file.exists()) {
      return null;
    }
    final AudioPlayer player = AudioPlayer();
    try {
      await player.setAudioSource(AudioSource.uri(Uri.file(file.path)));
      return player.duration;
    } catch (e, st) {
      debugPrint('AudioPickerUtils.getAudioDuration: $e\n$st');
      return null;
    } finally {
      await player.dispose();
    }
  }
}
