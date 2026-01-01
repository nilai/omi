import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/bt_device/bt_device.dart';
import 'package:omi/providers/base_provider.dart';
import 'package:omi/providers/device_provider.dart';
import 'package:omi/services/devices.dart';
import 'package:omi/services/services.dart';
import 'package:omi/utils/alerts/app_snackbar.dart';
import 'package:omi/utils/bluetooth/bluetooth_adapter.dart';
import 'package:omi/utils/platform/platform_service.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/devices/note_connection.dart';

/// 设备发现和自动连接 Provider
/// 负责扫描设备并自动连接第一个发现的设备
class MPDeviceFinderProvider extends BaseProvider implements IDeviceServiceSubsciption {
  DeviceProvider? _deviceProvider;

  /// 蓝牙权限状态
  bool _hasBluetoothPermission = false;
  bool get hasBluetoothPermission => _hasBluetoothPermission;

  // Method channel for macOS/Windows permissions
  static const MethodChannel _screenCaptureChannel = MethodChannel('screenCapturePlatform');

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

  /// 设备信息
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
  }) {
    _deviceProvider = deviceProvider;

    // 如果设备已连接，立即初始化连接状态
    if (deviceProvider.isConnected && deviceProvider.connectedDevice != null) {
      _initializeConnectedDevice(deviceProvider.connectedDevice!);
    }

    notifyListeners();
  }

  /// 初始化已连接设备的状态
  void _initializeConnectedDevice(BtDevice device) {
    _isConnected = true;
    _isScanning = false;
    _isConnecting = false;
    _connectionStatusText = '已连接';

    // 从设备对象恢复基本信息
    deviceId = device.id;
    deviceName = device.name.isNotEmpty ? device.name : deviceName;

    // 如果设备信息为空，尝试从 SharedPreferences 恢复
    if (deviceName.isEmpty) {
      final storedDevice = SharedPreferencesUtil().btDevice;
      if (storedDevice.id.isNotEmpty) {
        deviceName = storedDevice.name;
        deviceId = storedDevice.id;
      }
    }

    // 尝试从缓存恢复设备信息
    loadCachedDeviceInfo();

    // 从 DeviceProvider 恢复设备信息（如果可用）
    if (_deviceProvider != null) {
      // 从 pairedDevice 恢复固件版本
      if (_deviceProvider!.pairedDevice != null) {
        final pairedDevice = _deviceProvider!.pairedDevice!;
        if (pairedDevice.firmwareRevision.isNotEmpty && pairedDevice.firmwareRevision != 'Unknown') {
          firmwareRevision = pairedDevice.firmwareRevision;
        }
        if (pairedDevice.hardwareRevision.isNotEmpty) {
          hardwareRevision = pairedDevice.hardwareRevision;
        }
      }

      // 从 DeviceProvider 恢复电池电量
      if (_deviceProvider!.batteryLevel >= 0) {
        batteryPercentage = _deviceProvider!.batteryLevel;
      }
    }

    notifyListeners();
  }

  /// 从缓存加载设备信息
  void loadCachedDeviceInfo() {
    final storedDevice = SharedPreferencesUtil().btDevice;
    if (storedDevice.id.isNotEmpty && (storedDevice.id == deviceId || deviceId.isEmpty)) {
      // 恢复设备基本信息
      if (deviceName.isEmpty) {
        deviceName = storedDevice.name;
      }
      if (deviceId.isEmpty) {
        deviceId = storedDevice.id;
      }

      // 恢复固件版本信息
      if (storedDevice.firmwareRevision.isNotEmpty && storedDevice.firmwareRevision != 'Unknown') {
        firmwareRevision = storedDevice.firmwareRevision;
      }
      if (storedDevice.hardwareRevision.isNotEmpty) {
        hardwareRevision = storedDevice.hardwareRevision;
      }
    }
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
    await _updateBluetoothPermission();
    if (!_hasBluetoothPermission) {
      await _askForBluetoothPermissions();
      if (!_hasBluetoothPermission) {
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

      // 获取设备信息（如果失败，使用上次的信息）
      try {
        final connection = await ServiceManager.instance().device.ensureConnection(device.id) as NoteDeviceConnection?;
        if (connection != null) {
          await queryDeviceInfo(connection);
        } else {
          // 连接为空，尝试从缓存恢复
          loadCachedDeviceInfo();
          // 从 DeviceProvider 恢复信息
          syncFromDeviceProvider();
        }
      } catch (e) {
        debugPrint('Error fetching device info, using cached info: $e');
        // 获取失败，使用上次的信息（从缓存恢复）
        loadCachedDeviceInfo();
        // 从 DeviceProvider 恢复信息
        syncFromDeviceProvider();
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

  /// 查询设备信息
  Future<void> queryDeviceInfo(NoteDeviceConnection connection) async {
    try {
      // 查询电池电量
      final batteryLevel = await connection.performRetrieveBatteryLevel();
      if (batteryLevel >= 0) {
        batteryPercentage = batteryLevel;
      }

      // 查询固件版本
      final firmwareVersion = await connection.queryFirmwareVersion();
      if (firmwareVersion.isNotEmpty && firmwareVersion != 'Unknown') {
        firmwareRevision = firmwareVersion;
      }

      // 查询存储信息
      final storageInfo = await connection.queryStorage();
      noteUsedKB = storageInfo.usedKB;
      noteTotalKB = storageInfo.totalKB;

      debugPrint(
          'Device info queried: battery=$batteryPercentage%, firmware=$firmwareRevision, storage=$noteUsedKB/$noteTotalKB KB');
      notifyListeners();
    } catch (e) {
      debugPrint('Error querying device info: $e');
      // 查询失败，使用缓存信息
      loadCachedDeviceInfo();
      // 从 DeviceProvider 恢复信息
      syncFromDeviceProvider();
      notifyListeners();
    }
  }

  /// 从 DeviceProvider 同步设备信息
  void syncFromDeviceProvider() {
    if (_deviceProvider == null) return;

    // 从 pairedDevice 恢复固件版本
    if (_deviceProvider!.pairedDevice != null) {
      final pairedDevice = _deviceProvider!.pairedDevice!;
      if (firmwareRevision.isEmpty &&
          pairedDevice.firmwareRevision.isNotEmpty &&
          pairedDevice.firmwareRevision != 'Unknown') {
        firmwareRevision = pairedDevice.firmwareRevision;
      }
      if (hardwareRevision.isEmpty && pairedDevice.hardwareRevision.isNotEmpty) {
        hardwareRevision = pairedDevice.hardwareRevision;
      }
    }

    // 从 DeviceProvider 恢复电池电量
    if (batteryPercentage < 0 && _deviceProvider!.batteryLevel >= 0) {
      batteryPercentage = _deviceProvider!.batteryLevel;
    }
  }

  /// 更新蓝牙权限状态
  Future<void> _updateBluetoothPermission() async {
    if (PlatformService.isDesktop) {
      try {
        String bluetoothStatus = await _screenCaptureChannel.invokeMethod('checkBluetoothPermission');
        _hasBluetoothPermission = bluetoothStatus == 'granted';
      } catch (e) {
        debugPrint('Error checking Bluetooth permission on macOS: $e');
        _hasBluetoothPermission = await Permission.bluetooth.isGranted;
      }
    } else {
      _hasBluetoothPermission = await Permission.bluetooth.isGranted;
    }
    notifyListeners();
  }

  /// 请求蓝牙权限
  Future<void> _askForBluetoothPermissions() async {
    if (!PlatformService.isWindows) {
      FlutterBluePlus.setLogLevel(LogLevel.info, color: true);
    }

    if (PlatformService.isDesktop) {
      try {
        String bluetoothStatus = await _screenCaptureChannel.invokeMethod('checkBluetoothPermission');
        if (bluetoothStatus == 'granted') {
          _hasBluetoothPermission = true;
          notifyListeners();
          return;
        }

        if (bluetoothStatus == 'undetermined') {
          bool granted = await _screenCaptureChannel.invokeMethod('requestBluetoothPermission');
          _hasBluetoothPermission = granted;
          if (!granted) {
            AppSnackbar.showSnackbarError('Bluetooth permission is required to connect to your device.');
          }
        } else if (bluetoothStatus == 'denied' || bluetoothStatus == 'restricted') {
          _hasBluetoothPermission = false;
          AppSnackbar.showSnackbarError('Bluetooth permission denied. Please grant permission in System Preferences.');
        } else {
          _hasBluetoothPermission = false;
          AppSnackbar.showSnackbarError(
              'Bluetooth permission status: $bluetoothStatus. Please check System Preferences.');
        }
      } catch (e) {
        debugPrint('Error checking/requesting Bluetooth permission on macOS: $e');
        AppSnackbar.showSnackbarError('Failed to check Bluetooth permission: $e');
        _hasBluetoothPermission = false;
      }
    } else if (Platform.isIOS) {
      PermissionStatus bleStatus = await Permission.bluetooth.request();
      debugPrint('bleStatus: $bleStatus');
      _hasBluetoothPermission = bleStatus.isGranted;
    } else {
      if (Platform.isAndroid) {
        if (!(await BluetoothAdapter.isSupported) ||
            FlutterBluePlus.adapterStateNow != BluetoothAdapterStateHelper.on) {
          try {
            await FlutterBluePlus.turnOn();
          } catch (e) {
            if (e is FlutterBluePlusException) {
              if (e.code == 11) {
                //  onShowDialog();
              }
            }
          }
        }
      }
      PermissionStatus bleScanStatus = await Permission.bluetoothScan.request();
      PermissionStatus bleConnectStatus = await Permission.bluetoothConnect.request();
      _hasBluetoothPermission = bleConnectStatus.isGranted && bleScanStatus.isGranted;
    }
    notifyListeners();
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
