import 'package:json_annotation/json_annotation.dart';

part 'mp_chat.g.dart';

// Chat Request
@JsonSerializable()
class MPChatRequest {
  @JsonKey(name: 'expert_id')
  final String expertId; // 专家模型ID, 不用的话，为空字符串

  @JsonKey(name: 'memory_id')
  final String memoryId; // 对应的记忆id，不用的话，为空字符串。针对记忆总结的场景

  @JsonKey(name: 'template_id')
  final String templateId; // 对应的模板id，不用的话，为空字符串

  @JsonKey(name: 'speaker_id')
  final String speakerId; // 对应人物的id，没有的话，为空字符串。针对AI分析助手的场景

  MPChatRequest({
    required this.expertId,
    required this.memoryId,
    required this.templateId,
    required this.speakerId,
  });

  factory MPChatRequest.fromJson(Map<String, dynamic> json) =>
      _$MPChatRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPChatRequestToJson(this);
}

