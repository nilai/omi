import 'package:json_annotation/json_annotation.dart';

import 'mp_data_model.dart';

part 'mp_expert.g.dart';

// Get Expert List Request
@JsonSerializable()
class MPGetExpertListRequest {
  @JsonKey(name: 'page_size')
  final int pageSize;

  @JsonKey(name: 'cursor')
  final String cursor;

  MPGetExpertListRequest({
    required this.pageSize,
    required this.cursor,
  });

  factory MPGetExpertListRequest.fromJson(Map<String, dynamic> json) => _$MPGetExpertListRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetExpertListRequestToJson(this);
}

// Get Expert Detail Request
@JsonSerializable()
class MPGetExpertDetailRequest {
  @JsonKey(name: 'expert_id')
  final String expertId;

  MPGetExpertDetailRequest({
    required this.expertId,
  });

  factory MPGetExpertDetailRequest.fromJson(Map<String, dynamic> json) => _$MPGetExpertDetailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetExpertDetailRequestToJson(this);
}

// Create Expert Request
@JsonSerializable()
class MPCreateExpertRequest {
  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'avatar')
  final String avatar;

  @JsonKey(name: 'about')
  final String about;

  @JsonKey(name: 'capabilities')
  final List<String> capabilities;

  @JsonKey(name: 'type')
  final String type;

  @JsonKey(name: 'chat_prompt')
  final String? chatPrompt;

  @JsonKey(name: 'feedback_prompt')
  final String? feedbackPrompt;

  @JsonKey(name: 'feedback_cron_at')
  final String? feedbackCronAt;

  @JsonKey(name: 'auto_send')
  final bool? autoSend;

  MPCreateExpertRequest({
    required this.name,
    required this.avatar,
    required this.about,
    required this.capabilities,
    required this.type,
    this.chatPrompt,
    this.feedbackPrompt,
    this.feedbackCronAt,
    this.autoSend,
  });

  factory MPCreateExpertRequest.fromJson(Map<String, dynamic> json) => _$MPCreateExpertRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateExpertRequestToJson(this);
}

// ========== Response Classes ==========

// Get Expert List Response
@JsonSerializable()
class MPGetExpertListResponse {
  @JsonKey(name: 'experts')
  final List<MPExpertMergeUserStruct> experts;

  @JsonKey(name: 'has_more')
  final bool hasMore;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetExpertListResponse({
    required this.experts,
    required this.hasMore,
    required this.baseResp,
  });

  factory MPGetExpertListResponse.fromJson(Map<String, dynamic> json) => _$MPGetExpertListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetExpertListResponseToJson(this);
}

// Get Expert Detail Response
@JsonSerializable()
class MPGetExpertDetailResponse {
  @JsonKey(name: 'expert')
  final MPExpertMergeUserStruct expert;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetExpertDetailResponse({
    required this.expert,
    required this.baseResp,
  });

  factory MPGetExpertDetailResponse.fromJson(Map<String, dynamic> json) => _$MPGetExpertDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetExpertDetailResponseToJson(this);
}

// Create Expert Response
@JsonSerializable()
class MPCreateExpertResponse {
  @JsonKey(name: 'expert_id')
  final String? expertId;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPCreateExpertResponse({
    this.expertId,
    required this.baseResp,
  });

  factory MPCreateExpertResponse.fromJson(Map<String, dynamic> json) => _$MPCreateExpertResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateExpertResponseToJson(this);
}
