// GET /api/v1/template/get_list
import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../../env/env.dart';
import '../schema/mp_template.dart';
import '../shared.dart';

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