import 'package:shared_preferences/shared_preferences.dart';

import '../login/mp_user.dart';

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
  String getString(String key) {
    return _preferences?.getString(key) ?? '';
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

/// 上次成功连接并持久化到本地的 BLE 设备（仅 [remoteId] + [displayName]）。
class MPLastBleDeviceRecord {
  /// 创建记录。
  const MPLastBleDeviceRecord({required this.remoteId, required this.displayName});

  /// [BluetoothDevice.remoteId] 字符串。
  final String remoteId;

  /// 列表展示名（与广播名或用户可见名一致）。
  final String displayName;
}

///
class SharedPreferencesUtil extends MPPreferences {
  static final SharedPreferencesUtil _instance = SharedPreferencesUtil._internal();

  factory SharedPreferencesUtil() => _instance;

  SharedPreferencesUtil._internal() : super._internal();

  static const String _lastBleRemoteIdKey = 'mp_last_ble_remote_id';
  static const String _lastBleDisplayNameKey = 'mp_last_ble_display_name';

  /// 读取上次连接成功的 BLE 设备；未记录时返回 `null`。
  MPLastBleDeviceRecord? readLastConnectedBleDevice() {
    final String id = MPPreferences().getString(_lastBleRemoteIdKey);
    if (id.isEmpty) {
      return null;
    }
    final String name = MPPreferences().getString(_lastBleDisplayNameKey);
    return MPLastBleDeviceRecord(remoteId: id, displayName: name.isEmpty ? 'MemoPin' : name);
  }

  /// 持久化上次成功连接的 BLE 设备（连接成功后调用）。
  Future<void> setLastConnectedBleDevice({required String remoteId, required String displayName}) async {
    await MPPreferences().saveString(_lastBleRemoteIdKey, remoteId);
    await MPPreferences().saveString(_lastBleDisplayNameKey, displayName);
  }

  /// 清除上次连接的 BLE 设备记录（例如登出或用户解绑时调用）。
  Future<void> clearLastConnectedBleDevice() async {
    await MPPreferences().remove(_lastBleRemoteIdKey);
    await MPPreferences().remove(_lastBleDisplayNameKey);
  }

  /// 清除所有本地数据。
  static Future<void> clearAll() async {
    await MPUser.instance.clearSession();
    await _instance.clearLastConnectedBleDevice();
  }
}
