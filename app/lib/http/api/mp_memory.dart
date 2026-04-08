import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../../env/env.dart';
import '../schema/mp_memory.dart';
import '../shared.dart';

// GET /api/v1/memory/get_list
Future<MPGetMemoryListResponse?> getMemoryList(MPGetMemoryV2ListRequest req) async {
  var response = await makeApiCall(
    url:
    '${Env.apiBaseUrl}api/v2/memory/get_list?page_size=${req.pageSize}&cursor=${req.cursor.isNotEmpty ? req.cursor : ''}${req.day != null ? '&day=${req.day}' : ''}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getMemoryList response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetMemoryListResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// GET /api/v1/memory/get_detail
Future<MPGetMemoryV2DetailResponse?> getMemoryDetail(MPGetMemoryV2DetailRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/memory/get_detail?memory_id=${req.memoryId}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getMemoryDetail response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetMemoryV2DetailResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

Future<MPGetMemoryFeedResponse?> getMemoryFeed(MPGetMemoryFeedRequest req) async {
  var response = await makeApiCall(
    url:
        '${Env.apiBaseUrl}api/v2/memory/feed/get_list?page_size=${req.pageSize}&memory_id=${req.memoryId}&cursor=${req.cursor}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getMemoryFeed response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetMemoryFeedResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  return null;
}

// POST /api/v1/memory/delete
Future<MPDeleteMemoryResponse?> deleteMemory(MPDeleteMemoryRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memory/delete',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('deleteMemory response: ${response.body}');
  if (response.statusCode == 200) {
    return MPDeleteMemoryResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/memory/rename
Future<MPRenameMemoryResponse?> renameMemory(MPRenameMemoryRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memory/rename',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('renameMemory response: ${response.body}');
  if (response.statusCode == 200) {
    return MPRenameMemoryResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// GET /api/v1/memory/share
Future<MPShareMemoryResponse?> shareMemory(MPShareMemoryRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memory/share?memory_id=${req.memoryId}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('shareMemory response: ${response.body}');
  if (response.statusCode == 200) {
    return MPShareMemoryResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/memory/create_record
Future<MPCreateRecordResponse?> createRecord(MPCreateRecordRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memory/create_record',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('createRecord response: ${response.body}');
  if (response.statusCode == 200) {
    return MPCreateRecordResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/memory/summary_record
Future<MPSummaryRecordResponse?> summaryRecord(MPSummaryRecordRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memory/summary_record',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('summaryRecord response: ${response.body}');
  if (response.statusCode == 200) {
    return MPSummaryRecordResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// GET /api/v1/memory/get_upload_record_url
Future<MPGetUploadRecordUrlResponse?> getUploadRecordUrl(MPGetUploadRecordUrlRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memory/get_upload_record_url?content_type=${req.contentType}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getUploadRecordUrl response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetUploadRecordUrlResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}