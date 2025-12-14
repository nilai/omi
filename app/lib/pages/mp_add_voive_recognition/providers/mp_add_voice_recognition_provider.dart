// AI-generated START - 录制声纹状态管理Provider
import 'dart:async';
import 'package:flutter/material.dart';

/// 录制声纹状态管理Provider
/// 管理声纹录制相关的状态
class MPAddVoiceRecognitionProvider with ChangeNotifier {
  // AI-generated START - 是否正在录音
  bool _isRecording = false;
  // AI-generated END - _isRecording

  // AI-generated START - 录音时长（秒）
  int _recordingDuration = 0;
  // AI-generated END - _recordingDuration

  // AI-generated START - 定时器
  Timer? _recordingTimer;
  // AI-generated END - _recordingTimer

  // AI-generated START - 最大录音时长（秒）
  static const int maxRecordingDuration = 90;
  // AI-generated END - maxRecordingDuration

  // AI-generated START - 获取是否正在录音
  bool get isRecording => _isRecording;
  // AI-generated END - isRecording

  // AI-generated START - 获取录音时长
  int get recordingDuration => _recordingDuration;
  // AI-generated END - recordingDuration

  // AI-generated START - 开始录音
  void startRecording() {
    _isRecording = true;
    _recordingDuration = 0;
    notifyListeners();
    
    // 启动定时器，每秒更新一次
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_recordingDuration < maxRecordingDuration) {
        _recordingDuration++;
        notifyListeners();
      } else {
        // 达到最大时长，自动停止
        stopRecording();
      }
    });
    
    // TODO: 实现实际的录音逻辑
  }
  // AI-generated END - startRecording

  // AI-generated START - 停止录音
  void stopRecording() {
    _isRecording = false;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    notifyListeners();
    // TODO: 实现停止录音和保存逻辑
  }
  // AI-generated END - stopRecording

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }
}
// AI-generated END - mp_add_voice_recognition_provider.dart
// AI-generated END - mp_add_voice_recognition_provider.dart

