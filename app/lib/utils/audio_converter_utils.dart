import 'dart:io';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_lame/flutter_lame.dart';
import 'package:opus_flutter/opus_flutter.dart' as opus_flutter;

/// Audio format conversion utilities
/// Supports Opus to MP3 conversion with progress callbacks
class AudioConverterUtils {
  /// Default MP3 bitrate (128 kbps)
  static const int defaultBitrate = 128;

  /// Chunk size for processing (10 seconds at 16kHz = 160000 samples)
  static const int _chunkSamples = 160000;

  /// Note device opus frame size in bytes (40 bytes per frame for mono)
  static const int _noteOpusFrameSize = 40;

  /// PCM frame size for decoding (40ms frame at 16kHz mono = 640 samples)
  static const int _opusPcmFrameSize = 640;

  /// Convert Opus file to MP3
  ///
  /// [opusFilePath] - Path to the source Opus file
  /// [sampleRate] - Audio sample rate (default: 16000 Hz)
  /// [channels] - Number of audio channels (default: 1 for mono)
  /// [outputPath] - Optional custom output path. If null, uses same directory as source
  /// [onProgress] - Optional callback for progress updates (0.0 to 1.0)
  /// [keepWavFile] - If true, keeps the intermediate WAV file for debugging (default: true)
  ///
  /// Returns the path to the generated MP3 file
  Future<String> convertOpusToMp3({
    required String opusFilePath,
    int sampleRate = 16000,
    int channels = 1,
    String? outputPath,
    void Function(double progress)? onProgress,
    bool keepWavFile = true,
  }) async {
    // Step 1: Decode Opus to PCM
    onProgress?.call(0.0);
    final pcmData = await _decodeOpusToPcm(
      opusFilePath: opusFilePath,
      sampleRate: sampleRate,
      channels: channels,
    );

    if (pcmData.isEmpty) {
      throw Exception('Failed to decode Opus file: empty PCM data');
    }

    onProgress?.call(0.3);

    // Step 2: Save intermediate WAV file for debugging
    if (keepWavFile) {
      final wavPath = _getWavOutputPath(opusFilePath);
      await _savePcmAsWav(
        pcmData: pcmData,
        sampleRate: sampleRate,
        channels: channels,
        outputPath: wavPath,
      );
      debugPrint('AudioConverterUtils: Saved intermediate WAV: $wavPath');
    }

    // Step 3: Convert PCM bytes to Int16List (LAME requires Int16 samples)
    final int16Samples = pcmData.buffer.asInt16List();
    onProgress?.call(0.4);

    // Step 4: Encode to MP3
    final mp3Path = await _encodePcmToMp3(
      samples: int16Samples,
      sampleRate: sampleRate,
      channels: channels,
      outputPath: outputPath ?? _getDefaultOutputPath(opusFilePath),
      onProgress: (progress) {
        // Map encoding progress from 0.4 to 1.0
        onProgress?.call(0.4 + progress * 0.6);
      },
    );

    onProgress?.call(1.0);
    return mp3Path;
  }

  /// Decode Opus file to PCM16 samples using FFI
  Future<Uint8List> _decodeOpusToPcm({
    required String opusFilePath,
    required int sampleRate,
    required int channels,
  }) async {
    final file = File(opusFilePath);
    if (!file.existsSync()) {
      throw Exception('Opus file not found: $opusFilePath');
    }

    final opusData = await file.readAsBytes();

    if (opusData.isEmpty) {
      throw Exception('Opus file is empty');
    }

    debugPrint('AudioConverterUtils: File size: ${opusData.length} bytes');

    // Load opus library via opus_flutter
    final libopus = await opus_flutter.load();

    // Create FFI-based decoder
    final decoder = _OpusDecoderFFI(libopus, sampleRate, channels);

    try {
      // Decode using streaming approach (like reference code)
      final pcmData = await _decodeOpusStream(decoder, opusData, channels);

      debugPrint('AudioConverterUtils: Decoded PCM size: ${pcmData.length} bytes');

      if (pcmData.isEmpty) {
        throw Exception('Failed to decode any Opus frames');
      }

      return pcmData;
    } finally {
      decoder.dispose();
    }
  }

  /// Decode opus data stream frame by frame
  Future<Uint8List> _decodeOpusStream(
    _OpusDecoderFFI decoder,
    Uint8List opusData,
    int channels,
  ) async {
    final outputBuilder = BytesBuilder(copy: false);
    int offset = 0;
    int frameCount = 0;
    int errorCount = 0;

    // Process fixed-size frames (80 bytes each for Note device)
    while (offset + _noteOpusFrameSize <= opusData.length) {
      final frameData = opusData.sublist(offset, offset + _noteOpusFrameSize);
      offset += _noteOpusFrameSize;

      try {
        final pcmFrame = decoder.decode(frameData, _opusPcmFrameSize);
        outputBuilder.add(pcmFrame.buffer.asUint8List());
        frameCount++;
      } catch (e) {
        errorCount++;
        if (errorCount <= 10) {
          debugPrint('AudioConverterUtils: Error decoding frame $frameCount: $e');
        }
        // Continue with other frames
      }
    }

    // Handle remaining bytes
    final remaining = opusData.length - offset;
    if (remaining > 0) {
      debugPrint('AudioConverterUtils: Warning - $remaining bytes remaining after parsing $frameCount frames');
    }

    debugPrint('AudioConverterUtils: Decoded $frameCount frames, $errorCount errors');

    return outputBuilder.toBytes();
  }

