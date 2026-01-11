// AI-generated START - 声纹详情状态管理Provider
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:omi/backend/http/mp_api/mp_speaker.dart';
import 'package:omi/pages/mp_custom_utils/mp_toast_utils.dart';

import '../../../backend/schema/mp/mp_speaker.dart';
import '../../../services/mp_audio_download.dart';
import '../../../services/mp_audio_upload.dart';
import '../../../utils/mp_local_records_util.dart';

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

  // AI-generated START - 是否正在下载
  bool _isDownloading = false;
  // AI-generated END - _isDownloading

  // AI-generated START - 当前播放时间（秒）
  int _currentTime = 0;
  // AI-generated END - _currentTime

  // AI-generated START - 总时长（秒）
  int _totalDuration;
  // AI-generated END - _totalDuration

  // // AI-generated START - 播放定时器
  // Timer? _playTimer;
  // // AI-generated END - _playTimer

  // AI-generated START - 是否编辑模式
  bool _isEditMode = false;
  // AI-generated END - _isEditMode

  // AI-generated START - 音频块数据
  String? audioPath;
  // AI-generated END - audioFile

  // AI-generated START - 头像图片路径
  File? _avatarImage;
  String? _avatarUrl;
  // AI-generated END - _avatarImage

  // AI-generated START - 音频播放器
  FlutterSoundPlayer? _audioPlayer;
  // AI-generated END - _audioPlayer

  // AI-generated START - 播放进度订阅
  StreamSubscription<PlaybackDisposition>? _progressSubscription;
  // AI-generated END - _progressSubscription

  // AI-generated START - 播放进度定时器（用于主动更新进度）
  Timer? _progressTimer;
  // AI-generated END - _progressTimer

  // AI-generated START - 播放开始时间
  DateTime? _playStartTime;
  int _playStartPosition = 0;
  // AI-generated END - 播放开始时间

  // AI-generated START - 构造函数
  MPVoiceRecognitionDetailProvider({
    this.voiceId,
    required int audioDuration,
    this.audioPath,
    bool isEditMode = false,
    this.isMyselfVoice = false,
    String? avatarUrl,
  })  : _totalDuration = audioDuration,
        _isEditMode = isEditMode,
        _avatarUrl = avatarUrl {
    // 如果 audioDuration 为 0 且 audioPath 存在，尝试从 audioPath 获取时长
    // if (_totalDuration == 0 && audioPath != null && audioPath!.isNotEmpty) {
    //   // 异步初始化时长，不阻塞构造函数
    //   initializeDurationFromPath();
    // }
  }
  // AI-generated END - 构造函数

  // AI-generated START - 获取是否正在播放
  bool get isPlaying => _isPlaying;
  // AI-generated END - isPlaying

  // AI-generated START - 获取是否正在下载
  bool get isDownloading => _isDownloading;
  // AI-generated END - isDownloading

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

  // AI-generated START - 从 audioPath 获取音频时长
  /// 从 audioPath 获取音频时长
  /// 通过播放器的 onProgress 流获取时长
  /// 如果 audioPath 为空或获取失败，返回 null
  Future<int?> getAudioDurationFromPath() async {
    if (audioPath == null || audioPath!.isEmpty) {
      debugPrint('audioPath 为空，无法获取时长');
      return null;
    }

    try {
      // 确保播放器已初始化
      await _ensurePlayerInitialized();
      if (_audioPlayer == null) {
        debugPrint('播放器初始化失败，无法获取时长');
        return null;
      }

      // 对于本地文件，检查文件是否存在
      if (!audioPath!.contains('http')) {
        if (!await _fileExists(audioPath!)) {
          debugPrint('音频文件不存在: $audioPath');
          return null;
        }
      }

      // 使用一个临时的进度监听来获取时长
      // 注意：需要先开始播放才能获取准确的时长
      // 这里我们尝试获取进度信息
      Completer<int?> completer = Completer<int?>();
      StreamSubscription<PlaybackDisposition>? tempSubscription;

      // 设置临时监听，获取时长后立即取消
      tempSubscription = _audioPlayer?.onProgress?.listen((disposition) {
        final duration = disposition.duration.inSeconds;
        if (duration > 0 && !completer.isCompleted) {
          tempSubscription?.cancel();
          completer.complete(duration);
        }
      });

      // 尝试开始播放以获取时长（静音播放）
      try {
        if (audioPath!.contains('http')) {
          await _audioPlayer!.startPlayer(
            fromURI: audioPath!,
            codec: Codec.mp3,
            sampleRate: 44100,
          );
        } else {
          await _audioPlayer!.startPlayer(
            fromURI: audioPath!,
            codec: Codec.aacADTS,
            sampleRate: 8000,
          );
        }

        // 等待获取时长（最多等待 3 秒）
        final duration = await completer.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            tempSubscription?.cancel();
            return null;
          },
        );

        // 停止播放
        await _audioPlayer!.stopPlayer();

        if (duration != null && duration > 0) {
          debugPrint('从 audioPath 获取到时长: $duration 秒');
          return duration;
        }
      } catch (e) {
        debugPrint('播放音频以获取时长时出错: $e');
        tempSubscription?.cancel();
        await _audioPlayer!.stopPlayer().catchError((_) {});
      }
    } catch (e) {
      debugPrint('获取音频时长失败: $e');
    }

    return null;
  }

  /// 初始化时从 audioPath 获取时长（如果 audioDuration 为 0）
  Future<void> initializeDurationFromPath() async {
    // 如果已经有有效的时长，不需要重新获取
    if (_totalDuration > 0) {
      return;
    }

    // 如果 audioPath 存在，尝试获取时长
    if (audioPath != null && audioPath!.isNotEmpty) {
      final duration = await getAudioDurationFromPath();
      if (duration != null && duration > 0) {
        _totalDuration = duration;
        notifyListeners();
        debugPrint('更新总时长: $_totalDuration 秒');
      }
    }
  }
  // AI-generated END - getAudioDurationFromPath

  // AI-generated START - 获取播放进度（0.0 - 1.0）
  double get progress {
    if (_totalDuration == 0) return 0.0;
    return _currentTime / _totalDuration;
  }
  // AI-generated END - progress

  // AI-generated START - 获取头像图片
  File? get avatarImage => _avatarImage;
  String? get avatarUrl => _avatarUrl;
  // AI-generated END - avatarImage

  // AI-generated START - 选择头像图片
  /// 从相册选择头像图片
  Future<void> pickAvatarImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        _avatarImage = File(image.path);
        _avatarUrl = null; // 清除之前的网络URL
        notifyListeners();
      }
    } catch (e) {
      debugPrint('选择头像图片失败: $e');
      MPToastUtils.showMessage('选择图片失败');
    }
  }
  // AI-generated END - pickAvatarImage

  /// 检查本地是否有对应的音频文件
  /// 如果是网络URL，尝试从本地记录中查找
  Future<String?> _checkLocalFile(String url) async {
    // 如果不是网络URL，直接检查文件是否存在
    if (!url.contains('http')) {
      if (await _fileExists(url)) {
        return url;
      }
      return null;
    }

    // 如果是网络URL，尝试从本地记录中查找
    try {
      final localPath = await MPLocalRecordsUtil.instance.getLocalRecordPath(url);
      if (localPath != null && await _fileExists(localPath)) {
        debugPrint('找到本地文件: $localPath');
        return localPath;
      }
    } catch (e) {
      debugPrint('检查本地文件时出错: $e');
    }

    return null;
  }

  /// 下载音频文件
  Future<String?> _downloadAudio(String url) async {
    _isDownloading = true;
    notifyListeners();

    try {
      debugPrint('开始下载音频: $url');
      final result = await MPAudioDownloadService.instance.downloadAndSaveAudio(
        url,
        onProgress: (downloaded, total) {
          // 可以在这里更新下载进度，如果需要的话
          debugPrint('下载进度: $downloaded / ${total ?? '未知'}');
        },
      );

      if (result != null && await _fileExists(result.path)) {
        debugPrint('下载完成，文件路径: ${result.path}');
        // 更新 audioPath 为本地路径
        audioPath = result.path;
        _isDownloading = false;
        notifyListeners();
        return result.path;
      } else {
        debugPrint('下载失败或文件不存在');
        _isDownloading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      debugPrint('下载音频时出错: $e');
      _isDownloading = false;
      notifyListeners();
      return null;
    }
  }

  // AI-generated START - 播放音频
  Future<void> play() async {
    if (_isPlaying || _isDownloading) return;

    if (audioPath == null) {
      debugPrint('play() 被调用但 audioPath 为空');
      pause();
      return;
    }

    try {
      String? playPath = audioPath;

      // 如果是网络URL，先检查本地是否有文件
      if (audioPath!.contains('http')) {
        final localPath = await _checkLocalFile(audioPath!);
        if (localPath != null) {
          // 本地有文件，直接使用
          playPath = localPath;
          debugPrint('使用本地文件播放: $playPath');
        } else {
          // 本地没有文件，需要下载
          debugPrint('本地没有文件，开始下载');
          playPath = await _downloadAudio(audioPath!);
          if (playPath == null) {
            debugPrint('下载失败，无法播放');
            MPToastUtils.showMessage('下载音频失败');
            return;
          }
        }
      } else {
        // 本地文件，检查是否存在
        if (!await _fileExists(playPath!)) {
          debugPrint('音频文件不存在: $playPath');
          MPToastUtils.showMessage('音频文件不存在');
          return;
        }
      }

      // 开始播放
      _isPlaying = true;
      notifyListeners();

      // 确保播放器已初始化
      await _ensurePlayerInitialized();

      // 重置当前时间
      _currentTime = 0;
      notifyListeners();

      // 取消之前的进度监听
      await _progressSubscription?.cancel();
      _progressSubscription = null;

      // 判断音频格式（下载后的文件都是本地文件，使用本地文件格式）
      // 如果正在播放，先停止
      if (_audioPlayer!.isPlaying) {
        await _audioPlayer!.stopPlayer();
      }

      // 判断是网络URL还是本地文件
      if (playPath.contains('http')) {
        // 直接播放网络音频，使用 MP3 codec
        debugPrint('播放网络音频: $playPath');
        await _audioPlayer!.startPlayer(
          fromURI: playPath,
          codec: Codec.mp3,
          sampleRate: 44100,
          whenFinished: () {
            debugPrint('音频播放完成');
            _onPlaybackFinished();
          },
        );
      } else {
        // 本地文件，使用 AAC ADTS codec
        debugPrint('播放本地音频: $playPath');
        await _audioPlayer!.startPlayer(
          fromURI: playPath,
          codec: Codec.aacADTS,
          sampleRate: 8000,
          whenFinished: () {
            debugPrint('音频播放完成');
            _onPlaybackFinished();
          },
        );
      }

      // 等待一小段时间，确保播放器真正开始播放
      await Future.delayed(const Duration(milliseconds: 200));

      // 检查播放器是否真的在播放
      if (!_audioPlayer!.isPlaying) {
        debugPrint('警告: 播放器启动后未处于播放状态');
        // 即使不在播放状态，也设置监听，因为可能正在缓冲
      }

      // 设置播放进度监听（在播放器开始播放后）
      _setupPositionTracking();

      // 再次触发 UI 更新，确保初始状态正确显示
      notifyListeners();
    } catch (err, stackTrace) {
      debugPrint('播放音频时出错: $err');
      debugPrint('错误堆栈: $stackTrace');
      _isPlaying = false;
      _isDownloading = false;
      notifyListeners();
      MPToastUtils.showMessage('播放音频失败');
    }
  }

  /// 播放完成回调
  void _onPlaybackFinished() {
    _isPlaying = false;
    // 重置到初始状态
    _currentTime = 0;
    notifyListeners();
    debugPrint('播放完成，已重置到初始状态');
  }
  // AI-generated END - play

  /// 结束播放
  Future<void> stopPlayer() async {
    try {
      if (_audioPlayer != null && _audioPlayer!.isPlaying) {
        await _audioPlayer!.stopPlayer();
      }
      cancelPlayerSubscriptions();
      _isPlaying = false;
      notifyListeners();
    } catch (err) {
      debugPrint('停止播放时出错: $err');
    }
  }

  /// 取消播放监听
  void cancelPlayerSubscriptions() {
    _progressSubscription?.cancel();
    _progressSubscription = null;
    _progressTimer?.cancel();
    _progressTimer = null;
    _playStartTime = null;
  }

  /// 获取播放状态
  Future<PlayerState> getPlayState() async {
    if (_audioPlayer == null) {
      return PlayerState.isStopped;
    }
    return await _audioPlayer!.getPlayerState();
  }

  /// 释放播放器
  Future<void> releaseFlauto() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.closePlayer();
      }
    } catch (e) {
      debugPrint('释放播放器时出错: $e');
    }
  }

  /// 判断文件是否存在
  Future<bool> _fileExists(String path) async {
    return await File(path).exists();
  }

  /// 初始化播放器
  /// 确保播放器已创建并打开
  Future<void> _ensurePlayerInitialized() async {
    if (_audioPlayer != null) return;

    _audioPlayer = FlutterSoundPlayer();

    if (_audioPlayer != null && !_audioPlayer!.isOpen()) {
      try {
        await _audioPlayer!.openPlayer();
      } catch (e) {
        debugPrint('_ensurePlayerInitialized: openPlayer 出错: $e');
        rethrow;
      }
    }
  }

  /// 设置播放进度监听
  /// 与 audio_player_utils.dart 的 _setupPositionTracking 保持一致
  void _setupPositionTracking() {
    // 取消之前的监听和定时器
    _progressSubscription?.cancel();
    _progressSubscription = null;
    _progressTimer?.cancel();
    _progressTimer = null;

    // 记录播放开始时间和位置
    _playStartTime = DateTime.now();
    _playStartPosition = _currentTime;

    // 设置 onProgress 流监听（用于获取准确的播放位置和总时长）
    _progressSubscription = _audioPlayer?.onProgress?.listen((disposition) {
      if (_isPlaying) {
        // 从播放器获取准确的播放位置
        final positionSeconds = disposition.position.inSeconds;
        final durationSeconds = disposition.duration.inSeconds;

        // 更新当前时间（使用播放器返回的准确位置）
        _currentTime = positionSeconds;

        // 同步更新播放开始位置和时间
        _playStartPosition = _currentTime;
        _playStartTime = DateTime.now();

        // 如果从播放器获取到的时长与当前不同，更新总时长
        if (durationSeconds > 0 && durationSeconds != _totalDuration) {
          _totalDuration = durationSeconds;
          debugPrint('从播放器更新总时长: $_totalDuration 秒');
        }

        debugPrint('onProgress 流更新: $_currentTime / $_totalDuration');
        notifyListeners();
      }
    });

    if (_progressSubscription == null) {
      debugPrint('警告: onProgress 流为 null，无法设置进度监听');
    } else {
      debugPrint('播放进度监听设置成功');
    }

    // 使用 Timer 主动更新进度（参考 audio_player_utils.dart 的实现）
    // 每 100ms 更新一次，确保 UI 流畅更新
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPlaying || _audioPlayer == null || !_audioPlayer!.isPlaying) {
        timer.cancel();
        _progressTimer = null;
        _playStartTime = null;
        return;
      }

      // 如果总时长大于0，主动更新进度
      if (_totalDuration > 0 && _playStartTime != null) {
        // 计算从播放开始到现在经过的时间（秒）
        final elapsed = DateTime.now().difference(_playStartTime!).inMilliseconds ~/ 1000;
        final estimatedTime = _playStartPosition + elapsed;

        if (estimatedTime <= _totalDuration) {
          // 只有当估算时间大于当前时间时才更新（避免倒退）
          if (estimatedTime > _currentTime) {
            _currentTime = estimatedTime;
            debugPrint('Timer 更新进度: $_currentTime / $_totalDuration');
            notifyListeners();
          }
        } else {
          // 如果已经到达或超过总时长
          if (_currentTime < _totalDuration) {
            _currentTime = _totalDuration;
            notifyListeners();
          }
        }
      } else {
        // 如果总时长为0，至少触发一次 UI 更新
        notifyListeners();
      }
    });
  }

  /// 暂停播放
  /// 暂停当前正在播放的音频
  Future<void> pause() async {
    if (!_isPlaying) return;

    _isPlaying = false;

    try {
      if (_audioPlayer != null && _audioPlayer!.isPlaying) {
        await _audioPlayer!.pausePlayer();
        debugPrint('音频已暂停');
      }
    } catch (e) {
      debugPrint('暂停音频时出错: $e');
    }

    notifyListeners();
  }

  /// 停止播放并重置到初始状态
  Future<void> stop() async {
    _isPlaying = false;
    _currentTime = 0;

    try {
      if (_audioPlayer != null && _audioPlayer!.isPlaying) {
        await _audioPlayer!.stopPlayer();
        debugPrint('音频已停止');
      }
    } catch (e) {
      debugPrint('停止音频时出错: $e');
    }

    notifyListeners();
  }
  // AI-generated END - pause

  /// 跳转到指定位置
  /// @param progress 播放进度 (0.0 - 1.0)
  Future<void> seekTo(double progress) async {
    final newTime = (progress * _totalDuration).round();
    _currentTime = newTime.clamp(0, _totalDuration);
    notifyListeners();

    try {
      if (_audioPlayer != null && _audioPlayer!.isOpen()) {
        // 即使不在播放状态，也可以跳转位置
        await _audioPlayer!.seekToPlayer(Duration(seconds: _currentTime));
        debugPrint('跳转到位置: $_currentTime 秒');
      }
    } catch (e) {
      debugPrint('跳转音频时出错: $e');
    }
  }
  // AI-generated END - seekTo

  // // AI-generated START - 保存声纹
  void saveVoice(String name, VoidCallback? successCallback) async {
    if (name.isEmpty) {
      debugPrint('保存声纹失败，姓名为空');
      MPToastUtils.showMessage('请输入姓名');
      return;
    }
    debugPrint('Saving voice: $name, voiceId: $voiceId, isEditMode: $_isEditMode');

    // 上传头像（如果有）
    String avatarUrl = '';
    if (_avatarImage != null) {
      final avatarUri = await MPAudioUploadService().uploadMPAudio(_avatarImage!);
      avatarUrl = avatarUri ?? '';
    } else if (_avatarUrl != null) {
      avatarUrl = _avatarUrl!;
    }

    // 编辑模式：更新现有声纹
    if (voiceId != null && voiceId!.isNotEmpty) {
      // 编辑模式下，音频文件可能没有变化，所以 audioPath 可能为空
      // String? audioUri;
      // if (audioPath != null) {
      //   audioUri = await MPAudioUploadService().uploadMPAudio(File(audioPath!)) ?? '';
      //   if (audioUri.isEmpty) {
      //     debugPrint('更新声纹失败，音频上传失败');
      //     MPToastUtils.showMessage('音频上传失败');
      //     return;
      //   }
      // }

      final updateReq = MPUpdateSpeakerRequest(
        speakerId: voiceId!,
        name: name,
        // audioUrl: audioUri,
        avatar: avatarUrl.isNotEmpty ? avatarUrl : null,
        // myselfVoice: isMyselfVoice,
      );

      final res = await updateSpeaker(updateReq);
      if (res?.baseResp.code == 0) {
        debugPrint('更新声纹成功');
        MPToastUtils.showMessage('更新声纹成功');
        successCallback?.call();
        _deleteAudioFile();
      } else {
        debugPrint('更新声纹失败: ${res?.baseResp.message}');
        MPToastUtils.showMessage(res?.baseResp.message ?? '更新声纹失败');
      }
    } else {
      // 新增模式：创建新声纹
      if (audioPath == null) {
        debugPrint('保存声纹失败，音频文件为空');
        MPToastUtils.showMessage('音频文件为空');
        return;
      }

      final uri = await MPAudioUploadService().uploadMPAudio(File(audioPath!)) ?? '';
      if (uri.isEmpty) {
        debugPrint('保存声纹失败，返回的uri为空');
        MPToastUtils.showMessage('音频上传失败');
        return;
      }

      final req = MPAddSpeakerRequest(
        name: name,
        audioUrl: uri,
        avatar: avatarUrl,
        myselfVoice: isMyselfVoice,
        duration: _totalDuration,
      );

      final res = await addSpeaker(req);
      if (res?.baseResp.code == 0) {
        debugPrint('保存声纹成功，声纹ID: ${res?.baseResp.message}');
        MPToastUtils.showMessage('保存声纹成功');
        successCallback?.call();
        _deleteAudioFile();
      } else {
        debugPrint('保存声纹失败: ${res?.baseResp.message}');
        MPToastUtils.showMessage(res?.baseResp.message ?? '保存声纹失败');
      }
    }
  }
  // AI-generated END - saveVoice

  // AI-generated START - 删除声纹
  /// 删除声纹
  /// 如果是编辑模式（有 voiceId），调用删除 API
  /// 如果是新增模式（没有 voiceId），只删除本地文件
  Future<void> deleteVoice({VoidCallback? successCallback}) async {
    if (voiceId != null && voiceId!.isNotEmpty) {
      // 编辑模式：调用删除 API
      debugPrint('删除声纹: $voiceId');
      final req = MPDeleteSpeakerRequest(speakerId: voiceId!);
      final res = await deleteSpeaker(req);

      if (res?.baseResp.code == 0) {
        debugPrint('删除声纹成功');
        MPToastUtils.showMessage('删除声纹成功');
        successCallback?.call();
      } else {
        debugPrint('删除声纹失败: ${res?.baseResp.message}');
        MPToastUtils.showMessage(res?.baseResp.message ?? '删除声纹失败');
      }
    } else {
      // 新增模式：只删除本地文件
      debugPrint('删除本地音频文件');
      _deleteAudioFile();
      MPToastUtils.showMessage('删除声纹成功');
      successCallback?.call();
    }
  }
  // AI-generated END - deleteVoice

  // 删除audioFile
  void _deleteAudioFile() {
    if (audioPath != null && File(audioPath!).existsSync()) {
      File(audioPath!).delete().catchError((e) {
        debugPrint('删除音频文件时出错: $e');
        return File(audioPath!);
      });
      audioPath = null;
    }
  }

  @override
  void dispose() {
    // 取消播放进度监听和定时器
    _progressSubscription?.cancel();
    _progressSubscription = null;
    _progressTimer?.cancel();
    _progressTimer = null;
    _playStartTime = null;

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
