import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;
import 'package:memo_pin/utils/mp_uuid_util.dart';
import 'package:path/path.dart';
import 'package:memo_pin/utils/platform/platform_manager.dart';
import '../../env/env.dart';
import '../login/mp_login_util.dart';
import '../login/mp_user.dart';
import 'api/mp_login.dart';
import 'mp_chat_stream_utils.dart';
import 'schema/mp_login.dart';

class Logger {
  static void log(String message) {
    debugPrint(message);
  }

  static void error(String message) {
    debugPrint(message);
  }

  static void handle(Object error, StackTrace stackTrace, {String? message}) {
    debugPrint(message ?? error.toString());
    debugPrint(stackTrace.toString());
  }
}

class ApiClient {
  static const Duration requestTimeoutRead = Duration(seconds: 60);
  static const Duration requestTimeoutWrite = Duration(seconds: 600);

  static final _client = _createClient();
  // static final _client = http.Client();

  static http.Client _createClient() {
    // Only bypass certificate verification in debug mode
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      // Development mode - bypass SSL verification
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return http_io.IOClient(client);
    }
    // Production mode - use default client with proper SSL verification
    return http.Client();
  }

  static void dispose() {
    _client.close();
  }
}

class ApiTools {
  // 单例实例
  static ApiTools? _instance;

  // 私有构造函数
  ApiTools._();

  // 获取单例实例
  static ApiTools get instance {
    _instance ??= ApiTools._();
    return _instance!;
  }

  // 获取设备 UUID，复用统一工具实现。
  Future<String> get uuid async {
    return MPUuidUtil.instance.uuid;
  }

  /// 获取访问令牌
  static String get accessToken => MPUser.instance.accessToken ?? '';

  /// 判断是否有访问令牌
  static bool hasAccessToken() {
    return accessToken.isNotEmpty;
  }

  /// 获取邮箱
  static String get email => MPUser.instance.email;

  /// 获取 token 过期时间
  static DateTime? get tokenExpiresTime => MPUser.instance.tokenExpiresTime;

  /// 判断 token 是否过期
  static bool tokenIsExpired() {
    return false;
    final DateTime? tokenExpiresTime = MPUser.instance.tokenExpiresTime;
    if (tokenExpiresTime == null) {
      return false;
    }
    return DateTime.now().isAfter(tokenExpiresTime) ||
        tokenExpiresTime.isAtSameMomentAs(DateTime.fromMillisecondsSinceEpoch(0));
  }

  static Completer<void>? _tokenRefreshCompleter;

  static Future<void> refreshToken() async {
    final String refreshToken = MPUser.instance.refreshToken;
    if (refreshToken.isEmpty) {
      throw Exception('Refresh token is empty');
    }
    final MPRefreshTokenRequest req = MPRefreshTokenRequest(refreshToken: refreshToken);
    final MPTokenResponse? response = await refresh(req);
    if (response == null) return;
    await MPUser.instance.setAccessToken(response.accessToken);
    await MPUser.instance.setRefreshToken(response.refreshToken);
    await MPUser.instance.setTokenExpiresTime(response.expiresIn);
  }

  /// 并发 401 时只允许一次 refresh，其余调用等待同一结果后再重试原请求。
  static Future<void> refreshTokenLocked() async {
    if (_tokenRefreshCompleter != null) {
      return _tokenRefreshCompleter!.future;
    }
    final Completer<void> completer = Completer<void>();
    _tokenRefreshCompleter = completer;
    try {
      await refreshToken();
      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _tokenRefreshCompleter = null;
    }
  }
}

Future<String> getAuthHeader() async {
  if (ApiTools.hasAccessToken() && ApiTools.tokenIsExpired()) {
    // 刷新 token
    await ApiTools.refreshTokenLocked();
  }

  if (!ApiTools.hasAccessToken()) {
    final String refreshToken = MPUser.instance.refreshToken;
    if (refreshToken.isEmpty) {
      return '';
    }
    await ApiTools.refreshTokenLocked();
  }
  final String accessToken = ApiTools.accessToken;
  return accessToken.isEmpty ? '' : 'Bearer $accessToken';
}

String? _extractUserIdFromJwt(String? accessToken) {
  if (accessToken == null || accessToken.isEmpty) {
    return null;
  }
  final List<String> parts = accessToken.split('.');
  if (parts.length < 2) {
    return null;
  }
  try {
    String normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }
    final String payload = utf8.decode(base64.decode(normalized));
    final Map<String, dynamic> map = jsonDecode(payload) as Map<String, dynamic>;
    final Object? sub = map['sub'];
    if (sub == null) {
      return null;
    }
    final String uid = sub.toString().trim();
    if (uid.isEmpty) {
      return null;
    }
    return uid;
  } catch (_) {
    return null;
  }
}

