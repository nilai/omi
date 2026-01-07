import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;
import 'package:omi/backend/preferences.dart';
import 'package:omi/env/env.dart';
import 'package:omi/services/auth_service.dart';
import 'package:omi/utils/logger.dart';
import 'package:omi/utils/platform/platform_manager.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class ApiClient {
  static const Duration requestTimeoutRead = Duration(seconds: 30);
  static const Duration requestTimeoutWrite = Duration(seconds: 300);

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

  // UUID 生成器
  static const _uuidGenerator = Uuid();

  // 安全存储实例（使用 Keychain/KeyStore）
  // iOS: 使用 Keychain
  // Android: 使用 EncryptedSharedPreferences
  static const _secureStorage = FlutterSecureStorage();

  // 设备信息插件
  static final _deviceInfo = DeviceInfoPlugin();

  // uuid 缓存
  String? _uuid;

  // UUID 存储键
  static const String _uuidStorageKey = 'device_uuid';

  // 获取 uuid（懒加载，持久化存储）
  // 使用平台特定的设备标识符确保卸载重装后 UUID 保持不变
  // iOS: 使用 identifierForVendor（卸载后可能变化，但比随机 UUID 更稳定）
  // Android: 使用 Android ID（卸载重装后保持不变，除非恢复出厂设置）
  Future<String> get uuid async {
    if (_uuid != null) {
      return _uuid!;
    }

    try {
      // 首先尝试从安全存储获取已保存的 UUID
      final savedUuid = await _secureStorage.read(key: _uuidStorageKey);

      if (savedUuid != null && savedUuid.isNotEmpty && savedUuid != 'unknown') {
        _uuid = savedUuid;
        return _uuid!;
      }

      // 如果没有保存的 UUID，尝试使用平台特定的设备标识符
      if (Platform.isAndroid) {
        // Android: 使用 Android ID（卸载重装后保持不变）
        try {
          final androidInfo = await _deviceInfo.androidInfo;
          final androidId = androidInfo.id; // Android ID
          if (androidId.isNotEmpty && androidId != '9774d56d682e549c') {
            // 排除已知的无效 Android ID
            _uuid = androidId;
            Logger.log('Using Android ID as device UUID: ${_uuid!.substring(0, 8)}...');
          }
        } catch (e) {
          Logger.error('Failed to get Android ID: $e');
        }
      } else if (Platform.isIOS) {
        // iOS: 使用 identifierForVendor
        // 注意：identifierForVendor 在卸载重装后可能变化，但比随机 UUID 更稳定
        try {
          final iosInfo = await _deviceInfo.iosInfo;
          final identifierForVendor = iosInfo.identifierForVendor;
          if (identifierForVendor != null && identifierForVendor.isNotEmpty) {
            _uuid = identifierForVendor;
            Logger.log('Using iOS identifierForVendor as device UUID: ${_uuid!.substring(0, 8)}...');
          }
        } catch (e) {
          Logger.error('Failed to get iOS identifierForVendor: $e');
        }
      }

      // 如果平台标识符不可用，生成一个新的 UUID
      if (_uuid == null || _uuid!.isEmpty) {
        _uuid = _uuidGenerator.v4();
        Logger.log('Generated new UUID as device identifier');
      }

      // 保存到安全存储
      try {
        await _secureStorage.write(key: _uuidStorageKey, value: _uuid!);
      } catch (saveError) {
        Logger.error('Failed to save UUID to secure storage: $saveError');
      }

      return _uuid!;
    } catch (e) {
      Logger.error('Failed to get device UUID: $e');
      // 如果出错，尝试生成一个临时 UUID
      _uuid = _uuidGenerator.v4();
      try {
        await _secureStorage.write(key: _uuidStorageKey, value: _uuid!);
      } catch (saveError) {
        Logger.error('Failed to save UUID to secure storage: $saveError');
      }
      return _uuid!;
    }
  }
}

