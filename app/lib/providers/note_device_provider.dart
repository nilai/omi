/// Note 设备状态管理 Provider
/// 负责设备连接、信息查询和设备操作
library;

import 'package:flutter/foundation.dart';
import '../backend/schema/bt_device/bt_device.dart';
import '../backend/schema/bt_device/note_device.dart';
import '../services/devices.dart';
import '../services/devices/device_connection.dart';
import '../services/devices/note_connection.dart';
import '../services/devices/note_storage_manager.dart';
import 'base_provider.dart';

/// Note 设备 Provider
///
/// 功能:
/// - 设备连接/断开管理
/// - 设备信息查询和刷新
/// - 设备操作(绑定、解绑、重启、恢复出厂)
class NoteDeviceProvider extends BaseProvider {
  /// 设备连接实例
  NoteDeviceConnection? _connection;

  /// 设备信息
  NoteDevice? _deviceInfo;

  /// 连接状态
  bool _isConnected = false;

  /// 正在连接
  bool _isConnecting = false;

  /// 获取设备信息
  NoteDevice? get deviceInfo => _deviceInfo;

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 是否正在连接
  bool get isConnecting => _isConnecting;

  /// 获取连接实例(供 OTA Provider 使用)
  NoteDeviceConnection? get connection => _connection;

  /// 连接设备
  ///
  /// device: 要连接的设备
  Future<void> connectDevice(BtDevice device) async {
    if (_isConnecting) {
      print('[NoteDeviceProvider] 正在连接中,跳过重复连接请求');
      return;
    }

    _isConnecting = true;
    setLoadingState(true);
    notifyListeners();

    try {
      print('[NoteDeviceProvider] 开始连接设备: ${device.name}');

      // 通过工厂创建连接
      final connection = DeviceConnectionFactory.create(device);
      if (connection == null || connection is! NoteDeviceConnection) {
        throw Exception('无法创建 Note 设备连接');
      }

      _connection = connection;

      // 执行连接(会自动执行初始化:RTC同步、绑定检查等)
      await _connection!.connect(
        onConnectionStateChanged: (deviceId, state) {
          print('[NoteDeviceProvider] 连接状态变化: $state');
          _isConnected = state == DeviceConnectionState.connected;
          notifyListeners();
        },
      );

      _isConnected = true;
      print('[NoteDeviceProvider] 设备连接成功');

      // 加载设备信息
      await _loadDeviceInfo();
    } catch (e) {
      print('[NoteDeviceProvider] 连接失败: $e');
      _isConnected = false;
      _connection = null;
      rethrow;
    } finally {
      _isConnecting = false;
      setLoadingState(false);
      notifyListeners();
    }
  }

  /// 断开设备
  Future<void> disconnectDevice() async {
    if (_connection == null) {
      print('[NoteDeviceProvider] 设备未连接,无需断开');
      return;
    }

    setLoadingState(true);

    try {
      print('[NoteDeviceProvider] 断开设备连接');
      await _connection!.disconnect();
      _connection = null;
      _deviceInfo = null;
      _isConnected = false;
      print('[NoteDeviceProvider] 设备已断开');
    } catch (e) {
      print('[NoteDeviceProvider] 断开失败: $e');
    } finally {
      setLoadingState(false);
      notifyListeners();
    }
  }

  /// 加载设备信息
  Future<void> _loadDeviceInfo() async {
    if (_connection == null) {
      print('[NoteDeviceProvider] 设备未连接,无法加载信息');
      return;
    }

    try {
      print('[NoteDeviceProvider] 加载设备信息');

      // 查询设备信息
      final battery = await _connection!.performRetrieveBatteryLevel();
      final version = await _connection!.queryFirmwareVersion();
      final storage = await _connection!.queryStorage();

      // 获取绑定信息
      final storageManager = NoteStorageManager();
      final bindingInfo = await storageManager.getDeviceBinding();

      _deviceInfo = NoteDevice(
        id: _connection!.device.id,
        name: _connection!.device.name,
        snid: bindingInfo?.snid,
        isBound: bindingInfo != null,
        batteryLevel: battery,
        firmwareVersion: version,
        storage: storage,
      );

      print('[NoteDeviceProvider] 设备信息已加载: '
          'battery=$battery%, version=$version, storage=${storage.usedMB}/${storage.totalMB}MB');

      notifyListeners();
    } catch (e) {
      print('[NoteDeviceProvider] 加载设备信息失败: $e');
    }
  }

  /// 刷新设备信息
  Future<void> refreshDeviceInfo() async {
    if (!_isConnected || _connection == null) {
      print('[NoteDeviceProvider] 设备未连接,无法刷新信息');
      return;
    }

    setLoadingState(true);

    try {
      await _loadDeviceInfo();
      print('[NoteDeviceProvider] 设备信息已刷新');
    } catch (e) {
      print('[NoteDeviceProvider] 刷新设备信息失败: $e');
    } finally {
      setLoadingState(false);
    }
  }