/// Builds common headers for API and WebSocket requests
/// Centralizes header logic for easy maintenance and consistency
/// Automatically adds Authorization header if required
Future<Map<String, String>> buildHeaders({
  required bool requireAuthCheck,
  Map<String, String> fromHeaders = const {},
}) async {
  final uuid = await ApiTools.instance.uuid;
  final headers = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': '${PlatformManager.instance.platform} ${PlatformManager.instance.appVersion}',
    // 'X-Request-Start-Time': (DateTime.now().millisecondsSinceEpoch / 1000).toString(),
    'X-App-Platform': PlatformManager.instance.platform,
    'X-App-Version': PlatformManager.instance.appVersion,
    'X-Device-ID': uuid,
    ...fromHeaders,
  };

  if (requireAuthCheck) {
    final String authHeader = await getAuthHeader();
    if (authHeader.isNotEmpty) {
      headers['Authorization'] = authHeader;
    }
    final String? userId = _extractUserIdFromJwt(ApiTools.accessToken);
    if (userId != null && userId.isNotEmpty) {
      headers['user_id'] = userId;
    }
  }

  return headers;
}

bool _isRequiredAuthCheck(String url) {
  if (url.contains(Env.apiBaseUrl!)) {
    return true;
  }
  return false;
}

Future<http.StreamedResponse> makeRawApiCall({
  required String url,
  required String method,
  Map<String, String> headers = const {},
}) async {
  var request = http.Request(method, Uri.parse(url));
  final builtHeaders = await buildHeaders(requireAuthCheck: _isRequiredAuthCheck(url), fromHeaders: headers);
  request.headers.addAll(builtHeaders);
  return ApiClient._client.send(request);
}

const int _kApiMaxAttempts = 3;

const Set<int> _kRetryableHttpStatusCodes = <int>{502, 503, 504};

/// 瞬态传输错误：弱网、超时、连接重置等，可安全重试。
bool _isTransientTransportError(Object error) {
  return error is TimeoutException ||
      error is SocketException ||
      error is HttpException ||
      error is HandshakeException ||
      error is IOException;
}

bool _isRetryableHttpStatus(int statusCode) {
  return _kRetryableHttpStatusCodes.contains(statusCode);
}

/// 单次 API 请求（含 401 token 刷新与重试）。
Future<http.Response> _makeApiCallOnce({
  required String url,
  required Map<String, String> headers,
  required String body,
  required String method,
}) async {
  final bool requireAuthCheck = _isRequiredAuthCheck(url);
  final builtHeaders = await buildHeaders(requireAuthCheck: requireAuthCheck, fromHeaders: headers);

  http.Response response = await _performRequest(url, builtHeaders, body, method);
  if (requireAuthCheck && response.statusCode == 401) {
    Logger.log('Token expired on 1st attempt');
    await ApiTools.refreshTokenLocked();
    if (ApiTools.hasAccessToken()) {
      final refreshedHeaders = await buildHeaders(requireAuthCheck: requireAuthCheck, fromHeaders: headers);
      response = await _performRequest(url, refreshedHeaders, body, method);
      Logger.log('Token refreshed and request retried');
      if (response.statusCode == 401) {
        await MPLoginUtil.signOut();
        Logger.handle(
          Exception('Authentication failed. Please sign in again.'),
          StackTrace.current,
          message: 'Authentication failed. Please sign in again.',
        );
      }
    } else {
      await MPLoginUtil.signOut();
      Logger.handle(
        Exception('Authentication failed. Please sign in again.'),
        StackTrace.current,
        message: 'Authentication failed. Please sign in again.',
      );
    }
  }

  return response;
}

