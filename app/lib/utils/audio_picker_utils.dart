import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../backend/http/api/audio_record.dart';

/// 音频选择工具类
/// 提供从文件、相册和其他应用选择音频文件的功能
class AudioPickerUtils {

  /// 从文件选择音频
  static Future<File?> pickAudioFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: audioExtensions,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        
        if (_isAudioFormatSupported(filePath)) {
          return file;
        } else {
          debugPrint('不支持的音频格式');
          return null;
        }
      }
    } catch (e) {
      debugPrint('从文件选择音频失败: $e');
    }
    return null;
  }

  /// 从相册选择音频
  static Future<File?> pickAudioFromAlbum() async {
    try {
      if (Platform.isIOS) {
        // iOS 平台使用 UIDocumentPickerViewController 访问相册
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: audioExtensions,
          withData: false,
        );
        
        if (result != null && result.files.single.path != null) {
          final filePath = result.files.single.path!;
          final file = File(filePath);
          
          if (_isAudioFormatSupported(filePath)) {
            return file;
          } else {
            debugPrint('不支持的音频格式');
            return null;
          }
        }
      } else {
        // Android 平台使用 file_picker 从媒体库选择
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
        );
        
        if (result != null && result.files.single.path != null) {
          final filePath = result.files.single.path!;
          final file = File(filePath);
          
          if (_isAudioFormatSupported(filePath)) {
            return file;
          } else {
            debugPrint('不支持的音频格式');
            return null;
          }
        }
      }
    } catch (e) {
      debugPrint('从相册选择音频失败: $e');
    }
    return null;
  }

  /// 从其他应用选择音频
  static Future<File?> pickAudioFromOtherApp(BuildContext context) async {
    try {
      if (Platform.isIOS) {
        // iOS上使用UIDocumentPickerViewController
        // 但Flutter没有直接的API，需要使用file_picker的另一种方式
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
          allowMultiple: false,
        );
        
        if (result != null && result.files.single.path != null) {
          final filePath = result.files.single.path!;
          final file = File(filePath);
          
          if (_isAudioFormatSupported(filePath)) {
            return file;
          } else {
            debugPrint('不支持的音频格式');
            return null;
          }
        }
      } else {
        // Android上使用Intent.ACTION_GET_CONTENT
        // 同样使用file_picker实现
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
          allowMultiple: false,
        );
        
        if (result != null && result.files.single.path != null) {
          final filePath = result.files.single.path!;
          final file = File(filePath);
          
          if (_isAudioFormatSupported(filePath)) {
            return file;
          } else {
            debugPrint('不支持的音频格式');
            return null;
          }
        }
      }
    } catch (e) {
      debugPrint('从其他应用选择音频失败: $e');
    }
    return null;
  }

  /// 检查音频格式是否支持
  static bool _isAudioFormatSupported(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return audioExtensions.contains(extension);
  }

  /// 将临时文件复制到应用目录（如果需要）
  static Future<File?> copyToAppDirectory(File sourceFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = sourceFile.path.split('/').last;
      final destinationFile = File('${appDir.path}/$fileName');
      
      if (await destinationFile.exists()) {
        await destinationFile.delete();
      }
      
      return await sourceFile.copy(destinationFile.path);
    } catch (e) {
      debugPrint('复制文件失败: $e');
      return null;
    }
  }
}