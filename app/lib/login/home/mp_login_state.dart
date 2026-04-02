/// 认证页：登录 / 注册模式。
enum MPLoginMode {
  /// 登录
  login,

  /// 注册
  signup,
}

class _Unset {
  const _Unset();
}

const Object _kUnset = _Unset();

/// 认证页状态：模式、输入与校验错误。
///
/// [emailError]、[passwordError] 为 `null` 或空字符串时不展示错误文案。
/// 当 [email]、[password] 为空（`''`）时，对应错误字段应为 `null`。
class MPLoginState {
  const MPLoginState({
    this.mode = MPLoginMode.login,
    this.email = '903645893@qq.com',
    this.password = '123456',
    this.emailError,
    this.passwordError,
    this.obscurePassword = true,
  });

  final MPLoginMode mode;

  /// 邮箱输入（空字符串表示未填）。
  final String email;

  /// 密码输入。
  final String password;

  /// 邮箱错误；`null` 或 `''` 不展示。
  final String? emailError;

  /// 密码错误；`null` 或 `''` 不展示。
  final String? passwordError;

  /// 是否隐藏密码。
  final bool obscurePassword;

  /// 主按钮是否可点：邮箱、密码均非空（trim 后）。
  bool get isPrimaryButtonEnabled => email.trim().isNotEmpty && password.isNotEmpty;

  /// 规范化错误：仅非空字符串视为有效提示。
  static String? normalizeError(String? e) {
    if (e == null || e.isEmpty) return null;
    return e;
  }

  MPLoginState copyWith({
    MPLoginMode? mode,
    String? email,
    String? password,
    Object? emailError = _kUnset,
    Object? passwordError = _kUnset,
    bool? obscurePassword,
  }) {
    return MPLoginState(
      mode: mode ?? this.mode,
      email: email ?? this.email,
      password: password ?? this.password,
      emailError: identical(emailError, _kUnset) ? this.emailError : emailError as String?,
      passwordError: identical(passwordError, _kUnset) ? this.passwordError : passwordError as String?,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}
