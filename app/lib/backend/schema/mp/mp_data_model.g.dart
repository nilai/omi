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
      id: json['id'] as String,
      title: json['title'] as String,
      owner: MPSpeakerStruct.fromJson(json['owner'] as Map<String, dynamic>),
      priority: json['priority'] as String,
      deadline: json['deadline'] as String,
      status: (json['status'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MPTodoStructToJson(MPTodoStruct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'owner': instance.owner,
      'priority': instance.priority,
      'deadline': instance.deadline,
      'status': instance.status,
    };

MPSummaryConversationStruct _$MPSummaryConversationStructFromJson(
        Map<String, dynamic> json) =>
    MPSummaryConversationStruct(
      id: json['id'] as String,
      speaker:
          MPSpeakerStruct.fromJson(json['speaker'] as Map<String, dynamic>),
      content: json['content'] as String,
      time: json['time'] as String,
    );

Map<String, dynamic> _$MPSummaryConversationStructToJson(
        MPSummaryConversationStruct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'speaker': instance.speaker,
      'content': instance.content,
      'time': instance.time,
    };

MPSummaryMemoryStruct _$MPSummaryMemoryStructFromJson(
        Map<String, dynamic> json) =>
    MPSummaryMemoryStruct(
      participants: (json['participants'] as List<dynamic>)
          .map((e) => MPSpeakerStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
      recordUrl: json['record_url'] as String,
      summary: json['summary'] as String,
      transcript: (json['transcript'] as List<dynamic>)
          .map((e) =>
              MPSummaryConversationStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
      todos: (json['todos'] as List<dynamic>)
          .map((e) => MPTodoStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
      participants_cnt: (json['participants_cnt'] as num).toInt(),
    );

Map<String, dynamic> _$MPSummaryMemoryStructToJson(
        MPSummaryMemoryStruct instance) =>
    <String, dynamic>{
      'participants': instance.participants,
      'participants_cnt': instance.participants_cnt,
      'record_url': instance.recordUrl,
      'summary': instance.summary,
      'transcript': instance.transcript,
      'todos': instance.todos,
    };

MPOnlyRecordMemoryStruct _$MPOnlyRecordMemoryStructFromJson(
        Map<String, dynamic> json) =>
    MPOnlyRecordMemoryStruct(
      recordFile: json['record_file'] as String,
    );

Map<String, dynamic> _$MPOnlyRecordMemoryStructToJson(
        MPOnlyRecordMemoryStruct instance) =>
    <String, dynamic>{
      'record_file': instance.recordFile,
    };

MPInsightMemoryStruct _$MPInsightMemoryStructFromJson(
        Map<String, dynamic> json) =>
    MPInsightMemoryStruct(
      content: json['content'] as String,
    );

Map<String, dynamic> _$MPInsightMemoryStructToJson(
        MPInsightMemoryStruct instance) =>
    <String, dynamic>{
      'content': instance.content,
    };

MPAiExpertMemoryStruct _$MPAiExpertMemoryStructFromJson(
        Map<String, dynamic> json) =>
    MPAiExpertMemoryStruct(
      content: json['content'] as String,
    );

Map<String, dynamic> _$MPAiExpertMemoryStructToJson(
        MPAiExpertMemoryStruct instance) =>
    <String, dynamic>{
      'content': instance.content,
    };

MPMemoryStruct _$MPMemoryStructFromJson(Map<String, dynamic> json) =>
    MPMemoryStruct(
      id: json['id'] as String,
      createAt: (json['create_at'] as num).toInt(),
      title: json['title'] as String,
      type: $enumDecode(_$MPMemoryTypeEnumMap, json['type']),
      label: json['label'] as String,
      labelColor: json['label_color'] as String?,
      content: json['content'] as String,
      duration: (json['duration'] as num).toInt(),
      summaryContent: json['summary_content'] == null
          ? null
          : MPSummaryMemoryStruct.fromJson(
              json['summary_content'] as Map<String, dynamic>),
      onlyRecordContent: json['only_record_content'] == null
          ? null
          : MPOnlyRecordMemoryStruct.fromJson(
              json['only_record_content'] as Map<String, dynamic>),
      insightContent: json['insight_content'] == null
          ? null
          : MPInsightMemoryStruct.fromJson(
              json['insight_content'] as Map<String, dynamic>),
      aiExpertContent: json['ai_expert_content'] == null
          ? null
          : MPAiExpertMemoryStruct.fromJson(
              json['ai_expert_content'] as Map<String, dynamic>),
      customLabels: (json['custom_labels'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$MPMemoryStructToJson(MPMemoryStruct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'create_at': instance.createAt,
      'title': instance.title,
      'type': _$MPMemoryTypeEnumMap[instance.type]!,
      'label': instance.label,
      'label_color': instance.labelColor,
      'content': instance.content,
      'duration': instance.duration,
      'summary_content': instance.summaryContent,
      'only_record_content': instance.onlyRecordContent,
      'insight_content': instance.insightContent,
      'ai_expert_content': instance.aiExpertContent,
      'custom_labels': instance.customLabels,
    };

const _$MPMemoryTypeEnumMap = {
  MPMemoryType.summary: 1,
  MPMemoryType.onlyRecord: 2,
  MPMemoryType.insight: 3,
  MPMemoryType.aiExpert: 4,
};

MPMemoStruct _$MPMemoStructFromJson(Map<String, dynamic> json) => MPMemoStruct(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createAt: (json['create_at'] as num?)?.toInt(),
      relateMemoryId: (json['relate_memory_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MPMemoStructToJson(MPMemoStruct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'tags': instance.tags,
      'create_at': instance.createAt,
      'relate_memory_id': instance.relateMemoryId,
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
    );

Map<String, dynamic> _$MPTemplateStructToJson(MPTemplateStruct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
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
          json['ai_settings'] as Map<String, dynamic>),
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
        Map<String, dynamic> json) =>
    MPSpeakerWithDetailStruct(
      speaker:
          MPSpeakerStruct.fromJson(json['speaker'] as Map<String, dynamic>),
      summary: json['summary'] as String,
      last_memory_at: (json['last_memory_at'] as num).toInt(),
      memory_total: (json['memory_total'] as num).toInt(),
    );

Map<String, dynamic> _$MPSpeakerWithDetailStructToJson(
        MPSpeakerWithDetailStruct instance) =>
    <String, dynamic>{
      'speaker': instance.speaker,
      'summary': instance.summary,
      'last_memory_at': instance.last_memory_at,
      'memory_total': instance.memory_total,
    };

MPExpertMergeUserStruct _$MPExpertMergeUserStructFromJson(
        Map<String, dynamic> json) =>
    MPExpertMergeUserStruct(
      expert: MPExpertStruct.fromJson(json['expert'] as Map<String, dynamic>),
      isAdd: json['is_add'] as bool,
    );

Map<String, dynamic> _$MPExpertMergeUserStructToJson(
        MPExpertMergeUserStruct instance) =>
    <String, dynamic>{
      'expert': instance.expert,
      'is_add': instance.isAdd,
    };
