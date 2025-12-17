// AI-generated START - 声纹详情状态管理Provider
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:omi/backend/http/mp_api/mp_speaker.dart';
import 'package:omi/pages/mp_custom_utils/mp_toast_utils.dart';

import '../../../backend/schema/mp/mp_speaker.dart';
import '../../../services/mp_audio_upload.dart';

/// 声纹详情状态管理Provider
/// 管理声纹详情页面的状态，包括音频播放、保存、删除等
class MPVoiceRecognitionDetailProvider with ChangeNotifier {
  // AI-generated START - 声纹ID
  final String? voiceId;
  // AI-generated END - voiceId

  // AI-generated START - 是否是自己的声音
  final bool isMyselfVoice;
  // AI-generated END - isMyselfVoice

  // AI-generated START - 是否正在播放
  bool _isPlaying = false;
  // AI-generated END - _isPlaying

  // AI-generated START - 当前播放时间（秒）
  int _currentTime = 0;
  // AI-generated END - _currentTime

  // AI-generated START - 总时长（秒）
  final int _totalDuration;
  // AI-generated END - _totalDuration

  // // AI-generated START - 播放定时器
  // Timer? _playTimer;
  // // AI-generated END - _playTimer

  // AI-generated START - 是否编辑模式
  bool _isEditMode = false;
  // AI-generated END - _isEditMode

  // AI-generated START - 音频块数据
  File? audioFile;
  // AI-generated END - audioFile

  // AI-generated START - 音频播放器
  FlutterSoundPlayer? _audioPlayer;
  // AI-generated END - _audioPlayer

