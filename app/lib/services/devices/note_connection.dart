/// Note 设备连接层
/// 实现设备级别的命令控制、响应处理、状态管理
library;

import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:omi/backend/schema/bt_device/bt_device.dart';
import 'package:omi/backend/schema/bt_device/note_device.dart';
import 'package:omi/services/devices.dart';
import 'package:omi/services/devices/device_connection.dart';
import 'package:omi/services/devices/models.dart';
import 'package:omi/services/devices/transports/note_ble_transport.dart';
import 'package:omi/services/devices/transports/device_transport.dart';
import 'package:omi/services/devices/note_commands.dart';
import 'package:omi/services/devices/note_storage_manager.dart';

/// Note 设备连接类
///
/// 功能:
/// - 设备连接初始化(RTC同步、绑定检查)
/// - 设备信息查询(电量、版本、存储)
/// - 设备配置(录音模式)
/// - 录音控制(开始、停止)
/// - 文件管理(列表、上传、删除)
/// - 设备管理(绑定、解绑、重启、恢复出厂)
class NoteDeviceConnection extends DeviceConnection {
  final NoteBleTransport _transport;
  final NoteStorageManager _storage = NoteStorageManager();

  /// 自动重连定时器
  Timer? _autoReconnectTimer;

  /// 响应等待队列
  Completer<List<int>>? _responseCompleter;

  /// 连接初始化标志
  bool _isInitialized = false;

  // ============ #2: 分包拼接相关 ============

  /// 分包数据缓存
  final List<int> _packetCache = [];

  /// 分包超时定时器
  Timer? _packetTimeoutTimer;

  /// 分包超时时间 (毫秒)
  static const int _kPacketTimeoutMs = 50;

  /// 分包继续标识 (0x0d 表示后续还有数据)
  static const int _kPacketContinueFlag = 0x0d;

  // ============ #7: 自动重连相关 ============

  /// 自动重连间隔 (秒)
  static const int _kAutoReconnectIntervalSec = 5;

  /// 是否启用自动重连
  bool _autoReconnectEnabled = false;

  /// 连接状态回调
  void Function(String deviceId, DeviceConnectionState state)? _connectionStateCallback;

  NoteDeviceConnection(BtDevice device, this._transport) : super(device, _transport) {
    _setupResponseListener();
    _setupConnectionStateListener();
  }

  /// 设置连接状态监听器（用于自动重连）
  void _setupConnectionStateListener() {
    _transport.connectionStateStream.listen((state) {
      if (state == DeviceTransportState.disconnected && _autoReconnectEnabled) {
        print('[NoteConnection] 连接断开，启动自动重连');
        _startAutoReconnect();
      }
    });
  }

  /// 设置响应监听器
  void _setupResponseListener() {
    _transport.responseStream.listen((response) {
      _handleIncomingPacket(response);
    });
  }

