import 'package:json_annotation/json_annotation.dart';

part 'mp_data_model.g.dart';

// Base Response
@JsonSerializable()
class MPBaseResp {
  @JsonKey(name: 'code')
  final int code;

  @JsonKey(name: 'message')
  final String message;

  @JsonKey(name: 'logid')
  final String logid;

  MPBaseResp({
    required this.code,
    required this.message,
    required this.logid,
  });

  factory MPBaseResp.fromJson(Map<String, dynamic> json) => _$MPBaseRespFromJson(json);

  Map<String, dynamic> toJson() => _$MPBaseRespToJson(this);
}

// MemoryType Enum
enum MPMemoryType {
  @JsonValue(1)
  summary,

  @JsonValue(2)
  onlyRecord,

  @JsonValue(3)
  insight,

  @JsonValue(4)
  aiExpert,
}

// Speaker Struct
@JsonSerializable()
class MPSpeakerStruct {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'avatar')
  final String avatar;

  @JsonKey(name: 'is_temporary')
  final bool isTemporary;

  @JsonKey(name: 'myself_voice')
  final bool? myselfVoice;

  @JsonKey(name: 'audio_url')
  final String? audioUrl;

  @JsonKey(name: 'created_at')
  final int? createdAt;

  @JsonKey(name: 'duration')
  final int? duration;

  MPSpeakerStruct({
    required this.id,
    required this.name,
    required this.avatar,
    required this.isTemporary,
    this.myselfVoice,
    this.audioUrl,
    this.createdAt,
    this.duration,
  });

  factory MPSpeakerStruct.fromJson(Map<String, dynamic> json) => _$MPSpeakerStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPSpeakerStructToJson(this);
}

// Todo Struct
@JsonSerializable()
class MPTodoStruct {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'owner')
  final MPSpeakerStruct owner;

  @JsonKey(name: 'priority')
  final String priority;

  @JsonKey(name: 'deadline')
  final String deadline;

  @JsonKey(name: 'status')
  final int? status;

  MPTodoStruct({
    required this.id,
    required this.title,
    required this.owner,
    required this.priority,
    required this.deadline,
    this.status,
  });

  factory MPTodoStruct.fromJson(Map<String, dynamic> json) => _$MPTodoStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPTodoStructToJson(this);
}

// Summary Conversation Struct
@JsonSerializable()
class MPSummaryConversationStruct {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'speaker')
  final MPSpeakerStruct speaker;

  @JsonKey(name: 'content')
  final String content;

  @JsonKey(name: 'time')
  final String time;

  MPSummaryConversationStruct({
    required this.id,
    required this.speaker,
    required this.content,
    required this.time,
  });

  factory MPSummaryConversationStruct.fromJson(Map<String, dynamic> json) =>
      _$MPSummaryConversationStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPSummaryConversationStructToJson(this);
}

// Summary Memory Struct
@JsonSerializable()
class MPSummaryMemoryStruct {
  @JsonKey(name: 'participants')
  final List<MPSpeakerStruct> participants;

  @JsonKey(name: 'participants_cnt')
  final int participants_cnt;

  @JsonKey(name: 'record_url')
  final String recordUrl;

  @JsonKey(name: 'summary')
  final String summary;

  @JsonKey(name: 'transcript')
  final List<MPSummaryConversationStruct> transcript;

  @JsonKey(name: 'todos')
  final List<MPTodoStruct> todos;

  MPSummaryMemoryStruct({
    required this.participants,
    required this.recordUrl,
    required this.summary,
    required this.transcript,
    required this.todos,
    required this.participants_cnt,
  });

  factory MPSummaryMemoryStruct.fromJson(Map<String, dynamic> json) => _$MPSummaryMemoryStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPSummaryMemoryStructToJson(this);
}

// Only Record Memory Struct
@JsonSerializable()
class MPOnlyRecordMemoryStruct {
  @JsonKey(name: 'record_file')
  final String recordFile;

  MPOnlyRecordMemoryStruct({
    required this.recordFile,
  });

  factory MPOnlyRecordMemoryStruct.fromJson(Map<String, dynamic> json) => _$MPOnlyRecordMemoryStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPOnlyRecordMemoryStructToJson(this);
}

// Insight Memory Struct
@JsonSerializable()
class MPInsightMemoryStruct {
  @JsonKey(name: 'content')
  final String content;

  MPInsightMemoryStruct({
    required this.content,
  });

  factory MPInsightMemoryStruct.fromJson(Map<String, dynamic> json) => _$MPInsightMemoryStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPInsightMemoryStructToJson(this);
}

// AI Expert Memory Struct
@JsonSerializable()
class MPAiExpertMemoryStruct {
  @JsonKey(name: 'content')
  final String content;

  MPAiExpertMemoryStruct({
    required this.content,
  });

  factory MPAiExpertMemoryStruct.fromJson(Map<String, dynamic> json) => _$MPAiExpertMemoryStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPAiExpertMemoryStructToJson(this);
}

