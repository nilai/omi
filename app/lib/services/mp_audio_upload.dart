import 'dart:io'; 
 
 import 'package:flutter/material.dart'; 
 import 'package:omi/backend/http/api/audio_record.dart';
 import 'package:omi/backend/schema/schema.dart';

import '../backend/http/mp_api/mp_memory.dart';
import '../backend/schema/mp/mp_memory.dart';
 
 /// MP音频上传服务 
 /// 
 /// 负责处理MP音频文件的完整上传流程： 
 /// 1. 获取预签名URL 
 /// 2. 上传文件到S3 
 /// 3. 创建录音记录 
 class MPAudioUploadService { 
   /// 最大重试次数（用于网络错误） 
   static const int _maxRetries = 3; 
 
   /// 上传音频文件的完整流程 
   /// 
   /// [audioFile] 要上传的音频文件 
   /// [onProgress] 可选的进度回调，参数为当前步骤 (1-3) 和总步骤数 (3) 
   /// 
   /// 返回 上传后的uri, 不同场景保存使用
   Future<String?> uploadMPAudio( 
     File audioFile, { 
     Function(int current, int total)? onProgress, 
   }) async { 
     try { 
       // 获取文件的 MIME 类型 
       final contentType = getAudioMimeType(audioFile.path); 
       debugPrint('MPAudioUploadService: uploading ${audioFile.path} with type $contentType'); 
 
       // 步骤 1: 获取预签名 URL 
       onProgress?.call(1, 3); 
       final presignedUrl = await _getPresignedUrlWithRetry(contentType); 
       if (presignedUrl == null) { 
         debugPrint('MPAudioUploadService: failed to get presigned URL'); 
         return null; 
       } 
       debugPrint('MPAudioUploadService: got presigned URL: ${presignedUrl.uri}'); 
 
       // 步骤 2: 上传文件到 S3 
       onProgress?.call(2, 3); 
       final uploadSuccess = await _uploadToS3WithRetry( 
         presignedUrl.uploadUrl, 
         audioFile, 
         contentType, 
       ); 
       if (!uploadSuccess) { 
         debugPrint('MPAudioUploadService: failed to upload to S3'); 
         return null; 
       } 
       debugPrint('MPAudioUploadService: uploaded to S3 successfully'); 
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
         debugPrint('MPAudioUploadService: createRecord attempt ${i + 1} failed: $e'); 
         if (i == _maxRetries) return null; 
         // 简单的延迟重试 
         await Future.delayed(const Duration(seconds: 1)); 
       } 
     } 
     return null; 
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
       final supportedExtensions = ['.m4a', '.wav', '.mp3', '.aac']; 
       final hasValidExtension = supportedExtensions.any((ext) => filename.endsWith(ext)); 
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