  /// #2: 处理接收到的数据包（支持分包拼接）
  void _handleIncomingPacket(List<int> packet) {
    if (packet.isEmpty) return;

    final hexString = packet.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
    print('[NoteConnection] 收到数据包: $hexString');

    // 检查是否为分包数据 (命令 0x03 文件列表)
    // 格式: 0x03 0x0d ... 表示后续还有数据
    if (packet.length >= 2 && packet[0] == 0x03 && packet[1] == _kPacketContinueFlag) {
      // 这是一个中间包，需要缓存
      _cancelPacketTimeout();

      if (_packetCache.isEmpty) {
        // 第一个中间包，保留命令字节
        _packetCache.add(packet[0]);
      }
      // 添加数据部分（跳过命令字节和分包标识）
      _packetCache.addAll(packet.sublist(2));

      // 设置超时等待下一包
      _startPacketTimeout();
      print('[NoteConnection] 分包数据缓存中，当前长度: ${_packetCache.length}');
    } else {
      // 这是最后一包或完整包
      _cancelPacketTimeout();

      List<int> finalData;
      if (_packetCache.isNotEmpty) {
        // 有缓存数据，拼接最后一包
        if (packet.length >= 2 && packet[0] == 0x03) {
          // 最后一包也是 0x03 命令，跳过命令字节
          _packetCache.addAll(packet.sublist(1));
        } else {
          _packetCache.addAll(packet);
        }
        finalData = List<int>.from(_packetCache);
        _packetCache.clear();
        print('[NoteConnection] 分包拼接完成，总长度: ${finalData.length}');
      } else {
        // 没有缓存，这是完整的单包数据
        finalData = packet;
      }

      // 完成响应
      if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
        _responseCompleter!.complete(finalData);
      }
      _handleResponse(finalData);
    }
  }

  /// #2: 开始分包超时计时
  void _startPacketTimeout() {
    _packetTimeoutTimer = Timer(const Duration(milliseconds: _kPacketTimeoutMs), () {
      // 超时后，将已缓存的数据作为最终数据返回
      if (_packetCache.isNotEmpty) {
        print('[NoteConnection] 分包超时，返回已缓存数据，长度: ${_packetCache.length}');
        final finalData = List<int>.from(_packetCache);
        _packetCache.clear();

        if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
          _responseCompleter!.complete(finalData);
        }
        _handleResponse(finalData);
      }
    });
  }

  /// #2: 取消分包超时计时
  void _cancelPacketTimeout() {
    _packetTimeoutTimer?.cancel();
    _packetTimeoutTimer = null;
  }

  @override
  Future<void> connect({
    void Function(String deviceId, DeviceConnectionState state)? onConnectionStateChanged,
  }) async {
    print('[NoteConnection] 开始连接设备: ${device.name}');

    // 保存回调供自动重连使用
    _connectionStateCallback = onConnectionStateChanged;

    // 停止自动重连定时器（如果正在运行）
    _stopAutoReconnect();

    // 调用父类连接方法
    await super.connect(onConnectionStateChanged: onConnectionStateChanged);

    // Note 设备特有的初始化
    if (!_isInitialized) {
      await _initialize();
      _isInitialized = true;
    }

    // 连接成功后启用自动重连
    _autoReconnectEnabled = true;
  }

  // ============ #7: 自动重连方法 ============

  /// 启动自动重连
  void _startAutoReconnect() async {
    // 检查是否已绑定设备
    final isBound = await _storage.isDeviceBound();
    if (!isBound) {
      print('[NoteConnection] 设备未绑定，不启动自动重连');
      return;
    }

    _stopAutoReconnect();
    print('[NoteConnection] 启动自动重连定时器 ($_kAutoReconnectIntervalSec秒间隔)');

    _autoReconnectTimer = Timer.periodic(
      const Duration(seconds: _kAutoReconnectIntervalSec),
      (timer) async {
        if (!_autoReconnectEnabled) {
          timer.cancel();
          return;
        }

        print('[NoteConnection] 尝试自动重连...');
        try {
          await connect(onConnectionStateChanged: _connectionStateCallback);
          print('[NoteConnection] 自动重连成功');
          timer.cancel();
        } catch (e) {
          print('[NoteConnection] 自动重连失败: $e, 将继续重试');
        }
      },
    );
  }

  /// 停止自动重连
  void _stopAutoReconnect() {
    _autoReconnectTimer?.cancel();
    _autoReconnectTimer = null;
  }

  /// 启用/禁用自动重连
  void setAutoReconnectEnabled(bool enabled) {
    _autoReconnectEnabled = enabled;
    if (!enabled) {
      _stopAutoReconnect();
    }
    print('[NoteConnection] 自动重连已${enabled ? "启用" : "禁用"}');
  }

  /// 连接初始化流程
  ///
  /// 1. RTC 时间同步
  /// 2. 检查设备绑定状态
  /// 3. 设置录音模式(可选)
  Future<void> _initialize() async {
    try {
      print('[NoteConnection] 开始设备初始化');

      // 1. RTC 时间同步
      await syncRTC();
      await Future.delayed(const Duration(milliseconds: 50));

      // 2. 检查绑定状态
      final isBound = await _storage.isDeviceBound();
      if (!isBound) {
        print('[NoteConnection] 设备未绑定,执行绑定流程');
        await bindDevice();
      } else {
        print('[NoteConnection] 设备已绑定');
      }

      // 3. 保存设备类型
      await _storage.saveDeviceType('AI Note');

      print('[NoteConnection] 设备初始化完成');
    } catch (e) {
      print('[NoteConnection] 设备初始化失败: $e');
    }
  }

  // ============ 设备信息查询 ============

  @override
  Future<int> performRetrieveBatteryLevel() async {
    try {
      final response = await _sendCommandWithResponse([NoteCommands.queryBattery]);
      if (response.isNotEmpty && response[0] == NoteCommands.queryBattery) {
        return response[1];
      }
      return -1;
    } catch (e) {
      print('[NoteConnection] 查询电量失败: $e');
      return -1;
    }
  }

  /// 查询固件版本
  ///
  /// 返回格式: "vX.Y.Z"
  Future<String> queryFirmwareVersion() async {
    try {
      final response = await _sendCommandWithResponse([NoteCommands.queryVersion]);
      if (response.isNotEmpty && response[0] == NoteCommands.queryVersion) {
        final versionBytes = response.sublist(1, 10);
        // 将0字节替换为ASCII '0'
        final processed = versionBytes.map((b) => b == 0 ? 0x30 : b);
        return String.fromCharCodes(processed).trim();
      }
      return 'Unknown';
    } catch (e) {
      print('[NoteConnection] 查询版本失败: $e');
      return 'Unknown';
    }
  }

  /// 查询存储空间
  ///
  /// 返回存储信息对象
  Future<NoteStorageInfo> queryStorage() async {
    try {
      final response = await _sendCommandWithResponse([NoteCommands.queryStorage]);
      if (response.isNotEmpty && response[0] == NoteCommands.queryStorage) {
        final dataLength = response[1];
        final spaceBytes = response.sublist(3, 2 + dataLength);
        final spaceInfo = String.fromCharCodes(spaceBytes).trim();

        // 格式: "usedKB/totalKB"
        final parts = spaceInfo.split('/');
        if (parts.length == 2) {
          return NoteStorageInfo(
            usedKB: int.tryParse(parts[0]) ?? 0,
            totalKB: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
      return NoteStorageInfo(usedKB: 0, totalKB: 0);
    } catch (e) {
      print('[NoteConnection] 查询存储失败: $e');
      return NoteStorageInfo(usedKB: 0, totalKB: 0);
    }
  }

  // ============ 设备配置 ============

  /// RTC 时间同步
  ///
  /// 将当前系统时间同步到设备
  Future<void> syncRTC() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final command = [
        NoteCommands.syncRTC,
        (timestamp >> 24) & 0xFF,
        (timestamp >> 16) & 0xFF,
        (timestamp >> 8) & 0xFF,
        timestamp & 0xFF,
      ];

      await _sendCommand(command);
      print('[NoteConnection] RTC 时间已同步: ${DateTime.now()}');
    } catch (e) {
      print('[NoteConnection] RTC 同步失败: $e');
      rethrow;
    }
  }

  /// 设置录音模式
  ///
  /// mode: NoteRecordingMode.recordOnly 或 NoteRecordingMode.recordAndUpload
  Future<void> setRecordingMode(NoteRecordingMode mode) async {
    try {
      await _sendCommand([NoteCommands.setRecordingMode, mode.value]);
      print('[NoteConnection] 录音模式已设置: ${mode.description}');
    } catch (e) {
      print('[NoteConnection] 设置录音模式失败: $e');
      rethrow;
    }
  }

  /// 设置U盘模式
  ///
  /// enabled: true 开启, false 关闭
  Future<void> setUsbMode(bool enabled) async {
    try {
      await _sendCommand([NoteCommands.usbMode, enabled ? 0x01 : 0x00]);
      print('[NoteConnection] U盘模式已设置: ${enabled ? "开启" : "关闭"}');
    } catch (e) {
      print('[NoteConnection] 设置U盘模式失败: $e');
      rethrow;
    }
  }

  // ============ 录音控制 ============

  /// 开始录音
  ///
  /// 返回: true 成功, false 失败(设备正在录音)
  Future<bool> startRecording() async {
    try {
      final response = await _sendCommandWithResponse([NoteCommands.startRecording]);
      if (response.isNotEmpty && response[0] == 0x01) {
        if (response[1] == 0x01) {
          print('[NoteConnection] 录音已开始');
          return true;
        } else if (response.length >= 3 && response[1] == 0x00 && response[2] == 0x01) {
          print('[NoteConnection] 设备正在录音');
          return false;
        }
      }
      return false;
    } catch (e) {
      print('[NoteConnection] 开始录音失败: $e');
      return false;
    }
  }

  /// 停止录音
  ///
  /// 返回: Map包含成功状态、文件索引、文件名等信息
  Future<Map<String, dynamic>> stopRecording() async {
    try {
      final response = await _sendCommandWithResponse([NoteCommands.stopRecording]);
      if (response.isNotEmpty && response[0] == 0x02 && response[1] == 0x00) {
        if (response[2] == 0x01) {
          // 成功,有文件
          final fileIndex = response[3];
          final fileName = String.fromCharCodes(response.sublist(5));
          print('[NoteConnection] 录音已停止,文件: $fileName');
          return {
            'success': true,
            'fileIndex': fileIndex,
            'fileName': fileName,
          };
        } else if (response[2] == 0x02) {
          // 成功,但文件为空
          print('[NoteConnection] 录音已停止,文件为空');
          return {'success': true, 'empty': true};
        }
      }
      return {'success': false};
    } catch (e) {
      print('[NoteConnection] 停止录音失败: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============ 文件管理 ============

  /// 获取文件列表
  ///
  /// 返回设备上所有录音文件的信息列表
  Future<List<NoteFileInfo>> getFileList() async {
    try {
      final response = await _sendCommandWithResponse([NoteCommands.getFileList]);
      if (response.isEmpty || response[0] != 0x03) return [];

      final fileCount = response[1];
      if (fileCount == 0 || fileCount == 255) {
        print('[NoteConnection] 没有文件');
        return [];
      }

      final files = <NoteFileInfo>[];
      int offset = 2;

      for (int i = 0; i < fileCount; i++) {
        final index = response[offset];
        final duration = (response[offset + 1] << 8) + response[offset + 2];
        final nameLength = response[offset + 3];
        final fileNameBytes = response.sublist(offset + 4, offset + 4 + nameLength);
        final name = utf8.decode(fileNameBytes);

        // 验证文件名格式
        if (name.isNotEmpty && name.length >= 15 && name.contains('_')) {
          files.add(NoteFileInfo(
            index: index,
            name: name,
            durationSeconds: duration,
          ));
        }

        offset += 4 + nameLength;
      }

      print('[NoteConnection] 获取文件列表成功,共 ${files.length} 个文件');
      return files;
    } catch (e) {
      print('[NoteConnection] 获取文件列表失败: $e');
      return [];
    }
  }

  /// 上传文件
  ///
  /// fileName: 要上传的文件名
  /// 文件内容会通过 fileStream 接收
  Future<void> uploadFile(String fileName) async {
    try {
      final fileNameBytes = utf8.encode(fileName);
      final command = [NoteCommands.uploadFile, fileNameBytes.length, ...fileNameBytes];
      await _sendCommand(command);
      print('[NoteConnection] 开始上传文件: $fileName');
    } catch (e) {
      print('[NoteConnection] 上传文件失败: $e');
      rethrow;
    }
  }

  /// 删除文件
  ///
  /// fileName: 要删除的文件名
  Future<void> deleteFile(String fileName) async {
    try {
      final fileNameBytes = utf8.encode(fileName);
      final command = [NoteCommands.deleteFile, fileNameBytes.length, ...fileNameBytes];
      await _sendCommand(command);
      print('[NoteConnection] 文件已删除: $fileName');
    } catch (e) {
      print('[NoteConnection] 删除文件失败: $e');
      rethrow;
    }
  }

  // ============ 设备管理 ============

  /// 设备绑定
  ///
  /// 生成SNID并保存到本地文件
  Future<void> bindDevice() async {
    try {
      await _sendCommand([NoteCommands.bindDevice, 0x01]);
      await _storage.saveDeviceBinding(device.id, device.name);
      print('[NoteConnection] 设备绑定成功');
    } catch (e) {
      print('[NoteConnection] 设备绑定失败: $e');
      rethrow;
    }
  }

  /// 设备解绑
  ///
  /// 清除本地绑定信息
  Future<void> unbindDevice() async {
    try {
      await _sendCommand([NoteCommands.bindDevice, 0x00]);
      await _storage.clearDeviceBinding();
      print('[NoteConnection] 设备解绑成功');
    } catch (e) {
      print('[NoteConnection] 设备解绑失败: $e');
      rethrow;
    }
  }

  /// 设备重启
  Future<void> reboot() async {
    try {
      await _sendCommand([NoteCommands.reboot]);
      print('[NoteConnection] 设备重启命令已发送');
    } catch (e) {
      print('[NoteConnection] 设备重启失败: $e');
      rethrow;
    }
  }

  /// 恢复出厂设置
  ///
  /// keepRecordings: true 保留录音文件, false 删除录音文件
  /// 返回: true 成功, false 失败
  Future<bool> factoryReset({bool keepRecordings = false}) async {
    try {
      final param = keepRecordings ? 0x00 : 0xFF;
      final response = await _sendCommandWithResponse([NoteCommands.factoryReset, param]);

      if (response.isNotEmpty && response[0] == 0xE9 && response[1] == 0x01) {
        await _storage.clearDeviceBinding();
        print('[NoteConnection] 恢复出厂设置成功');
        return true;
      }
      return false;
    } catch (e) {
      print('[NoteConnection] 恢复出厂设置失败: $e');
      return false;
    }
  }

  // ============ 音频流监听 ============

  @override
  Future<StreamSubscription?> performGetBleAudioBytesListener({
    required void Function(List<int>) onAudioBytesReceived,
  }) async {
    return _transport.audioStream.listen(onAudioBytesReceived);
  }

  /// 获取文件数据流
  ///
  /// 用于接收设备上传的文件数据
  Future<StreamSubscription?> getFileDataListener({
    required void Function(List<int>) onFileDataReceived,
  }) async {
    return _transport.fileStream.listen(onFileDataReceived);
  }

  // ============ OTA 相关方法 (供 NoteOtaService 使用) ============

  /// 发送命令并等待响应 (公开方法,供 OTA 服务使用)
  ///
  /// timeout: 超时时间
  /// 返回: 响应数据
  Future<List<int>> sendCommandWithResponse(
    List<int> command, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return await _sendCommandWithResponse(command, timeout: timeout);
  }

  /// 发送 OTA 文件数据 (供 OTA 服务使用)
  ///
  /// data: 固件数据块
  Future<void> sendOtaData(List<int> data) async {
    await _transport.sendOtaData(data);
  }

  // ============ 未实现的抽象方法(Note设备不需要) ============

  @override
  Future<List<int>> performGetButtonState() async {
    // Note 设备没有按钮状态
    return [];
  }

  @override
  Future<StreamSubscription?> performGetBleButtonListener({
    required void Function(List<int>) onButtonReceived,
  }) async {
    // Note 设备没有按钮监听
    return null;
  }

  @override
  Future<BleAudioCodec> performGetAudioCodec() async {
    // Note 设备使用 Opus 编码
    return BleAudioCodec.opus;
  }

  @override
  Future<bool> performPlayToSpeakerHaptic(int mode) async {
    // Note 设备不支持扬声器/触觉反馈
    return false;
  }

  @override
  Future<List<int>> performGetStorageList() async {
    // Note 设备使用自己的文件管理系统
    return [];
  }

  @override
  Future<bool> performWriteToStorage(int numFile, int command, int offset) async {
    // Note 设备使用自己的文件传输协议
    return false;
  }

  @override
  Future<StreamSubscription?> performGetBleStorageBytesListener({
    required void Function(List<int>) onStorageBytesReceived,
  }) async {
    // Note 设备使用自己的文件数据流
    return _transport.fileStream.listen(onStorageBytesReceived);
  }

  @override
  Future performCameraStartPhotoController() async {
    // Note 设备不支持相机
    throw UnimplementedError('Camera not supported on Note device');
  }

  @override
  Future performCameraStopPhotoController() async {
    // Note 设备不支持相机
    throw UnimplementedError('Camera not supported on Note device');
  }

  @override
  Future<bool> performHasPhotoStreamingCharacteristic() async {
    // Note 设备不支持相机
    return false;
  }

  @override
  Future<StreamSubscription?> performGetImageListener({
    required void Function(OrientedImage) onImageReceived,
  }) async {
    // Note 设备不支持相机
    return null;
  }

  @override
  Future<StreamSubscription<List<int>>?> performGetAccelListener({
    void Function(int)? onAccelChange,
  }) async {
    // Note 设备不支持加速度计
    return null;
  }

  @override
  Future<int> performGetFeatures() async {
    // Note 设备特性标志(可根据实际需要设置)
    return 0;
  }

  @override
  Future<void> performSetLedDimRatio(int ratio) async {
    // Note 设备不支持LED控制
  }

  @override
  Future<int?> performGetLedDimRatio() async {
    // Note 设备不支持LED控制
    return null;
  }

  @override
  Future<void> performSetMicGain(int gain) async {
    // Note 设备不支持麦克风增益控制
  }

  @override
  Future<int?> performGetMicGain() async {
    // Note 设备不支持麦克风增益控制
    return null;
  }

  // ============ 命令发送辅助方法 ============

  /// 发送命令(无需响应)
  Future<void> _sendCommand(List<int> command) async {
    await _transport.sendCommand(command);
    final hexString = command.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
    print('[NoteConnection] 命令已发送: $hexString');
  }

  /// 发送命令并等待响应
  ///
  /// timeout: 超时时间(默认10秒)
  /// 返回: 响应数据
  Future<List<int>> _sendCommandWithResponse(
    List<int> command, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _responseCompleter = Completer<List<int>>();

    await _transport.sendCommand(command);
    final hexString = command.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
    print('[NoteConnection] 命令已发送(等待响应): $hexString');

    try {
      final response = await _responseCompleter!.future.timeout(
        timeout,
        onTimeout: () {
          print('[NoteConnection] 等待响应超时');
          return [];
        },
      );
      return response;
    } finally {
      _responseCompleter = null;
    }
  }

  /// 处理响应数据
  ///
  /// 可在这里添加通用的响应处理逻辑
  void _handleResponse(List<int> response) {
    final hexString = response.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
    print('[NoteConnection] 收到响应: $hexString');
  }

  // ============ 连接管理 ============

  @override
  Future<void> disconnect() async {
    print('[NoteConnection] 断开连接');
    // 主动断开时禁用自动重连
    _autoReconnectEnabled = false;
    _stopAutoReconnect();
    _cancelPacketTimeout();
    _packetCache.clear();
    _isInitialized = false;
    await super.disconnect();
  }

  /// 释放资源
  void dispose() {
    _autoReconnectTimer?.cancel();
    _cancelPacketTimeout();
    _packetCache.clear();
    _transport.dispose();
  }

  /// 获取存储管理器(用于外部访问)
  NoteStorageManager get storageManager => _storage;

  /// 获取传输层(用于OTA服务访问)
  NoteBleTransport get bleTransport => _transport;
}
