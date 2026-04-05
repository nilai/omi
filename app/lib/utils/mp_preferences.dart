import 'package:shared_preferences/shared_preferences.dart';

/// 应用本地偏好存储（核心精简版）。
class MPPreferences {
  static final MPPreferences _instance = MPPreferences._internal();
  static SharedPreferences? _preferences;

  factory MPPreferences() => _instance;

  MPPreferences._internal();

  /// 初始化 SharedPreferences。
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  /// 写入字符串。
  Future<bool> saveString(String key, String value) async {
    return await _preferences?.setString(key, value) ?? false;
  }

  /// 读取字符串。
  String? getString(String key) {
    return _preferences?.getString(key);
  }

  /// 写入整型。
  Future<bool> saveInt(String key, int value) async {
    return await _preferences?.setInt(key, value) ?? false;
  }

  /// 读取整型。
  int? getInt(String key) {
    return _preferences?.getInt(key);
  }

  /// 写入布尔值。
  Future<bool> saveBool(String key, bool value) async {
    return await _preferences?.setBool(key, value) ?? false;
  }

  /// 读取布尔值。
  bool? getBool(String key) {
    return _preferences?.getBool(key);
  }

  /// 写入双精度浮点数。
  Future<bool> saveDouble(String key, double value) async {
    return await _preferences?.setDouble(key, value) ?? false;
  }

  /// 读取双精度浮点数。
  double? getDouble(String key) {
    return _preferences?.getDouble(key);
  }

  /// 写入字符串数组。
  Future<bool> saveStringList(String key, List<String> value) async {
    return await _preferences?.setStringList(key, value) ?? false;
  }

  /// 读取字符串数组。
  List<String>? getStringList(String key) {
    return _preferences?.getStringList(key);
  }

  /// 删除指定 key。
  Future<bool> remove(String key) async {
    return await _preferences?.remove(key) ?? false;
  }

  /// 清空全部偏好数据。
  Future<bool> clear() async {
    return await _preferences?.clear() ?? false;
  }
}

/// 
class SharedPreferencesUtil extends MPPreferences {
  static final SharedPreferencesUtil _instance = SharedPreferencesUtil._internal();

  factory SharedPreferencesUtil() => _instance;

  SharedPreferencesUtil._internal() : super._internal();

  static const String _accessTokenKey = 'mp_accessToken';
  static const String _refreshTokenKey = 'mp_refreshToken';
  static const String _emailKey = 'mp_email';
  static const String _tokenExpiresTimeKey = 'mp_tokenExpiresTime';

  String? _accessToken;
  String? _refreshToken;
  String? _email;
  /// token 过期时间（毫秒时间戳）。
  DateTime? _tokenExpiresTime;


  /// 获取访问令牌：优先取内存中的私有属性，其次取本地存储。
  String? get accessToken => _accessToken ?? MPPreferences().getString(_accessTokenKey);

  /// 设置访问令牌：写入本地并更新内存；登出时 `value == null` 会同时清除 [uid]。
  /// 传入 [uid] 时一并持久化（仅刷 token 可不传，保留原 uid）。
  Future<void> setAccessToken(String? value, {String? uid}) async {
    if (value == null) {
      await MPPreferences().remove(_accessTokenKey);
      _accessToken = null;
    } else {
      await MPPreferences().saveString(_accessTokenKey, value);
      _accessToken = value;
    }
  }


  /// 获取刷新令牌：优先取内存中的私有属性，其次取本地存储。
  String? get refreshToken => _refreshToken ?? MPPreferences().getString(_refreshTokenKey);

  /// 设置刷新令牌：优先写入本地存储，再更新内存中的私有属性。
  Future<void> setRefreshToken(String? value) async {
    if (value == null) {
      await MPPreferences().remove(_refreshTokenKey);
    } else {
      await MPPreferences().saveString(_refreshTokenKey, value);
    }
    _refreshToken = value;
  }

  /// 获取邮箱：优先取内存中的私有属性，其次取本地存储。
  String? get email => _email ?? MPPreferences().getString(_emailKey);

  /// 设置邮箱：优先写入本地存储，再更新内存中的私有属性。
  Future<void> setEmail(String? value) async {
    if (value == null) {
      await MPPreferences().remove(_emailKey);
    } else {
      await MPPreferences().saveString(_emailKey, value);
    }
    _email = value;
  }

  /// 获取 token 过期时间：优先取内存中的私有属性，其次取本地存储。
  DateTime? get tokenExpiresTime => _tokenExpiresTime ?? DateTime.fromMillisecondsSinceEpoch(MPPreferences().getInt(_tokenExpiresTimeKey) ?? 0);

  /// 设置 token 过期时间：优先写入本地存储，再更新内存中的私有属性。
  Future<void> setTokenExpiresTime(int value) async {
    final int timestamp = DateTime.now().add(Duration(seconds: value - 2)).millisecondsSinceEpoch;
    await MPPreferences().saveInt(_tokenExpiresTimeKey, timestamp);
    _tokenExpiresTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// 清除本地记录的 token 过期时间（登出时使用）。
  Future<void> clearTokenExpiresTime() async {
    await MPPreferences().remove(_tokenExpiresTimeKey);
    _tokenExpiresTime = null;
  }
}
