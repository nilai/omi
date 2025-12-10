// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mp_speaker.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MPAddSpeakerRequest _$MPAddSpeakerRequestFromJson(Map<String, dynamic> json) =>
    MPAddSpeakerRequest(
      audioUrl: json['audio_url'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
    );

Map<String, dynamic> _$MPAddSpeakerRequestToJson(
        MPAddSpeakerRequest instance) =>
    <String, dynamic>{
      'audio_url': instance.audioUrl,
      'name': instance.name,
      'avatar': instance.avatar,
    };

MPMarkSpeakerRequest _$MPMarkSpeakerRequestFromJson(
        Map<String, dynamic> json) =>
    MPMarkSpeakerRequest(
      memoryId: json['memory_id'] as String,
      templateSpeakerName: json['template_speaker_name'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
    );

Map<String, dynamic> _$MPMarkSpeakerRequestToJson(
        MPMarkSpeakerRequest instance) =>
    <String, dynamic>{
      'memory_id': instance.memoryId,
      'template_speaker_name': instance.templateSpeakerName,
      'name': instance.name,
      'avatar': instance.avatar,
    };

MPGetSpeakerListRequest _$MPGetSpeakerListRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetSpeakerListRequest(
      pageSize: (json['page_size'] as num).toInt(),
      cursor: json['cursor'] as String,
    );

Map<String, dynamic> _$MPGetSpeakerListRequestToJson(
        MPGetSpeakerListRequest instance) =>
    <String, dynamic>{
      'page_size': instance.pageSize,
      'cursor': instance.cursor,
    };

MPGetSpeakerListWithDetailRequest _$MPGetSpeakerListWithDetailRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetSpeakerListWithDetailRequest(
      pageSize: (json['page_size'] as num).toInt(),
      cursor: json['cursor'] as String,
    );

Map<String, dynamic> _$MPGetSpeakerListWithDetailRequestToJson(
        MPGetSpeakerListWithDetailRequest instance) =>
    <String, dynamic>{
      'page_size': instance.pageSize,
      'cursor': instance.cursor,
    };

MPGetSpeakerDetailRequest _$MPGetSpeakerDetailRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetSpeakerDetailRequest(
      speakerId: json['speaker_id'] as String,
    );

Map<String, dynamic> _$MPGetSpeakerDetailRequestToJson(
        MPGetSpeakerDetailRequest instance) =>
    <String, dynamic>{
      'speaker_id': instance.speakerId,
    };
