// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mp_speaker.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MPAddSpeakerRequest _$MPAddSpeakerRequestFromJson(Map<String, dynamic> json) => MPAddSpeakerRequest(
      audioUrl: json['audio_url'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      myselfVoice: json['myself_voice'] as bool?,
    );

Map<String, dynamic> _$MPAddSpeakerRequestToJson(MPAddSpeakerRequest instance) => <String, dynamic>{
      'audio_url': instance.audioUrl,
      'name': instance.name,
      'avatar': instance.avatar,
      'myself_voice': instance.myselfVoice,
    };

MPMarkSpeakerRequest _$MPMarkSpeakerRequestFromJson(Map<String, dynamic> json) => MPMarkSpeakerRequest(
      memoryId: json['memory_id'] as String,
      templateSpeakerName: json['template_speaker_name'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
    );

Map<String, dynamic> _$MPMarkSpeakerRequestToJson(MPMarkSpeakerRequest instance) => <String, dynamic>{
      'memory_id': instance.memoryId,
      'template_speaker_name': instance.templateSpeakerName,
      'name': instance.name,
      'avatar': instance.avatar,
    };

MPGetSpeakerListRequest _$MPGetSpeakerListRequestFromJson(Map<String, dynamic> json) => MPGetSpeakerListRequest(
      pageSize: (json['page_size'] as num).toInt(),
      cursor: json['cursor'] as String,
    );

Map<String, dynamic> _$MPGetSpeakerListRequestToJson(MPGetSpeakerListRequest instance) => <String, dynamic>{
      'page_size': instance.pageSize,
      'cursor': instance.cursor,
    };

MPGetSpeakerListWithDetailRequest _$MPGetSpeakerListWithDetailRequestFromJson(Map<String, dynamic> json) =>
    MPGetSpeakerListWithDetailRequest(
      pageSize: (json['page_size'] as num).toInt(),
      cursor: json['cursor'] as String,
    );

Map<String, dynamic> _$MPGetSpeakerListWithDetailRequestToJson(MPGetSpeakerListWithDetailRequest instance) =>
    <String, dynamic>{
      'page_size': instance.pageSize,
      'cursor': instance.cursor,
    };

MPGetSpeakerDetailRequest _$MPGetSpeakerDetailRequestFromJson(Map<String, dynamic> json) => MPGetSpeakerDetailRequest(
      speakerId: json['speaker_id'] as String,
    );

Map<String, dynamic> _$MPGetSpeakerDetailRequestToJson(MPGetSpeakerDetailRequest instance) => <String, dynamic>{
      'speaker_id': instance.speakerId,
    };

MPAddSpeakerResponse _$MPAddSpeakerResponseFromJson(Map<String, dynamic> json) => MPAddSpeakerResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPAddSpeakerResponseToJson(MPAddSpeakerResponse instance) => <String, dynamic>{
      'base_resp': instance.baseResp,
    };

MPMarkSpeakerResponse _$MPMarkSpeakerResponseFromJson(Map<String, dynamic> json) => MPMarkSpeakerResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPMarkSpeakerResponseToJson(MPMarkSpeakerResponse instance) => <String, dynamic>{
      'base_resp': instance.baseResp,
    };

MPGetSpeakerListResponse _$MPGetSpeakerListResponseFromJson(Map<String, dynamic> json) => MPGetSpeakerListResponse(
      speakers:
          (json['speakers'] as List<dynamic>).map((e) => MPSpeakerStruct.fromJson(e as Map<String, dynamic>)).toList(),
      hasMore: json['has_more'] as bool,
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetSpeakerListResponseToJson(MPGetSpeakerListResponse instance) => <String, dynamic>{
      'speakers': instance.speakers,
      'has_more': instance.hasMore,
      'base_resp': instance.baseResp,
    };

MPGetSpeakerListWithDetailResponse _$MPGetSpeakerListWithDetailResponseFromJson(Map<String, dynamic> json) =>
    MPGetSpeakerListWithDetailResponse(
      speakers: (json['speakers'] as List<dynamic>)
          .map((e) => MPSpeakerWithDetailStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['has_more'] as bool,
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetSpeakerListWithDetailResponseToJson(MPGetSpeakerListWithDetailResponse instance) =>
    <String, dynamic>{
      'speakers': instance.speakers,
      'has_more': instance.hasMore,
      'base_resp': instance.baseResp,
    };

MPGetSpeakerDetailResponse _$MPGetSpeakerDetailResponseFromJson(Map<String, dynamic> json) =>
    MPGetSpeakerDetailResponse(
      speaker: MPSpeakerStruct.fromJson(json['speaker'] as Map<String, dynamic>),
      memorys:
          (json['memorys'] as List<dynamic>).map((e) => MPMemoryStruct.fromJson(e as Map<String, dynamic>)).toList(),
      memoryTotal: (json['memory_total'] as num).toInt(),
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetSpeakerDetailResponseToJson(MPGetSpeakerDetailResponse instance) => <String, dynamic>{
      'speaker': instance.speaker,
      'memorys': instance.memorys,
      'memory_total': instance.memoryTotal,
      'base_resp': instance.baseResp,
    };
