class _Unset {
  const _Unset();
}

const Object _kUnset = _Unset();

/// 验证码页面状态。
class MPVerifyState {
  const MPVerifyState({
    this.code = '',
    this.codeError,
    this.isResendInProgress = false,
  });

  /// 用户输入的验证码(长度大于等于4)。
  final String code;

  /// 错误文案，`null` 或空字符串不展示。
  final String? codeError;

  /// 是否正在请求重新发送验证码。
  final bool isResendInProgress;

  // /// 最近一次提交是否通过校验。
  // final bool isSubmitted;

  /// 验证按钮是否可点。
  bool get isPrimaryButtonEnabled => code.length >= 4;

  /// 规范化错误信息。
  static String? normalizeError(String? e) {
    if (e == null || e.isEmpty) return null;
    return e;
  }

  /// 复制状态。
  MPVerifyState copyWith({
    String? code,
    Object? codeError = _kUnset,
    bool? isSubmitted,
    bool? isResendInProgress,
  }) {
    return MPVerifyState(
      code: code ?? this.code,
      codeError: identical(codeError, _kUnset) ? this.codeError : codeError as String?,
      isResendInProgress: isResendInProgress ?? this.isResendInProgress,
      // isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }
}
