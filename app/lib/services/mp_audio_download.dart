import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class MPAudioDownloadResult {
  final String path;
  final String fileName;
  MPAudioDownloadResult({required this.path, required this.fileName});
}

/// MP音频下载服务
///
/// 负责处理MP音频文件的完整下载流程：
/// 1. 从URL下载音频文件
/// 2. 从URL中提取文件名
/// 3. 保存文件到本地
/// 4. 返回文件路径和文件名
class MPAudioDownloadService {
  /// 私有构造函数
  MPAudioDownloadService._();

  /// 单例实例
  static final MPAudioDownloadService instance = MPAudioDownloadService._();

  /// 下载目录名称
  static const String _downloadDirName = 'AudioDownloads';

  /// 最大重试次数（用于网络错误）
  static const int _maxRetries = 3;

  /// 获取下载目录路径
  ///
  /// Android: External storage directory / AudioDownloads
  /// iOS: Application Documents Directory / AudioDownloads
  Future<String> _getDownloadPath() async {
    Directory? directory;

    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
      if (directory != null) {
        // Use parent path for more accessible location
        directory = directory.parent;
      }
    }

    // Fallback to documents directory for iOS or if external storage unavailable
    directory ??= await getApplicationDocumentsDirectory();

    final downloadDir = Directory('${directory.path}/$_downloadDirName');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    return downloadDir.path;
  }

  /// 从URL下载音频文件
  ///
  /// [url] 音频文件的URL地址
  /// [onProgress] 可选的进度回调，参数为已下载字节数和总字节数（如果可用）
  ///
  /// 返回下载的音频字节数据，失败返回null
  Future<List<int>?> downloadAudio(
    String url, {
    void Function(int downloaded, int? total)? onProgress,
  }) async {
    try {
      debugPrint('MPAudioDownloadService: 开始下载音频: $url');

      final uri = Uri.parse(url);
      final request = http.Request('GET', uri);
      final streamedResponse = await http.Client().send(request);

      if (streamedResponse.statusCode != 200) {
        debugPrint('MPAudioDownloadService: 下载失败，状态码: ${streamedResponse.statusCode}');
        return null;
      }

      final contentLength = streamedResponse.contentLength;
      final bytes = <int>[];
      int downloaded = 0;

      await for (final chunk in streamedResponse.stream) {
        bytes.addAll(chunk);
        downloaded += chunk.length;
        onProgress?.call(downloaded, contentLength);
      }

      debugPrint('MPAudioDownloadService: 下载完成，大小: ${bytes.length} 字节');
      return bytes;
    } catch (e) {
      debugPrint('MPAudioDownloadService: 下载异常: $e');
      return null;
    }
  }

  /// 带重试的下载音频文件
  ///
  /// [url] 音频文件的URL地址
  /// [onProgress] 可选的进度回调，参数为已下载字节数和总字节数（如果可用）
  ///
  /// 返回下载的音频字节数据，失败返回null
  Future<List<int>?> downloadAudioWithRetry(
    String url, {
    void Function(int downloaded, int? total)? onProgress,
  }) async {
    for (int i = 0; i <= _maxRetries; i++) {
      try {
        final bytes = await downloadAudio(url, onProgress: onProgress);
        if (bytes != null) return bytes;
      } catch (e) {
        debugPrint('MPAudioDownloadService: 下载尝试 ${i + 1} 失败: $e');
        if (i == _maxRetries) return null;
        // 简单的延迟重试
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return null;
  }

  /// 根据音频数据的文件头检测文件格式
  ///
  /// [audioBytes] 音频文件的字节数据
  ///
  /// 返回检测到的文件扩展名（如 '.m4a', '.wav', '.mp3', '.aac'），
  /// 如果无法检测则返回默认值 '.m4a'
  String detectAudioFormat(List<int> audioBytes) {
    if (audioBytes.length < 12) {
      debugPrint('MPAudioDownloadService: 音频数据太短，无法检测格式');
      return '.m4a'; // 默认返回 m4a
    }

    // 检查 WAV 格式 (RIFF...WAVE)
    if (audioBytes.length >= 12) {
      final riffHeader = String.fromCharCodes(audioBytes.sublist(0, 4));
      final waveFormat = audioBytes.length >= 12 ? String.fromCharCodes(audioBytes.sublist(8, 12)) : '';
      if (riffHeader == 'RIFF' && waveFormat == 'WAVE') {
        debugPrint('MPAudioDownloadService: 检测到 WAV 格式');
        return '.wav';
      }
    }

    // 检查 M4A/AAC 格式 (ftyp...M4A 或 ftyp...mp4)
    if (audioBytes.length >= 20) {
      final ftypHeader = String.fromCharCodes(audioBytes.sublist(4, 8));
      if (ftypHeader == 'ftyp') {
        // 检查是否包含 M4A 相关标识
        final brand = String.fromCharCodes(audioBytes.sublist(8, 12));
        if (brand == 'M4A ' || brand == 'mp41' || brand == 'isom') {
          debugPrint('MPAudioDownloadService: 检测到 M4A 格式');
          return '.m4a';
        }
        // 检查是否包含 AAC 相关标识
        if (brand == 'mp42' || brand == 'M4B ') {
          debugPrint('MPAudioDownloadService: 检测到 AAC 格式');
          return '.aac';
        }
      }
    }

    // 检查 AAC ADTS 格式 (0xFF 0xF1 或 0xFF 0xF9)
    if (audioBytes.length >= 2) {
      if (audioBytes[0] == 0xFF && (audioBytes[1] & 0xF6) == 0xF0) {
        debugPrint('MPAudioDownloadService: 检测到 AAC ADTS 格式');
        return '.aac';
      }
    }

    // 检查 MP3 格式
    // MP3 文件可能以 ID3 标签开始 (ID3) 或直接以帧同步字节开始 (0xFF 0xFB 或 0xFF 0xF3)
    if (audioBytes.length >= 3) {
      // 检查 ID3 标签
      final id3Header = String.fromCharCodes(audioBytes.sublist(0, 3));
      if (id3Header == 'ID3') {
        debugPrint('MPAudioDownloadService: 检测到 MP3 格式 (ID3标签)');
        return '.mp3';
      }
      // 检查 MP3 帧同步字节
      if (audioBytes[0] == 0xFF && (audioBytes[1] & 0xE0) == 0xE0) {
        debugPrint('MPAudioDownloadService: 检测到 MP3 格式 (帧同步)');
        return '.mp3';
      }
    }

    // 如果无法检测，返回默认值
    debugPrint('MPAudioDownloadService: 无法检测音频格式，使用默认值 .m4a');
    return '.m4a';
  }

  /// 从URL中获取音频文件名
  ///
  /// [url] 音频文件的URL地址
  ///
  /// 返回文件名，例如从 `audios/44726b9e-ef76-4f89-8e60-fb22b8c9abc8?` 中提取 `44726b9e-ef76-4f89-8e60-fb22b8c9abc8`
  String? getAudioFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;

      // 查找 'audios/' 的位置
      final audiosIndex = path.indexOf('audios/');
      if (audiosIndex == -1) {
        debugPrint('MPAudioDownloadService: URL中未找到 audios/ 路径');
        return null;
      }

      // 提取 audios/ 后面的部分
      final afterAudios = path.substring(audiosIndex + 'audios/'.length);

      // 如果后面有 '/' 或 '?'，则截取到该位置
      final fileName = afterAudios.split('/').first.split('?').first;

      if (fileName.isEmpty) {
        debugPrint('MPAudioDownloadService: 无法从URL中提取文件名');
        return null;
      }

      debugPrint('MPAudioDownloadService: 提取的文件名: $fileName');
      return fileName;
    } catch (e) {
      debugPrint('MPAudioDownloadService: 提取文件名异常: $e');
      return null;
    }
  }

  /// 保存音频文件到本地并返回路径
  ///
  /// [audioBytes] 音频文件的字节数据
  /// [fileName] 文件名（不包含扩展名）
  /// [extension] 文件扩展名，默认为 '.m4a'
  ///
  /// 返回保存后的文件路径，失败返回null
  Future<String?> saveAudioToLocal(
    List<int> audioBytes,
    String fileName, {
    String extension = '.m4a',
  }) async {
    try {
      // 确保文件名包含扩展名
      final fullFileName = fileName.endsWith(extension) ? fileName : '$fileName$extension';

      // 获取下载目录
      final downloadPath = await _getDownloadPath();
      final filePath = '$downloadPath/$fullFileName';
      final file = File(filePath);

      // 写入文件
      await file.writeAsBytes(audioBytes);

      debugPrint('MPAudioDownloadService: 文件已保存到: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('MPAudioDownloadService: 保存文件异常: $e');
      return null;
    }
  }

  /// 整合后的方法：下载音频并保存到本地
  ///
  /// [url] 音频文件的URL地址
  /// [extension] 文件扩展名（已废弃，将根据音频数据自动检测）
  /// [onProgress] 可选的进度回调，参数为已下载字节数和总字节数（如果可用）
  ///
  /// 返回包含文件路径和文件名的 [MPAudioDownloadResult]，失败返回null
  Future<MPAudioDownloadResult?> downloadAndSaveAudio(
    String url, {
    String extension = '.m4a', // 已废弃，保留以保持向后兼容
    void Function(int downloaded, int? total)? onProgress,
  }) async {
    try {
      // 步骤 1: 下载音频
      debugPrint('MPAudioDownloadService: 步骤 1/4 - 开始下载音频');
      final audioBytes = await downloadAudioWithRetry(url, onProgress: onProgress);
      if (audioBytes == null) {
        debugPrint('MPAudioDownloadService: 下载失败');
        return null;
      }

      // 步骤 2: 根据音频数据检测文件格式
      debugPrint('MPAudioDownloadService: 步骤 2/4 - 检测音频格式');
      final detectedExtension = detectAudioFormat(audioBytes);
      debugPrint('MPAudioDownloadService: 检测到的扩展名: $detectedExtension');

      // 步骤 3: 从URL中提取文件名
      debugPrint('MPAudioDownloadService: 步骤 3/4 - 提取文件名');
      final fileName = getAudioFileName(url);
      if (fileName == null) {
        debugPrint('MPAudioDownloadService: 无法提取文件名');
        return null;
      }

      // 步骤 4: 保存文件到本地（使用检测到的扩展名）
      debugPrint('MPAudioDownloadService: 步骤 4/4 - 保存文件到本地');
      final filePath = await saveAudioToLocal(audioBytes, fileName, extension: detectedExtension);
      if (filePath == null) {
        debugPrint('MPAudioDownloadService: 保存文件失败');
        return null;
      }

      debugPrint('MPAudioDownloadService: 下载并保存完成');
      return MPAudioDownloadResult(path: filePath, fileName: fileName);
    } catch (e) {
      debugPrint('MPAudioDownloadService: 下载并保存异常: $e');
      return null;
    }
  }
}
