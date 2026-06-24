import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../http/api/mp_memory.dart';
import '../../http/schema/mp_memory.dart';
import 'audio_record.dart';
import 'mp_audio_upload_background_support.dart';

/// 音频/伴生文件上传结果（含用户可读的错误信息）。
class MPAudioUploadResult {
  const MPAudioUploadResult._({this.uri, this.errorMessage});

  const MPAudioUploadResult.success(String uri) : this._(uri: uri);

  const MPAudioUploadResult.failure(String errorMessage) : this._(errorMessage: errorMessage);

  final String? uri;
  final String? errorMessage;

  bool get isSuccess => uri != null && uri!.isNotEmpty;
}

/// MP音频上传服务
///
/// 负责处理MP音频文件的完整上传流程：
/// 1. 获取预签名URL
/// 2. 上传文件到S3
class MPAudioUploadService {
  /// 获取预签名 URL 的最大重试次数
  static const int _maxRetries = 3;

  /// S3 PUT 上传最大重试次数（首次上传 + 2 次重试）
  static const int _s3MaxRetries = 2;

  /// 上传音频文件的完整流程
  ///
  /// [audioFile] 要上传的音频文件
  /// [onProgress] 可选的进度回调，参数为当前步骤 (1-3) 和总步骤数 (3)
  ///
  /// 返回上传结果；失败时 [MPAudioUploadResult.errorMessage] 含网络等原因说明。
  ///
  /// 按文件扩展名选择 MIME 类型（如 `.aac` → `audio/aac`）直接上传。
  Future<MPAudioUploadResult> uploadMPAudio(
    File audioFile, {
    Function(int current, int total)? onProgress,
  }) async {
    final File? resolved = await _resolveAudioFileForUpload(audioFile);
    if (resolved == null) {
      return const MPAudioUploadResult.failure('Recording file not found.');
    }
    return uploadRecordFile(
      resolved,
      contentType: getAudioMimeType(resolved.path),
      onProgress: onProgress,
    );
  }

  /// 删除本地录音文件；若存在同主文件名的 `.mp3` 伴生文件（历史遗留）则一并删除。
  static Future<void> deleteLocalRecordingArtifacts(String? recordPath) async {
    final String trimmed = recordPath?.trim() ?? '';
    if (trimmed.isEmpty) {
      return;
    }
    try {
      final File file = File(trimmed);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('MPAudioUploadService: delete recording failed: $e');
    }
    if (p.extension(trimmed).toLowerCase() == '.mp3') {
      return;
    }
    final String mp3Path = p.join(
      p.dirname(trimmed),
      '${p.basenameWithoutExtension(trimmed)}.mp3',
    );
    if (mp3Path == trimmed) {
      return;
    }
    try {
      final File mp3 = File(mp3Path);
      if (await mp3.exists()) {
        await mp3.delete();
      }
    } catch (e) {
      debugPrint('MPAudioUploadService: delete converted mp3 failed: $e');
    }
  }

  /// 上传前校验文件存在；不做格式转码。
  static Future<File?> _resolveAudioFileForUpload(File audioFile) async {
    if (!await audioFile.exists()) {
      debugPrint('MPAudioUploadService: file does not exist: ${audioFile.path}');
      return null;
    }
    return audioFile;
  }

