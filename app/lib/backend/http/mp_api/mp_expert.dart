import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:omi/backend/http/shared.dart';
import 'package:omi/backend/schema/mp/mp_expert.dart';
import 'package:omi/env/env.dart';

// GET /api/v1/expert/get_list
Future<MPGetExpertListResponse?> getExpertList(MPGetExpertListRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/expert/get_list?page_size=${req.pageSize}&cursor=${req.cursor}&type=${req.type}',
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

// POST /api/v1/expert/create
Future<MPCreateExpertResponse?> createExpert(MPCreateExpertRequest req) async {
  try {
    var response = await makeApiCall(
      url: '${Env.apiBaseUrl}api/v1/expert/create',
      headers: {'Content-Type': 'application/json'},
      method: 'POST',
      body: jsonEncode(req.toJson()),
    );
    if (response == null) return null;
    debugPrint('createExpert response: ${response.body}');

    if (response.statusCode == 200) {
      return MPCreateExpertResponse.fromJson(jsonDecode(response.body));
    } else {
      debugPrint('createExpert error ${response.statusCode}: ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('createExpert exception: $e');
    return null;
  }
}

// POST /api/v1/expert/user_add
Future<UserAddExpertResponse?> userAddExpert(UserAddExpertRequest req) async {
  try {
    var response = await makeApiCall(
      url: '${Env.apiBaseUrl}api/v1/expert/user_add',
      headers: {'Content-Type': 'application/json'},
      method: 'POST',
      body: jsonEncode(req.toJson()),
    );
    if (response == null) return null;
    debugPrint('userAddExpert response: ${response.body}');

    if (response.statusCode == 200) {
      return UserAddExpertResponse.fromJson(jsonDecode(response.body));
    } else {
      debugPrint('userAddExpert error ${response.statusCode}: ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('userAddExpert exception: $e');
    return null;
  }
}

// POST /api/v1/expert/user_cancel
Future<UserCancelExpertResponse?> userCancelExpert(UserCancelExpertRequest req) async {
  try {
    var response = await makeApiCall(
      url: '${Env.apiBaseUrl}api/v1/expert/user_cancel',
      headers: {'Content-Type': 'application/json'},
      method: 'POST',
      body: jsonEncode(req.toJson()),
    );
    if (response == null) return null;
    debugPrint('userCancelExpert response: ${response.body}');

    if (response.statusCode == 200) {
      return UserCancelExpertResponse.fromJson(jsonDecode(response.body));
    } else {
      debugPrint('userCancelExpert error ${response.statusCode}: ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('userCancelExpert exception: $e');
    return null;
  }
}
