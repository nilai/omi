import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  /// @return 选择的音频文件，如果用户取消或出错则返回 null
  static Future<File?> pickAudioFromAlbum() async {
    try {
      // 检查并请求权限
      final hasPermission = await _checkAndRequestMediaPermission();
      if (!hasPermission) {
        debugPrint('媒体库权限被拒绝，无法从相册选择音频');
        return null;
      }

      if (Platform.isIOS) {
        // iOS: 尝试使用 ImagePicker 的 pickMedia 方法
        // 注意：ImagePicker 主要支持图片和视频，音频支持可能有限
        try {
          final ImagePicker picker = ImagePicker();
          // pickMedia 在 iOS 14+ 支持选择音频文件
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
        } catch (e) {
          debugPrint('使用 ImagePicker 选择音频失败，回退到 FilePicker: $e');
          // 回退到 FilePicker
          return await _pickAudioFromAlbumFallback();
        }
      } else {
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

        // 如果权限未确定或被拒绝，尝试请求权限
        // 在 iOS 上，notDetermined 和 denied 状态都应该调用 request() 来弹出权限对话框
        if (status.isDenied || status == PermissionStatus.denied) {
          debugPrint('iOS 照片库权限被拒绝，尝试请求权限...');
          status = await Permission.photos.request();
          debugPrint('iOS 照片库权限请求后状态: $status');

          // 请求后检查是否授予或受限访问
          if (status.isGranted || status.isLimited) {
            return true;
          }

          // 如果请求后仍然被拒绝，可能是用户拒绝了
          if (status.isPermanentlyDenied) {
            debugPrint('iOS 照片库权限被永久拒绝，请到设置中手动开启');
            return false;
          }

          return false;
        }

        // 对于 notDetermined 状态，也应该请求权限
        // 注意：permission_handler 可能不会将 notDetermined 识别为 isDenied
        // 所以我们需要显式检查并请求
        debugPrint('iOS 照片库权限状态未确定，尝试请求权限...');
        status = await Permission.photos.request();
        debugPrint('iOS 照片库权限请求后状态: $status');

        return status.isGranted || status.isLimited;
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
      final fileName = sourceFile.path.split('/').last;
      final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
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
}
