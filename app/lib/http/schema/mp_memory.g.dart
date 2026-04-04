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

MPGetMemoryV2DetailRequest _$MPGetMemoryV2DetailRequestFromJson(
  Map<String, dynamic> json,
) => MPGetMemoryV2DetailRequest(memoryId: json['memory_id'] as String);

Map<String, dynamic> _$MPGetMemoryV2DetailRequestToJson(
  MPGetMemoryV2DetailRequest instance,
) => <String, dynamic>{'memory_id': instance.memoryId};

MPGetMemoryV2DetailResponse _$MPGetMemoryV2DetailResponseFromJson(
  Map<String, dynamic> json,
) => MPGetMemoryV2DetailResponse(
  memoryDetail: MPMemoryStruct.fromJson(
    json['memory_detail'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$MPGetMemoryV2DetailResponseToJson(
  MPGetMemoryV2DetailResponse instance,
) => <String, dynamic>{'memory_detail': instance.memoryDetail};

MPGetMemoryFeedRequest _$MPGetMemoryFeedRequestFromJson(
  Map<String, dynamic> json,
) => MPGetMemoryFeedRequest(
  memoryId: json['memory_id'] as String,
  pageSize: (json['page_size'] as num?)?.toInt(),
  cursor: json['cursor'] as String,
);

Map<String, dynamic> _$MPGetMemoryFeedRequestToJson(
  MPGetMemoryFeedRequest instance,
) => <String, dynamic>{
  'memory_id': instance.memoryId,
  'page_size': instance.pageSize,
  'cursor': instance.cursor,
};

MPGetMemoryFeedResponse _$MPGetMemoryFeedResponseFromJson(
  Map<String, dynamic> json,
) => MPGetMemoryFeedResponse(
  feeds: (json['feeds'] as List<dynamic>?)
      ?.map((e) => MPFeedCardStruct.fromJson(e as Map<String, dynamic>))
      .toList(),
  hasMore: json['has_more'] as bool?,
);

Map<String, dynamic> _$MPGetMemoryFeedResponseToJson(
  MPGetMemoryFeedResponse instance,
) => <String, dynamic>{'feeds': instance.feeds, 'has_more': instance.hasMore};
