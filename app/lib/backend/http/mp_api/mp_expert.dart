import 'dart:convert';
import 'dart:io';

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

// POST /api/v1/expert/create
Future<MPCreateExpertResponse?> createExpert(
  MPCreateExpertRequest req, {
  File? avatarFile,
}) async {
  try {
    var response;
    if (avatarFile != null) {
      // 如果有头像文件，使用 multipart 上传
      response = await makeMultipartApiCall(
        url: '${Env.apiBaseUrl}api/v1/expert/create',
        files: [avatarFile],
        fileFieldName: 'avatar',
        fields: {
          'expert_data': jsonEncode(req.toJson()),
        },
        method: 'POST',
      );
    } else {
      // 如果没有头像文件，使用普通 POST
      response = await makeApiCall(
        url: '${Env.apiBaseUrl}api/v1/expert/create',
        headers: {'Content-Type': 'application/json'},
        method: 'POST',
        body: jsonEncode(req.toJson()),
      );
    }

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