Future<http.Response?> makeApiCall({
  required String url,
  required Map<String, String> headers,
  required String body,
  required String method,
}) async {
  Object? lastError;
  StackTrace? lastStackTrace;

  for (int attempt = 0; attempt < _kApiMaxAttempts; attempt++) {
    if (attempt > 0) {
      final int delayMs = 500 * attempt;
      httpDebugPrint('Retrying API call in ${delayMs}ms (${attempt + 1}/$_kApiMaxAttempts): $method $url');
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
    try {
      final http.Response response = await _makeApiCallOnce(
        url: url,
        headers: headers,
        body: body,
        method: method,
      );
      if (_isRetryableHttpStatus(response.statusCode) && attempt < _kApiMaxAttempts - 1) {
        httpDebugPrint('Retryable HTTP ${response.statusCode}, will retry: $method $url');
        continue;
      }
      return response;
    } catch (e, stackTrace) {
      lastError = e;
      lastStackTrace = stackTrace;
      if (!_isTransientTransportError(e) || attempt >= _kApiMaxAttempts - 1) {
        break;
      }
      httpDebugPrint('Transient transport error, will retry: $e');
    }
  }

  httpDebugPrint('HTTP request failed after $_kApiMaxAttempts attempts: $lastError, $lastStackTrace');
  if (lastError != null && lastStackTrace != null) {
    PlatformManager.instance.crashReporter.reportCrash(
      lastError,
      lastStackTrace,
      userAttributes: <String, String>{'url': url, 'method': method},
    );
  }
  return null;
}

Future<http.Response> _performRequest(String url, Map<String, String> headers, String body, String method) async {
  final client = ApiClient._client;

  // 记录请求开始时间
  final stopwatch = Stopwatch()..start();

  // 记录请求详情
  httpDebugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  httpDebugPrint('🌐 HTTP REQUEST');
  httpDebugPrint('Method: $method');
  httpDebugPrint('URL: $url');
  httpDebugPrint('Headers: ${_sanitizeHeaders(headers)}');
  if (body.isNotEmpty) {
    httpDebugPrint('Body: $body');
  }
  httpDebugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  http.Response response;

  switch (method) {
    case 'POST':
      headers['Content-Type'] = 'application/json';
      response = await client
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(ApiClient.requestTimeoutWrite, onTimeout: () => throw TimeoutException('Request timeout'));
      break;
    case 'GET':
      response = await client
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiClient.requestTimeoutRead, onTimeout: () => throw TimeoutException('Request timeout'));
      break;
    case 'DELETE':
      headers['Content-Type'] = 'application/json';
      response = await client
          .delete(Uri.parse(url), headers: headers, body: body)
          .timeout(ApiClient.requestTimeoutWrite, onTimeout: () => throw TimeoutException('Request timeout'));
      break;
    case 'PATCH':
      headers['Content-Type'] = 'application/json';
      response = await client
          .patch(Uri.parse(url), headers: headers, body: body)
          .timeout(ApiClient.requestTimeoutWrite, onTimeout: () => throw TimeoutException('Request timeout'));
      break;
    case 'PUT':
      headers['Content-Type'] = 'application/json';
      response = await client
          .put(Uri.parse(url), headers: headers, body: body)
          .timeout(ApiClient.requestTimeoutWrite, onTimeout: () => throw TimeoutException('Request timeout'));
      break;
    default:
      throw Exception('Unsupported HTTP method: $method');
  }

  stopwatch.stop();

  // 记录响应详情
  final statusIcon = response.statusCode >= 200 && response.statusCode < 300 ? '✅' : '❌';
  httpDebugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  httpDebugPrint('$statusIcon HTTP RESPONSE');
  httpDebugPrint('Method: $method');
  httpDebugPrint('URL: $url');
  httpDebugPrint('Status: ${response.statusCode}');
  httpDebugPrint('Duration: ${stopwatch.elapsedMilliseconds}ms');
  final bodyForLog = _truncateResponse(response.body, maxLength: kDebugMode ? null : 1000);
  httpDebugPrint('Response Body: $bodyForLog');
  httpDebugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  return response;
}

/// 隐藏敏感的 header 信息
String _sanitizeHeaders(Map<String, String> headers) {
  final sanitized = Map<String, String>.from(headers);
  if (sanitized.containsKey('Authorization')) {
    final auth = sanitized['Authorization']!;
    if (auth.startsWith('Bearer ') && auth.length > 20) {
      sanitized['Authorization'] = 'Bearer ${auth.substring(7, 17)}...';
    }
  }
  return sanitized.toString();
}

/// 网络请求日志时间戳，格式 HH:mm:ss.SSS。
String _httpLogTimestamp() {
  final now = DateTime.now();
  return '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')}.'
      '${now.millisecond.toString().padLeft(3, '0')}';
}

/// 带时间戳的网络请求 debugPrint。
void httpDebugPrint(String message) {
  debugPrint('[${_httpLogTimestamp()}] $message');
}

