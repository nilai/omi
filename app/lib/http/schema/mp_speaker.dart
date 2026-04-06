import 'package:json_annotation/json_annotation.dart';

import 'mp_data_model.dart';

part 'mp_speaker.g.dart';

// Add Speaker Request
@JsonSerializable()
class MPAddSpeakerRequest {
  @JsonKey(name: 'audio_url')
  final String audioUrl;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'avatar')
  final String avatar; // 可以为空

  @JsonKey(name: 'myself_voice')
  final bool? myselfVoice;

  @JsonKey(name: 'duration')
  final int? duration; // 单位是秒

  MPAddSpeakerRequest({
    required this.audioUrl,
    required this.name,
    required this.avatar,
    this.myselfVoice,
    this.duration,
  });

  factory MPAddSpeakerRequest.fromJson(Map<String, dynamic> json) => _$MPAddSpeakerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPAddSpeakerRequestToJson(this);
}

// Update Speaker Request
@JsonSerializable()
class MPUpdateSpeakerRequest {
  @JsonKey(name: 'speaker_id')
  final String speakerId;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'avatar')
  final String? avatar;

  MPUpdateSpeakerRequest({
    required this.speakerId,
    this.name,
    this.avatar,
  });

  factory MPUpdateSpeakerRequest.fromJson(Map<String, dynamic> json) => _$MPUpdateSpeakerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPUpdateSpeakerRequestToJson(this);
}

@JsonSerializable()
class MPDeleteSpeakerRequest {
  @JsonKey(name: 'speaker_id')
  final String speakerId;

  MPDeleteSpeakerRequest({
    required this.speakerId,
  });

  factory MPDeleteSpeakerRequest.fromJson(Map<String, dynamic> json) => _$MPDeleteSpeakerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPDeleteSpeakerRequestToJson(this);
}

// Add Speaker Response
@JsonSerializable()
class MPAddSpeakerResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPAddSpeakerResponse({
    required this.baseResp,
  });

  factory MPAddSpeakerResponse.fromJson(Map<String, dynamic> json) => _$MPAddSpeakerResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPAddSpeakerResponseToJson(this);
}

// Update Speaker Response
@JsonSerializable()
class MPUpdateSpeakerResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPUpdateSpeakerResponse({
    required this.baseResp,
  });

  factory MPUpdateSpeakerResponse.fromJson(Map<String, dynamic> json) => _$MPUpdateSpeakerResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPUpdateSpeakerResponseToJson(this);
}

// Delete Speaker Response
@JsonSerializable()
class MPDeleteSpeakerResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPDeleteSpeakerResponse({
    required this.baseResp,
  });

  factory MPDeleteSpeakerResponse.fromJson(Map<String, dynamic> json) => _$MPDeleteSpeakerResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPDeleteSpeakerResponseToJson(this);
}