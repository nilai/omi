import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../../env/env.dart';
import '../schema/mp_chat.dart';
import '../shared.dart';

// POST /api/v1/chat/create_conversation
Future<MPCreateConversationResponse?> createConversation(
  MPCreateConversationRequest req,
) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/chat/create_conversation',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('createConversation response: ${response.body}');
  if (response.statusCode == 200) {
    return MPCreateConversationResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  return null;
}

// POST /api/v1/chat/chat
Stream<String> chat(MPChatRequest req) {
  return makeStreamingApiCall(
    url: '${Env.apiBaseUrl}api/v1/chat/chat',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
}

// GET /api/v1/chat/get_conversation_list
Future<MPGetConversationListResponse?> getConversationList(
  MPGetConversationListRequest req,
) async {
  final response = await makeApiCall(
    url:
        '${Env.apiBaseUrl}api/v1/chat/get_conversation_list?page_size=${req.pageSize}${req.cursor == null || req.cursor!.isEmpty ? '' : '&cursor=${req.cursor}'}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getConversationList response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetConversationListResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  return null;
}

// GET /api/v1/chat/get_conversation_detail
Future<MPGetConversationDetailResponse?> getConversationDetail(
  MPGetConversationDetailRequest req,
) async {
  final response = await makeApiCall(
    url:
        '${Env.apiBaseUrl}api/v1/chat/get_conversation_detail?conversation_id=${req.conversationId}&page_size=${req.pageSize}${req.cursor == null || req.cursor!.isEmpty ? '' : '&cursor=${req.cursor}'}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getConversationDetail response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetConversationDetailResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  return null;
}

// POST /api/v1/chat/transcript
Future<MPTranscriptResponse?> transcript(MPTranscriptRequest req) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/chat/transcript',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('transcript response: ${response.body}');
  if (response.statusCode == 200) {
    return MPTranscriptResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  return null;
}

// GET /api/v1/chat/suggestion_cards
Future<MPGetChatSuggestionCardsResponse?> getChatSuggestionCards(
  MPGetChatSuggestionCardRequest req,
) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/chat/suggestion_cards',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getChatSuggestionCards response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetChatSuggestionCardsResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  return null;
}

// GET /api/v1/chat/get_last_conversation_id
Future<MPGetLastConversationResponse?> getLastConversation(
  MPGetLastConversationRequest req,
) async {
  final response = await makeApiCall(
    url:
        '${Env.apiBaseUrl}api/v1/chat/get_last_conversation_id?conversation_type=${req.conversationType}&param_id=${req.paramId}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getLastConversation response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetLastConversationResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  return null;
}

// POST /api/v1/chat/delete
Future<MPDeleteChatResponse?> deleteChat(MPDeleteChatRequest req) async {
  final response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/chat/delete',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('deleteChat response: ${response.body}');
  if (response.statusCode == 200) {
    return MPDeleteChatResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  return null;
}
