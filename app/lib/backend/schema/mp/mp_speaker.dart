import 'package:json_annotation/json_annotation.dart';

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

  MPAddSpeakerRequest({
    required this.audioUrl,
    required this.name,
    required this.avatar,
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
