import 'dart:io';

import 'package:flutter/material.dart';
import 'package:omi/backend/http/api/audio_record.dart';
import 'package:omi/backend/schema/schema.dart';

/// 录音上传服务
///
/// 负责处理音频文件的完整上传流程：
/// 1. 获取预签名URL
/// 2. 上传文件到S3
/// 3. 创建录音记录
class AudioRecordService {
  /// 最大重试次数（用于网络错误）
  static const int _maxRetries = 1;

  /// 上传音频文件的完整流程
  ///
  /// [audioFile] 要上传的音频文件
  /// [onProgress] 可选的进度回调，参数为当前步骤 (1-3) 和总步骤数 (3)
  ///
  /// 返回创建的 [AudioRecord]，失败返回 null
  Future<AudioRecord?> uploadAudioRecord(
    File audioFile, {
    Function(int current, int total)? onProgress,
  }) async {
    try {
      // 获取文件的 MIME 类型
      final contentType = getAudioMimeType(audioFile.path);
      debugPrint('AudioRecordService: uploading ${audioFile.path} with type $contentType');

      // 步骤 1: 获取预签名 URL
      onProgress?.call(1, 3);
      final presignedUrl = await _getPresignedUrlWithRetry(contentType);
      if (presignedUrl == null) {
        debugPrint('AudioRecordService: failed to get presigned URL');
        return null;
      }
      debugPrint('AudioRecordService: got presigned URL: ${presignedUrl.uri}');

      // 步骤 2: 上传文件到 S3
      onProgress?.call(2, 3);
      final uploadSuccess = await _uploadToS3WithRetry(
        presignedUrl.uploadUrl,
        audioFile,
        contentType,
      );
      if (!uploadSuccess) {
        debugPrint('AudioRecordService: failed to upload to S3');
        return null;
      }
      debugPrint('AudioRecordService: uploaded to S3 successfully');

      // 步骤 3: 创建录音记录
      onProgress?.call(3, 3);
      final recordTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final audioRecord = await _createRecordWithRetry(
        presignedUrl.uri,
        recordTs,
      );

      if (audioRecord != null && audioRecord.isSuccess) {
        debugPrint('AudioRecordService: created record successfully: ${audioRecord.audioRecordId}');
        return audioRecord;
      } else {
        debugPrint('AudioRecordService: failed to create record');
        return null;
      }
    } catch (e) {
      debugPrint('AudioRecordService: exception during upload: $e');
      return null;
    }
  }

  /// 带重试的获取预签名 URL
  Future<PresignedUrlResponse?> _getPresignedUrlWithRetry(
    String contentType,
  ) async {
    for (int i = 0; i <= _maxRetries; i++) {
      try {
        final result = await getPresignedUrl(contentType);
        if (result != null) return result;
      } catch (e) {
        debugPrint('AudioRecordService: getPresignedUrl attempt ${i + 1} failed: $e');
        if (i == _maxRetries) return null;
        // 简单的延迟重试
        await Future.delayed(Duration(seconds: 1));
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
        debugPrint('AudioRecordService: uploadToS3 attempt ${i + 1} failed: $e');
        if (i == _maxRetries) return false;
        // 简单的延迟重试
        await Future.delayed(Duration(seconds: 1));
      }
    }
    return false;
  }

  /// 带重试的创建录音记录
  Future<AudioRecord?> _createRecordWithRetry(
    String audioUri,
    int recordTs,
  ) async {
    for (int i = 0; i <= _maxRetries; i++) {
      try {
        final result = await createAudioRecord(audioUri, recordTs);
        if (result != null) return result;
      } catch (e) {
        debugPrint('AudioRecordService: createRecord attempt ${i + 1} failed: $e');
        if (i == _maxRetries) return null;
        // 简单的延迟重试
        await Future.delayed(Duration(seconds: 1));
      }
    }
    return null;
  }

  /// 验证音频文件是否有效
  ///
  /// 检查文件是否存在、大小是否合理、格式是否支持
  Future<bool> validateAudioFile(File audioFile) async {
    try {
      // 检查文件是否存在
      if (!await audioFile.exists()) {
        debugPrint('AudioRecordService: file does not exist');
        return false;
      }

      // 检查文件大小（例如：不超过 100MB）
      final fileSize = await audioFile.length();
      if (fileSize == 0) {
        debugPrint('AudioRecordService: file is empty');
        return false;
      }
      if (fileSize > 100 * 1024 * 1024) {
        debugPrint('AudioRecordService: file is too large (${fileSize} bytes)');
        return false;
      }

      // 检查文件扩展名
      final filename = audioFile.path.toLowerCase();
      final supportedExtensions = ['.m4a', '.wav', '.mp3', '.aac'];
      final hasValidExtension = supportedExtensions.any((ext) => filename.endsWith(ext));
      if (!hasValidExtension) {
        debugPrint('AudioRecordService: unsupported file format');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('AudioRecordService: error validating file: $e');
      return false;
    }
  }
}
