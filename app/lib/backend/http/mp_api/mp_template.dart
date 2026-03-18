import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:omi/backend/http/shared.dart';
import 'package:omi/backend/schema/mp/mp_template.dart';
import 'package:omi/env/env.dart';

// GET /api/v1/template/get_list
Future<MPGetTemplateListResponse?> getTemplateList(MPGetTemplateListRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/template/get_list?page_size=${req.pageSize}&cursor=${req.cursor}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getTemplateList response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetTemplateListResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// GET /api/v1/template/get_detail
Future<MPGetTemplateDetailResponse?> getTemplateDetail(MPGetTemplateDetailRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/template/get_detail?template_id=${req.templateId}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getTemplateDetail response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetTemplateDetailResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/template/set_default
Future<MPSetTemplateDefaultResponse?> setTemplateDefault(MPSetTemplateDefaultRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/template/set_default',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('setTemplateDefault response: ${response.body}');
  if (response.statusCode == 200) {
    return MPSetTemplateDefaultResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/template/create
Future<MPCreateTemplateResponse?> createTemplate(MPCreateTemplateRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/template/create',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('createTemplate response: ${response.body}');
  if (response.statusCode == 200) {
    return MPCreateTemplateResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}
