import 'package:flutter/material.dart';
import 'package:omi/pages/mp_custom_utils/mp_toast_utils.dart';
import 'package:omi/providers/device_provider.dart';
import 'package:omi/services/devices/note_connection.dart';
import 'package:omi/services/services.dart';
import 'package:provider/provider.dart';

/// 录音工具类
///
/// 提供设备录音的开始和停止功能
/// 单例模式，通过 instance 获取实例
class MPRecordAudioUtil {
  /// 私有构造函数
  MPRecordAudioUtil._();

  /// 单例实例
  static final MPRecordAudioUtil instance = MPRecordAudioUtil._();

  /// 是否正在录音
  bool _isRecording = false;

  /// 获取是否正在录音
  bool get isRecording => _isRecording;

  /// 开始录音
  ///
  /// [context] BuildContext，用于获取 DeviceProvider
  ///
  /// 返回录音是否成功开始
  ///
  /// 如果正在录音，则直接返回 false
  Future<bool> startRecording(BuildContext context) async {
    // 如果正在录音，直接返回
    if (_isRecording) {
      print('[MPRecordAudioUtil] 正在录音中，跳过重复请求');
      return false;
    }

    try {
      // 获取 DeviceProvider
      final deviceProvider = context.read<DeviceProvider>();

      // 检查设备是否已连接
      if (deviceProvider.connectedDevice == null) {
        _toast('设备未连接');
        throw Exception('设备未连接');
      }

      // 获取设备连接
      final connection = await ServiceManager.instance().device.ensureConnection(deviceProvider.connectedDevice!.id)
          as NoteDeviceConnection?;

      if (connection == null) {
        _toast('无法获取设备连接');
        throw Exception('无法获取设备连接');
      }

      // 开始录音
      final success = await connection.startRecording();

      if (success) {
        _isRecording = true;
        print('[MPRecordAudioUtil] 录音已开始');
      } else {
        print('[MPRecordAudioUtil] 开始录音失败');
        _toast('开始录音失败');
      }

      return success;
    } catch (e) {
      print('[MPRecordAudioUtil] 开始录音失败: $e');
      _toast('开始录音失败: $e');
      _isRecording = false;
      rethrow;
    }
  }

  /// 停止录音
  ///
  /// [context] BuildContext，用于获取 DeviceProvider
  ///
  /// 返回停止录音的结果，包含 success 字段表示是否成功
  Future<Map<String, dynamic>> stopRecording(BuildContext context) async {
    try {
      // 获取 DeviceProvider
      final deviceProvider = context.read<DeviceProvider>();

      // 检查设备是否已连接
      if (deviceProvider.connectedDevice == null) {
        _toast('设备未连接');
        throw Exception('设备未连接');
      }

      // 获取设备连接
      final connection = await ServiceManager.instance().device.ensureConnection(deviceProvider.connectedDevice!.id)
          as NoteDeviceConnection?;

      if (connection == null) {
        _toast('无法获取设备连接');
        throw Exception('无法获取设备连接');
      }

      print('[MPRecordAudioUtil] 停止录音');

      // 停止录音
      final result = await connection.stopRecording();

      if (result['success'] == true) {
        _isRecording = false;
        print('[MPRecordAudioUtil] 录音已停止');
      } else {
        _toast('停止录音失败');
      }

      return result;
    } catch (e) {
      _toast('停止录音失败: $e');
      _isRecording = false;
      rethrow;
    }
  }

  /// 显示Toast
  void _toast(String message) {
    MPToastUtils.showMessage(message);
  }
}
