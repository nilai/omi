// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mp_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MPBaseResp _$MPBaseRespFromJson(Map<String, dynamic> json) => MPBaseResp(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String,
  logid: json['logid'] as String,
);

Map<String, dynamic> _$MPBaseRespToJson(MPBaseResp instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'logid': instance.logid,
    };

MPSpeakerStruct _$MPSpeakerStructFromJson(Map<String, dynamic> json) =>
    MPSpeakerStruct(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      isTemporary: json['is_temporary'] as bool,
      myselfVoice: json['myself_voice'] as bool?,
      audioUrl: json['audio_url'] as String?,
      createdAt: (json['created_at'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MPSpeakerStructToJson(MPSpeakerStruct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatar': instance.avatar,
      'is_temporary': instance.isTemporary,
      'myself_voice': instance.myselfVoice,
      'audio_url': instance.audioUrl,
      'created_at': instance.createdAt,
      'duration': instance.duration,
    };

MPTodoStruct _$MPTodoStructFromJson(Map<String, dynamic> json) => MPTodoStruct(
  id: json['id'] as String?,
  title: json['title'] as String?,
  owner: json['owner'] == null
      ? null
      : MPSpeakerStruct.fromJson(json['owner'] as Map<String, dynamic>),
  priority: json['priority'] as String?,
  deadline: mpTodoDeadlineFromJson(json['deadline']),
  status: (json['status'] as num?)?.toInt(),
);

Map<String, dynamic> _$MPTodoStructToJson(MPTodoStruct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'owner': instance.owner,
      'priority': instance.priority,
      'deadline': mpTodoDeadlineToJson(instance.deadline),
      'status': instance.status,
    };

MPRecordConversationStruct _$MPRecordConversationStructFromJson(
  Map<String, dynamic> json,
) => MPRecordConversationStruct(
  id: json['id'] as String,
  speaker: MPSpeakerStruct.fromJson(json['speaker'] as Map<String, dynamic>),
  content: json['content'] as String,
  time: mpNullableIntFromJson(json['time']),
);

Map<String, dynamic> _$MPRecordConversationStructToJson(
  MPRecordConversationStruct instance,
) => <String, dynamic>{
  'id': instance.id,
  'speaker': instance.speaker,
  'content': instance.content,
  'time': instance.time,
};

MPSummaryMemoryStruct _$MPSummaryMemoryStructFromJson(
  Map<String, dynamic> json,
) => MPSummaryMemoryStruct(
  title: json['title'] as String?,
  content: json['content'] as String?,
  createAt: (json['create_at'] as num?)?.toInt(),
  duration: (json['duration'] as num?)?.toInt(),
  participants: (json['participants'] as List<dynamic>?)
      ?.map((e) => MPSpeakerStruct.fromJson(e as Map<String, dynamic>))
      .toList(),
  participantsCnt: (json['participants_cnt'] as num?)?.toInt(),
  recordUrl: json['record_url'] as String?,
  recordUri: json['record_uri'] as String?,
  summary: json['summary'] as String?,
  transcript: (json['transcript'] as List<dynamic>?)
      ?.map(
        (e) => MPRecordConversationStruct.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  todos: (json['todos'] as List<dynamic>?)
      ?.map((e) => MPTodoStruct.fromJson(e as Map<String, dynamic>))
      .toList(),
  status: (json['status'] as num?)?.toInt(),
  source: json['source'] as String?,
);

Map<String, dynamic> _$MPSummaryMemoryStructToJson(
  MPSummaryMemoryStruct instance,
) => <String, dynamic>{
  'title': instance.title,
  'content': instance.content,
  'create_at': instance.createAt,
  'duration': instance.duration,
  'participants': instance.participants?.map((e) => e.toJson()).toList(),
  'participants_cnt': instance.participantsCnt,
  'record_url': instance.recordUrl,
  'record_uri': instance.recordUri,
  'summary': instance.summary,
  'transcript': instance.transcript?.map((e) => e.toJson()).toList(),
  'todos': instance.todos?.map((e) => e.toJson()).toList(),
  'status': instance.status,
  'source': instance.source,
};

MPOnlyRecordMemoryStruct _$MPOnlyRecordMemoryStructFromJson(
  Map<String, dynamic> json,
) => MPOnlyRecordMemoryStruct(
  recordFile: json['record_file'] as String?,
  recordUri: json['record_uri'] as String?,
  source: json['source'] as String?,
);

Map<String, dynamic> _$MPOnlyRecordMemoryStructToJson(
  MPOnlyRecordMemoryStruct instance,
) => <String, dynamic>{
  'record_file': instance.recordFile,
  'record_uri': instance.recordUri,
  'source': instance.source,
};

MPInsightMemoryStruct _$MPInsightMemoryStructFromJson(
  Map<String, dynamic> json,
) => MPInsightMemoryStruct(content: json['content'] as String);

Map<String, dynamic> _$MPInsightMemoryStructToJson(
  MPInsightMemoryStruct instance,
) => <String, dynamic>{'content': instance.content};

MPAiExpertMemoryStruct _$MPAiExpertMemoryStructFromJson(
  Map<String, dynamic> json,
) => MPAiExpertMemoryStruct(content: json['content'] as String);

Map<String, dynamic> _$MPAiExpertMemoryStructToJson(
  MPAiExpertMemoryStruct instance,
) => <String, dynamic>{'content': instance.content};

MPMemoryStruct _$MPMemoryStructFromJson(Map<String, dynamic> json) =>
    MPMemoryStruct(
      id: json['id'] as String?,
      createAt: mpIntFromJson(json['create_at']),
      title: json['title'] as String?,
      subTitle: json['sub_title'] as String?,
      type: $enumDecodeNullable(_$MPMemoryTypeEnumMap, json['type']),
      content: json['content'] as String?,
      duration: mpNullableIntFromJson(json['duration']),
      memoList: (json['memo_list'] as List<dynamic>?)
          ?.map((e) => MPMemoStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
      source: json['source'] as String?,
      memoryFeed: json['memory_feed'] == null
          ? null
          : MPMemoryFeedStruct.fromJson(
              json['memory_feed'] as Map<String, dynamic>,
            ),
      summaryContent: json['summary_content'] == null
          ? null
          : MPSummaryMemoryStruct.fromJson(
              json['summary_content'] as Map<String, dynamic>,
            ),
      onlyRecordContent: json['only_record_content'] == null
          ? null
          : MPOnlyRecordMemoryStruct.fromJson(
              json['only_record_content'] as Map<String, dynamic>,
            ),
      unreadItemCnt: mpNullableIntFromJson(json['unread_item_cnt']),
    );

Map<String, dynamic> _$MPMemoryStructToJson(MPMemoryStruct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'create_at': instance.createAt,
      'title': instance.title,
      'sub_title': instance.subTitle,
      'type': _$MPMemoryTypeEnumMap[instance.type],
      'content': instance.content,
      'duration': instance.duration,
      'unread_item_cnt': instance.unreadItemCnt,
      'memo_list': instance.memoList,
      'source': instance.source,
      'memory_feed': instance.memoryFeed,
      'summary_content': instance.summaryContent,
      'only_record_content': instance.onlyRecordContent,
    };

const _$MPMemoryTypeEnumMap = {
  MPMemoryType.summary: 1,
  MPMemoryType.onlyRecord: 2,
  MPMemoryType.memoryFeed: 5,
  MPMemoryType.memoList: 6,
};

MPFeedCardStruct _$MPFeedCardStructFromJson(Map<String, dynamic> json) =>
    MPFeedCardStruct(
      id: json['id'] as String?,
      type: (json['type'] as num?)?.toInt(),
      title: json['title'] as String?,
      createAt: (json['create_at'] as num?)?.toInt(),
      content: json['content'] as String?,
      todos: (json['todos'] as List<dynamic>?)
          ?.map((e) => MPTodoStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasAddedTodo: json['has_added_todo'] as bool?,
      memos: (json['memos'] as List<dynamic>?)
          ?.map((e) => MPMemoStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MPFeedCardStructToJson(MPFeedCardStruct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'create_at': instance.createAt,
      'content': instance.content,
      'todos': instance.todos,
      'has_added_todo': instance.hasAddedTodo,
      'memos': instance.memos,
    };

MPMemoryFeedStruct _$MPMemoryFeedStructFromJson(Map<String, dynamic> json) =>
    MPMemoryFeedStruct(
      summaryMemory: json['summary_memory'] == null
          ? null
          : MPSummaryMemoryStruct.fromJson(
              json['summary_memory'] as Map<String, dynamic>,
            ),
      feeds:
          (json['feeds'] as List<dynamic>?)
              ?.map((e) => MPFeedCardStruct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$MPMemoryFeedStructToJson(MPMemoryFeedStruct instance) =>
    <String, dynamic>{
      'summary_memory': instance.summaryMemory?.toJson(),
      'feeds': instance.feeds.map((e) => e.toJson()).toList(),
    };

MPMemoStruct _$MPMemoStructFromJson(Map<String, dynamic> json) => MPMemoStruct(
  id: json['id'] as String,
  title: json['title'] as String,
  content: json['content'] as String,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  createAt: (json['create_at'] as num?)?.toInt(),
  relateMemoryId: (json['relate_memory_id'] as num?)?.toInt(),
  type: $enumDecodeNullable(_$MPMemoTypeEnumMap, json['type']),
);

Map<String, dynamic> _$MPMemoStructToJson(MPMemoStruct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'tags': instance.tags,
      'create_at': instance.createAt,
      'relate_memory_id': instance.relateMemoryId,
      'type': _$MPMemoTypeEnumMap[instance.type],
    };

const _$MPMemoTypeEnumMap = {
  MPMemoType.highlightMemo: 1,
  MPMemoType.manualMemo: 2,
};

MPExpertStruct _$MPExpertStructFromJson(Map<String, dynamic> json) =>
    MPExpertStruct(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      label: json['label'] as String?,
      about: json['about'] as String?,
      capabilities: (json['capabilities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      chatPrompt: json['chat_prompt'] as String?,
      feedPrompt: json['feed_prompt'] as String?,
      feedbackCronAt: json['feedback_cron_at'] as String?,
    );

Map<String, dynamic> _$MPExpertStructToJson(MPExpertStruct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatar': instance.avatar,
      'label': instance.label,
      'about': instance.about,
      'capabilities': instance.capabilities,
      'chat_prompt': instance.chatPrompt,
      'feed_prompt': instance.feedPrompt,
      'feedback_cron_at': instance.feedbackCronAt,
    };

MPTemplateStruct _$MPTemplateStructFromJson(Map<String, dynamic> json) =>
    MPTemplateStruct(
      id: json['id'] as String?,
      title: json['title'] as String?,
      icon: json['icon'] as String?,
      type: json['type'] as String?,
      prompt: json['prompt'] as String?,
      subTitle: json['sub_title'] as String?,
    );

Map<String, dynamic> _$MPTemplateStructToJson(MPTemplateStruct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'sub_title': instance.subTitle,
      'icon': instance.icon,
      'type': instance.type,
      'prompt': instance.prompt,
    };

MPUserAISettings _$MPUserAISettingsFromJson(Map<String, dynamic> json) =>
    MPUserAISettings(
      appellation: json['appellation'] as String,
      profession: json['profession'] as String,
      aiPersonality: json['ai_personality'] as String,
      responseStyle: json['response_style'] as String,
      customPrompt: json['custom_prompt'] as String,
    );

Map<String, dynamic> _$MPUserAISettingsToJson(MPUserAISettings instance) =>
    <String, dynamic>{
      'appellation': instance.appellation,
      'profession': instance.profession,
      'ai_personality': instance.aiPersonality,
      'response_style': instance.responseStyle,
      'custom_prompt': instance.customPrompt,
    };

MPUserStruct _$MPUserStructFromJson(Map<String, dynamic> json) => MPUserStruct(
  userName: json['user_name'] as String,
  email: json['email'] as String,
  avatar: json['avatar'] as String,
  phone: json['phone'] as String,
  birthday: json['brithday'] as String,
  aiSettings: MPUserAISettings.fromJson(
    json['ai_settings'] as Map<String, dynamic>,
  ),
  rightNowTranscribe: json['right_now_transcribe'] as bool?,
);

Map<String, dynamic> _$MPUserStructToJson(MPUserStruct instance) =>
    <String, dynamic>{
      'user_name': instance.userName,
      'email': instance.email,
      'avatar': instance.avatar,
      'phone': instance.phone,
      'brithday': instance.birthday,
      'ai_settings': instance.aiSettings,
      'right_now_transcribe': instance.rightNowTranscribe,
    };

MPSpeakerWithDetailStruct _$MPSpeakerWithDetailStructFromJson(
  Map<String, dynamic> json,
) => MPSpeakerWithDetailStruct(
  speaker: MPSpeakerStruct.fromJson(json['speaker'] as Map<String, dynamic>),
  summary: json['summary'] as String,
  last_memory_at: (json['last_memory_at'] as num).toInt(),
  memory_total: (json['memory_total'] as num).toInt(),
);

Map<String, dynamic> _$MPSpeakerWithDetailStructToJson(
  MPSpeakerWithDetailStruct instance,
) => <String, dynamic>{
  'speaker': instance.speaker,
  'summary': instance.summary,
  'last_memory_at': instance.last_memory_at,
  'memory_total': instance.memory_total,
};

MPExpertMergeUserStruct _$MPExpertMergeUserStructFromJson(
  Map<String, dynamic> json,
) => MPExpertMergeUserStruct(
  expert: MPExpertStruct.fromJson(json['expert'] as Map<String, dynamic>),
  isAdd: json['is_add'] as bool,
);

Map<String, dynamic> _$MPExpertMergeUserStructToJson(
  MPExpertMergeUserStruct instance,
) => <String, dynamic>{'expert': instance.expert, 'is_add': instance.isAdd};
