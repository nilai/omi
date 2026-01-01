import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/bt_device/bt_device.dart';
import 'package:omi/providers/base_provider.dart';
import 'package:omi/providers/device_provider.dart';
import 'package:omi/providers/onboarding_provider.dart';
import 'package:omi/services/devices.dart';
import 'package:omi/services/services.dart';

import '../services/devices/note_connection.dart';

/// 设备发现和自动连接 Provider
/// 负责扫描设备并自动连接第一个发现的设备
class MPDeviceFinderProvider extends BaseProvider implements IDeviceServiceSubsciption {
  DeviceProvider? _deviceProvider;
  OnboardingProvider? _onboardingProvider;

  /// 是否正在扫描
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  /// 是否正在连接
  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  /// 是否已连接
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// 连接状态文本（用于显示在扫描页面）
  String _connectionStatusText = '正在搜索设备';
  String get connectionStatusText => _connectionStatusText;

  /// 设备信息（从 OnboardingProvider 同步）
  int batteryPercentage = -1;
  String deviceName = '';
  String deviceId = '';
  String firmwareRevision = '';
  String hardwareRevision = '';
  int noteUsedKB = 0;
  int noteTotalKB = 0;

  /// 获取已使用存储的显示标题
  String get noteUsedKBTitle {
    return _formatStorageSize(noteUsedKB);
  }

  /// 格式化存储大小
  String _formatStorageSize(int sizeKB) {
    if (sizeKB < 1000) {
      return '${sizeKB.toStringAsFixed(2)} KB';
    } else if (sizeKB < 1000000) {
      double mb = sizeKB / 1000.0;
      return '${mb.toStringAsFixed(2)} MB';
    } else {
      double gb = sizeKB / 1000000.0;
      return '${gb.toStringAsFixed(2)} GB';
    }
  }

  /// 设置依赖的 Provider
  void setProviders({
    required DeviceProvider deviceProvider,
    required OnboardingProvider onboardingProvider,
  }) {
    _deviceProvider = deviceProvider;
    _onboardingProvider = onboardingProvider;
    notifyListeners();
  }

  /// 开始扫描并自动连接设备
  Future<void> startScanAndAutoConnect() async {
    if (_isScanning || _isConnected) {
      return;
    }

    _isScanning = true;
    _connectionStatusText = '正在搜索设备';
    notifyListeners();

    // 检查权限
    if (_onboardingProvider != null && !_onboardingProvider!.hasBluetoothPermission) {
      await _onboardingProvider!.askForBluetoothPermissions();
      if (!_onboardingProvider!.hasBluetoothPermission) {
        _isScanning = false;
        _connectionStatusText = '需要蓝牙权限';
        notifyListeners();
        return;
      }
    }

    // 订阅设备服务
    ServiceManager.instance().device.subscribe(this, this);

    // 开始周期性连接（会自动扫描）
    if (_deviceProvider != null) {
      await _deviceProvider!.periodicConnect('coming from MPDeviceFinder');
    }

    // 检查是否已有已连接的设备
    _checkExistingConnection();
  }

  /// 检查是否已有已连接的设备
  Future<void> _checkExistingConnection() async {
    if (_deviceProvider == null) return;

    // 等待一小段时间让设备状态稳定
    await Future.delayed(const Duration(milliseconds: 500));

    if (_deviceProvider!.isConnected && _deviceProvider!.connectedDevice != null) {
      await _handleDeviceConnected(_deviceProvider!.connectedDevice!);
    }
  }

  /// 处理设备连接
  Future<void> _handleDeviceConnected(BtDevice device) async {
    if (_isConnected) return;

    _isConnecting = true;
    _isScanning = false;
    _connectionStatusText = '正在连接设备...';
    notifyListeners();

    try {
      // 设置设备信息
      deviceId = device.id;
      deviceName = device.name;

      // 通过 DeviceProvider 设置连接设备
      if (_deviceProvider != null) {
        _deviceProvider!.setConnectedDevice(device);
        _deviceProvider!.setIsConnected(true);
      }

      // 保存设备信息
      await SharedPreferencesUtil().btDeviceSet(device);
      SharedPreferencesUtil().deviceName = device.name;

      // 等待连接稳定
      await Future.delayed(const Duration(seconds: 1));

      // 获取设备信息
      final connection = await ServiceManager.instance().device.ensureConnection(device.id) as NoteDeviceConnection?;
      if (connection != null && _onboardingProvider != null) {
        await _onboardingProvider!.sendQueryBattery(connection);
        await _onboardingProvider!.sendQueryVersion(connection);
        await _onboardingProvider!.sendQueryStorage(connection);

        // 同步设备信息
        syncDeviceInfo();
      }

      _isConnected = true;
      _isConnecting = false;
      _connectionStatusText = '已连接';
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling device connection: $e');
      _isConnecting = false;
      _isScanning = true;
      _connectionStatusText = '连接失败，继续搜索...';
      notifyListeners();
    }
  }

