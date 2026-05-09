import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_lame/flutter_lame.dart';
import 'package:opus_dart/opus_dart.dart';
import 'package:opus_flutter/opus_flutter.dart' as opus_flutter;
import 'package:path/path.dart' as p;

import '../audio/record/mp_audio_local_records_util.dart';

/// Opus（Ogg 封装）转 MP3：依赖 [opus_dart]/[opus_flutter] 解码，[flutter_lame] 编码。
///
/// 仅支持 **Ogg Opus**（常见 `.opus`/`.ogg`）；裸 Opus 包文件不支持。
class MPOpusToMp3Util {
  MPOpusToMp3Util._();

  static Future<void>? _opusLoadFuture;

  /// 确保 libopus FFI 已 [initOpus]，可多并发安全复用。
  static Future<void> _ensureOpusLoaded() {
    return _opusLoadFuture ??= () async {
      initOpus(await opus_flutter.load());
    }();
  }

  /// 将本地 Opus 文件转为同目录、同主文件名的 MP3。
  ///
  /// - [opusPath]：Ogg Opus 绝对路径（建议在应用沙盒内）。
  /// - 返回 MP3 绝对路径；失败返回 `null`。
  static Future<String?> convertOpusFileToMp3(String opusPath) async {
    if (kIsWeb) {
      debugPrint('MPOpusToMp3Util: unsupported on web');
      return null;
    }
    final String normalized = p.normalize(opusPath.trim());
    if (normalized.isEmpty) {
      return null;
    }
    final File input = File(normalized);
    if (!await input.exists()) {
      debugPrint('MPOpusToMp3Util: opus file not found: $normalized');
      return null;
    }

    final String dir = p.dirname(normalized);
    final String base = p.basenameWithoutExtension(normalized);
    final String mp3Path = p.join(dir, '$base.mp3');

    try {
      await _ensureOpusLoaded();
      final Uint8List raw = await input.readAsBytes();
      final List<Uint8List> packets = _extractOggPackets(raw);
      if (packets.isEmpty) {
        debugPrint('MPOpusToMp3Util: no Ogg packets (need Ogg Opus container)');
        return null;
      }

      int channels = 1;
      int decodeRate = 48000;
      var packetIndex = 0;

      if (packets.isNotEmpty && _packetMagic(packets.first) == 'OpusHead') {
        final Uint8List head = packets.first;
        if (head.length >= 12) {
          channels = head[9] == 2 ? 2 : 1;
          final ByteData bd = ByteData.sublistView(head);
          final int inputRate = bd.getUint32(12, Endian.little);
          decodeRate = _opusDecoderSampleRate(inputRate);
        }
        packetIndex = 1;
      }
      while (packetIndex < packets.length &&
          _packetMagic(packets[packetIndex]) == 'OpusTags') {
        packetIndex++;
      }

      final SimpleOpusDecoder decoder = SimpleOpusDecoder(
        sampleRate: decodeRate,
        channels: channels,
      );
      final LameMp3Encoder encoder = LameMp3Encoder(
        sampleRate: decodeRate,
        numChannels: channels,
        bitRate: 128,
      );

      final IOSink sink = File(mp3Path).openWrite();
      final List<double> leftAcc = <double>[];
      final List<double> rightAcc = <double>[];

      try {
        const int chunkSamples = 48000;

        for (int i = packetIndex; i < packets.length; i++) {
          final Uint8List pkt = packets[i];
          if (pkt.isEmpty) {
            continue;
          }
          final Float32List pcm = decoder.decodeFloat(input: pkt);
          if (channels == 1) {
            for (int j = 0; j < pcm.length; j++) {
              leftAcc.add(pcm[j]);
            }
          } else {
            final int frames = pcm.length ~/ 2;
            for (int j = 0; j < frames; j++) {
              leftAcc.add(pcm[j * 2]);
              rightAcc.add(pcm[j * 2 + 1]);
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
        }

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
        decoder.destroy();
        await encoder.close();
        await sink.close();
      }

      final String? verified =
          await MPAudioLocalRecordsUtil.adjustAudioFileIfWrongExtension(mp3Path);
      return verified ?? mp3Path;
    } catch (e, st) {
      debugPrint('MPOpusToMp3Util.convertOpusFileToMp3: $e\n$st');
      try {
        final File out = File(mp3Path);
        if (await out.exists()) {
          await out.delete();
        }
      } catch (_) {}
      return null;
    }
  }

  /// Opus 解码器允许的采样率；头里为 0 或未列出时用 48000。
  static int _opusDecoderSampleRate(int inputSampleRateFromHead) {
    const List<int> allowed = <int>[8000, 12000, 16000, 24000, 48000];
    if (inputSampleRateFromHead == 0) {
      return 48000;
    }
    if (allowed.contains(inputSampleRateFromHead)) {
      return inputSampleRateFromHead;
    }
    return 48000;
  }

  static String _packetMagic(Uint8List p) {
    if (p.length < 8) {
      return '';
    }
    return String.fromCharCodes(p.sublist(0, 8));
  }

  /// 从 Ogg 物理页拆出逻辑包（支持跨页包）。
  static List<Uint8List> _extractOggPackets(Uint8List data) {
    final List<Uint8List> packets = <Uint8List>[];
    final BytesBuilder current = BytesBuilder(copy: false);
    var i = 0;
    while (i < data.length) {
      if (!_isOggCapturePattern(data, i)) {
        i++;
        continue;
      }
      if (i + 27 > data.length) {
        break;
      }
      final int nseg = data[i + 26];
      final int headerEnd = i + 27 + nseg;
      if (headerEnd > data.length) {
        break;
      }
      var bodyPos = headerEnd;
      for (int s = 0; s < nseg; s++) {
        final int segLen = data[i + 27 + s];
        if (bodyPos + segLen > data.length) {
          return packets;
        }
        current.add(Uint8List.sublistView(data, bodyPos, bodyPos + segLen));
        bodyPos += segLen;
        if (segLen < 255) {
          packets.add(current.toBytes());
          current.clear();
        }
      }
      i = bodyPos;
    }
    return packets;
  }

  static bool _isOggCapturePattern(Uint8List d, int i) {
    return i + 4 <= d.length &&
        d[i] == 0x4f &&
        d[i + 1] == 0x67 &&
        d[i + 2] == 0x67 &&
        d[i + 3] == 0x53;
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
      final Float64List left =
          Float64List.fromList(leftAcc.sublist(0, chunkSamples));
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

