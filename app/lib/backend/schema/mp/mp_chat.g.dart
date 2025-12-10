// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mp_chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MPChatRequest _$MPChatRequestFromJson(Map<String, dynamic> json) =>
    MPChatRequest(
      expertId: json['expert_id'] as String,
      memoryId: json['memory_id'] as String,
      templateId: json['template_id'] as String,
      speakerId: json['speaker_id'] as String,
    );

Map<String, dynamic> _$MPChatRequestToJson(MPChatRequest instance) =>
    <String, dynamic>{
      'expert_id': instance.expertId,
      'memory_id': instance.memoryId,
      'template_id': instance.templateId,
      'speaker_id': instance.speakerId,
    };

MPChatResponse _$MPChatResponseFromJson(Map<String, dynamic> json) =>
    MPChatResponse(
      baseResp: json['base_resp'] == null
          ? null
          : MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPChatResponseToJson(MPChatResponse instance) =>
    <String, dynamic>{
      'base_resp': instance.baseResp,
    };
