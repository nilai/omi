// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mp_memo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MPGetMemoListRequest _$MPGetMemoListRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetMemoListRequest(
      pageSize: (json['page_size'] as num).toInt(),
      cursor: json['cursor'] as String,
    );

Map<String, dynamic> _$MPGetMemoListRequestToJson(
        MPGetMemoListRequest instance) =>
    <String, dynamic>{
      'page_size': instance.pageSize,
      'cursor': instance.cursor,
    };

MPGetMemoDetailRequest _$MPGetMemoDetailRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetMemoDetailRequest(
      memoId: json['memo_id'] as String,
    );

Map<String, dynamic> _$MPGetMemoDetailRequestToJson(
        MPGetMemoDetailRequest instance) =>
    <String, dynamic>{
      'memo_id': instance.memoId,
    };

MPCreateMemoWithRecordRequest _$MPCreateMemoWithRecordRequestFromJson(
        Map<String, dynamic> json) =>
    MPCreateMemoWithRecordRequest(
      recordUrl: json['record_url'] as String,
      createAt: (json['create_at'] as num).toInt(),
    );

Map<String, dynamic> _$MPCreateMemoWithRecordRequestToJson(
        MPCreateMemoWithRecordRequest instance) =>
    <String, dynamic>{
      'record_url': instance.recordUrl,
      'create_at': instance.createAt,
    };

MPCreateMemoWithTextRequest _$MPCreateMemoWithTextRequestFromJson(
        Map<String, dynamic> json) =>
    MPCreateMemoWithTextRequest(
      content: json['content'] as String,
      createAt: (json['create_at'] as num).toInt(),
    );

Map<String, dynamic> _$MPCreateMemoWithTextRequestToJson(
        MPCreateMemoWithTextRequest instance) =>
    <String, dynamic>{
      'content': instance.content,
      'create_at': instance.createAt,
    };

MPDeleteMemoRequest _$MPDeleteMemoRequestFromJson(Map<String, dynamic> json) =>
    MPDeleteMemoRequest(
      memoId: json['memo_id'] as String,
    );

Map<String, dynamic> _$MPDeleteMemoRequestToJson(
        MPDeleteMemoRequest instance) =>
    <String, dynamic>{
      'memo_id': instance.memoId,
    };
