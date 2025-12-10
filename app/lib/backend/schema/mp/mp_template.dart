import 'package:json_annotation/json_annotation.dart';
import 'mp_data_model.dart';

part 'mp_template.g.dart';

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

  factory MPGetTemplateListRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetTemplateListRequestFromJson(json);

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

  factory MPGetTemplateDetailRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetTemplateDetailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetTemplateDetailRequestToJson(this);
}

// ========== Response Classes ==========

// Get Template List Response
@JsonSerializable()
class MPGetTemplateListResponse {
  @JsonKey(name: 'templates')
  final List<MPTemplateStruct> templates;

  @JsonKey(name: 'has_more')
  final bool hasMore;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetTemplateListResponse({
    required this.templates,
    required this.hasMore,
    required this.baseResp,
  });

  factory MPGetTemplateListResponse.fromJson(Map<String, dynamic> json) =>
      _$MPGetTemplateListResponseFromJson(json);

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

