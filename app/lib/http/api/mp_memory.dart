import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../../env/env.dart';
import '../schema/mp_memory.dart';
import '../shared.dart';

// GET /api/v1/memory/get_list
Future<MPGetMemoryListResponse?> getMemoryList(MPGetMemoryV2ListRequest req) async {
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