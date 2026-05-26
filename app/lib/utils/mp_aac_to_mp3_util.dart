import 'dart:io';

import 'package:audio_decoder/audio_decoder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_lame/flutter_lame.dart';
import 'package:path/path.dart' as p;
import 'package:wav/wav.dart';

import '../audio/record/mp_audio_local_records_util.dart';

/// AAC（ADTS 等）转 MP3：依赖 [audio_decoder] 解码为 WAV，[flutter_lame] 编码 MP3。
class MPAacToMp3Util {
  MPAacToMp3Util._();

  /// 手机端录音：临时 AAC 落盘后转同目录同名 MP3，删除 AAC，返回 MP3 绝对路径。
  static Future<String?> persistTempAacRecordingAsMp3(File tempAacFile) async {
    final String? aacPath = await MPAudioLocalRecordsUtil.copyTempFileToLocalStorage(tempAacFile);
    if (aacPath == null || aacPath.isEmpty) {
      return null;
    }
    final String? mp3Path = await convertAacFileToMp3(aacPath);
    if (mp3Path == null) {
      try {
        final File leftover = File(aacPath);
        if (await leftover.exists()) {
          await leftover.delete();
        }
      } catch (e) {
        debugPrint('MPAacToMp3Util: cleanup aac after failed transcode: $e');
      }
    }
    return mp3Path;
  }

  /// 将本地 AAC 转为同目录、同主文件名的 MP3。
  ///
  /// - [aacPath]：沙盒内 `.aac` 绝对路径。
  /// - [deleteSourceAfterSuccess]：转码成功后删除源 AAC（默认 `true`）。
  /// - 返回 MP3 绝对路径；失败返回 `null`。
  static Future<String?> convertAacFileToMp3(
    String aacPath, {
    bool deleteSourceAfterSuccess = true,
  }) async {
    if (kIsWeb) {
      debugPrint('MPAacToMp3Util: unsupported on web');
      return null;
    }
    final String normalized = p.normalize(aacPath.trim());
    if (normalized.isEmpty) {
      return null;
    }
    final File input = File(normalized);
    if (!await input.exists()) {
      debugPrint('MPAacToMp3Util: aac file not found: $normalized');
      return null;
    }

    final String dir = p.dirname(normalized);
    final String base = p.basenameWithoutExtension(normalized);
    final String mp3Path = p.join(dir, '$base.mp3');
    final String wavPath = p.join(dir, '$base._transcode_tmp.wav');

    try {
      await AudioDecoder.convertToWav(normalized, wavPath);
      final Wav wav = await Wav.readFile(wavPath);
      if (wav.channels.isEmpty || wav.channels.first.isEmpty) {
        debugPrint('MPAacToMp3Util: decoded wav is empty');
        return null;
      }

      final int channels = wav.channels.length;
      final int sampleRate = wav.samplesPerSecond;
      final int bitRate = sampleRate <= 8000 ? 32 : 128;
      final LameMp3Encoder encoder = LameMp3Encoder(
        sampleRate: sampleRate,
        numChannels: channels,
        bitRate: bitRate,
      );

      final IOSink sink = File(mp3Path).openWrite();
      final List<double> leftAcc = <double>[];
      final List<double> rightAcc = <double>[];
      const int chunkSamples = 48000;

      try {
        final Float64List left = wav.channels[0];
        final Float64List? right = channels > 1 ? wav.channels[1] : null;
        if (channels == 1) {
          for (int j = 0; j < left.length; j++) {
            leftAcc.add(left[j]);
          }
        } else if (right != null) {
          final int frames = left.length;
          for (int j = 0; j < frames; j++) {
            leftAcc.add(left[j]);
            rightAcc.add(right[j]);
          }
        }

        await _encodePcmChunksFromBuffers(
          encoder: encoder,
          sink: sink,
          leftAcc: leftAcc,
          rightAcc: rightAcc,
          channels: channels,
          chunkSamples: chunkSamples,
          encodePartialOnly: false,
        );
        await _encodePcmChunksFromBuffers(
          encoder: encoder,
          sink: sink,
          leftAcc: leftAcc,
          rightAcc: rightAcc,
          channels: channels,
          chunkSamples: chunkSamples,
          encodePartialOnly: true,
        );
        sink.add(await encoder.flush());
      } finally {
        await encoder.close();
        await sink.close();
      }

      final String? verified =
          await MPAudioLocalRecordsUtil.adjustAudioFileIfWrongExtension(mp3Path);
      final String resultPath = verified ?? mp3Path;
      if (!await File(resultPath).exists()) {
        return null;
      }

      if (deleteSourceAfterSuccess) {
        try {
          if (await input.exists()) {
            await input.delete();
          }
        } catch (e) {
          debugPrint('MPAacToMp3Util: delete aac failed: $e');
        }
      }
      return resultPath;
    } catch (e, st) {
      debugPrint('MPAacToMp3Util.convertAacFileToMp3: $e\n$st');
      try {
        final File out = File(mp3Path);
        if (await out.exists()) {
          await out.delete();
        }
      } catch (_) {}
      return null;
    } finally {
      try {
        final File tmpWav = File(wavPath);
        if (await tmpWav.exists()) {
          await tmpWav.delete();
        }
      } catch (_) {}
    }
  }

  /// [encodePartialOnly] 为 `false` 时仅当累积样本 ≥ [chunkSamples] 才编码；为 `true` 时将剩余样本一次性编码。
  static Future<void> _encodePcmChunksFromBuffers({
    required LameMp3Encoder encoder,
    required IOSink sink,
    required List<double> leftAcc,
    required List<double> rightAcc,
    required int channels,
    required int chunkSamples,
    required bool encodePartialOnly,
  }) async {
    if (encodePartialOnly) {
      if (leftAcc.isEmpty) {
        return;
      }
      final int take = leftAcc.length;
      final Float64List left = Float64List.fromList(leftAcc.sublist(0, take));
      leftAcc.clear();
      Float64List? right;
      if (channels == 2) {
        right = Float64List.fromList(rightAcc.sublist(0, take));
        rightAcc.clear();
      }
      sink.add(await encoder.encodeDouble(leftChannel: left, rightChannel: right));
      return;
    }

    while (leftAcc.length >= chunkSamples) {
      final Float64List left = Float64List.fromList(leftAcc.sublist(0, chunkSamples));
      leftAcc.removeRange(0, chunkSamples);
      Float64List? right;
      if (channels == 2) {
        right = Float64List.fromList(rightAcc.sublist(0, chunkSamples));
        rightAcc.removeRange(0, chunkSamples);
      }
      sink.add(await encoder.encodeDouble(leftChannel: left, rightChannel: right));
    }
  }
}
