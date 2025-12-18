import 'dart:async';

import 'package:flutter/material.dart';
import 'package:omi/backend/http/api/device.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/bt_device/bt_device.dart';
import 'package:omi/main.dart';
import 'package:omi/pages/home/firmware_update.dart';
import 'package:omi/providers/capture_provider.dart';
import 'package:omi/services/devices.dart';
import 'package:omi/services/notifications.dart';
import 'package:omi/services/services.dart';
import 'package:omi/utils/analytics/mixpanel.dart';
import 'package:omi/utils/device.dart';
import 'package:omi/utils/logger.dart';
import 'package:omi/utils/other/debouncer.dart';
import 'package:omi/utils/platform/platform_manager.dart';
import 'package:omi/widgets/confirmation_dialog.dart';

/// 设备提供者类
/// 负责管理蓝牙设备的连接、断开、固件更新等核心功能
class DeviceProvider extends ChangeNotifier implements IDeviceServiceSubsciption {
  CaptureProvider? captureProvider;

  bool isConnecting = false; // 是否正在连接中
  bool isConnected = false; // 是否已连接
  bool isDeviceStorageSupport = false; // 设备是否支持存储功能
  BtDevice? connectedDevice; // 当前连接的设备
  BtDevice? pairedDevice; // 已配对的设备
  StreamSubscription<List<int>>? _bleBatteryLevelListener; // 电池电量监听器
  int batteryLevel = -1; // 电池电量 (-1 表示未知)
  bool _hasLowBatteryAlerted = false; // 是否已发送低电量警告
  Timer? _reconnectionTimer; // 重连定时器
  DateTime? _reconnectAt; // 下次重连时间
  final int _connectionCheckSeconds = 15; // 连接检查间隔（秒）

  /// Whether to auto-connect the first discovered unpaired device (是否自动连接第一个发现的未配对设备)
  bool _autoConnectFirstDevice = false;

  bool _havingNewFirmware = false; // 是否有新固件
  bool get havingNewFirmware => _havingNewFirmware && pairedDevice != null && isConnected;

  // 追踪固件更新状态，防止更新期间显示对话框
  bool _isFirmwareUpdateInProgress = false;
  bool get isFirmwareUpdateInProgress => _isFirmwareUpdateInProgress;

  // 当前和最新固件版本（用于 UI 显示）
  String get currentFirmwareVersion => pairedDevice?.firmwareRevision ?? 'Unknown';
  String _latestFirmwareVersion = '';
  String get latestFirmwareVersion => _latestFirmwareVersion;

  Timer? _disconnectNotificationTimer; // 断开连接通知定时器
  final Debouncer _disconnectDebouncer = Debouncer(delay: const Duration(milliseconds: 500)); // 断开连接防抖
  final Debouncer _connectDebouncer = Debouncer(delay: const Duration(milliseconds: 100)); // 连接防抖

  /// 构造函数
  /// 订阅设备服务，监听设备状态变化
  DeviceProvider() {
    ServiceManager.instance().device.subscribe(this, this);
  }

  /// 设置依赖的提供者
  /// @param provider 录音提供者实例
  void setProviders(CaptureProvider provider) {
    captureProvider = provider;
    notifyListeners();
  }

  /// 设置已连接的设备
  /// 同时更新配对设备信息并获取设备详细信息
  /// @param device 蓝牙设备对象，null 表示无设备
  void setConnectedDevice(BtDevice? device) async {
    connectedDevice = device;
    pairedDevice = device;
    await getDeviceInfo();
    Logger.debug('setConnectedDevice: $device');
    notifyListeners();
  }

  /// 获取设备详细信息
  /// 包括固件版本等信息，并保存到本地存储
  Future getDeviceInfo() async {
    if (connectedDevice != null) {
      if (pairedDevice?.firmwareRevision != null && pairedDevice?.firmwareRevision != 'Unknown') {
        return;
      }
      var connection = await ServiceManager.instance().device.ensureConnection(connectedDevice!.id);
      pairedDevice = await connectedDevice?.getDeviceInfo(connection);
      SharedPreferencesUtil().btDevice = pairedDevice!;
    } else {
      if (SharedPreferencesUtil().btDevice.id.isEmpty) {
        pairedDevice = BtDevice.empty();
      } else {
        pairedDevice = SharedPreferencesUtil().btDevice;
      }
    }
    notifyListeners();
  }

