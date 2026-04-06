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
      myselfVoice: json['myself_voice'] as bool?,
      duration: (json['duration'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MPAddSpeakerRequestToJson(
  MPAddSpeakerRequest instance,
) => <String, dynamic>{
  'audio_url': instance.audioUrl,
  'name': instance.name,
  'avatar': instance.avatar,
  'myself_voice': instance.myselfVoice,
  'duration': instance.duration,
};

MPUpdateSpeakerRequest _$MPUpdateSpeakerRequestFromJson(
  Map<String, dynamic> json,
) => MPUpdateSpeakerRequest(
  speakerId: json['speaker_id'] as String,
  name: json['name'] as String?,
  avatar: json['avatar'] as String?,
);

Map<String, dynamic> _$MPUpdateSpeakerRequestToJson(
  MPUpdateSpeakerRequest instance,
) => <String, dynamic>{
  'speaker_id': instance.speakerId,
  'name': instance.name,
  'avatar': instance.avatar,
};

MPDeleteSpeakerRequest _$MPDeleteSpeakerRequestFromJson(
  Map<String, dynamic> json,
) => MPDeleteSpeakerRequest(speakerId: json['speaker_id'] as String);

Map<String, dynamic> _$MPDeleteSpeakerRequestToJson(
  MPDeleteSpeakerRequest instance,
) => <String, dynamic>{'speaker_id': instance.speakerId};

MPAddSpeakerResponse _$MPAddSpeakerResponseFromJson(
  Map<String, dynamic> json,
) => MPAddSpeakerResponse(
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPAddSpeakerResponseToJson(
  MPAddSpeakerResponse instance,
) => <String, dynamic>{'base_resp': instance.baseResp};

MPUpdateSpeakerResponse _$MPUpdateSpeakerResponseFromJson(
  Map<String, dynamic> json,
) => MPUpdateSpeakerResponse(
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPUpdateSpeakerResponseToJson(
  MPUpdateSpeakerResponse instance,
) => <String, dynamic>{'base_resp': instance.baseResp};

MPDeleteSpeakerResponse _$MPDeleteSpeakerResponseFromJson(
  Map<String, dynamic> json,
) => MPDeleteSpeakerResponse(
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPDeleteSpeakerResponseToJson(
  MPDeleteSpeakerResponse instance,
) => <String, dynamic>{'base_resp': instance.baseResp};
