import 'package:json_annotation/json_annotation.dart';

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

