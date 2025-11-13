// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presigned_url_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresignedUrlResponse _$PresignedUrlResponseFromJson(
        Map<String, dynamic> json) =>
    PresignedUrlResponse(
      uploadUrl: json['upload_url'] as String,
      uri: json['uri'] as String,
    );

Map<String, dynamic> _$PresignedUrlResponseToJson(
        PresignedUrlResponse instance) =>
    <String, dynamic>{
      'upload_url': instance.uploadUrl,
      'uri': instance.uri,
    };