  /// 使用指定 [contentType] 走预签名 URL + S3（与 [uploadMPAudio] 相同步骤）。
  ///
  /// 例如 companion `.txt` 使用 `text/plain; charset=utf-8`。
  Future<MPAudioUploadResult> uploadRecordFile(
    File file, {
    required String contentType,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      debugPrint(
        'MPAudioUploadService: uploading ${file.path} with type $contentType',
      );

      _emitUploadStepProgress(onProgress, 1, 3, 'getPresignedUrl');
      final ({MPGetUploadRecordUrlResponse? response, Object? lastError}) presigned =
          await _getPresignedUrlWithRetry(contentType);
      if (presigned.response == null) {
        debugPrint('MPAudioUploadService: failed to get presigned URL');
        return MPAudioUploadResult.failure(
          _formatPresignedUrlFailure(presigned.lastError),
        );
      }
      debugPrint('MPAudioUploadService: got presigned URL: ${presigned.response!.uri}');

      _emitUploadStepProgress(onProgress, 2, 3, 'uploadToS3');
      final ({bool success, Object? lastError}) s3Result = await _uploadToS3WithRetry(
        presigned.response!.uploadUrl,
        file,
        contentType,
      );
      if (!s3Result.success) {
        debugPrint('MPAudioUploadService: failed to upload to S3');
        return MPAudioUploadResult.failure(
          _formatS3UploadFailure(s3Result.lastError),
        );
      }
      debugPrint('MPAudioUploadService: uploaded to S3 successfully');
      _emitUploadStepProgress(onProgress, 3, 3, 'done');
      return MPAudioUploadResult.success(presigned.response!.uri);
    } catch (e) {
      debugPrint('MPAudioUploadService: exception during upload: $e');
      return MPAudioUploadResult.failure(formatUploadError(e));
    }
  }

  /// 上传音频字节的完整流程
  ///
  /// [audioBytes] 要上传的音频字节数组
  /// [contentType] 音频文件的MIME类型
  /// [onProgress] 可选的进度回调，参数为当前步骤 (1-3) 和总步骤数 (3)
  ///
  /// 返回上传结果；失败时 [MPAudioUploadResult.errorMessage] 含网络等原因说明。
  Future<MPAudioUploadResult> uploadMPAudioBytes(
    List<int> audioBytes,
    String contentType, {
    Function(int current, int total)? onProgress,
  }) async {
    try {
      debugPrint('MPAudioUploadService: uploading bytes with type $contentType');

      _emitUploadStepProgress(onProgress, 1, 3, 'getPresignedUrl');
      final ({MPGetUploadRecordUrlResponse? response, Object? lastError}) presigned =
          await _getPresignedUrlWithRetry(contentType);
      if (presigned.response == null) {
        debugPrint('MPAudioUploadService: failed to get presigned URL');
        return MPAudioUploadResult.failure(
          _formatPresignedUrlFailure(presigned.lastError),
        );
      }
      debugPrint('MPAudioUploadService: got presigned URL: ${presigned.response!.uri}');

      _emitUploadStepProgress(onProgress, 2, 3, 'uploadToS3');
      final ({bool success, Object? lastError}) s3Result = await _uploadBytesToS3WithRetry(
        presigned.response!.uploadUrl,
        audioBytes,
        contentType,
      );
      if (!s3Result.success) {
        debugPrint('MPAudioUploadService: failed to upload bytes to S3');
        return MPAudioUploadResult.failure(
          _formatS3UploadFailure(s3Result.lastError),
        );
      }
      debugPrint('MPAudioUploadService: uploaded bytes to S3 successfully');
      _emitUploadStepProgress(onProgress, 3, 3, 'done');
      return MPAudioUploadResult.success(presigned.response!.uri);
    } catch (e) {
      debugPrint('MPAudioUploadService: exception during bytes upload: $e');
      return MPAudioUploadResult.failure(formatUploadError(e));
    }
  }

  void _emitUploadStepProgress(
    void Function(int current, int total)? onProgress,
    int current,
    int total,
    String step,
  ) {
    debugPrint('MPAudioUploadService: upload step $current/$total ($step)');
    onProgress?.call(current, total);
  }

  Future<({MPGetUploadRecordUrlResponse? response, Object? lastError})> _getPresignedUrlWithRetry(
    String contentType,
  ) async {
    Object? lastError;
    for (int i = 0; i <= _maxRetries; i++) {
      final int attempt = i + 1;
      final int maxAttempts = _maxRetries + 1;
      debugPrint(
        'MPAudioUploadService: getPresignedUrl attempt $attempt/$maxAttempts contentType=$contentType',
      );
      try {
        final req = MPGetUploadRecordUrlRequest(
          contentType: contentType,
        );
        final result = await getUploadRecordUrl(req);
        if (result != null) {
          debugPrint('MPAudioUploadService: getPresignedUrl success on attempt $attempt');
          return (response: result, lastError: null);
        }
        lastError ??= StateError('Server did not return an upload URL.');
        debugPrint('MPAudioUploadService: getPresignedUrl attempt $attempt returned null');
      } catch (e) {
        lastError = e;
        debugPrint('MPAudioUploadService: getPresignedUrl attempt $attempt failed: $e');
      }
      if (i == _maxRetries) {
        debugPrint('MPAudioUploadService: getPresignedUrl failed after $maxAttempts attempts');
        return (response: null, lastError: lastError);
      }
      debugPrint('MPAudioUploadService: getPresignedUrl retry in 1s (next attempt ${attempt + 1})');
      await Future.delayed(const Duration(seconds: 1));
    }
    return (response: null, lastError: lastError);
  }

