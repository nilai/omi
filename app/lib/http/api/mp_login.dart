import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:memo_pin/env/env.dart';
import 'package:memo_pin/http/schema/mp_login.dart';
import 'package:memo_pin/http/shared.dart';

Future<MPSendCodeResponse?> sendCode(MPSendCodeRequest req) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/auth/send-code',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('sendCode response: ${response.body}');
  if (response.statusCode == 200) {
    return MPSendCodeResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  return null;
}

Future<MPTokenResponse?> register(MPRegisterRequest req) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/auth/register',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('register response: ${response.body}');
  if (response.statusCode == 200) {
    return MPTokenResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  return null;
}

Future<MPTokenResponse?> login(MPLoginRequest req) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/auth/login',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('login response: ${response.body}');
  if (response.statusCode == 200) {
    return MPTokenResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  return null;
}

Future<MPTokenResponse?> refresh(MPRefreshTokenRequest req) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/auth/refresh',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('refresh response: ${response.body}');
  if (response.statusCode == 200) {
    return MPTokenResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  return null;
}

Future<MPCommonAuthResponse?> logout() async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/auth/logout',
    headers: {},
    method: 'POST',
    body: '',
  );
  if (response == null) return null;
  debugPrint('logout response: ${response.body}');
  if (response.statusCode == 200) {
    return MPCommonAuthResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  return null;
}

Future<MPCommonAuthResponse?> logoutAll() async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/auth/logout-all',
    headers: {},
    method: 'POST',
    body: '',
  );
  if (response == null) return null;
  debugPrint('logoutAll response: ${response.body}');
  if (response.statusCode == 200) {
    return MPCommonAuthResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  return null;
}

Future<MPSendCodeResponse?> resetSendCode(MPSendCodeRequest req) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/auth/reset/send-code',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('resetSendCode response: ${response.body}');
  if (response.statusCode == 200) {
    return MPSendCodeResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  return null;
}

Future<MPCommonAuthResponse?> resetConfirm(MPResetPasswordConfirmRequest req) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/auth/reset/confirm',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('resetConfirm response: ${response.body}');
  if (response.statusCode == 200) {
    return MPCommonAuthResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  return null;
}
