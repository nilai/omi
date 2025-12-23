import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:omi/backend/http/shared.dart';
import 'package:omi/backend/schema/mp/mp_chat.dart';
import 'package:omi/env/env.dart';

/// POST /api/v1/chat/create_conversation
Future<MPCreateConversationResponse?> createConversation(MPCreateConversationRequest req) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/chat/create_conversation',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('createConversation response: ${response.body}');
  if (response.statusCode == 200) {
    return MPCreateConversationResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

/// POST /api/v1/chat/chat
Future<MPChatResponse?> chat(MPChatRequest req) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/chat/chat',
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

/// GET /api/v1/chat/get_conversation_list
Future<MPGetConversationListResponse?> getConversationList(MPGetConversationListRequest req) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/chat/get_conversation_list?page_size=${req.pageSize}&cursor=${req.cursor}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getConversationList response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetConversationListResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

/// GET /api/v1/chat/get_conversation_detail
Future<MPGetConversationDetailResponse?> getConversationDetail(MPGetConversationDetailRequest req) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/chat/get_conversation_detail?conversation_id=${req.conversationId}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getConversationDetail response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetConversationDetailResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}
