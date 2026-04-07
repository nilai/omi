// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mp_chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MPChatRequest _$MPChatRequestFromJson(Map<String, dynamic> json) =>
    MPChatRequest(
      message: json['message'] as String,
      conversationId: json['conversation_id'] as String,
    );

Map<String, dynamic> _$MPChatRequestToJson(MPChatRequest instance) =>
    <String, dynamic>{
      'message': instance.message,
      'conversation_id': instance.conversationId,
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
