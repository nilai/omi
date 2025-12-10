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

  factory MPGetExpertListRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetExpertListRequestFromJson(json);

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

  factory MPGetExpertDetailRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetExpertDetailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetExpertDetailRequestToJson(this);
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

  factory MPGetExpertListResponse.fromJson(Map<String, dynamic> json) =>
      _$MPGetExpertListResponseFromJson(json);

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

  factory MPGetExpertDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$MPGetExpertDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetExpertDetailResponseToJson(this);
}

