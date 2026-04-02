// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mp_memory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MPGetMemoryV2ListRequest _$MPGetMemoryV2ListRequestFromJson(
  Map<String, dynamic> json,
) => MPGetMemoryV2ListRequest(
  pageSize: (json['page_size'] as num).toInt(),
  cursor: json['cursor'] as String,
  day: json['day'] as String?,
);

Map<String, dynamic> _$MPGetMemoryV2ListRequestToJson(
  MPGetMemoryV2ListRequest instance,
) => <String, dynamic>{
  'page_size': instance.pageSize,
  'cursor': instance.cursor,
  'day': instance.day,
};

MPGetMemoryListResponse _$MPGetMemoryListResponseFromJson(
  Map<String, dynamic> json,
) => MPGetMemoryListResponse(
  memorys: (json['memorys'] as List<dynamic>)
      .map((e) => MPMemoryStruct.fromJson(e as Map<String, dynamic>))
      .toList(),
  hasMore: json['has_more'] as bool,
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
  memoryTotal: (json['memory_total'] as num).toInt(),
);

Map<String, dynamic> _$MPGetMemoryListResponseToJson(
  MPGetMemoryListResponse instance,
) => <String, dynamic>{
  'memorys': instance.memorys,
  'has_more': instance.hasMore,
  'base_resp': instance.baseResp,
  'memory_total': instance.memoryTotal,
};
