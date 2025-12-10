// AI-generated START - 音频播放器卡片组件，显示原始音频播放控件
import 'package:flutter/material.dart';

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
  final String? audioUrl;
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
  // AI-generated START - 是否正在播放
  bool _isPlaying = false;
  // AI-generated END - _isPlaying

  // AI-generated START - 当前播放位置（秒）
  int _currentPosition = 0;
  // AI-generated END - _currentPosition

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalDurationSeconds > 0
        ? _currentPosition / widget.totalDurationSeconds
        : 0.0;

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
                style: TextStyle(
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
                onTap: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                  // TODO: 实现音频播放/暂停逻辑
                },
                child: Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28.0,
                  ),
                ),
              ),
              // AI-generated END - 播放按钮

              const SizedBox(width: 16.0),

              // AI-generated START - 进度条和时间
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI-generated START - 进度条
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2.0),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
                        minHeight: 4.0,
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
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.0,
                          ),
                        ),
                        Text(
                          _formatTime(widget.totalDurationSeconds),
                          style: TextStyle(
                            color: Colors.grey.shade600,
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

