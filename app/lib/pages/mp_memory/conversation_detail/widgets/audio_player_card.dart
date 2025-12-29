// AI-generated START - 音频播放器卡片组件，显示原始音频播放控件
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// 音频播放器卡片组件
/// 显示原始音频的播放控件，包括播放按钮、进度条和时间显示
class AudioPlayerCard extends StatefulWidget {
  // AI-generated START - 音频标题
  final String? title;
  // AI-generated END - title

  // AI-generated START - 音频总时长（秒）
  final int totalDurationSeconds;
  // AI-generated END - totalDurationSeconds

  // AI-generated START - 音频URL
  final Future<String>? audioUrl;
  // AI-generated END - audioUrl

  const AudioPlayerCard({
    super.key,
    this.title,
    required this.totalDurationSeconds,
    this.audioUrl,
  });

  @override
  State<AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<AudioPlayerCard> {
  // AI-generated START - 音频播放器
  final AudioPlayer _audioPlayer = AudioPlayer();
  // AI-generated END - _audioPlayer

  // AI-generated START - 是否正在播放
  bool _isPlaying = false;
  // AI-generated END - _isPlaying

  // AI-generated START - 当前播放位置（秒）
  int _currentPosition = 0;
  // AI-generated END - _currentPosition

  // AI-generated START - 是否正在缓冲
  bool _isBuffering = false;
  // AI-generated END - _isBuffering

  // AI-generated START - 进度监听订阅
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  // AI-generated END - 订阅

  @override
  void initState() {
    super.initState();
    _setupPlayer();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// 初始化音频播放器
  Future<void> _setupPlayer() async {
    final audioUrl = await widget.audioUrl;
    if (audioUrl == null || audioUrl.isEmpty) {
      return;
    }

    try {
      await _audioPlayer.setUrl(audioUrl);
      _setupPositionTracking();
    } catch (e) {
      debugPrint('初始化音频播放器失败: $e');
    }
  }

  /// 设置播放进度监听
  void _setupPositionTracking() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();

    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position.inSeconds;
        });
      }
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        // 如果传入的 totalDurationSeconds 和实际时长不一致，可以在这里更新
      }
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isBuffering =
              state.processingState == ProcessingState.loading || state.processingState == ProcessingState.buffering;
        });
      }
    });
  }

  /// 播放音频
  Future<void> play() async {
    final audioUrl = await widget.audioUrl;
    if (audioUrl == null || audioUrl.isEmpty) {
      debugPrint('音频URL为空，无法播放');
      return;
    }

    try {
      // 如果播放器还没有设置URL，先设置
      if (_audioPlayer.audioSource == null) {
        await _audioPlayer.setUrl(audioUrl);
        _setupPositionTracking();
      }
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('播放音频失败: $e');
    }
  }

  /// 暂停音频
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('暂停音频失败: $e');
    }
  }

  /// 继续播放音频（从暂停位置继续）
  Future<void> resume() async {
    final audioUrl = await widget.audioUrl;
    if (audioUrl == null || audioUrl.isEmpty) {
      debugPrint('音频URL为空，无法继续播放');
      return;
    }

    try {
      // 如果播放器还没有设置URL，先设置
      if (_audioPlayer.audioSource == null) {
        await _audioPlayer.setUrl(audioUrl);
        _setupPositionTracking();
      }
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('继续播放音频失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalDurationSeconds > 0 ? _currentPosition / widget.totalDurationSeconds : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI-generated START - 标题和时长
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title ?? '原始音频',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatDuration(widget.totalDurationSeconds),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14.0,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          // AI-generated END - 标题和时长

          const SizedBox(height: 16.0),

          // AI-generated START - 播放控件
          Row(
            children: [
              // AI-generated START - 播放按钮
              GestureDetector(
                onTap: _isBuffering
                    ? null
                    : () {
                        if (_isPlaying) {
                          pause();
                        } else {
                          if (_currentPosition > 0) {
                            resume();
                          } else {
                            play();
                          }
                        }
                      },
                child: Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: _isBuffering ? Colors.grey : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: _isBuffering
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 20.0,
                        ),
                ),
              ),
              // AI-generated END - 播放按钮

              const SizedBox(width: 12.0),

              // AI-generated START - 进度条和时间
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI-generated START - 进度条
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                        minHeight: 8.0,
                      ),
                    ),
                    // AI-generated END - 进度条

                    const SizedBox(height: 8.0),

                    // AI-generated START - 时间显示
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(_currentPosition),
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12.0,
                          ),
                        ),
                        Text(
                          _formatTime(widget.totalDurationSeconds),
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                    // AI-generated END - 时间显示
                  ],
                ),
              ),
              // AI-generated END - 进度条和时间
            ],
          ),
          // AI-generated END - 播放控件
        ],
      ),
    );
  }

  // AI-generated START - 格式化时长
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0 && remainingSeconds > 0) {
      return '$minutes分$remainingSeconds秒';
    } else if (minutes > 0) {
      return '$minutes分钟';
    } else {
      return '$remainingSeconds秒';
    }
  }
  // AI-generated END - _formatDuration

  // AI-generated START - 格式化时间（MM:SS格式）
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  // AI-generated END - _formatTime
}
// AI-generated END - audio_player_card.dart