/// 截断过长的响应内容以便控制台阅读。
///
/// [maxLength] 为 null 时不截断，输出完整 body。
String _truncateResponse(String body, {required int? maxLength}) {
  if (maxLength == null || body.length <= maxLength) {
    return body;
  }
  return '${body.substring(0, maxLength)}... (truncated ${body.length - maxLength} chars)';
}

Future<http.Response> makeMultipartApiCall({
  required String url,
  required List<File> files,
  Map<String, String> headers = const {},
  Map<String, String> fields = const {},
  String fileFieldName = 'files',
  String method = 'POST',
}) async {
  try {
    var request = http.MultipartRequest(method, Uri.parse(url));

    final builtHeaders = await buildHeaders(requireAuthCheck: _isRequiredAuthCheck(url), fromHeaders: headers);
    request.headers.addAll(builtHeaders);
    request.fields.addAll(fields);

    for (var file in files) {
      var stream = http.ByteStream(file.openRead());
      var length = await file.length();
      var multipartFile = http.MultipartFile(fileFieldName, stream, length, filename: basename(file.path));
      request.files.add(multipartFile);
    }

    var streamedResponse = await ApiClient._client.send(request);
    return await http.Response.fromStream(streamedResponse);
  } catch (e, stackTrace) {
    httpDebugPrint('Multipart HTTP request failed: $e, $stackTrace');
    PlatformManager.instance.crashReporter.reportCrash(e, stackTrace, userAttributes: {'url': url, 'method': method});
    rethrow;
  }
}

/// 从 SSE event 中提取 data 字段内容及是否为 JSON delta。
(String payload, bool isJsonDelta)? _extractSseEventPayload(String eventText) {
  final String trimmed = eventText.trim();
  if (trimmed.isEmpty || trimmed == '[DONE]') {
    return null;
  }

  final List<String> dataLines = <String>[];
  bool isJsonDelta = false;
  for (final String line in eventText.split('\n')) {
    if (!line.startsWith('data:')) {
      continue;
    }
    String value = line.substring(5);
    if (value.startsWith(' ')) {
      value = value.substring(1);
    }
    if (value.startsWith('{')) {
      isJsonDelta = true;
    }
    dataLines.add(_extractChatStreamDataLine(value));
  }

  if (dataLines.isNotEmpty) {
    return (dataLines.join('\n'), isJsonDelta);
  }

  return (eventText, false);
}

/// 解析单条 SSE data 行，支持 JSON 与纯文本。
String _extractChatStreamDataLine(String value) {
  if (!value.startsWith('{')) {
    return value;
  }
  try {
    final dynamic decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) {
      for (final String key in <String>['content', 'delta', 'text', 'message']) {
        final dynamic field = decoded[key];
        if (field is String) {
          return field;
        }
      }
    }
  } catch (_) {}
  return value;
}

Stream<String> makeStreamingApiCall({
  required String url,
  Map<String, String> headers = const {},
  String body = '',
  String method = 'POST',
}) async* {
  try {
    httpDebugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    httpDebugPrint('🌊 STREAMING REQUEST');
    httpDebugPrint('Method: $method');
    httpDebugPrint('URL: $url');
    final builtHeaders = await buildHeaders(requireAuthCheck: _isRequiredAuthCheck(url), fromHeaders: headers);
    httpDebugPrint('Headers: ${_sanitizeHeaders(builtHeaders)}');
    if (body.isNotEmpty) {
      httpDebugPrint('Body: $body');
    }
    httpDebugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    var request = http.Request(method, Uri.parse(url));
    request.headers.addAll(builtHeaders);

    if (body.isNotEmpty) {
      request.headers['Content-Type'] = 'application/json';
      request.body = body;
    }

    var streamedResponse = await ApiClient._client.send(request);

    if (streamedResponse.statusCode != 200) {
      Logger.error('Streaming request failed: ${streamedResponse.statusCode}');
      httpDebugPrint('❌ STREAMING RESPONSE: ${streamedResponse.statusCode}');
      return;
    }

    httpDebugPrint('✅ STREAMING RESPONSE: ${streamedResponse.statusCode} - Started receiving data...');
    int chunkCount = 0;

    final StringBuffer eventBuffer = StringBuffer();
    await for (final String data in streamedResponse.stream.transform(utf8.decoder)) {
      eventBuffer.write(data);
      String buffered = eventBuffer.toString();
      int separatorIndex = buffered.indexOf('\n\n');
      while (separatorIndex != -1) {
        final String eventText = buffered.substring(0, separatorIndex);
        buffered = buffered.substring(separatorIndex + 2);
        final (String payload, bool isJsonDelta)? extracted = _extractSseEventPayload(eventText);
        if (extracted != null) {
          final String normalized = MPChatStreamUtils.normalizeEventChunk(
            extracted.$1,
            isJsonDelta: extracted.$2,
          );
          chunkCount++;
          final String chunkText = _truncateResponse(normalized, maxLength: kDebugMode ? null : 200);
          httpDebugPrint('📦 Chunk #$chunkCount: $chunkText');
          yield normalized;
        }
        separatorIndex = buffered.indexOf('\n\n');
      }
      eventBuffer
        ..clear()
        ..write(buffered);
    }

    final String remaining = eventBuffer.toString();
    if (remaining.isNotEmpty) {
      final (String payload, bool isJsonDelta)? extracted = _extractSseEventPayload(remaining);
      if (extracted != null) {
        final String normalized = MPChatStreamUtils.normalizeEventChunk(
          extracted.$1,
          isJsonDelta: extracted.$2,
        );
        chunkCount++;
        final String chunkText = _truncateResponse(normalized, maxLength: kDebugMode ? null : 200);
        httpDebugPrint('📦 Chunk #$chunkCount (final): $chunkText');
        yield normalized;
      }
    }

    httpDebugPrint('🏁 STREAMING COMPLETE: Received $chunkCount chunks');
  } catch (e, stackTrace) {
    Logger.error('Streaming request error: $e');
    PlatformManager.instance.crashReporter.reportCrash(e, stackTrace, userAttributes: {'url': url, 'method': method});
  }
}

