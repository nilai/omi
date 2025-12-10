import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:omi/backend/http/shared.dart';
import 'package:omi/backend/schema/mp/mp_expert.dart';
import 'package:omi/env/env.dart';

// GET /api/v1/expert/get_list
Future<MPGetExpertListResponse?> getExpertList(MPGetExpertListRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/expert/get_list?page_size=${req.pageSize}&cursor=${req.cursor}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getExpertList response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetExpertListResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// GET /api/v1/expert/get_detail
Future<MPGetExpertDetailResponse?> getExpertDetail(MPGetExpertDetailRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/expert/get_detail?expert_id=${req.expertId}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getExpertDetail response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetExpertDetailResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

