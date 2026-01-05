// AI-generated START - 音频播放器卡片组件，显示原始音频播放控件
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../pages/mp_custom_utils/mp_timestamp_utils.dart';
import '../../../../pages/mp_custom_utils/mp_toast_utils.dart';
import '../../../../services/mp_audio_download.dart';
import '../../../../utils/mp_local_records_util.dart';

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

  // AI-generated START - 是否正在下载
  bool _isDownloading = false;
  // AI-generated END - _isDownloading

  // AI-generated START - 下载进度（0.0 - 1.0）
  double _downloadProgress = 0.0;
  // AI-generated END - _downloadProgress

  // AI-generated START - 是否正在拖拽进度条
  bool _isDragging = false;
  // AI-generated END - _isDragging

  // AI-generated START - 拖拽时的临时位置（秒）
  int _dragPosition = 0;
  // AI-generated END - _dragPosition

  // AI-generated START - 本地文件路径
  String? _localFilePath;
  // AI-generated END - _localFilePath

  // AI-generated START - 是否已初始化
  bool _isInitialized = false;
  // AI-generated END - _isInitialized

  // AI-generated START - 进度监听订阅
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  // AI-generated END - 订阅

  @override
  void initState() {
    print('----hjj----initState: AudioPlayerCard初始化');
    super.initState();
    print('----hjj----initState: 开始检查本地文件');
    _checkLocalFile();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// 检查本地文件是否存在
  Future<void> _checkLocalFile() async {
    print('----hjj----_checkLocalFile: 开始检查本地文件');
    final audioUrl = widget.audioUrl;
    if (audioUrl == null || audioUrl.isEmpty) {
      print('----hjj----_checkLocalFile: audioUrl为空，返回');
      return;
    }
    print('----hjj----_checkLocalFile: audioUrl=$audioUrl');

    // 检查本地记录
    print('----hjj----_checkLocalFile: 开始检查本地记录');
    final localPath = await MPLocalRecordsUtil.instance.getLocalRecordPath(audioUrl);
    print('----hjj----_checkLocalFile: 本地路径=$localPath');
    if (localPath != null && localPath.isNotEmpty) {
      // 检查文件是否真的存在于文件系统
      final file = File(localPath);
      final exists = await file.exists();
      print('----hjj----_checkLocalFile: 文件存在=$exists, 路径=$localPath');
      if (exists) {
        setState(() {
          _localFilePath = localPath;
        });
        print('----hjj----_checkLocalFile: 设置_localFilePath=$localPath，开始初始化播放器');
        await _setupPlayer(localPath, isLocalFile: true);
        return;
      }
    }

    // 本地文件不存在
    print('----hjj----_checkLocalFile: 本地文件不存在，设置_localFilePath=null');
    setState(() {
      _localFilePath = null;
    });
  }

  /// 初始化音频播放器
  Future<void> _setupPlayer(String audioPath, {bool isLocalFile = false}) async {
    print('----hjj----_setupPlayer: 开始初始化播放器, audioPath=$audioPath, isLocalFile=$isLocalFile');
    if (audioPath.isEmpty) {
      print('----hjj----_setupPlayer: audioPath为空，返回');
      return;
    }

    try {
      // 判断是本地文件还是网络URL
      final isNetworkUrl = audioPath.startsWith('http://') || audioPath.startsWith('https://');
      print('----hjj----_setupPlayer: isNetworkUrl=$isNetworkUrl');

      if (isLocalFile || !isNetworkUrl) {
        // 本地文件，使用 Uri.file
        print('----hjj----_setupPlayer: 使用本地文件路径初始化, path=$audioPath');
        await _audioPlayer.setAudioSource(AudioSource.uri(Uri.file(audioPath)));
        print('----hjj----_setupPlayer: 本地文件初始化成功');
      } else {
        // 网络URL，使用 Uri.parse
        print('----hjj----_setupPlayer: 使用网络URL初始化, url=$audioPath');
        await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(audioPath)));
        print('----hjj----_setupPlayer: 网络URL初始化成功');
      }

      _setupPositionTracking();
      setState(() {
        _isInitialized = true;
      });
      print('----hjj----_setupPlayer: 播放器初始化完成, _isInitialized=true');
    } catch (e) {
      print('----hjj----_setupPlayer: 初始化音频播放器失败: $e');
      debugPrint('初始化音频播放器失败: $e');
    }
  }

  /// 设置播放进度监听
  void _setupPositionTracking() {
    print('----hjj----_setupPositionTracking: 开始设置播放进度监听');
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();

    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (mounted && !_isDragging) {
        setState(() {
          _currentPosition = position.inSeconds;
        });
      }
    });
    print('----hjj----_setupPositionTracking: 位置监听已设置');

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        print('----hjj----_setupPositionTracking: 时长更新=$duration');
        // 如果传入的 totalDurationSeconds 和实际时长不一致，可以在这里更新
      }
    });
    print('----hjj----_setupPositionTracking: 时长监听已设置');

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        print(
            '----hjj----_setupPositionTracking: 播放状态更新, playing=${state.playing}, processingState=${state.processingState}');
        setState(() {
          _isPlaying = state.playing;
          _isBuffering =
              state.processingState == ProcessingState.loading || state.processingState == ProcessingState.buffering;

          // 播放完成后重置状态
          if (state.processingState == ProcessingState.completed) {
            print('----hjj----_setupPositionTracking: 播放完成，调用_onPlaybackCompleted');
            _onPlaybackCompleted();
          }
        });
      }
    });
    print('----hjj----_setupPositionTracking: 播放状态监听已设置');
  }

  /// 播放完成回调
  void _onPlaybackCompleted() {
    print('----hjj----_onPlaybackCompleted: 播放完成回调');
    setState(() {
      _isPlaying = false;
      _currentPosition = 0;
      _dragPosition = 0;
    });
    // 重置播放位置
    _audioPlayer.seek(Duration.zero);
    _audioPlayer.stop();
    print('----hjj----_onPlaybackCompleted: 播放位置已重置');
  }

  /// 处理播放按钮点击
  Future<void> _handlePlayButtonTap() async {
    print('----hjj----_handlePlayButtonTap: 播放按钮被点击');
    final audioUrl = widget.audioUrl;
    if (audioUrl == null || audioUrl.isEmpty) {
      print('----hjj----_handlePlayButtonTap: audioUrl为空');
      MPToastUtils.showMessage('音频文件链接出错');
      return;
    }
    print('----hjj----_handlePlayButtonTap: audioUrl=$audioUrl');

    // 如果正在下载，不处理
    if (_isDownloading) {
      print('----hjj----_handlePlayButtonTap: 正在下载中，返回');
      return;
    }

    // 如果正在播放，则暂停
    if (_isPlaying) {
      print('----hjj----_handlePlayButtonTap: 正在播放，执行暂停');
      await pause();
      return;
    }

    // 检查本地文件是否存在
    print('----hjj----_handlePlayButtonTap: _localFilePath=$_localFilePath');
    if (_localFilePath == null) {
      // 本地文件不存在，开始下载
      print('----hjj----_handlePlayButtonTap: 本地文件不存在，开始下载');
      await _downloadAudio(audioUrl);
      return;
    }

    // 本地文件存在，开始播放
    print('----hjj----_handlePlayButtonTap: 本地文件存在，开始播放');
    await _startPlayback();
  }

  /// 下载音频文件
  Future<void> _downloadAudio(String audioUrl) async {
    print('----hjj----_downloadAudio: 开始下载音频, audioUrl=$audioUrl');
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      print('----hjj----_downloadAudio: 调用MPAudioDownloadService下载');
      final result = await MPAudioDownloadService.instance.downloadAndSaveAudio(
        audioUrl,
        onProgress: (downloaded, total) {
          if (mounted && total != null && total > 0) {
            setState(() {
              _downloadProgress = downloaded / total;
            });
          }
        },
      );
      print('----hjj----_downloadAudio: 下载完成, result=$result');

      if (result != null && mounted) {
        print('----hjj----_downloadAudio: 下载成功, path=${result.path}, fileName=${result.fileName}');
        // 保存到本地记录
        print('----hjj----_downloadAudio: 保存到本地记录');
        await MPLocalRecordsUtil.instance.addLocalRecord(
          result.path,
          createAt: MPTimestampUtils.timestampNow,
          fileName: result.fileName,
          source: '',
          isRemoved: true,
        );
        print('----hjj----_downloadAudio: 本地记录保存完成');

        setState(() {
          _localFilePath = result.path;
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
        print('----hjj----_downloadAudio: 设置_localFilePath=${result.path}');

        // 下载完成后初始化播放器并开始播放
        print('----hjj----_downloadAudio: 开始初始化播放器，使用本地路径=${result.path}');
        await _setupPlayer(result.path, isLocalFile: true);
        print('----hjj----_downloadAudio: 播放器初始化完成，开始播放');
        await _startPlayback();
        print('----hjj----_downloadAudio: 播放开始');
      } else {
        print('----hjj----_downloadAudio: 下载失败，result为null');
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _downloadProgress = 0.0;
          });
          MPToastUtils.showMessage('下载失败');
        }
      }
    } catch (e) {
      print('----hjj----_downloadAudio: 下载异常: $e');
      debugPrint('下载音频失败: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
        MPToastUtils.showMessage('下载失败: $e');
      }
    }
  }

  /// 开始播放
  Future<void> _startPlayback() async {
    print('----hjj----_startPlayback: 开始播放');
    print('----hjj----_startPlayback: _localFilePath=$_localFilePath');
    print('----hjj----_startPlayback: _isInitialized=$_isInitialized');

    if (_localFilePath == null || _localFilePath!.isEmpty) {
      print('----hjj----_startPlayback: 本地文件路径为空，返回');
      MPToastUtils.showMessage('音频文件不存在');
      return;
    }

    try {
      // 如果播放器还没有初始化，先初始化
      if (!_isInitialized) {
        print('----hjj----_startPlayback: 播放器未初始化，开始初始化');
        await _setupPlayer(_localFilePath!, isLocalFile: true);
        print('----hjj----_startPlayback: 播放器初始化完成');
      }

      // 如果当前有播放位置，从该位置继续播放；否则从头开始
      print('----hjj----_startPlayback: _currentPosition=$_currentPosition');
      if (_currentPosition > 0) {
        print('----hjj----_startPlayback: 从位置$_currentPosition秒开始播放');
        await _audioPlayer.seek(Duration(seconds: _currentPosition));
      } else {
        print('----hjj----_startPlayback: 从头开始播放');
        await _audioPlayer.seek(Duration.zero);
      }

      print('----hjj----_startPlayback: 调用play()方法');
      await _audioPlayer.play();
      print('----hjj----_startPlayback: play()调用成功');
    } catch (e) {
      print('----hjj----_startPlayback: 播放失败: $e');
      debugPrint('播放音频失败: $e');
      MPToastUtils.showMessage('播放失败: $e');
    }
  }

  /// 暂停音频
  Future<void> pause() async {
    print('----hjj----pause: 开始暂停');
    try {
      await _audioPlayer.pause();
      print('----hjj----pause: 暂停成功');
    } catch (e) {
      print('----hjj----pause: 暂停失败: $e');
      debugPrint('暂停音频失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 计算进度值（如果正在拖拽，使用拖拽位置；否则使用当前播放位置）
    final displayPosition = _isDragging ? _dragPosition : _currentPosition;
    final progress =
        widget.totalDurationSeconds > 0 ? (displayPosition / widget.totalDurationSeconds).clamp(0.0, 1.0) : 0.0;

    // 确定按钮状态和图标
    IconData buttonIcon;
    Color buttonColor;
    Widget? buttonContent;

    if (_isDownloading) {
      // 下载中状态
      buttonIcon = Icons.download;
      buttonColor = Colors.orange;
      buttonContent = Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: _downloadProgress,
            strokeWidth: 2.0,
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
          ),
          if (_downloadProgress > 0)
            Text(
              '${(_downloadProgress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      );
    } else if (_isBuffering) {
      // 缓冲中状态
      buttonIcon = Icons.play_arrow;
      buttonColor = Colors.grey;
      buttonContent = const Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          color: Colors.white,
        ),
      );
    } else if (_isPlaying) {
      // 播放中状态
      buttonIcon = Icons.pause;
      buttonColor = Colors.blue;
      buttonContent = null;
    } else {
      // 未播放状态
      buttonIcon = Icons.play_arrow;
      buttonColor = Colors.blue;
      buttonContent = null;
    }

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
                onTap: (_isDownloading || _isBuffering) ? null : _handlePlayButtonTap,
                child: Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: buttonColor,
                    shape: BoxShape.circle,
                  ),
                  child: buttonContent ??
                      Icon(
                        buttonIcon,
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
                    // AI-generated START - 可拖拽进度条
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 8.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                        activeTrackColor: const Color(0xFF2563EB),
                        inactiveTrackColor: const Color(0xFFE5E7EB),
                        thumbColor: const Color(0xFF2563EB),
                      ),
                      child: Slider(
                        value: progress,
                        min: 0.0,
                        max: 1.0,
                        onChangeStart: (value) {
                          // 拖拽开始：暂停位置更新
                          print(
                              '----hjj----Slider onChangeStart: 开始拖拽, value=$value, _currentPosition=$_currentPosition');
                          setState(() {
                            _isDragging = true;
                            _dragPosition = _currentPosition;
                          });
                        },
                        onChanged: (value) {
                          // 拖拽中：更新拖拽位置
                          if (widget.totalDurationSeconds > 0) {
                            final dragPos = (widget.totalDurationSeconds * value).round();
                            print('----hjj----Slider onChanged: 拖拽中, value=$value, dragPosition=$dragPos');
                            setState(() {
                              _dragPosition = dragPos;
                            });
                          }
                        },
                        onChangeEnd: (value) async {
                          // 拖拽结束：跳转到新位置
                          print('----hjj----Slider onChangeEnd: 拖拽结束, value=$value');
                          if (widget.totalDurationSeconds > 0) {
                            final newPosition = (widget.totalDurationSeconds * value).round();
                            print('----hjj----Slider onChangeEnd: 跳转到位置=$newPosition秒');
                            try {
                              await _audioPlayer.seek(Duration(seconds: newPosition));
                              print('----hjj----Slider onChangeEnd: 跳转成功');
                              setState(() {
                                _currentPosition = newPosition;
                                _dragPosition = newPosition;
                                _isDragging = false;
                              });
                            } catch (e) {
                              print('----hjj----Slider onChangeEnd: 跳转失败: $e');
                              debugPrint('跳转播放位置失败: $e');
                              setState(() {
                                _isDragging = false;
                              });
                            }
                          } else {
                            print('----hjj----Slider onChangeEnd: totalDurationSeconds为0，无法跳转');
                            setState(() {
                              _isDragging = false;
                            });
                          }
                        },
                      ),
                    ),
                    // AI-generated END - 可拖拽进度条

                    const SizedBox(height: 8.0),

                    // AI-generated START - 时间显示
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(displayPosition),
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
