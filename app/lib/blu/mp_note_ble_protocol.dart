library;

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
}

/// `e2c1a305` 文件流分帧常量（与 `ble/note_ble_transport.dart` 及 [MPNoteBleFilePayloadAssembler] 一致）。
abstract class MPNoteBleFileTransferConstants {
  /// 单块 `[Seq 4B][Opus 480B]` 总长。
  static const int notifyChunkBytes = 484;

  /// Seq 前缀长度。
  static const int seqPrefixBytes = 4;

  /// 剥离 Seq 后的 Opus 帧长。
  static const int opusFrameBytes = 480;
}

/// 录音控制报文布局（`ble/doc/ble-api-documentation.md`「录音控制协议详解」）。
///
/// **Cmd / Op 分离**：APP 下发 `[0x01,0,0]` 表示在 **command** 上发起开始录音；303 成功帧形如
/// `[Cmd=0x01][Op=0x01][RecordState][Mode][FileName…]` — 前两字节**数值均为** `0x01`，但分别是 **Cmd**
/// 与 **Op**（「开始录音」操作回显），**第二字节不是「再发一次开始录音指令」**，也不是泛化的「成功码」；
/// 偏移 2 为 **RecordState**，偏移 3 为 **Mode**。
abstract class MPNoteBleRecordingWire {
  /// 开始录音链路的 **Cmd**（APP 写 command 的首字节 / 303 成功响应偏移 0）。
  static const int cmdRecordingStart = 0x01;

  /// 停止录音链路的 **Cmd**（APP 写 command 的首字节 / 303 停止响应偏移 0）。
  static const int cmdRecordingStop = 0x02;

  /// 303 开始录音成功响应偏移 1：**Op**，`0x01` = 开始录音分支回显。
  static const int opStartRecordingAck = 0x01;

  /// APP 停止命令第二字节与 303 停止成功响应偏移 1：**Op**，`0x00` = 结束录音。
  static const int opEndRecording = 0x00;

  /// 303 停止响应偏移 2：**Result**，`0x01` = 成功。
  static const int resultSuccess = 0x01;
}

/// 命令字节（与设备固件协议一致）。
abstract class MPNoteBleCommands {
  /// 与 [MPNoteBleRecordingWire.cmdRecordingStart] 同值：**仅用于**拼 **command** 写帧（开始录音）。
  static const int startRecording = MPNoteBleRecordingWire.cmdRecordingStart;

  /// 与 [MPNoteBleRecordingWire.cmdRecordingStop] 同值：**仅用于**拼 **command** 写帧（停止录音）。
  static const int stopRecording = MPNoteBleRecordingWire.cmdRecordingStop;
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

/// 303 **开始录音成功**帧中偏移 3 的 **Mode**（与 `NoteRecordingType` 一致；勿与 Cmd/Op 混淆）。
abstract class MPNoteBleRecordingSessionModes {
  /// 普通 / memory 长录音（文档称 Normal）。
  static const int memory = 0x00;

  /// 备忘录短录音（Memo）。
  static const int memo = 0x01;
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
