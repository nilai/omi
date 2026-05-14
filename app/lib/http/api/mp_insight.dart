import 'dart:convert';

import 'package:flutter/material.dart';

import '../../env/env.dart';
import '../schema/mp_insight.dart';
import '../shared.dart';

/// GET /api/v2/insight/feed/get_list — Insight 信息流分页。
Future<MPGetInsightFeedListResponse?> getInsightFeedList(
  MPGetInsightFeedListRequest req,
) async {
  final StringBuffer url = StringBuffer(
    '${Env.apiBaseUrl}api/v2/insight/feed/get_list?page_size=${req.pageSize}',
  );
  if (req.cursor != null && req.cursor!.isNotEmpty) {
    url.write('&cursor=${req.cursor}');
  }

  final response = await makeApiCall(
    url: url.toString(),
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) {
    return null;
  }
  debugPrint('getInsightFeedList response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetInsightFeedListResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  return null;
}

/// GET /api/v2/insight/get_detail — Insight 详情。
Future<MPGetInsightDetailResponse?> getInsightDetail(
  MPGetInsightDetailRequest req,
) async {
  final String url =
      '${Env.apiBaseUrl}api/v2/insight/get_detail?insight_id=${req.insightId}';
  final response = await makeApiCall(
    url: url,
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) {
    return null;
  }
  debugPrint('getInsightDetail response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetInsightDetailResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  return null;
}

/// GET /api/v2/insight/get_simple_detail — 按 todo 拉取 Insight 简易信息。
Future<MPGetInsightSimpleDetailResponse?> getInsightSimpleDetail(
  MPGetInsightSimpleDetailRequest req,
) async {
  final String url =
      '${Env.apiBaseUrl}api/v2/insight/get_simple_detail?todo_id=${req.todoId}';
  final response = await makeApiCall(
    url: url,
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) {
    return null;
  }
  debugPrint('getInsightSimpleDetail response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetInsightSimpleDetailResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  return null;
}

/// GET /api/v2/home/get_insight_overview — 首页 Insight 聚合概览。
Future<MPGetHomeInsightOverviewResponse?> getHomeInsightOverview(
  MPGetHomeInsightOverviewRequest req,
) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/home/get_insight_overview',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) {
    return null;
  }
  debugPrint('getHomeInsightOverview response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetHomeInsightOverviewResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  return null;
}

/// GET /api/v2/insight/insight_suggestion — 获取 Insight 建议问题。
Future<MPGetInsightSuggestionResponse?> getInsightSuggestion(
  MPGetInsightSuggestionRequest req,
) async {
  final String url =
      '${Env.apiBaseUrl}api/v2/insight/insight_suggestion?insight_id=${req.insightId}';
  final response = await makeApiCall(
    url: url,
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) {
    return null;
  }
  debugPrint('getInsightSuggestion response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetInsightSuggestionResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  return null;
}

/// POST /api/v2/insight/delete — 删除 Insight。
Future<MPDeleteInsightResponse?> deleteInsight(
  MPDeleteInsightRequest req,
) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/insight/delete',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) {
    return null;
  }
  debugPrint('deleteInsight response: ${response.body}');
  if (response.statusCode == 200) {
    return MPDeleteInsightResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  return null;
}

/// GET /api/v2/insight/share — 获取 Insight 分享信息。
Future<MPShareInsightResponse?> shareInsight(
  MPShareInsightRequest req,
) async {
  final String url =
      '${Env.apiBaseUrl}api/v2/insight/share?insight_id=${req.insightId}';
  final response = await makeApiCall(
    url: url,
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) {
    return null;
  }
  debugPrint('shareInsight response: ${response.body}');
  if (response.statusCode == 200) {
    return MPShareInsightResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  return null;
}
