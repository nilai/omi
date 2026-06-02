import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../http/api/mp_memory.dart';
import '../../http/schema/mp_memory.dart';
import 'audio_record.dart';


/// MP音频上传服务
///
/// 负责处理MP音频文件的完整上传流程：
/// 1. 获取预签名URL
/// 2. 上传文件到S3
class MPAudioUploadService {
  /// 最大重试次数（用于网络错误）
  static const int _maxRetries = 3;

  /// 上传音频文件的完整流程
  ///
  /// [audioFile] 要上传的音频文件
  /// [onProgress] 可选的进度回调，参数为当前步骤 (1-3) 和总步骤数 (3)
  ///
  /// 返回 上传后的uri, 不同场景保存使用
  ///
  /// 按文件扩展名选择 MIME 类型（如 `.aac` → `audio/aac`）直接上传。
  Future<String?> uploadMPAudio(
    File audioFile, {
    Function(int current, int total)? onProgress,
  }) async {
    final File? resolved = await _resolveAudioFileForUpload(audioFile);
    if (resolved == null) {
      return null;
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
  Future<String?> uploadRecordFile(
    File file, {
    required String contentType,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      debugPrint(
        'MPAudioUploadService: uploading ${file.path} with type $contentType',
      );

      onProgress?.call(1, 3);
      final presignedUrl = await _getPresignedUrlWithRetry(contentType);
      if (presignedUrl == null) {
        debugPrint('MPAudioUploadService: failed to get presigned URL');
        return null;
      }
      debugPrint('MPAudioUploadService: got presigned URL: ${presignedUrl.uri}');

      onProgress?.call(2, 3);
      final uploadSuccess = await _uploadToS3WithRetry(
        presignedUrl.uploadUrl,
        file,
        contentType,
      );
      if (!uploadSuccess) {
        debugPrint('MPAudioUploadService: failed to upload to S3');
        return null;
      }
      debugPrint('MPAudioUploadService: uploaded to S3 successfully');
      onProgress?.call(3, 3);
      return presignedUrl.uri;
    } catch (e) {
      debugPrint('MPAudioUploadService: exception during upload: $e');
      return null;
    }
  }

  /// 上传音频字节的完整流程
  ///
  /// [audioBytes] 要上传的音频字节数组
  /// [contentType] 音频文件的MIME类型
  /// [onProgress] 可选的进度回调，参数为当前步骤 (1-3) 和总步骤数 (3)
  ///
  /// 返回 上传后的uri, 不同场景保存使用
  ///
  Future<String?> uploadMPAudioBytes(
    List<int> audioBytes,
    String contentType, {
    Function(int current, int total)? onProgress,
  }) async {
    try {
      debugPrint('MPAudioUploadService: uploading bytes with type $contentType');

      // 步骤 1: 获取预签名 URL
      onProgress?.call(1, 3);
      final presignedUrl = await _getPresignedUrlWithRetry(contentType);
      if (presignedUrl == null) {
        debugPrint('MPAudioUploadService: failed to get presigned URL');
        return null;
      }
      debugPrint('MPAudioUploadService: got presigned URL: ${presignedUrl.uri}');

      // 步骤 2: 上传字节到 S3
      onProgress?.call(2, 3);
      final uploadSuccess = await _uploadBytesToS3WithRetry(
        presignedUrl.uploadUrl,
        audioBytes,
        contentType,
      );
      if (!uploadSuccess) {
        debugPrint('MPAudioUploadService: failed to upload bytes to S3');
        return null;
      }
      debugPrint('MPAudioUploadService: uploaded bytes to S3 successfully');
      return presignedUrl.uri;
    } catch (e) {
      debugPrint('MPAudioUploadService: exception during bytes upload: $e');
      return null;
    }
  }

  Future<MPGetUploadRecordUrlResponse?> _getPresignedUrlWithRetry(
    String contentType,
  ) async {
    for (int i = 0; i <= _maxRetries; i++) {
      try {
        //  final result = await getPresignedUrl(contentType);
        final req = MPGetUploadRecordUrlRequest(
          contentType: contentType,
        );
        final result = await getUploadRecordUrl(req);
        if (result != null) return result;
      } catch (e) {
        debugPrint('MPAudioUploadService: getPresignedUrl attempt ${i + 1} failed: $e');
        if (i == _maxRetries) return null;
        // 简单的延迟重试
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return null;
  }

  /// 带重试的上传到 S3
  Future<bool> _uploadToS3WithRetry(
    String uploadUrl,
    File audioFile,
    String contentType,
  ) async {
    for (int i = 0; i <= _maxRetries; i++) {
      try {
        final result = await uploadAudioToS3(uploadUrl, audioFile, contentType);
        if (result) return true;
      } catch (e) {
        debugPrint('MPAudioUploadService: uploadToS3 attempt ${i + 1} failed: $e');
        if (i == _maxRetries) return false;
        // 简单的延迟重试
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return false;
  }

  /// 带重试的上传字节到 S3
  Future<bool> _uploadBytesToS3WithRetry(
    String uploadUrl,
    List<int> audioBytes,
    String contentType,
  ) async {
    for (int i = 0; i <= _maxRetries; i++) {
      try {
        final result = await uploadAudioToS3Bytes(uploadUrl, audioBytes, contentType);
        if (result) return true;
      } catch (e) {
        debugPrint('MPAudioUploadService: uploadBytesToS3 attempt ${i + 1} failed: $e');
        if (i == _maxRetries) return false;
        // 简单的延迟重试
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return false;
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
