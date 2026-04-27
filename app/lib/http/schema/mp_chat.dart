import 'package:json_annotation/json_annotation.dart';

import 'mp_data_model.dart';

part 'mp_chat.g.dart';

@JsonSerializable()
class MPCreateConversationRequest {
  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'expert_id')
  final String expertId;

  @JsonKey(name: 'memory_id')
  final String memoryId;

  @JsonKey(name: 'template_id')
  final String templateId;

  @JsonKey(name: 'speaker_id')
  final String speakerId;

  MPCreateConversationRequest({
    this.title,
    required this.expertId,
    required this.memoryId,
    required this.templateId,
    required this.speakerId,
  });

  factory MPCreateConversationRequest.fromJson(Map<String, dynamic> json) =>
      _$MPCreateConversationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateConversationRequestToJson(this);
}

@JsonSerializable()
class MPCreateConversationResponse {
  @JsonKey(name: 'conversation_id')
  final String conversationId;

  @JsonKey(name: 'greet')
  final String greet;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPCreateConversationResponse({
    required this.conversationId,
    required this.greet,
    required this.baseResp,
  });

  factory MPCreateConversationResponse.fromJson(Map<String, dynamic> json) =>
      _$MPCreateConversationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateConversationResponseToJson(this);
}

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

  factory MPChatRequest.fromJson(Map<String, dynamic> json) =>
      _$MPChatRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPChatRequestToJson(this);
}

@JsonSerializable()
class MPGetConversationListRequest {
  @JsonKey(name: 'page_size')
  final int pageSize;

  @JsonKey(name: 'cursor')
  final String? cursor;

  MPGetConversationListRequest({
    required this.pageSize,
    this.cursor,
  });

  factory MPGetConversationListRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetConversationListRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetConversationListRequestToJson(this);
}

@JsonSerializable()
class MPConversationHeaderStruct {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'title')
  final String title;

  MPConversationHeaderStruct({
    required this.id,
    required this.title,
  });

  factory MPConversationHeaderStruct.fromJson(Map<String, dynamic> json) =>
      _$MPConversationHeaderStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPConversationHeaderStructToJson(this);
}

@JsonSerializable()
class MPGetConversationListResponse {
  @JsonKey(name: 'conversations')
  final List<MPConversationHeaderStruct> conversations;

  @JsonKey(name: 'has_more')
  final bool hasMore;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetConversationListResponse({
    required this.conversations,
    required this.hasMore,
    required this.baseResp,
  });

  factory MPGetConversationListResponse.fromJson(Map<String, dynamic> json) =>
      _$MPGetConversationListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetConversationListResponseToJson(this);
}

@JsonSerializable()
class MPGetConversationDetailRequest {
  @JsonKey(name: 'conversation_id')
  final String conversationId;

  @JsonKey(name: 'page_size')
  final int pageSize;

  @JsonKey(name: 'cursor')
  final String? cursor;

  MPGetConversationDetailRequest({
    required this.conversationId,
    required this.pageSize,
    this.cursor,
  });

  factory MPGetConversationDetailRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetConversationDetailRequestFromJson(json);

  Map<String, dynamic> toJson() =>
      _$MPGetConversationDetailRequestToJson(this);
}

@JsonSerializable()
class MPConversationStruct {
  @JsonKey(name: 'speaker')
  final MPSpeakerStruct speaker;

  @JsonKey(name: 'content')
  final String content;

  @JsonKey(name: 'time')
  final String time;

  MPConversationStruct({
    required this.speaker,
    required this.content,
    required this.time,
  });

  factory MPConversationStruct.fromJson(Map<String, dynamic> json) =>
      _$MPConversationStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPConversationStructToJson(this);
}

@JsonSerializable()
class MPGetConversationDetailResponse {
  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'contents')
  final List<MPConversationStruct> contents;

  @JsonKey(name: 'has_more')
  final bool hasMore;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetConversationDetailResponse({
    required this.title,
    required this.contents,
    required this.hasMore,
    required this.baseResp,
  });

  factory MPGetConversationDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$MPGetConversationDetailResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$MPGetConversationDetailResponseToJson(this);
}

