import 'package:json_annotation/json_annotation.dart';

part 'presigned_url_response.g.dart';

/// 预签名URL响应模型
/// 用于获取S3上传的预签名URL
@JsonSerializable()
class PresignedUrlResponse {
  /// S3预签名上传URL
  @JsonKey(name: 'upload_url')
  final String uploadUrl;

  /// 文件在S3中的路径
  @JsonKey(name: 'uri')
  final String uri;

  PresignedUrlResponse({
    required this.uploadUrl,
    required this.uri,
  });

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) =>
      _$PresignedUrlResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PresignedUrlResponseToJson(this);

  @override
  String toString() {
    return 'PresignedUrlResponse(uploadUrl: $uploadUrl, uri: $uri)';
  }
}
