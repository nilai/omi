import 'package:json_annotation/json_annotation.dart';

import 'mp_data_model.dart';

part 'mp_template.g.dart';

// 自定义转换函数：处理 templates 字段可能是 List 或 Map 的情况
Map<String, List<MPTemplateStruct>> _templatesFromJson(dynamic json) {
  if (json == null) {
    return {};
  }

  if (json is Map) {
    // 如果是 Map，直接转换
    final Map<String, List<MPTemplateStruct>> result = {};
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key.toString()] = [MPTemplateStruct.fromJson(value)];
      } else if (value is List<dynamic>) {
        result[key.toString()] = value.map((e) => MPTemplateStruct.fromJson(e as Map<String, dynamic>)).toList();
      }
    });
    return result;
  } else {
    return {};
  }
}

// Get Template List Request
@JsonSerializable()
class MPGetTemplateListRequest {
  @JsonKey(name: 'page_size')
  final int pageSize;

  @JsonKey(name: 'cursor')
  final String cursor;

  MPGetTemplateListRequest({
    required this.pageSize,
    required this.cursor,
  });

  factory MPGetTemplateListRequest.fromJson(Map<String, dynamic> json) => _$MPGetTemplateListRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetTemplateListRequestToJson(this);
}

// Get Template Detail Request
@JsonSerializable()
class MPGetTemplateDetailRequest {
  @JsonKey(name: 'template_id')
  final String templateId;

  MPGetTemplateDetailRequest({
    required this.templateId,
  });

  factory MPGetTemplateDetailRequest.fromJson(Map<String, dynamic> json) => _$MPGetTemplateDetailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetTemplateDetailRequestToJson(this);
}

// Set Template Default Request
@JsonSerializable()
class MPSetTemplateDefaultRequest {
  @JsonKey(name: 'template_id')
  final String templateId;

  MPSetTemplateDefaultRequest({
    required this.templateId,
  });

  factory MPSetTemplateDefaultRequest.fromJson(Map<String, dynamic> json) =>
      _$MPSetTemplateDefaultRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPSetTemplateDefaultRequestToJson(this);
}

// Create Template Request
@JsonSerializable()
class MPCreateTemplateRequest {
  @JsonKey(name: 'template_id')
  final String? templateId;

  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'icon')
  final String? icon;

  @JsonKey(name: 'prompt')
  final String prompt;

  @JsonKey(name: 'type')
  final String type;

  @JsonKey(name: 'set_default')
  final bool? setDefault;

  MPCreateTemplateRequest({
    required this.title,
    this.icon,
    required this.prompt,
    required this.type,
    required this.setDefault,
    this.templateId,
  });

  factory MPCreateTemplateRequest.fromJson(Map<String, dynamic> json) => _$MPCreateTemplateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateTemplateRequestToJson(this);
}

// ========== Response Classes ==========

// Get Template List Response
@JsonSerializable()
class MPGetTemplateListResponse {
  @JsonKey(name: 'recommend_templates')
  final List<MPTemplateStruct> recommendTemplates;

  @JsonKey(name: 'custom_templates')
  final List<MPTemplateStruct> customTemplates;

  @JsonKey(name: 'recent_template')
  final MPTemplateStruct? recentTemplate;

  @JsonKey(name: 'templates', fromJson: _templatesFromJson)
  final Map<String, List<MPTemplateStruct>> templates;

  @JsonKey(name: 'has_more')
  final bool hasMore;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetTemplateListResponse({
    required this.recommendTemplates,
    required this.customTemplates,
    this.recentTemplate,
    required this.templates,
    required this.hasMore,
    required this.baseResp,
  });

  factory MPGetTemplateListResponse.fromJson(Map<String, dynamic> json) => _$MPGetTemplateListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetTemplateListResponseToJson(this);
}

// Get Template Detail Response
@JsonSerializable()
class MPGetTemplateDetailResponse {
  @JsonKey(name: 'template')
  final MPTemplateStruct template;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetTemplateDetailResponse({
    required this.template,
    required this.baseResp,
  });

  factory MPGetTemplateDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$MPGetTemplateDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetTemplateDetailResponseToJson(this);
}

// Set Template Default Response
@JsonSerializable()
class MPSetTemplateDefaultResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPSetTemplateDefaultResponse({
    required this.baseResp,
  });

  factory MPSetTemplateDefaultResponse.fromJson(Map<String, dynamic> json) =>
      _$MPSetTemplateDefaultResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPSetTemplateDefaultResponseToJson(this);
}

// Create Template Response
@JsonSerializable()
class MPCreateTemplateResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPCreateTemplateResponse({
    required this.baseResp,
  });

  factory MPCreateTemplateResponse.fromJson(Map<String, dynamic> json) => _$MPCreateTemplateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateTemplateResponseToJson(this);
}