  /// 设备绑定
  Future<void> bindDevice() async {
    if (_connection == null) {
      throw Exception('设备未连接');
    }

    setLoadingState(true);

    try {
      print('[NoteDeviceProvider] 执行设备绑定');
      await _connection!.bindDevice();
      await _loadDeviceInfo();
      print('[NoteDeviceProvider] 设备绑定成功');
    } catch (e) {
      print('[NoteDeviceProvider] 设备绑定失败: $e');
      rethrow;
    } finally {
      setLoadingState(false);
    }
  }

  /// 设备解绑
  Future<void> unbindDevice() async {
    if (_connection == null) {
      throw Exception('设备未连接');
    }

    setLoadingState(true);

    try {
      print('[NoteDeviceProvider] 执行设备解绑');
      await _connection!.unbindDevice();
      await disconnectDevice();
      print('[NoteDeviceProvider] 设备解绑成功');
    } catch (e) {
      print('[NoteDeviceProvider] 设备解绑失败: $e');
      rethrow;
    } finally {
      setLoadingState(false);
    }
  }

  /// 设备重启
  Future<void> rebootDevice() async {
    if (_connection == null) {
      throw Exception('设备未连接');
    }

    setLoadingState(true);

    try {
      print('[NoteDeviceProvider] 执行设备重启');
      await _connection!.reboot();
      print('[NoteDeviceProvider] 设备重启命令已发送');
      // 设备重启后会断开连接
      await Future.delayed(const Duration(seconds: 1));
      await disconnectDevice();
    } catch (e) {
      print('[NoteDeviceProvider] 设备重启失败: $e');
      rethrow;
    } finally {
      setLoadingState(false);
    }
  }

  /// 恢复出厂设置
  ///
  /// keepRecordings: 是否保留录音文件
  /// 返回: 是否成功
  Future<bool> factoryReset({bool keepRecordings = false}) async {
    if (_connection == null) {
      throw Exception('设备未连接');
    }

    setLoadingState(true);

    try {
      print('[NoteDeviceProvider] 执行恢复出厂设置 (保留录音: $keepRecordings)');
      final success = await _connection!.factoryReset(keepRecordings: keepRecordings);

      if (success) {
        print('[NoteDeviceProvider] 恢复出厂设置成功');
        await disconnectDevice();
      } else {
        print('[NoteDeviceProvider] 恢复出厂设置失败');
      }

      return success;
    } catch (e) {
      print('[NoteDeviceProvider] 恢复出厂设置失败: $e');
      rethrow;
    } finally {
      setLoadingState(false);
    }
  }

  /// 获取文件列表
  Future<List<NoteFileInfo>> getFileList() async {
    if (_connection == null) {
      throw Exception('设备未连接');
    }

    setLoadingState(true);

    try {
      print('[NoteDeviceProvider] 获取文件列表');
      final files = await _connection!.getFileList();
      print('[NoteDeviceProvider] 文件列表已获取,共 ${files.length} 个文件');
      return files;
    } catch (e) {
      print('[NoteDeviceProvider] 获取文件列表失败: $e');
      rethrow;
    } finally {
      setLoadingState(false);
    }
  }

  /// 删除文件
  Future<void> deleteFile(String fileName) async {
    if (_connection == null) {
      throw Exception('设备未连接');
    }

    setLoadingState(true);

    try {
      print('[NoteDeviceProvider] 删除文件: $fileName');
      await _connection!.deleteFile(fileName);
      print('[NoteDeviceProvider] 文件已删除');
    } catch (e) {
      print('[NoteDeviceProvider] 删除文件失败: $e');
      rethrow;
    } finally {
      setLoadingState(false);
    }
  }

  /// 开始录音
  Future<bool> startRecording() async {
    if (_connection == null) {
      throw Exception('设备未连接');
    }

    setLoadingState(true);

    try {
      print('[NoteDeviceProvider] 开始录音');
      final success = await _connection!.startRecording();
      if (success) {
        print('[NoteDeviceProvider] 录音已开始');
      } else {
        print('[NoteDeviceProvider] 开始录音失败');
      }
      return success;
    } catch (e) {
      print('[NoteDeviceProvider] 开始录音失败: $e');
      rethrow;
    } finally {
      setLoadingState(false);
    }
  }

  /// 停止录音
  Future<Map<String, dynamic>> stopRecording() async {
    if (_connection == null) {
      throw Exception('设备未连接');
    }

    setLoadingState(true);

    try {
      print('[NoteDeviceProvider] 停止录音');
      final result = await _connection!.stopRecording();
      if (result['success'] == true) {
        print('[NoteDeviceProvider] 录音已停止');
      } else {
        print('[NoteDeviceProvider] 停止录音失败');
      }
      return result;
    } catch (e) {
      print('[NoteDeviceProvider] 停止录音失败: $e');
      rethrow;
    } finally {
      setLoadingState(false);
    }
  }

  @override
  void dispose() {
    _connection?.disconnect();
    super.dispose();
  }
}