  /// 将异常格式化为用户可读的上传错误文案（优先识别网络类错误）。
  static String formatUploadError(Object? error) {
    if (error == null) {
      return 'Upload failed. Please try again.';
    }
    if (error is TimeoutException) {
      return 'Network timeout. Please check your connection and try again.';
    }
    if (error is SocketException) {
      return 'No network connection. Please check your network and try again.';
    }
    if (error is HandshakeException) {
      return 'Secure connection failed. Please check your network and try again.';
    }
    if (error is HttpException || error is IOException) {
      return 'Network error. Please check your connection and try again.';
    }
    if (MPAudioUploadBackgroundSupport.isLikelyBackgroundNetworkFailure(error)) {
      return 'Upload interrupted. Please reopen the app and try again.';
    }
    final String message = error.toString();
    if (_looksLikeNetworkMessage(message)) {
      return 'Network error: $message';
    }
    return 'Upload failed: $message';
  }

  static String _formatPresignedUrlFailure(Object? lastError) {
    if (lastError == null) {
      return 'Failed to get upload URL. Please check your network and try again.';
    }
    return 'Failed to get upload URL. ${formatUploadError(lastError)}';
  }

  static String _formatS3UploadFailure(Object? lastError) {
    if (lastError == null) {
      return 'Failed to upload file. Please check your network and try again.';
    }
    return 'Failed to upload file. ${formatUploadError(lastError)}';
  }

  static bool _looksLikeNetworkMessage(String message) {
    final String lower = message.toLowerCase();
    return lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('timeout') ||
        lower.contains('timed out') ||
        lower.contains('host lookup') ||
        lower.contains('failed host lookup') ||
        lower.contains('socket') ||
        lower.contains('offline');
  }

  /// 带重试的上传到 S3（连续 60s 无网络收发则超时；退后台网络中断会等待回前台后继续重试）。
  Future<({bool success, Object? lastError})> _uploadToS3WithRetry(
    String uploadUrl,
    File audioFile,
    String contentType,
  ) async {
    final int fileSize = await audioFile.length();
    int foregroundAttempts = 0;
    Object? lastError;
    const int maxForegroundAttempts = _s3MaxRetries + 1;
    while (foregroundAttempts < maxForegroundAttempts) {
      final int attempt = foregroundAttempts + 1;
      debugPrint(
        'MPAudioUploadService: uploadToS3 attempt $attempt/$maxForegroundAttempts '
        'path=${audioFile.path} size=$fileSize contentType=$contentType',
      );
      try {
        final bool result = await uploadAudioToS3(uploadUrl, audioFile, contentType);
        if (result) {
          debugPrint('MPAudioUploadService: uploadToS3 success on attempt $attempt');
          return (success: true, lastError: null);
        }
        lastError ??= StateError('S3 upload returned failure.');
        debugPrint('MPAudioUploadService: uploadToS3 attempt $attempt failed (returned false)');
        if (!MPAudioUploadBackgroundSupport.isAppInForeground) {
          await MPAudioUploadBackgroundSupport.waitUntilForegroundForRetry();
          continue;
        }
      } on TimeoutException catch (e) {
        lastError = e;
        debugPrint('MPAudioUploadService: uploadToS3 attempt $attempt idle timeout: $e');
      } catch (e) {
        lastError = e;
        debugPrint('MPAudioUploadService: uploadToS3 attempt $attempt failed: $e');
        if (MPAudioUploadBackgroundSupport.isLikelyBackgroundNetworkFailure(e)) {
          await MPAudioUploadBackgroundSupport.waitUntilForegroundForRetry();
          continue;
        }
      }
      foregroundAttempts++;
      if (foregroundAttempts >= maxForegroundAttempts) {
        break;
      }
      debugPrint(
        'MPAudioUploadService: uploadToS3 retry in 1s (next attempt ${foregroundAttempts + 1})',
      );
      await Future.delayed(const Duration(seconds: 1));
    }
    debugPrint('MPAudioUploadService: uploadToS3 failed after $maxForegroundAttempts attempts');
    return (success: false, lastError: lastError);
  }

