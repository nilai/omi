import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:omi/backend/http/shared.dart';
import 'package:omi/backend/schema/schema.dart';
import 'package:omi/env/env.dart';
import 'package:http/http.dart' as http;

/// 音频文件扩展名到MIME类型的映射
Map<String, String> audioMimeTypes = {
  '.m4a': 'audio/m4a',
  '.wav': 'audio/wav',
  '.mp3': 'audio/mpeg',
  '.aac': 'audio/aac',
};

/// 支持的音频文件扩展名列表
List<String> audioExtensions = ['m4a', 'wav', 'mp3', 'aac'];

/// 根据文件扩展名获取MIME类型
String getAudioMimeType(String filename) {
  final extension = filename.toLowerCase().substring(filename.lastIndexOf('.'));
  return audioMimeTypes[extension] ?? 'audio/wav';
}

/// 获取预签名上传URL
///
/// [contentType] 音频文件的MIME类型，如 'audio/m4a', 'audio/wav' 等
///
/// 返回包含上传URL和文件URI的 [PresignedUrlResponse]，失败返回 null
Future<PresignedUrlResponse?> getPresignedUrl(String contentType) async {
  // 将参数编码为 URL 查询参数
  final encodedType = Uri.encodeComponent(contentType);
  final fullUrl = '${Env.noteBaseUrl}v3/get_presigned_url?content_type=$encodedType';

  debugPrint('🔵 [getPresignedUrl] Request URL: $fullUrl');

  var response = await makeApiCall(
    url: fullUrl,
    headers: {'Content-Type': 'application/json'},
    method: 'GET',
    body: '', // GET 请求不应有 body
  );

  if (response == null) return null;
  debugPrint('getPresignedUrl: ${response.body}');

  if (response.statusCode == 200) {
    return PresignedUrlResponse.fromJson(jsonDecode(response.body));
  } else {
    debugPrint('getPresignedUrl error ${response.statusCode}');
  }

  return null;
}

/// 上传音频文件到S3
///
/// [uploadUrl] 预签名的S3上传URL
/// [audioFile] 要上传的音频文件
/// [contentType] 音频文件的MIME类型
///
/// 返回 true 表示上传成功，false 表示失败
Future<bool> uploadAudioToS3(
  String uploadUrl,
  File audioFile,
  String contentType,
) async {
  try {
    // 读取文件字节
    final bytes = await audioFile.readAsBytes();

    // 直接使用 PUT 方法上传到 S3 预签名 URL
    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': contentType,
        'Content-Length': bytes.length.toString(),
      },
      body: bytes,
    );

    debugPrint('uploadAudioToS3: status ${response.statusCode}');

    // S3 返回 200 或 204 表示成功
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      debugPrint('uploadAudioToS3 error ${response.statusCode}: ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('uploadAudioToS3 exception: $e');
    return false;
  }
}

/// 上传音频字节到S3
///
/// [uploadUrl] 预签名的S3上传URL
/// [audioBytes] 要上传的音频字节数组
/// [contentType] 音频文件的MIME类型
///
/// 返回 true 表示上传成功，false 表示失败
Future<bool> uploadAudioToS3Bytes(
  String uploadUrl,
  List<int> audioBytes,
  String contentType,
) async {
  try {
    // 直接使用 PUT 方法上传到 S3 预签名 URL
    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': contentType,
        'Content-Length': audioBytes.length.toString(),
      },
      body: audioBytes,
    );

    debugPrint('uploadAudioToS3Bytes: status ${response.statusCode}');

    // S3 返回 200 或 204 表示成功
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      debugPrint('uploadAudioToS3Bytes error ${response.statusCode}: ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('uploadAudioToS3Bytes exception: $e');
    return false;
  }
}

/// 创建录音记录
///
/// [audioUri] 音频文件在S3中的URI路径
/// [recordTs] 录音发生时间的时间戳（秒）
///
/// 返回创建的 [AudioRecord]，失败返回 null
Future<AudioRecord?> createAudioRecord(
  String audioUri,
  int recordTs,
) async {
  final fullUrl = '${Env.noteBaseUrl}v3/create_record';
  debugPrint('🟢 [createAudioRecord] Request URL: $fullUrl');

  var response = await makeApiCall(
    url: fullUrl,
    headers: {'Content-Type': 'application/json'},
    method: 'POST',
    body: jsonEncode({
      'audio_uri': audioUri,
      'record_ts': recordTs,
    }),
  );

  if (response == null) return null;
  debugPrint('createAudioRecord: ${response.body}');

  if (response.statusCode == 200) {
    return AudioRecord.fromJson(jsonDecode(response.body));
  } else {
    debugPrint('createAudioRecord error ${response.statusCode}');
  }

  return null;
}
