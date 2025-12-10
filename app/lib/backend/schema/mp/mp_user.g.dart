// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mp_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MPGetUserProfileRequest _$MPGetUserProfileRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetUserProfileRequest();

Map<String, dynamic> _$MPGetUserProfileRequestToJson(
        MPGetUserProfileRequest instance) =>
    <String, dynamic>{};

MPGetUserProfileResponse _$MPGetUserProfileResponseFromJson(
        Map<String, dynamic> json) =>
    MPGetUserProfileResponse(
      user: MPUserStruct.fromJson(json['user'] as Map<String, dynamic>),
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetUserProfileResponseToJson(
        MPGetUserProfileResponse instance) =>
    <String, dynamic>{
      'user': instance.user,
      'base_resp': instance.baseResp,
    };
