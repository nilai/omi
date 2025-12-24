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
Stream<String> chat(MPChatRequest req) async* {
  // final response = await makeApiCall(
  //   url: '${Env.apiBaseUrl}api/v1/chat/chat',
  //   headers: {},
  //   method: 'POST',
  //   body: jsonEncode(req.toJson()),
  // );
  // if (response == null) return null;
  // debugPrint('chat response: ${response.body}');
  // if (response.statusCode == 200) {
  //   return MPChatResponse.fromJson(jsonDecode(response.body));
  // }
  // return null;

  var url = '${Env.apiBaseUrl}api/v1/chat/chat';
  // var messageId = "1000"; // Default new message

  await for (var line in makeStreamingApiCall(
    url: url,
    // body: jsonEncode({'text': text, 'file_ids': filesId}),
    body: jsonEncode(req.toJson()),
  )) {
    yield line;
  }
}

// Stream<ServerMessageChunk> sendMessageStreamServer(String text) async* {
//   var url = '${Env.apiBaseUrl}api/v1/chat/chat';
//   // if (appId == null || appId.isEmpty || appId == 'null' || appId == 'no_selected') {
//   //   url = '${Env.apiBaseUrl}v2/messages';
//   // }

//   var messageId = "1000"; // Default new message

//   await for (var line in makeStreamingApiCall(
//     url: url,
//     body: jsonEncode({'text': text, 'file_ids': filesId}),
//   )) {
//     var messageChunk = parseMessageChunk(line, messageId);
//     if (messageChunk != null) {
//       yield messageChunk;
//     } else {
//       yield ServerMessageChunk.failedMessage();
//       return;
//     }
//   }
// }

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
