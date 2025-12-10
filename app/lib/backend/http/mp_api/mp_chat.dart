import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:omi/backend/http/shared.dart';
import 'package:omi/backend/schema/mp/mp_chat.dart';
import 'package:omi/env/env.dart';

// POST /api/v1/chat
Future<MPChatResponse?> chat(MPChatRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/chat',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('chat response: ${response.body}');
  if (response.statusCode == 200) {
    return MPChatResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}
