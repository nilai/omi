/// Note 设备 OTA 升级服务
/// 负责固件版本检查、下载、传输和升级触发

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'note_connection.dart';
import 'note_commands.dart';

/// OTA 版本信息
class OtaVersionInfo {
  /// 是否需要升级 8711 模块
  final bool need8711Update;

  /// 是否需要升级 3085 模块
  final bool need3085Update;

  /// 8711 固件下载地址
  final String? url8711;

  /// 3085 固件下载地址
  final String? url3085;

  OtaVersionInfo({
    required this.need8711Update,
    required this.need3085Update,
    this.url8711,
    this.url3085,
  });

  /// 是否需要升级
  bool get needsUpdate => need8711Update || need3085Update;

  @override
  String toString() => 'OtaVersionInfo('
      'need8711: $need8711Update, '
      'need3085: $need3085Update, '
      'url8711: ${url8711 ?? "N/A"}, '
      'url3085: ${url3085 ?? "N/A"})';
}

/// Note 设备 OTA 升级服务
///
/// 功能:
/// - 检查云端版本
/// - 下载固件文件
/// - 传输固件到设备
/// - 触发升级
class NoteOtaService {
  final NoteDeviceConnection _connection;

  /// OTA 服务器地址 (需要根据实际情况配置)
  static const String otaServerUrl = 'http://your-ota-server.com/check_ota_update';

  /// 客户ID (需要根据实际情况配置)
  static const String customerId = 'your_customer_id';

  NoteOtaService(this._connection);