  /// 断开蓝牙设备连接
  /// @param btDevice 要断开的蓝牙设备
  /// @return 断开连接的 Future
  // TODO: thinh, 直接使用 connection
  Future _bleDisconnectDevice(BtDevice btDevice) async {
    var connection = await ServiceManager.instance().device.ensureConnection(btDevice.id);
    if (connection == null) {
      return Future.value(null);
    }
    return await connection.disconnect();
  }

  /// 获取设备电池电量
  /// @param deviceId 设备 ID
  /// @return 电池电量百分比，-1 表示获取失败
  Future<int> _retrieveBatteryLevel(String deviceId) async {
    var connection = await ServiceManager.instance().device.ensureConnection(deviceId);
    if (connection == null) {
      return -1;
    }
    return connection.retrieveBatteryLevel();
  }

  /// 获取电池电量监听器
  /// 监听设备电池电量变化，实时更新
  /// @param deviceId 设备 ID
  /// @param onBatteryLevelChange 电量变化回调函数
  /// @return 电量监听订阅对象
  Future<StreamSubscription<List<int>>?> _getBleBatteryLevelListener(
    String deviceId, {
    void Function(int)? onBatteryLevelChange,
  }) async {
    {
      var connection = await ServiceManager.instance().device.ensureConnection(deviceId);
      if (connection == null) {
        return Future.value(null);
      }
      return connection.getBleBatteryLevelListener(onBatteryLevelChange: onBatteryLevelChange);
    }
  }

  /// 获取设备存储文件列表
  /// @param deviceId 设备 ID
  /// @return 存储文件 ID 列表
  Future<List<int>> _getStorageList(String deviceId) async {
    var connection = await ServiceManager.instance().device.ensureConnection(deviceId);
    if (connection == null) {
      return [];
    }
    return connection.getStorageList();
  }

  /// 获取已连接的设备
  /// 从本地存储读取设备 ID 并尝试获取连接
  /// @return 已连接的设备对象，null 表示无连接
  Future<BtDevice?> _getConnectedDevice() async {
    var deviceId = SharedPreferencesUtil().btDevice.id;
    if (deviceId.isEmpty) {
      return null;
    }
    var connection = await ServiceManager.instance().device.ensureConnection(deviceId);
    return connection?.device;
  }

  /// 初始化电池电量监听器
  /// 监听设备电量变化，低于 20% 时发送通知
  initiateBleBatteryListener() async {
    if (connectedDevice == null) {
      return;
    }
    _bleBatteryLevelListener?.cancel();
    _bleBatteryLevelListener = await _getBleBatteryLevelListener(
      connectedDevice!.id,
      onBatteryLevelChange: (int value) {
        batteryLevel = value;
        if (batteryLevel < 20 && !_hasLowBatteryAlerted) {
          _hasLowBatteryAlerted = true;
          NotificationService.instance.createNotification(
            title: "Low Battery Alert",
            body: "Your device is running low on battery. Time for a recharge! 🔋",
          );
        } else if (batteryLevel > 20) {
          _hasLowBatteryAlerted = true;
        }
        notifyListeners();
      },
    );
    notifyListeners();
  }

  /// 定期尝试连接设备
  /// 每隔一定时间扫描并连接设备，直到连接成功
  /// @param printer 调试信息标识
  /// @param boundDeviceOnly 是否仅连接已绑定的设备
  /// @param autoConnectFirstDevice 是否自动连接第一个发现的未配对设备
  Future periodicConnect(String printer, {bool boundDeviceOnly = false, bool autoConnectFirstDevice = false}) async {
    _reconnectionTimer?.cancel();
    scan(t) async {
      debugPrint("Period connect seconds: $_connectionCheckSeconds, triggered timer at ${DateTime.now()}");
      updateConnectingStatus(true);
      if (_reconnectAt != null && _reconnectAt!.isAfter(DateTime.now())) {
        return;
      }
      if (boundDeviceOnly && SharedPreferencesUtil().btDevice.id.isEmpty) {
        t.cancel();
        return;
      }
      Logger.debug("isConnected: $isConnected, isConnecting: $isConnecting, connectedDevice: $connectedDevice");
      if ((!isConnected && connectedDevice == null)) {
        if (isConnecting) {
          return;
        }
        await scanAndConnectToDevice(autoConnectFirstDevice: autoConnectFirstDevice);
      } else {
        t.cancel();
      }
    }

    _reconnectionTimer = Timer.periodic(Duration(seconds: _connectionCheckSeconds), scan);
    scan(_reconnectionTimer);
  }

