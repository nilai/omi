// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mp_memory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MPGetMemoryListRequest _$MPGetMemoryListRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetMemoryListRequest(
      pageSize: (json['page_size'] as num).toInt(),
      cursor: json['cursor'] as String,
      date: json['date'] as String,
    );

Map<String, dynamic> _$MPGetMemoryListRequestToJson(
        MPGetMemoryListRequest instance) =>
    <String, dynamic>{
      'page_size': instance.pageSize,
      'cursor': instance.cursor,
      'date': instance.date,
    };

MPGetMemoryDaysRequest _$MPGetMemoryDaysRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetMemoryDaysRequest(
      month: json['month'] as String,
    );

Map<String, dynamic> _$MPGetMemoryDaysRequestToJson(
        MPGetMemoryDaysRequest instance) =>
    <String, dynamic>{
      'month': instance.month,
    };

MPGetMemoryDetailRequest _$MPGetMemoryDetailRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetMemoryDetailRequest(
      memoryId: json['memory_id'] as String,
    );

Map<String, dynamic> _$MPGetMemoryDetailRequestToJson(
        MPGetMemoryDetailRequest instance) =>
    <String, dynamic>{
      'memory_id': instance.memoryId,
    };

MPGetInsightListRequest _$MPGetInsightListRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetInsightListRequest(
      pageSize: (json['page_size'] as num).toInt(),
      cursor: json['cursor'] as String,
    );

Map<String, dynamic> _$MPGetInsightListRequestToJson(
        MPGetInsightListRequest instance) =>
    <String, dynamic>{
      'page_size': instance.pageSize,
      'cursor': instance.cursor,
    };

MPCreateRecordRequest _$MPCreateRecordRequestFromJson(
        Map<String, dynamic> json) =>
    MPCreateRecordRequest(
      recordFile: json['record_file'] as String,
      createAt: (json['create_at'] as num).toInt(),
      duration: (json['duration'] as num).toInt(),
    );

Map<String, dynamic> _$MPCreateRecordRequestToJson(
        MPCreateRecordRequest instance) =>
    <String, dynamic>{
      'record_file': instance.recordFile,
      'create_at': instance.createAt,
      'duration': instance.duration,
    };

MPGetUploadRecordUrlRequest _$MPGetUploadRecordUrlRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetUploadRecordUrlRequest(
      contentType: json['content_type'] as String,
    );

Map<String, dynamic> _$MPGetUploadRecordUrlRequestToJson(
        MPGetUploadRecordUrlRequest instance) =>
    <String, dynamic>{
      'content_type': instance.contentType,
    };

MPSummaryRecordRequest _$MPSummaryRecordRequestFromJson(
        Map<String, dynamic> json) =>
    MPSummaryRecordRequest(
      memoryId: json['memory_id'] as String,
      recordUrl: json['record_url'] as String,
      recordMemoAt: (json['record_memo_at'] as num).toInt(),
      templateId: json['template_id'] as String?,
    );

Map<String, dynamic> _$MPSummaryRecordRequestToJson(
        MPSummaryRecordRequest instance) =>
    <String, dynamic>{
      'memory_id': instance.memoryId,
      'record_url': instance.recordUrl,
      'record_memo_at': instance.recordMemoAt,
      'template_id': instance.templateId,
    };

MPShareMemoryRequest _$MPShareMemoryRequestFromJson(
        Map<String, dynamic> json) =>
    MPShareMemoryRequest(
      memoryId: json['memory_id'] as String,
    );

Map<String, dynamic> _$MPShareMemoryRequestToJson(
        MPShareMemoryRequest instance) =>
    <String, dynamic>{
      'memory_id': instance.memoryId,
    };

MPDeleteMemoryRequest _$MPDeleteMemoryRequestFromJson(
        Map<String, dynamic> json) =>
    MPDeleteMemoryRequest(
      memoryId: json['memory_id'] as String,
    );

Map<String, dynamic> _$MPDeleteMemoryRequestToJson(
        MPDeleteMemoryRequest instance) =>
    <String, dynamic>{
      'memory_id': instance.memoryId,
    };

MPGetSummaryStatusRequest _$MPGetSummaryStatusRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetSummaryStatusRequest(
      memoryId: json['memory_id'] as String,
    );

Map<String, dynamic> _$MPGetSummaryStatusRequestToJson(
        MPGetSummaryStatusRequest instance) =>
    <String, dynamic>{
      'memory_id': instance.memoryId,
    };

MPSearchMemoryRequest _$MPSearchMemoryRequestFromJson(
        Map<String, dynamic> json) =>
    MPSearchMemoryRequest(
      searchContent: json['search_content'] as String,
    );

Map<String, dynamic> _$MPSearchMemoryRequestToJson(
        MPSearchMemoryRequest instance) =>
    <String, dynamic>{
      'search_content': instance.searchContent,
    };

