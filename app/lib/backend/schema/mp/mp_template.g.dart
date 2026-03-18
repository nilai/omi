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

MPSetTemplateDefaultRequest _$MPSetTemplateDefaultRequestFromJson(
        Map<String, dynamic> json) =>
    MPSetTemplateDefaultRequest(
      templateId: json['template_id'] as String,
    );

Map<String, dynamic> _$MPSetTemplateDefaultRequestToJson(
        MPSetTemplateDefaultRequest instance) =>
    <String, dynamic>{
      'template_id': instance.templateId,
    };

MPCreateTemplateRequest _$MPCreateTemplateRequestFromJson(
        Map<String, dynamic> json) =>
    MPCreateTemplateRequest(
      title: json['title'] as String,
      icon: json['icon'] as String?,
      prompt: json['prompt'] as String,
      type: json['type'] as String,
      setDefault: json['set_default'] as bool?,
      templateId: json['template_id'] as String?,
    );

Map<String, dynamic> _$MPCreateTemplateRequestToJson(
        MPCreateTemplateRequest instance) =>
    <String, dynamic>{
      'template_id': instance.templateId,
      'title': instance.title,
      'icon': instance.icon,
      'prompt': instance.prompt,
      'type': instance.type,
      'set_default': instance.setDefault,
    };

MPGetTemplateListResponse _$MPGetTemplateListResponseFromJson(
        Map<String, dynamic> json) =>
    MPGetTemplateListResponse(
      recommendTemplates: (json['recommend_templates'] as List<dynamic>)
          .map((e) => MPTemplateStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
      customTemplates: (json['custom_templates'] as List<dynamic>)
          .map((e) => MPTemplateStruct.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentTemplate: json['recent_template'] == null
          ? null
          : MPTemplateStruct.fromJson(
              json['recent_template'] as Map<String, dynamic>),
      templates: _templatesFromJson(json['templates']),
      hasMore: json['has_more'] as bool,
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPGetTemplateListResponseToJson(
        MPGetTemplateListResponse instance) =>
    <String, dynamic>{
      'recommend_templates': instance.recommendTemplates,
      'custom_templates': instance.customTemplates,
      'recent_template': instance.recentTemplate,
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

MPSetTemplateDefaultResponse _$MPSetTemplateDefaultResponseFromJson(
        Map<String, dynamic> json) =>
    MPSetTemplateDefaultResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPSetTemplateDefaultResponseToJson(
        MPSetTemplateDefaultResponse instance) =>
    <String, dynamic>{
      'base_resp': instance.baseResp,
    };

MPCreateTemplateResponse _$MPCreateTemplateResponseFromJson(
        Map<String, dynamic> json) =>
    MPCreateTemplateResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPCreateTemplateResponseToJson(
        MPCreateTemplateResponse instance) =>
    <String, dynamic>{
      'base_resp': instance.baseResp,
    };
