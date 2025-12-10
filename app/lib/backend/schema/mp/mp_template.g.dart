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

MPGetTemplateListResponse _$MPGetTemplateListResponseFromJson(
        Map<String, dynamic> json) =>
    MPGetTemplateListResponse(
      templates: (json['templates'] as List<dynamic>)
          .map((e) => MPTemplateStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['has_more'] as bool,
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetTemplateListResponseToJson(
        MPGetTemplateListResponse instance) =>
    <String, dynamic>{
      'templates': instance.templates,
      'has_more': instance.hasMore,
      'base_resp': instance.baseResp,
    };

MPGetTemplateDetailResponse _$MPGetTemplateDetailResponseFromJson(
        Map<String, dynamic> json) =>
    MPGetTemplateDetailResponse(
      template:
          MPTemplateStruct.fromJson(json['template'] as Map<String, dynamic>),
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetTemplateDetailResponseToJson(
        MPGetTemplateDetailResponse instance) =>
    <String, dynamic>{
      'template': instance.template,
      'base_resp': instance.baseResp,
    };
