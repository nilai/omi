import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:memo_pin/env/env.dart';
import 'package:memo_pin/http/shared.dart';
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

  /// 拉取远端录音字节：落在 [Env.apiBaseUrl] 下的地址走 [makeRawApiCall]（带登录态），否则裸 `GET`。
  static Future<http.Response?> httpGetAudioDownloadUrl(String downloadUrl) async {
    try {
      final String trimmed = downloadUrl.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      final String? base = Env.apiBaseUrl;
      if (base != null &&
          base.isNotEmpty &&
          trimmed.startsWith(base)) {
        final http.StreamedResponse streamed = await makeRawApiCall(
          url: trimmed,
          method: 'GET',
          headers: const <String, String>{},
        );
        final List<int> bytes = await streamed.stream.toBytes();
        return http.Response.bytes(
          bytes,
          streamed.statusCode,
          headers: streamed.headers,
        );
      }
      return await http.get(Uri.parse(trimmed));
    } catch (e, st) {
      debugPrint('httpGetAudioDownloadUrl failed: $e\n$st');
      return null;
    }
  }

  static bool _bytesLookLikeJsonOrHtml(Uint8List head) {
    if (head.isEmpty) {
      return false;
    }
    final int b0 = head[0];
    if (b0 == 0x7b || b0 == 0x5b) {
      return true;
    }
    if (head.length >= 3 && b0 == 0xef && head[1] == 0xbb && head[2] == 0xbf) {
      return head.length > 3 && (head[3] == 0x7b || head[3] == 0x5b);
    }
    if (b0 == 0x3c) {
      return true;
    }
    return false;
  }

  static bool _bytesAreMp4Ftyp(Uint8List head) {
    return head.length >= 8 &&
        head[4] == 0x66 &&
        head[5] == 0x74 &&
        head[6] == 0x79 &&
        head[7] == 0x70;
  }

  static bool _bytesAreAdtsAac(Uint8List head) {
    return head.length >= 2 &&
        (head[0] & 0xff) == 0xff &&
        (head[1] & 0xf0) == 0xf0;
  }

  /// 根据文件头修正扩展名：裸 ADTS 常被误存为 `.m4a`，iOS 会报 **-11829 Cannot Open**。
  /// 返回新路径（可能与入参相同）；明显为 JSON/HTML 时删文件并返回 `null`。
  static Future<String?> adjustAudioFileIfWrongExtension(String savedPath) async {
    final File f = File(p.normalize(savedPath.trim()));
    if (!await f.exists()) {
      return null;
    }
    final int len = await f.length();
    if (len < 2) {
      try {
        await f.delete();
      } catch (_) {}
      return null;
    }
    RandomAccessFile? raf;
    try {
      raf = await f.open(mode: FileMode.read);
      final int n = min(64, len);
      final Uint8List head = await raf.read(n);
      if (_bytesLookLikeJsonOrHtml(head)) {
        debugPrint('adjustAudioFileIfWrongExtension: payload is not audio');
        await raf.close();
        raf = null;
        try {
          await f.delete();
        } catch (_) {}
        return null;
      }
      if (_bytesAreMp4Ftyp(head)) {
        return f.path;
      }
      if (_bytesAreAdtsAac(head)) {
        final String ext = p.extension(f.path).toLowerCase();
        if (ext == '.m4a' || ext == '.mp4') {
          await raf.close();
          raf = null;
          String newPath = p.join(
            p.dirname(f.path),
            '${p.basenameWithoutExtension(f.path)}.aac',
          );
          if (File(newPath).existsSync()) {
            newPath = p.join(
              p.dirname(f.path),
              '${p.basenameWithoutExtension(f.path)}_${DateTime.now().millisecondsSinceEpoch}.aac',
            );
          }
          await f.rename(newPath);
          return newPath;
        }
        return f.path;
      }
      return f.path;
    } finally {
      if (raf != null) {
        try {
          await raf.close();
        } catch (_) {}
      }
    }
  }

  /// 将已落盘的本地文件交给 [just_audio]：先 [AudioPlayer.stop] 再 [setAudioSource]，
  /// 使用 [Uri.file]（iOS 上比裸 [setFilePath] 换源更稳）。
  static Future<void> bindLocalAudioForPlayback(
    AudioPlayer player,
    String localPath,
  ) async {
    final String normalized = p.normalize(localPath.trim());
    final String? fixed = await adjustAudioFileIfWrongExtension(normalized);
    if (fixed == null) {
      throw StateError('Invalid or non-audio file: $normalized');
    }
    if (fixed != normalized) {
      await instance.migrateRecordPathIfExists(normalized, fixed);
    }
    final File f = File(fixed);
    if (!await f.exists()) {
      throw StateError('Local audio not found: $fixed');
    }
    if (await f.length() <= 0) {
      throw StateError('Local audio is empty: $fixed');
    }
    try {
      await player.stop();
    } catch (_) {}
    final Uri uri = Uri.file(f.absolute.path);
    await player.setAudioSource(
      AudioSource.uri(uri),
      preload: true,
    );
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

  /// 磁盘上文件已从 [oldPath] 改名到 [newPath] 时，同步更新持久化索引（如 `.m4a` → `.aac`）。
  Future<void> migrateRecordPathIfExists(String oldPath, String newPath) async {
    if (oldPath.isEmpty || newPath.isEmpty || oldPath == newPath) {
      return;
    }
    await load();
    final int i = _records.indexWhere((MPAudioLocalRecord e) => e.path == oldPath);
    if (i < 0) {
      return;
    }
    _records[i] = _records[i].copyWith(path: newPath);
    await _persist();
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
