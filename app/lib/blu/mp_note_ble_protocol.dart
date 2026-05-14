library;

import 'dart:convert';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// MemoPin / AI_NOTE 设备 BLE 协议常量（与 `ble/note_commands.dart` 对齐，供 `BleTransport` GATT 访问使用）。

/// Note 服务与特征 UUID（128-bit 字符串，与 `flutter_blue_plus` 的 `str128` 比较一致）。
abstract class MPNoteBleUUIDs {
  //  78563400-ecf0-89b1-c845-2b9e631f4d7a
  static const uuidPre = "e2c1a30"; //"7856340";
  /// BLE Service UUID
  static final service = Uuid.parse("${uuidPre}0-7f4b-5e9d-bc23-1a2f3e4d5c6b");

  /// 音频实时数据特征 (设备→APP)
  static final audioData = Uuid.parse("${uuidPre}1-7f4b-5e9d-bc23-1a2f3e4d5c6b");

  /// 命令下行特征 (APP→设备)
  static final command = Uuid.parse("${uuidPre}2-7f4b-5e9d-bc23-1a2f3e4d5c6b");

  /// 设备响应/通知特征 (设备→APP)
  static final response = Uuid.parse("${uuidPre}3-7f4b-5e9d-bc23-1a2f3e4d5c6b");

  /// OTA 文件下载特征 (APP→设备)
  static final otaFile = Uuid.parse("${uuidPre}4-7f4b-5e9d-bc23-1a2f3e4d5c6b");

  /// 录音文件/数据流特征 (设备→APP)
  static final recordFile = Uuid.parse("${uuidPre}5-7f4b-5e9d-bc23-1a2f3e4d5c6b");

  /// 日志文件/数据流特征 (设备→APP)
  static final logFile = Uuid.parse("${uuidPre}6-7f4b-5e9d-bc23-1a2f3e4d5c6b");

  /// 录音状态查询特征 (只读)
  /// 格式: [Status 1B] [FileNameLen 1B] [FileName 变长]
  static final recordStatus = Uuid.parse("e2c1a310-7f4b-5e9d-bc23-1a2f3e4d5c6b");
}

/// 命令字节（与设备固件协议一致）。
abstract class MPNoteBleCommands {
  static const int startRecording = 0x01;
  static const int stopRecording = 0x02;
  static const int getFileList = 0x03;
  static const int uploadFile = 0x04;
  static const int deleteFile = 0x05;

  /// 推流策略：`0x01` 仅录音，`0x10` 边录边传（见 BLE 文档 `0x0D`）。
  static const int setRecordingTransportMode = 0x0D;

  /// 音频帧补传（Seq 为 **大端**）。
  static const int retransmitAudio = 0x20;
  static const int queryBattery = 0xE1;
}

/// `0x0D` 录音上行模式（与 `ble-api-documentation.md` 一致）。
abstract class MPNoteBleRecordingTransportModes {
  static const int recordOnly = 0x01;
  static const int recordAndStream = 0x10;
}

/// 设备 `0x01` 响应中的业务类型字节（与 `NoteRecordingType` 一致）。
abstract class MPNoteBleRecordingSessionModes {
  /// 普通 / memory 长录音（文档称 Normal）。
  static const int memory = 0x00;

  /// 备忘录短录音（Memo）。
  static const int memo = 0x01;
}

/// `e2c1a310` 主动读或通知解析结果（`0x00` 未录音 / `0x01` 录音中）。
class MPBleMemopinRecordStatus310 {
  /// 创建解析结果。
  const MPBleMemopinRecordStatus310({required this.isRecording, this.activeFileName});

  /// 是否正在录音。
  final bool isRecording;

  /// 当前录音文件名（未录音时多为空）。
  final String? activeFileName;

  /// 从特征原始字节解析；非法或空载荷视为未录音。
  static MPBleMemopinRecordStatus310 parse(List<int> raw) {
    if (raw.isEmpty) {
      return const MPBleMemopinRecordStatus310(isRecording: false);
    }
    final int status = raw[0];
    final bool rec = status == 0x01;
    if (raw.length < 2) {
      return MPBleMemopinRecordStatus310(isRecording: rec);
    }
    final int nameLen = raw[1] & 0xff;
    if (nameLen <= 0 || raw.length < 2 + nameLen) {
      return MPBleMemopinRecordStatus310(isRecording: rec);
    }
    try {
      final String name = utf8.decode(raw.sublist(2, 2 + nameLen));
      return MPBleMemopinRecordStatus310(isRecording: rec, activeFileName: name);
    } catch (_) {
      return MPBleMemopinRecordStatus310(isRecording: rec);
    }
  }
}

/// 主动 `0x01` 开始录音成功后的解析结果（含业务 mode 与文件名）。
class MPBleRecordingStartInfo {
  /// 创建开始录音解析结果。
  const MPBleRecordingStartInfo({required this.modeByte, required this.fileName});

  /// `0x00` memory / normal，`0x01` memo。
  final int modeByte;

  /// 设备分配的文件名（通常 `.opus`）。
  final String fileName;

  /// 从响应字节解析；`null` 表示失败或已在录音等。
  static MPBleRecordingStartInfo? tryParse(List<int> r) {
    if (r.length >= 5 && r[0] == MPNoteBleCommands.startRecording && r[1] == 0x01) {
      try {
        final String name = utf8.decode(r.sublist(4));
        if (name.isEmpty) {
          return null;
        }
        return MPBleRecordingStartInfo(modeByte: r[3] & 0xff, fileName: name);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

/// 通过 `0xE1` 读取电量时的解析结果。
class MPNoteBatteryReading {
  /// 创建电量读取结果。
  const MPNoteBatteryReading({required this.percent, this.chargingState});

  /// 电量 0–100。
  final int percent;

  /// 充电状态（若固件返回）：1=充电中，2=未充电，3=已充满。
  final int? chargingState;
}
