/// Note 设备 BLE 协议定义
/// 包含 UUID、命令常量、枚举类型等
library;

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Note 设备 UUID 定义
/// Service UUID: e2c1a300-7f4b-5e9d-bc23-1a2f3e4d5c6b
/// Characteristic UUIDs: e2c1a301~e2c1a306
class NoteUUIDs {
  //  78563400-ecf0-89b1-c845-2b9e631f4d7a
  static const uuidPre = "e2c1a30";//"7856340";
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

/// Note 设备命令定义
/// 所有命令值均为十六进制
class NoteCommands {
  // ============ 录音控制 ============

  /// 开始录音
  /// 命令: 0x01
  /// 响应: 0x01 0x01(成功) / 0x01 0x00 0x01(设备正在录音)
  static const int startRecording = 0x01;

  /// 停止录音
  /// 命令: 0x02
  /// 响应: 0x02 0x00 0x01(成功,有文件) / 0x02 0x00 0x02(文件为空)
  static const int stopRecording = 0x02;

  /// 设置录音模式
  /// 命令: 0x0D + 模式值
  /// 模式: 0x10=边录边传, 0x01=仅录音
  static const int setRecordingMode = 0x0D;

  // ============ 文件管理 ============

  /// 获取文件列表
  /// 命令: 0x03
  /// 响应: 0x03 | 文件数量 | 文件信息列表
  static const int getFileList = 0x03;

  /// 上传文件
  /// 命令: 0x04 | 文件名长度 | 文件名
  /// 响应: 0x04 0x01(开始) / 0x04 0x02(完成)
  static const int uploadFile = 0x04;

  /// 删除文件
  /// 命令: 0x05 | 文件索引(FILE_ID)
  /// 返回: 0x05 0x01(成功) / 0x05 0x00(失败)
  static const int deleteFile = 0x05;

  // ============ 设备管理 ============

  /// 设备重启
  /// 命令: 0x09
  static const int reboot = 0x09;

  /// 设备绑定
  /// 命令: 0x0B + 绑定状态
  /// 绑定状态: 0x01=绑定, 0x00=解绑
  static const int bindDevice = 0x0B;

  /// 查询电池电量
  /// 命令: 0xE1
  /// 响应: 0xE1 | 电量百分比(0-100)
  static const int queryBattery = 0xE1;

  /// 查询固件版本
  /// 命令: 0xE3
  /// 响应: 0xE3 | 9字节版本号
  static const int queryVersion = 0xE3;

  /// U盘模式控制
  /// 命令: 0xE4 + 模式值
  /// 模式: 0x01=开启, 0x00=关闭
  static const int usbMode = 0xE4;

  /// RTC 时间同步
  /// 命令: 0xE5 + 4字节时间戳
  static const int syncRTC = 0xE5;

  /// 查询存储空间
  /// 命令: 0xE8
  /// 响应: 0xE8 | len | 状态 | 已用KB/总KB
  static const int queryStorage = 0xE8;

  /// 恢复出厂设置
  /// 命令: 0xE9 + 参数
  /// 参数: 0x00=保留录音文件, 0xFF=删除录音文件
  /// 响应: 0xE9 0x01(成功)
  static const int factoryReset = 0xE9;

  // ============ 音频传输协议 V1.0 ============

  /// 补传请求命令 (APP→设备)
  /// 格式: [Cmd 0x20] [FileNameLen 1B] [FileName] [StartSeq 4B] [EndSeq 4B]
  static const int retransmitRequest = 0x20;

  /// 补传错误 - 文件不存在
  static const int retransmitErrorNoFile = 0x21;

  /// 补传错误 - 序号范围无效
  static const int retransmitErrorBadRange = 0x22;

  // ============ OTA 升级 ============

  /// OTA 控制命令
  /// 命令: 0xF6 + 子命令
  /// 子命令: 0x01=准备OTA, 0x02=完成OTA
  static const int otaControl = 0xF6;

  /// 进入 OTA 模式
  /// 命令: 0xE6 + 模块类型
  /// 模块: 0x03=8711模块, 0x02=3085模块
  static const int otaEnter = 0xE6;

  // ============ WiFi 相关(未实现) ============

  /// WiFi 模式控制
  /// 命令: 0xF3 + 模式值
  /// 模式: 0x01=开启, 0x00=关闭
  static const int wifiMode = 0xF3;
}

/// 录音模式枚举（上行行为，0x0D 命令的参数）
///
/// 注意：本枚举控制"录音的同时是否实时通过 a301 推流"，
/// 与"录音业务类型 normal/memo"是两个独立维度。后者见 [NoteRecordingType]。
enum NoteRecordingMode {
  /// 仅录音模式(0x01)
  /// 音频数据仅保存在设备,不实时上传
  recordOnly(0x01),

  /// 边录边传模式(0x10)
  /// 音频数据同时保存和实时上传到APP
  recordAndUpload(0x10);

  final int value;
  const NoteRecordingMode(this.value);

  /// 从值创建枚举
  static NoteRecordingMode fromValue(int value) {
    switch (value) {
      case 0x01:
        return NoteRecordingMode.recordOnly;
      case 0x10:
        return NoteRecordingMode.recordAndUpload;
      default:
        return NoteRecordingMode.recordOnly;
    }
  }

