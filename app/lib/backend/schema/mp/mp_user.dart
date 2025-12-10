import 'package:json_annotation/json_annotation.dart';

part 'mp_user.g.dart';

// Get User Profile Request
@JsonSerializable()
class MPGetUserProfileRequest {
  MPGetUserProfileRequest();

  factory MPGetUserProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetUserProfileRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetUserProfileRequestToJson(this);
}

