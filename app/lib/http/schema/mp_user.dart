import 'mp_data_model.dart';

/// 获取用户资料请求体（当前无字段，与接口空对象对齐）。
class MPGetUserProfileRequest {
  MPGetUserProfileRequest();

  /// 从 JSON 解析；忽略未知字段。
  factory MPGetUserProfileRequest.fromJson(Map<String, dynamic> json) {
    return MPGetUserProfileRequest();
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{};
}

/// 获取用户资料响应。
class MPGetUserProfileResponse {
  final MPUserStruct user;
  final MPBaseResp baseResp;

  MPGetUserProfileResponse({
    required this.user,
    required this.baseResp,
  });

  /// 从 JSON 解析。
  factory MPGetUserProfileResponse.fromJson(Map<String, dynamic> json) {
    return MPGetUserProfileResponse(
      user: MPUserStruct.fromJson(json['user'] as Map<String, dynamic>),
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'user': user.toJson(),
        'base_resp': baseResp.toJson(),
      };
}
