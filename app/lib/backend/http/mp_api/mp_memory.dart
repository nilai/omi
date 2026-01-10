import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:omi/backend/http/shared.dart';
import 'package:omi/backend/schema/mp/mp_memory.dart';
import 'package:omi/env/env.dart';

// GET /api/v1/memory/get_list
Future<MPGetMemoryListResponse?> getMemoryList(MPGetMemoryListRequest req) async {
  var response = await makeApiCall(
    url:
        '${Env.apiBaseUrl}api/v1/memory/get_list?page_size=${req.pageSize}&cursor=${req.cursor.isNotEmpty ? req.cursor : ''}${req.day != null ? '&day=${req.day}' : ''}',
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

// GET /api/v1/memory/get_days
Future<MPGetMemoryDaysResponse?> getMemoryDays(MPGetMemoryDaysRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memory/get_days?month=${req.month}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getMemoryDays response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetMemoryDaysResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// GET /api/v1/memory/get_detail
Future<MPGetMemoryDetailResponse?> getMemoryDetail(MPGetMemoryDetailRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memory/get_detail?memory_id=${req.memoryId}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getMemoryDetail response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetMemoryDetailResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// GET /api/v1/memory/get_insight_list
Future<MPGetInsightListResponse?> getInsightList(MPGetInsightListRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memory/get_insight_list?page_size=${req.pageSize}&cursor=${req.cursor}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getInsightList response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetInsightListResponse.fromJson(jsonDecode(response.body));
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

// GET /api/v1/memory/get_popular_search_keywords
Future<MPGetPopularSearchKeywordsResponse?> getPopularSearchKeywords() async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memory/get_popular_search_keywords',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getPopularSearchKeywords response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetPopularSearchKeywordsResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// GET /api/v1/memory/summary/get_status
Future<MPGetSummaryStatusResponse?> getSummaryStatus(MPGetSummaryStatusRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memory/summary/get_status?memory_id=${req.memoryId}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getSummaryStatus response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetSummaryStatusResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// GET /api/v1/memory/search
Future<MPSearchMemoryResponse?> searchMemory(MPSearchMemoryRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memory/search?search_content=${Uri.encodeComponent(req.searchContent)}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('searchMemory response: ${response.body}');
  if (response.statusCode == 200) {
    return MPSearchMemoryResponse.fromJson(jsonDecode(response.body));
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

// POST /api/v1/memory/add_tag
Future<MPMemoryAddTagResponse?> memoryAddTag(MPMemoryAddTagRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memory/add_tag',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('memoryAddTag response: ${response.body}');
  if (response.statusCode == 200) {
    return MPMemoryAddTagResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// GET /api/v1/memory/get_summary_list
Future<MPGetSummaryListResponse?> getSummaryList(MPGetSummaryListRequest req) async {
  var response = await makeApiCall(
    url:
        '${Env.apiBaseUrl}api/v1/memory/get_summary_list?page_size=${req.pageSize}&cursor=${Uri.encodeComponent(req.cursor)}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getSummaryList response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetSummaryListResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/memory/append_summary
Future<MPAppendMemoryResponse?> appendMemory(MPAppendMemoryRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memory/append_summary',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('appendMemory response: ${response.body}');
  if (response.statusCode == 200) {
    return MPAppendMemoryResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}
