// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mp_expert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MPGetExpertListRequest _$MPGetExpertListRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetExpertListRequest(
      pageSize: (json['page_size'] as num).toInt(),
      cursor: json['cursor'] as String,
    );

Map<String, dynamic> _$MPGetExpertListRequestToJson(
        MPGetExpertListRequest instance) =>
    <String, dynamic>{
      'page_size': instance.pageSize,
      'cursor': instance.cursor,
    };

MPGetExpertDetailRequest _$MPGetExpertDetailRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetExpertDetailRequest(
      expertId: json['expert_id'] as String,
    );

Map<String, dynamic> _$MPGetExpertDetailRequestToJson(
        MPGetExpertDetailRequest instance) =>
    <String, dynamic>{
      'expert_id': instance.expertId,
    };