  /// 检查云端版本
  ///
  /// currentVersion: 当前设备版本号,格式为 "vX.Y.Z"
  /// 返回: OTA 版本信息
  Future<OtaVersionInfo> checkVersion(String currentVersion) async {
    try {
      print('[NoteOta] 检查版本更新: 当前版本 $currentVersion');

      // 解析版本号: vX.Y.Z
      // 3085 模块版本 = X, 8711 模块版本 = Y
      final cleanedVersion = currentVersion.replaceAll(' ', '').replaceFirst('v', '');
      final parts = cleanedVersion.split('.');

      final verCode3085 = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
      final verCode8711 = parts.length >= 2 ? (int.tryParse(parts[1]) ?? 0) : 0;

      print('[NoteOta] 版本解析: 3085=$verCode3085, 8711=$verCode8711');

      // 构造请求体
      final requestBody = {
        "customer": customerId,
        "verCode8711": verCode8711.toString(),
        "verCode3085": verCode3085.toString(),
      };

      // 发送请求到服务器
      final response = await http.post(
        Uri.parse(otaServerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('[NoteOta] 服务器响应: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        print('[NoteOta] 响应数据: $jsonResponse');

        if (jsonResponse['result'] == '1' && jsonResponse['info'] is Map) {
          final info = jsonResponse['info'] as Map<String, dynamic>;

          final versionInfo = OtaVersionInfo(
            need8711Update: info['upgrade8711'] == '1',
            need3085Update: info['upgrade3085'] == '1',
            url8711: info['href8711'] as String?,
            url3085: info['href3085'] as String?,
          );

          print('[NoteOta] 版本检查结果: $versionInfo');
          return versionInfo;
        }
      }

      // 默认返回不需要升级
      print('[NoteOta] 未发现新版本');
      return OtaVersionInfo(
        need8711Update: false,
        need3085Update: false,
      );
    } catch (e) {
      print('[NoteOta] 版本检查失败: $e');
      // 出错时返回不需要升级
      return OtaVersionInfo(
        need8711Update: false,
        need3085Update: false,
      );
    }
  }

  /// 下载固件
  ///
  /// url: 固件下载地址
  /// moduleType: 模块类型标识 (用于文件命名)
  /// 返回: 下载后的临时文件
  Future<File> downloadFirmware(String url, String moduleType) async {
    print('[NoteOta] 开始下载固件: $url');

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('固件下载失败: HTTP ${response.statusCode}');
    }

    // 保存到临时文件
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/ota_$moduleType.bin');
    await file.writeAsBytes(response.bodyBytes);

    print('[NoteOta] 固件已下载: ${file.path}, 大小: ${response.bodyBytes.length} 字节');
    return file;
  }

  /// 传输固件到设备
  ///
  /// firmwareFile: 固件文件
  /// module: OTA 模块类型
  /// onProgress: 进度回调 (0.0 ~ 1.0)
  /// 返回: 是否传输成功
  Future<bool> transferFirmware(
    File firmwareFile,
    NoteOtaModule module,
    Function(double)? onProgress,
  ) async {
    try {
      print('[NoteOta] 开始传输固件: ${firmwareFile.path}');

      final fileBytes = await firmwareFile.readAsBytes();
      final md5Hash = md5.convert(fileBytes);
      final md5Bytes = _hexToBytes(md5Hash.toString());

      print('[NoteOta] 固件大小: ${fileBytes.length} 字节');
      print('[NoteOta] MD5: ${md5Hash.toString()}');

      // 1. 准备 OTA (发送模块类型和 MD5)
      final prepareCmd = [0xF6, 0x01, module.value, ...md5Bytes];
      final prepareResponse = await _connection.sendCommandWithResponse(prepareCmd);

      if (prepareResponse.isEmpty ||
          prepareResponse[0] != 0xF6 ||
          prepareResponse[1] != 0x01) {
        print('[NoteOta] OTA 准备失败: 响应异常');
        return false;
      }

      print('[NoteOta] OTA 准备成功');

      // 2. 分包传输
      const chunkSize = 500; // 每包 500 字节
      int offset = 0;
      final totalSize = fileBytes.length;

      while (offset < totalSize) {
        final end = (offset + chunkSize) < totalSize ? offset + chunkSize : totalSize;
        final chunk = fileBytes.sublist(offset, end);

        await _connection.sendOtaData(chunk);

        offset = end;
        final progress = offset / totalSize;
        onProgress?.call(progress);

        if (offset % 5000 == 0 || offset == totalSize) {
          print('[NoteOta] 传输进度: ${(progress * 100).toStringAsFixed(1)}%');
        }

        // 避免发送过快导致设备缓冲区溢出
        await Future.delayed(Duration(milliseconds: 10));
      }

      print('[NoteOta] 固件传输完成');

      // 3. 完成传输
      final finishCmd = [0xF6, 0x02];
      final finishResponse = await _connection.sendCommandWithResponse(finishCmd);

      if (finishResponse.isEmpty ||
          finishResponse[0] != 0xF6 ||
          finishResponse[1] != 0x02) {
        print('[NoteOta] OTA 完成确认失败: 响应异常');
        return false;
      }

      print('[NoteOta] OTA 传输流程完成');

      // 4. 删除临时文件
      if (await firmwareFile.exists()) {
        await firmwareFile.delete();
        print('[NoteOta] 临时文件已删除');
      }

      return true;
    } catch (e) {
      print('[NoteOta] 固件传输失败: $e');
      return false;
    }
  }

  /// 触发 OTA 升级
  ///
  /// module: OTA 模块类型
  /// 返回: 是否触发成功
  Future<bool> triggerUpgrade(NoteOtaModule module) async {
    try {
      print('[NoteOta] 触发 ${module == NoteOtaModule.module8711 ? "8711" : "3085"} 模块升级');

      final command = module == NoteOtaModule.module8711
          ? [0xE6, 0x03] // 进入 8711 OTA 模式
          : [0xE6, 0x02]; // 进入 3085 OTA 模式

      if (module == NoteOtaModule.module8711) {
        // 8711 模块升级需要等待响应
        final response = await _connection.sendCommandWithResponse(command);

        final success = response.isNotEmpty &&
            response[0] == 0xE6 &&
            response[1] == 0x03 &&
            response[2] == 0x01;

        if (success) {
          print('[NoteOta] 8711 模块升级已触发');
        } else {
          print('[NoteOta] 8711 模块升级触发失败');
        }

        return success;
      } else {
        // 3085 模块升级后设备会重启,不等待响应
        await _connection.sendCommandWithResponse(
          command,
          timeout: Duration(seconds: 2),
        );
        print('[NoteOta] 3085 模块升级已触发 (设备即将重启)');
        return true;
      }
    } catch (e) {
      print('[NoteOta] 触发升级失败: $e');
      return false;
    }
  }

  /// 十六进制字符串转字节数组
  ///
  /// hexString: 十六进制字符串 (如 "a1b2c3d4")
  /// 返回: 字节数组
  List<int> _hexToBytes(String hexString) {
    final result = <int>[];
    for (int i = 0; i < hexString.length; i += 2) {
      final byteStr = hexString.substring(i, i + 2);
      result.add(int.parse(byteStr, radix: 16));
    }
    return result;
  }
}
