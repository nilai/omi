// AI-generated START - 声纹详情状态管理Provider
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:omi/backend/http/mp_api/mp_speaker.dart';
import 'package:omi/pages/mp_custom_utils/mp_toast_utils.dart';
import 'package:path_provider/path_provider.dart';

import '../../../backend/schema/mp/mp_speaker.dart';
import '../../../services/mp_audio_upload.dart';
import '../../../utils/audio/wav_bytes.dart';

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
      _playAudioFile();
    }else {

    }

   
  }
  // AI-generated END - play

  // 是否有音频文件加载
  bool get isAudioFileLoaded => audioFile != null;

  Future<void> _playAudioFile() async {
     try {
      // 初始化播放器并播放
      _audioPlayer ??= FlutterSoundPlayer();
      await _audioPlayer!.openPlayer();
      await _audioPlayer!.startPlayer(
        fromURI: audioFile?.path ?? '',
        whenFinished: () {
          pause();
        },
      );

      // 监听播放进度
      _audioPlayer!.onProgress?.listen((disposition) {
        _currentTime = disposition.position.inSeconds;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('播放音频时出错: $e');
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
  void saveVoice(String name) async{
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
    );

    // await MPVoiceRecognitionService().addSpeaker(req);
    final res = await addSpeaker(req);
    if (res?.baseResp.code == 0) {
      debugPrint('保存声纹成功，声纹ID');
    } else {
      debugPrint('保存声纹失败');
    }

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
