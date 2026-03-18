import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../backend/http/mp_api/mp_memory.dart';
import '../backend/schema/mp/mp_memory.dart';

/// MP图片上传服务
///
/// 负责处理MP图片文件的完整上传流程：
/// 1. 获取预签名URL
/// 2. 上传文件到S3
/// 3. 返回上传后的URI
class MPImageUploadService {
  /// 最大重试次数（用于网络错误）
  static const int _maxRetries = 3;

  /// 图片文件扩展名到MIME类型的映射
  static final Map<String, String> _imageMimeTypes = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
    '.bmp': 'image/bmp',
    '.heic': 'image/heic',
    '.heif': 'image/heif',
  };

  /// 根据文件扩展名获取图片MIME类型
  static String getImageMimeType(String filename) {
    final extension = filename.toLowerCase().substring(filename.lastIndexOf('.'));
    return _imageMimeTypes[extension] ?? 'image/jpeg';
  }

  /// 上传图片文件的完整流程
  ///
  /// [imageFile] 要上传的图片文件
  /// [onProgress] 可选的进度回调，参数为当前步骤 (1-2) 和总步骤数 (2)
  ///
  /// 返回 上传后的uri, 不同场景保存使用
  Future<String?> uploadMPImage(
    File imageFile, {
    Function(int current, int total)? onProgress,
  }) async {
    try {
      // 获取文件的 MIME 类型
      final contentType = getImageMimeType(imageFile.path);
      debugPrint('MPImageUploadService: uploading ${imageFile.path} with type $contentType');

      // 步骤 1: 获取预签名 URL
      onProgress?.call(1, 2);
      final presignedUrl = await _getPresignedUrlWithRetry(contentType);
      if (presignedUrl == null) {
        debugPrint('MPImageUploadService: failed to get presigned URL');
        return null;
      }
      debugPrint('MPImageUploadService: got presigned URL: ${presignedUrl.uri}');

      // 步骤 2: 上传文件到 S3
      onProgress?.call(2, 2);
      final uploadSuccess = await _uploadToS3WithRetry(
        presignedUrl.uploadUrl,
        imageFile,
        contentType,
      );
      if (!uploadSuccess) {
        debugPrint('MPImageUploadService: failed to upload to S3');
        return null;
      }
      debugPrint('MPImageUploadService: uploaded to S3 successfully');
      return presignedUrl.uri;
    } catch (e) {
      debugPrint('MPImageUploadService: exception during upload: $e');
      return null;
    }
  }

  /// 上传图片字节的完整流程
  ///
  /// [imageBytes] 要上传的图片字节数组
  /// [contentType] 图片文件的MIME类型
  /// [onProgress] 可选的进度回调，参数为当前步骤 (1-2) 和总步骤数 (2)
  ///
  /// 返回 上传后的uri, 不同场景保存使用
  Future<String?> uploadMPImageBytes(
    List<int> imageBytes,
    String contentType, {
    Function(int current, int total)? onProgress,
  }) async {
    try {
      debugPrint('MPImageUploadService: uploading bytes with type $contentType');

      // 步骤 1: 获取预签名 URL
      onProgress?.call(1, 2);
      final presignedUrl = await _getPresignedUrlWithRetry(contentType);
      if (presignedUrl == null) {
        debugPrint('MPImageUploadService: failed to get presigned URL');
        return null;
      }
      debugPrint('MPImageUploadService: got presigned URL: ${presignedUrl.uri}');

      // 步骤 2: 上传字节到 S3
      onProgress?.call(2, 2);
      final uploadSuccess = await _uploadBytesToS3WithRetry(
        presignedUrl.uploadUrl,
        imageBytes,
        contentType,
      );
      if (!uploadSuccess) {
        debugPrint('MPImageUploadService: failed to upload bytes to S3');
        return null;
      }
      debugPrint('MPImageUploadService: uploaded bytes to S3 successfully');
      return presignedUrl.uri;
    } catch (e) {
      debugPrint('MPImageUploadService: exception during bytes upload: $e');
      return null;
    }
  }

  /// 带重试的获取预签名 URL
  Future<MPGetUploadRecordUrlResponse?> _getPresignedUrlWithRetry(
    String contentType,
  ) async {
    for (int i = 0; i <= _maxRetries; i++) {
      try {
        final req = MPGetUploadRecordUrlRequest(
          contentType: contentType,
        );
        final result = await getUploadRecordUrl(req);
        if (result != null) return result;
      } catch (e) {
        debugPrint('MPImageUploadService: getPresignedUrl attempt ${i + 1} failed: $e');
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
    File imageFile,
    String contentType,
  ) async {
    for (int i = 0; i <= _maxRetries; i++) {
      try {
        final result = await _uploadImageToS3(uploadUrl, imageFile, contentType);
        if (result) return true;
      } catch (e) {
        debugPrint('MPImageUploadService: uploadToS3 attempt ${i + 1} failed: $e');
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
    List<int> imageBytes,
    String contentType,
  ) async {
    for (int i = 0; i <= _maxRetries; i++) {
      try {
        final result = await _uploadImageBytesToS3(uploadUrl, imageBytes, contentType);
        if (result) return true;
      } catch (e) {
        debugPrint('MPImageUploadService: uploadBytesToS3 attempt ${i + 1} failed: $e');
        if (i == _maxRetries) return false;
        // 简单的延迟重试
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return false;
  }

  /// 上传图片文件到S3
  ///
  /// [uploadUrl] 预签名的S3上传URL
  /// [imageFile] 要上传的图片文件
  /// [contentType] 图片文件的MIME类型
  ///
  /// 返回 true 表示上传成功，false 表示失败
  Future<bool> _uploadImageToS3(
    String uploadUrl,
    File imageFile,
    String contentType,
  ) async {
    try {
      // 读取文件字节
      final bytes = await imageFile.readAsBytes();

      // 直接使用 PUT 方法上传到 S3 预签名 URL
      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': contentType,
          'Content-Length': bytes.length.toString(),
        },
        body: bytes,
      );

      debugPrint('MPImageUploadService: uploadImageToS3 status ${response.statusCode}');

      // S3 返回 200 或 204 表示成功
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        debugPrint('MPImageUploadService: uploadImageToS3 error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('MPImageUploadService: uploadImageToS3 exception: $e');
      return false;
    }
  }

  /// 上传图片字节到S3
  ///
  /// [uploadUrl] 预签名的S3上传URL
  /// [imageBytes] 要上传的图片字节数组
  /// [contentType] 图片文件的MIME类型
  ///
  /// 返回 true 表示上传成功，false 表示失败
  Future<bool> _uploadImageBytesToS3(
    String uploadUrl,
    List<int> imageBytes,
    String contentType,
  ) async {
    try {
      // 直接使用 PUT 方法上传到 S3 预签名 URL
      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': contentType,
          'Content-Length': imageBytes.length.toString(),
        },
        body: imageBytes,
      );

      debugPrint('MPImageUploadService: uploadImageBytesToS3 status ${response.statusCode}');

      // S3 返回 200 或 204 表示成功
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        debugPrint('MPImageUploadService: uploadImageBytesToS3 error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('MPImageUploadService: uploadImageBytesToS3 exception: $e');
      return false;
    }
  }
}
