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

MPUpdateMemoAIRequest _$MPUpdateMemoAIRequestFromJson(
        Map<String, dynamic> json) =>
    MPUpdateMemoAIRequest(
      rightNowTranscribe: json['right_now_transcribe'] as bool?,
      appellation: json['appellation'] as String?,
      profession: json['profession'] as String?,
      aiPersonality: json['ai_personality'] as String?,
      responseStyle: json['response_style'] as String?,
      customPrompt: json['custom_prompt'] as String?,
    );

Map<String, dynamic> _$MPUpdateMemoAIRequestToJson(
        MPUpdateMemoAIRequest instance) =>
    <String, dynamic>{
      'right_now_transcribe': instance.rightNowTranscribe,
      'appellation': instance.appellation,
      'profession': instance.profession,
      'ai_personality': instance.aiPersonality,
      'response_style': instance.responseStyle,
      'custom_prompt': instance.customPrompt,
    };

MPUpdateMemoRequest _$MPUpdateMemoRequestFromJson(Map<String, dynamic> json) =>
    MPUpdateMemoRequest(
      memoId: json['memo_id'] as String,
      content: json['content'] as String,
    );

Map<String, dynamic> _$MPUpdateMemoRequestToJson(
        MPUpdateMemoRequest instance) =>
    <String, dynamic>{
      'memo_id': instance.memoId,
      'content': instance.content,
    };

MPGetMemoListResponse _$MPGetMemoListResponseFromJson(
        Map<String, dynamic> json) =>
    MPGetMemoListResponse(
      memos: (json['memos'] as List<dynamic>)
          .map((e) => MPMemoStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['has_more'] as bool,
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetMemoListResponseToJson(
        MPGetMemoListResponse instance) =>
    <String, dynamic>{
      'memos': instance.memos,
      'has_more': instance.hasMore,
      'base_resp': instance.baseResp,
    };

MPGetMemoDetailResponse _$MPGetMemoDetailResponseFromJson(
        Map<String, dynamic> json) =>
    MPGetMemoDetailResponse(
      memo: MPMemoStruct.fromJson(json['memo'] as Map<String, dynamic>),
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetMemoDetailResponseToJson(
        MPGetMemoDetailResponse instance) =>
    <String, dynamic>{
      'memo': instance.memo,
      'base_resp': instance.baseResp,
    };

MPCreateMemoWithRecordResponse _$MPCreateMemoWithRecordResponseFromJson(
        Map<String, dynamic> json) =>
    MPCreateMemoWithRecordResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPCreateMemoWithRecordResponseToJson(
        MPCreateMemoWithRecordResponse instance) =>
    <String, dynamic>{
      'base_resp': instance.baseResp,
    };

MPCreateMemoWithTextResponse _$MPCreateMemoWithTextResponseFromJson(
        Map<String, dynamic> json) =>
    MPCreateMemoWithTextResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPCreateMemoWithTextResponseToJson(
        MPCreateMemoWithTextResponse instance) =>
    <String, dynamic>{
      'base_resp': instance.baseResp,
    };

MPDeleteMemoResponse _$MPDeleteMemoResponseFromJson(
        Map<String, dynamic> json) =>
    MPDeleteMemoResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPDeleteMemoResponseToJson(
        MPDeleteMemoResponse instance) =>
    <String, dynamic>{
      'base_resp': instance.baseResp,
    };

MPUpdateMemoAIResponse _$MPUpdateMemoAIResponseFromJson(
        Map<String, dynamic> json) =>
    MPUpdateMemoAIResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPUpdateMemoAIResponseToJson(
        MPUpdateMemoAIResponse instance) =>
    <String, dynamic>{
      'base_resp': instance.baseResp,
    };

MPUpdateMemoResponse _$MPUpdateMemoResponseFromJson(
        Map<String, dynamic> json) =>
    MPUpdateMemoResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPUpdateMemoResponseToJson(
        MPUpdateMemoResponse instance) =>
    <String, dynamic>{
      'base_resp': instance.baseResp,
    };
