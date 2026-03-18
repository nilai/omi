import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MPLocalMemoryModel {
  MPLocalMemoryModel({
    required this.fileName,
    required this.createAt,
    required this.path,
    this.duration,
    this.fileId = '',
    required this.source,
    this.isRemoved = false,
  });

  /// 文件名
  final String fileName;

  /// 创建时间
  final int createAt;

  /// 本地文件路径
  final String path;

  /// 是否已从本地删除
  bool isRemoved = false;

  /// sdcards记录，中间时间
  int? duration;

  /// 上传文件时，后端返回的文件id
  String fileId;

  /// 文件来源(mobile phone or mp)
  final String source;

  factory MPLocalMemoryModel.fromJson(Map<String, dynamic> json) => MPLocalMemoryModel(
      fileName: json['fileName'],
      createAt: json['createAt'],
      path: json['path'],
      duration: json['duration'],
      fileId: json['fileId'],
      source: json['source'],
      isRemoved: json['isRemoved']);

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'createAt': createAt,
        'path': path,
        'duration': duration,
        'fileId': fileId,
        'source': source,
        'isRemoved': isRemoved,
      };

  /// 将模型转为 json 字符串
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// 从 json 字符串解析创建模型
  static MPLocalMemoryModel fromJsonString(String jsonString) {
    final Map<String, dynamic> map = jsonDecode(jsonString);
    return MPLocalMemoryModel.fromJson(map);
  }

  /// 获取显示名称
  String get showName {
    if (fileName.isEmpty) {
      return '';
    }
    if (fileName.startsWith('mp')) {
      return fileName.split('_').last;
    }
    return fileName;
  }
}

/// 本地记录工具类
/// 单例模式，提供本地记录的增删查改功能
class MPLocalRecordsUtil {
  /// 私有构造函数
  MPLocalRecordsUtil._();

  /// 单例实例
  static final MPLocalRecordsUtil instance = MPLocalRecordsUtil._();

  /// 本地记录列表
  List<MPLocalMemoryModel> _localRecords = [];

  /// 获取本地记录
  /// 如果 _localRecords 不为空，直接返回；如果为空，先加载数据，然后返回
  /// @returns 本地记录列表
  Future<List<MPLocalMemoryModel>> getLocalRecords() async {
    if (_localRecords.isNotEmpty) {
      return _localRecords;
    }
    await loadLocalRecords();
    return _localRecords;
  }

