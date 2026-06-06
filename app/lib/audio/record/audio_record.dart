import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;

import '../../env/env.dart';
import '../../http/schema/mp_memory.dart';
import '../../http/shared.dart';

/// 音频文件扩展名到MIME类型的映射
Map<String, String> audioMimeTypes = {
  '.m4a': 'audio/m4a',
  '.wav': 'audio/wav',
  '.mp3': 'audio/mpeg',
  '.aac': 'audio/aac',
  '.opus': 'audio/opus',
};

/// 支持的音频文件扩展名列表
List<String> audioExtensions = ['m4a', 'wav', 'mp3', 'aac', 'opus'];

/// S3 PUT 上传空闲超时：连续该时长无网络收发则判定失败（大文件可慢传，不受总时长限制）。
const Duration kS3UploadIdleTimeout = Duration(seconds: 60);

/// 分块大小；较小分块可在慢速网络下更频繁刷新空闲计时，避免误超时。
const int _kS3UploadStreamChunkSize = 16 * 1024;

/// 监控 S3 PUT 上传过程中的网络空闲时间。
class _S3UploadIdleWatch {
  _S3UploadIdleWatch(this._idleLimit);

  final Duration _idleLimit;
  DateTime _lastActivity = DateTime.now();
  Timer? _timer;
  HttpClient? _clientToAbort;
  bool _timedOut = false;

  bool get hasTimedOut => _timedOut;

  void bindClient(HttpClient client) {
    _clientToAbort = client;
  }

  void markActivity() {
    _lastActivity = DateTime.now();
  }

  void start() {
    markActivity();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _checkIdle());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _checkIdle() {
    if (_timedOut) {
      return;
    }
    if (DateTime.now().difference(_lastActivity) > _idleLimit) {
      _timedOut = true;
      _clientToAbort?.close(force: true);
    }
  }

  void throwIfTimedOut() {
    if (_timedOut) {
      throw TimeoutException('S3 upload idle timeout');
    }
  }
}

Stream<List<int>> _chunkedByteStream(List<int> bytes) async* {
  for (int offset = 0; offset < bytes.length; offset += _kS3UploadStreamChunkSize) {
    final int end = math.min(offset + _kS3UploadStreamChunkSize, bytes.length);
    yield bytes.sublist(offset, end);
  }
}

Stream<List<int>> _fileChunkStream(File file) async* {
  final RandomAccessFile handle = await file.open();
  try {
    while (true) {
      final List<int> buffer = await handle.read(_kS3UploadStreamChunkSize);
      if (buffer.isEmpty) {
        break;
      }
      yield buffer;
    }
  } finally {
    await handle.close();
  }
}

/// 在 body 流每块产出时刷新 idle 计时。
Stream<List<int>> _attachIdleWatch(Stream<List<int>> source, _S3UploadIdleWatch idle) {
  return source.map((List<int> chunk) {
    idle.throwIfTimedOut();
    idle.markActivity();
    return chunk;
  });
}

/// [http.StreamedRequest] PUT 到 S3，[kS3UploadIdleTimeout] 内无收发则超时。
Future<bool> _s3PutWithIdleTimeout({
  required String uploadUrl,
  required Stream<List<int>> bodyStream,
  required int contentLength,
  required String contentType,
}) async {
  final HttpClient rawClient = HttpClient();
  final http.Client client = http_io.IOClient(rawClient);
  final _S3UploadIdleWatch idle = _S3UploadIdleWatch(kS3UploadIdleTimeout);
  idle.bindClient(rawClient);
  idle.start();

  try {
    final http.StreamedRequest request = http.StreamedRequest('PUT', Uri.parse(uploadUrl));
    request.headers['Content-Type'] = contentType;
    request.contentLength = contentLength;

    final Stream<List<int>> monitoredBody = _attachIdleWatch(bodyStream, idle);
    unawaited(
      request.sink.addStream(monitoredBody).whenComplete(request.sink.close),
    );

    idle.throwIfTimedOut();
    final http.StreamedResponse streamedResponse = await client.send(request);
    idle.markActivity();

    final int statusCode = streamedResponse.statusCode;
    await for (final List<int> _ in streamedResponse.stream) {
      idle.throwIfTimedOut();
      idle.markActivity();
    }

    idle.throwIfTimedOut();
    debugPrint('_s3PutWithIdleTimeout: status $statusCode');
    if (statusCode == 200 || statusCode == 204) {
      return true;
    }
    debugPrint('_s3PutWithIdleTimeout error $statusCode');
    return false;
  } on TimeoutException {
    rethrow;
  } catch (e) {
    if (idle.hasTimedOut) {
      throw TimeoutException('S3 upload idle timeout');
    }
    debugPrint('_s3PutWithIdleTimeout exception: $e');
    return false;
  } finally {
    idle.stop();
    client.close();
  }
}

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
    final int contentLength = await audioFile.length();
    return await _s3PutWithIdleTimeout(
      uploadUrl: uploadUrl,
      bodyStream: _fileChunkStream(audioFile),
      contentLength: contentLength,
      contentType: contentType,
    );
  } on TimeoutException {
    rethrow;
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
    return await _s3PutWithIdleTimeout(
      uploadUrl: uploadUrl,
      bodyStream: _chunkedByteStream(audioBytes),
      contentLength: audioBytes.length,
      contentType: contentType,
    );
  } on TimeoutException {
    rethrow;
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
