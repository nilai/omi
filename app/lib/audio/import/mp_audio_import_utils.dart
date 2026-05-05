import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:memo_pin/audio/record/mp_audio_upload_manger.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:path_provider/path_provider.dart';

/// 同步到沙盒时的进度（0–1）、已复制字节、总字节。
typedef _SyncProgressCallback = void Function(
  double progress,
  int copiedBytes,
  int totalBytes,
);

/// 将所选文件复制到沙盒时的进度：[fileIndex] / [fileTotal] 为第几个文件；[progressPercent] 为当前文件 0–100。
typedef MPAudioImportCopyProgress = void Function({
  required int fileIndex,
  required int fileTotal,
  required int progressPercent,
});

/// 首页 / 业务侧「导入音频」工具：选择文件、复制到沙盒（带进度）、上传。
///
/// 实现自包含，**不依赖** `lib/tab/home/audio/` 下任何源码。
class MPAudioImportUtils {
  MPAudioImportUtils._();

  static const String _sandboxAudioDirName = 'mp_audio_storage';

  static const List<String> _audioExtensions = <String>[
    'mp3',
    'm4a',
    'wav',
    'aac',
    'flac',
    'ogg',
    'oga',
    'opus',
  ];

  static const MethodChannel _androidAudioMultiPickerChannel = MethodChannel(
    'ai.memopin.app/mp_android_audio_multi_picker',
  );

  /// 从系统文件选择（**支持多选**）并复制到应用沙盒。
  static Future<List<String>?> pickFromFileWithProgress({
    required MPAudioImportCopyProgress onProgress,
  }) async {
    final List<File> picked = await _pickMultipleAudioFromFile();
    if (picked.isEmpty) {
      return null;
    }
    return _syncEachPickedFileToSandboxAndRegister(picked, onProgress: onProgress, source: 'MobilePhone');
  }

  /// 从相册选择（**支持多选**，iOS 优先 [ImagePicker.pickMultipleMedia]）并复制到应用沙盒。
  static Future<List<String>?> pickFromAlbumWithProgress({
    required MPAudioImportCopyProgress onProgress,
  }) async {
    final List<File> picked = await _pickMultipleAudioFromAlbum();
    if (picked.isEmpty) {
      return null;
    }
    return _syncEachPickedFileToSandboxAndRegister(picked, onProgress: onProgress, source: 'MobilePhone');
  }

  /// 按路径列表逐个上传：使用 [MPAudioUploadManager.uploadMultipleLocalRecords] + [localRecordsAlreadyAdded]。
  ///
  /// 须与 [pickFromFileWithProgress] / [pickFromAlbumWithProgress] 配套（二者已在同步后写入本地索引）。
  static Future<void> uploadImportedSandboxFiles(List<String> sandboxPaths, {String source = 'MobilePhone'}) async {
    final List<MPAudioUploadLocalItem> items = <MPAudioUploadLocalItem>[];
    for (final String sandboxPath in sandboxPaths) {
      final File file = File(sandboxPath);
      if (!await file.exists()) {
        continue;
      }
      final int? dur = await _getAudioDurationSeconds(sandboxPath);
      final int durationSec = (dur != null && dur > 0) ? dur : 1;
      final int createAt =
          (await file.lastModified()).millisecondsSinceEpoch ~/ 1000;
      items.add(
        MPAudioUploadLocalItem(
          localFile: file,
          durationSec: durationSec,
          createAt: createAt,
          source: source,
        ),
      );
    }
    if (items.isEmpty) {
      return;
    }
    await MPAudioUploadManager.instance.uploadMultipleLocalRecords(
      items: items,
      rightNowTranscribe: false,
      localRecordsAlreadyAdded: true,
    );
  }

  /// 逐个：同步到沙盒 → [MPAudioUploadManager.registerLocalRecordBeforeUpload]。
  static Future<List<String>> _syncEachPickedFileToSandboxAndRegister(
    List<File> picked, {
    required MPAudioImportCopyProgress onProgress,
    String source = 'MobilePhone',
  }) async {
    final int total = picked.length;
    final List<String> out = <String>[];
    for (int i = 0; i < total; i++) {
      final File file = picked[i];
      onProgress(fileIndex: i + 1, fileTotal: total, progressPercent: 0);
      final String? path = await _syncAudioToSandbox(
        file,
        onProgress: (double p, int copiedBytes, int totalBytes) {
          onProgress(
            fileIndex: i + 1,
            fileTotal: total,
            progressPercent: (p * 100).round().clamp(0, 100),
          );
        },
      );
      if (path == null) {
        continue;
      }
      final File sandboxFile = File(path);
      final int? dur = await _getAudioDurationSeconds(path);
      final int durationSec = (dur != null && dur > 0) ? dur : 1;
      final int createAt =
          (await sandboxFile.lastModified()).millisecondsSinceEpoch ~/ 1000;
      final record =
          await MPAudioUploadManager.instance.registerLocalRecordBeforeUpload(
        localFile: sandboxFile,
        durationSec: durationSec,
        createAt: createAt,
        source: source,
      );
      if (record == null) {
        debugPrint('MPAudioImportUtils: register local record failed, skip: $path');
        continue;
      }
      onProgress(fileIndex: i + 1, fileTotal: total, progressPercent: 100);
      out.add(path);
    }
    return out;
  }