  /// 加载本地记录
  /// @returns 加载后的本地记录列表
  Future<List<MPLocalMemoryModel>> loadLocalRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getStringList('mp_local_records');
    if (jsonString != null) {
      _localRecords = jsonString.map((e) => MPLocalMemoryModel.fromJsonString(e)).toList();
    } else {
      _localRecords = [];
    }
    return _localRecords;
  }

  /// 添加本地记录
  /// @param path 文件路径
  /// @param duration 时长（可选）
  /// @param fileName 文件名（可选）
  /// @param source 文件来源
  /// @returns 添加后的本地记录列表
  Future<List<MPLocalMemoryModel>> addLocalRecord(
    String path, {
    int? duration,
    String? fileName,
    required String source,
    required int createAt,
    bool isRemoved = false,
    String? fileId,
  }) async {
    // 通过path获取到filename
    final String filename = fileName ?? path.split('/').last;

    // 检查是否已存在相同路径的记录，如果存在则删除旧记录
    _localRecords.removeWhere((element) => element.path == path);

    // 添加新记录
    final model = MPLocalMemoryModel(
      fileName: filename,
      createAt: createAt,
      path: path,
      source: source,
      duration: duration,
      isRemoved: isRemoved,
      fileId: fileId ?? '',
    );
    _localRecords.add(model);
    debugPrint('-------hjj------addLocalRecord path: $path, isRemoved: $isRemoved , fileId: $fileId');

    final prefs = await SharedPreferences.getInstance();
    final jsonList = _localRecords.map((e) => e.toJsonString()).toList();
    await prefs.setStringList('mp_local_records', jsonList);
    return _localRecords;
  }

  /// 删除本地记录
  /// @param model 本地记录模型
  /// @param fildId 文件ID
  /// @returns 删除后的本地记录列表
  Future<List<MPLocalMemoryModel>> removeLocalRecord(MPLocalMemoryModel model) async {
    for (var element in _localRecords) {
      if (element.path == model.path && element.createAt == model.createAt) {
        element.isRemoved = true;
        debugPrint('-------hjj------removeLocalRecord path: ${element.path}');
        break;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _localRecords.map((e) => e.toJsonString()).toList();
    await prefs.setStringList('mp_local_records', jsonList);
    return _localRecords;
  }

  /// 将包含中文的文件路径转换为 MD5 编码的路径（iOS 26+ 兼容）
  /// 路径格式：{目录}/{timestamp}_{filename}.ext
  /// 转换后：{目录}/{timestamp}_{md5}.ext
  /// @param originalPath 原始路径
  /// @returns MD5 编码后的路径，如果不需要转换则返回原路径
  static String _convertToMd5Path(String originalPath) {
    if (!Platform.isIOS) {
      return originalPath;
    }

    try {
      // 提取目录和文件名
      final pathParts = originalPath.split('/');
      if (pathParts.isEmpty) {
        return originalPath;
      }

      final fileName = pathParts.last;
      // 检查文件名是否包含非 ASCII 字符
      final hasNonAscii = fileName.runes.any((rune) => rune > 127);
      if (!hasNonAscii) {
        return originalPath;
      }

      // 文件名格式可能是：{timestamp}_{filename}.ext 或 {filename}.ext
      // 需要保留时间戳前缀（如果存在）
      final lastDotIndex = fileName.lastIndexOf('.');
      final nameWithoutExt = lastDotIndex > 0 ? fileName.substring(0, lastDotIndex) : fileName;
      final extension = lastDotIndex > 0 ? fileName.substring(lastDotIndex) : '';

      // 检查是否有时间戳前缀（格式：{timestamp}_{filename}）
      String? timestampPrefix;
      String nameToHash = nameWithoutExt;
      final underscoreIndex = nameWithoutExt.indexOf('_');
      if (underscoreIndex > 0) {
        // 提取时间戳前缀
        final prefix = nameWithoutExt.substring(0, underscoreIndex);
        // 检查是否是时间戳（纯数字，长度通常为 13 位）
        if (prefix.length >= 10 && prefix.length <= 15 && RegExp(r'^\d+$').hasMatch(prefix)) {
          timestampPrefix = prefix;
          nameToHash = nameWithoutExt.substring(underscoreIndex + 1);
        }
      }

      // 生成 MD5 哈希（只对文件名部分，不包括时间戳）
      final bytes = utf8.encode(nameToHash);
      final digest = md5.convert(bytes);
      final md5Hash = digest.toString();

      // 构建新的文件名
      final newFileName = timestampPrefix != null ? '${timestampPrefix}_$md5Hash$extension' : '$md5Hash$extension';

      // 构建新的路径
      pathParts[pathParts.length - 1] = newFileName;
      return pathParts.join('/');
    } catch (e) {
      debugPrint('MPLocalRecordsUtil: 转换 MD5 路径失败: $e');
      return originalPath;
    }
  }

  /// 获取本地记录的文件路径
  /// @param recordFile 记录文件 URL
  /// @returns 文件路径，如果文件不存在，会尝试更新应用容器ID或查找 MD5 编码的路径
  Future<String?> getLocalRecordPath(String recordFile) async {
    if (recordFile.isEmpty) {
      return null;
    }
    final fileId = MPLocalRecordsUtil.getFileIdFromUrl(recordFile);
    final locaRecords = await MPLocalRecordsUtil.instance.loadLocalRecords();
    for (var el in locaRecords) {
      if (el.fileId == fileId) {
        if (el.path.isNotEmpty) {
          final originalPath = el.path;

          // 检查文件是否存在
          final file = File(originalPath);
          final fileExists = await file.exists();

          if (fileExists) {
            return originalPath;
          }

          // 如果文件不存在，尝试更新应用容器ID（iOS应用重新安装后容器ID会变化）
          if (Platform.isIOS) {
            // 尝试使用当前应用容器路径替换旧路径
            final updatedPath = await _updateContainerId(originalPath);
            if (updatedPath != null && updatedPath != originalPath) {
              final updatedFile = File(updatedPath);
              final updatedFileExists = await updatedFile.exists();
              if (updatedFileExists) {
                // 更新记录中的路径
                final updatedModel = MPLocalMemoryModel(
                  fileName: el.fileName,
                  createAt: el.createAt,
                  path: updatedPath,
                  duration: el.duration,
                  fileId: el.fileId,
                  source: el.source,
                  isRemoved: el.isRemoved,
                );
                final index = _localRecords.indexOf(el);
                if (index >= 0) {
                  _localRecords[index] = updatedModel;
                  final prefs = await SharedPreferences.getInstance();
                  final jsonList = _localRecords.map((e) => e.toJsonString()).toList();
                  await prefs.setStringList('mp_local_records', jsonList);
                }
                return updatedPath;
              }
            }

            // 如果更新容器ID后还是不存在，尝试查找 MD5 编码的路径
            // 即使文件名不包含非ASCII字符，也可能因为保存时使用了MD5编码
            final md5Path = _convertToMd5Path(originalPath);
            if (md5Path != originalPath) {
              final md5File = File(md5Path);
              final md5FileExists = await md5File.exists();

              if (md5FileExists) {
                // 找到 MD5 路径的文件，更新记录中的路径
                final updatedModel = MPLocalMemoryModel(
                  fileName: el.fileName,
                  createAt: el.createAt,
                  path: md5Path,
                  duration: el.duration,
                  fileId: el.fileId,
                  source: el.source,
                  isRemoved: el.isRemoved,
                );
                final index = _localRecords.indexOf(el);
                if (index >= 0) {
                  _localRecords[index] = updatedModel;
                  final prefs = await SharedPreferences.getInstance();
                  final jsonList = _localRecords.map((e) => e.toJsonString()).toList();
                  await prefs.setStringList('mp_local_records', jsonList);
                }
                return md5Path;
              }
            }

            // 如果MD5路径也不存在，尝试更新容器ID后的MD5路径
            if (md5Path != originalPath) {
              final updatedMd5Path = await _updateContainerId(md5Path);
              if (updatedMd5Path != null && updatedMd5Path != md5Path) {
                final updatedMd5File = File(updatedMd5Path);
                final updatedMd5FileExists = await updatedMd5File.exists();
                if (updatedMd5FileExists) {
                  final updatedModel = MPLocalMemoryModel(
                    fileName: el.fileName,
                    createAt: el.createAt,
                    path: updatedMd5Path,
                    duration: el.duration,
                    fileId: el.fileId,
                    source: el.source,
                    isRemoved: el.isRemoved,
                  );
                  final index = _localRecords.indexOf(el);
                  if (index >= 0) {
                    _localRecords[index] = updatedModel;
                    final prefs = await SharedPreferences.getInstance();
                    final jsonList = _localRecords.map((e) => e.toJsonString()).toList();
                    await prefs.setStringList('mp_local_records', jsonList);
                  }
                  return updatedMd5Path;
                }
              }
            }
          }

          // 文件不存在，返回 null（调用方会尝试重新下载）
          return null;
        }
        break;
      }
    }
    return null;
  }

  /// 更新路径中的应用容器ID（iOS）
  /// @param originalPath 原始路径
  /// @returns 更新后的路径，如果无法更新则返回 null
  static Future<String?> _updateContainerId(String originalPath) async {
    if (!Platform.isIOS) {
      return null;
    }

    try {
      // iOS路径格式：/var/mobile/Containers/Data/Application/{容器ID}/Documents/...
      // 提取相对路径部分（Documents之后的部分）
      final documentsIndex = originalPath.indexOf('/Documents/');
      if (documentsIndex == -1) {
        return null;
      }

      final relativePath = originalPath.substring(documentsIndex + '/Documents/'.length);

      // 获取当前应用的Documents目录
      final appDir = await getApplicationDocumentsDirectory();
      final newPath = '${appDir.path}/$relativePath';

      return newPath;
    } catch (e) {
      debugPrint('MPLocalRecordsUtil: 更新容器ID失败: $e');
      return null;
    }
  }

  /// 从URL中获取音频文件名
  ///
  /// [url] 音频文件的URL地址
  ///
  /// 返回文件名，例如从 `audios/44726b9e-ef76-4f89-8e60-fb22b8c9abc8?` 中提取 `44726b9e-ef76-4f89-8e60-fb22b8c9abc8`
  static String getFileIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;

      // 查找 'audios/' 的位置
      final audiosIndex = path.indexOf('audios/');
      if (audiosIndex == -1) {
        debugPrint('MPAudioDownloadService: URL中未找到 audios/ 路径');
        return url;
      }

      // 提取 audios/ 后面的部分
      final afterAudios = path.substring(audiosIndex + 'audios/'.length);

      // 如果后面有 '/' 或 '?'，则截取到该位置
      final fileName = afterAudios.split('/').first.split('?').first;

      if (fileName.isEmpty) {
        debugPrint('MPAudioDownloadService: 无法从URL中提取文件名');
        return url;
      }

      debugPrint('MPAudioDownloadService: 提取的文件名: $fileName');
      return fileName;
    } catch (e) {
      debugPrint('MPAudioDownloadService: 提取文件名异常: $e');
      return url;
    }
  }
}
