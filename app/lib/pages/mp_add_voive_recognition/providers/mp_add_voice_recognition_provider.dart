// AI-generated START - 录制声纹状态管理Provider
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
  // List<double> get audioLevels => _audioLevels;
  // AI-generated END - audioLevels

  BuildContext? context;

  FlutterSoundRecorder? recorder;

  String? _audioPath;

  // AI-generated START - 开始录音
  Future<void> startRecording() async {
    // 请求麦克风权限
    await Permission.microphone.request();
    _recordingDuration = 0;
    _audioChunks = [];
    // 重置音频可视化级别
    // _audioLevels = List.generate(50, (_) => 0.1);

    // 启动实际录音服务
    _audioPath = await _getAudioFilePath();
    recorder ??= FlutterSoundRecorder();
    await recorder!.openRecorder(isBGService: false);
    await recorder!.startRecorder(
      toFile: _audioPath!,
      codec: Codec.aacADTS,
      bitRate: 8000,
      numChannels: 1,
      sampleRate: 8000,
    );
    // 启动定时器，每秒更新一次
    _isRecording = true;
    notifyListeners();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDuration++;
      notifyListeners();
    });
  }
  // AI-generated END - startRecording

  // AI-generated START - 停止录音
  void stopRecording(BuildContext context) async {
    // 停止录音服务
    if (recorder == null) {
      return;
    }
    this.context = context;
    await recorder!.stopRecorder();
    await recorder!.closeRecorder();
    recorder = null;
    _isRecording = false;
    _stopRecordDeal();
  }
  // AI-generated END - stopRecording

  /// 处理停止录音
  void _stopRecordDeal() async {
    if (context == null) {
      return;
    }
    if (_recordingDuration < 30) {
      _deleteAudioFile();
      Navigator.pop(context!);
      return;
    }
    // final audioFile = await _saveAudioChunksToFile();
    // 跳转详情页面
    Navigator.of(context!).pushReplacement(MaterialPageRoute(
      builder: (context) => MPVoiceRecognitionDetailPage(
        voiceId: null,
        initialName: isMyselfVoice ? '我的声音' : null,
        audioDuration: _recordingDuration.toString(),
        isEditMode: true,
        audioPath: _audioPath,
        isMyselfVoice: isMyselfVoice,
      ),
    ));
  }

  Future<String> _getAudioFilePath() async {
    final tempDir = await getTemporaryDirectory();
    final audioFilePath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
    return audioFilePath;
  }

  void _deleteAudioFile() {
    if (_audioPath != null && File(_audioPath!).existsSync()) {
      File(_audioPath!).delete().catchError((e) {
        debugPrint('删除音频文件时出错: $e');
        return File(_audioPath!);
      });
      _audioPath = null;
    }
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