  /// Encode Int16 samples to MP3
  Future<String> _encodePcmToMp3({
    required Int16List samples,
    required int sampleRate,
    required int channels,
    required String outputPath,
    void Function(double progress)? onProgress,
  }) async {
    // Create LAME encoder
    final encoder = LameMp3Encoder(
      sampleRate: sampleRate,
      numChannels: channels,
      bitRate: defaultBitrate,
    );

    // Create output file
    final outputFile = File(outputPath);
    final sink = outputFile.openWrite();

    try {
      final totalSamples = samples.length;
      int processedSamples = 0;

      // Process in chunks
      while (processedSamples < totalSamples) {
        final chunkEnd = (processedSamples + _chunkSamples).clamp(0, totalSamples);
        final chunk = Int16List.sublistView(samples, processedSamples, chunkEnd);

        // Encode chunk
        final mp3Chunk = await encoder.encode(leftChannel: chunk);
        if (mp3Chunk.isNotEmpty) {
          sink.add(mp3Chunk);
        }

        processedSamples = chunkEnd;
        onProgress?.call(processedSamples / totalSamples);
      }

      // Flush remaining data
      final lastChunk = await encoder.flush();
      if (lastChunk.isNotEmpty) {
        sink.add(lastChunk);
      }
    } finally {
      await sink.close();
    }

    return outputPath;
  }

  /// Get default output path by replacing extension with .mp3
  String _getDefaultOutputPath(String sourcePath) {
    final lastDot = sourcePath.lastIndexOf('.');
    if (lastDot > 0) {
      return '${sourcePath.substring(0, lastDot)}.mp3';
    }
    return '$sourcePath.mp3';
  }

  /// Get WAV output path by replacing extension with .wav
  String _getWavOutputPath(String sourcePath) {
    final lastDot = sourcePath.lastIndexOf('.');
    if (lastDot > 0) {
      return '${sourcePath.substring(0, lastDot)}.wav';
    }
    return '$sourcePath.wav';
  }

  /// Save PCM data as WAV file with proper header
  Future<void> _savePcmAsWav({
    required Uint8List pcmData,
    required int sampleRate,
    required int channels,
    required String outputPath,
  }) async {
    const int bitsPerSample = 16;
    final int byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final int blockAlign = channels * bitsPerSample ~/ 8;
    final int dataSize = pcmData.length;
    final int fileSize = 36 + dataSize;

    // Build WAV header (44 bytes)
    final header = ByteData(44);

    // RIFF chunk descriptor
    header.setUint8(0, 0x52); // 'R'
    header.setUint8(1, 0x49); // 'I'
    header.setUint8(2, 0x46); // 'F'
    header.setUint8(3, 0x46); // 'F'
    header.setUint32(4, fileSize, Endian.little); // File size - 8
    header.setUint8(8, 0x57);  // 'W'
    header.setUint8(9, 0x41);  // 'A'
    header.setUint8(10, 0x56); // 'V'
    header.setUint8(11, 0x45); // 'E'

    // fmt sub-chunk
    header.setUint8(12, 0x66); // 'f'
    header.setUint8(13, 0x6D); // 'm'
    header.setUint8(14, 0x74); // 't'
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    header.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
    header.setUint16(22, channels, Endian.little); // NumChannels
    header.setUint32(24, sampleRate, Endian.little); // SampleRate
    header.setUint32(28, byteRate, Endian.little); // ByteRate
    header.setUint16(32, blockAlign, Endian.little); // BlockAlign
    header.setUint16(34, bitsPerSample, Endian.little); // BitsPerSample

    // data sub-chunk
    header.setUint8(36, 0x64); // 'd'
    header.setUint8(37, 0x61); // 'a'
    header.setUint8(38, 0x74); // 't'
    header.setUint8(39, 0x61); // 'a'
    header.setUint32(40, dataSize, Endian.little); // Subchunk2Size

    // Write WAV file
    final file = File(outputPath);
    final sink = file.openWrite();
    try {
      sink.add(header.buffer.asUint8List());
      sink.add(pcmData);
    } finally {
      await sink.close();
    }

    debugPrint('AudioConverterUtils: WAV file saved - ${pcmData.length} PCM bytes, $channels channels, ${sampleRate}Hz');
  }

