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

MPDeleteMemoryRequest _$MPDeleteMemoryRequestFromJson(
  Map<String, dynamic> json,
) => MPDeleteMemoryRequest(memoryId: json['memory_id'] as String);

Map<String, dynamic> _$MPDeleteMemoryRequestToJson(
  MPDeleteMemoryRequest instance,
) => <String, dynamic>{'memory_id': instance.memoryId};

MPDeleteMemoryResponse _$MPDeleteMemoryResponseFromJson(
  Map<String, dynamic> json,
) => MPDeleteMemoryResponse(
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPDeleteMemoryResponseToJson(
  MPDeleteMemoryResponse instance,
) => <String, dynamic>{'base_resp': instance.baseResp};

MPRenameMemoryRequest _$MPRenameMemoryRequestFromJson(
  Map<String, dynamic> json,
) => MPRenameMemoryRequest(
  memoryId: json['memory_id'] as String,
  title: json['title'] as String,
);

Map<String, dynamic> _$MPRenameMemoryRequestToJson(
  MPRenameMemoryRequest instance,
) => <String, dynamic>{'memory_id': instance.memoryId, 'title': instance.title};

MPRenameMemoryResponse _$MPRenameMemoryResponseFromJson(
  Map<String, dynamic> json,
) => MPRenameMemoryResponse(
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPRenameMemoryResponseToJson(
  MPRenameMemoryResponse instance,
) => <String, dynamic>{'base_resp': instance.baseResp};

MPCreateRecordRequest _$MPCreateRecordRequestFromJson(
  Map<String, dynamic> json,
) => MPCreateRecordRequest(
  recordFile: json['record_file'] as String,
  createAt: (json['create_at'] as num).toInt(),
  duration: (json['duration'] as num).toInt(),
  source: json['source'] as String?,
);

Map<String, dynamic> _$MPCreateRecordRequestToJson(
  MPCreateRecordRequest instance,
) => <String, dynamic>{
  'record_file': instance.recordFile,
  'create_at': instance.createAt,
  'duration': instance.duration,
  'source': instance.source,
};

MPCreateRecordResponse _$MPCreateRecordResponseFromJson(
  Map<String, dynamic> json,
) => MPCreateRecordResponse(
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
  memoryId: json['memory_id'] as String,
  recordUrl: json['record_url'] as String,
);

Map<String, dynamic> _$MPCreateRecordResponseToJson(
  MPCreateRecordResponse instance,
) => <String, dynamic>{
  'memory_id': instance.memoryId,
  'record_url': instance.recordUrl,
  'base_resp': instance.baseResp,
};

MPSummaryRecordRequest _$MPSummaryRecordRequestFromJson(
  Map<String, dynamic> json,
) => MPSummaryRecordRequest(
  memoryId: json['memory_id'] as String,
  recordUrl: json['record_url'] as String,
  recordMemoAt: (json['record_memo_at'] as num).toInt(),
  templateId: json['template_id'] as String?,
  isRegen: json['is_regen'] as bool? ?? false,
);

Map<String, dynamic> _$MPSummaryRecordRequestToJson(
  MPSummaryRecordRequest instance,
) => <String, dynamic>{
  'memory_id': instance.memoryId,
  'record_url': instance.recordUrl,
  'record_memo_at': instance.recordMemoAt,
  'template_id': instance.templateId,
  'is_regen': instance.isRegen,
};

MPSummaryRecordResponse _$MPSummaryRecordResponseFromJson(
  Map<String, dynamic> json,
) => MPSummaryRecordResponse(
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPSummaryRecordResponseToJson(
  MPSummaryRecordResponse instance,
) => <String, dynamic>{'base_resp': instance.baseResp};

MPGetUploadRecordUrlRequest _$MPGetUploadRecordUrlRequestFromJson(
  Map<String, dynamic> json,
) => MPGetUploadRecordUrlRequest(contentType: json['content_type'] as String);

Map<String, dynamic> _$MPGetUploadRecordUrlRequestToJson(
  MPGetUploadRecordUrlRequest instance,
) => <String, dynamic>{'content_type': instance.contentType};

MPGetUploadRecordUrlResponse _$MPGetUploadRecordUrlResponseFromJson(
  Map<String, dynamic> json,
) => MPGetUploadRecordUrlResponse(
  uploadUrl: json['upload_url'] as String,
  uri: json['uri'] as String,
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPGetUploadRecordUrlResponseToJson(
  MPGetUploadRecordUrlResponse instance,
) => <String, dynamic>{
  'upload_url': instance.uploadUrl,
  'uri': instance.uri,
  'base_resp': instance.baseResp,
};

PresignedUrlResponse _$PresignedUrlResponseFromJson(
  Map<String, dynamic> json,
) => PresignedUrlResponse(
  uploadUrl: json['upload_url'] as String,
  uri: json['uri'] as String,
);

Map<String, dynamic> _$PresignedUrlResponseToJson(
  PresignedUrlResponse instance,
) => <String, dynamic>{'upload_url': instance.uploadUrl, 'uri': instance.uri};

AudioRecord _$AudioRecordFromJson(Map<String, dynamic> json) => AudioRecord(
  audioRecordId: json['audio_record_id'] as String,
  audioUri: json['audio_uri'] as String,
  recordTs: (json['record_ts'] as num).toInt(),
  statusCode: (json['status_code'] as num).toInt(),
  statusMessage: json['status_message'] as String,
);

Map<String, dynamic> _$AudioRecordToJson(AudioRecord instance) =>
    <String, dynamic>{
      'audio_record_id': instance.audioRecordId,
      'audio_uri': instance.audioUri,
      'record_ts': instance.recordTs,
      'status_code': instance.statusCode,
      'status_message': instance.statusMessage,
    };