Future<String> getAuthHeader() async {
  DateTime? expiry = DateTime.fromMillisecondsSinceEpoch(SharedPreferencesUtil().tokenExpirationTime);
  bool hasAuthToken = SharedPreferencesUtil().authToken.isNotEmpty;

  bool isExpirationDateValid = !(expiry.isBefore(DateTime.now()) ||
      expiry.isAtSameMomentAs(DateTime.fromMillisecondsSinceEpoch(0)) ||
      (expiry.isBefore(DateTime.now().add(const Duration(minutes: 5))) && expiry.isAfter(DateTime.now())));

  if (!hasAuthToken || !isExpirationDateValid) {
    SharedPreferencesUtil().authToken = await AuthService.instance.getIdToken() ?? '';
  }

  if (!hasAuthToken) {
    if (AuthService.instance.isSignedIn()) {
      // should only throw if the user is signed in but the token is not found
      // if the user is not signed in, the token will always be empty
      throw Exception('No auth token found');
    }
  }
  return 'Bearer ${SharedPreferencesUtil().authToken}';
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
    'X-Request-Start-Time': (DateTime.now().millisecondsSinceEpoch / 1000).toString(),
    'X-App-Platform': PlatformManager.instance.platform,
    'X-App-Version': PlatformManager.instance.appVersion,
    'X-User-ID': uuid,
    ...fromHeaders,
  };

  if (requireAuthCheck) {
    headers['Authorization'] = await getAuthHeader();
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
  final builtHeaders = await buildHeaders(
    requireAuthCheck: _isRequiredAuthCheck(url),
    fromHeaders: headers,
  );
  request.headers.addAll(builtHeaders);
  return ApiClient._client.send(request);
}

Future<http.Response?> makeApiCall({
  required String url,
  required Map<String, String> headers,
  required String body,
  required String method,
}) async {
  try {
    final bool requireAuthCheck = _isRequiredAuthCheck(url);
    final builtHeaders = await buildHeaders(
      requireAuthCheck: requireAuthCheck,
      fromHeaders: headers,
    );

    http.Response? response = await _performRequest(url, builtHeaders, body, method);
    if (requireAuthCheck && response.statusCode == 401) {
      Logger.log('Token expired on 1st attempt');
      SharedPreferencesUtil().authToken = await AuthService.instance.getIdToken() ?? '';
      if (SharedPreferencesUtil().authToken.isNotEmpty) {
        final refreshedHeaders = await buildHeaders(
          requireAuthCheck: requireAuthCheck,
          fromHeaders: headers,
        );
        response = await _performRequest(url, refreshedHeaders, body, method);
        Logger.log('Token refreshed and request retried');
        if (response.statusCode == 401) {
          // Force user to sign in again
          await AuthService.instance.signOut();
          Logger.handle(Exception('Authentication failed. Please sign in again.'), StackTrace.current,
              message: 'Authentication failed. Please sign in again.');
        }
      } else {
        // Force user to sign in again
        await AuthService.instance.signOut();
        Logger.handle(Exception('Authentication failed. Please sign in again.'), StackTrace.current,
            message: 'Authentication failed. Please sign in again.');
      }
    }

    return response;
  } catch (e, stackTrace) {
    debugPrint('HTTP request failed: $e, $stackTrace');
    PlatformManager.instance.crashReporter.reportCrash(e, stackTrace, userAttributes: {'url': url, 'method': method});
    return null;
  } finally {}
}

