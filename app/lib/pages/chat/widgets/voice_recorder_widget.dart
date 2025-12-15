import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:omi/backend/http/api/messages.dart';
import 'package:omi/services/services.dart';
import 'package:omi/utils/alerts/app_snackbar.dart';
import 'package:omi/utils/file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';

/// 录音状态枚举
/// 定义了录音过程中的各种状态
enum RecordingState {
  /// 未录音状态
  notRecording,
  
  /// 正在录音状态
  recording,
  
  /// 正在转录状态
  transcribing,
  
  /// 转录成功状态
  transcribeSuccess,
  
  /// 转录失败状态
  transcribeFailed,
}

class VoiceRecorderWidget extends StatefulWidget {
  /// 转录完成回调函数
  /// 当语音转录完成后调用，参数为转录的文本
  final Function(String) onTranscriptReady;
  
  /// 关闭回调函数
  /// 当用户关闭录音控件时调用
  final VoidCallback onClose;

  const VoiceRecorderWidget({
    super.key,
    required this.onTranscriptReady,
    required this.onClose,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> with SingleTickerProviderStateMixin {
  /// 当前录音状态
  RecordingState _state = RecordingState.recording;
  
  /// 存储音频数据块的列表
  List<List<int>> _audioChunks = [];
  
  /// 存储转录文本
  String _transcript = '';
  
  /// 是否正在处理音频数据
  bool _isProcessing = false;

  // Audio visualization
  /// 音频可视化级别数组
  final List<double> _audioLevels = List.generate(20, (_) => 0.1);
  
  /// 动画控制器，用于音频波形动画
  late AnimationController _animationController;
  
  /// 波形更新定时器
  Timer? _waveformTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Setup timer to update the wave visualization every second
    /// 设置定时器，每秒更新波形可视化
    _waveformTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state == RecordingState.recording && mounted) {
        setState(() {
          // Just trigger a repaint
          /// 仅触发重绘
        });
      }
    });

    _startRecording();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _waveformTimer?.cancel();

    // Make sure to stop recording when widget is disposed
    /// 确保在控件被销毁时停止录音
    if (_state == RecordingState.recording) {
      // Use a synchronous call to stop recording to avoid any async issues
      /// 使用同步调用停止录音以避免异步问题
      ServiceManager.instance().mic.stop();
    }

