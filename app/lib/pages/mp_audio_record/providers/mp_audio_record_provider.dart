import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../utils/audio_converter_utils.dart';

/// 音频录制状态
enum MPAudioRecordState {
  /// 未开始
  idle,

  /// 正在录制
  recording,

  /// 已暂停
  paused,
}

/// 音频录制Provider
/// 管理音频录制相关的状态和操作
class MPAudioRecordProvider with ChangeNotifier, WidgetsBindingObserver {
  /// 录制状态
  MPAudioRecordState _state = MPAudioRecordState.idle;

  /// 录制时长（秒）
  int _duration = 0;

  /// 标题
  String _title = '新建音频文件';

  /// 定时器
  Timer? _timer;

  /// FlutterSoundRecorder实例
  FlutterSoundRecorder? _recorder;

  /// 录音文件路径
  String? _audioPath;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 音频转换工具
  final AudioConverterUtils _audioConverter = AudioConverterUtils();

  MPAudioRecordProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// 获取录制状态
  MPAudioRecordState get state => _state;

  /// 获取录制时长（秒）
  int get duration => _duration;

  /// 获取格式化的时长（mm:ss）
  String get formattedDuration {
    final minutes = _duration ~/ 60;
    final seconds = _duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 获取标题
  String get title => _title;

  /// 获取状态文本
  String get statusText {
    switch (_state) {
      case MPAudioRecordState.recording:
        return '正在录音中...';
      case MPAudioRecordState.paused:
        return '录音已暂停';
      case MPAudioRecordState.idle:
        return '';
    }
  }

  /// 更新标题
  void updateTitle(String newTitle) {
    if (_title != newTitle) {
      _title = newTitle;
      notifyListeners();
    }
  }

  /// 初始化录音器
  Future<void> _initializeRecorder() async {
    if (_isInitialized) return;

    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder(isBGService: false);
    _isInitialized = true;
  }

  /// 开始录制
  Future<void> startRecording() async {
    // 请求麦克风权限（与聊天场景保持一致）
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      throw Exception('麦克风权限未授予');
    }

    // 如果已暂停，继续录制
    if (_state == MPAudioRecordState.paused) {
      await _resumeRecording();
      return;
    }

    // 初始化录音器
    await _initializeRecorder();

    // 获取录音文件路径（使用WAV格式，方便后续转换为MP3）
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _audioPath = '${tempDir.path}/recording_$timestamp.wav';

    // 开始录制为WAV格式
    await _recorder!.startRecorder(
      toFile: _audioPath!,
      codec: Codec.pcm16WAV,
      numChannels: 1,
      sampleRate: 44100,
    );

    // 更新状态
    _state = MPAudioRecordState.recording;
    _duration = 0;
    notifyListeners();

    // 启动定时器
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _duration++;
      notifyListeners();
    });
  }

  /// 暂停录制
  Future<void> pauseRecording() async {
    if (_state != MPAudioRecordState.recording) return;

    // flutter_sound不支持pauseRecorder，使用stopRecorder停止录制
    // 但保留状态和文件，以便继续录制
    await _recorder!.stopRecorder();
    _state = MPAudioRecordState.paused;
    _timer?.cancel();
    notifyListeners();
  }

  /// 继续录制
  /// 注意：由于flutter_sound不支持追加录制，继续录制会重新开始
  /// 但保留之前的时长统计
  Future<void> _resumeRecording() async {
    if (_state != MPAudioRecordState.paused) return;

    // 重新开始录制到同一个文件（会覆盖之前的录制）
    // 如果需要保留之前的录制，需要使用文件合并功能
    await _recorder!.startRecorder(
      toFile: _audioPath!,
      codec: Codec.pcm16WAV,
      numChannels: 1,
      sampleRate: 44100,
    );

    _state = MPAudioRecordState.recording;
    notifyListeners();

    // 重新启动定时器（继续累计时长）
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _duration++;
      notifyListeners();
    });
  }

  /// 停止录制
  Future<void> stopRecording() async {
    if (_recorder == null) return;

    await _recorder!.stopRecorder();
    _timer?.cancel();
    _state = MPAudioRecordState.idle;
    notifyListeners();
  }

  /// 取消录制
  Future<void> cancelRecording() async {
    await stopRecording();
    _deleteAudioFile();
    _duration = 0;
    notifyListeners();
  }

  /// 保存录音为MP3
  /// 返回保存的文件路径
  Future<String?> saveAsMp3() async {
    if (_audioPath == null || !File(_audioPath!).existsSync()) {
      throw Exception('录音文件不存在');
    }

    // 停止录制
    await stopRecording();

    // 获取保存目录
    final documentsDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${documentsDir.path}/audio_records');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    // 生成文件名：mp_时间戳_标题.mp3
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // 清理标题中的非法字符
    final safeTitle = _title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final fileName = 'mp_${timestamp}_$safeTitle.mp3';
    final mp3Path = '${audioDir.path}/$fileName';

    // 将WAV文件转换为MP3
    try {
      await _audioConverter.convertWavToMp3(
        wavFilePath: _audioPath!,
        outputPath: mp3Path,
        onProgress: (progress) {
          debugPrint('MP3转换进度: ${(progress * 100).toStringAsFixed(1)}%');
        },
      );
    } catch (e) {
      debugPrint('MP3转换失败: $e');
      // 如果转换失败，删除临时文件并抛出异常
      _deleteAudioFile();
      rethrow;
    }

    // 删除临时WAV文件
    _deleteAudioFile();

    return mp3Path;
  }

  /// 删除录音文件
  void _deleteAudioFile() {
    if (_audioPath != null && File(_audioPath!).existsSync()) {
      File(_audioPath!).deleteSync();
      _audioPath = null;
    }
  }

  /// 应用生命周期变化
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // 应用退到后台，暂停录制
      if (_state == MPAudioRecordState.recording) {
        pauseRecording();
      }
    } else if (state == AppLifecycleState.resumed) {
      // 应用回到前台，可以继续录制（但不自动继续，需要用户点击）
      // 这里不做任何操作，让用户手动点击继续
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _recorder?.closeRecorder();
    _deleteAudioFile();
    super.dispose();
  }
}
