import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../env/env.dart';
import '../schema/mp_home.dart';
import '../shared.dart';

/// GET /api/v2/home/get_overview — 首页聚合：今日焦点待办、最近记忆、Insight 概览。
Future<MPGetHomeOverviewResponse?> getHomeOverview(MPGetHomeOverviewRequest req) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/home/get_overview',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) {
    return null;
  }
  debugPrint('getHomeOverview response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetHomeOverviewResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  return null;
}

/// POST /api/v2/home/close_transcription_banner — 关闭转录提示弹窗。
Future<MPCloseTranscriptionBannerResponse?> closeTranscriptionBanner(
  MPCloseTranscriptionBannerRequest req,
) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/home/close_transcription_banner',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) {
    return null;
  }
  debugPrint('closeTranscriptionBanner response: ${response.body}');
  if (response.statusCode == 200) {
    return MPCloseTranscriptionBannerResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  return null;
}