MPGetSummaryListRequest _$MPGetSummaryListRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetSummaryListRequest(
      pageSize: (json['page_size'] as num).toInt(),
      cursor: json['cursor'] as String,
    );

Map<String, dynamic> _$MPGetSummaryListRequestToJson(
        MPGetSummaryListRequest instance) =>
    <String, dynamic>{
      'page_size': instance.pageSize,
      'cursor': instance.cursor,
    };

MPAppendMemoryRequest _$MPAppendMemoryRequestFromJson(
        Map<String, dynamic> json) =>
    MPAppendMemoryRequest(
      memoryIds: (json['memory_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$MPAppendMemoryRequestToJson(
        MPAppendMemoryRequest instance) =>
    <String, dynamic>{
      'memory_ids': instance.memoryIds,
    };

MPGetMemoryListResponse _$MPGetMemoryListResponseFromJson(
        Map<String, dynamic> json) =>
    MPGetMemoryListResponse(
      memorys: (json['memorys'] as List<dynamic>)
          .map((e) => MPMemoryStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['has_more'] as bool,
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
      memoryTotal: (json['memory_total'] as num).toInt(),
    );

Map<String, dynamic> _$MPGetMemoryListResponseToJson(
        MPGetMemoryListResponse instance) =>
    <String, dynamic>{
      'memorys': instance.memorys,
      'has_more': instance.hasMore,
      'base_resp': instance.baseResp,
      'memory_total': instance.memoryTotal,
    };

MPGetMemoryDaysResponse _$MPGetMemoryDaysResponseFromJson(
        Map<String, dynamic> json) =>
    MPGetMemoryDaysResponse(
      days: (json['days'] as List<dynamic>).map((e) => e as String).toList(),
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetMemoryDaysResponseToJson(
        MPGetMemoryDaysResponse instance) =>
    <String, dynamic>{
      'days': instance.days,
      'base_resp': instance.baseResp,
    };

MPGetMemoryDetailResponse _$MPGetMemoryDetailResponseFromJson(
        Map<String, dynamic> json) =>
    MPGetMemoryDetailResponse(
      memory: MPMemoryStruct.fromJson(json['memory'] as Map<String, dynamic>),
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetMemoryDetailResponseToJson(
        MPGetMemoryDetailResponse instance) =>
    <String, dynamic>{
      'memory': instance.memory,
      'base_resp': instance.baseResp,
    };

MPGetInsightListResponse _$MPGetInsightListResponseFromJson(
        Map<String, dynamic> json) =>
    MPGetInsightListResponse(
      memorys: (json['memorys'] as List<dynamic>?)
              ?.map((e) => MPMemoryStruct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      hasMore: json['has_more'] as bool,
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetInsightListResponseToJson(
        MPGetInsightListResponse instance) =>
    <String, dynamic>{
      'memorys': instance.memorys,
      'has_more': instance.hasMore,
      'base_resp': instance.baseResp,
    };

MPCreateRecordResponse _$MPCreateRecordResponseFromJson(
        Map<String, dynamic> json) =>
    MPCreateRecordResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
      memoryId: json['memory_id'] as String,
      recordUrl: json['record_url'] as String,
    );

Map<String, dynamic> _$MPCreateRecordResponseToJson(
        MPCreateRecordResponse instance) =>
    <String, dynamic>{
      'memory_id': instance.memoryId,
      'record_url': instance.recordUrl,
      'base_resp': instance.baseResp,
    };

MPGetUploadRecordUrlResponse _$MPGetUploadRecordUrlResponseFromJson(
        Map<String, dynamic> json) =>
    MPGetUploadRecordUrlResponse(
      uploadUrl: json['upload_url'] as String,
      uri: json['uri'] as String,
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetUploadRecordUrlResponseToJson(
        MPGetUploadRecordUrlResponse instance) =>
    <String, dynamic>{
      'upload_url': instance.uploadUrl,
      'uri': instance.uri,
      'base_resp': instance.baseResp,
    };

MPSummaryRecordResponse _$MPSummaryRecordResponseFromJson(
        Map<String, dynamic> json) =>
    MPSummaryRecordResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPSummaryRecordResponseToJson(
        MPSummaryRecordResponse instance) =>
    <String, dynamic>{
      'base_resp': instance.baseResp,
    };

MPShareMemoryResponse _$MPShareMemoryResponseFromJson(
        Map<String, dynamic> json) =>
    MPShareMemoryResponse(
      id: json['id'] as String,
      shareCode: json['share_code'] as String,
      shareUrl: json['share_url'] as String,
      shortUrl: json['short_url'] as String,
      expiresAt: (json['expires_at'] as num).toInt(),
      createAt: (json['create_at'] as num).toInt(),
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPShareMemoryResponseToJson(
        MPShareMemoryResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'share_code': instance.shareCode,
      'share_url': instance.shareUrl,
      'short_url': instance.shortUrl,
      'expires_at': instance.expiresAt,
      'create_at': instance.createAt,
      'base_resp': instance.baseResp,
    };

MPUpdateMemoryNameRequest _$MPUpdateMemoryNameRequestFromJson(
        Map<String, dynamic> json) =>
    MPUpdateMemoryNameRequest(
      memoryId: json['memory_id'] as String,
      title: json['title'] as String,
    );

Map<String, dynamic> _$MPUpdateMemoryNameRequestToJson(
        MPUpdateMemoryNameRequest instance) =>
    <String, dynamic>{
      'memory_id': instance.memoryId,
      'title': instance.title,
    };

MPRenameMemoryRequest _$MPRenameMemoryRequestFromJson(
        Map<String, dynamic> json) =>
    MPRenameMemoryRequest(
      memoryId: json['memory_id'] as String,
      title: json['title'] as String,
    );

Map<String, dynamic> _$MPRenameMemoryRequestToJson(
        MPRenameMemoryRequest instance) =>
    <String, dynamic>{
      'memory_id': instance.memoryId,
      'title': instance.title,
    };

MPMemoryAddTagRequest _$MPMemoryAddTagRequestFromJson(
        Map<String, dynamic> json) =>
    MPMemoryAddTagRequest(
      memoryId: json['memory_id'] as String,
      label: json['label'] as String,
    );

Map<String, dynamic> _$MPMemoryAddTagRequestToJson(
        MPMemoryAddTagRequest instance) =>
    <String, dynamic>{
      'memory_id': instance.memoryId,
      'label': instance.label,
    };

MPDeleteMemoryResponse _$MPDeleteMemoryResponseFromJson(
        Map<String, dynamic> json) =>
    MPDeleteMemoryResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPDeleteMemoryResponseToJson(
        MPDeleteMemoryResponse instance) =>
    <String, dynamic>{
      'base_resp': instance.baseResp,
    };

MPUpdateMemoryNameResponse _$MPUpdateMemoryNameResponseFromJson(
        Map<String, dynamic> json) =>
    MPUpdateMemoryNameResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPUpdateMemoryNameResponseToJson(
        MPUpdateMemoryNameResponse instance) =>
    <String, dynamic>{
      'base_resp': instance.baseResp,
    };

MPRenameMemoryResponse _$MPRenameMemoryResponseFromJson(
        Map<String, dynamic> json) =>
    MPRenameMemoryResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPRenameMemoryResponseToJson(
        MPRenameMemoryResponse instance) =>
    <String, dynamic>{
      'base_resp': instance.baseResp,
    };

MPMemoryAddTagResponse _$MPMemoryAddTagResponseFromJson(
        Map<String, dynamic> json) =>
    MPMemoryAddTagResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPMemoryAddTagResponseToJson(
        MPMemoryAddTagResponse instance) =>
    <String, dynamic>{
      'base_resp': instance.baseResp,
    };

MPGetPopularSearchKeywordsResponse _$MPGetPopularSearchKeywordsResponseFromJson(
        Map<String, dynamic> json) =>
    MPGetPopularSearchKeywordsResponse(
      keywords:
          (json['keywords'] as List<dynamic>).map((e) => e as String).toList(),
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetPopularSearchKeywordsResponseToJson(
        MPGetPopularSearchKeywordsResponse instance) =>
    <String, dynamic>{
      'keywords': instance.keywords,
      'base_resp': instance.baseResp,
    };

MPGetSummaryStatusResponse _$MPGetSummaryStatusResponseFromJson(
        Map<String, dynamic> json) =>
    MPGetSummaryStatusResponse(
      status: (json['status'] as num).toInt(),
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetSummaryStatusResponseToJson(
        MPGetSummaryStatusResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'base_resp': instance.baseResp,
    };

MPSearchMemoryResponse _$MPSearchMemoryResponseFromJson(
        Map<String, dynamic> json) =>
    MPSearchMemoryResponse(
      memorys: (json['memorys'] as List<dynamic>)
          .map((e) => MPMemoryStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPSearchMemoryResponseToJson(
        MPSearchMemoryResponse instance) =>
    <String, dynamic>{
      'memorys': instance.memorys,
      'base_resp': instance.baseResp,
    };

MPGetSummaryListResponse _$MPGetSummaryListResponseFromJson(
        Map<String, dynamic> json) =>
    MPGetSummaryListResponse(
      summarys: (json['summarys'] as List<dynamic>)
          .map((e) => MPMemoryStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['has_more'] as bool,
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetSummaryListResponseToJson(
        MPGetSummaryListResponse instance) =>
    <String, dynamic>{
      'summarys': instance.summarys,
      'has_more': instance.hasMore,
      'base_resp': instance.baseResp,
    };

MPAppendMemoryResponse _$MPAppendMemoryResponseFromJson(
        Map<String, dynamic> json) =>
    MPAppendMemoryResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPAppendMemoryResponseToJson(
        MPAppendMemoryResponse instance) =>
    <String, dynamic>{
      'base_resp': instance.baseResp,
    };
