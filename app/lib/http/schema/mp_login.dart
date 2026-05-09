import 'package:memo_pin/http/schema/mp_base.dart';
class MPSendCodeRequest {
  MPSendCodeRequest({required this.email, this.password});

  final String email;

  final String? password;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'email': email};
    if (password != null && password!.isNotEmpty) {
      json['password'] = password;
    }
    return json;
  }
}

class MPSendCodeResponse {
  MPSendCodeResponse({required this.baseResp});

  final MPBaseResp baseResp;

  factory MPSendCodeResponse.fromJson(Map<String, dynamic> json) {
    return MPSendCodeResponse(
      baseResp: MPBaseResp.fromJson((json['base_resp'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'base_resp': baseResp.toJson()};
  }
}

class MPRegisterRequest {
  MPRegisterRequest({
    required this.email,
    required this.code,
    required this.password,
  });

  final String email;
  final String code;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'email': email,
      'code': code,
      'password': password,
    };
  }
}

class MPLoginRequest {
  MPLoginRequest({
    required this.email,
    required this.password,
    this.deviceId,
  });

  final String email;
  final String password;
  final String? deviceId;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'email': email,
      'password': password,
    };
    if (deviceId != null && deviceId!.isNotEmpty) {
      json['device_id'] = deviceId;
    }
    return json;
  }
}

class MPRefreshTokenRequest {
  MPRefreshTokenRequest({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'refresh_token': refreshToken};
  }
}

class MPTokenResponse {
  MPTokenResponse({
    required this.baseResp,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.userId,
  });

  final MPBaseResp baseResp;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String userId;

  factory MPTokenResponse.fromJson(Map<String, dynamic> json) {
    return MPTokenResponse(
      baseResp: MPBaseResp.fromJson((json['base_resp'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? -1,
      userId: json['user_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'base_resp': baseResp.toJson(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'user_id': userId,
    };
  }
}

class MPCommonAuthResponse {
  MPCommonAuthResponse({required this.baseResp});

  final MPBaseResp baseResp;

  factory MPCommonAuthResponse.fromJson(Map<String, dynamic> json) {
    return MPCommonAuthResponse(
      baseResp: MPBaseResp.fromJson((json['base_resp'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'base_resp': baseResp.toJson()};
  }
}

class MPResetPasswordConfirmRequest {
  MPResetPasswordConfirmRequest({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  final String email;
  final String code;
  final String newPassword;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'email': email,
      'code': code,
      'new_password': newPassword,
    };
  }
}
