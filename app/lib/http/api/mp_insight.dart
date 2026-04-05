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
