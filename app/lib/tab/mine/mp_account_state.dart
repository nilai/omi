/// 账户页资料加载状态。
enum MPAccountProfileStatus {
  /// 正在请求用户资料。
  loading,

  /// 已成功展示后台资料（或降级展示本地占位）。
  loaded,

  /// 请求失败，已使用本地/占位文案。
  error,
}

/// 账户页 UI 状态。
class MPAccountState {
  /// 创建初始状态（进入页时即视为加载中）。
  const MPAccountState({
    required this.profileStatus,
    required this.displayName,
    required this.displayEmail,
    this.memberSinceLabel = '',
    this.errorMessage,
    this.signOutInProgress = false,
  });

  /// 首帧：加载中、展示空字符串直至接口返回。
  factory MPAccountState.initial() => const MPAccountState(
        profileStatus: MPAccountProfileStatus.loading,
        displayName: '',
        displayEmail: '',
        memberSinceLabel: '',
      );

  final MPAccountProfileStatus profileStatus;
  final String displayName;
  final String displayEmail;

  /// 如 `Member since January 2024`；无有效 [create_at] 时为空。
  final String memberSinceLabel;
  final String? errorMessage;
  final bool signOutInProgress;

  MPAccountState copyWith({
    MPAccountProfileStatus? profileStatus,
    String? displayName,
    String? displayEmail,
    String? memberSinceLabel,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? signOutInProgress,
  }) {
    return MPAccountState(
      profileStatus: profileStatus ?? this.profileStatus,
      displayName: displayName ?? this.displayName,
      displayEmail: displayEmail ?? this.displayEmail,
      memberSinceLabel: memberSinceLabel ?? this.memberSinceLabel,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      signOutInProgress: signOutInProgress ?? this.signOutInProgress,
    );
  }
}
