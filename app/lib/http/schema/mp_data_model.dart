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

enum MPMemoryType {
  /// memory summary
  @JsonValue(1)
  summary,

  /// memory only audio
  @JsonValue(2)
  onlyRecord,

  /// memory detail
  @JsonValue(5)
  memoryFeed,

  /// 
  @JsonValue(6)
  memoList,
}

/// 与后端 `MemoType` 对齐：1 = HIGHLIGHT_MEMO，2 = MANUAL_MEMO。
enum MPMemoType {
  @JsonValue(1)
  highlightMemo,

  @JsonValue(2)
  manualMemo,
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

/// Todo `deadline`：兼容 JSON 为 int、[num] 或数字字符串（Unix 秒）。
int? mpTodoDeadlineFromJson(Object? json) {
  if (json == null) {
    return null;
  }
  if (json is int) {
    return json;
  }
  if (json is num) {
    return json.toInt();
  }
  if (json is String) {
    final String s = json.trim();
    if (s.isEmpty) {
      return null;
    }
    return int.tryParse(s);
  }
  return null;
}

Object? mpTodoDeadlineToJson(int? value) => value;

/// 兼容 JSON 为 int、num、数字字符串的整型解析（非空）。
int mpIntFromJson(Object? json, {int defaultValue = 0}) {
  if (json == null) {
    return defaultValue;
  }
  if (json is int) {
    return json;
  }
  if (json is num) {
    return json.toInt();
  }
  if (json is String) {
    final String s = json.trim();
    if (s.isEmpty) {
      return defaultValue;
    }
    return int.tryParse(s) ?? double.tryParse(s)?.toInt() ?? defaultValue;
  }
  return defaultValue;
}

/// 兼容 JSON 为 int、num、数字字符串的可空整型解析。
int? mpNullableIntFromJson(Object? json) {
  if (json == null) {
    return null;
  }
  if (json is int) {
    return json;
  }
  if (json is num) {
    return json.toInt();
  }
  if (json is String) {
    final String s = json.trim();
    if (s.isEmpty) {
      return null;
    }
    return int.tryParse(s) ?? double.tryParse(s)?.toInt();
  }
  return null;
}

/// `insight_id`：后端可能为 **字符串** 或 **整型**（统一为可空 [String]）。
String? mpInsightIdFromJson(Object? json) {
  if (json == null) {
    return null;
  }
  if (json is String) {
    final String t = json.trim();
    return t.isEmpty ? null : t;
  }
  if (json is int) {
    return '$json';
  }
  if (json is num) {
    return json.toInt().toString();
  }
  final String s = json.toString().trim();
  return s.isEmpty ? null : s;
}

// Todo Struct
@JsonSerializable(explicitToJson: true)
class MPTodoStruct {
  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'owner')
  final MPSpeakerStruct? owner;

  @JsonKey(name: 'priority')
  final String? priority;

  @JsonKey(
    name: 'deadline',
    fromJson: mpTodoDeadlineFromJson,
    toJson: mpTodoDeadlineToJson,
  )
  final int? deadline;

  //（1-进行中，0-已删除，2-已完成, 3-已超期）
  @JsonKey(name: 'status')
  final int? status;

  @JsonKey(name: 'reason')
  final String? reason;

  @JsonKey(name: 'pre_create_status')
  final int? preCreateStatus;

  @JsonKey(name: 'memory_id')
  final int? memoryId;

  @JsonKey(name: 'insight_id', fromJson: mpInsightIdFromJson)
  final String? insightId;

  @JsonKey(name: 'slot')
  final int? slot;
  MPTodoStruct({
    this.id,
    this.title,
    this.owner,
    this.priority,
    this.deadline,
    this.status,
    this.reason,
    this.preCreateStatus,
    this.memoryId,
    this.insightId,
    this.slot,
  });

  factory MPTodoStruct.fromJson(Map<String, dynamic> json) => _$MPTodoStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPTodoStructToJson(this);
}

