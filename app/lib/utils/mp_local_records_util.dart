import 'dart:convert';

import 'package:flutter/material.dart';
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
  }) async {
    // 通过path获取到filename
    final String filename = fileName ?? path.split('/').last;
    final model = MPLocalMemoryModel(
      fileName: filename,
      createAt: createAt,
      path: path,
      source: source,
      duration: duration,
      isRemoved: false,
    );
    _localRecords.add(model);
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _localRecords.map((e) => e.toJsonString()).toList();
    await prefs.setStringList('mp_local_records', jsonList);
    return _localRecords;
  }

  /// 删除本地记录
  /// @param path 文件路径
  /// @param fildId 文件ID
  /// @returns 删除后的本地记录列表
  Future<List<MPLocalMemoryModel>> removeLocalRecord(
    String path, {
    required String fildId,
  }) async {
    for (var element in _localRecords) {
      if (element.path == path) {
        element.isRemoved = true;
        element.fileId = fildId;
        break;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _localRecords.map((e) => e.toJsonString()).toList();
    await prefs.setStringList('mp_local_records', jsonList);
    return _localRecords;
  }

  /// 获取本地记录的文件路径
  /// @param fileId 文件ID
  /// @returns 文件路径
  Future<String> getLocalRecordPath(String recordFile) async {
    if (recordFile.isEmpty) {
      return '';
    }
    final fileId = MPLocalRecordsUtil.getFileIdFromUrl(recordFile);
    final locaRecords = await MPLocalRecordsUtil.instance.loadLocalRecords();
    for (var el in locaRecords) {
      if (el.fileId == fileId) {
        if (el.path.isNotEmpty) {
          return el.path;
        }
        break;
      }
    }
    return recordFile;
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
