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

  MPAddSpeakerRequest({
    required this.audioUrl,
    required this.name,
    required this.avatar,
    this.myselfVoice,
  });

  factory MPAddSpeakerRequest.fromJson(Map<String, dynamic> json) => _$MPAddSpeakerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPAddSpeakerRequestToJson(this);
}

// Mark Speaker Request
@JsonSerializable()
class MPMarkSpeakerRequest {
  @JsonKey(name: 'memory_id')
  final String memoryId;

  @JsonKey(name: 'template_speaker_name')
  final String templateSpeakerName; // 在记忆的对话的临时名字

  @JsonKey(name: 'name')
  final String name; // 设置的名字

  @JsonKey(name: 'avatar')
  final String avatar; // 可以为空

  MPMarkSpeakerRequest({
    required this.memoryId,
    required this.templateSpeakerName,
    required this.name,
    required this.avatar,
  });

  factory MPMarkSpeakerRequest.fromJson(Map<String, dynamic> json) => _$MPMarkSpeakerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPMarkSpeakerRequestToJson(this);
}

// Get Speaker List Request
@JsonSerializable()
class MPGetSpeakerListRequest {
  @JsonKey(name: 'page_size')
  final int pageSize;

  @JsonKey(name: 'cursor')
  final String cursor;

  MPGetSpeakerListRequest({
    required this.pageSize,
    required this.cursor,
  });

  factory MPGetSpeakerListRequest.fromJson(Map<String, dynamic> json) => _$MPGetSpeakerListRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetSpeakerListRequestToJson(this);
}

// Get Speaker List With Detail Request
@JsonSerializable()
class MPGetSpeakerListWithDetailRequest {
  @JsonKey(name: 'page_size')
  final int pageSize;

  @JsonKey(name: 'cursor')
  final String cursor;

  MPGetSpeakerListWithDetailRequest({
    required this.pageSize,
    required this.cursor,
  });

  factory MPGetSpeakerListWithDetailRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetSpeakerListWithDetailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetSpeakerListWithDetailRequestToJson(this);
}

// Get Speaker Detail Request
@JsonSerializable()
class MPGetSpeakerDetailRequest {
  @JsonKey(name: 'speaker_id')
  final String speakerId;

  MPGetSpeakerDetailRequest({
    required this.speakerId,
  });

  factory MPGetSpeakerDetailRequest.fromJson(Map<String, dynamic> json) => _$MPGetSpeakerDetailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetSpeakerDetailRequestToJson(this);
}

// Delete Speaker Request
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

// ========== Response Classes ==========

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

// Mark Speaker Response
@JsonSerializable()
class MPMarkSpeakerResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPMarkSpeakerResponse({
    required this.baseResp,
  });

  factory MPMarkSpeakerResponse.fromJson(Map<String, dynamic> json) => _$MPMarkSpeakerResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPMarkSpeakerResponseToJson(this);
}

// Get Speaker List Response
@JsonSerializable()
class MPGetSpeakerListResponse {
  @JsonKey(name: 'speakers')
  final List<MPSpeakerStruct> speakers;

  @JsonKey(name: 'has_more')
  final bool hasMore;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetSpeakerListResponse({
    required this.speakers,
    required this.hasMore,
    required this.baseResp,
  });

  factory MPGetSpeakerListResponse.fromJson(Map<String, dynamic> json) => _$MPGetSpeakerListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetSpeakerListResponseToJson(this);
}

// Get Speaker List With Detail Response
@JsonSerializable()
class MPGetSpeakerListWithDetailResponse {
  @JsonKey(name: 'speakers')
  final List<MPSpeakerWithDetailStruct> speakers;

  @JsonKey(name: 'has_more')
  final bool hasMore;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetSpeakerListWithDetailResponse({
    required this.speakers,
    required this.hasMore,
    required this.baseResp,
  });

  factory MPGetSpeakerListWithDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$MPGetSpeakerListWithDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetSpeakerListWithDetailResponseToJson(this);
}

// Get Speaker Detail Response
@JsonSerializable()
class MPGetSpeakerDetailResponse {
  @JsonKey(name: 'speaker')
  final MPSpeakerStruct speaker;

  @JsonKey(name: 'memorys')
  final List<MPMemoryStruct> memorys;

  @JsonKey(name: 'memory_total')
  final int memoryTotal;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetSpeakerDetailResponse({
    required this.speaker,
    required this.memorys,
    required this.memoryTotal,
    required this.baseResp,
  });

  factory MPGetSpeakerDetailResponse.fromJson(Map<String, dynamic> json) => _$MPGetSpeakerDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetSpeakerDetailResponseToJson(this);
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
