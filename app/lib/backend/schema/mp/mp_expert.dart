import 'package:json_annotation/json_annotation.dart';

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

