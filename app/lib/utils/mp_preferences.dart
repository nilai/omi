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

  /// 用户唯一标识。
  String get uid => getString('uid') ?? '';
  set uid(String value) => saveString('uid', value);

  /// 鉴权 token。
  String get authToken => getString('authToken') ?? '';
  set authToken(String value) => saveString('authToken', value);

  /// token 过期时间（毫秒时间戳）。
  int get tokenExpirationTime => getInt('tokenExpirationTime') ?? 0;
  set tokenExpirationTime(int value) => saveInt('tokenExpirationTime', value);

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

/// 兼容旧调用：保留历史类名，内部复用 MPPreferences。
class SharedPreferencesUtil extends MPPreferences {
  static final SharedPreferencesUtil _instance = SharedPreferencesUtil._internal();

  factory SharedPreferencesUtil() => _instance;

  SharedPreferencesUtil._internal() : super._internal();
}
