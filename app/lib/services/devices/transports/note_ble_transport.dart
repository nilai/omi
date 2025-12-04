/// Note BLE 传输层
/// 使用 flutter_reactive_ble 实现的 BLE 通信层

import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:omi/backend/schema/bt_device/bt_device.dart';
import 'package:omi/services/devices/note_commands.dart';
import 'device_transport.dart';

/// MTU 配置常量
const int _kNoteMtuSize = 517;
/// 连接稳定等待时间 (ms)
const int _kConnectionStabilizeDelayMs = 200;
/// 服务发现超时时间 (秒)
const int _kServiceDiscoveryTimeoutSec = 10;

/// Note 设备 BLE 传输层
///
/// 负责:
/// - BLE 设备连接管理
/// - 特征订阅和数据流管理
/// - 命令发送和响应接收
/// - OTA 文件传输
class NoteBleTransport implements DeviceTransport {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final BtDevice device;

  // 连接订阅
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;

  // 特征数据订阅
  StreamSubscription<List<int>>? _audioSubscription;
  StreamSubscription<List<int>>? _responseSubscription;
  StreamSubscription<List<int>>? _fileSubscription;
  StreamSubscription<List<int>>? _logSubscription;

  // 数据流控制器
  final _connectionStateController = StreamController<DeviceTransportState>.broadcast();
  final _audioDataController = StreamController<List<int>>.broadcast();
  final _responseDataController = StreamController<List<int>>.broadcast();
  final _fileDataController = StreamController<List<int>>.broadcast();
  final _logDataController = StreamController<List<int>>.broadcast();

  // 当前连接状态
  DeviceTransportState _currentState = DeviceTransportState.disconnected;

  // 当前协商的 MTU 值
  int _negotiatedMtu = 23; // 默认 BLE MTU

  // 连接完成器 - 用于等待连接流程完成
  Completer<void>? _connectionCompleter;

  NoteBleTransport(this.device);

  /// 获取当前协商的 MTU 值
  int get negotiatedMtu => _negotiatedMtu;

  @override
  String get deviceId => device.id;

  @override
  Stream<DeviceTransportState> get connectionStateStream =>
      _connectionStateController.stream;

  /// 音频数据流 (设备→APP)
  Stream<List<int>> get audioStream => _audioDataController.stream;

  /// 响应数据流 (设备→APP)
  Stream<List<int>> get responseStream => _responseDataController.stream;

  /// 文件数据流 (设备→APP)
  Stream<List<int>> get fileStream => _fileDataController.stream;

  /// 日志数据流 (设备→APP)
  Stream<List<int>> get logStream => _logDataController.stream;

