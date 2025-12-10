import 'package:json_annotation/json_annotation.dart';
import 'mp_data_model.dart';

part 'mp_user.g.dart';

// Get User Profile Request
@JsonSerializable()
class MPGetUserProfileRequest {
  MPGetUserProfileRequest();

  factory MPGetUserProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetUserProfileRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetUserProfileRequestToJson(this);
}

// ========== Response Classes ==========

// Get User Profile Response
@JsonSerializable()
class MPGetUserProfileResponse {
  @JsonKey(name: 'user')
  final MPUserStruct user;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetUserProfileResponse({
    required this.user,
    required this.baseResp,
  });

  factory MPGetUserProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$MPGetUserProfileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetUserProfileResponseToJson(this);
}