Future<http.Response> _performRequest(
  String url,
  Map<String, String> headers,
  String body,
  String method,
) async {
  final client = ApiClient._client;

  // 记录请求开始时间
  final stopwatch = Stopwatch()..start();

  // 记录请求详情
  debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  debugPrint('🌐 HTTP REQUEST');
  debugPrint('Method: $method');
  debugPrint('URL: $url');
  debugPrint('Headers: ${_sanitizeHeaders(headers)}');
  if (body.isNotEmpty) {
    debugPrint('Body: $body');
  }
  debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  http.Response response;

  switch (method) {
    case 'POST':
      headers['Content-Type'] = 'application/json';
      response = await client.post(Uri.parse(url), headers: headers, body: body).timeout(
            ApiClient.requestTimeoutWrite,
            onTimeout: () => throw TimeoutException('Request timeout'),
          );
      break;
    case 'GET':
      response = await client.get(Uri.parse(url), headers: headers).timeout(
            ApiClient.requestTimeoutRead,
            onTimeout: () => throw TimeoutException('Request timeout'),
          );
      break;
    case 'DELETE':
      headers['Content-Type'] = 'application/json';
      response = await client.delete(Uri.parse(url), headers: headers, body: body).timeout(
            ApiClient.requestTimeoutWrite,
            onTimeout: () => throw TimeoutException('Request timeout'),
          );
      break;
    case 'PATCH':
      headers['Content-Type'] = 'application/json';
      response = await client.patch(Uri.parse(url), headers: headers, body: body).timeout(
            ApiClient.requestTimeoutWrite,
            onTimeout: () => throw TimeoutException('Request timeout'),
          );
      break;
    case 'PUT':
      headers['Content-Type'] = 'application/json';
      response = await client.put(Uri.parse(url), headers: headers, body: body).timeout(
            ApiClient.requestTimeoutWrite,
            onTimeout: () => throw TimeoutException('Request timeout'),
          );
      break;
    default:
      throw Exception('Unsupported HTTP method: $method');
  }

  stopwatch.stop();

  // 记录响应详情
  final statusIcon = response.statusCode >= 200 && response.statusCode < 300 ? '✅' : '❌';
  debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  debugPrint('$statusIcon HTTP RESPONSE');
  debugPrint('Method: $method');
  debugPrint('URL: $url');
  debugPrint('Status: ${response.statusCode}');
  debugPrint('Duration: ${stopwatch.elapsedMilliseconds}ms');
  debugPrint('Response Body: ${_truncateResponse(response.body)}');
  debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

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

/// 截断过长的响应内容
String _truncateResponse(String body, {int maxLength = 1000}) {
  if (body.length <= maxLength) {
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

    final builtHeaders = await buildHeaders(
      requireAuthCheck: _isRequiredAuthCheck(url),
      fromHeaders: headers,
    );
    request.headers.addAll(builtHeaders);
    request.fields.addAll(fields);

    for (var file in files) {
      var stream = http.ByteStream(file.openRead());
      var length = await file.length();
      var multipartFile = http.MultipartFile(
        fileFieldName,
        stream,
        length,
        filename: basename(file.path),
      );
      request.files.add(multipartFile);
    }

    var streamedResponse = await ApiClient._client.send(request);
    return await http.Response.fromStream(streamedResponse);
  } catch (e, stackTrace) {
    debugPrint('Multipart HTTP request failed: $e, $stackTrace');
    PlatformManager.instance.crashReporter.reportCrash(e, stackTrace, userAttributes: {'url': url, 'method': method});
    rethrow;
  }
}

Stream<String> makeStreamingApiCall({
  required String url,
  Map<String, String> headers = const {},
  String body = '',
  String method = 'POST',
}) async* {
  try {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🌊 STREAMING REQUEST');
    debugPrint('Method: $method');
    debugPrint('URL: $url');
    debugPrint('Headers: ${_sanitizeHeaders(headers)}');
    if (body.isNotEmpty) {
      debugPrint('Body: $body');
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    var request = http.Request(method, Uri.parse(url));

    final builtHeaders = await buildHeaders(
      requireAuthCheck: _isRequiredAuthCheck(url),
      fromHeaders: headers,
    );
    request.headers.addAll(builtHeaders);

    if (body.isNotEmpty) {
      request.headers['Content-Type'] = 'application/json';
      request.body = body;
    }

    var streamedResponse = await ApiClient._client.send(request);

    if (streamedResponse.statusCode != 200) {
      Logger.error('Streaming request failed: ${streamedResponse.statusCode}');
      debugPrint('❌ STREAMING RESPONSE: ${streamedResponse.statusCode}');
      return;
    }

    debugPrint('✅ STREAMING RESPONSE: ${streamedResponse.statusCode} - Started receiving data...');
    int chunkCount = 0;

    var buffers = <String>[];
    await for (var data in streamedResponse.stream.transform(utf8.decoder)) {
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

        chunkCount++;
        debugPrint('📦 Chunk #$chunkCount: ${_truncateResponse(line, maxLength: 200)}');
        yield line;
      }
    }

    // Flush remaining buffers
    if (buffers.isNotEmpty) {
      chunkCount++;
      debugPrint('📦 Chunk #$chunkCount (final): ${_truncateResponse(buffers.join(), maxLength: 200)}');
      yield buffers.join();
    }

    debugPrint('🏁 STREAMING COMPLETE: Received $chunkCount chunks');
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

    final builtHeaders = await buildHeaders(
      requireAuthCheck: _isRequiredAuthCheck(url),
      fromHeaders: headers,
    );
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
    PlatformManager.instance.crashReporter
        .reportCrash(Exception('Error fetching data: ${response?.statusCode}'), StackTrace.current, userAttributes: {
      'response_null': (response == null).toString(),
      'response_status_code': response?.statusCode.toString() ?? '',
      'is_embedding': isEmbedding.toString(),
      'is_function_calling': isFunctionCalling.toString(),
    });
    return null;
  }
}
