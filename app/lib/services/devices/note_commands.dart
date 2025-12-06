/// Note 设备 BLE 协议定义
/// 包含 UUID、命令常量、枚举类型等

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Note 设备 UUID 定义
/// Service UUID: e2c1a300-7f4b-5e9d-bc23-1a2f3e4d5c6b
/// Characteristic UUIDs: e2c1a301~e2c1a306
class NoteUUIDs {
  /// BLE Service UUID
  static final service = Uuid.parse("78563400-ecf0-89b1-c845-2b9e631f4d7a");

  /// 音频实时数据特征 (设备→APP)
  static final audioData = Uuid.parse("78563401-ecf0-89b1-c845-2b9e631f4d7a");

  /// 命令下行特征 (APP→设备)
  static final command = Uuid.parse("78563402-ecf0-89b1-c845-2b9e631f4d7a");

  /// 设备响应/通知特征 (设备→APP)
  static final response = Uuid.parse("78563403-ecf0-89b1-c845-2b9e631f4d7a");

  /// OTA 文件下载特征 (APP→设备)
  static final otaFile = Uuid.parse("78563404-ecf0-89b1-c845-2b9e631f4d7a");

  /// 录音文件/数据流特征 (设备→APP)
  static final recordFile = Uuid.parse("78563405-ecf0-89b1-c845-2b9e631f4d7a");

  /// 日志文件/数据流特征 (设备→APP)
  static final logFile = Uuid.parse("78563406-ecf0-89b1-c845-2b9e631f4d7a");
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
  /// 命令: 0x05 | 文件名长度 | 文件名
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

/// 录音模式枚举
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
