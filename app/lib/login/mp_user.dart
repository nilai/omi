import '../utils/mp_preferences.dart';
import '../utils/mp_time_utils.dart';

class MPUser {
  /// 用户信息
  String? name;

  String? _accessToken;
  String? _userId;
  String? _refreshToken;
  String? _email;
  DateTime? _tokenExpiresTime;

  // 单例实例
  static final MPUser _instance = MPUser._internal();

  /// 私有构造
  MPUser._internal();

  /// 工厂构造返回单例
  factory MPUser() => _instance;

  /// 静态便捷方式
  static MPUser get instance => _instance;

  static const String _accessTokenKey = 'mp_accessToken';
  static const String _userIdKey = 'mp_userId';
  static const String _refreshTokenKey = 'mp_refreshToken';
  static const String _emailKey = 'mp_email';
  static const String _tokenExpiresTimeKey = 'mp_tokenExpiresTime';

  /// 获取访问令牌：优先内存，其次本地。
  String get accessToken {
    // return 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiAiMTgiLCAiZGV2aWNlX2lkIjogIjExMTExMTExIiwgImlhdCI6IDE3NzQ5NzcxMzcsICJleHAiOiAxNzc3NTY5MTM3fQ.r7QWpUTVt9uJMR2-lwJwlb6S5pkug0EIALTpLBO-Ci8';
    if (_accessToken?.isNotEmpty == true) {
      return _accessToken!;
    }
    final String token = MPPreferences().getString(_accessTokenKey);
    if (token.isNotEmpty) {
      _accessToken = token;
    }
    return token;
  }

  /// 设置访问令牌：null 时清除。
  Future<void> setAccessToken(String? value) async {
    if (value == null) {
      await MPPreferences().remove(_accessTokenKey);
      _accessToken = null;
      return;
    }
    await MPPreferences().saveString(_accessTokenKey, value);
    _accessToken = value;
  }

  /// 获取用户 ID：优先内存，其次本地。
  String get userId {
    // return '18';
    if (_userId?.isNotEmpty == true) {
      return _userId!;
    }
    final String id = MPPreferences().getString(_userIdKey);
    if (id.isNotEmpty) {
      _userId = id;
    }
    return id;
  }

  /// 设置用户 ID：null 时清除。
  Future<void> setUserId(String? value) async {
    if (value == null) {
      await MPPreferences().remove(_userIdKey);
      _userId = null;
      return;
    }
    await MPPreferences().saveString(_userIdKey, value);
    _userId = value;
  }

  /// 获取刷新令牌：优先内存，其次本地。
  String get refreshToken {
    if (_refreshToken?.isNotEmpty == true) {
      return _refreshToken!;
    }
    final String token = MPPreferences().getString(_refreshTokenKey);
    if (token.isNotEmpty) {
      _refreshToken = token;
    }
    return token;
  }

  /// 设置刷新令牌：null 时清除。
  Future<void> setRefreshToken(String? value) async {
    if (value == null) {
      await MPPreferences().remove(_refreshTokenKey);
    } else {
      await MPPreferences().saveString(_refreshTokenKey, value);
    }
    _refreshToken = value;
  }

  /// 获取邮箱：优先内存，其次本地。
  String get email {
    if (_email?.isNotEmpty == true) {
      return _email!;
    }
    final String e = MPPreferences().getString(_emailKey);
    if (e.isNotEmpty) {
      _email = e;
    }
    return e;
  }

  /// 设置邮箱：null 时清除。
  Future<void> setEmail(String? value) async {
    if (value == null) {
      await MPPreferences().remove(_emailKey);
    } else {
      await MPPreferences().saveString(_emailKey, value);
    }
    _email = value;
  }

  /// token 过期时间（毫秒时间戳）。
  DateTime get tokenExpiresTime {
    if (_tokenExpiresTime != null) {
      return _tokenExpiresTime!;
    }
    final int? ts = MPPreferences().getInt(_tokenExpiresTimeKey);
    if (ts == null) {
      _tokenExpiresTime = DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      _tokenExpiresTime = DateTime.fromMillisecondsSinceEpoch(ts);
    }
    return _tokenExpiresTime!;
  }

  /// 设置 token 过期时间（秒）。
  Future<void> setTokenExpiresTime(int value) async {
    final int timestamp = MPTimeUtils.unixMillisecondsWithOffset(Duration(seconds: value - 2));
    await MPPreferences().saveInt(_tokenExpiresTimeKey, timestamp);
    _tokenExpiresTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// 清除 token 过期时间。
  Future<void> clearTokenExpiresTime() async {
    await MPPreferences().remove(_tokenExpiresTimeKey);
    _tokenExpiresTime = null;
  }

  /// 清空用户信息与登录会话（登出）。
  Future<void> clear() async {
    await setAccessToken(null);
    await setUserId(null);
    await setRefreshToken(null);
    await setEmail(null);
    await clearTokenExpiresTime();
    name = null;
    _accessToken = null;
    _userId = null;
    _refreshToken = null;
    _email = null;
    _tokenExpiresTime = null;
  }
}
