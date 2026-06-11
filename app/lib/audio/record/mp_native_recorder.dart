import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 首页长录音：iOS [AVAudioRecorder] / Android [MediaRecorder] 原生实现，支持混音与打断自动续录。
class MPNativeRecorder {
  MPNativeRecorder();

  static const MethodChannel _channel = MethodChannel('mp_native_recorder');
  static const EventChannel _eventChannel = EventChannel('mp_native_recorder/events');

  Stream<Map<String, dynamic>>? _eventStream;
  StreamSubscription<Map<String, dynamic>>? _eventSub;
  void Function(String path)? _onAutoSegmentStarted;

  /// 订阅原生自动续录新分段（系统音频打断结束后）。
  void listenAutoSegmentStarted(void Function(String path) onStarted) {
    _onAutoSegmentStarted = onStarted;
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((dynamic e) => Map<String, dynamic>.from(e as Map));
    _eventSub ??= _eventStream!.listen((Map<String, dynamic> event) {
      if (event['type'] == 'segmentAutoStarted') {
        final String? path = event['path'] as String?;
        if (path != null && path.isNotEmpty) {
          _onAutoSegmentStarted?.call(path);
        }
      }
    });
  }

  Future<void> dispose() async {
    await _eventSub?.cancel();
    _eventSub = null;
    _eventStream = null;
    _onAutoSegmentStarted = null;
  }

  /// 打开原生录音器；[mixWithOthers] 为 true 时启用混音并自动处理系统打断。
  Future<bool> open({required bool mixWithOthers}) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }
    try {
      final bool? ok = await _channel.invokeMethod<bool>('open', <String, dynamic>{
        'mixWithOthers': mixWithOthers,
      });
      return ok ?? false;
    } catch (e, st) {
      debugPrint('MPNativeRecorder.open: $e\n$st');
      return false;
    }
  }

  Future<void> close() async {
    try {
      await _channel.invokeMethod<void>('close');
    } catch (e, st) {
      debugPrint('MPNativeRecorder.close: $e\n$st');
    }
  }

  /// 开始写入 [path]（新分段）。
  Future<bool> start(String path) async {
    try {
      final bool? ok = await _channel.invokeMethod<bool>('start', <String, dynamic>{
        'path': path,
      });
      return ok ?? false;
    } catch (e, st) {
      debugPrint('MPNativeRecorder.start: $e\n$st');
      return false;
    }
  }

  /// 停止当前分段并保留文件；返回该段路径。
  Future<String?> pauseSegment() async {
    try {
      return await _channel.invokeMethod<String>('pauseSegment');
    } catch (e, st) {
      debugPrint('MPNativeRecorder.pauseSegment: $e\n$st');
      return null;
    }
  }

  /// 结束录音：合并全部分段到 [outputPath]，返回最终路径。
  Future<String?> finish({required String outputPath}) async {
    try {
      return await _channel.invokeMethod<String>('finish', <String, dynamic>{
        'outputPath': outputPath,
      });
    } catch (e, st) {
      debugPrint('MPNativeRecorder.finish: $e\n$st');
      return null;
    }
  }

  Future<bool> isRecording() async {
    try {
      final bool? ok = await _channel.invokeMethod<bool>('isRecording');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> currentPath() async {
    try {
      return await _channel.invokeMethod<String>('currentPath');
    } catch (_) {
      return null;
    }
  }

  Future<int> fileSize(String path) async {
    try {
      final int? size = await _channel.invokeMethod<int>('fileSize', <String, dynamic>{
        'path': path,
      });
      return size ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<String>> segmentPaths() async {
    try {
      final List<dynamic>? list = await _channel.invokeMethod<List<dynamic>>('segmentPaths');
      return list?.map((dynamic e) => e.toString()).toList() ?? <String>[];
    } catch (_) {
      return <String>[];
    }
  }
}
