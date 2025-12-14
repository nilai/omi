// AI-generated START - 声纹详情状态管理Provider
import 'dart:async';

import 'package:flutter/material.dart';

/// 声纹详情状态管理Provider
/// 管理声纹详情页面的状态，包括音频播放、保存、删除等
class MPVoiceRecognitionDetailProvider with ChangeNotifier {
  // AI-generated START - 声纹ID
  final String? voiceId;
  // AI-generated END - voiceId

  // AI-generated START - 是否正在播放
  bool _isPlaying = false;
  // AI-generated END - _isPlaying

  // AI-generated START - 当前播放时间（秒）
  int _currentTime = 0;
  // AI-generated END - _currentTime

  // AI-generated START - 总时长（秒）
  final int _totalDuration;
  // AI-generated END - _totalDuration

  // AI-generated START - 播放定时器
  Timer? _playTimer;
  // AI-generated END - _playTimer

  // AI-generated START - 是否编辑模式
  bool _isEditMode = false;
  // AI-generated END - _isEditMode

  // AI-generated START - 构造函数
  MPVoiceRecognitionDetailProvider({
    this.voiceId,
    required int audioDuration,
    bool isEditMode = false,
  })  : _totalDuration = audioDuration,
        _isEditMode = isEditMode;
  // AI-generated END - 构造函数

  // AI-generated START - 获取是否正在播放
  bool get isPlaying => _isPlaying;
  // AI-generated END - isPlaying

  // AI-generated START - 获取是否编辑模式
  bool get isEditMode => _isEditMode;
  // AI-generated END - isEditMode

  // AI-generated START - 设置编辑模式
  void setEditMode(bool editMode) {
    _isEditMode = editMode;
    notifyListeners();
  }
  // AI-generated END - setEditMode

  // AI-generated START - 获取当前播放时间
  int get currentTime => _currentTime;
  // AI-generated END - currentTime

  // AI-generated START - 获取总时长
  int get totalDuration => _totalDuration;
  // AI-generated END - totalDuration

  // AI-generated START - 获取播放进度（0.0 - 1.0）
  double get progress {
    if (_totalDuration == 0) return 0.0;
    return _currentTime / _totalDuration;
  }
  // AI-generated END - progress

  // AI-generated START - 播放音频
  void play() {
    if (_isPlaying) return;

    _isPlaying = true;
    notifyListeners();

    // 启动定时器，每秒更新一次播放时间
    _playTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTime < _totalDuration) {
        _currentTime++;
        notifyListeners();
      } else {
        // 播放完成
        pause();
      }
    });

    // TODO: 实现实际的音频播放逻辑
  }
  // AI-generated END - play

  // AI-generated START - 暂停播放
  void pause() {
    if (!_isPlaying) return;

    _isPlaying = false;
    _playTimer?.cancel();
    _playTimer = null;
    notifyListeners();

    // TODO: 实现实际的音频暂停逻辑
  }
  // AI-generated END - pause

  // AI-generated START - 跳转到指定位置
  void seekTo(double progress) {
    final newTime = (progress * _totalDuration).round();
    _currentTime = newTime.clamp(0, _totalDuration);
    notifyListeners();

    // TODO: 实现实际的音频跳转逻辑
  }
  // AI-generated END - seekTo

  // AI-generated START - 保存声纹
  void saveVoice(String name) {
    // TODO: 实现保存声纹的逻辑
    debugPrint('Saving voice: $name, voiceId: $voiceId');
  }
  // AI-generated END - saveVoice

  // AI-generated START - 删除声纹
  void deleteVoice() {
    // TODO: 实现删除声纹的逻辑
    debugPrint('Deleting voice: $voiceId');
  }
  // AI-generated END - deleteVoice

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }
}
// AI-generated END - mp_voice_recognition_detail_provider.dart
