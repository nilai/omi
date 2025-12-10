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
    );

Map<String, dynamic> _$MPGetMemoryListRequestToJson(
        MPGetMemoryListRequest instance) =>
    <String, dynamic>{
      'page_size': instance.pageSize,
      'cursor': instance.cursor,
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
    );

Map<String, dynamic> _$MPSummaryRecordRequestToJson(
        MPSummaryRecordRequest instance) =>
    <String, dynamic>{
      'memory_id': instance.memoryId,
      'record_url': instance.recordUrl,
      'record_memo_at': instance.recordMemoAt,
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