// Record Conversation Struct（后端 `RecordConversationStruct`，transcript 条目）
@JsonSerializable(explicitToJson: true)
class MPRecordConversationStruct {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'speaker')
  final MPSpeakerStruct speaker;

  @JsonKey(name: 'content')
  final String content;

  @JsonKey(name: 'time', fromJson: mpNullableIntFromJson)
  final int? time;

  MPRecordConversationStruct({
    required this.id,
    required this.speaker,
    required this.content,
    required this.time,
  });

  factory MPRecordConversationStruct.fromJson(Map<String, dynamic> json) =>
      _$MPRecordConversationStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPRecordConversationStructToJson(this);
}

/// 兼容旧命名（与 [MPRecordConversationStruct] 相同）
typedef MPSummaryConversationStruct = MPRecordConversationStruct;

// Summary Memory Struct
@JsonSerializable(explicitToJson: true)
class MPSummaryMemoryStruct {

  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'content')
  final String? content;

  @JsonKey(name: 'create_at')
  final int? createAt;

  @JsonKey(name: 'duration')
  final int? duration;

  @JsonKey(name: 'participants')
  final List<MPSpeakerStruct>? participants;

  @JsonKey(name: 'participants_cnt')
  final int? participantsCnt;

  /// 录音地址
  @JsonKey(name: 'record_url')
  final String? recordUrl;

  /// 录音地址
  @JsonKey(name: 'record_uri')
  final String? recordUri;

  /// markdown 格式
  @JsonKey(name: 'summary')
  final String? summary;

  @JsonKey(name: 'transcript')
  final List<MPRecordConversationStruct>? transcript;

  @JsonKey(name: 'todos')
  final List<MPTodoStruct>? todos;

  @JsonKey(name: 'status')
  final int? status;

  @JsonKey(name: 'source')
  final String? source;

  MPSummaryMemoryStruct({
    this.title,
    this.content,
    this.createAt,
    this.duration,
    this.participants,
    this.participantsCnt,
    this.recordUrl,
    this.recordUri,
    this.summary,
    this.transcript,
    this.todos,
    this.status,
    this.source,
  });

  factory MPSummaryMemoryStruct.fromJson(Map<String, dynamic> json) => _$MPSummaryMemoryStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPSummaryMemoryStructToJson(this);
}

// Only Record Memory Struct
@JsonSerializable()
class MPOnlyRecordMemoryStruct {
  @JsonKey(name: 'record_file')
  final String? recordFile;

  @JsonKey(name: 'record_uri')
  final String? recordUri;

  @JsonKey(name: 'source')
  final String? source;

  MPOnlyRecordMemoryStruct({
    this.recordFile,
    this.recordUri,
    this.source,
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
@JsonSerializable(explicitToJson: true)
class MPMemoryStruct {
  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'create_at', fromJson: mpIntFromJson)
  final int createAt;

  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'sub_title')
  final String? subTitle;

  @JsonKey(name: 'type')
  final MPMemoryType? type;

  @JsonKey(name: 'content')
  final String? content;

  @JsonKey(name: 'duration', fromJson: mpNullableIntFromJson)
  final int? duration;

  // 仅 MEMORY_FEED 类型有意义
  @JsonKey(name: 'unread_item_cnt', fromJson: mpNullableIntFromJson)
  final int? unreadItemCnt;

  /// 后端约定：当 type 为 MEMO_LIST 时，这里可能为空，需要从 `memo_list` 拼装展示内容
  @JsonKey(name: 'memo_list')
  final List<MPMemoStruct>? memoList;

  @JsonKey(name: 'source')
  final String? source;
  
  @JsonKey(name: 'memory_feed')
  final MPMemoryFeedStruct? memoryFeed;

  @JsonKey(name: 'summary_content')
  final MPSummaryMemoryStruct? summaryContent;
  
  @JsonKey(name: 'only_record_content')
  final MPOnlyRecordMemoryStruct? onlyRecordContent;


  MPMemoryStruct({
    required this.id,
    required this.createAt,
    required this.title,
    this.subTitle,
    required this.type,
    required this.content,
    this.duration,
    this.memoList,
    this.source,
    this.memoryFeed,
    this.summaryContent,
    this.onlyRecordContent,
    this.unreadItemCnt,
  });

  factory MPMemoryStruct.fromJson(Map<String, dynamic> json) => _$MPMemoryStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPMemoryStructToJson(this);
}

// Feed Card Struct（后端 `FeedCardStruct`，字段后续按需补全）
@JsonSerializable(explicitToJson: true)
class MPFeedCardStruct {
  @JsonKey(name: 'id')
  final String? id;

