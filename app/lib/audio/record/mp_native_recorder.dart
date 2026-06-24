import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 原生录音器事件（混音模式下系统打断/恢复）。
enum MPNativeRecorderEventType {
  interruptionBegan,
  interruptionEnded,
}

class MPNativeRecorderEvent {
  const MPNativeRecorderEvent({required this.type});

  final MPNativeRecorderEventType type;
}

/// 首页长录音：iOS [AVAudioRecorder] / Android [MediaRecorder] 整段单文件；混音模式下支持系统打断后自动续录。
class MPNativeRecorder {
  MPNativeRecorder();

  static const MethodChannel _channel = MethodChannel('mp_native_recorder');
  static const EventChannel _eventChannel = EventChannel('mp_native_recorder/events');

  Stream<MPNativeRecorderEvent>? _eventStream;

  /// 混音模式下原生层打断/恢复事件。
  Stream<MPNativeRecorderEvent> get recordingEvents {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const Stream<MPNativeRecorderEvent>.empty();
    }
    return _eventStream ??= _eventChannel.receiveBroadcastStream().map((dynamic raw) {
      if (raw is! Map) {
        return null;
      }
      final String? type = raw['type'] as String?;
      switch (type) {
        case 'interruptionBegan':
          return const MPNativeRecorderEvent(type: MPNativeRecorderEventType.interruptionBegan);
        case 'interruptionEnded':
          return const MPNativeRecorderEvent(type: MPNativeRecorderEventType.interruptionEnded);
        default:
          return null;
      }
    }).where((MPNativeRecorderEvent? event) => event != null).cast<MPNativeRecorderEvent>();
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

  /// 开始写入整段 [path]。
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

  /// 暂停整段录音并保留文件。
  Future<String?> pauseSegment() async {
    try {
      return await _channel.invokeMethod<String>('pauseSegment');
    } catch (e, st) {
      debugPrint('MPNativeRecorder.pauseSegment: $e\n$st');
      return null;
    }
  }

  /// 在同文件上继续录音。
  Future<bool> resumeSegment() async {
    try {
      final bool? ok = await _channel.invokeMethod<bool>('resumeSegment');
      return ok ?? false;
    } catch (e, st) {
      debugPrint('MPNativeRecorder.resumeSegment: $e\n$st');
      return false;
    }
  }

  /// 结束录音并返回整段文件路径。
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
}