// Memory Struct
@JsonSerializable()
class MPMemoryStruct {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'create_at')
  final int createAt;

  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'type')
  final MPMemoryType type;

  @JsonKey(name: 'label')
  final String label;

  @JsonKey(name: 'label_color')
  final String? labelColor;

  @JsonKey(name: 'content')
  final String content;

  @JsonKey(name: 'duration')
  final int duration;

  @JsonKey(name: 'summary_content')
  final MPSummaryMemoryStruct? summaryContent;

  @JsonKey(name: 'only_record_content')
  final MPOnlyRecordMemoryStruct? onlyRecordContent;

  @JsonKey(name: 'insight_content')
  final MPInsightMemoryStruct? insightContent;

  @JsonKey(name: 'ai_expert_content')
  final MPAiExpertMemoryStruct? aiExpertContent;

  @JsonKey(name: 'custom_labels')
  final List<String>? customLabels;

  MPMemoryStruct({
    required this.id,
    required this.createAt,
    required this.title,
    required this.type,
    required this.label,
    this.labelColor,
    required this.content,
    required this.duration,
    this.summaryContent,
    this.onlyRecordContent,
    this.insightContent,
    this.aiExpertContent,
    this.customLabels,
  });

  factory MPMemoryStruct.fromJson(Map<String, dynamic> json) => _$MPMemoryStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPMemoryStructToJson(this);
}

// Memo Struct
@JsonSerializable()
class MPMemoStruct {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'content')
  final String content;

  @JsonKey(name: 'tags')
  final List<String>? tags;

  @JsonKey(name: 'create_at')
  final int? createAt;

  @JsonKey(name: 'relate_memory_id')
  final int? relateMemoryId;

  MPMemoStruct({
    required this.id,
    required this.title,
    required this.content,
    this.tags,
    this.createAt,
    this.relateMemoryId,
  });

  factory MPMemoStruct.fromJson(Map<String, dynamic> json) => _$MPMemoStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPMemoStructToJson(this);
}

// Expert Struct
@JsonSerializable()
class MPExpertStruct {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'avatar')
  final String? avatar;

  @JsonKey(name: 'label')
  final String? label;

  @JsonKey(name: 'about')
  final String? about;

  @JsonKey(name: 'capabilities')
  final List<String>? capabilities;

  @JsonKey(name: 'chat_prompt')
  final String? chatPrompt;

  @JsonKey(name: 'feed_prompt')
  final String? feedPrompt;

  @JsonKey(name: 'feedback_cron_at')
  final String? feedbackCronAt;

  MPExpertStruct({
    required this.id,
    required this.name,
    this.avatar,
    this.label,
    this.about,
    this.capabilities,
    this.chatPrompt,
    this.feedPrompt,
    this.feedbackCronAt,
  });

  factory MPExpertStruct.fromJson(Map<String, dynamic> json) => _$MPExpertStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPExpertStructToJson(this);
}

// Template Struct
@JsonSerializable()
class MPTemplateStruct {
  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'icon')
  final String? icon;

  @JsonKey(name: 'type')
  final String? type;

  @JsonKey(name: 'prompt')
  final String? prompt;

  MPTemplateStruct({
    this.id,
    this.title,
    this.icon,
    this.type,
    this.prompt,
  });

  factory MPTemplateStruct.fromJson(Map<String, dynamic> json) => _$MPTemplateStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPTemplateStructToJson(this);
}

// User AI Settings
@JsonSerializable()
class MPUserAISettings {
  @JsonKey(name: 'appellation')
  final String appellation;

  @JsonKey(name: 'profession')
  final String profession;

  @JsonKey(name: 'ai_personality')
  final String aiPersonality;

  @JsonKey(name: 'response_style')
  final String responseStyle;

  @JsonKey(name: 'custom_prompt')
  final String customPrompt;

  MPUserAISettings({
    required this.appellation,
    required this.profession,
    required this.aiPersonality,
    required this.responseStyle,
    required this.customPrompt,
  });

  factory MPUserAISettings.fromJson(Map<String, dynamic> json) => _$MPUserAISettingsFromJson(json);

  Map<String, dynamic> toJson() => _$MPUserAISettingsToJson(this);
}

// User Struct
@JsonSerializable()
class MPUserStruct {
  @JsonKey(name: 'user_name')
  final String userName;

  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'avatar')
  final String avatar;

  @JsonKey(name: 'phone')
  final String phone;

  @JsonKey(name: 'brithday')
  final String birthday;

  @JsonKey(name: 'ai_settings')
  final MPUserAISettings aiSettings;

  @JsonKey(name: 'right_now_transcribe')
  final bool? rightNowTranscribe;

  MPUserStruct({
    required this.userName,
    required this.email,
    required this.avatar,
    required this.phone,
    required this.birthday,
    required this.aiSettings,
    this.rightNowTranscribe,
  });

  factory MPUserStruct.fromJson(Map<String, dynamic> json) => _$MPUserStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPUserStructToJson(this);
}

// Speaker With Detail Struct
@JsonSerializable()
class MPSpeakerWithDetailStruct {
  @JsonKey(name: 'speaker')
  final MPSpeakerStruct speaker;

  @JsonKey(name: 'summary')
  final String summary;

  @JsonKey(name: 'last_memory_at')
  final int last_memory_at;

  @JsonKey(name: 'memory_total')
  final int memory_total;

  MPSpeakerWithDetailStruct({
    required this.speaker,
    required this.summary,
    required this.last_memory_at,
    required this.memory_total,
  });

  factory MPSpeakerWithDetailStruct.fromJson(Map<String, dynamic> json) => _$MPSpeakerWithDetailStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPSpeakerWithDetailStructToJson(this);
}

// Expert Merge User Struct
@JsonSerializable()
class MPExpertMergeUserStruct {
  @JsonKey(name: 'expert')
  final MPExpertStruct expert;

  @JsonKey(name: 'is_add')
  final bool isAdd;

  MPExpertMergeUserStruct({
    required this.expert,
    required this.isAdd,
  });

  factory MPExpertMergeUserStruct.fromJson(Map<String, dynamic> json) => _$MPExpertMergeUserStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPExpertMergeUserStructToJson(this);
}
