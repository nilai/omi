import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 单条 Audio 本地记录（持久化到 SharedPreferences）。
class MPAudioLocalRecord {
  const MPAudioLocalRecord({
    required this.path,
    required this.fileName,
    required this.createAt,
    this.duration,
    this.fileId = '',
    required this.source,
    this.isRemoved = false,
  });

  /// 本地绝对路径
  final String path;

  /// 展示用文件名
  final String fileName;

  /// 创建时间 Unix（毫秒或秒，与调用方约定一致）
  final int createAt;

  /// 时长（秒），可选
  final int? duration;

  /// 服务端文件 id，可选
  final String fileId;

  /// 来源标识，如 `mp` / `mobile`
  final String source;

  /// 是否逻辑删除
  final bool isRemoved;

  MPAudioLocalRecord copyWith({
    String? path,
    String? fileName,
    int? createAt,
    int? duration,
    String? fileId,
    String? source,
    bool? isRemoved,
    bool clearDuration = false,
  }) {
    return MPAudioLocalRecord(
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      createAt: createAt ?? this.createAt,
      duration: clearDuration ? null : (duration ?? this.duration),
      fileId: fileId ?? this.fileId,
      source: source ?? this.source,
      isRemoved: isRemoved ?? this.isRemoved,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'path': path,
        'fileName': fileName,
        'createAt': createAt,
        'duration': duration,
        'fileId': fileId,
        'source': source,
        'isRemoved': isRemoved,
      };

  factory MPAudioLocalRecord.fromJson(Map<String, dynamic> json) {
    return MPAudioLocalRecord(
      path: json['path'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      createAt: json['createAt'] as int? ?? 0,
      duration: json['duration'] as int?,
      fileId: json['fileId'] as String? ?? '',
      source: json['source'] as String? ?? '',
      isRemoved: json['isRemoved'] as bool? ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static MPAudioLocalRecord fromJsonString(String raw) {
    final Map<String, dynamic> map =
        jsonDecode(raw) as Map<String, dynamic>;
    return MPAudioLocalRecord.fromJson(map);
  }
}

/// Audio 详情相关：本地录音记录 **单例**，提供增删查改（持久化键独立）。
class MPAudioLocalRecordsUtil {
  MPAudioLocalRecordsUtil._();

  static final MPAudioLocalRecordsUtil instance = MPAudioLocalRecordsUtil._();

  static const String _prefsKey = 'mp_audio_detail_local_records_v1';

  /// 应用 Documents 下本地录音文件目录名（录音保存、详情下载、上传共用）。
  static const String kLocalStorageDirName = 'mp_audio_records';

  /// 确保 [kLocalStorageDirName] 存在并返回其绝对路径。
  static Future<String> ensureLocalStorageDirectoryPath() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final String dir = p.join(docs.path, kLocalStorageDirName);
    await Directory(dir).create(recursive: true);
    return dir;
  }

  /// 将临时录音复制到 [ensureLocalStorageDirectoryPath] 目录下（与详情下载、索引路径一致）。
  ///
  /// 成功返回新文件绝对路径；失败返回 `null`。[deleteAfterCopy] 为 true 时尝试删除 [tempFile]。
  static Future<String?> copyTempFileToLocalStorage(
    File tempFile, {
    bool deleteAfterCopy = true,
  }) async {
    try {
      if (!await tempFile.exists()) {
        return null;
      }
      final String dir = await ensureLocalStorageDirectoryPath();
      final String ext = p.extension(tempFile.path);
      final String name =
          'omi_record_${DateTime.now().millisecondsSinceEpoch}${ext.isEmpty ? '.aac' : ext}';
      final String destPath = p.join(dir, name);
      await tempFile.copy(destPath);
      if (deleteAfterCopy) {
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (_) {}
      }
      return destPath;
    } catch (e, st) {
      debugPrint('copyTempFileToLocalStorage failed: $e\n$st');
      return null;
    }
  }

  List<MPAudioLocalRecord> _records = <MPAudioLocalRecord>[];

  /// 从远端 URL 或本地路径取稳定「文件名」片段（与下载落盘时的 [MPAudioLocalRecord.fileId] 对齐）。
  static String getFileIdFromUrl(String source) {
    final String s = source.trim();
    if (s.isEmpty) {
      return '';
    }
    final Uri? u = Uri.tryParse(s);
    if (u != null) {
      if ((u.scheme == 'http' || u.scheme == 'https') && u.path.isNotEmpty) {
        final List<String> segs = u.pathSegments;
        if (segs.isNotEmpty) {
          return segs.last.split('?').first;
        }
      }
      if (u.scheme == 'file' && u.path.isNotEmpty) {
        final List<String> segs = u.pathSegments;
        if (segs.isNotEmpty) {
          return segs.last.split('?').first;
        }
      }
    }
    if (s.startsWith('/')) {
      final int lastSlash = s.lastIndexOf('/');
      if (lastSlash >= 0 && lastSlash < s.length - 1) {
        return s.substring(lastSlash + 1).split('?').first;
      }
    }
    final int slash = s.lastIndexOf('/');
    if (slash >= 0 && slash < s.length - 1) {
      return s.substring(slash + 1).split('?').first;
    }
    return s.split('?').first;
  }

  /// 播放前：若本地已有可播放文件则返回绝对路径，否则 `null`（再走网络下载）。
  Future<String?> getLocalRecordPath(String recordFile) async {
    final String raw = recordFile.trim();
    if (raw.isEmpty) {
      return null;
    }

    if (raw.startsWith('/')) {
      final File f = File(raw);
      if (await f.exists()) {
        return f.path;
      }
    }
    final Uri? asUri = Uri.tryParse(raw);
    if (asUri != null && asUri.scheme == 'file') {
      final File f = File.fromUri(asUri);
      if (await f.exists()) {
        return f.path;
      }
    }

    final String fileId = getFileIdFromUrl(raw);
    if (fileId.isNotEmpty) {
      final MPAudioLocalRecord? byId = await queryByFileId(fileId);
      if (byId != null && !byId.isRemoved) {
        final String p = byId.path.trim();
        if (p.isNotEmpty) {
          final File f = File(p);
          if (await f.exists()) {
            return f.path;
          }
        }
      }
    }

    await load();
    for (final MPAudioLocalRecord e in _records) {
      if (e.isRemoved) {
        continue;
      }
      final String p = e.path.trim();
      if (p.isEmpty) {
        continue;
      }
      final File f = File(p);
      if (!await f.exists()) {
        continue;
      }
      if (fileId.isNotEmpty &&
          (e.fileId == fileId || e.fileName == fileId)) {
        return f.path;
      }
    }

    return null;
  }

  Future<void> _persist() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> jsonList =
        _records.map((MPAudioLocalRecord e) => e.toJsonString()).toList();
    await prefs.setStringList(_prefsKey, jsonList);
  }

  /// 从磁盘加载；若内存已有数据且 [force] 为 false 则跳过重复 IO（可先 [clearMemory] 再加载）。
  Future<List<MPAudioLocalRecord>> load({bool force = false}) async {
    if (!force && _records.isNotEmpty) {
      return List<MPAudioLocalRecord>.from(_records);
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? raw = prefs.getStringList(_prefsKey);
    if (raw == null || raw.isEmpty) {
      _records = <MPAudioLocalRecord>[];
    } else {
      _records = raw
          .map((String s) => MPAudioLocalRecord.fromJsonString(s))
          .toList();
    }
    return List<MPAudioLocalRecord>.from(_records);
  }

  /// 仅清空内存缓存（不删 SharedPreferences）。
  void clearMemory() {
    _records = <MPAudioLocalRecord>[];
  }

  /// 全部记录（默认不含已逻辑删除项）。
  Future<List<MPAudioLocalRecord>> queryAll({
    bool includeRemoved = false,
  }) async {
    await load();
    if (includeRemoved) {
      return List<MPAudioLocalRecord>.from(_records);
    }
    return _records
        .where((MPAudioLocalRecord e) => !e.isRemoved)
        .toList(growable: false);
  }

  /// 按本地路径查找（先 [load]）。
  Future<MPAudioLocalRecord?> queryByPath(String path) async {
    if (path.isEmpty) return null;
    await load();
    for (final MPAudioLocalRecord e in _records) {
      if (e.path == path) return e;
    }
    return null;
  }

  /// 按 [fileId] 查找（非空时）。
  Future<MPAudioLocalRecord?> queryByFileId(String fileId) async {
    if (fileId.isEmpty) return null;
    await load();
    for (final MPAudioLocalRecord e in _records) {
      if (e.fileId == fileId) return e;
    }
    return null;
  }

  /// 新增或同路径覆盖后写入。
  Future<List<MPAudioLocalRecord>> add(MPAudioLocalRecord record) async {
    await load();
    _records.removeWhere((MPAudioLocalRecord e) => e.path == record.path);
    _records.add(record);
    await _persist();
    return List<MPAudioLocalRecord>.from(_records);
  }

  /// 更新：以 [path] + [createAt] 唯一匹配（与旧逻辑一致）；未找到返回 false。
  Future<bool> update(MPAudioLocalRecord next) async {
    await load();
    final int index = _records.indexWhere(
      (MPAudioLocalRecord e) =>
          e.path == next.path && e.createAt == next.createAt,
    );
    if (index < 0) return false;
    _records[index] = next;
    await _persist();
    return true;
  }

  /// 逻辑删除（[isRemoved] = true）。
  Future<bool> removeSoft(MPAudioLocalRecord target) async {
    await load();
    bool changed = false;
    for (int i = 0; i < _records.length; i++) {
      final MPAudioLocalRecord e = _records[i];
      if (e.path == target.path && e.createAt == target.createAt) {
        _records[i] = e.copyWith(isRemoved: true);
        changed = true;
        break;
      }
    }
    if (changed) await _persist();
    return changed;
  }

  /// 从列表中物理删除一条。
  Future<bool> removeHard(MPAudioLocalRecord target) async {
    await load();
    final int before = _records.length;
    _records.removeWhere(
      (MPAudioLocalRecord e) =>
          e.path == target.path && e.createAt == target.createAt,
    );
    if (_records.length == before) return false;
    await _persist();
    return true;
  }

  /// 清空持久化与内存。
  Future<void> clearAll() async {
    _records = <MPAudioLocalRecord>[];
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    debugPrint('MPAudioLocalRecordsUtil: clearAll');
  }
}
