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

MPGetMemoryV2UnreadCountRequest _$MPGetMemoryV2UnreadCountRequestFromJson(
  Map<String, dynamic> json,
) => MPGetMemoryV2UnreadCountRequest(
  memberIds: (json['member_ids'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$MPGetMemoryV2UnreadCountRequestToJson(
  MPGetMemoryV2UnreadCountRequest instance,
) => <String, dynamic>{'member_ids': instance.memberIds};

MPGetTodayFocusCandidatesRequest _$MPGetTodayFocusCandidatesRequestFromJson(
  Map<String, dynamic> json,
) => MPGetTodayFocusCandidatesRequest();

Map<String, dynamic> _$MPGetTodayFocusCandidatesRequestToJson(
  MPGetTodayFocusCandidatesRequest instance,
) => <String, dynamic>{};

MPGetMemoryV2UnreadCountResponse _$MPGetMemoryV2UnreadCountResponseFromJson(
  Map<String, dynamic> json,
) => MPGetMemoryV2UnreadCountResponse(
  unreadCounts: Map<String, int>.from(json['unread_counts'] as Map),
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPGetMemoryV2UnreadCountResponseToJson(
  MPGetMemoryV2UnreadCountResponse instance,
) => <String, dynamic>{
  'unread_counts': instance.unreadCounts,
  'base_resp': instance.baseResp,
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

MPShareMemoryRequest _$MPShareMemoryRequestFromJson(
  Map<String, dynamic> json,
) => MPShareMemoryRequest(memoryId: json['memory_id'] as String);

Map<String, dynamic> _$MPShareMemoryRequestToJson(
  MPShareMemoryRequest instance,
) => <String, dynamic>{'memory_id': instance.memoryId};

MPShareMemoryWithOptionsRequest _$MPShareMemoryWithOptionsRequestFromJson(
  Map<String, dynamic> json,
) => MPShareMemoryWithOptionsRequest(
  memoryId: json['memory_id'] as String,
  optionIds: (json['option_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$MPShareMemoryWithOptionsRequestToJson(
  MPShareMemoryWithOptionsRequest instance,
) => <String, dynamic>{
  'memory_id': instance.memoryId,
  'option_ids': instance.optionIds,
};

MPShareMemoryV2Request _$MPShareMemoryV2RequestFromJson(
  Map<String, dynamic> json,
) => MPShareMemoryV2Request(
  memoryId: json['memory_id'] as String,
  optionIds: (json['option_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$MPShareMemoryV2RequestToJson(
  MPShareMemoryV2Request instance,
) => <String, dynamic>{
  'memory_id': instance.memoryId,
  'option_ids': instance.optionIds,
};

MPGetShareOptionsRequest _$MPGetShareOptionsRequestFromJson(
  Map<String, dynamic> json,
) => MPGetShareOptionsRequest(memoryId: json['memory_id'] as String);

Map<String, dynamic> _$MPGetShareOptionsRequestToJson(
  MPGetShareOptionsRequest instance,
) => <String, dynamic>{'memory_id': instance.memoryId};

MPShareMemoryResponse _$MPShareMemoryResponseFromJson(
  Map<String, dynamic> json,
) => MPShareMemoryResponse(
  id: json['id'] as String,
  shareCode: json['share_code'] as String,
  shareUrl: json['share_url'] as String,
  shortUrl: json['short_url'] as String,
  expiresAt: mpIntFromJson(json['expires_at']),
  createAt: mpIntFromJson(json['create_at']),
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPShareMemoryResponseToJson(
  MPShareMemoryResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'share_code': instance.shareCode,
  'share_url': instance.shareUrl,
  'short_url': instance.shortUrl,
  'expires_at': instance.expiresAt,
  'create_at': instance.createAt,
  'base_resp': instance.baseResp,
};

MPShareMemoryV2Response _$MPShareMemoryV2ResponseFromJson(
  Map<String, dynamic> json,
) => MPShareMemoryV2Response(
  id: json['id'] as String,
  shareCode: json['share_code'] as String,
  shareUrl: json['share_url'] as String,
  shortUrl: json['short_url'] as String,
  expiresAt: mpIntFromJson(json['expires_at']),
  createAt: mpIntFromJson(json['create_at']),
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPShareMemoryV2ResponseToJson(
  MPShareMemoryV2Response instance,
) => <String, dynamic>{
  'id': instance.id,
  'share_code': instance.shareCode,
  'share_url': instance.shareUrl,
  'short_url': instance.shortUrl,
  'expires_at': instance.expiresAt,
  'create_at': instance.createAt,
  'base_resp': instance.baseResp,
};

MPShareOptionItem _$MPShareOptionItemFromJson(Map<String, dynamic> json) =>
    MPShareOptionItem(
      optionId: mpIntFromJson(json['option_id']),
      optionKey: json['option_key'] as String,
      optionName: json['option_name'] as String,
      required: json['required'] as bool,
    );

Map<String, dynamic> _$MPShareOptionItemToJson(MPShareOptionItem instance) =>
    <String, dynamic>{
      'option_id': instance.optionId,
      'option_key': instance.optionKey,
      'option_name': instance.optionName,
      'required': instance.required,
    };

MPGetShareOptionsResponse _$MPGetShareOptionsResponseFromJson(
  Map<String, dynamic> json,
) => MPGetShareOptionsResponse(
  memoryId: json['memory_id'] as String,
  options:
      (json['options'] as List<dynamic>?)
          ?.map((e) => MPShareOptionItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPGetShareOptionsResponseToJson(
  MPGetShareOptionsResponse instance,
) => <String, dynamic>{
  'memory_id': instance.memoryId,
  'options': instance.options.map((e) => e.toJson()).toList(),
  'base_resp': instance.baseResp.toJson(),
};

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
  summaryId: json['summary_id'] as String?,
);

Map<String, dynamic> _$MPSummaryRecordResponseToJson(
  MPSummaryRecordResponse instance,
) => <String, dynamic>{
  'summary_id': instance.summaryId,
  'base_resp': instance.baseResp,
};

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

MPGetSummaryStatusRequest _$MPGetSummaryStatusRequestFromJson(
  Map<String, dynamic> json,
) => MPGetSummaryStatusRequest(
  summaryMemoryId: json['summary_memory_id'] as String,
);

Map<String, dynamic> _$MPGetSummaryStatusRequestToJson(
  MPGetSummaryStatusRequest instance,
) => <String, dynamic>{'summary_memory_id': instance.summaryMemoryId};

MPGetSummaryStatusResponse _$MPGetSummaryStatusResponseFromJson(
  Map<String, dynamic> json,
) => MPGetSummaryStatusResponse(
  status: (json['status'] as num).toInt(),
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPGetSummaryStatusResponseToJson(
  MPGetSummaryStatusResponse instance,
) => <String, dynamic>{
  'status': instance.status,
  'base_resp': instance.baseResp,
};

MPGetMemorySummaryStatusRequest _$MPGetMemorySummaryStatusRequestFromJson(
  Map<String, dynamic> json,
) => MPGetMemorySummaryStatusRequest(memoryId: json['memory_id'] as String);

Map<String, dynamic> _$MPGetMemorySummaryStatusRequestToJson(
  MPGetMemorySummaryStatusRequest instance,
) => <String, dynamic>{'memory_id': instance.memoryId};

Map<String, dynamic> _$MPGetMemorySummaryStatusResponseToJson(
  MPGetMemorySummaryStatusResponse instance,
) => <String, dynamic>{
  'resummary_memories': instance.resummaryMemoriesStatus,
  'base_resp': instance.baseResp,
};

MPMemorySummaryStatusItem _$MPMemorySummaryStatusItemFromJson(
  Map<String, dynamic> json,
) => MPMemorySummaryStatusItem(
  summaryMemoryId: json['resummary_memory_id'] as String,
  summaryStatus: (json['resummary_status'] as num).toInt(),
);

Map<String, dynamic> _$MPMemorySummaryStatusItemToJson(
  MPMemorySummaryStatusItem instance,
) => <String, dynamic>{
  'resummary_memory_id': instance.summaryMemoryId,
  'resummary_status': instance.summaryStatus,
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