Stream<String> makeMultipartStreamingApiCall({
  required String url,
  required List<File> files,
  Map<String, String> headers = const {},
  String fileFieldName = 'files',
}) async* {
  try {
    var request = http.MultipartRequest('POST', Uri.parse(url));

    final builtHeaders = await buildHeaders(requireAuthCheck: _isRequiredAuthCheck(url), fromHeaders: headers);
    request.headers.addAll(builtHeaders);

    for (var file in files) {
      request.files.add(await http.MultipartFile.fromPath(fileFieldName, file.path, filename: basename(file.path)));
    }

    var response = await ApiClient._client.send(request);

    if (response.statusCode != 200) {
      Logger.error('Multipart streaming request failed: ${response.statusCode}');
      return;
    }

    var buffers = <String>[];
    await for (var data in response.stream.transform(utf8.decoder)) {
      var lines = data.split('\n\n');
      for (var line in lines.where((line) => line.isNotEmpty)) {
        // Handle package splitting by 1024 bytes in dart
        if (line.length >= 1024) {
          buffers.add(line);
          continue;
        }

        // Merge packages if needed
        if (buffers.isNotEmpty) {
          buffers.add(line);
          line = buffers.join();
          buffers.clear();
        }

        yield line;
      }
    }

    // Flush remaining buffers
    if (buffers.isNotEmpty) {
      yield buffers.join();
    }
  } catch (e, stackTrace) {
    Logger.error('Multipart streaming request error: $e');
    PlatformManager.instance.crashReporter.reportCrash(e, stackTrace, userAttributes: {'url': url, 'method': 'POST'});
  }
}

// Function to extract content from the API response.
dynamic extractContentFromResponse(
  http.Response? response, {
  bool isEmbedding = false,
  bool isFunctionCalling = false,
}) {
  if (response != null && response.statusCode == 200) {
    var data = jsonDecode(response.body);
    if (isEmbedding) {
      var embedding = data['data'][0]['embedding'];
      return embedding;
    }
    var message = data['choices'][0]['message'];
    if (isFunctionCalling && message['tool_calls'] != null) {
      debugPrint('message $message');
      debugPrint('message ${message['tool_calls'].runtimeType}');
      return message['tool_calls'];
    }
    return data['choices'][0]['message']['content'];
  } else {
    debugPrint('Error fetching data: ${response?.statusCode}');
    // TODO: handle error, better specially for script migration
    PlatformManager.instance.crashReporter.reportCrash(
      Exception('Error fetching data: ${response?.statusCode}'),
      StackTrace.current,
      userAttributes: {
        'response_null': (response == null).toString(),
        'response_status_code': response?.statusCode.toString() ?? '',
        'is_embedding': isEmbedding.toString(),
        'is_function_calling': isFunctionCalling.toString(),
      },
    );
    return null;
  }
}
