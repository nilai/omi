import 'dart:convert';

import 'package:http/http.dart' as http;

/// 网络层不可达（如 [makeApiCall] 在重试耗尽后返回 `null`）。
class MPApiNetworkException implements Exception {
  MPApiNetworkException([this.message = 'Network unavailable']);

  final String message;

  @override
  String toString() => 'MPApiNetworkException: $message';
}

/// HTTP 有响应但 body 无法解析为预期 JSON 结构。
class MPApiHttpException implements Exception {
  MPApiHttpException({
    required this.statusCode,
    this.body = '',
  });

  final int statusCode;
  final String body;

  @override
  String toString() => 'MPApiHttpException: status=$statusCode';
}

/// 从 HTTP 响应解析 JSON，**不依赖** `statusCode == 200`。
///
/// 若服务端在 4xx/5xx 下仍返回带 `base_resp` 的 JSON，也能正确解析业务错误。
T parseApiJsonResponse<T>({
  required http.Response? response,
  required T Function(Map<String, dynamic> json) fromJson,
}) {
  if (response == null) {
    throw MPApiNetworkException();
  }
  final String rawBody = response.body;
  try {
    final dynamic decoded = jsonDecode(rawBody);
    if (decoded is! Map<String, dynamic>) {
      throw MPApiHttpException(statusCode: response.statusCode, body: rawBody);
    }
    return fromJson(decoded);
  } on MPApiNetworkException {
    rethrow;
  } on MPApiHttpException {
    rethrow;
  } catch (_) {
    throw MPApiHttpException(statusCode: response.statusCode, body: rawBody);
  }
}
