import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:omi/backend/schema/bt_device/note_device.dart';
import 'package:omi/providers/device_provider.dart';
import 'package:omi/services/devices/note_connection.dart';
import 'package:omi/services/services.dart';
import 'package:omi/utils/audio_converter_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

/// 设备文件详细信息模型
///
/// 包含文件的完整信息：文件名、大小、时间、断点时间等
class MPDeviceFileDetail {
  /// 文件名
  final String name;

  /// 文件大小（字节），如果文件未下载则为估算值
  final int size;

  /// 文件创建时间（从文件名解析）
  final DateTime? createTime;

  /// 断点时间（录音时长，秒）
  final int durationSeconds;

  /// 文件索引
  final int index;

  /// 是否为估算的文件大小
  final bool isEstimatedSize;

  /// 本地文件路径（如果已下载）
  final String? localPath;

  /// MP3文件路径（如果已转换）
  final String? mp3Path;

  MPDeviceFileDetail({
    required this.name,
    required this.size,
    this.createTime,
    required this.durationSeconds,
    required this.index,
    this.isEstimatedSize = true,
    this.localPath,
    this.mp3Path,
  });

  /// 从 NoteFileInfo 创建
  factory MPDeviceFileDetail.fromNoteFileInfo(
    NoteFileInfo fileInfo, {
    String? localPath,
    String? mp3Path,
    int? actualSize,
  }) {
    // 解析文件名中的时间信息
    // 文件名格式通常为: YYYYMMDD_HHMMSS_xxx.opus
    DateTime? createTime;
    try {
      final parts = fileInfo.name.split('_');
      if (parts.length >= 2) {
        final dateStr = parts[0];
        final timeStr = parts[1];
        if (dateStr.length == 8 && timeStr.length >= 6) {
          final year = int.parse(dateStr.substring(0, 4));
          final month = int.parse(dateStr.substring(4, 6));
          final day = int.parse(dateStr.substring(6, 8));
          final hour = int.parse(timeStr.substring(0, 2));
          final minute = int.parse(timeStr.substring(2, 4));
          final second = int.parse(timeStr.substring(4, 6));
          createTime = DateTime(year, month, day, hour, minute, second);
        }
      }
    } catch (e) {
      print('[MPDeviceFileUtil] 解析文件时间失败: $e');
    }

    // 估算文件大小：16kHz, 16bit PCM = 32KB/s
    // Opus压缩比约为1:10，所以约为3.2KB/s
    const int bytesPerSecond = 3200;
    final estimatedSize = fileInfo.durationSeconds * bytesPerSecond;

    return MPDeviceFileDetail(
      name: fileInfo.name,
      size: actualSize ?? estimatedSize,
      createTime: createTime,
      durationSeconds: fileInfo.durationSeconds,
      index: fileInfo.index,
      isEstimatedSize: actualSize == null,
      localPath: localPath,
      mp3Path: mp3Path,
    );
  }

  /// 格式化的文件大小字符串
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// 格式化的时长字符串 (HH:MM:SS)
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

/// 设备文件工具类
///
/// 提供设备文件管理功能：获取文件列表、导出文件、转换MP3、删除文件
/// 单例模式，通过 instance 获取实例
class MPDeviceFileUtil {
  /// 私有构造函数
  MPDeviceFileUtil._();

  /// 单例实例
  static final MPDeviceFileUtil instance = MPDeviceFileUtil._();

  /// 音频转换工具实例
  final AudioConverterUtils _audioConverter = AudioConverterUtils();

  /// 下载目录名称
  static const String _downloadDirName = 'NoteDownloads';

  /// 写入缓冲区大小（32KB）
  static const int _writeBufferSize = 32 * 1024;

  /// 当前下载的文件名
  String? _downloadingFileName;

  /// 当前下载的文件路径
  String? _currentFilePath;

  /// 文件数据缓冲区
  final List<int> _fileDataBuffer = [];

  /// 文件写入流
  IOSink? _fileSink;

  /// 文件数据流订阅
  StreamSubscription? _fileDataSubscription;

  /// 响应流订阅
  StreamSubscription<List<int>>? _responseSubscription;

  /// 是否正在下载
  bool get isDownloading => _downloadingFileName != null;

