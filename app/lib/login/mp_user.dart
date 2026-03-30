class MPUser {
  /// 用户信息
  String? name;

  /// 访问令牌
  String? accessToken;

  /// 刷新令牌
  String? refreshToken;

  /// 邮箱
  String? email;

  // 单例实例
  static final MPUser _instance = MPUser._internal();

  /// 私有构造
  MPUser._internal();

  /// 工厂构造返回单例
  factory MPUser() => _instance;

  /// 静态便捷方式
  static MPUser get instance => _instance;

  /// 当前用户是否已登录
  // static bool get isLoggedIn => instance.accessToken != null && instance.accessToken!.isNotEmpty;
  static bool get isLoggedIn => false;

  /// 清空用户信息（登出）
  void clear() {
    name = null;
    accessToken = null;
    refreshToken = null;
    email = null;
  }
}