  /// Convert WAV file to MP3
  /// For cases where WAV is already available
  Future<String> convertWavToMp3({
    required String wavFilePath,
    String? outputPath,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(wavFilePath);
    if (!file.existsSync()) {
      throw Exception('WAV file not found: $wavFilePath');
    }

    final wavData = await file.readAsBytes();

    // Parse WAV header to get audio parameters
    if (wavData.length < 44) {
      throw Exception('Invalid WAV file: too short');
    }

    // Read WAV parameters from header
    final byteData = ByteData.sublistView(wavData);
    final channels = byteData.getUint16(22, Endian.little);
    final sampleRate = byteData.getUint32(24, Endian.little);

    // Skip 44-byte WAV header to get PCM data
    final pcmData = Uint8List.sublistView(wavData, 44);

    onProgress?.call(0.2);

    // Convert to Int16 samples
    final int16Samples = pcmData.buffer.asInt16List();

    onProgress?.call(0.3);

    // Encode to MP3
    final mp3Path = await _encodePcmToMp3(
      samples: int16Samples,
      sampleRate: sampleRate,
      channels: channels,
      outputPath: outputPath ?? _getDefaultOutputPath(wavFilePath),
      onProgress: (progress) {
        onProgress?.call(0.3 + progress * 0.7);
      },
    );

    onProgress?.call(1.0);
    return mp3Path;
  }

  /// Batch convert multiple Opus files to MP3
  Future<List<String>> batchConvertToMp3({
    required List<String> opusFilePaths,
    int sampleRate = 16000,
    int channels = 1,
    void Function(int current, int total, double fileProgress)? onProgress,
  }) async {
    final List<String> results = [];

    for (int i = 0; i < opusFilePaths.length; i++) {
      try {
        final mp3Path = await convertOpusToMp3(
          opusFilePath: opusFilePaths[i],
          sampleRate: sampleRate,
          channels: channels,
          onProgress: (progress) {
            onProgress?.call(i + 1, opusFilePaths.length, progress);
          },
        );
        results.add(mp3Path);
      } catch (e) {
        debugPrint('AudioConverterUtils: Failed to convert ${opusFilePaths[i]}: $e');
        // Continue with other files
      }
    }

    return results;
  }
}

// ============ FFI-based Opus Decoder ============

/// FFI function signatures for opus library
typedef OpusDecoderCreateNative = Pointer<Void> Function(
    Int32 sampleRate, Int32 channels, Pointer<Int32> error);
typedef OpusDecoderCreateDart = Pointer<Void> Function(
    int sampleRate, int channels, Pointer<Int32> error);

typedef OpusDecodeNative = Int32 Function(Pointer<Void> decoder,
    Pointer<Uint8> data, Int32 len, Pointer<Int16> pcm, Int32 frameSize, Int32 decodeFec);
typedef OpusDecodeDart = int Function(Pointer<Void> decoder,
    Pointer<Uint8> data, int len, Pointer<Int16> pcm, int frameSize, int decodeFec);

typedef OpusDecoderDestroyNative = Void Function(Pointer<Void> decoder);
typedef OpusDecoderDestroyDart = void Function(Pointer<Void> decoder);

/// FFI-based Opus decoder (matches reference implementation)
class _OpusDecoderFFI {
  final DynamicLibrary _lib;
  final Pointer<Void> _decoder;
  final int _channels;

  late final OpusDecodeDart _opusDecode;
  late final OpusDecoderDestroyDart _opusDecoderDestroy;

  _OpusDecoderFFI(this._lib, int sampleRate, int channels)
      : _channels = channels,
        _decoder = _initializeDecoder(_lib, sampleRate, channels) {
    _opusDecode = _lib
        .lookupFunction<OpusDecodeNative, OpusDecodeDart>('opus_decode');
    _opusDecoderDestroy = _lib
        .lookupFunction<OpusDecoderDestroyNative, OpusDecoderDestroyDart>(
            'opus_decoder_destroy');
  }

  static Pointer<Void> _initializeDecoder(
      DynamicLibrary lib, int sampleRate, int channels) {
    final opusDecoderCreate = lib
        .lookupFunction<OpusDecoderCreateNative, OpusDecoderCreateDart>(
            'opus_decoder_create');

    final errorPtr = calloc<Int32>();
    try {
      final decoder = opusDecoderCreate(sampleRate, channels, errorPtr);
      final error = errorPtr.value;
      if (error != 0) {
        throw Exception(
            'Opus decoder initialization failed with error code: $error');
      }
      return decoder;
    } finally {
      calloc.free(errorPtr);
    }
  }

  /// Decode opus frame to PCM samples
  /// Returns Int16List of decoded samples
  Int16List decode(Uint8List encodedData, int frameSize) {
    final pcmPtr = calloc<Int16>(frameSize * _channels);
    final dataPtr = calloc<Uint8>(encodedData.length);

    try {
      // Copy input data to native memory
      dataPtr.asTypedList(encodedData.length).setAll(0, encodedData);

      // Decode
      final samplesDecoded = _opusDecode(
        _decoder,
        dataPtr,
        encodedData.length,
        pcmPtr,
        frameSize,
        0, // decodeFec = 0
      );

      if (samplesDecoded < 0) {
        throw Exception('Opus decode failed with error code: $samplesDecoded');
      }

      // Copy result to Dart
      return Int16List.fromList(pcmPtr.asTypedList(samplesDecoded * _channels));
    } finally {
      calloc.free(dataPtr);
      calloc.free(pcmPtr);
    }
  }

  void dispose() {
    if (_decoder != nullptr) {
      _opusDecoderDestroy(_decoder);
    }
  }
}