@JsonSerializable()
class MPTranscriptRequest {
  @JsonKey(name: 'audio_url')
  final String audioUrl;

  MPTranscriptRequest({
    required this.audioUrl,
  });

  factory MPTranscriptRequest.fromJson(Map<String, dynamic> json) =>
      _$MPTranscriptRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPTranscriptRequestToJson(this);
}

@JsonSerializable()
class MPTranscriptResponse {
  @JsonKey(name: 'content')
  final String content;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPTranscriptResponse({
    required this.content,
    required this.baseResp,
  });

  factory MPTranscriptResponse.fromJson(Map<String, dynamic> json) =>
      _$MPTranscriptResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPTranscriptResponseToJson(this);
}

@JsonSerializable()
class MPGetChatSuggestionRequest {
  MPGetChatSuggestionRequest();

  factory MPGetChatSuggestionRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetChatSuggestionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetChatSuggestionRequestToJson(this);
}

@JsonSerializable()
class MPGetChatSuggestionResponse {
  @JsonKey(name: 'suggestion')
  final Map<String, Map<String, List<String>>> suggestion;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetChatSuggestionResponse({
    required this.suggestion,
    required this.baseResp,
  });

  factory MPGetChatSuggestionResponse.fromJson(Map<String, dynamic> json) =>
      _$MPGetChatSuggestionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetChatSuggestionResponseToJson(this);
}

@JsonSerializable()
class MPGetChatSuggestionCardRequest {
  MPGetChatSuggestionCardRequest();

  factory MPGetChatSuggestionCardRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetChatSuggestionCardRequestFromJson(json);

  Map<String, dynamic> toJson() =>
      _$MPGetChatSuggestionCardRequestToJson(this);
}

@JsonSerializable()
class MPChatSuggestionCard {
  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'subtitle')
  final String subtitle;

  @JsonKey(name: 'content')
  final String content;

  @JsonKey(name: 'detail')
  final String detail;

  @JsonKey(name: 'suggestions')
  final List<String> suggestions;

  MPChatSuggestionCard({
    required this.title,
    required this.subtitle,
    required this.content,
    required this.detail,
    required this.suggestions,
  });

  factory MPChatSuggestionCard.fromJson(Map<String, dynamic> json) =>
      _$MPChatSuggestionCardFromJson(json);

  Map<String, dynamic> toJson() => _$MPChatSuggestionCardToJson(this);
}

@JsonSerializable()
class MPGetChatSuggestionCardsResponse {
  @JsonKey(name: 'suggestion')
  final List<MPChatSuggestionCard> suggestion;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetChatSuggestionCardsResponse({
    required this.suggestion,
    required this.baseResp,
  });

  factory MPGetChatSuggestionCardsResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$MPGetChatSuggestionCardsResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$MPGetChatSuggestionCardsResponseToJson(this);
}

@JsonSerializable()
class MPGetLastConversationRequest {
  MPGetLastConversationRequest();

  factory MPGetLastConversationRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetLastConversationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetLastConversationRequestToJson(this);
}

@JsonSerializable()
class MPGetLastConversationResponse {
  @JsonKey(name: 'conversation_id')
  final String conversationId;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetLastConversationResponse({
    required this.conversationId,
    required this.baseResp,
  });

  factory MPGetLastConversationResponse.fromJson(Map<String, dynamic> json) =>
      _$MPGetLastConversationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetLastConversationResponseToJson(this);
}

@JsonSerializable()
class MPGetConversationTitleRequest {
  @JsonKey(name: 'conversation_id')
  final String conversationId;

  MPGetConversationTitleRequest({
    required this.conversationId,
  });

  factory MPGetConversationTitleRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetConversationTitleRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetConversationTitleRequestToJson(this);
}

@JsonSerializable()
class MPGetConversationTitleResponse {
  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetConversationTitleResponse({
    required this.title,
    required this.baseResp,
  });

  factory MPGetConversationTitleResponse.fromJson(Map<String, dynamic> json) =>
      _$MPGetConversationTitleResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetConversationTitleResponseToJson(this);
}