  /// 自动连接发现的设备
  Future<void> _autoConnectDevice(BtDevice device) async {
    if (_isConnecting || _isConnected) {
      return;
    }

    _isConnecting = true;
    _connectionStatusText = '正在连接 ${device.name}...';
    notifyListeners();

    try {
      // 强制连接设备
      await ServiceManager.instance().device.ensureConnection(device.id, force: true);
      
      // 等待连接完成
      await Future.delayed(const Duration(seconds: 2));

      // 检查连接状态
      final connection = await ServiceManager.instance().device.ensureConnection(device.id);
      if (connection != null && connection.status == DeviceConnectionState.connected) {
        await _handleDeviceConnected(device);
      } else {
        throw Exception('Connection failed');
      }
    } catch (e) {
      debugPrint('Error auto connecting to device: $e');
      _isConnecting = false;
      _isScanning = true;
      _connectionStatusText = '连接失败，继续搜索...';
      notifyListeners();
    }
  }

  /// 同步设备信息从 OnboardingProvider
  void syncDeviceInfo() {
    if (_onboardingProvider == null) return;

    final oldBattery = batteryPercentage;
    final oldName = deviceName;
    final oldFirmware = firmwareRevision;
    final oldHardware = hardwareRevision;
    final oldUsedKB = noteUsedKB;
    final oldTotalKB = noteTotalKB;

    batteryPercentage = _onboardingProvider!.batteryPercentage;
    deviceName = _onboardingProvider!.deviceName.isNotEmpty 
        ? _onboardingProvider!.deviceName 
        : deviceName;
    firmwareRevision = _onboardingProvider!.firmwareRevision;
    hardwareRevision = _onboardingProvider!.hardwareRevision;
    noteUsedKB = _onboardingProvider!.noteUsedKB;
    noteTotalKB = _onboardingProvider!.noteTotalKB;

    // 如果信息有变化，通知监听者
    if (oldBattery != batteryPercentage ||
        oldName != deviceName ||
        oldFirmware != firmwareRevision ||
        oldHardware != hardwareRevision ||
        oldUsedKB != noteUsedKB ||
        oldTotalKB != noteTotalKB) {
      notifyListeners();
    }
  }

  /// 停止扫描
  void stopScanning() {
    _isScanning = false;
    _isConnecting = false;
    ServiceManager.instance().device.unsubscribe(this);
    notifyListeners();
  }

  /// 重置状态
  void reset() {
    _isScanning = false;
    _isConnecting = false;
    _isConnected = false;
    _connectionStatusText = '正在搜索设备';
    batteryPercentage = -1;
    deviceName = '';
    deviceId = '';
    firmwareRevision = '';
    hardwareRevision = '';
    noteUsedKB = 0;
    noteTotalKB = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    stopScanning();
    super.dispose();
  }

  // ========== IDeviceServiceSubsciption 实现 ==========

  @override
  void onDeviceConnectionStateChanged(String deviceId, DeviceConnectionState state) {
    if (state == DeviceConnectionState.connected) {
      // 设备连接状态改变时，检查是否是当前设备
      if (_deviceProvider != null && _deviceProvider!.connectedDevice?.id == deviceId) {
        final device = _deviceProvider!.connectedDevice;
        if (device != null && !_isConnected) {
          _handleDeviceConnected(device);
        }
      }
    } else if (state == DeviceConnectionState.disconnected) {
      // 设备断开连接
      if (this.deviceId == deviceId) {
        _isConnected = false;
        _isScanning = true;
        _connectionStatusText = '设备已断开，重新搜索...';
        notifyListeners();
      }
    }
  }

  @override
  void onDevices(List<BtDevice> devices) {
    if (_isConnected || _isConnecting || devices.isEmpty) {
      return;
    }

    // 自动连接第一个发现的设备
    final firstDevice = devices.first;
    debugPrint('Found device: ${firstDevice.name}, auto connecting...');
    _autoConnectDevice(firstDevice);
  }

  @override
  void onStatusChanged(DeviceServiceStatus status) {
    // 可以在这里处理服务状态变化
  }
}