  // AI-generated START - 构造函数
  MPVoiceRecognitionDetailProvider({
    this.voiceId,
    required int audioDuration,
    this.audioFile,
    bool isEditMode = false,
    this.isMyselfVoice = false,
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
  Future<void> play() async {
    if (_isPlaying) return;

    _isPlaying = true;
    notifyListeners();

    if (audioFile != null) {
      await _playAudioFile(); // 确保等待播放完成
    } else {
      debugPrint('play() 被调用但 audioFile 为空');
      pause();
    }
  }
  // AI-generated END - play

  // 是否有音频文件加载
  bool get isAudioFileLoaded => audioFile != null;

  Future<void> _playAudioFile() async {
    try {
      // 初始化播放器并播放
      _audioPlayer ??= FlutterSoundPlayer();
      debugPrint('播放音频文件: ${audioFile?.path}');

      // 验证文件是否存在
      if (audioFile == null) {
        debugPrint('音频文件为空');
        pause();
        return;
      }

      if (!await audioFile!.exists()) {
        debugPrint('音频文件不存在: ${audioFile?.path}');
        pause();
        return;
      }

      // 检查路径格式并转换为URI
      final path = audioFile?.path ?? '';
      debugPrint('音频文件路径: $path');
      debugPrint('文件大小: ${await audioFile!.length()} bytes');

      // 转换为URI格式
      final uri = Uri.file(path).toString();
      debugPrint('转换后的音频URI: $uri');

      // 确保播放器已打开
      if (!_audioPlayer!.isOpen()) {
        await _audioPlayer!.openPlayer();
        debugPrint('播放器打开成功');
      } else {
        debugPrint('播放器已经处于打开状态');
      }

      // 停止之前可能正在播放的音频
      if (_audioPlayer!.isPlaying) {
        await _audioPlayer!.stopPlayer();
        debugPrint('停止之前的播放');
      }

      // 开始播放 - 使用更明确的参数
      debugPrint('准备开始播放音频');

      // 对于本地文件，使用startPlayerFromUri可能更可靠
      await _audioPlayer!.startPlayer(
        fromURI: uri,
        whenFinished: () {
          debugPrint('音频播放完成');
          pause();
        },
        codec: Codec.pcm16WAV, // WAV格式文件使用正确的编解码器
      );

      debugPrint('音频播放开始 - startPlayer()调用成功');
      debugPrint('播放器当前状态: 正在播放=${_audioPlayer!.isPlaying}, 已打开=${_audioPlayer!.isOpen}');

      // 监听播放进度
      if (_audioPlayer!.onProgress != null) {
        debugPrint('设置播放进度监听');
        _audioPlayer!.onProgress!.listen((disposition) {
          _currentTime = disposition.position.inSeconds;
          debugPrint('播放进度更新: $_currentTime / ${disposition.duration.inSeconds}');
          notifyListeners();
        });
      } else {
        debugPrint('onProgress 流为 null');
      }
    } catch (e, stackTrace) {
      debugPrint('播放音频时出错: $e');
      debugPrint('错误类型: ${e.runtimeType}');
      debugPrint('错误堆栈: $stackTrace');

      // 尝试重置播放器
      try {
        if (_audioPlayer != null) {
          await _audioPlayer!.stopPlayer();
          await _audioPlayer!.closePlayer();
          _audioPlayer = null;
        }
      } catch (resetError) {
        debugPrint('重置播放器时出错: $resetError');
      }

      pause();
    }
  }

  // AI-generated START - 暂停播放
  Future<void> pause() async {
    if (!_isPlaying) return;

    _isPlaying = false;
    // _playTimer?.cancel();
    // _playTimer = null;

    try {
      if (_audioPlayer != null && _audioPlayer!.isPlaying) {
        await _audioPlayer!.pausePlayer();
      }
    } catch (e) {
      debugPrint('暂停音频时出错: $e');
    }

    notifyListeners();
  }
  // AI-generated END - pause

  // AI-generated START - 跳转到指定位置
  Future<void> seekTo(double progress) async {
    final newTime = (progress * _totalDuration).round();
    _currentTime = newTime.clamp(0, _totalDuration);
    notifyListeners();

    try {
      if (_audioPlayer != null && _audioPlayer!.isPlaying) {
        await _audioPlayer!.seekToPlayer(Duration(seconds: _currentTime));
      }
    } catch (e) {
      debugPrint('跳转音频时出错: $e');
    }
  }
  // AI-generated END - seekTo

  // AI-generated START - 保存声纹
  void saveVoice(String name, VoidCallback? successCallback) async {
    if (name.isEmpty) {
      debugPrint('保存声纹失败，姓名为空');
      MPToastUtils.showMessage('请输入姓名');
      return;
    }
    debugPrint('Saving voice: $name, voiceId: $voiceId');
    if (audioFile == null) {
      debugPrint('保存声纹失败，音频文件为空');
      return;
    }
    final uri = await MPAudioUploadService().uploadMPAudio(audioFile!) ?? '';
    if (uri.isEmpty) {
      debugPrint('保存声纹失败，返回的uri为空');
      return;
    }
    final req = MPAddSpeakerRequest(
      name: name,
      audioUrl: uri,
      avatar: '',
      myselfVoice: isMyselfVoice,
    );

    // await MPVoiceRecognitionService().addSpeaker(req);
    final res = await addSpeaker(req);
    if (res?.baseResp.code == 0) {
      debugPrint('保存声纹成功，声纹ID: ${res?.baseResp.message}');
      successCallback?.call();
      _deleteAudioFile();
    } else {
      MPToastUtils.showMessage('保存声纹失败');
    }
  }
  // AI-generated END - saveVoice

  // AI-generated START - 删除声纹
  void deleteVoice() {
    // TODO: 实现删除声纹的逻辑
    debugPrint('Deleting voice: $voiceId');
  }
  // AI-generated END - deleteVoice

  // 删除audioFile
  void _deleteAudioFile() {
    if (audioFile != null && audioFile!.existsSync()) {
      audioFile!.delete().catchError((e) {
        debugPrint('删除音频文件时出错: $e');
        return audioFile!;
      });
      audioFile = null;
    }
  }

  @override
  void dispose() {
    // _playTimer?.cancel();
    // _playTimer = null;
    // 同步释放资源
    try {
      if (_audioPlayer != null) {
        // 尝试停止和关闭播放器
        _audioPlayer!.stopPlayer().catchError((e) {
          debugPrint('停止播放器时出错: $e');
        });
        _audioPlayer!.closePlayer().catchError((e) {
          debugPrint('关闭播放器时出错: $e');
        });
        _audioPlayer = null;
      }

      // 注意：不要删除audioFile，因为它可能还需要被上传使用
      // 如果需要清理，应该在上传完成后由调用方处理
    } catch (e) {
      debugPrint('释放资源时出错: $e');
    }

    super.dispose();
  }
}
// AI-generated END - mp_voice_recognition_detail_provider.dart
