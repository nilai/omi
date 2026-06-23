// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mp_chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MPCreateConversationRequest _$MPCreateConversationRequestFromJson(
  Map<String, dynamic> json,
) => MPCreateConversationRequest(
  title: json['title'] as String?,
  expertId: json['expert_id'] as String,
  memoryId: json['memory_id'] as String,
  templateId: json['template_id'] as String,
  speakerId: json['speaker_id'] as String,
  insightId: json['insight_id'] as String,
);

Map<String, dynamic> _$MPCreateConversationRequestToJson(
  MPCreateConversationRequest instance,
) => <String, dynamic>{
  'title': instance.title,
  'expert_id': instance.expertId,
  'memory_id': instance.memoryId,
  'template_id': instance.templateId,
  'speaker_id': instance.speakerId,
  'insight_id': instance.insightId,
};

MPCreateConversationResponse _$MPCreateConversationResponseFromJson(
  Map<String, dynamic> json,
) => MPCreateConversationResponse(
  conversationId: json['conversation_id'] as String,
  greet: json['greet'] as String,
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPCreateConversationResponseToJson(
  MPCreateConversationResponse instance,
) => <String, dynamic>{
  'conversation_id': instance.conversationId,
  'greet': instance.greet,
  'base_resp': instance.baseResp,
};

MPChatRequest _$MPChatRequestFromJson(Map<String, dynamic> json) =>
    MPChatRequest(
      message: json['message'] as String,
      conversationId: json['conversation_id'] as String,
    );

Map<String, dynamic> _$MPChatRequestToJson(MPChatRequest instance) =>
    <String, dynamic>{
      'message': instance.message,
      'conversation_id': instance.conversationId,
    };

MPGetConversationListRequest _$MPGetConversationListRequestFromJson(
  Map<String, dynamic> json,
) => MPGetConversationListRequest(
  pageSize: (json['page_size'] as num).toInt(),
  cursor: json['cursor'] as String?,
);

Map<String, dynamic> _$MPGetConversationListRequestToJson(
  MPGetConversationListRequest instance,
) => <String, dynamic>{
  'page_size': instance.pageSize,
  'cursor': instance.cursor,
};

MPConversationHeaderStruct _$MPConversationHeaderStructFromJson(
  Map<String, dynamic> json,
) => MPConversationHeaderStruct(
  id: json['id'] as String,
  title: json['title'] as String,
);

Map<String, dynamic> _$MPConversationHeaderStructToJson(
  MPConversationHeaderStruct instance,
) => <String, dynamic>{'id': instance.id, 'title': instance.title};

MPGetConversationListResponse _$MPGetConversationListResponseFromJson(
  Map<String, dynamic> json,
) => MPGetConversationListResponse(
  conversations: (json['conversations'] as List<dynamic>)
      .map(
        (e) => MPConversationHeaderStruct.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  hasMore: json['has_more'] as bool,
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPGetConversationListResponseToJson(
  MPGetConversationListResponse instance,
) => <String, dynamic>{
  'conversations': instance.conversations,
  'has_more': instance.hasMore,
  'base_resp': instance.baseResp,
};

MPGetConversationDetailRequest _$MPGetConversationDetailRequestFromJson(
  Map<String, dynamic> json,
) => MPGetConversationDetailRequest(
  conversationId: json['conversation_id'] as String,
  pageSize: (json['page_size'] as num).toInt(),
  cursor: json['cursor'] as String?,
);

Map<String, dynamic> _$MPGetConversationDetailRequestToJson(
  MPGetConversationDetailRequest instance,
) => <String, dynamic>{
  'conversation_id': instance.conversationId,
  'page_size': instance.pageSize,
  'cursor': instance.cursor,
};

MPConversationStruct _$MPConversationStructFromJson(
  Map<String, dynamic> json,
) => MPConversationStruct(
  speaker: MPSpeakerStruct.fromJson(json['speaker'] as Map<String, dynamic>),
  content: json['content'] as String,
  time: json['time'] as String,
);

Map<String, dynamic> _$MPConversationStructToJson(
  MPConversationStruct instance,
) => <String, dynamic>{
  'speaker': instance.speaker,
  'content': instance.content,
  'time': instance.time,
};

MPGetConversationDetailResponse _$MPGetConversationDetailResponseFromJson(
  Map<String, dynamic> json,
) => MPGetConversationDetailResponse(
  title: json['title'] as String,
  contents: (json['contents'] as List<dynamic>)
      .map((e) => MPConversationStruct.fromJson(e as Map<String, dynamic>))
      .toList(),
  hasMore: json['has_more'] as bool,
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPGetConversationDetailResponseToJson(
  MPGetConversationDetailResponse instance,
) => <String, dynamic>{
  'title': instance.title,
  'contents': instance.contents,
  'has_more': instance.hasMore,
  'base_resp': instance.baseResp,
};

MPTranscriptRequest _$MPTranscriptRequestFromJson(Map<String, dynamic> json) =>
    MPTranscriptRequest(audioUrl: json['audio_url'] as String);

Map<String, dynamic> _$MPTranscriptRequestToJson(
  MPTranscriptRequest instance,
) => <String, dynamic>{'audio_url': instance.audioUrl};

MPTranscriptResponse _$MPTranscriptResponseFromJson(
  Map<String, dynamic> json,
) => MPTranscriptResponse(
  content: json['content'] as String,
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPTranscriptResponseToJson(
  MPTranscriptResponse instance,
) => <String, dynamic>{
  'content': instance.content,
  'base_resp': instance.baseResp,
};

MPGetChatSuggestionCardRequest _$MPGetChatSuggestionCardRequestFromJson(
  Map<String, dynamic> json,
) => MPGetChatSuggestionCardRequest();

Map<String, dynamic> _$MPGetChatSuggestionCardRequestToJson(
  MPGetChatSuggestionCardRequest instance,
) => <String, dynamic>{};

MPChatSuggestionCard _$MPChatSuggestionCardFromJson(
  Map<String, dynamic> json,
) => MPChatSuggestionCard(
  title: json['title'] as String,
  subtitle: json['subtitle'] as String,
  content: json['content'] as String,
  detail: json['detail'] as String,
  suggestions: (json['suggestions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$MPChatSuggestionCardToJson(
  MPChatSuggestionCard instance,
) => <String, dynamic>{
  'title': instance.title,
  'subtitle': instance.subtitle,
  'content': instance.content,
  'detail': instance.detail,
  'suggestions': instance.suggestions,
};

MPGetChatSuggestionCardsResponse _$MPGetChatSuggestionCardsResponseFromJson(
  Map<String, dynamic> json,
) => MPGetChatSuggestionCardsResponse(
  suggestion: (json['suggestion'] as List<dynamic>)
      .map((e) => MPChatSuggestionCard.fromJson(e as Map<String, dynamic>))
      .toList(),
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPGetChatSuggestionCardsResponseToJson(
  MPGetChatSuggestionCardsResponse instance,
) => <String, dynamic>{
  'suggestion': instance.suggestion,
  'base_resp': instance.baseResp,
};

MPGetLastConversationRequest _$MPGetLastConversationRequestFromJson(
  Map<String, dynamic> json,
) => MPGetLastConversationRequest(
  conversationType: (json['conversation_type'] as num).toInt(),
  paramId: json['param_id'] as String,
);

Map<String, dynamic> _$MPGetLastConversationRequestToJson(
  MPGetLastConversationRequest instance,
) => <String, dynamic>{
  'conversation_type': instance.conversationType,
  'param_id': instance.paramId,
};

MPGetLastConversationResponse _$MPGetLastConversationResponseFromJson(
  Map<String, dynamic> json,
) => MPGetLastConversationResponse(
  conversationId: json['conversation_id'] as String,
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPGetLastConversationResponseToJson(
  MPGetLastConversationResponse instance,
) => <String, dynamic>{
  'conversation_id': instance.conversationId,
  'base_resp': instance.baseResp,
};

MPDeleteChatRequest _$MPDeleteChatRequestFromJson(Map<String, dynamic> json) =>
    MPDeleteChatRequest(conversationId: json['conversation_id'] as String);

Map<String, dynamic> _$MPDeleteChatRequestToJson(
  MPDeleteChatRequest instance,
) => <String, dynamic>{'conversation_id': instance.conversationId};

MPDeleteChatResponse _$MPDeleteChatResponseFromJson(
  Map<String, dynamic> json,
) => MPDeleteChatResponse(
  success: json['success'] as bool,
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPDeleteChatResponseToJson(
  MPDeleteChatResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'base_resp': instance.baseResp,
};
