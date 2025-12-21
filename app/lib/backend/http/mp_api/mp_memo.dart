import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:omi/backend/http/shared.dart';
import 'package:omi/backend/schema/mp/mp_memo.dart';
import 'package:omi/env/env.dart';

// GET /api/v1/memo/get_list
Future<MPGetMemoListResponse?> getMemoList(MPGetMemoListRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memo/get_list?page_size=${req.pageSize}&cursor=${req.cursor}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getMemoList response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetMemoListResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// GET /api/v1/memo/get_detail
Future<MPGetMemoDetailResponse?> getMemoDetail(MPGetMemoDetailRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memo/get_detail?memo_id=${req.memoId}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getMemoDetail response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetMemoDetailResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/memo/create_with_record
Future<MPCreateMemoWithRecordResponse?> createMemoWithRecord(MPCreateMemoWithRecordRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memo/create_with_record',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('createMemoWithRecord response: ${response.body}');
  if (response.statusCode == 200) {
    return MPCreateMemoWithRecordResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/memo/create_with_text
Future<MPCreateMemoWithTextResponse?> createMemoWithText(MPCreateMemoWithTextRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memo/create_with_text',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('createMemoWithText response: ${response.body}');
  if (response.statusCode == 200) {
    return MPCreateMemoWithTextResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/memo/delete
Future<MPDeleteMemoResponse?> deleteMemo(MPDeleteMemoRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memo/delete',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('deleteMemo response: ${response.body}');
  if (response.statusCode == 200) {
    return MPDeleteMemoResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/memo/update
Future<MPUpdateMemoResponse?> updateMemo(MPUpdateMemoRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memo/update',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('updateMemo response: ${response.body}');
  if (response.statusCode == 200) {
    return MPUpdateMemoResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/user/update_ai_setting
Future<MPUpdateMemoAIResponse?> updateMemoAI(MPUpdateMemoAIRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/user/update_ai_setting',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('updateMemoAI response: ${response.body}');
  if (response.statusCode == 200) {
    return MPUpdateMemoAIResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}