  @override
  Future<void> connect() async {
    if (_currentState == DeviceTransportState.connected) {
      print('[NoteBleTransport] 设备已连接,跳过连接');
      return;
    }

    // 停止 flutter_blue_plus 的扫描，避免库冲突
    if (fbp.FlutterBluePlus.isScanningNow) {
      await fbp.FlutterBluePlus.stopScan();
      print('[NoteBleTransport] 已停止 flutter_blue_plus 扫描');
    }

    await _connectionSubscription?.cancel();
    _updateState(DeviceTransportState.connecting);

    // 创建连接完成器
    _connectionCompleter = Completer<void>();

    print('[NoteBleTransport] 开始连接设备: ${device.name} (${device.id})');

    _connectionSubscription = _ble
        .connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 10),
    )
        .listen(
      (state) async {
        print('[NoteBleTransport] 连接状态变化: ${state.connectionState}');

        if (state.connectionState == DeviceConnectionState.connected) {
          try {
            print('[NoteBleTransport] 设备连接成功');

            // #5: 连接稳定等待
            await Future.delayed(const Duration(milliseconds: _kConnectionStabilizeDelayMs));
            print('[NoteBleTransport] 连接稳定等待完成');

            // #1: MTU 交换
            await _exchangeMtu();

            // #3 & #8: 服务发现和验证
            await _discoverAndValidateServices();

            // 订阅特征
            await _subscribeCharacteristics();

            _updateState(DeviceTransportState.connected);
            print('[NoteBleTransport] 连接流程完成');

            // 通知连接完成
            if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
              _connectionCompleter!.complete();
            }
          } catch (e) {
            print('[NoteBleTransport] 连接初始化失败: $e');
            if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
              _connectionCompleter!.completeError(e);
            }
          }
        } else if (state.connectionState == DeviceConnectionState.disconnected) {
          _updateState(DeviceTransportState.disconnected);
          if (state.failure != null) {
            print('[NoteBleTransport] 连接失败: ${state.failure}');
            if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
              _connectionCompleter!.completeError(state.failure!);
            }
          }
        }
      },
      onError: (error) {
        print('[NoteBleTransport] 连接错误: $error');
        _handleBleError(error);
        if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.completeError(error);
        }
      },
    );

    // 等待连接完成（带超时）
    await _connectionCompleter!.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('连接超时: 设备未能在15秒内完成连接');
      },
    );
  }

  /// #1: MTU 交换
  Future<void> _exchangeMtu() async {
    try {
      _negotiatedMtu = await _ble.requestMtu(deviceId: device.id, mtu: _kNoteMtuSize);
      print('[NoteBleTransport] MTU 协商成功: $_negotiatedMtu');
    } catch (e) {
      print('[NoteBleTransport] MTU 协商失败: $e, 使用默认值');
      // MTU 协商失败不中断连接，使用默认值
      _negotiatedMtu = 23;
    }
  }

  /// #3 & #8: 服务发现和验证
  Future<void> _discoverAndValidateServices() async {
    try {
      // 显式发现服务（带超时）
      await _ble
          .discoverAllServices(device.id)
          .timeout(const Duration(seconds: _kServiceDiscoveryTimeoutSec));

      // 获取已发现的服务列表
      final discoveredServices = await _ble.getDiscoveredServices(device.id);
      print('[NoteBleTransport] 发现 ${discoveredServices.length} 个服务');

      // 验证 Note 服务是否存在
      final hasNoteService = discoveredServices.any((s) => s.id == NoteUUIDs.service);
      if (!hasNoteService) {
        throw Exception('设备不支持 Note 服务 (UUID: ${NoteUUIDs.service})');
      }
      print('[NoteBleTransport] Note 服务验证通过');
    } catch (e) {
      print('[NoteBleTransport] 服务发现/验证失败: $e');
      await disconnect();
      rethrow;
    }
  }

  /// 订阅所有特征
  Future<void> _subscribeCharacteristics() async {
    try {
      // 订阅音频数据特征
      final audioChar = QualifiedCharacteristic(
        serviceId: NoteUUIDs.service,
        characteristicId: NoteUUIDs.audioData,
        deviceId: device.id,
      );
      _audioSubscription = _ble.subscribeToCharacteristic(audioChar).listen(
            (data) => _audioDataController.add(data),
            onError: (error) => _handleSubscriptionError('音频', error),
          );

      // 订阅响应特征
      final responseChar = QualifiedCharacteristic(
        serviceId: NoteUUIDs.service,
        characteristicId: NoteUUIDs.response,
        deviceId: device.id,
      );
      _responseSubscription = _ble.subscribeToCharacteristic(responseChar).listen(
            (data) => _responseDataController.add(data),
            onError: (error) => _handleSubscriptionError('响应', error),
          );

      // 订阅文件数据特征
      final fileChar = QualifiedCharacteristic(
        serviceId: NoteUUIDs.service,
        characteristicId: NoteUUIDs.recordFile,
        deviceId: device.id,
      );
      _fileSubscription = _ble.subscribeToCharacteristic(fileChar).listen(
            (data) => _fileDataController.add(data),
            onError: (error) => _handleSubscriptionError('文件', error),
          );

      // 订阅日志数据特征
      final logChar = QualifiedCharacteristic(
        serviceId: NoteUUIDs.service,
        characteristicId: NoteUUIDs.logFile,
        deviceId: device.id,
      );
      _logSubscription = _ble.subscribeToCharacteristic(logChar).listen(
            (data) => _logDataController.add(data),
            onError: (error) => _handleSubscriptionError('日志', error),
          );

      print('[NoteBleTransport] 所有特征订阅完成');
    } catch (e) {
      print('[NoteBleTransport] 订阅特征失败: $e');
      rethrow;
    }
  }

  /// #6: 处理订阅错误
  void _handleSubscriptionError(String name, dynamic error) {
    print('[NoteBleTransport] $name订阅错误: $error');
    // 只记录错误，不断开连接
    // 部分特征可能不存在（取决于设备固件版本），这不应该影响整体连接
  }

  /// #6: 统一处理 BLE 错误
  void _handleBleError(dynamic error) {
    // 检查是否为断开连接异常
    if (error.toString().contains('Disconnected') ||
        error.toString().contains('disconnected')) {
      print('[NoteBleTransport] 检测到设备断开连接');
      _updateState(DeviceTransportState.disconnected);
      _cancelAllSubscriptions();
    } else {
      _updateState(DeviceTransportState.disconnected);
    }
  }

  @override
  Future<void> disconnect() async {
    if (_currentState == DeviceTransportState.disconnected) {
      return;
    }

    _updateState(DeviceTransportState.disconnecting);
    print('[NoteBleTransport] 断开连接');

    await _cancelAllSubscriptions();

    // #4: 清理 GATT 缓存
    try {
      await _ble.clearGattCache(device.id);
      print('[NoteBleTransport] GATT 缓存已清理');
    } catch (e) {
      print('[NoteBleTransport] 清理 GATT 缓存失败: $e');
    }

    _updateState(DeviceTransportState.disconnected);
  }

  /// 取消所有订阅
  Future<void> _cancelAllSubscriptions() async {
    await _connectionSubscription?.cancel();
    await _audioSubscription?.cancel();
    await _responseSubscription?.cancel();
    await _fileSubscription?.cancel();
    await _logSubscription?.cancel();

    _connectionSubscription = null;
    _audioSubscription = null;
    _responseSubscription = null;
    _fileSubscription = null;
    _logSubscription = null;
  }

  @override
  Future<bool> isConnected() async {
    return _currentState == DeviceTransportState.connected;
  }

  @override
  Future<bool> ping() async {
    // Note 设备可以通过查询电量来验证连接
    try {
      await sendCommand([NoteCommands.queryBattery]);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<List<int>> getCharacteristicStream(
      String serviceUuid, String characteristicUuid) {
    // 根据特征 UUID 返回对应的流
    final uuid = characteristicUuid.toLowerCase();

    if (uuid == NoteUUIDs.audioData.toString().toLowerCase()) {
      return audioStream;
    } else if (uuid == NoteUUIDs.response.toString().toLowerCase()) {
      return responseStream;
    } else if (uuid == NoteUUIDs.recordFile.toString().toLowerCase()) {
      return fileStream;
    } else if (uuid == NoteUUIDs.logFile.toString().toLowerCase()) {
      return logStream;
    }

    // 不支持的特征,返回空流
    return Stream<List<int>>.empty();
  }

  @override
  Future<List<int>> readCharacteristic(
      String serviceUuid, String characteristicUuid) async {
    // flutter_reactive_ble 主要通过订阅来读取数据
    // 这里可以实现一个简单的读取逻辑
    final char = QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(characteristicUuid),
      deviceId: device.id,
    );

    try {
      return await _ble.readCharacteristic(char);
    } catch (e) {
      print('[NoteBleTransport] 读取特征失败: $e');
      return [];
    }
  }

  @override
  Future<void> writeCharacteristic(
      String serviceUuid, String characteristicUuid, List<int> data) async {
    final char = QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(characteristicUuid),
      deviceId: device.id,
    );

    try {
      await _ble.writeCharacteristicWithoutResponse(char, value: data);
    } catch (e) {
      print('[NoteBleTransport] 写入特征失败: $e');
      rethrow;
    }
  }

  /// 发送命令 (写入命令特征,无需响应)
  Future<void> sendCommand(List<int> command) async {
    final commandChar = QualifiedCharacteristic(
      serviceId: NoteUUIDs.service,
      characteristicId: NoteUUIDs.command,
      deviceId: device.id,
    );

    await _ble.writeCharacteristicWithoutResponse(
      commandChar,
      value: command,
    );

    final hexString = command.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
    print('[NoteBleTransport] 命令已发送: $hexString');
  }

  /// 发送 OTA 文件数据 (使用有响应写入)
  Future<void> sendOtaData(List<int> data) async {
    final otaChar = QualifiedCharacteristic(
      serviceId: NoteUUIDs.service,
      characteristicId: NoteUUIDs.otaFile,
      deviceId: device.id,
    );

    await _ble.writeCharacteristicWithResponse(
      otaChar,
      value: data,
    );
  }

  /// 更新连接状态
  void _updateState(DeviceTransportState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _connectionStateController.add(newState);
    }
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _connectionStateController.close();
    await _audioDataController.close();
    await _responseDataController.close();
    await _fileDataController.close();
    await _logDataController.close();
  }
}
