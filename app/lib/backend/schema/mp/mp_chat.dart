import 'package:json_annotation/json_annotation.dart';

import 'mp_data_model.dart';

part 'mp_chat.g.dart';

/// Chat Request
@JsonSerializable()
class MPChatRequest {
  @JsonKey(name: 'message')
  final String message;

  @JsonKey(name: 'conversation_id')
  final String conversationId;

  MPChatRequest({
    required this.message,
    required this.conversationId,
  });

  factory MPChatRequest.fromJson(Map<String, dynamic> json) => _$MPChatRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPChatRequestToJson(this);
}

// ========== Response Classes ==========

// Chat Response (streaming接口，暂时为空结构)
@JsonSerializable()
class MPChatResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp? baseResp;

  MPChatResponse({
    this.baseResp,
  });

  factory MPChatResponse.fromJson(Map<String, dynamic> json) => _$MPChatResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPChatResponseToJson(this);
}

/// Create Conversation Request
class MPCreateConversationRequest {
  final String? title;
  final String expertId;
  final String memoryId;
  final String templateId;
  final String speakerId;

  MPCreateConversationRequest({
    this.title,
    this.expertId = '',
    this.memoryId = '',
    this.templateId = '',
    this.speakerId = '',
  });

  factory MPCreateConversationRequest.fromJson(Map<String, dynamic> json) {
    return MPCreateConversationRequest(
      title: json['title'] as String?,
      expertId: json['expert_id'] as String? ?? '',
      memoryId: json['memory_id'] as String? ?? '',
      templateId: json['template_id'] as String? ?? '',
      speakerId: json['speaker_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      'expert_id': expertId,
      'memory_id': memoryId,
      'template_id': templateId,
      'speaker_id': speakerId,
    };
  }
}

/// Create Conversation Response
class MPCreateConversationResponse {
  final String conversationId;
  final MPBaseResp baseResp;

  MPCreateConversationResponse({
    required this.conversationId,
    required this.baseResp,
  });

  factory MPCreateConversationResponse.fromJson(Map<String, dynamic> json) {
    return MPCreateConversationResponse(
      conversationId: json['conversation_id'] as String? ?? '',
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'base_resp': baseResp.toJson(),
    };
  }
}

/// Conversation Header Struct
class MPConversationHeaderStruct {
  final String id;
  final String title;

  MPConversationHeaderStruct({
    required this.id,
    required this.title,
  });

  factory MPConversationHeaderStruct.fromJson(Map<String, dynamic> json) {
    return MPConversationHeaderStruct(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }
}

/// Conversation Struct
class MPConversationStruct {
  final MPSpeakerStruct speaker;
  final String content;
  final String time;

  MPConversationStruct({
    required this.speaker,
    required this.content,
    required this.time,
  });

  factory MPConversationStruct.fromJson(Map<String, dynamic> json) {
    return MPConversationStruct(
      speaker: MPSpeakerStruct.fromJson(json['speaker'] as Map<String, dynamic>),
      content: json['content'] as String? ?? '',
      time: json['time'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speaker': speaker.toJson(),
      'content': content,
      'time': time,
    };
  }
}

/// Get Conversation List Request
class MPGetConversationListRequest {
  final int pageSize;
  final String cursor;

  MPGetConversationListRequest({
    required this.pageSize,
    required this.cursor,
  });

  factory MPGetConversationListRequest.fromJson(Map<String, dynamic> json) {
    return MPGetConversationListRequest(
      pageSize: json['page_size'] as int? ?? 0,
      cursor: json['cursor'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page_size': pageSize,
      'cursor': cursor,
    };
  }
}

/// Get Conversation List Response
class MPGetConversationListResponse {
  final List<MPConversationHeaderStruct> conversations;
  final bool hasMore;
  final MPBaseResp baseResp;

  MPGetConversationListResponse({
    required this.conversations,
    required this.hasMore,
    required this.baseResp,
  });

  factory MPGetConversationListResponse.fromJson(Map<String, dynamic> json) {
    return MPGetConversationListResponse(
      conversations: ((json['conversations'] ?? []) as List<dynamic>)
          .map((item) => MPConversationHeaderStruct.fromJson(item as Map<String, dynamic>))
          .toList(),
      hasMore: json['has_more'] as bool? ?? false,
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversations': conversations.map((e) => e.toJson()).toList(),
      'has_more': hasMore,
      'base_resp': baseResp.toJson(),
    };
  }
}

/// Get Conversation Detail Request
class MPGetConversationDetailRequest {
  final String conversationId;

  MPGetConversationDetailRequest({
    required this.conversationId,
  });

  factory MPGetConversationDetailRequest.fromJson(Map<String, dynamic> json) {
    return MPGetConversationDetailRequest(
      conversationId: json['conversation_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
    };
  }
}

/// Get Conversation Detail Response
class MPGetConversationDetailResponse {
  final String title;
  final List<MPConversationStruct> contents;
  final MPBaseResp baseResp;

  MPGetConversationDetailResponse({
    required this.title,
    required this.contents,
    required this.baseResp,
  });

  factory MPGetConversationDetailResponse.fromJson(Map<String, dynamic> json) {
    return MPGetConversationDetailResponse(
      title: json['title'] as String? ?? '',
      contents: ((json['contents'] ?? []) as List<dynamic>)
          .map((item) => MPConversationStruct.fromJson(item as Map<String, dynamic>))
          .toList(),
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'contents': contents.map((e) => e.toJson()).toList(),
      'base_resp': baseResp.toJson(),
    };
  }
}