  /// 当前下载的文件名
  String? get downloadingFileName => _downloadingFileName;

  /// 获取下载目录路径
  ///
  /// Android: External storage directory / NoteDownloads
  /// iOS: Application Documents Directory / NoteDownloads
  Future<String> getDownloadPath() async {
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

  /// 获取设备连接
  ///
  /// [context] BuildContext，用于获取 DeviceProvider
  ///
  /// 返回 NoteDeviceConnection，如果未连接则返回 null
  Future<NoteDeviceConnection?> _getConnection(BuildContext context) async {
    try {
      final deviceProvider = context.read<DeviceProvider>();

      if (deviceProvider.connectedDevice == null) {
        print('[MPDeviceFileUtil] 设备未连接');
        return null;
      }

      final connection = await ServiceManager.instance().device.ensureConnection(deviceProvider.connectedDevice!.id);

      if (connection is NoteDeviceConnection) {
        return connection;
      }

      print('[MPDeviceFileUtil] 无法获取设备连接');
      return null;
    } catch (e) {
      print('[MPDeviceFileUtil] 获取设备连接失败: $e');
      return null;
    }
  }

  /// 获取设备上所有文件列表
  ///
  /// [context] BuildContext，用于获取 DeviceProvider
  ///
  /// 返回包含文件详细信息的列表
  /// 包含文件名、文件大小、时间、断点时间等所有相关信息
  Future<List<MPDeviceFileDetail>> getDeviceFiles(BuildContext context) async {
    try {
      final connection = await _getConnection(context);
      if (connection == null) {
        throw Exception('设备未连接');
      }

      // 获取文件列表
      final files = await connection.getFileList();
      print('[MPDeviceFileUtil] 获取到 ${files.length} 个文件');

      // 获取下载目录路径
      final downloadPath = await getDownloadPath();

      // 转换为详细信息列表
      final List<MPDeviceFileDetail> fileDetails = [];
      for (final file in files) {
        final localPath = '$downloadPath/${file.name}';
        final localFile = File(localPath);
        final mp3Path = _getMp3Path(localPath);
        final mp3File = File(mp3Path);

        // 如果文件已下载，获取实际大小
        int? actualSize;
        if (localFile.existsSync()) {
          actualSize = await localFile.length();
        }

        final detail = MPDeviceFileDetail.fromNoteFileInfo(
          file,
          localPath: localFile.existsSync() ? localPath : null,
          mp3Path: mp3File.existsSync() ? mp3Path : null,
          actualSize: actualSize,
        );

        fileDetails.add(detail);
      }

      return fileDetails;
    } catch (e) {
      print('[MPDeviceFileUtil] 获取文件列表失败: $e');
      rethrow;
    }
  }

  /// 导出文件（从设备下载到本地）
  ///
  /// [context] BuildContext，用于获取 DeviceProvider
  /// [fileDetail] 文件详情对象，包含文件名和时长信息
  /// [onProgress] 可选的回调函数，用于报告下载进度 (0.0 - 1.0)
  ///
  /// 返回下载后的文件路径
  Future<String> exportFileFromDetail(
    BuildContext context,
    MPDeviceFileDetail fileDetail, {
    void Function(double progress)? onProgress,
  }) async {
    return exportFile(
      context,
      fileDetail.name,
      durationSeconds: fileDetail.durationSeconds,
      onProgress: onProgress,
    );
  }

  /// 导出文件（从设备下载到本地）
  ///
  /// [context] BuildContext，用于获取 DeviceProvider
  /// [fileName] 要导出的文件名
  /// [durationSeconds] 可选的文件时长（秒），用于估算进度
  /// [onProgress] 可选的回调函数，用于报告下载进度 (0.0 - 1.0)
  ///
  /// 返回下载后的文件路径
  Future<String> exportFile(
    BuildContext context,
    String fileName, {
    int? durationSeconds,
    void Function(double progress)? onProgress,
  }) async {
    if (_downloadingFileName != null) {
      throw Exception('另一个文件正在下载中');
    }

    try {
      final connection = await _getConnection(context);
      if (connection == null) {
        throw Exception('设备未连接');
      }

      _downloadingFileName = fileName;
      _fileDataBuffer.clear();

      // 估算总字节数（如果提供了时长）
      // Opus压缩比约为1:10，16kHz 16bit PCM = 32KB/s，压缩后约为3.2KB/s
      if (durationSeconds != null) {
        _estimatedTotalBytes = durationSeconds * 3200;
      } else {
        _estimatedTotalBytes = 0;
      }

      // 创建下载目录和文件
      final downloadPath = await getDownloadPath();
      _currentFilePath = '$downloadPath/$fileName';
      final outputFile = File(_currentFilePath!);
      _fileSink = outputFile.openWrite();
      print('[MPDeviceFileUtil] 开始下载文件: $fileName');

      // 设置完成监听器
      _setupCompletionListener(connection, onProgress);

      // 设置文件数据监听器
      _fileDataSubscription?.cancel();
      _fileDataSubscription = await connection.getFileDataListener(
        onFileDataReceived: (data) => _onFileDataReceived(data, onProgress),
      );

      // 请求文件上传
      await connection.uploadFile(fileName);

      // 等待下载完成
      final completer = Completer<String>();
      _downloadCompleter = completer;

      return await completer.future;
    } catch (e) {
      _cleanupDownloadState();
      print('[MPDeviceFileUtil] 导出文件失败: $e');
      rethrow;
    }
  }

  /// 下载完成等待器
  Completer<String>? _downloadCompleter;

  /// 设置完成监听器
  void _setupCompletionListener(
    NoteDeviceConnection connection,
    void Function(double progress)? onProgress,
  ) {
    _responseSubscription?.cancel();
    _responseSubscription = connection.bleTransport.responseStream.listen(
      (data) {
        // 检测文件上传完成信号: 0x04 0x02
        if (data.length >= 2 && data[0] == 0x04 && data[1] == 0x02) {
          print('[MPDeviceFileUtil] 收到文件传输完成信号');
          _completeDownload(onProgress);
        }
      },
    );
  }

  /// 处理接收到的文件数据
  void _onFileDataReceived(
    List<int> data,
    void Function(double progress)? onProgress,
  ) {
    if (_downloadingFileName == null || _fileSink == null) return;

    // 添加数据到缓冲区
    _fileDataBuffer.addAll(data);

    // 当缓冲区满时刷新到文件
    if (_fileDataBuffer.length >= _writeBufferSize) {
      _flushBuffer();
    }

    // 报告进度（基于实际下载的字节数）
    if (onProgress != null) {
      final downloaded = _getDownloadedBytes() + _fileDataBuffer.length;
      if (_estimatedTotalBytes > 0) {
        // 如果有估算值，使用估算值计算进度
        final progress = (downloaded / _estimatedTotalBytes).clamp(0.0, 1.0);
        onProgress(progress);
      } else {
        // 如果没有估算值，使用文件大小计算进度
        final fileSize = _getFileSize();
        if (fileSize > 0) {
          final progress = (downloaded / fileSize).clamp(0.0, 1.0);
          onProgress(progress);
        }
      }
    }
  }

  /// 获取文件大小（如果文件已存在）
  int _getFileSize() {
    if (_currentFilePath == null) return 0;
    try {
      final file = File(_currentFilePath!);
      if (file.existsSync()) {
        return file.lengthSync();
      }
    } catch (e) {
      // 忽略错误
    }
    return 0;
  }

  /// 已下载的字节数（从文件大小计算）
  int _getDownloadedBytes() {
    if (_currentFilePath == null) return 0;
    try {
      final file = File(_currentFilePath!);
      if (file.existsSync()) {
        return file.lengthSync();
      }
    } catch (e) {
      // 忽略错误
    }
    return 0;
  }

  /// 估算的总字节数
  int _estimatedTotalBytes = 0;

  /// 刷新缓冲区数据到文件
  void _flushBuffer() {
    if (_fileDataBuffer.isEmpty || _fileSink == null) return;

    _fileSink!.add(Uint8List.fromList(_fileDataBuffer));
    _fileDataBuffer.clear();
  }

  /// 完成下载
  Future<void> _completeDownload(
    void Function(double progress)? onProgress,
  ) async {
    final fileName = _downloadingFileName;
    if (fileName == null) return;

    print('[MPDeviceFileUtil] 下载完成: $fileName');

    try {
      // 取消订阅
      _fileDataSubscription?.cancel();
      _fileDataSubscription = null;
      _responseSubscription?.cancel();
      _responseSubscription = null;

      // 刷新剩余缓冲区数据
      _flushBuffer();

      // 关闭文件流
      await _fileSink?.flush();
      await _fileSink?.close();
      _fileSink = null;

      final filePath = _currentFilePath!;
      print('[MPDeviceFileUtil] 文件已保存到: $filePath');

      // 报告完成
      onProgress?.call(1.0);

      // 完成等待器
      if (_downloadCompleter != null && !_downloadCompleter!.isCompleted) {
        _downloadCompleter!.complete(filePath);
        _downloadCompleter = null;
      }
    } catch (e) {
      print('[MPDeviceFileUtil] 完成下载时出错: $e');
      if (_downloadCompleter != null && !_downloadCompleter!.isCompleted) {
        _downloadCompleter!.completeError(e);
        _downloadCompleter = null;
      }
    } finally {
      _cleanupDownloadState();
    }
  }

  /// 清理下载状态
  void _cleanupDownloadState() {
    _downloadingFileName = null;
    _fileDataBuffer.clear();
    _fileSink = null;
    _currentFilePath = null;
    _estimatedTotalBytes = 0;
  }

  /// 取消当前下载
  Future<void> cancelDownload() async {
    if (_downloadingFileName != null) {
      print('[MPDeviceFileUtil] 取消下载: $_downloadingFileName');

      // 取消订阅
      _fileDataSubscription?.cancel();
      _fileDataSubscription = null;
      _responseSubscription?.cancel();
      _responseSubscription = null;

      // 关闭文件流
      await _fileSink?.close();
      _fileSink = null;

      // 删除不完整的文件
      if (_currentFilePath != null) {
        try {
          final file = File(_currentFilePath!);
          if (await file.exists()) {
            await file.delete();
            print('[MPDeviceFileUtil] 已删除不完整文件: $_currentFilePath');
          }
        } catch (e) {
          print('[MPDeviceFileUtil] 删除不完整文件失败: $e');
        }
      }

      // 完成等待器（如果存在）
      if (_downloadCompleter != null && !_downloadCompleter!.isCompleted) {
        _downloadCompleter!.completeError(Exception('下载已取消'));
        _downloadCompleter = null;
      }

      // 清理状态
      _cleanupDownloadState();
    }
  }

  /// 文件转MP3
  ///
  /// [opusFilePath] Opus文件路径
  /// [onProgress] 可选的回调函数，用于报告转换进度 (0.0 - 1.0)
  ///
  /// 返回转换后的MP3文件路径
  Future<String> convertToMp3(
    String opusFilePath, {
    void Function(double progress)? onProgress,
  }) async {
    final file = File(opusFilePath);
    if (!file.existsSync()) {
      throw Exception('文件不存在: $opusFilePath');
    }

    try {
      print('[MPDeviceFileUtil] 开始转换MP3: $opusFilePath');

      final mp3Path = await _audioConverter.convertOpusToMp3(
        opusFilePath: opusFilePath,
        sampleRate: 16000,
        channels: 1, // Note设备使用单声道
        onProgress: onProgress,
      );

      print('[MPDeviceFileUtil] MP3转换完成: $mp3Path');
      return mp3Path;
    } catch (e) {
      print('[MPDeviceFileUtil] MP3转换失败: $e');
      rethrow;
    }
  }

  /// 删除设备上的文件
  ///
  /// [context] BuildContext，用于获取 DeviceProvider
  /// [fileName] 要删除的文件名
  Future<void> deleteFile(BuildContext context, String fileName) async {
    try {
      final connection = await _getConnection(context);
      if (connection == null) {
        throw Exception('设备未连接');
      }

      print('[MPDeviceFileUtil] 删除文件: $fileName');
      await connection.deleteFile(fileName);
      print('[MPDeviceFileUtil] 文件已删除: $fileName');
    } catch (e) {
      print('[MPDeviceFileUtil] 删除文件失败: $e');
      rethrow;
    }
  }

  /// 获取MP3文件路径
  String _getMp3Path(String opusFilePath) {
    final lastDot = opusFilePath.lastIndexOf('.');
    if (lastDot > 0) {
      return '${opusFilePath.substring(0, lastDot)}.mp3';
    }
    return '$opusFilePath.mp3';
  }

  /// 检查文件是否已转换为MP3
  ///
  /// [opusFilePath] Opus文件路径
  ///
  /// 返回MP3文件路径，如果未转换则返回null
  Future<String?> getMp3Path(String opusFilePath) async {
    final mp3Path = _getMp3Path(opusFilePath);
    final file = File(mp3Path);
    if (await file.exists()) {
      return mp3Path;
    }
    return null;
  }

  /// 批量导出所有文件
  ///
  /// [context] BuildContext，用于获取 DeviceProvider
  /// [onFileListCount] 文件列表数量回调
  /// [onExportProgress] 导出进度回调，参数：文件索引、进度(0.0-1.0)、速度(字节/秒)
  /// [onFileExported] 文件导出完成回调，参数：文件索引、文件详情
  ///
  /// 返回所有导出文件的路径列表
  Future<List<String>> exportAllFiles(
    BuildContext context, {
    void Function(int count)? onFileListCount,
    void Function(int index, double progress, double speed)? onExportProgress,
    void Function(int index, MPDeviceFileDetail fileDetail)? onFileExported,
  }) async {
    try {
      // 1. 获取所有文件列表
      final files = await getDeviceFiles(context);
      final fileCount = files.length;
      print('[MPDeviceFileUtil] 开始批量导出，共 $fileCount 个文件');

      // 回调文件列表数量
      onFileListCount?.call(fileCount);

      if (fileCount == 0) {
        print('[MPDeviceFileUtil] 没有文件需要导出');
        return [];
      }

      final List<String> exportedPaths = [];

      // 2. 遍历文件，逐个导出
      for (int i = 0; i < files.length; i++) {
        final fileDetail = files[i];
        print('[MPDeviceFileUtil] 开始导出文件 [$i/$fileCount]: ${fileDetail.name}');

        try {
          // 用于跟踪速度的变量
          final stopwatch = Stopwatch();

          // 导出文件，带进度和速度回调
          final filePath = await exportFileFromDetail(
            context,
            fileDetail,
            onProgress: (progress) {
              double speed = 0.0;

              if (!stopwatch.isRunning) {
                // 第一次更新，开始计时
                stopwatch.start();
              } else {
                // 计算速度：使用总下载字节数除以总时间
                final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000.0;
                if (elapsedSeconds > 0) {
                  final currentDownloaded = _getDownloadedBytes() + _fileDataBuffer.length;
                  // 使用平均速度（总字节数 / 总时间）
                  speed = currentDownloaded / elapsedSeconds;
                }
              }

              // 回调进度和速度
              onExportProgress?.call(i, progress, speed);
            },
          );

          exportedPaths.add(filePath);
          print('[MPDeviceFileUtil] 文件 [$i/$fileCount] 导出完成: $filePath');

          // 3. 文件导出完成回调
          // 更新文件详情中的本地路径
          final updatedDetail = MPDeviceFileDetail(
            name: fileDetail.name,
            size: fileDetail.size,
            createTime: fileDetail.createTime,
            durationSeconds: fileDetail.durationSeconds,
            index: fileDetail.index,
            isEstimatedSize: fileDetail.isEstimatedSize,
            localPath: filePath,
            mp3Path: fileDetail.mp3Path,
          );

          onFileExported?.call(i, updatedDetail);
        } catch (e) {
          print('[MPDeviceFileUtil] 导出文件 [$i/$fileCount] 失败: $e');
          // 继续导出下一个文件，不中断整个流程
        }
      }

      print('[MPDeviceFileUtil] 批量导出完成，共导出 ${exportedPaths.length}/$fileCount 个文件');
      return exportedPaths;
    } catch (e) {
      print('[MPDeviceFileUtil] 批量导出失败: $e');
      rethrow;
    }
  }

  /// 清理资源
  void dispose() {
    _fileDataSubscription?.cancel();
    _responseSubscription?.cancel();
    _fileSink?.close();
    _cleanupDownloadState();
  }
}
