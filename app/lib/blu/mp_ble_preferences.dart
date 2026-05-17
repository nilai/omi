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

  static const String _interruptedRecordingRemoteIdKey = 'mp_ble_interrupted_recording_remote_id';
  static const String _interruptedRecordingFileNameKey = 'mp_ble_interrupted_recording_file_name';
  static const String _interruptedRecordingLocalPathKey = 'mp_ble_interrupted_recording_local_path';
  static const String _interruptedRecordingModeKey = 'mp_ble_interrupted_recording_mode';

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

  /// 断连或冷启动前持久化的「设备仍在录音、待续传」会话。
  MPBleInterruptedRecordingRecord? readInterruptedRecording() {
    final String remoteId = MPPreferences().getString(_interruptedRecordingRemoteIdKey);
    if (remoteId.isEmpty) {
      return null;
    }
    final String fileName = MPPreferences().getString(_interruptedRecordingFileNameKey);
    final String localPath = MPPreferences().getString(_interruptedRecordingLocalPathKey);
    if (fileName.isEmpty || localPath.isEmpty) {
      return null;
    }
    final int? mode = MPPreferences().getInt(_interruptedRecordingModeKey);
    return MPBleInterruptedRecordingRecord(
      remoteId: remoteId,
      activeFileName: fileName,
      localOpusPath: localPath,
      sessionModeByte: mode,
    );
  }

  /// 保存待重连续传的录音会话（BLE 链路丢失或 App 被杀前调用）。
  Future<void> saveInterruptedRecording(MPBleInterruptedRecordingRecord record) async {
    await MPPreferences().saveString(_interruptedRecordingRemoteIdKey, record.remoteId);
    await MPPreferences().saveString(_interruptedRecordingFileNameKey, record.activeFileName);
    await MPPreferences().saveString(_interruptedRecordingLocalPathKey, record.localOpusPath);
    if (record.sessionModeByte != null) {
      await MPPreferences().saveInt(_interruptedRecordingModeKey, record.sessionModeByte!);
    } else {
      await MPPreferences().remove(_interruptedRecordingModeKey);
    }
  }

  /// 清除待续传会话（正常停止录音、用户断开 BLE、续传成功后）。
  Future<void> clearInterruptedRecording() async {
    await MPPreferences().remove(_interruptedRecordingRemoteIdKey);
    await MPPreferences().remove(_interruptedRecordingFileNameKey);
    await MPPreferences().remove(_interruptedRecordingLocalPathKey);
    await MPPreferences().remove(_interruptedRecordingModeKey);
  }
}

/// 断连 / 冷启动后待恢复的 MemoPin 实时录音会话。
class MPBleInterruptedRecordingRecord {
  /// 创建记录。
  const MPBleInterruptedRecordingRecord({
    required this.remoteId,
    required this.activeFileName,
    required this.localOpusPath,
    this.sessionModeByte,
  });

  /// 设备 [BleTransport.deviceId]。
  final String remoteId;

  /// 设备 303 上报的 `.opus` 文件名。
  final String activeFileName;

  /// 手机沙盒内已写入的裸 Opus 文件路径。
  final String localOpusPath;

  /// 录音 mode 字节；未知为 `null`。
  final int? sessionModeByte;
}