  /// 扫描并连接设备
  /// 先尝试直接重连已配对设备，失败后进行扫描
  /// @param autoConnectFirstDevice 是否自动连接第一个发现的未配对设备
  /// @return 连接的设备对象，null 表示连接失败
  Future<BtDevice?> _scanConnectDevice({bool autoConnectFirstDevice = false}) async {
    var device = await _getConnectedDevice();
    if (device != null) {
      return device;
    }

    final pairedDeviceId = SharedPreferencesUtil().btDevice.id;
    if (pairedDeviceId.isNotEmpty) {
      try {
        Logger.debug('Attempting direct reconnection to paired device: $pairedDeviceId');
        await ServiceManager.instance().device.ensureConnection(pairedDeviceId, force: true);

        // Check if connection succeeded
        await Future.delayed(const Duration(seconds: 2));
        device = await _getConnectedDevice();
        if (device != null) {
          Logger.debug('Direct reconnection successful');
          return device;
        }
      } catch (e) {
        Logger.debug('Direct reconnection failed: $e');
      }
    }

    // Set flag for auto-connecting first device
    _autoConnectFirstDevice = autoConnectFirstDevice;

    // If auto-connecting, scan without desirableDeviceId to discover all devices
    if (autoConnectFirstDevice) {
      Logger.debug('Scanning for unpaired devices, will auto-connect first found device');
      await ServiceManager.instance().device.discover(desirableDeviceId: null);
    } else {
      await ServiceManager.instance().device.discover(desirableDeviceId: pairedDeviceId);
    }

    // Waiting for the device connected (if any)
    await Future.delayed(const Duration(seconds: 2));
    if (connectedDevice != null) {
      _autoConnectFirstDevice = false;
      return connectedDevice;
    }
    return null;
  }

  /// 扫描并连接到设备
  /// 主要的设备连接入口方法
  /// @param autoConnectFirstDevice 是否自动连接第一个发现的未配对设备
  Future scanAndConnectToDevice({bool autoConnectFirstDevice = false}) async {
    updateConnectingStatus(true);
    if (isConnected) {
      if (connectedDevice == null) {
        connectedDevice = await _getConnectedDevice();
        SharedPreferencesUtil().deviceName = connectedDevice!.name;
        MixpanelManager().deviceConnected();
      }

      setIsConnected(true);
      // updateConnectingStatus(false);
      updateConnectingStatus(true);
      notifyListeners();
      return;
    }

    // else
    var device = await _scanConnectDevice(autoConnectFirstDevice: autoConnectFirstDevice);
    Logger.debug('inside scanAndConnectToDevice $device in device_provider');
    if (device != null) {
      var cDevice = await _getConnectedDevice();
      if (cDevice != null) {
        setConnectedDevice(cDevice);
        setisDeviceStorageSupport();
        SharedPreferencesUtil().deviceName = cDevice.name;
        MixpanelManager().deviceConnected();
        setIsConnected(true);
      }
      Logger.debug('device is not null $cDevice');
    }
    // updateConnectingStatus(false);
    updateConnectingStatus(true);

    notifyListeners();
  }

  /// 更新连接状态
  /// @param value true 表示正在连接，false 表示未连接
  void updateConnectingStatus(bool value) {
    isConnecting = value;
    notifyListeners();
  }

  /// 设置设备连接状态
  /// 连接成功时取消重连定时器
  /// @param value true 表示已连接，false 表示未连接
  void setIsConnected(bool value) {
    isConnected = value;
    if (isConnected) {
      _reconnectionTimer?.cancel();
    }
    notifyListeners();
  }

  /// 释放资源
  /// 取消所有监听器和定时器，清理资源
  @override
  void dispose() {
    _bleBatteryLevelListener?.cancel();
    _reconnectionTimer?.cancel();
    _disconnectDebouncer.cancel();
    _connectDebouncer.cancel();
    ServiceManager.instance().device.unsubscribe(this);
    super.dispose();
  }