  /// 带重试的上传字节到 S3（连续 60s 无网络收发则超时；退后台网络中断会等待回前台后继续重试）。
  Future<({bool success, Object? lastError})> _uploadBytesToS3WithRetry(
    String uploadUrl,
    List<int> audioBytes,
    String contentType,
  ) async {
    int foregroundAttempts = 0;
    Object? lastError;
    const int maxForegroundAttempts = _s3MaxRetries + 1;
    while (foregroundAttempts < maxForegroundAttempts) {
      final int attempt = foregroundAttempts + 1;
      debugPrint(
        'MPAudioUploadService: uploadBytesToS3 attempt $attempt/$maxForegroundAttempts '
        'size=${audioBytes.length} contentType=$contentType',
      );
      try {
        final bool result = await uploadAudioToS3Bytes(uploadUrl, audioBytes, contentType);
        if (result) {
          debugPrint('MPAudioUploadService: uploadBytesToS3 success on attempt $attempt');
          return (success: true, lastError: null);
        }
        lastError ??= StateError('S3 upload returned failure.');
        debugPrint('MPAudioUploadService: uploadBytesToS3 attempt $attempt failed (returned false)');
        if (!MPAudioUploadBackgroundSupport.isAppInForeground) {
          await MPAudioUploadBackgroundSupport.waitUntilForegroundForRetry();
          continue;
        }
      } on TimeoutException catch (e) {
        lastError = e;
        debugPrint('MPAudioUploadService: uploadBytesToS3 attempt $attempt idle timeout: $e');
      } catch (e) {
        lastError = e;
        debugPrint('MPAudioUploadService: uploadBytesToS3 attempt $attempt failed: $e');
        if (MPAudioUploadBackgroundSupport.isLikelyBackgroundNetworkFailure(e)) {
          await MPAudioUploadBackgroundSupport.waitUntilForegroundForRetry();
          continue;
        }
      }
      foregroundAttempts++;
      if (foregroundAttempts >= maxForegroundAttempts) {
        break;
      }
      debugPrint(
        'MPAudioUploadService: uploadBytesToS3 retry in 1s (next attempt ${foregroundAttempts + 1})',
      );
      await Future.delayed(const Duration(seconds: 1));
    }
    debugPrint('MPAudioUploadService: uploadBytesToS3 failed after $maxForegroundAttempts attempts');
    return (success: false, lastError: lastError);
  }

  /// 验证音频文件是否有效
  ///
  /// 检查文件是否存在、大小是否合理、格式是否支持
  Future<bool> validateMPAudioFile(File audioFile) async {
    try {
      // 检查文件是否存在
      if (!await audioFile.exists()) {
        debugPrint('MPAudioUploadService: file does not exist');
        return false;
      }

      // 检查文件大小（例如：不超过 100MB）
      final fileSize = await audioFile.length();
      if (fileSize == 0) {
        debugPrint('MPAudioUploadService: file is empty');
        return false;
      }
      if (fileSize > 100 * 1024 * 1024) {
        debugPrint('MPAudioUploadService: file is too large ($fileSize bytes)');
        return false;
      }

      // 检查文件扩展名
      final filename = audioFile.path.toLowerCase();
      final hasValidExtension = audioExtensions.any((ext) => filename.endsWith(ext));
      if (!hasValidExtension) {
        debugPrint('MPAudioUploadService: unsupported file format');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('MPAudioUploadService: error validating file: $e');
      return false;
    }
  }
}
