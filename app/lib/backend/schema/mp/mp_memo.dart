import 'package:json_annotation/json_annotation.dart';

import 'mp_data_model.dart';

part 'mp_memo.g.dart';

// Get Memo List Request
@JsonSerializable()
class MPGetMemoListRequest {
  @JsonKey(name: 'page_size')
  final int pageSize;

  @JsonKey(name: 'cursor')
  final String cursor;

  MPGetMemoListRequest({
    required this.pageSize,
    required this.cursor,
  });

  factory MPGetMemoListRequest.fromJson(Map<String, dynamic> json) => _$MPGetMemoListRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetMemoListRequestToJson(this);
}

// Get Memo Detail Request
@JsonSerializable()
class MPGetMemoDetailRequest {
  @JsonKey(name: 'memo_id')
  final String memoId;

  MPGetMemoDetailRequest({
    required this.memoId,
  });

  factory MPGetMemoDetailRequest.fromJson(Map<String, dynamic> json) => _$MPGetMemoDetailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetMemoDetailRequestToJson(this);
}

// Create Memo With Record Request
@JsonSerializable()
class MPCreateMemoWithRecordRequest {
  @JsonKey(name: 'record_url')
  final String recordUrl; // 针对没开启录音情况下的memo创建

  @JsonKey(name: 'create_at')
  final int createAt;

  MPCreateMemoWithRecordRequest({
    required this.recordUrl,
    required this.createAt,
  });

  factory MPCreateMemoWithRecordRequest.fromJson(Map<String, dynamic> json) =>
      _$MPCreateMemoWithRecordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateMemoWithRecordRequestToJson(this);
}

// Create Memo With Text Request
@JsonSerializable()
class MPCreateMemoWithTextRequest {
  @JsonKey(name: 'content')
  final String content;

  @JsonKey(name: 'create_at')
  final int createAt;

  MPCreateMemoWithTextRequest({
    required this.content,
    required this.createAt,
  });

  factory MPCreateMemoWithTextRequest.fromJson(Map<String, dynamic> json) =>
      _$MPCreateMemoWithTextRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateMemoWithTextRequestToJson(this);
}

// Delete Memo Request
@JsonSerializable()
class MPDeleteMemoRequest {
  @JsonKey(name: 'memo_id')
  final String memoId;

  MPDeleteMemoRequest({
    required this.memoId,
  });

  factory MPDeleteMemoRequest.fromJson(Map<String, dynamic> json) => _$MPDeleteMemoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPDeleteMemoRequestToJson(this);
}

// Update Memo AI Request
@JsonSerializable()
class MPUpdateMemoAIRequest {
  @JsonKey(name: 'right_now_transcribe')
  final bool? rightNowTranscribe;

  // AI如何称呼您
  @JsonKey(name: 'appellation')
  final String? appellation;

  // 职业
  @JsonKey(name: 'profession')
  final String? profession;

  // AI人格
  @JsonKey(name: 'ai_personality')
  final String? aiPersonality;

  @JsonKey(name: 'response_style')
  final String? responseStyle;

  @JsonKey(name: 'custom_prompt')
  final String? customPrompt;

  MPUpdateMemoAIRequest({
    this.rightNowTranscribe,
    this.appellation,
    this.profession,
    this.aiPersonality,
    this.responseStyle,
    this.customPrompt,
  });

  factory MPUpdateMemoAIRequest.fromJson(Map<String, dynamic> json) => _$MPUpdateMemoAIRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPUpdateMemoAIRequestToJson(this);
}

// Update Memo Request
@JsonSerializable()
class MPUpdateMemoRequest {
  @JsonKey(name: 'memo_id')
  final String memoId;

  @JsonKey(name: 'content')
  final String content;

  MPUpdateMemoRequest({
    required this.memoId,
    required this.content,
  });

  factory MPUpdateMemoRequest.fromJson(Map<String, dynamic> json) => _$MPUpdateMemoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPUpdateMemoRequestToJson(this);
}

// ========== Response Classes ==========

// Get Memo List Response
@JsonSerializable()
class MPGetMemoListResponse {
  @JsonKey(name: 'memos')
  final List<MPMemoStruct> memos;

  @JsonKey(name: 'has_more')
  final bool hasMore;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetMemoListResponse({
    required this.memos,
    required this.hasMore,
    required this.baseResp,
  });

  factory MPGetMemoListResponse.fromJson(Map<String, dynamic> json) => _$MPGetMemoListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetMemoListResponseToJson(this);
}

// Get Memo Detail Response
@JsonSerializable()
class MPGetMemoDetailResponse {
  @JsonKey(name: 'memo')
  final MPMemoStruct memo;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetMemoDetailResponse({
    required this.memo,
    required this.baseResp,
  });

  factory MPGetMemoDetailResponse.fromJson(Map<String, dynamic> json) => _$MPGetMemoDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetMemoDetailResponseToJson(this);
}

// Create Memo With Record Response
@JsonSerializable()
class MPCreateMemoWithRecordResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPCreateMemoWithRecordResponse({
    required this.baseResp,
  });

  factory MPCreateMemoWithRecordResponse.fromJson(Map<String, dynamic> json) =>
      _$MPCreateMemoWithRecordResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateMemoWithRecordResponseToJson(this);
}

// Create Memo With Text Response
@JsonSerializable()
class MPCreateMemoWithTextResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPCreateMemoWithTextResponse({
    required this.baseResp,
  });

  factory MPCreateMemoWithTextResponse.fromJson(Map<String, dynamic> json) =>
      _$MPCreateMemoWithTextResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateMemoWithTextResponseToJson(this);
}

// Delete Memo Response
@JsonSerializable()
class MPDeleteMemoResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPDeleteMemoResponse({
    required this.baseResp,
  });

  factory MPDeleteMemoResponse.fromJson(Map<String, dynamic> json) => _$MPDeleteMemoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPDeleteMemoResponseToJson(this);
}

// Update Memo AI Response
@JsonSerializable()
class MPUpdateMemoAIResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPUpdateMemoAIResponse({
    required this.baseResp,
  });

  factory MPUpdateMemoAIResponse.fromJson(Map<String, dynamic> json) => _$MPUpdateMemoAIResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPUpdateMemoAIResponseToJson(this);
}

// Update Memo Response
@JsonSerializable()
class MPUpdateMemoResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPUpdateMemoResponse({
    required this.baseResp,
  });

  factory MPUpdateMemoResponse.fromJson(Map<String, dynamic> json) => _$MPUpdateMemoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPUpdateMemoResponseToJson(this);
}
