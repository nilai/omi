import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:memo_pin/audio/record/mp_audio_upload_manger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// 同步到沙盒时的进度（0–1）、已复制字节、总字节。
typedef _SyncProgressCallback = void Function(
  double progress,
  int copiedBytes,
  int totalBytes,
);

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
    'opus',
  ];

  /// 从系统文件选择并复制到应用沙盒。
  ///
  /// [onProgressPercent] 为 0–100。
  static Future<String?> pickFromFileWithProgress({
    required void Function(int progressPercent) onProgressPercent,
  }) async {
    onProgressPercent(0);
    final File? file = await _pickAudioFromFile();
    if (file == null) {
      return null;
    }
    final String? path = await _syncAudioToSandbox(
      file,
      onProgress: (double p, int _, int __) {
        onProgressPercent((p * 100).round().clamp(0, 100));
      },
    );
    if (path != null) {
      onProgressPercent(100);
    }
    return path;
  }

  /// 从相册选择并复制到应用沙盒（iOS 常用）。
  static Future<String?> pickFromAlbumWithProgress({
    required void Function(int progressPercent) onProgressPercent,
  }) async {
    onProgressPercent(0);
    final File? file = await _pickAudioFromAlbum();
    if (file == null) {
      return null;
    }
    final String? path = await _syncAudioToSandbox(
      file,
      onProgress: (double p, int _, int __) {
        onProgressPercent((p * 100).round().clamp(0, 100));
      },
    );
    if (path != null) {
      onProgressPercent(100);
    }
    return path;
  }

  /// 将沙盒内音频上传并创建远端记录（与录音上传链路一致）。
  static Future<void> uploadImportedSandboxFile(String sandboxPath) async {
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
      rightNowTranscribe: true,
      source: 'MobilePhone',
    );
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

  static Future<File?> _pickAudioFromFile() async {
    try {
      if (Platform.isAndroid) {
        final bool hasPermission = await _checkAndRequestStoragePermission();
        if (!hasPermission) {
          debugPrint('MPAudioImportUtils: 存储权限被拒绝，无法从文件选择音频');
          return null;
        }
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _audioExtensions,
        dialogTitle: '选择音频文件',
        withData: false,
        allowCompression: false,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        final String filePath = result.files.single.path!;
        final File file = File(filePath);
        if (!await file.exists()) {
          debugPrint('MPAudioImportUtils: 选择的文件不存在: $filePath');
          return null;
        }
        if (_isAudioFormatSupported(filePath)) {
          return file;
        }
        debugPrint('MPAudioImportUtils: 不支持的音频格式: $filePath');
        return null;
      }
    } catch (e) {
      debugPrint('MPAudioImportUtils: 从文件选择音频失败: $e');
    }
    return null;
  }

  static Future<File?> _pickAudioFromAlbum() async {
    try {
      if (Platform.isIOS) {
        try {
          final ImagePicker picker = ImagePicker();
          final XFile? media = await picker.pickMedia(imageQuality: 100);
          if (media != null) {
            final File file = File(media.path);
            if (!await file.exists()) {
              debugPrint('MPAudioImportUtils: 选择的文件不存在: ${media.path}');
              return null;
            }
            if (_isAudioFormatSupported(media.path)) {
              return file;
            }
            return await _pickAudioFromAlbumFallback();
          }
        } on PlatformException catch (e) {
          if (e.code == 'photo_access_denied' || e.code == 'photo_access_restricted') {
            debugPrint('MPAudioImportUtils: 照片库权限被拒绝: ${e.message}');
            return null;
          }
          debugPrint('MPAudioImportUtils: ImagePicker 失败，回退 FilePicker: $e');
          return await _pickAudioFromAlbumFallback();
        } catch (e) {
          debugPrint('MPAudioImportUtils: ImagePicker 失败，回退 FilePicker: $e');
          return await _pickAudioFromAlbumFallback();
        }
      } else {
        final bool hasPermission = await _checkAndRequestMediaPermission();
        if (!hasPermission) {
          debugPrint('MPAudioImportUtils: 媒体库权限被拒绝');
          return null;
        }
        return await _pickAudioFromAlbumFallback();
      }
    } catch (e) {
      debugPrint('MPAudioImportUtils: 从相册选择音频失败: $e');
    }
    return null;
  }

  static Future<File?> _pickAudioFromAlbumFallback() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _audioExtensions,
        withData: false,
        allowCompression: false,
        allowMultiple: false,
        dialogTitle: Platform.isIOS ? '选择音频文件' : '从相册选择音频',
      );

      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        final String filePath = result.files.single.path!;
        final File file = File(filePath);
        if (!await file.exists()) {
          return null;
        }
        if (_isAudioFormatSupported(filePath)) {
          return file;
        }
        return null;
      }
    } catch (e) {
      debugPrint('MPAudioImportUtils: FilePicker 选择失败: $e');
    }
    return null;
  }

  static Future<bool> _checkAndRequestStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }
    try {
      PermissionStatus audioStatus = await Permission.audio.status;
      if (audioStatus.isGranted) {
        return true;
      }
      PermissionStatus storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        return true;
      }
      if (audioStatus.isDenied) {
        audioStatus = await Permission.audio.request();
        if (audioStatus.isGranted) {
          return true;
        }
      }
      if (storageStatus.isDenied) {
        storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          return true;
        }
      }
      if (audioStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
        return false;
      }
      return false;
    } catch (e) {
      debugPrint('MPAudioImportUtils: 存储权限检查失败: $e');
      return false;
    }
  }

  static Future<bool> _checkAndRequestMediaPermission() async {
    try {
      if (Platform.isAndroid) {
        return await _checkAndRequestStoragePermission();
      }
      if (Platform.isIOS) {
        PermissionStatus status = await Permission.photos.status;
        if (status.isGranted || status.isLimited) {
          return true;
        }
        if (status.isPermanentlyDenied || status.isRestricted) {
          return false;
        }
        if (status.isDenied) {
          status = await Permission.photos.request();
          if (status.isPermanentlyDenied) {
            return false;
          }
          if (status.isGranted || status.isLimited) {
            return true;
          }
          return false;
        }
        status = await Permission.photos.request();
        if (status.isGranted || status.isLimited) {
          return true;
        }
        if (status.isPermanentlyDenied) {
          return false;
        }
        return false;
      }
      return true;
    } catch (e, st) {
      debugPrint('MPAudioImportUtils: 媒体权限检查失败: $e\n$st');
      return false;
    }
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
