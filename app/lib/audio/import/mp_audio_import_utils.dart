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
    return _syncPickedFilesToSandbox(picked, onProgress: onProgress);
  }

  /// 从相册选择（**支持多选**，iOS 优先 [ImagePicker.pickMultipleMedia]）并复制到应用沙盒。
  static Future<List<String>?> pickFromAlbumWithProgress({
    required MPAudioImportCopyProgress onProgress,
  }) async {
    final List<File> picked = await _pickMultipleAudioFromAlbum();
    if (picked.isEmpty) {
      return null;
    }
    return _syncPickedFilesToSandbox(picked, onProgress: onProgress);
  }

  /// 将沙盒内一条音频上传并创建远端记录（与录音上传链路一致）。
  ///
  /// [batchTotal] / [batchIndex] 用于首页多文件导入时的进度条批次展示。
  static Future<void> uploadImportedSandboxFile(
    String sandboxPath, {
    int batchTotal = 1,
    int batchIndex = 1,
  }) async {
    final File file = File(sandboxPath);
    if (!await file.exists()) {
      return;
    }
    final int? dur = await _getAudioDurationSeconds(sandboxPath);
    final int durationSec = (dur != null && dur > 0) ? dur : 1;
    final int createAt = (await file.lastModified()).millisecondsSinceEpoch ~/ 1000;
    await MPAudioUploadManager.instance.uploadLocalRecord(
      localFile: file,
      durationSec: durationSec,
      createAt: createAt,
      source: 'MobilePhone',
      batchTotal: batchTotal,
      batchIndex: batchIndex,
    );
  }

  /// 批量上传已由 [pickFromFileWithProgress] / [pickFromAlbumWithProgress] 写入沙盒的路径。
  static Future<void> uploadImportedSandboxFiles(List<String> sandboxPaths) async {
    final int n = sandboxPaths.length;
    if (n == 0) {
      return;
    }
    for (int i = 0; i < n; i++) {
      await uploadImportedSandboxFile(
        sandboxPaths[i],
        batchTotal: n,
        batchIndex: i + 1,
      );
    }
  }

  static Future<List<String>> _syncPickedFilesToSandbox(
    List<File> picked, {
    required MPAudioImportCopyProgress onProgress,
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
      if (path != null) {
        onProgress(fileIndex: i + 1, fileTotal: total, progressPercent: 100);
        out.add(path);
      }
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
        dialogTitle: '选择音频文件',
        withData: false,
        allowCompression: false,
        allowMultiple: true,
      );
      return _audioFilesFromPickerResult(result);
    } catch (e) {
      debugPrint('MPAudioImportUtils: 从文件选择音频失败: $e');
    }
    return <File>[];
  }

  /// 返回非 null：用户结束原生选择（含取消时的空列表）。
  /// 返回 null：通道异常，应回退 [FilePicker]。
  static Future<List<File>?> _pickMultipleAudioFromAndroidChannel() async {
    try {
      final Object? raw = await _androidAudioMultiPickerChannel.invokeMethod<Object?>(
        'pickMultipleAudio',
        <String, String>{'title': '选择音频文件'},
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
          debugPrint('MPAudioImportUtils: 原生通道文件不存在: $item');
          continue;
        }
        if (_isAudioFormatSupported(item)) {
          out.add(file);
        } else {
          debugPrint('MPAudioImportUtils: 原生通道跳过不支持的格式: $item');
        }
      }
      return out;
    } on PlatformException catch (e) {
      debugPrint('MPAudioImportUtils: Android 原生多选失败，回退 FilePicker: $e');
      return null;
    } catch (e) {
      debugPrint('MPAudioImportUtils: Android 原生多选异常，回退 FilePicker: $e');
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
        debugPrint('MPAudioImportUtils: 跳过无路径的文件: ${pf.name}');
        continue;
      }
      final File file = File(path);
      if (!file.existsSync()) {
        debugPrint('MPAudioImportUtils: 选择的文件不存在: $path');
        continue;
      }
      if (_isAudioFormatSupported(path)) {
        out.add(file);
      } else {
        debugPrint('MPAudioImportUtils: 不支持的音频格式: $path');
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
              debugPrint('MPAudioImportUtils: 选择的文件不存在: ${media.path}');
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
            debugPrint('MPAudioImportUtils: 照片库权限被拒绝: ${e.message}');
            MPToastUtils.showMessage(
              'Photos access is required to import audio. Allow access in Settings if you previously denied it.',
              duration: const Duration(seconds: 5),
            );
            return <File>[];
          }
          debugPrint('MPAudioImportUtils: ImagePicker 失败，回退 FilePicker: $e');
          return _pickMultipleAudioFromAlbumFallback();
        } catch (e) {
          debugPrint('MPAudioImportUtils: ImagePicker 失败，回退 FilePicker: $e');
          return _pickMultipleAudioFromAlbumFallback();
        }
      }
      return _pickMultipleAudioFromAlbumFallback();
    } catch (e) {
      debugPrint('MPAudioImportUtils: 从相册选择音频失败: $e');
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
        dialogTitle: Platform.isIOS ? '选择音频文件' : '从相册选择音频',
      );
      return _audioFilesFromPickerResult(result);
    } catch (e) {
      debugPrint('MPAudioImportUtils: FilePicker 选择失败: $e');
    }
    return <File>[];
  }

  static bool _isAudioFormatSupported(String filePath) {
    try {
      final String extension = filePath.split('.').last.toLowerCase();
      return _audioExtensions.contains(extension);
    } catch (e) {
      debugPrint('MPAudioImportUtils: 格式检查失败: $e');
      return false;
    }
  }

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
      debugPrint('MPAudioImportUtils: 同步沙盒失败: $e');
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
      debugPrint('MPAudioImportUtils: 读取时长失败: $e');
      return null;
    }
  }
}
