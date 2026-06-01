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

/// 更新用户资料请求体；字段为空字符串则不更新。
class MPUpdateUserProfileRequest {
  final String name;
  final String email;
  final String avatar;
  final String phone;
  final String brithday;
  final String language;
  final String timezone;

  MPUpdateUserProfileRequest({
    this.name = '',
    this.email = '',
    this.avatar = '',
    this.phone = '',
    this.brithday = '',
    this.language = '',
    this.timezone = '',
  });

  /// 从 JSON 解析。
  factory MPUpdateUserProfileRequest.fromJson(Map<String, dynamic> json) {
    return MPUpdateUserProfileRequest(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      brithday: json['brithday'] as String? ?? '',
      language: json['language'] as String? ?? '',
      timezone: json['timezone'] as String? ?? '',
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'email': email,
        'avatar': avatar,
        'phone': phone,
        'brithday': brithday,
        'language': language,
        'timezone': timezone,
      };
}

/// 更新用户资料响应。
class MPUpdateUserProfileResponse {
  final MPBaseResp baseResp;

  MPUpdateUserProfileResponse({
    required this.baseResp,
  });

  /// 从 JSON 解析。
  factory MPUpdateUserProfileResponse.fromJson(Map<String, dynamic> json) {
    return MPUpdateUserProfileResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'base_resp': baseResp.toJson(),
      };
}
