// AI-generated START - 声纹识别事件服务
import 'dart:async';

/// 声纹识别事件类型
enum VoiceRecognitionEventType {
  /// 声音保存成功
  voiceSaved,

  /// 声音删除成功
  voiceDeleted,
}

/// 声纹识别事件
class VoiceRecognitionEvent {
  /// 事件类型
  final VoiceRecognitionEventType type;

  /// 事件数据（可选）
  final Map<String, dynamic>? data;

  VoiceRecognitionEvent({
    required this.type,
    this.data,
  });
}

/// 声纹识别事件服务
/// 用于发送和监听声纹识别相关的事件
class VoiceRecognitionEventService {
  // 单例模式
  static final VoiceRecognitionEventService _instance = VoiceRecognitionEventService._internal();
  factory VoiceRecognitionEventService() => _instance;
  VoiceRecognitionEventService._internal();

  // 事件流控制器
  final _eventController = StreamController<VoiceRecognitionEvent>.broadcast();

  /// 获取事件流
  Stream<VoiceRecognitionEvent> get events => _eventController.stream;

  /// 发送事件
  void emit(VoiceRecognitionEvent event) {
    _eventController.add(event);
  }

  /// 发送声音保存成功事件
  void emitVoiceSaved({Map<String, dynamic>? data}) {
    emit(VoiceRecognitionEvent(
      type: VoiceRecognitionEventType.voiceSaved,
      data: data,
    ));
  }

  /// 发送声音删除成功事件
  void emitVoiceDeleted({Map<String, dynamic>? data}) {
    emit(VoiceRecognitionEvent(
      type: VoiceRecognitionEventType.voiceDeleted,
      data: data,
    ));
  }

  /// 释放资源
  void dispose() {
    _eventController.close();
  }
}
// AI-generated END - voice_recognition_event_service.dart
