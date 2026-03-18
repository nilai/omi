import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:omi/backend/http/api/audio_record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// 同步进度回调
/// [progress] 已完成比例 0-1
/// [copiedBytes] 已复制的字节数
/// [totalBytes] 文件总字节数
typedef SyncProgressCallback = void Function(
  double progress,
  int copiedBytes,
  int totalBytes,
);

/// 音频选择工具类
/// 提供从文件、相册选择音频文件的功能，包含权限检查
class AudioPickerUtils {
  static const String _sandboxAudioDirName = 'mp_audio_storage';

  /// 生成安全的文件名（iOS 26+ 兼容）
  /// 在 iOS 上，如果文件名包含非 ASCII 字符，使用 MD5 编码
  /// 在 Android 上，保持原文件名
  ///
  /// [fileName] 原始文件名（可能包含扩展名）
  /// 返回安全的文件名
  static String _generateSafeFileName(String fileName) {
    if (Platform.isIOS) {
      // 检查文件名是否包含非 ASCII 字符
      final hasNonAscii = fileName.runes.any((rune) => rune > 127);
      if (hasNonAscii) {
        // 提取文件名和扩展名
        final lastDotIndex = fileName.lastIndexOf('.');
        final nameWithoutExt = lastDotIndex > 0 ? fileName.substring(0, lastDotIndex) : fileName;
        final extension = lastDotIndex > 0 ? fileName.substring(lastDotIndex) : '';

        // 生成 MD5 哈希
        final bytes = utf8.encode(nameWithoutExt);
        final digest = md5.convert(bytes);
        final md5Hash = digest.toString();

        // 返回 MD5 值 + 扩展名
        return '$md5Hash$extension';
      }
    }
    // Android 或其他平台，保持原文件名
    return fileName;
  }

  /// 从文件选择音频并同步到沙盒持久目录
  /// @param onProgress 同步进度回调
  /// @return 成功返回沙盒内文件路径，失败返回 null
  static Future<String?> pickAudioFromFileAndSync({
    SyncProgressCallback? onProgress,
  }) async {
    final file = await pickAudioFromFile();
    if (file == null) return null;
    return syncAudioToSandbox(file, onProgress: onProgress);
  }

  /// 从相册选择音频并同步到沙盒持久目录
  /// @param onProgress 同步进度回调
  /// @return 成功返回沙盒内文件路径，失败返回 null
  static Future<String?> pickAudioFromAlbumAndSync({
    SyncProgressCallback? onProgress,
  }) async {
    final file = await pickAudioFromAlbum();
    if (file == null) return null;
    return syncAudioToSandbox(file, onProgress: onProgress);
  }

