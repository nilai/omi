/// MemoPin / AI_NOTE 设备 BLE 协议常量（与 `ble/note_commands.dart` 对齐，供 `BleTransport` GATT 访问使用）。
library;

/// Note 服务与特征 UUID（128-bit 字符串，与 `flutter_blue_plus` 的 `str128` 比较一致）。
abstract class MPNoteBleUUIDs {
  static const String uuidPrefix = 'e2c1a30';

  /// 主服务
  static const String service = '$uuidPrefix' '0-7f4b-5e9d-bc23-1a2f3e4d5c6b';

  /// 音频实时数据（设备→APP）
  static const String audioData = '$uuidPrefix' '1-7f4b-5e9d-bc23-1a2f3e4d5c6b';

  /// 命令下行（APP→设备）
  static const String command = '$uuidPrefix' '2-7f4b-5e9d-bc23-1a2f3e4d5c6b';

  /// 响应 / 通知（设备→APP）
  static const String response = '$uuidPrefix' '3-7f4b-5e9d-bc23-1a2f3e4d5c6b';

  /// 录音文件数据流（设备→APP），导出文件时走此特征通知
  static const String recordFile = '$uuidPrefix' '5-7f4b-5e9d-bc23-1a2f3e4d5c6b';

  /// 日志文件数据流（设备→APP）
  static const String logFile = '$uuidPrefix' '6-7f4b-5e9d-bc23-1a2f3e4d5c6b';

  /// 录音状态（只读）
  static const String recordStatus = 'e2c1a310-7f4b-5e9d-bc23-1a2f3e4d5c6b';
}

/// 命令字节（与设备固件协议一致）。
abstract class MPNoteBleCommands {
  static const int getFileList = 0x03;
  static const int uploadFile = 0x04;
  static const int deleteFile = 0x05;
  static const int queryBattery = 0xE1;
}

/// 通过 `0xE1` 读取电量时的解析结果。
class MPNoteBatteryReading {
  /// 创建电量读取结果。
  const MPNoteBatteryReading({
    required this.percent,
    this.chargingState,
  });

  /// 电量 0–100。
  final int percent;

  /// 充电状态（若固件返回）：1=充电中，2=未充电，3=已充满。
  final int? chargingState;
}
