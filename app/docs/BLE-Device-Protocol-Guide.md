# BLE 设备协议技术文档

> 本文档基于 Omi Flutter App 的实际实现，总结各类 BLE 可穿戴设备的通信协议规范。

---

## 目录

1. [协议架构总览](#协议架构总览)
2. [MemoPin/Omi 协议](#memopinomi-协议)
3. [PLAUD NotePin 协议](#plaud-notepin-协议)
4. [Friend Pendant 协议](#friend-pendant-协议)
5. [协议对比与最佳实践](#协议对比与最佳实践)
6. [文件索引](#文件索引)

---

## 协议架构总览


### 设备类型枚举

```dart
// lib/backend/schema/bt_device/bt_device.dart

enum DeviceType {
    omi,              // MemoPin (Seeed Xiao BLE Sense)
    openglass,        // OpenGlass with image streaming
    frame,            // Brilliant Labs Frame
    appleWatch,       // Apple Watch (watchOS)
    plaud,            // PLAUD NotePin
    bee,              // Bee recorder
    fieldy,           // Fieldy/Compass
    aiNote,           // AI Note with new protocol
    friendPendant,    // Friend Pendant with LC3 codec
}
```

### 音频编码枚举

```dart
enum BleAudioCodec {
    pcm16,        // PCM 16-bit @ 16kHz, 160字节帧, 100 fps
    pcm8,         // PCM 8-bit @ 16kHz, 80字节帧, 100 fps
    mulaw16,      // μ-law 16-bit
    mulaw8,       // μ-law 8-bit
    opus,         // Opus @ 16kHz, 80字节帧, 100 fps
    opusFS320,    // Opus @ 16kHz, 160字节帧, 50 fps
    aac,          // AAC (变长帧)
    lc3FS1030,    // LC3 @ 16kHz, 30字节帧, 100 fps
    unknown;

    int getFrameSize() => this == BleAudioCodec.opusFS320 ? 320 : 160;
    int getFramesPerSecond() => this == BleAudioCodec.opusFS320 ? 50 : 100;
}
```

### 设备连接工厂

```dart
// lib/services/devices/device_connection.dart

class DeviceConnectionFactory {
    static DeviceConnection? create(BtDevice device) {
        switch (device.type) {
            case DeviceType.omi:
            case DeviceType.openglass:
                return OmiDeviceConnection(device, transport);
            case DeviceType.plaud:
                return PlaudDeviceConnection(device, transport);
            case DeviceType.friendPendant:
                return FriendPendantDeviceConnection(device, transport);
            // ...
        }
    }
}
```

### 传输层抽象

```dart
// lib/services/devices/transports/

abstract class DeviceTransport {
    Stream<DeviceTransportState> get connectionStateStream;

    Future<void> connect();
    Future<void> disconnect();
    Future<bool> isConnected();
    Future<bool> ping();

    Future<List<int>> readCharacteristic(String serviceUuid, String charUuid);
    Future<void> writeCharacteristic(String serviceUuid, String charUuid, List<int> data);
    Stream<List<int>> getCharacteristicStream(String serviceUuid, String charUuid);
}
```

**传输层实现：**
- `BleTransport` - flutter_blue_plus 封装
- `WatchTransport` - watchOS Connectivity API
- `FrameTransport` - Brilliant Labs Frame SDK
- `NoteBleTransport` - flutter_reactive_ble 封装

---

## MemoPin/Omi 协议

### 设备概述

| 项目 | 值 |
|-----|---|
| **硬件平台** | Seeed Xiao BLE Sense (nRF52840) |
| **支持编码** | PCM16, PCM8, Opus, OpusFS320 |
| **默认编码** | Opus (80字节帧, 100fps) |
| **特色功能** | 按钮、存储、加速度计、图像流(OpenGlass)、麦克风增益调节 |

### BLE Service UUID 定义

```dart
// lib/services/devices/models.dart

// ═══════════════════════════════════════════════════════════════
// 主服务
// ═══════════════════════════════════════════════════════════════
const String omiServiceUuid = '19b10000-e8f2-537e-4f6c-d104768a1214';

// ═══════════════════════════════════════════════════════════════
// 音频特征
// ═══════════════════════════════════════════════════════════════
const String audioDataStreamCharacteristicUuid = '19b10001-e8f2-537e-4f6c-d104768a1214';
const String audioCodecCharacteristicUuid       = '19b10002-e8f2-537e-4f6c-d104768a1214';

// ═══════════════════════════════════════════════════════════════
// 图像流特征 (OpenGlass)
// ═══════════════════════════════════════════════════════════════
const String imageDataStreamCharacteristicUuid      = '19b10005-e8f2-537e-4f6c-d104768a1214';
const String imageCaptureControlCharacteristicUuid  = '19b10006-e8f2-537e-4f6c-d104768a1214';

// ═══════════════════════════════════════════════════════════════
// 按钮服务
// ═══════════════════════════════════════════════════════════════
const String buttonServiceUuid                  = '23ba7924-0000-1000-7450-346eac492e92';
const String buttonTriggerCharacteristicUuid    = '23ba7925-0000-1000-7450-346eac492e92';

// ═══════════════════════════════════════════════════════════════
// 存储服务
// ═══════════════════════════════════════════════════════════════
const String storageDataStreamServiceUuid       = '30295780-4301-eabd-2904-2849adfeae43';
const String storageDataStreamCharacteristicUuid= '30295781-4301-eabd-2904-2849adfeae43';
const String storageReadControlCharacteristicUuid='30295782-4301-eabd-2904-2849adfeae43';

// ═══════════════════════════════════════════════════════════════
// 加速度计服务
// ═══════════════════════════════════════════════════════════════
const String accelDataStreamServiceUuid         = '32403790-0000-1000-7450-bf445e5829a2';
const String accelDataStreamCharacteristicUuid  = '32403791-0000-1000-7450-bf445e5829a2';

// ═══════════════════════════════════════════════════════════════
// 扬声器/触觉反馈服务
// ═══════════════════════════════════════════════════════════════
const String speakerDataStreamServiceUuid       = 'cab1ab95-2ea5-4f4d-bb56-874b72cfc984';
const String speakerDataStreamCharacteristicUuid= 'cab1ab96-2ea5-4f4d-bb56-874b72cfc984';

// ═══════════════════════════════════════════════════════════════
// 设置服务
// ═══════════════════════════════════════════════════════════════
static const String settingsServiceUuid               = '19b10010-e8f2-537e-4f6c-d104768a1214';
static const String settingsDimRatioCharacteristicUuid= '19b10011-e8f2-537e-4f6c-d104768a1214';
static const String settingsMicGainCharacteristicUuid = '19b10012-e8f2-537e-4f6c-d104768a1214';

// ═══════════════════════════════════════════════════════════════
// 功能服务
// ═══════════════════════════════════════════════════════════════
static const String featuresServiceUuid         = '19b10020-e8f2-537e-4f6c-d104768a1214';
static const String featuresCharacteristicUuid  = '19b10021-e8f2-537e-4f6c-d104768a1214';

// ═══════════════════════════════════════════════════════════════
// 标准电池服务 (BLE Standard)
// ═══════════════════════════════════════════════════════════════
const String batteryServiceUuid                 = '0000180f-0000-1000-8000-00805f9b34fb';
const String batteryLevelCharacteristicUuid     = '00002a19-0000-1000-8000-00805f9b34fb';

// ═══════════════════════════════════════════════════════════════
// 设备信息服务 (BLE Standard)
// ═══════════════════════════════════════════════════════════════
const String deviceInformationServiceUuid       = '0000180a-0000-1000-8000-00805f9b34fb';
const String firmwareRevisionCharacteristicUuid = '00002a26-0000-1000-8000-00805f9b34fb';
const String hardwareRevisionCharacteristicUuid = '00002a27-0000-1000-8000-00805f9b34fb';
const String manufacturerNameCharacteristicUuid = '00002a29-0000-1000-8000-00805f9b34fb';
```

### 服务架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                         MemoPin/Omi                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │ Main Service│    │Button Service│   │Storage Svc  │         │
│  │  19b10000   │    │  23ba7924   │    │  30295780   │         │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘         │
│         │                  │                  │                 │
│  ┌──────┴──────┐    ┌──────┴──────┐    ┌──────┴──────┐         │
│  │Audio Stream │    │Button Trigger│   │Data Stream  │         │
│  │  19b10001   │    │  23ba7925   │    │  30295781   │         │
│  │ (Notify)    │    │ (Notify)    │    │ (Notify)    │         │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
│                                                                  │
│  ┌──────┴──────┐    ┌─────────────┐    ┌─────────────┐         │
│  │Audio Codec  │    │Settings Svc │    │Features Svc │         │
│  │  19b10002   │    │  19b10010   │    │  19b10020   │         │
│  │ (Read)      │    │             │    │             │         │
│  └─────────────┘    └──────┬──────┘    └──────┬──────┘         │
│                            │                  │                 │
│                     ┌──────┴──────┐    ┌──────┴──────┐         │
│                     │Mic Gain     │    │Features     │         │
│                     │  19b10012   │    │  19b10021   │         │
│                     │ (R/W)       │    │ (Read)      │         │
│                     └─────────────┘    └─────────────┘         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 音频编码 ID 映射

| ID | 编码 | 帧大小 | 帧率 |
|---|------|-------|-----|
| 0 | PCM8 | 80B | 100fps |
| 1 | PCM16 | 160B | 100fps |
| 10 | MuLaw8 | 80B | 100fps |
| 11 | MuLaw16 | 160B | 100fps |
| 20 | Opus | 80B | 100fps |
| 21 | OpusFS320 | 160B | 50fps |

### 音频数据格式

```
┌────────────────────────────────────────────────────────────────┐
│                   Audio Packet (Opus)                           │
├────────────────────────────────────────────────────────────────┤
│  Byte 0-79: Opus encoded audio frame                           │
│  - Sample Rate: 16000 Hz                                       │
│  - Frame Duration: 10ms                                        │
│  - Frames Per Second: 100                                      │
│  - Bitrate: ~64 kbps                                           │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                  Audio Packet (PCM16)                           │
├────────────────────────────────────────────────────────────────┤
│  Byte 0-159: Raw PCM 16-bit samples (Little Endian)            │
│  - Sample Rate: 16000 Hz                                       │
│  - Frame Duration: 10ms (160 samples)                          │
│  - Frames Per Second: 100                                      │
└────────────────────────────────────────────────────────────────┘
```

### 核心实现代码

```dart
// lib/services/devices/omi_connection.dart

class OmiDeviceConnection extends DeviceConnection {

  /// 获取音频编码
  @override
  Future<BleAudioCodec> performGetAudioCodec() async {
    try {
      final codecData = await transport.readCharacteristic(
        omiServiceUuid,
        audioCodecCharacteristicUuid
      );
      if (codecData.isNotEmpty) {
        final codecId = codecData[0];
        switch (codecId) {
          case 0: return BleAudioCodec.pcm8;
          case 1: return BleAudioCodec.pcm16;
          case 10: return BleAudioCodec.mulaw8;
          case 11: return BleAudioCodec.mulaw16;
          case 20: return BleAudioCodec.opus;
          case 21: return BleAudioCodec.opusFS320;
          default: return BleAudioCodec.opus;
        }
      }
    } catch (e) {
      debugPrint('Failed to read audio codec: $e');
    }
    return BleAudioCodec.opus;
  }

  /// 订阅音频流
  @override
  Future<StreamSubscription?> performGetBleAudioBytesListener({
    required void Function(List<int>) onAudioBytesReceived,
  }) async {
    return transport
      .getCharacteristicStream(omiServiceUuid, audioDataStreamCharacteristicUuid)
      .listen(onAudioBytesReceived);
  }

  /// 获取电池电量
  @override
  Future<int> performGetBatteryLevel() async {
    final data = await transport.readCharacteristic(
      batteryServiceUuid,
      batteryLevelCharacteristicUuid
    );
    return data.isNotEmpty ? data[0] : -1;
  }

  /// 设置麦克风增益 (0-100)
  Future<void> setMicGain(int gain) async {
    await transport.writeCharacteristic(
      settingsServiceUuid,
      settingsMicGainCharacteristicUuid,
      [gain.clamp(0, 100)]
    );
  }

  /// 订阅按钮事件
  Future<StreamSubscription?> getButtonListener({
    required void Function() onButtonPressed,
  }) async {
    return transport
      .getCharacteristicStream(buttonServiceUuid, buttonTriggerCharacteristicUuid)
      .listen((_) => onButtonPressed());
  }
}
```

### 设备识别方法

```dart
// 通过 Service UUID 识别（连接后，最可靠）
static bool isOmiDeviceFromDevice(BluetoothDevice device) {
    return device.servicesList.any((s) => s.uuid == Guid(omiServiceUuid));
}

// 通过设备名称识别（扫描时）
static bool isOmiDeviceFromScanResult(ScanResult result) {
    final name = result.device.platformName.toLowerCase();
    return name.contains('omi') ||
           name.contains('friend') ||
           name.contains('memopin');
}
```

---

## PLAUD NotePin 协议

### 设备概述

| 项目 | 值 |
|-----|---|
| **厂商** | PLAUD |
| **音频编码** | AAC |
| **厂商 ID** | 93 (0x5D) |
| **识别特征** | Manufacturer Data 模式 `[0x04, 0x56, 0xcf, 0x00]` |
| **通信模式** | 命令-响应式 + 数据流 |

### BLE Service UUID 定义

```dart
// lib/services/devices/models.dart

const String plaudServiceUuid    = "00001910-0000-1000-8000-00805f9b34fb";
const String plaudWriteCharUuid  = "00002bb1-0000-1000-8000-00805f9b34fb";  // 写入命令
const String plaudNotifyCharUuid = "00002bb0-0000-1000-8000-00805f9b34fb";  // 接收响应/数据
```

### 命令码定义

```dart
// 命令 ID 定义
static const int _cmdGetBattery     = 9;   // 获取电池电量
static const int _cmdStartRecord    = 20;  // 开始录音
static const int _cmdStopRecord     = 23;  // 停止录音
static const int _cmdSyncFileStart  = 28;  // 开始同步文件
```

### 服务架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        PLAUD NotePin                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    Main Service                          │    │
│  │                    00001910-...                          │    │
│  └────────────────────────┬────────────────────────────────┘    │
│                           │                                      │
│           ┌───────────────┴───────────────┐                     │
│           │                               │                      │
│  ┌────────┴────────┐           ┌─────────┴─────────┐            │
│  │  Write Char     │           │   Notify Char     │            │
│  │  00002bb1-...   │           │   00002bb0-...    │            │
│  │  (写入命令)      │           │   (接收响应/数据)  │            │
│  └────────┬────────┘           └─────────┬─────────┘            │
│           │                               │                      │
│           │    ┌──────────────────────────┘                     │
│           │    │                                                 │
│           ▼    ▼                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                   Command Protocol                       │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │ Request:  [Type][CmdID_Lo][CmdID_Hi][...Data]   │    │    │
│  │  │ Response: [Type][CmdID_Lo][CmdID_Hi][...Data]   │    │    │
│  │  │ Audio:    [0x02][...AAC Frame Data]             │    │    │
│  │  └─────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 数据包格式

```
┌────────────────────────────────────────────────────────────────┐
│                    Command Request Packet                       │
├────────────────────────────────────────────────────────────────┤
│  Byte 0:     Type (0x01 = Command)                             │
│  Byte 1:     Command ID Low byte                               │
│  Byte 2:     Command ID High byte                              │
│  Byte 3+:    Command Data (optional)                           │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                    Command Response Packet                      │
├────────────────────────────────────────────────────────────────┤
│  Byte 0:     Type (0x01 = Response)                            │
│  Byte 1:     Command ID Low byte                               │
│  Byte 2:     Command ID High byte                              │
│  Byte 3+:    Response Data                                     │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                      Audio Data Packet                          │
├────────────────────────────────────────────────────────────────┤
│  Byte 0:     Type (0x02 = Audio)                               │
│  Byte 1-4:   Reserved                                          │
│  Byte 5-8:   Position (Little Endian, 0xFFFFFFFF = End)        │
│  Byte 9:     Length of audio data                              │
│  Byte 10+:   AAC audio frame data                              │
└────────────────────────────────────────────────────────────────┘
```

### 核心实现代码

```dart
// lib/services/devices/plaud_connection.dart

class PlaudDeviceConnection extends DeviceConnection {
  final Map<int, StreamController<List<int>>> _commandQueues = {};
  final StreamController<List<int>> _audioStream = StreamController.broadcast();

  @override
  Future<void> performConnect() async {
    await super.performConnect();

    // 订阅通知特征
    transport.getCharacteristicStream(plaudServiceUuid, plaudNotifyCharUuid)
      .listen(_handleNotification);
  }

  /// 处理接收到的通知数据
  void _handleNotification(List<int> data) {
    if (data.isEmpty) return;

    if (data[0] == 2) {
      // 音频数据包 (Type = 0x02)
      final chunk = _parseAudioChunk(data.sublist(1));
      if (chunk != null) {
        _audioStream.add(chunk);
      }
    } else if (data.length >= 3) {
      // 命令响应包
      final cmdId = data[1] | (data[2] << 8);
      final payload = data.length > 3 ? data.sublist(3) : <int>[];
      _commandQueues.putIfAbsent(cmdId, () => StreamController()).add(payload);
    }
  }

  /// 解析音频数据块
  List<int>? _parseAudioChunk(List<int> payload) {
    if (payload.length < 9) return null;

    // 位置字段，0xFFFFFFFF 表示结束
    final position = _toInt32(payload.sublist(4, 8));
    if (position == 0xFFFFFFFF) return null;

    final length = payload[8];
    if (payload.length < 9 + length) return null;

    return payload.sublist(9, 9 + length);
  }

  /// 发送命令并等待响应
  Future<List<int>> _sendCommand(int cmdId, [List<int>? data]) async {
    final queue = _commandQueues.putIfAbsent(cmdId, () => StreamController());

    // 构建命令包
    final packet = [
      0x01,                  // Type = Command
      cmdId & 0xFF,          // CmdID Low byte
      (cmdId >> 8) & 0xFF,   // CmdID High byte
      ...?data
    ];

    await transport.writeCharacteristic(plaudServiceUuid, plaudWriteCharUuid, packet);

    // 等待响应（5秒超时）
    return queue.stream.first.timeout(Duration(seconds: 5));
  }

  /// 获取电池电量
  @override
  Future<int> performGetBatteryLevel() async {
    try {
      final response = await _sendCommand(_cmdGetBattery);
      return response.isNotEmpty ? response[0] : -1;
    } catch (e) {
      return -1;
    }
  }

  /// 开始录音
  Future<void> startRecording() async {
    await _sendCommand(_cmdStartRecord);
  }

  /// 停止录音
  Future<void> stopRecording() async {
    await _sendCommand(_cmdStopRecord);
  }

  /// 音频流
  @override
  Future<StreamSubscription?> performGetBleAudioBytesListener({
    required void Function(List<int>) onAudioBytesReceived,
  }) async {
    return _audioStream.stream.listen(onAudioBytesReceived);
  }

  int _toInt32(List<int> bytes) {
    return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
  }
}
```

### 设备识别方法

```dart
// 通过 Manufacturer Data 识别（最可靠）
static bool isPlaudDevice(ScanResult result) {
    final manufacturerData = result.advertisementData.manufacturerData;

    // 检查厂商 ID 93 (0x5D)
    if (manufacturerData.containsKey(93)) {
        final data = manufacturerData[93]!;
        // NotePin 特征模式
        if (data.length >= 4 &&
            data[0] == 0x04 &&
            data[1] == 0x56 &&
            data[2] == 0xcf &&
            data[3] == 0x00) {
            return true;
        }
        // 其他 PLAUD 设备
        if (data.isNotEmpty) return true;
    }

    // 名称匹配（备选）
    return result.device.platformName.toUpperCase().startsWith('PLAUD');
}
```

---

## Friend Pendant 协议

### 设备概述

| 项目 | 值 |
|-----|---|
| **音频编码** | LC3 (Low Complexity Communication Codec) |
| **帧大小** | 30 字节/帧 (10ms) |
| **每包帧数** | 3 帧 |
| **包结构** | 90 字节音频 + 5 字节 Footer = 95 字节 |
| **帧率** | 100 fps |

### BLE Service UUID 定义

```dart
// lib/services/devices/models.dart

const String friendPendantServiceUuid =
    "1a3fd0e7-b1f3-ac9e-2e49-b647b2c4f8da";

const String friendPendantAudioCharacteristicUuid =
    "01000000-1111-1111-1111-111111111111";
```

### 服务架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                       Friend Pendant                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    Main Service                          │    │
│  │            1a3fd0e7-b1f3-ac9e-2e49-b647b2c4f8da         │    │
│  └────────────────────────┬────────────────────────────────┘    │
│                           │                                      │
│  ┌────────────────────────┴────────────────────────────────┐    │
│  │                   Audio Characteristic                   │    │
│  │           01000000-1111-1111-1111-111111111111           │    │
│  │                      (Notify)                            │    │
│  └────────────────────────┬────────────────────────────────┘    │
│                           │                                      │
│                           ▼                                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                   Packet Structure                       │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │ [LC3 Frame 1][LC3 Frame 2][LC3 Frame 3][Footer] │    │    │
│  │  │    30 bytes    30 bytes    30 bytes   5 bytes   │    │    │
│  │  │                   Total: 95 bytes               │    │    │
│  │  └─────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                  Standard Battery Service                │    │
│  │                 0000180f-0000-1000-8000-...              │    │
│  │             (Returns static 90% if unavailable)          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 数据包格式

```
┌────────────────────────────────────────────────────────────────┐
│                   Friend Pendant Audio Packet                   │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    LC3 Audio Data (90 bytes)              │  │
│  ├──────────────────┬──────────────────┬────────────────────┤  │
│  │  Frame 1 (30B)   │  Frame 2 (30B)   │   Frame 3 (30B)    │  │
│  │  10ms audio      │  10ms audio      │   10ms audio       │  │
│  │  @16kHz          │  @16kHz          │   @16kHz           │  │
│  └──────────────────┴──────────────────┴────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Footer (5 bytes)                       │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │  Control/Metadata bytes (device-specific)                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Total Packet Size: 95 bytes                                    │
│  Audio Duration: 30ms per packet                                │
│  Delivery Rate: ~33 packets/second                              │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

### LC3 编码参数

```
┌────────────────────────────────────────────────────────────────┐
│                     LC3 Codec Parameters                        │
├────────────────────────────────────────────────────────────────┤
│  Codec:           LC3 (Low Complexity Communication Codec)     │
│  Sample Rate:     16000 Hz                                     │
│  Frame Duration:  10 ms                                        │
│  Frame Size:      30 bytes                                     │
│  Bitrate:         ~24 kbps per frame                           │
│  Channel:         Mono                                         │
│  Frames/Packet:   3                                            │
│  Frames/Second:   100                                          │
└────────────────────────────────────────────────────────────────┘
```

### 核心实现代码

```dart
// lib/services/devices/friend_pendant_connection.dart

class FriendPendantDeviceConnection extends DeviceConnection {
  static const int packetFooterSize = 5;    // Footer 大小
  static const int packetSize = 95;         // 总包大小
  static const int lc3DataSize = 90;        // LC3 数据大小 (3帧 × 30字节)
  static const int lc3FrameSize = 30;       // 单帧大小

  @override
  Future<BleAudioCodec> performGetAudioCodec() async {
    return BleAudioCodec.lc3FS1030;
  }

  /// 处理音频数据包 - 移除 Footer
  List<int>? _processAudioPacket(List<int> data) {
    if (data.length < packetFooterSize) return null;
    // 移除最后 5 字节的 Footer，返回 LC3 音频数据
    return data.sublist(0, data.length - packetFooterSize);
  }

  /// 订阅音频流
  @override
  Future<StreamSubscription?> performGetBleAudioBytesListener({
    required void Function(List<int>) onAudioBytesReceived,
  }) async {
    return transport
      .getCharacteristicStream(
        friendPendantServiceUuid,
        friendPendantAudioCharacteristicUuid
      )
      .listen((data) {
        final payload = _processAudioPacket(data);
        if (payload == null || payload.isEmpty) return;

        // 将 90 字节数据拆分为 3 个 30 字节的 LC3 帧
        for (int i = 0; i < payload.length; i += lc3FrameSize) {
          final end = (i + lc3FrameSize <= payload.length)
              ? i + lc3FrameSize
              : payload.length;
          final chunk = payload.sublist(i, end);

          // 只发送完整帧
          if (chunk.length == lc3FrameSize) {
            onAudioBytesReceived(chunk);
          }
        }
      });
  }

  /// 获取电池电量
  @override
  Future<int> performGetBatteryLevel() async {
    try {
      final data = await transport.readCharacteristic(
        batteryServiceUuid,
        batteryLevelCharacteristicUuid
      );
      return data.isNotEmpty ? data[0] : 90;  // 默认返回 90%
    } catch (e) {
      return 90;  // 读取失败返回默认值
    }
  }
}
```

### 设备识别方法

```dart
// 通过设备名称识别
static bool isFriendPendantDevice(ScanResult result) {
    final name = result.device.platformName.toLowerCase();
    return name.startsWith('friend_') || name.contains('pendant');
}

// 通过 Service UUID 识别（连接后）
static bool isFriendPendantFromDevice(BluetoothDevice device) {
    return device.servicesList.any(
      (s) => s.uuid == Guid(friendPendantServiceUuid)
    );
}
```

---

## 协议对比与最佳实践

### 协议对比总结

| 特性 | MemoPin/Omi | PLAUD NotePin | Friend Pendant |
|-----|-------------|---------------|----------------|
| **Service UUID** | `19b10000-...` | `00001910-...` | `1a3fd0e7-...` |
| **音频编码** | Opus/PCM | AAC | LC3 |
| **帧大小** | 80B (Opus) | 变长 | 30B |
| **帧率** | 100 fps | 变长 | 100 fps |
| **通信模式** | Notify 直接流 | 命令-响应式 | Notify 直接流 |
| **设备检测** | Service UUID | Manufacturer Data | 设备名称 |
| **附加功能** | 按钮/存储/加速度计 | 录音控制/文件同步 | 简单音频流 |
| **复杂度** | 中等 | 高 | 低 |

### 设备检测优先级

```dart
// 推荐检测顺序：Manufacturer Data > Service UUID > 设备名称

DeviceType detectDeviceType(ScanResult result) {
    // 1. 首先检查 Manufacturer Data（最可靠，无需连接）
    if (isPlaudDevice(result)) return DeviceType.plaud;

    // 2. 检查设备名称（扫描时可用）
    final name = result.device.platformName.toLowerCase();
    if (name.startsWith('friend_')) return DeviceType.friendPendant;
    if (name.contains('omi') || name.contains('memopin')) return DeviceType.omi;

    // 3. 连接后通过 Service UUID 确认
    return DeviceType.unknown;
}
```

### 音频流处理模板

```dart
/// 通用音频流处理模板
Future<StreamSubscription?> setupAudioStream({
    required String serviceUuid,
    required String characteristicUuid,
    required void Function(List<int>) onFrame,
    List<int>? Function(List<int>)? frameParser,
}) async {
    return transport
        .getCharacteristicStream(serviceUuid, characteristicUuid)
        .listen((data) {
            final frame = frameParser?.call(data) ?? data;
            if (frame != null && frame.isNotEmpty) {
                onFrame(frame);
            }
        });
}
```

### 命令-响应模式模板

```dart
/// 通用命令-响应处理模板
class CommandQueue {
    final Map<int, Completer<List<int>>> _pending = {};

    Future<List<int>> sendCommand(
        DeviceTransport transport,
        String serviceUuid,
        String writeCharUuid,
        int cmdId,
        [List<int>? data]
    ) async {
        final completer = Completer<List<int>>();
        _pending[cmdId] = completer;

        final packet = [0x01, cmdId & 0xFF, (cmdId >> 8) & 0xFF, ...?data];
        await transport.writeCharacteristic(serviceUuid, writeCharUuid, packet);

        return completer.future.timeout(Duration(seconds: 5));
    }

    void handleResponse(List<int> data) {
        if (data.length < 3) return;
        final cmdId = data[1] | (data[2] << 8);
        final payload = data.length > 3 ? data.sublist(3) : <int>[];
        _pending[cmdId]?.complete(payload);
        _pending.remove(cmdId);
    }
}
```

---

## 文件索引

### 核心代码文件

| 文件 | 职责 |
|-----|------|
| `lib/services/devices/models.dart` | BLE UUID 定义 |
| `lib/services/devices/device_connection.dart` | 设备连接工厂与基类 |
| `lib/services/devices/omi_connection.dart` | MemoPin/Omi 连接实现 |
| `lib/services/devices/plaud_connection.dart` | PLAUD 连接实现 |
| `lib/services/devices/friend_pendant_connection.dart` | Friend Pendant 连接实现 |
| `lib/services/devices/transports/ble_transport.dart` | BLE 传输层封装 |
| `lib/backend/schema/bt_device/bt_device.dart` | 设备类型与编码枚举 |

### 依赖包

```yaml
# pubspec.yaml
dependencies:
  flutter_blue_plus: ^1.33.6     # BLE 通信（主要）
  flutter_reactive_ble: ^5.0.0   # BLE 通信（AI Note 专用）
```

---

*文档版本：1.0*
*基于 Omi Flutter App 实现*
*最后更新：2026-01-19*
