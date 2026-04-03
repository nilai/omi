/// 忘记密码「邮件已发送」成功页状态。
class MPForgetSuccessState {
  const MPForgetSuccessState({
    required this.email,
    this.resendInProgress = false,
  });

  /// 接收重置链接的邮箱（展示与重发共用）。
  final String email;

  /// 是否正在调用重新发送接口。
  final bool resendInProgress;

  MPForgetSuccessState copyWith({
    String? email,
    bool? resendInProgress,
  }) {
    return MPForgetSuccessState(
      email: email ?? this.email,
      resendInProgress: resendInProgress ?? this.resendInProgress,
    );
  }
}
