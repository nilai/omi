/// Note 设备存储管理器
/// 管理设备绑定信息、SNID、设备类型等本地文件存储
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:path_provider/path_provider.dart';

/// 设备绑定信息模型
class DeviceBindingInfo {
  final String deviceId;
  final String deviceName;
  final String snid;

  DeviceBindingInfo({
    required this.deviceId,
    required this.deviceName,
    required this.snid,
  });

  @override
  String toString() => 'DeviceBinding(id: $deviceId, name: $deviceName, snid: $snid)';
}

/// Note 设备存储管理器(单例模式)
///
/// 管理以下文件:
/// - devType.txt: 设备类型标识
/// - devConnect.txt: 设备绑定信息(格式: deviceId|deviceName)
/// - snid.ini: 6字节随机数(hex字符串),用于服务端绑定验证
class NoteStorageManager {
  static final NoteStorageManager _instance = NoteStorageManager._internal();
  factory NoteStorageManager() => _instance;
  NoteStorageManager._internal();

  /// 获取存储基础路径
  /// Android: /storage/emulated/0/Android/data/<package>/
  /// iOS: Application Documents Directory
  Future<String> get _basePath async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      // 根据参考代码,Android 使用 parent.path
      return directory!.parent.path;
    } else {
      // iOS 使用 Application Documents Directory
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
  }

  /// 保存设备绑定信息
  ///
  /// 1. 生成6字节随机SNID
  /// 2. 写入 devConnect.txt (格式: deviceId|deviceName)
  /// 3. 写入 snid.ini (hex字符串)
  Future<void> saveDeviceBinding(String deviceId, String deviceName) async {
    final path = await _basePath;

    // 保存 devConnect.txt
    final connectFile = File('$path/devConnect.txt');
    await connectFile.writeAsString('$deviceId|$deviceName');

    // 生成并保存 snid.ini (6字节随机数)
    final snid = _generateSnid();
    final snidFile = File('$path/snid.ini');
    await snidFile.writeAsString(snid);

    print('[NoteStorage] 设备绑定信息已保存: $deviceId | $deviceName');
    print('[NoteStorage] SNID: $snid');
  }

  /// 获取设备绑定信息
  ///
  /// 返回 DeviceBindingInfo 或 null(如果未绑定)
  Future<DeviceBindingInfo?> getDeviceBinding() async {
    try {
      final path = await _basePath;
      final connectFile = File('$path/devConnect.txt');
      final snidFile = File('$path/snid.ini');

      if (!await connectFile.exists() || !await snidFile.exists()) {
        return null;
      }

      final connectData = await connectFile.readAsString();
      final parts = connectData.split('|');
      if (parts.length != 2) {
        print('[NoteStorage] devConnect.txt 格式错误: $connectData');
        return null;
      }

      final snid = await snidFile.readAsString();

      return DeviceBindingInfo(
        deviceId: parts[0],
        deviceName: parts[1],
        snid: snid,
      );
    } catch (e) {
      print('[NoteStorage] 读取设备绑定信息失败: $e');
      return null;
    }
  }

  /// 检查设备是否已绑定
  ///
  /// 通过检查 devConnect.txt 是否存在来判断
  Future<bool> isDeviceBound() async {
    try {
      final path = await _basePath;
      final connectFile = File('$path/devConnect.txt');
      return await connectFile.exists();
    } catch (e) {
      print('[NoteStorage] 检查绑定状态失败: $e');
      return false;
    }
  }

  /// 清除设备绑定信息
  ///
  /// 删除 devConnect.txt 和 snid.ini 文件
  /// 在解绑或恢复出厂设置时调用
  Future<void> clearDeviceBinding() async {
    try {
      final path = await _basePath;

      final connectFile = File('$path/devConnect.txt');
      if (await connectFile.exists()) {
        await connectFile.delete();
        print('[NoteStorage] devConnect.txt 已删除');
      }

      final snidFile = File('$path/snid.ini');
      if (await snidFile.exists()) {
        await snidFile.delete();
        print('[NoteStorage] snid.ini 已删除');
      }

      print('[NoteStorage] 设备绑定信息已清除');
    } catch (e) {
      print('[NoteStorage] 清除设备绑定信息失败: $e');
      rethrow;
    }
  }

  /// 保存设备类型
  ///
  /// 写入 devType.txt,例如 "AI Note"
  Future<void> saveDeviceType(String deviceType) async {
    try {
      final path = await _basePath;
      final file = File('$path/devType.txt');
      await file.writeAsString(deviceType, mode: FileMode.write);
      print('[NoteStorage] 设备类型已保存: $deviceType');
    } catch (e) {
      print('[NoteStorage] 保存设备类型失败: $e');
      rethrow;
    }
  }

  /// 获取设备类型
  ///
  /// 从 devType.txt 读取,如果文件不存在返回 null
  Future<String?> getDeviceType() async {
    try {
      final path = await _basePath;
      final file = File('$path/devType.txt');
      if (!await file.exists()) {
        return null;
      }
      return await file.readAsString();
    } catch (e) {
      print('[NoteStorage] 读取设备类型失败: $e');
      return null;
    }
  }

  /// 生成 6 字节随机 SNID
  ///
  /// 返回格式: 12位十六进制字符串(例如: "a1b2c3d4e5f6")
  /// 用于服务端绑定验证
  String _generateSnid() {
    final random = Random.secure();
    final bytes = Uint8List(6);
    for (var i = 0; i < 6; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  /// 获取存储路径(用于调试)
  Future<String> getStoragePath() async {
    return await _basePath;
  }

  /// 列出所有Note设备相关文件(用于调试)
  Future<Map<String, bool>> listFiles() async {
    final path = await _basePath;
    return {
      'devType.txt': await File('$path/devType.txt').exists(),
      'devConnect.txt': await File('$path/devConnect.txt').exists(),
      'snid.ini': await File('$path/snid.ini').exists(),
    };
  }
}
