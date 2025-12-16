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

MPCreateExpertRequest _$MPCreateExpertRequestFromJson(
        Map<String, dynamic> json) =>
    MPCreateExpertRequest(
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      about: json['about'] as String,
      capabilities: (json['capabilities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      type: json['type'] as String,
      chatPrompt: json['chat_prompt'] as String?,
      feedbackPrompt: json['feedback_prompt'] as String?,
      feedbackCronAt: json['feedback_cron_at'] as String?,
      autoSend: json['auto_send'] as bool?,
    );

Map<String, dynamic> _$MPCreateExpertRequestToJson(
        MPCreateExpertRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'avatar': instance.avatar,
      'about': instance.about,
      'capabilities': instance.capabilities,
      'type': instance.type,
      'chat_prompt': instance.chatPrompt,
      'feedback_prompt': instance.feedbackPrompt,
      'feedback_cron_at': instance.feedbackCronAt,
      'auto_send': instance.autoSend,
    };

MPGetExpertListResponse _$MPGetExpertListResponseFromJson(
        Map<String, dynamic> json) =>
    MPGetExpertListResponse(
      experts: (json['experts'] as List<dynamic>)
          .map((e) =>
              MPExpertMergeUserStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['has_more'] as bool,
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetExpertListResponseToJson(
        MPGetExpertListResponse instance) =>
    <String, dynamic>{
      'experts': instance.experts,
      'has_more': instance.hasMore,
      'base_resp': instance.baseResp,
    };

MPGetExpertDetailResponse _$MPGetExpertDetailResponseFromJson(
        Map<String, dynamic> json) =>
    MPGetExpertDetailResponse(
      expert: MPExpertMergeUserStruct.fromJson(
          json['expert'] as Map<String, dynamic>),
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetExpertDetailResponseToJson(
        MPGetExpertDetailResponse instance) =>
    <String, dynamic>{
      'expert': instance.expert,
      'base_resp': instance.baseResp,
    };

MPCreateExpertResponse _$MPCreateExpertResponseFromJson(
        Map<String, dynamic> json) =>
    MPCreateExpertResponse(
      expertId: json['expert_id'] as String?,
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPCreateExpertResponseToJson(
        MPCreateExpertResponse instance) =>
    <String, dynamic>{
      'expert_id': instance.expertId,
      'base_resp': instance.baseResp,
    };