    super.dispose();
  }

  /// 开始录音方法
  /// 请求麦克风权限并启动录音服务
  Future<void> _startRecording() async {
    await Permission.microphone.request();

    await ServiceManager.instance().mic.start(onByteReceived: (bytes) {
      if (_state == RecordingState.recording && mounted) {
        // Check if widget is still mounted before calling setState
        /// 在调用setState之前检查控件是否仍然挂载
        if (mounted) {
          setState(() {
            _audioChunks.add(bytes.toList());

            // Update audio visualization based on actual audio levels
            /// 根据实际音频级别更新音频可视化
            if (bytes.isNotEmpty) {
              // Calculate RMS (Root Mean Square) for PCM16 audio data
              /// 计算PCM16音频数据的RMS（均方根）
              double rms = 0;

              // Process bytes as 16-bit samples (2 bytes per sample)
              /// 将字节作为16位样本处理（每个样本2个字节）
              for (int i = 0; i < bytes.length - 1; i += 2) {
                // Convert two bytes to a 16-bit signed integer
                // PCM16 is little-endian: LSB first, then MSB
                /// 将两个字节转换为16位有符号整数
                /// PCM16是小端序：最低有效字节在前，最高有效字节在后
                int sample = bytes[i] | (bytes[i + 1] << 8);

                // Convert to signed value (if high bit is set)
                /// 转换为有符号值（如果高位被设置）
                if (sample > 32767) {
                  sample = sample - 65536;
                }

                // Square the sample and add to sum
                /// 对样本进行平方并加到总和中
                rms += sample * sample;
              }

              // Calculate RMS and normalize to 0.0-1.0 range
              // 32768 is max absolute value for 16-bit audio
              /// 计算RMS并归一化到0.0-1.0范围
              /// 32768是16位音频的最大绝对值
              int sampleCount = bytes.length ~/ 2;
              if (sampleCount > 0) {
                rms = math.sqrt(rms / sampleCount) / 32768.0;
              } else {
                rms = 0;
              }

              // Apply non-linear scaling to make quiet sounds more visible
              // and loud sounds more dramatic
              /// 应用非线性缩放使安静的声音更可见，响亮的声音更戏剧化
              final level = math.pow(rms, 0.4).toDouble().clamp(0.1, 1.0);

              // Shift all values left
              /// 将所有值向左移动
              for (int i = 0; i < _audioLevels.length - 1; i++) {
                _audioLevels[i] = _audioLevels[i + 1];
              }

              // Add new level at the end
              /// 在末尾添加新级别
              _audioLevels[_audioLevels.length - 1] = level;

              // We don't force setState here anymore - the timer will handle updates
              /// 我们不再在这里强制调用setState - 定时器将处理更新
            }
          });
        }
      }
    }, onRecording: () {
      debugPrint('Recording started');
      setState(() {
        _state = RecordingState.recording;
        _audioChunks = [];
        // Reset audio levels
        /// 重置音频级别
        for (int i = 0; i < _audioLevels.length; i++) {
          _audioLevels[i] = 0.1;
        }
      });
    }, onStop: () {
      debugPrint('Recording stopped');
    }, onInitializing: () {
      debugPrint('Initializing');
    });
  }

  /// 停止录音方法
  /// 取消波形定时器并停止录音服务
  Future<void> _stopRecording() async {
    _waveformTimer?.cancel();
    ServiceManager.instance().mic.stop();
  }

  /// 处理录音数据方法
  /// 停止录音并将音频数据转换为WAV文件进行转录
  Future<void> _processRecording() async {
    if (_audioChunks.isEmpty) {
      widget.onClose();
      return;
    }

    setState(() {
      _state = RecordingState.transcribing;
      _isProcessing = true;
    });

    await _stopRecording();

    // Flatten audio chunks into a single list
    /// 将音频块展平为单个列表
    List<int> flattenedBytes = [];
    for (var chunk in _audioChunks) {
      flattenedBytes.addAll(chunk);
    }

    // Convert PCM to WAV file
    /// 将PCM转换为WAV文件
    final audioFile = await FileUtils.convertPcmToWavFile(
      Uint8List.fromList(flattenedBytes),
      16000, // Sample rate
      1, // Mono channel
    );

    try {
      final transcript = await transcribeVoiceMessage(audioFile);
      if (mounted) {
        setState(() {
          _transcript = transcript;
          _state = RecordingState.transcribeSuccess;
          _isProcessing = false;
        });
        if (transcript.isNotEmpty) {
          widget.onTranscriptReady(transcript);
        }
      }
    } catch (e) {
      debugPrint('Error processing recording: $e');
      if (mounted) {
        setState(() {
          _state = RecordingState.transcribeFailed;
          _isProcessing = false;
        });
      }
      AppSnackbar.showSnackbarError('Failed to transcribe audio');
    }
  }

  /// 重试方法
  /// 如果没有音频数据则重新开始录音，否则重新处理现有音频数据
  void _retry() {
    if (_audioChunks.isEmpty) {
      _startRecording();
    } else {
      // Retry transcription with existing audio data
      /// 使用现有音频数据重试转录
      _processRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case RecordingState.recording:
        /// 正在录音状态UI
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Material(
                type: MaterialType.transparency,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: CustomPaint(
                    painter: AudioWavePainter(
                      levels: _audioLevels,
                      timestamp: DateTime.now(),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _processRecording,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  margin: const EdgeInsets.only(top: 10, bottom: 10, right: 6, left: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.black,
                    size: 20.0,
                  ),
                ),
              ),
            ],
          ),
        );

      case RecordingState.transcribing:
        /// 正在转录状态UI
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Shimmer.fromColors(
                baseColor: const Color(0xFF35343B),
                highlightColor: Colors.white,
                child: const Text(
                  'Transcribing...',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );

      case RecordingState.transcribeSuccess:
        /// 转录成功状态UI
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _transcript,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Material(
                  type: MaterialType.transparency,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onClose,
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => widget.onTranscriptReady(_transcript),
                  ),
                ),
              ],
            ),
          ],
        );

      case RecordingState.transcribeFailed:
        /// 转录失败状态UI
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Error',
                style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: CustomPaint(
                    painter: AudioWavePainter(
                      levels: _audioLevels,
                      timestamp: DateTime.now(),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                      onTap: _retry,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        margin: const EdgeInsets.only(left: 10, right: 0, top: 10, bottom: 10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          color: Colors.black,
                          Icons.refresh,
                          size: 20.0,
                        ),
                      )),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      padding: const EdgeInsets.only(left: 14, right: 0, top: 14, bottom: 14),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      default:
        /// 默认状态UI
        return const SizedBox.shrink();
    }
  }
}

class AudioWavePainter extends CustomPainter {
  /// 音频级别数组
  final List<double> levels;
  
  // Add timestamp to control repaint frequency
  /// 时间戳，用于控制重绘频率
  final DateTime timestamp;

  AudioWavePainter({
    required this.levels,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4 // Slightly thicker for better visibility
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;
    final barWidth = width / levels.length / 2;

    for (int i = 0; i < levels.length; i++) {
      final x = i * (barWidth * 2) + barWidth;

      // Use the level directly for more accurate RMS representation
      /// 直接使用级别以获得更准确的RMS表示
      final level = levels[i];
      final barHeight = level * height * 0.8;

      final topY = height / 2 - barHeight / 2;
      final bottomY = height / 2 + barHeight / 2;

      // Draw only the individual bars with rounded caps
      /// 仅绘制带有圆角的单独条形
      canvas.drawLine(
        Offset(x, topY),
        Offset(x, bottomY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AudioWavePainter oldDelegate) {
    return true;
  }
}
