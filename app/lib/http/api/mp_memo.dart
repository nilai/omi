// POST /api/v1/memo/create_with_text
import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../../env/env.dart';
import '../schema/mp_memo.dart';
import '../shared.dart';

Future<MPCreateMemoWithTextResponse?> createMemoWithText(MPCreateMemoWithTextRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memo/create_with_text',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('createMemoWithText response: ${response.body}');
  if (response.statusCode == 200) {
    return MPCreateMemoWithTextResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/memo/delete
Future<MPDeleteMemoResponse?> deleteMemo(MPDeleteMemoRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/memo/delete',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('deleteMemo response: ${response.body}');
  if (response.statusCode == 200) {
    return MPDeleteMemoResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}