  /// 后端 FeedCardType（枚举值先用 int 接住，后续再补齐为强类型枚举）
  @JsonKey(name: 'type')
  final int? type;

  /// BUSINESS INSIGHT / EXECUTION INSIGHT / TODOS CREATED / MY MEMO
  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'create_at', fromJson: mpNullableIntFromJson)
  final int? createAt;

  @JsonKey(name: 'content')
  final String? content;

  /// 仅在 TODOS_CREATED 卡片返回
  @JsonKey(name: 'todos')
  final List<MPTodoStruct>? todos;

  /// 仅在 INSIGHT 卡片返回，表示该 insight 是否已添加过 todo
  @JsonKey(name: 'has_added_todo')
  final bool? hasAddedTodo;

   /// 仅在 MY_MEMO 卡片返回
  @JsonKey(name: 'memos')
  final List<MPMemoStruct>? memos;

  /// expert insight
  @JsonKey(name: 'suggestion')
  final String? suggestion;

  @JsonKey(name: 'ask_ai_card')
  final MPConversationContentStruct? askAICard;

  @JsonKey(name: 'resummary_status')
  final int? resummaryStatus;

  @JsonKey(name: 'template_name')
  final String? templateName;


  const MPFeedCardStruct({
    this.id,
    this.type,
    this.title,
    this.createAt,
    this.content,
    this.todos,
    this.hasAddedTodo,
    this.memos,
    this.suggestion,
    this.askAICard,
    this.resummaryStatus,
    this.templateName,
  });

  factory MPFeedCardStruct.fromJson(Map<String, dynamic> json) =>
      _$MPFeedCardStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPFeedCardStructToJson(this);
}

/// 与后端 `FeedCardStruct.type` 取值一致（若与接口文档不符请在此调整）。
abstract final class MPFeedCardType {
  MPFeedCardType._();

  static const int insight = 1;
  static const int todosCreated = 2;
  static const int myMemo = 3;
  static const int resummary = 4;
  static const int followUpList = 6;
  static const int youAsked = 7;
}

// Memory Feed Struct
@JsonSerializable(explicitToJson: true)
class MPMemoryFeedStruct {
  @JsonKey(name: 'summary_memory')
  final MPSummaryMemoryStruct? summaryMemory;

  @JsonKey(name: 'feeds', defaultValue: <MPFeedCardStruct>[])
  final List<MPFeedCardStruct> feeds;

  const MPMemoryFeedStruct({
    this.summaryMemory,
    required this.feeds,
  });

  factory MPMemoryFeedStruct.fromJson(Map<String, dynamic> json) =>
      _$MPMemoryFeedStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPMemoryFeedStructToJson(this);
}

// Memo Struct
@JsonSerializable(explicitToJson: true)
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

  @JsonKey(name: 'type')
  final MPMemoType? type;

  MPMemoStruct({
    required this.id,
    required this.title,
    required this.content,
    this.tags,
    this.createAt,
    this.relateMemoryId,
    this.type,
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

@JsonSerializable()
class MPConversationContentStruct {
  @JsonKey(name: 'ask')
  final String? ask;
  @JsonKey(name: 'answer')
  final String? answer;
  @JsonKey(name: 'count')
  final int? count;

  MPConversationContentStruct({
    this.ask,
    this.answer,
    this.count,
  });

  factory MPConversationContentStruct.fromJson(Map<String, dynamic> json) => _$MPConversationContentStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPConversationContentStructToJson(this);
}

// Template Struct
@JsonSerializable()
class MPTemplateStruct {
  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'sub_title')
  final String? subTitle;

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
    this.subTitle,
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
