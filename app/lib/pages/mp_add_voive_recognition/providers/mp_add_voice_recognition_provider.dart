// AI-generated START - 录制声纹状态管理Provider
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../backend/schema/bt_device/bt_device.dart';
import '../../../services/services.dart';
import '../../../utils/audio/wav_bytes.dart';
import '../../mp_voice_congnition_detail/mp_voice_recognition_detail_page.dart';

/// 录制声纹状态管理Provider
/// 管理声纹录制相关的状态
class MPAddVoiceRecognitionProvider with ChangeNotifier {
  // AI-generated START - 是否是自己的声音
  final bool isMyselfVoice;
  // AI-generated END - isMyselfVoice

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
  static const int maxRecordingDuration = 30;
  // AI-generated END - maxRecordingDuration

  // AI-generated START - 录音数据
  List<Uint8List> _audioChunks = [];
  // AI-generated END - _audioChunks

  // AI-generated START - 音频可视化级别
  List<double> _audioLevels = List.generate(50, (_) => 0.1);
  // AI-generated END - _audioLevels

  // AI-generated START - 构造函数
  MPAddVoiceRecognitionProvider({
    this.isMyselfVoice = false,
  });
  // AI-generated END - 构造函数

  // AI-generated START - 获取是否正在录音
  bool get isRecording => _isRecording;
  // AI-generated END - isRecording

  // AI-generated START - 获取录音时长
  int get recordingDuration => _recordingDuration;
  // AI-generated END - recordingDuration

  // AI-generated START - 获取音频数据
  List<Uint8List> get audioChunks => _audioChunks;
  // AI-generated END - audioChunks

  // AI-generated START - 获取音频可视化级别
  List<double> get audioLevels => _audioLevels;
  // AI-generated END - audioLevels

  BuildContext? context;

  // AI-generated START - 开始录音
  Future<void> startRecording() async {
    // 请求麦克风权限
    await Permission.microphone.request();

    _recordingDuration = 0;
    _audioChunks = [];
    // 重置音频可视化级别
    _audioLevels = List.generate(50, (_) => 0.1);
    notifyListeners();

    // 启动定时器，每秒更新一次
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // if (_recordingDuration < maxRecordingDuration) {
      //   _recordingDuration++;
      //   notifyListeners();
      // } else {
      //   // 达到最大时长，自动停止
      //   stopRecording();
      // }
      _recordingDuration++;
      notifyListeners();
    });

    // 启动实际录音服务
    await ServiceManager.instance().mic.start(
      onByteReceived: (bytes) {
        if (_isRecording) {
          _audioChunks.add(bytes);
          debugPrint('-------hjj Recording ${bytes.length} bytes');

          // // 根据实际音频级别更新音频可视化
          // if (bytes.isNotEmpty) {
          //   // 计算PCM16音频数据的RMS（均方根）
          //   double rms = 0;

          //   // 将字节作为16位样本处理（每个样本2个字节）
          //   for (int i = 0; i < bytes.length - 1; i += 2) {
          //     // 将两个字节转换为16位有符号整数
          //     // PCM16是小端序：最低有效字节在前，最高有效字节在后
          //     int sample = bytes[i] | (bytes[i + 1] << 8);

          //     // 转换为有符号值（如果高位被设置）
          //     if (sample > 32767) {
          //       sample = sample - 65536;
          //     }

          //     // 对样本进行平方并加到总和中
          //     rms += sample * sample;
          //   }

          //   // 计算RMS并归一化到0.0-1.0范围
          //   // 32768是16位音频的最大绝对值
          //   int sampleCount = bytes.length ~/ 2;
          //   if (sampleCount > 0) {
          //     rms = sqrt(rms / sampleCount) / 32768.0;
          //   } else {
          //     rms = 0;
          //   }

          //   // 应用非线性缩放使安静的声音更可见，响亮的声音更戏剧化
          //   final level = pow(rms, 0.4).toDouble().clamp(0.1, 1.0);

          //   // 将所有值向左移动
          //   for (int i = 0; i < _audioLevels.length - 1; i++) {
          //     _audioLevels[i] = _audioLevels[i + 1];
          //   }

          //   // 在末尾添加新级别
          //   _audioLevels[_audioLevels.length - 1] = level;

          //   notifyListeners();
          // }
        }
      },
      onRecording: () {
        debugPrint('-------hjj Recording started');
        _isRecording = true;
        notifyListeners();
      },
      onStop: () {
        debugPrint('-------hjj Recording stopped');
        _isRecording = false;
        _recordingTimer?.cancel();
        _recordingTimer = null;
        // notifyListeners();
        _stopRecordDeal();
      },
      onInitializing: () {
        debugPrint('-------hjj Initializing');
      },
    );
  }
  // AI-generated END - startRecording

  // AI-generated START - 停止录音
  void stopRecording(BuildContext context) {
    // 停止录音服务
    ServiceManager.instance().mic.stop();

    this.context = context;
  }
  // AI-generated END - stopRecording

  /// 处理停止录音
  void _stopRecordDeal() async {
    if (context == null) {
      return;
    }
    if (_recordingDuration < 30) {
      Navigator.pop(context!);
      return;
    }
    final audioFile = await _saveAudioChunksToFile();
    // 跳转详情页面
    Navigator.of(context!).pushReplacement(MaterialPageRoute(
      builder: (context) => MPVoiceRecognitionDetailPage(
        voiceId: null,
        initialName: null,
        audioDuration: _recordingDuration,
        isEditMode: true,
        audioFile: audioFile,
        isMyselfVoice: isMyselfVoice,
      ),
    ));
  }

  /// 保存音频块到文件
  Future<File> _saveAudioChunksToFile() async {
    final tempDir = await getTemporaryDirectory();
    final wavFilePath = '${tempDir.path}/temp_recording.wav';

    // 将 List<Uint8List> 转换为 List<List<int>>
    List<List<int>> frames = _audioChunks.map((chunk) => chunk.toList()).toList();

    // 创建 WavBytesUtil 实例处理 PCM 数据
    WavBytesUtil wavUtil = WavBytesUtil(codec: BleAudioCodec.pcm16, framesPerSecond: 100);

    // 获取正确的 PCM 样本并转换为 WAV 字节
    Int16List samples = wavUtil.getPcmSamples(frames);
    Uint8List wavBytes = WavBytesUtil.getUInt8ListBytes(samples, 16000);

    await File(wavFilePath).writeAsBytes(wavBytes);
    return File(wavFilePath);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    super.dispose();
  }
}
// AI-generated END - mp_add_voice_recognition_provider.dart
// AI-generated END - mp_add_voice_recognition_provider.dart
