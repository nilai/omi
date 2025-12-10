// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mp_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MPGetTemplateListRequest _$MPGetTemplateListRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetTemplateListRequest(
      pageSize: (json['page_size'] as num).toInt(),
      cursor: json['cursor'] as String,
    );

Map<String, dynamic> _$MPGetTemplateListRequestToJson(
        MPGetTemplateListRequest instance) =>
    <String, dynamic>{
      'page_size': instance.pageSize,
      'cursor': instance.cursor,
    };

MPGetTemplateDetailRequest _$MPGetTemplateDetailRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetTemplateDetailRequest(
      templateId: json['template_id'] as String,
    );

Map<String, dynamic> _$MPGetTemplateDetailRequestToJson(
        MPGetTemplateDetailRequest instance) =>
    <String, dynamic>{
      'template_id': instance.templateId,
    };
