// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mp_memo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MPCreateMemoWithTextRequest _$MPCreateMemoWithTextRequestFromJson(
  Map<String, dynamic> json,
) => MPCreateMemoWithTextRequest(
  content: json['content'] as String,
  createAt: (json['create_at'] as num).toInt(),
);

Map<String, dynamic> _$MPCreateMemoWithTextRequestToJson(
  MPCreateMemoWithTextRequest instance,
) => <String, dynamic>{
  'content': instance.content,
  'create_at': instance.createAt,
};

MPDeleteMemoRequest _$MPDeleteMemoRequestFromJson(Map<String, dynamic> json) =>
    MPDeleteMemoRequest(memoId: json['memo_id'] as String);

Map<String, dynamic> _$MPDeleteMemoRequestToJson(
  MPDeleteMemoRequest instance,
) => <String, dynamic>{'memo_id': instance.memoId};

MPCreateMemoWithTextResponse _$MPCreateMemoWithTextResponseFromJson(
  Map<String, dynamic> json,
) => MPCreateMemoWithTextResponse(
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPCreateMemoWithTextResponseToJson(
  MPCreateMemoWithTextResponse instance,
) => <String, dynamic>{'base_resp': instance.baseResp};

MPDeleteMemoResponse _$MPDeleteMemoResponseFromJson(
  Map<String, dynamic> json,
) => MPDeleteMemoResponse(
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPDeleteMemoResponseToJson(
  MPDeleteMemoResponse instance,
) => <String, dynamic>{'base_resp': instance.baseResp};

MPAnalyzeMemoSuggestionStruct _$MPAnalyzeMemoSuggestionStructFromJson(
  Map<String, dynamic> json,
) => MPAnalyzeMemoSuggestionStruct(
  type: $enumDecode(_$MPAnalyzeMemoSuggestionTypeEnumMap, json['type']),
  content: json['content'] as String,
);

Map<String, dynamic> _$MPAnalyzeMemoSuggestionStructToJson(
  MPAnalyzeMemoSuggestionStruct instance,
) => <String, dynamic>{
  'type': _$MPAnalyzeMemoSuggestionTypeEnumMap[instance.type]!,
  'content': instance.content,
};

const _$MPAnalyzeMemoSuggestionTypeEnumMap = {
  MPAnalyzeMemoSuggestionType.todo: 1,
  MPAnalyzeMemoSuggestionType.memo: 2,
};

MPAnalyzeMemoRecordRequest _$MPAnalyzeMemoRecordRequestFromJson(
  Map<String, dynamic> json,
) => MPAnalyzeMemoRecordRequest(
  recordUrl: json['record_url'] as String,
  createAt: (json['create_at'] as num).toInt(),
);

Map<String, dynamic> _$MPAnalyzeMemoRecordRequestToJson(
  MPAnalyzeMemoRecordRequest instance,
) => <String, dynamic>{
  'record_url': instance.recordUrl,
  'create_at': instance.createAt,
};

MPAnalyzeMemoRecordResponse _$MPAnalyzeMemoRecordResponseFromJson(
  Map<String, dynamic> json,
) => MPAnalyzeMemoRecordResponse(
  originalText: json['original_text'] as String,
  structuredSuggestions: (json['structured_suggestions'] as List<dynamic>)
      .map(
        (e) =>
            MPAnalyzeMemoSuggestionStruct.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPAnalyzeMemoRecordResponseToJson(
  MPAnalyzeMemoRecordResponse instance,
) => <String, dynamic>{
  'original_text': instance.originalText,
  'structured_suggestions': instance.structuredSuggestions
      .map((e) => e.toJson())
      .toList(),
  'base_resp': instance.baseResp.toJson(),
};

MPAnalyzeMemoTextRequest _$MPAnalyzeMemoTextRequestFromJson(
  Map<String, dynamic> json,
) => MPAnalyzeMemoTextRequest(
  content: json['content'] as String,
  createAt: (json['create_at'] as num).toInt(),
);

Map<String, dynamic> _$MPAnalyzeMemoTextRequestToJson(
  MPAnalyzeMemoTextRequest instance,
) => <String, dynamic>{
  'content': instance.content,
  'create_at': instance.createAt,
};

MPAnalyzeMemoTextResponse _$MPAnalyzeMemoTextResponseFromJson(
  Map<String, dynamic> json,
) => MPAnalyzeMemoTextResponse(
  originalText: json['original_text'] as String,
  structuredSuggestions: (json['structured_suggestions'] as List<dynamic>)
      .map(
        (e) =>
            MPAnalyzeMemoSuggestionStruct.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPAnalyzeMemoTextResponseToJson(
  MPAnalyzeMemoTextResponse instance,
) => <String, dynamic>{
  'original_text': instance.originalText,
  'structured_suggestions': instance.structuredSuggestions
      .map((e) => e.toJson())
      .toList(),
  'base_resp': instance.baseResp.toJson(),
};
