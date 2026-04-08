import '../utils/mp_preferences.dart';

/// 上次成功连接并持久化到本地的 BLE 设备（仅 [remoteId] + [displayName]）。
class MPLastBleDeviceRecord {
  /// 创建记录。
  const MPLastBleDeviceRecord({required this.remoteId, required this.displayName});

  /// [BluetoothDevice.remoteId] 字符串。
  final String remoteId;

  /// 列表展示名（与广播名或用户可见名一致）。
  final String displayName;
}

/// BLE 相关持久化。
class MPBlePreferences {
  MPBlePreferences._();

  static final MPBlePreferences instance = MPBlePreferences._();

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
}