  /// 从文件选择音频 - 打开文件浏览器选择音频文件
  /// 在 Android 上需要存储权限，iOS 上不需要额外权限
  /// @return 选择的音频文件，如果用户取消或出错则返回 null
  static Future<File?> pickAudioFromFile() async {
    try {
      // 检查并请求权限
      if (Platform.isAndroid) {
        final hasPermission = await _checkAndRequestStoragePermission();
        if (!hasPermission) {
          debugPrint('存储权限被拒绝，无法从文件选择音频');
          return null;
        }
      }

      // 打开文件选择器
      // Android上需要明确设置allowMultiple为false，确保单选模式
      // 注意：某些Android文件管理器可能不尊重allowedExtensions过滤
      // 为了确保音频文件能正确显示，我们使用custom类型并明确指定扩展名
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: audioExtensions,
        dialogTitle: '选择音频文件',
        withData: false,
        allowCompression: false,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);

        // 验证文件是否存在
        if (!await file.exists()) {
          debugPrint('选择的文件不存在: $filePath');
          return null;
        }

        // 验证音频格式（Android上如果使用any类型，需要手动过滤）
        if (_isAudioFormatSupported(filePath)) {
          return file;
        } else {
          debugPrint('不支持的音频格式: $filePath');
          // 在Android上，如果文件格式不支持，提示用户
          if (Platform.isAndroid) {
            debugPrint('请选择音频文件（mp3, m4a, wav, aac）');
          }
          return null;
        }
      }
    } catch (e) {
      debugPrint('从文件选择音频失败: $e');
    }
    return null;
  }

  /// 从相册选择音频 - 访问设备的媒体库
  /// Android: 使用 FilePicker 访问媒体库
  /// iOS: 使用 ImagePicker 的 pickMedia 方法访问系统相册（如果支持音频）
  /// 在 Android 上需要存储权限，iOS 上需要照片库权限
  /// 注意：在 iOS 上，ImagePicker 会自动请求权限，所以不需要预先检查权限
  /// @return 选择的音频文件，如果用户取消或出错则返回 null
  static Future<File?> pickAudioFromAlbum() async {
    try {
      if (Platform.isIOS) {
        // iOS: 直接使用 ImagePicker，它会自动请求权限
        // 注意：ImagePicker 主要支持图片和视频，音频支持可能有限
        try {
          final ImagePicker picker = ImagePicker();
          // pickMedia 在 iOS 14+ 支持选择音频文件
          // ImagePicker 会自动处理权限请求，如果权限未授予会弹出权限对话框
          final XFile? media = await picker.pickMedia(
            imageQuality: 100,
          );

          if (media != null) {
            final file = File(media.path);

            // 验证文件是否存在
            if (!await file.exists()) {
              debugPrint('选择的文件不存在: ${media.path}');
              return null;
            }

            // 验证音频格式
            if (_isAudioFormatSupported(media.path)) {
              return file;
            } else {
              debugPrint('不支持的音频格式: ${media.path}');
              // 如果 ImagePicker 不支持音频，回退到 FilePicker
              return await _pickAudioFromAlbumFallback();
            }
          }
        } on PlatformException catch (e) {
          // 处理权限被拒绝的情况
          if (e.code == 'photo_access_denied' || e.code == 'photo_access_restricted') {
            debugPrint('照片库权限被拒绝: ${e.message}');
            // 权限被拒绝，返回 null
            return null;
          }
          debugPrint('使用 ImagePicker 选择音频失败，回退到 FilePicker: $e');
          // 回退到 FilePicker
          return await _pickAudioFromAlbumFallback();
        } catch (e) {
          debugPrint('使用 ImagePicker 选择音频失败，回退到 FilePicker: $e');
          // 回退到 FilePicker
          return await _pickAudioFromAlbumFallback();
        }
      } else {
        // Android: 需要先检查并请求权限
        final hasPermission = await _checkAndRequestMediaPermission();
        if (!hasPermission) {
          debugPrint('媒体库权限被拒绝，无法从相册选择音频');
          return null;
        }
        // Android: 使用 FilePicker 访问媒体库
        return await _pickAudioFromAlbumFallback();
      }
    } catch (e) {
      debugPrint('从相册选择音频失败: $e');
    }
    return null;
  }

  /// 从相册选择音频的回退方法 - 使用 FilePicker
  /// 注意：在 iOS 上，FilePicker 打开的是文档选择器，不是系统相册
  /// @return 选择的音频文件，如果用户取消或出错则返回 null
  static Future<File?> _pickAudioFromAlbumFallback() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: audioExtensions,
        withData: false,
        allowCompression: false,
        allowMultiple: false,
        dialogTitle: Platform.isIOS ? '选择音频文件' : '从相册选择音频',
      );

      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);

        // 验证文件是否存在
        if (!await file.exists()) {
          debugPrint('选择的文件不存在: $filePath');
          return null;
        }

        // 验证音频格式
        if (_isAudioFormatSupported(filePath)) {
          return file;
        } else {
          debugPrint('不支持的音频格式: $filePath');
          return null;
        }
      }
    } catch (e) {
      debugPrint('FilePicker 选择音频失败: $e');
    }
    return null;
  }

  /// 检查并请求存储权限（Android）
  /// Android 13+ (API 33+) 使用 READ_MEDIA_AUDIO
  /// Android 12 及以下使用 READ_EXTERNAL_STORAGE
  /// @return true 如果权限已授予，false 如果权限被拒绝
  static Future<bool> _checkAndRequestStoragePermission() async {
    if (!Platform.isAndroid) {
      return true; // iOS 和桌面平台不需要此权限
    }

    try {
      // 优先尝试音频权限（Android 13+）
      Permission audioPermission = Permission.audio;
      PermissionStatus audioStatus = await audioPermission.status;

      if (audioStatus.isGranted) {
        return true;
      }

      // 如果音频权限不可用或被拒绝，尝试存储权限（Android 12 及以下）
      Permission storagePermission = Permission.storage;
      PermissionStatus storageStatus = await storagePermission.status;

      // 如果存储权限已授予，返回 true
      if (storageStatus.isGranted) {
        return true;
      }

      // 请求权限（优先请求音频权限）
      if (audioStatus.isDenied) {
        audioStatus = await audioPermission.request();
        if (audioStatus.isGranted) {
          return true;
        }
      }

      // 如果音频权限不可用，请求存储权限
      if (storageStatus.isDenied) {
        storageStatus = await storagePermission.request();
        if (storageStatus.isGranted) {
          return true;
        }
      }

      // 检查是否有权限被永久拒绝
      if (audioStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
        debugPrint('存储权限被永久拒绝，请到设置中手动开启');
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('检查存储权限时出错: $e');
      return false;
    }
  }

  /// 检查并请求媒体库权限
  /// Android: 需要存储权限
  /// iOS: 需要照片库权限
  /// @return true 如果权限已授予，false 如果权限被拒绝
  static Future<bool> _checkAndRequestMediaPermission() async {
    try {
      if (Platform.isAndroid) {
        // Android 使用存储权限
        return await _checkAndRequestStoragePermission();
      } else if (Platform.isIOS) {
        // iOS 使用照片库权限
        PermissionStatus status = await Permission.photos.status;
        debugPrint('iOS 照片库权限状态: $status');

        // 如果已经授予或受限访问（iOS 14+），返回 true
        if (status.isGranted || status.isLimited) {
          debugPrint('iOS 照片库权限已授予或受限访问');
          return true;
        }

        // 如果权限被永久拒绝，无法请求
        if (status.isPermanentlyDenied) {
          debugPrint('iOS 照片库权限被永久拒绝，请到设置中手动开启');
          return false;
        }

        // 如果权限被限制（如家长控制），无法请求
        if (status.isRestricted) {
          debugPrint('iOS 照片库权限被限制，无法请求');
          return false;
        }

        // 在 iOS 上，如果权限状态是 denied（用户之前拒绝过），
        // 再次调用 request() 不会弹出对话框，而是直接返回 permanentlyDenied
        // 所以我们需要特殊处理这种情况
        if (status.isDenied) {
          debugPrint('iOS 照片库权限之前被拒绝，尝试请求权限（可能不会弹出对话框）...');
          // 尝试请求权限，虽然可能不会弹出对话框
          status = await Permission.photos.request();
          debugPrint('iOS 照片库权限请求后状态: $status');

          // 如果请求后变成永久拒绝，说明需要去设置中开启
          if (status.isPermanentlyDenied) {
            debugPrint('iOS 照片库权限被永久拒绝，需要到设置中手动开启');
            // 可以在这里打开设置页面，但为了保持方法简洁，只返回 false
            // 调用方可以根据需要处理打开设置页面的逻辑
            return false;
          }

          // 如果请求后授予了权限（虽然不太可能，但检查一下）
          if (status.isGranted || status.isLimited) {
            debugPrint('iOS 照片库权限请求成功');
            return true;
          }

          return false;
        }

        // 对于 notDetermined 状态（首次请求），调用 request() 会弹出权限对话框
        debugPrint('iOS 照片库权限状态未确定，请求权限（将弹出对话框）...');
        status = await Permission.photos.request();
        debugPrint('iOS 照片库权限请求后状态: $status');

        // 请求后检查是否授予或受限访问
        if (status.isGranted || status.isLimited) {
          debugPrint('iOS 照片库权限请求成功');
          return true;
        }

        // 如果请求后仍然被拒绝，可能是用户拒绝了
        if (status.isPermanentlyDenied) {
          debugPrint('iOS 照片库权限被永久拒绝，请到设置中手动开启');
          return false;
        }

        debugPrint('iOS 照片库权限请求被拒绝');
        return false;
      } else {
        // 桌面平台不需要权限
        return true;
      }
    } catch (e, stackTrace) {
      debugPrint('检查媒体库权限时出错: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return false;
    }
  }

  /// 检查音频格式是否支持
  /// @param filePath 文件路径
  /// @return true 如果格式支持，false 如果不支持
  static bool _isAudioFormatSupported(String filePath) {
    try {
      final extension = filePath.split('.').last.toLowerCase();
      return audioExtensions.contains(extension);
    } catch (e) {
      debugPrint('检查音频格式时出错: $e');
      return false;
    }
  }

  /// 将临时文件复制到应用目录（如果需要）
  /// 用于将选择的文件保存到应用的文档目录，避免文件被删除
  /// @param sourceFile 源文件
  /// @return 复制后的文件，如果复制失败则返回 null
  static Future<File?> copyToAppDirectory(File sourceFile) async {
    try {
      if (!await sourceFile.exists()) {
        debugPrint('源文件不存在: ${sourceFile.path}');
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = sourceFile.path.split('/').last;
      final destinationFile = File('${appDir.path}/$fileName');

      // 如果目标文件已存在，先删除
      if (await destinationFile.exists()) {
        await destinationFile.delete();
      }

      // 复制文件
      return await sourceFile.copy(destinationFile.path);
    } catch (e) {
      debugPrint('复制文件失败: $e');
      return null;
    }
  }

  /// 将文件同步到沙盒的持久化音频目录
  /// @param sourceFile 源文件
  /// @param onProgress 进度回调，返回进度、已复制字节数、总字节数
  /// @return 成功返回沙盒内的文件路径，失败返回 null
  static Future<String?> syncAudioToSandbox(
    File sourceFile, {
    SyncProgressCallback? onProgress,
  }) async {
    try {
      if (!await sourceFile.exists()) {
        debugPrint('源文件不存在: ${sourceFile.path}');
        return null;
      }

      final totalBytes = await sourceFile.length();
      final dir = await _getPersistentAudioDirectory();
      final originalFileName = sourceFile.path.split('/').last;
      // 使用 MD5 编码文件名（iOS 26+ 兼容）
      final safeFileName = _generateSafeFileName(originalFileName);
      final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';
      final targetFile = File(targetPath);

      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      final sink = targetFile.openWrite();
      var copiedBytes = 0;

      await for (final chunk in sourceFile.openRead()) {
        sink.add(chunk);
        copiedBytes += chunk.length;
        final progress = totalBytes == 0 ? 1.0 : (copiedBytes / totalBytes).clamp(0, 1).toDouble();
        onProgress?.call(progress, copiedBytes, totalBytes);
      }

      await sink.close();
      return targetFile.path;
    } catch (e) {
      debugPrint('同步文件到沙盒失败: $e');
      return null;
    }
  }

  /// 获取/创建沙盒内持久化音频目录
  /// @return 目录实例
  static Future<Directory> _getPersistentAudioDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_sandboxAudioDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 保存音频文件到本地并返回路径
  ///
  /// [audioBytes] 音频文件的字节数据
  /// [fileName] 文件名（不包含扩展名）
  /// [extension] 文件扩展名，默认为 '.m4a'
  ///
  /// 返回保存后的文件路径，失败返回null
  /// 文件路径格式：时间戳_md5值.扩展名
  static Future<String?> saveAudioToLocal(
    List<int> audioBytes,
    String fileName, {
    String extension = '.m4a',
  }) async {
    try {
      // 确保文件名包含扩展名
      final fullFileName = fileName.endsWith(extension) ? fileName : '$fileName$extension';

      // 使用 MD5 编码文件名（iOS 26+ 兼容）
      final safeFileName = _generateSafeFileName(fullFileName);

      // 获取沙盒持久化音频目录
      final dir = await _getPersistentAudioDirectory();
      // 统一使用 时间戳_md5值.扩展名 格式
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${dir.path}/${timestamp}_$safeFileName';
      final file = File(filePath);

      // 写入文件
      await file.writeAsBytes(audioBytes);

      debugPrint('AudioPickerUtils: 文件已保存到: $filePath (原始文件名: $fullFileName)');
      return filePath;
    } catch (e) {
      debugPrint('AudioPickerUtils: 保存文件异常: $e');
      return null;
    }
  }

  /// 获取音频文件的时长（秒）
  ///
  /// [filePath] 音频文件路径，可以是本地文件路径或 File 对象
  ///
  /// 返回音频时长（秒），如果获取失败返回 null
  /// 注意：此方法不会播放音频，只是读取文件元数据获取时长
  static Future<int?> getAudioDuration(dynamic filePath) async {
    try {
      String path;
      if (filePath is File) {
        if (!await filePath.exists()) {
          debugPrint('AudioPickerUtils: 文件不存在: ${filePath.path}');
          return null;
        }
        path = filePath.path;
      } else if (filePath is String) {
        final file = File(filePath);
        if (!await file.exists()) {
          debugPrint('AudioPickerUtils: 文件不存在: $filePath');
          return null;
        }
        path = filePath;
      } else {
        debugPrint('AudioPickerUtils: 不支持的文件路径类型');
        return null;
      }

      final player = AudioPlayer();
      try {
        await player.setAudioSource(AudioSource.uri(Uri.file(path)));
        final duration = player.duration;
        if (duration != null) {
          return duration.inSeconds;
        }
        return null;
      } finally {
        await player.dispose();
      }
    } catch (e) {
      debugPrint('AudioPickerUtils: 获取音频时长失败: $e');
      return null;
    }
  }
}