  /// 设备断开连接时的回调
  /// 清理设备状态，显示断开通知，启动重连机制
  void onDeviceDisconnected() async {
    Logger.debug('onDisconnected inside: $connectedDevice');
    _havingNewFirmware = false;
    setConnectedDevice(null);
    setisDeviceStorageSupport();
    setIsConnected(false);
    updateConnectingStatus(false);

    captureProvider?.updateRecordingDevice(null);

    // Wals
    ServiceManager.instance().wal.getSyncs().sdcard.setDevice(null);

    PlatformManager.instance.crashReporter.logInfo('Omi Device Disconnected');
    _disconnectNotificationTimer?.cancel();
    _disconnectNotificationTimer = Timer(const Duration(seconds: 30), () {
      NotificationService.instance.createNotification(
        title: 'Your Omi Device Disconnected',
        body: 'Please reconnect to continue using your Omi.',
      );
    });
    MixpanelManager().deviceDisconnected();

    // Retired 1s to prevent the race condition made by standby power of ble device
    Future.delayed(const Duration(seconds: 1), () {
      periodicConnect('coming from onDisconnect');
    });
  }

  /// 检查是否需要更新固件
  /// 比较当前固件版本和最新版本
  /// @return (消息, 是否需要更新, 最新版本号)
  Future<(String, bool, String)> shouldUpdateFirmware() async {
    if (pairedDevice == null || connectedDevice == null) {
      return ('No paired device is connected', false, '');
    }

    var device = pairedDevice!;
    var latestFirmwareDetails = await getLatestFirmwareVersion(
      deviceModelNumber: device.modelNumber,
      firmwareRevision: device.firmwareRevision,
      hardwareRevision: device.hardwareRevision,
      manufacturerName: device.manufacturerName,
    );

    return await DeviceUtils.shouldUpdateFirmware(
        currentFirmware: device.firmwareRevision, latestFirmwareDetails: latestFirmwareDetails);
  }

  /// 设备连接成功时的回调
  /// 更新设备状态，初始化电量监听，检查固件更新
  /// @param device 连接的设备对象
  void _onDeviceConnected(BtDevice device) async {
    Logger.debug('_onConnected inside: $connectedDevice');
    _disconnectNotificationTimer?.cancel();
    NotificationService.instance.clearNotification(1);
    setConnectedDevice(device);

    if (captureProvider != null) {
      captureProvider?.updateRecordingDevice(device);
    }

    setisDeviceStorageSupport();
    setIsConnected(true);

    // Read initial battery level
    int currentLevel = await _retrieveBatteryLevel(device.id);
    if (currentLevel != -1) {
      batteryLevel = currentLevel;
    }

    // Then set up listener for battery changes
    await initiateBleBatteryListener();
    if (batteryLevel != -1 && batteryLevel < 20) {
      _hasLowBatteryAlerted = false;
    }
    updateConnectingStatus(false);
    await captureProvider?.streamDeviceRecording(device: device);

    await getDeviceInfo();
    SharedPreferencesUtil().deviceName = device.name;

    // Wals
    ServiceManager.instance().wal.getSyncs().sdcard.setDevice(device);

    notifyListeners();

    // Check firmware updates
    _checkFirmwareUpdates();
  }

  /// 处理设备连接事件
  /// 确保连接并调用连接回调
  /// @param deviceId 设备 ID
  void _handleDeviceConnected(String deviceId) async {
    var connection = await ServiceManager.instance().device.ensureConnection(deviceId);
    if (connection == null) {
      return;
    }
    _onDeviceConnected(connection.device);
  }