  /// 获取描述
  String get description {
    switch (this) {
      case NoteRecordingMode.recordOnly:
        return '仅录音';
      case NoteRecordingMode.recordAndUpload:
        return '边录边传';
    }
  }
}

/// 录音业务类型枚举（mode 字节）
///
/// 由设备按键决定，APP 不可指定。出现在 0x01 开始录音成功通知、0x00 录音状态查询响应、
/// split 续录通知三处。见 docs/note-recording-modes-20260427.md。
enum NoteRecordingType {
  /// 普通录音 (mode=0x00)，长按 2.5s 触发
  normal(0x00),

  /// 备忘录/灵感速记 (mode=0x01)，关闭录音状态下短按触发，固定 ≤60s
  memo(0x01);

  final int value;
  const NoteRecordingType(this.value);

  static NoteRecordingType fromValue(int value) =>
      value == 0x01 ? NoteRecordingType.memo : NoteRecordingType.normal;

  String get description => this == NoteRecordingType.memo ? 'Memo' : 'Normal';
}

/// OTA 模块类型枚举
enum NoteOtaModule {
  /// 3085 模块(0x01)
  /// WiFi/蓝牙模块
  module3085(0x01),

  /// 8711 模块(0x04)
  /// 主控模块
  module8711(0x04);

  final int value;
  const NoteOtaModule(this.value);

  /// 从值创建枚举
  static NoteOtaModule fromValue(int value) {
    switch (value) {
      case 0x01:
        return NoteOtaModule.module3085;
      case 0x04:
        return NoteOtaModule.module8711;
      default:
        return NoteOtaModule.module8711;
    }
  }

  /// 获取模块名称
  String get moduleName {
    switch (this) {
      case NoteOtaModule.module3085:
        return '3085';
      case NoteOtaModule.module8711:
        return '8711';
    }
  }

  /// 获取描述
  String get description {
    switch (this) {
      case NoteOtaModule.module3085:
        return 'WiFi/蓝牙模块';
      case NoteOtaModule.module8711:
        return '主控模块';
    }
  }
}

/// 音频包协议常量 (V1.0)
///
/// 每个 BLE notification 格式: [Seq 4B] [Flag 1B] [Data 变长]
/// Seq: 音频帧序号 (每文件从 0 开始递增)
/// Flag: 高4位=分包总数(0=不分包), 低4位=当前包序号
/// Data: Opus 音频数据片段
class AudioPacketConstants {
  /// Opus CBR 压缩帧固定大小 (字节)
  static const int frameSize = 480;

  /// 包头大小 (含 Flag): 4B Seq + 1B Flag
  static const int headerSizeWithFlag = 5;

  /// 包头大小 (无 Flag): 仅 4B Seq
  /// 当 MTU 足够大不需要分包时，固件可能省略 Flag 字节
  static const int headerSizeSeqOnly = 4;

  /// Flag 高4位掩码 — 分包总数
  static const int flagTotalMask = 0xF0;

  /// Flag 低4位掩码 — 当前包序号
  static const int flagIndexMask = 0x0F;

  /// 最大分包数 (Flag 高4位最大值)
  static const int maxSubPackets = 15;

  /// 分包重组超时时间 (毫秒)
  static const int reassemblyTimeoutMs = 200;

  /// 解析 Flag 获取分包总数 (0=不分包)
  static int getFlagTotal(int flag) => (flag & flagTotalMask) >> 4;

  /// 解析 Flag 获取当前包序号 (0~15)
  static int getFlagIndex(int flag) => flag & flagIndexMask;

  /// 判断是否为分包
  static bool isSplit(int flag) => getFlagTotal(flag) > 0;

  /// 解析 4 字节 Seq (Big-Endian)
  /// [bytes] 数据源, [offset] 起始偏移量
  static int parseSeq(List<int> bytes, [int offset = 0]) {
    return (bytes[offset] << 24) | (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) | bytes[offset + 3];
  }
}

/// 录音状态值常量
class RecordStatusValues {
  /// 未录音
  static const int idle = 0x00;

  /// 录音中
  static const int recording = 0x01;
}

/// 录音状态查询结果
class RecordStatus {
  /// 录音状态: 0x00=未录音, 0x01=录音中
  final int status;

  /// 当前录音文件名 (未录音时为空)
  final String fileName;

  RecordStatus({required this.status, required this.fileName});

  /// 是否正在录音
  bool get isRecording => status == RecordStatusValues.recording;

  @override
  String toString() => 'RecordStatus(status=0x${status.toRadixString(16)}, '
      'fileName=$fileName, isRecording=$isRecording)';
}

/// 命令响应结果
class CommandResponse {
  final bool success;
  final List<int> data;
  final String? errorMessage;

  CommandResponse({
    required this.success,
    required this.data,
    this.errorMessage,
  });

  CommandResponse.success(this.data)
      : success = true,
        errorMessage = null;

  CommandResponse.error(String message)
      : success = false,
        data = [],
        errorMessage = message;
}
