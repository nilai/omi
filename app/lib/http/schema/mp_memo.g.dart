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
