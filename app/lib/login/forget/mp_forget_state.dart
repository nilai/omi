class _Unset {
  const _Unset();
}

const Object _kUnset = _Unset();

/// 忘记密码页状态：邮箱输入与校验结果。
class MPForgetState {
  const MPForgetState({
    this.email = '',
    this.emailError,
    this.isSubmitted = false,
  });

  /// 邮箱输入值（空字符串表示未填写）。
  final String email;

  /// 邮箱错误信息，`null` 或空字符串时不展示。
  final String? emailError;

  /// 最近一次提交是否通过校验。
  final bool isSubmitted;

  /// 主按钮是否可点击：邮箱非空。
  bool get isPrimaryButtonEnabled => email.trim().isNotEmpty;

  /// 规范化错误信息。
  static String? normalizeError(String? e) {
    if (e == null || e.isEmpty) return null;
    return e;
  }

  MPForgetState copyWith({
    String? email,
    Object? emailError = _kUnset,
    bool? isSubmitted,
  }) {
    return MPForgetState(
      email: email ?? this.email,
      emailError: identical(emailError, _kUnset) ? this.emailError : emailError as String?,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }
}