  /// 检查固件更新
  /// 设备连接后自动检查，有更新时显示对话框
  void _checkFirmwareUpdates() async {
    if (_isFirmwareUpdateInProgress) {
      return;
    }

    await checkFirmwareUpdates();

    // Show firmware update dialog if needed
    if (_havingNewFirmware) {
      // Use a small delay to ensure the UI is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        final context = MyApp.navigatorKey.currentContext;
        if (context != null) {
          showFirmwareUpdateDialog(context);
        }
      });
    }
  }

  /// 检查固件更新（带重试机制）
  /// 最多重试 3 次，每次间隔 3 秒
  /// @return 是否有可用更新
  Future checkFirmwareUpdates() async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 3);

    while (retryCount < maxRetries) {
      try {
        var (message, hasUpdate, version) = await shouldUpdateFirmware();
        _havingNewFirmware = hasUpdate;
        _latestFirmwareVersion = version.isNotEmpty ? version : message;
        notifyListeners();
        return hasUpdate; // Return whether there's an update
      } catch (e) {
        retryCount++;
        Logger.debug('Error checking firmware update (attempt $retryCount): $e');

        if (retryCount == maxRetries) {
          Logger.debug('Max retries reached, giving up');
          _havingNewFirmware = false;
          notifyListeners();
          break;
        }

        await Future.delayed(retryDelay);
      }
    }
    return;
  }

  /// 显示固件更新对话框
  /// 询问用户是否立即更新固件
  /// @param context 上下文对象
  void showFirmwareUpdateDialog(BuildContext context) {
    if (!_havingNewFirmware || !SharedPreferencesUtil().showFirmwareUpdateDialog || _isFirmwareUpdateInProgress) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Firmware Update Available',
        description:
            'A new firmware update ($_latestFirmwareVersion) is available for your Omi device. Would you like to update now?',
        confirmText: 'Update',
        cancelText: 'Later',
        onConfirm: () {
          Navigator.of(context).pop();
          setFirmwareUpdateInProgress(true);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FirmwareUpdate(device: pairedDevice),
            ),
          );
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// 设置设备是否支持存储功能
  /// 通过获取存储列表判断设备是否支持存储
  Future setisDeviceStorageSupport() async {
    if (connectedDevice == null) {
      isDeviceStorageSupport = false;
    } else {
      var storageFiles = await _getStorageList(connectedDevice!.id);
      isDeviceStorageSupport = storageFiles.isNotEmpty;
    }
    notifyListeners();
  }

  /// 设备连接状态变化回调
  /// 处理连接和断开事件，使用防抖避免频繁触发
  /// @param deviceId 设备 ID
  /// @param state 连接状态
  @override
  void onDeviceConnectionStateChanged(String deviceId, DeviceConnectionState state) async {
    Logger.debug("provider > device connection state changed...$deviceId...$state...${connectedDevice?.id}");
    switch (state) {
      case DeviceConnectionState.connected:
        _disconnectDebouncer.cancel();
        _connectDebouncer.run(() => _handleDeviceConnected(deviceId));
        break;
      case DeviceConnectionState.disconnected:
        _connectDebouncer.cancel();
        // Check if this is the paired device or currently connected device
        // Coz connectedDevice and pairedDevice are the same but connectedDevice becomes null after disconnect
        if (deviceId == connectedDevice?.id || deviceId == pairedDevice?.id) {
          _disconnectDebouncer.run(onDeviceDisconnected);
        }
        break;
    }
  }

  /// 设备列表变化回调
  /// 如果设置了自动连接标志，自动连接第一个发现的未配对设备
  /// @param devices 设备列表
  @override
  void onDevices(List<BtDevice> devices) async {
    if (_autoConnectFirstDevice && devices.isNotEmpty && !isConnected && connectedDevice == null) {
      // Find the first unpaired device (not in SharedPreferences)
      final pairedDeviceId = SharedPreferencesUtil().btDevice.id;
      BtDevice? deviceToConnect;

      if (pairedDeviceId.isEmpty) {
        // No paired device, connect to the first discovered device
        deviceToConnect = devices.first;
      } else {
        // Find first device that is not the paired device
        try {
          deviceToConnect = devices.firstWhere((d) => d.id != pairedDeviceId);
        } catch (e) {
          // No unpaired device found
          deviceToConnect = null;
        }
      }

      if (deviceToConnect != null) {
        Logger.debug('Auto-connecting to first discovered unpaired device: ${deviceToConnect.name}');
        _autoConnectFirstDevice = false; // Reset flag before connecting
        try {
          await ServiceManager.instance().device.ensureConnection(deviceToConnect.id, force: true);
          Logger.debug('Auto-connection initiated for device: ${deviceToConnect.name}');
        } catch (e) {
          Logger.debug('Auto-connection failed: $e');
        }
      }
    }
  }

  /// 设备服务状态变化回调（未实现）
  /// @param status 服务状态
  @override
  void onStatusChanged(DeviceServiceStatus status) {}

  /// 准备 DFU（设备固件更新）
  /// 断开设备连接并设置 30 秒后重连
  prepareDFU() {
    if (connectedDevice == null) {
      return;
    }
    _bleDisconnectDevice(connectedDevice!);
    _reconnectAt = DateTime.now().add(const Duration(seconds: 30));
  }

  /// 重置固件更新状态
  /// 在更新完成或失败时调用
  void resetFirmwareUpdateState() {
    _isFirmwareUpdateInProgress = false;
    notifyListeners();
  }

  /// 设置固件更新进行中状态
  /// 开始更新时调用
  /// @param inProgress true 表示正在更新，false 表示更新结束
  void setFirmwareUpdateInProgress(bool inProgress) {
    _isFirmwareUpdateInProgress = inProgress;
    notifyListeners();
  }
}