  // —— 以下为内联实现（对齐 tab/home/audio 侧原先 [AudioPickerUtils] 行为）——

  static String _generateSafeFileName(String fileName) {
    if (Platform.isIOS) {
      final bool hasNonAscii = fileName.runes.any((int rune) => rune > 127);
      if (hasNonAscii) {
        final int lastDotIndex = fileName.lastIndexOf('.');
        final String nameWithoutExt =
            lastDotIndex > 0 ? fileName.substring(0, lastDotIndex) : fileName;
        final String extension = lastDotIndex > 0 ? fileName.substring(lastDotIndex) : '';
        final List<int> bytes = utf8.encode(nameWithoutExt);
        final Digest digest = md5.convert(bytes);
        return '${digest.toString()}$extension';
      }
    }
    return fileName;
  }

  /// Android：优先走原生 [ACTION_GET_CONTENT] 多选（绕开部分 ROM 上 SAF 忽略多选），失败则回退 [FilePicker]。
  static Future<List<File>> _pickMultipleAudioFromFile() async {
    if (Platform.isAndroid) {
      final List<File>? viaNative = await _pickMultipleAudioFromAndroidChannel();
      if (viaNative != null) {
        return viaNative;
      }
    }
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _audioExtensions,
        dialogTitle: 'Choose audio files',
        withData: false,
        allowCompression: false,
        allowMultiple: true,
      );
      return _audioFilesFromPickerResult(result);
    } catch (e) {
      debugPrint('MPAudioImportUtils: pick audio from files failed: $e');
    }
    return <File>[];
  }

  /// 返回非 null：用户结束原生选择（含取消时的空列表）。
  /// 返回 null：通道异常，应回退 [FilePicker]。
  static Future<List<File>?> _pickMultipleAudioFromAndroidChannel() async {
    try {
      final Object? raw = await _androidAudioMultiPickerChannel.invokeMethod<Object?>(
        'pickMultipleAudio',
        <String, String>{'title': 'Choose audio files'},
      );
      if (raw == null) {
        return <File>[];
      }
      if (raw is! List<dynamic>) {
        return <File>[];
      }
      final List<File> out = <File>[];
      for (final Object? item in raw) {
        if (item is! String) {
          continue;
        }
        final File file = File(item);
        if (!file.existsSync()) {
          debugPrint('MPAudioImportUtils: native channel file missing: $item');
          continue;
        }
        if (_isAudioFormatSupported(item)) {
          out.add(file);
        } else {
          debugPrint('MPAudioImportUtils: native channel skip unsupported: $item');
        }
      }
      return out;
    } on PlatformException catch (e) {
      debugPrint('MPAudioImportUtils: Android native multi-pick failed, fallback FilePicker: $e');
      return null;
    } catch (e) {
      debugPrint('MPAudioImportUtils: Android native multi-pick error, fallback FilePicker: $e');
      return null;
    }
  }

  static List<File> _audioFilesFromPickerResult(FilePickerResult? result) {
    if (result == null || result.files.isEmpty) {
      return <File>[];
    }
    final List<File> out = <File>[];
    for (final PlatformFile pf in result.files) {
      final String? path = pf.path;
      if (path == null) {
        debugPrint('MPAudioImportUtils: skip file without path: ${pf.name}');
        continue;
      }
      final File file = File(path);
      if (!file.existsSync()) {
        debugPrint('MPAudioImportUtils: picked file missing: $path');
        continue;
      }
      if (_isAudioFormatSupported(path)) {
        out.add(file);
      } else {
        debugPrint('MPAudioImportUtils: unsupported audio format: $path');
      }
    }
    return out;
  }

  static Future<List<File>> _pickMultipleAudioFromAlbum() async {
    try {
      if (Platform.isIOS) {
        try {
          final ImagePicker picker = ImagePicker();
          final List<XFile> mediaList =
              await picker.pickMultipleMedia(imageQuality: 100);
          if (mediaList.isEmpty) {
            return <File>[];
          }
          final List<File> out = <File>[];
          for (final XFile media in mediaList) {
            final File file = File(media.path);
            if (!await file.exists()) {
              debugPrint('MPAudioImportUtils: picked file missing: ${media.path}');
              continue;
            }
            if (_isAudioFormatSupported(media.path)) {
              out.add(file);
            }
          }
          if (out.isNotEmpty) {
            return out;
          }
          return _pickMultipleAudioFromAlbumFallback();
        } on PlatformException catch (e) {
          if (e.code == 'photo_access_denied' ||
              e.code == 'photo_access_restricted') {
            debugPrint('MPAudioImportUtils: photo library access denied: ${e.message}');
            MPToastUtils.showMessage(
              'Photos access is required to import audio. Allow access in Settings if you previously denied it.',
              duration: const Duration(seconds: 5),
            );
            return <File>[];
          }
          debugPrint('MPAudioImportUtils: ImagePicker failed, fallback FilePicker: $e');
          return _pickMultipleAudioFromAlbumFallback();
        } catch (e) {
          debugPrint('MPAudioImportUtils: ImagePicker failed, fallback FilePicker: $e');
          return _pickMultipleAudioFromAlbumFallback();
        }
      }
      return _pickMultipleAudioFromAlbumFallback();
    } catch (e) {
      debugPrint('MPAudioImportUtils: pick audio from album failed: $e');
    }
    return <File>[];
  }

  static Future<List<File>> _pickMultipleAudioFromAlbumFallback() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _audioExtensions,
        withData: false,
        allowCompression: false,
        allowMultiple: true,
        dialogTitle:
            Platform.isIOS ? 'Choose audio files' : 'Choose audio from library',
      );
      return _audioFilesFromPickerResult(result);
    } catch (e) {
      debugPrint('MPAudioImportUtils: FilePicker failed: $e');
    }
    return <File>[];
  }

  static bool _isAudioFormatSupported(String filePath) {
    try {
      final String extension = filePath.split('.').last.toLowerCase();
      return _audioExtensions.contains(extension);
    } catch (e) {
      debugPrint('MPAudioImportUtils: format check failed: $e');
      return false;
    }
  }

  /// 将设备导出字节写入沙盒音频目录（路径规则与 [_syncAudioToSandbox] 一致）。
  static Future<String?> writeExportBytesToSandbox({
    required List<int> bytes,
    required String originalFileName,
  }) async {
    try {
      if (bytes.isEmpty) {
        return null;
      }
      final Directory dir = await _getPersistentAudioDirectory();
      final String safeFileName = _generateSafeFileName(originalFileName);
      final String targetPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';
      final File targetFile = File(targetPath);
      await targetFile.writeAsBytes(bytes, flush: true);
      return targetFile.path;
    } catch (e) {
      debugPrint('MPAudioImportUtils: writeExportBytesToSandbox failed: $e');
      return null;
    }
  }

  /// 读取本地音频文件时长（秒）；失败返回 `null`。
  static Future<int?> readAudioDurationSeconds(String filePath) =>
      _getAudioDurationSeconds(filePath);

  static Future<Directory> _getPersistentAudioDirectory() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${appDir.path}/$_sandboxAudioDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String?> _syncAudioToSandbox(
    File sourceFile, {
    _SyncProgressCallback? onProgress,
  }) async {
    try {
      if (!await sourceFile.exists()) {
        return null;
      }
      final int totalBytes = await sourceFile.length();
      final Directory dir = await _getPersistentAudioDirectory();
      final String originalFileName = sourceFile.path.split('/').last;
      final String safeFileName = _generateSafeFileName(originalFileName);
      final String targetPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';
      final File targetFile = File(targetPath);

      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      final IOSink sink = targetFile.openWrite();
      int copiedBytes = 0;

      await for (final List<int> chunk in sourceFile.openRead()) {
        sink.add(chunk);
        copiedBytes += chunk.length;
        final double progress =
            totalBytes == 0 ? 1.0 : (copiedBytes / totalBytes).clamp(0.0, 1.0).toDouble();
        onProgress?.call(progress, copiedBytes, totalBytes);
      }

      await sink.close();
      return targetFile.path;
    } catch (e) {
      debugPrint('MPAudioImportUtils: sandbox sync failed: $e');
      return null;
    }
  }

  static Future<int?> _getAudioDurationSeconds(dynamic filePath) async {
    try {
      final String path;
      if (filePath is File) {
        if (!await filePath.exists()) {
          return null;
        }
        path = filePath.path;
      } else if (filePath is String) {
        final File file = File(filePath);
        if (!await file.exists()) {
          return null;
        }
        path = filePath;
      } else {
        return null;
      }

      final AudioPlayer player = AudioPlayer();
      try {
        await player.setAudioSource(AudioSource.uri(Uri.file(path)));
        final Duration? duration = player.duration;
        if (duration != null) {
          return duration.inSeconds;
        }
        return null;
      } finally {
        await player.dispose();
      }
    } catch (e) {
      debugPrint('MPAudioImportUtils: read duration failed: $e');
      return null;
    }
  }
}
