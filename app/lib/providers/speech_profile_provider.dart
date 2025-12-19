/// 语音配置文件提供者
///
/// 负责管理用户语音配置文件的创建、上传和完成流程。
/// 通过蓝牙设备接收音频数据，通过WebSocket发送到服务器进行语音识别和转录，
/// 收集足够的语音样本后创建并上传语音配置文件。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_provider_utilities/flutter_provider_utilities.dart';
import 'package:omi/backend/http/api/speech_profile.dart';
import 'package:omi/backend/http/api/users.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/bt_device/bt_device.dart';
import 'package:omi/backend/schema/conversation.dart';
import 'package:omi/backend/schema/message_event.dart';
import 'package:omi/backend/schema/transcript_segment.dart';
import 'package:omi/providers/device_provider.dart';
import 'package:omi/services/devices.dart';
import 'package:omi/services/services.dart';
import 'package:omi/services/sockets/transcription_connection.dart';
import 'package:omi/utils/audio/wav_bytes.dart';

/// 语音配置文件提供者类
///
/// 管理语音配置文件的整个生命周期：
/// - 初始化蓝牙设备连接和WebSocket连接
/// - 接收并处理音频数据流
/// - 收集和验证语音转录片段
/// - 上传语音配置文件到服务器
/// - 跟踪录音进度和完成状态
class SpeechProfileProvider extends ChangeNotifier
    with MessageNotifierMixin
    implements IDeviceServiceSubsciption, ITransctipSegmentSocketServiceListener {
  /// 设备提供者，用于管理蓝牙设备连接
  DeviceProvider? deviceProvider;

  /// 录音权限是否已启用
  bool? permissionEnabled;

  /// 是否正在加载
  bool loading = false;

  /// 当前连接的蓝牙设备
  BtDevice? device;

  /// 目标单词数量，需要收集70个单词才能完成语音配置
  final targetWordsCount = 70;

  /// 最大录音时长（秒）
  final maxDuration = 150;

  /// 设备连接状态监听器
  StreamSubscription<OnConnectionStateChangedEvent>? connectionStateListener;

  /// 收集到的转录片段列表
  List<TranscriptSegment> segments = [];

  /// 音频流开始的时间点（秒）
  double? streamStartedAtSecond;

  /// 音频数据存储工具，用于存储和处理WAV格式的音频数据
  late WavBytesUtil audioStorage;

  /// 蓝牙音频字节流订阅
  StreamSubscription? _bleBytesStream;

  /// WebSocket服务，用于发送音频数据和接收转录结果
  TranscriptSegmentSocketService? _socket;

  /// 是否已开始录音
  bool startedRecording = false;

  /// 完成百分比（0.0 - 1.0）
  double percentageCompleted = 0;

  /// 是否正在上传配置文件
  bool uploadingProfile = false;

  /// 配置文件是否已完成
  bool profileCompleted = false;

  /// 强制完成定时器
  Timer? forceCompletionTimer;

  /// 是否正在初始化
  bool isInitialising = false;

  /// 是否已完成初始化
  bool isInitialised = false;

  /// 当前收集到的文本内容
  String text = '';

  /// 进度提示消息
  String message = '';

  /// 完成后的回调函数
  late Function? _finalizedCallback;

  /// 仅用于引导流程中的加载文本
  String loadingText = 'Uploading your voice profile....';

  /// 服务器会话（仅用于引导流程）
  ServerConversation? conversation;

  /// 更新加载文本
  ///
  /// [text] 要显示的加载文本
  void updateLoadingText(String text) {
    loadingText = text;
    notifyListeners();
  }

  /// 设置初始化状态
  ///
  /// [value] 是否正在初始化
  void setInitialising(bool value) {
    isInitialising = value;
    notifyListeners();
  }

  /// 设置已初始化状态
  ///
  /// [value] 是否已完成初始化
  void setInitialised(bool value) {
    isInitialised = value;
    notifyListeners();
  }

  /// 设置设备提供者
  ///
  /// [provider] 设备提供者实例
  void setProviders(DeviceProvider provider) {
    deviceProvider = provider;
    notifyListeners();
  }

  /// 更新设备连接
  ///
  /// 如果当前没有设备，则扫描并连接到设备
  Future<void> updateDevice() async {
    if (device == null) {
      await deviceProvider?.scanAndConnectToDevice();
      device = deviceProvider?.connectedDevice;
    }
    notifyListeners();
  }

  /// 初始化语音配置文件流程
  ///
  /// 执行以下步骤：
  /// 1. 获取设备音频编解码器
  /// 2. 初始化音频存储工具
  /// 3. 建立WebSocket连接
  /// 4. 启动蓝牙音频流
  ///
  /// [finalizedCallback] 完成后的回调函数
  Future<void> initialise({Function? finalizedCallback}) async {
    _finalizedCallback = finalizedCallback;
    setInitialising(true);
    device = deviceProvider?.connectedDevice;

    // 获取设备的音频编解码器
    BleAudioCodec codec = await _getAudioCodec(device!.id);
    // 初始化音频存储工具，使用编解码器的帧率
    audioStorage = WavBytesUtil(codec: codec, framesPerSecond: codec.getFramesPerSecond());
    // 建立WebSocket连接
    await _initiateWebsocket(codec: codec, force: true);

    // 如果设备存在，启动音频流
    if (device != null) await initiateFriendAudioStreaming();
    // 等待WebSocket连接建立
    if (_socket?.state != SocketServiceState.connected) {
      await Future.delayed(const Duration(seconds: 2));
    }

    setInitialising(false);
    setInitialised(true);
    notifyListeners();
  }

  /// 更新录音开始状态
  ///
  /// [value] 是否已开始录音
  void updateStartedRecording(bool value) {
    startedRecording = value;
    notifyListeners();
  }

  /// 更改加载状态
  ///
  /// [value] 是否正在加载
  changeLoadingState(bool value) {
    loading = value;
    notifyListeners();
  }

  /// 初始化连接状态监听器
  ///
  /// 订阅设备连接状态变化事件
  initiateConnectionListener() async {
    if (device == null || connectionStateListener != null) return;
    ServiceManager.instance().device.subscribe(this, this);
  }

  /// 初始化WebSocket连接
  ///
  /// 连接到语音配置文件WebSocket服务，用于发送音频数据和接收转录结果
  ///
  /// [codec] 音频编解码器
  /// [force] 是否强制创建新连接
  Future<void> _initiateWebsocket({required BleAudioCodec codec, bool force = false}) async {
    // 获取用户语言设置，如果没有设置则使用"multi"（多语言）
    String language =
        SharedPreferencesUtil().hasSetPrimaryLanguage ? SharedPreferencesUtil().userPrimaryLanguage : "multi";
    // 根据编解码器支持情况设置采样率：Opus支持16000Hz，否则8000Hz
    int sampleRate = (codec.isOpusSupported() ? 16000 : 8000);

    // 创建语音配置文件WebSocket连接
    _socket = await ServiceManager.instance()
        .socket
        .speechProfile(codec: codec, sampleRate: sampleRate, language: language, force: force);
    if (_socket == null) {
      throw Exception("Can not create new speech profile socket");
    }
    // 订阅WebSocket事件
    _socket?.subscribe(this, this);
  }

  /// 处理完成逻辑
  ///
  /// 计算当前完成百分比，如果达到100%则自动完成配置
  _handleCompletion() async {
    if (uploadingProfile || profileCompleted) return;
    // 合并所有片段的文本
    String text = segments.map((e) => e.text).join(' ').trim();
    // 计算单词数量
    int wordsCount = text.split(' ').length;
    // 计算完成百分比（0.0 - 1.0）
    percentageCompleted = (wordsCount / targetWordsCount).clamp(0, 1);
    notifyListeners();
    // 如果达到100%，则完成配置
    if (percentageCompleted == 1) {
      await finalize();
    }
    notifyListeners();
  }

  /// 完成语音配置文件创建
  ///
  /// 执行以下步骤：
  /// 1. 验证录音时长和单词数量
  /// 2. 停止所有流和连接
  /// 3. 创建WAV文件
  /// 4. 上传配置文件到服务器
  /// 5. 更新完成状态
  Future finalize() async {
    try {
      if (uploadingProfile || profileCompleted) return;

      // 计算录音时长
      int duration = segments.isEmpty ? 0 : segments.last.end.toInt();
      // 验证时长：如果时长不在10-155秒之间，且完成度低于80%，则报错
      if (duration < 10 || duration > 155) {
        if (percentageCompleted < 80) {
          notifyError('NO_SPEECH');
          return;
        }
      }

      // 合并所有文本并验证单词数量
      String text = segments.map((e) => e.text).join(' ').trim();
      // 如果单词数量少于目标的一半（35个），则报错
      if (text.split(' ').length < (targetWordsCount / 2)) {
        notifyError('TOO_SHORT');
        return;
      }

      uploadingProfile = true;
      notifyListeners();

      // 停止所有连接和流
      await _socket?.stop(reason: 'finalizing');
      forceCompletionTimer?.cancel();
      connectionStateListener?.cancel();
      _bleBytesStream?.cancel();

      // 创建WAV文件
      updateLoadingText('Memorizing your voice...');
      var data = await audioStorage.createWavFile(filename: 'speaker_profile.wav');
      try {
        // 上传配置文件
        await uploadProfile(data.item1);
      } catch (e) {}

      // 更新完成状态
      updateLoadingText('Personalizing your experience...');
      SharedPreferencesUtil().hasSpeakerProfile = true;
      uploadingProfile = false;
      profileCompleted = true;
      text = '';
      updateLoadingText("You're all set!");
      notifyListeners();
    } finally {
      // 执行完成回调
      if (_finalizedCallback != null) {
        _finalizedCallback!();
      }
    }
  }

  /// 获取设备的音频编解码器
  ///
  /// [deviceId] 设备ID
  /// 返回设备的音频编解码器，如果连接失败则返回默认的PCM8编解码器
  ///
  /// TODO: 直接使用连接对象
  Future<BleAudioCodec> _getAudioCodec(String deviceId) async {
    var connection = await ServiceManager.instance().device.ensureConnection(deviceId);
    if (connection == null) {
      return BleAudioCodec.pcm8;
    }
    return connection.getAudioCodec();
  }

  /// 获取蓝牙音频字节流监听器
  ///
  /// [deviceId] 设备ID
  /// [onAudioBytesReceived] 接收到音频字节时的回调函数
  /// 返回音频字节流的订阅对象，如果连接失败则返回null
  Future<StreamSubscription?> _getBleAudioBytesListener(
    String deviceId, {
    required void Function(List<int>) onAudioBytesReceived,
  }) async {
    var connection = await ServiceManager.instance().device.ensureConnection(deviceId);
    if (connection == null) {
      return Future.value(null);
    }
    return connection.getBleAudioBytesListener(onAudioBytesReceived: onAudioBytesReceived);
  }

  /// 启动音频流传输
  ///
  /// 从蓝牙设备接收音频数据，存储到本地并发送到WebSocket服务器
  Future<void> initiateFriendAudioStreaming() async {
    _bleBytesStream = await _getBleAudioBytesListener(
      device!.id,
      onAudioBytesReceived: (List<int> value) {
        if (value.isEmpty) return;
        // 存储音频帧数据
        audioStorage.storeFramePacket(value);

        // 移除前3个字节（可能是头部信息），然后发送到WebSocket
        value.removeRange(0, 3);
        if (_socket?.state == SocketServiceState.connected) {
          _socket?.send(value);
        }
      },
    );
  }

  /// 验证是否为单一说话人
  ///
  /// 检查转录片段中是否只有一个说话人。
  /// 如果检测到多个说话人且每个说话人的单词占比都超过8%，则报错
  _validateSingleSpeaker() {
    // 统计不同说话人的数量
    int speakersCount = segments.map((e) => e.speaker).toSet().length;
    debugPrint('_validateSingleSpeaker speakers count: $speakersCount');
    if (speakersCount > 1) {
      // 计算每个说话人的单词数量
      var speakerToWords = segments.fold<Map<int, int>>(
        {},
        (previousValue, element) {
          previousValue[element.speakerId] = (previousValue[element.speakerId] ?? 0) + element.text.split(' ').length;
          return previousValue;
        },
      );
      debugPrint('speakerToWords: $speakerToWords');
      // 如果每个说话人的单词占比都超过8%，则认为是多个说话人
      if (speakerToWords.values.every((element) => element / segments.length > 0.08)) {
        notifyError('MULTIPLE_SPEAKERS');
      }
    }
  }

  /// 重置所有片段数据
  ///
  /// 清空收集到的转录片段、音频数据和进度信息
  void resetSegments() {
    segments.clear();
    streamStartedAtSecond = null;
    audioStorage.clearAudioBytes();
    text = '';
    percentageCompleted = 0;
    notifyListeners();
  }

  /// 设置语音录音权限
  ///
  /// 请求并保存录音权限设置
  Future setupSpeechRecording() async {
    final permission = await getStoreRecordingPermission();
    permissionEnabled = permission;
    if (permission != null) {
      SharedPreferencesUtil().permissionStoreRecordingsEnabled = permission;
    }
    notifyListeners();
  }

  /// 更新进度消息
  ///
  /// 根据当前收集到的单词数量更新提示消息
  void updateProgressMessage() {
    // 合并所有片段的文本
    text = segments.map((e) => e.text).join(' ').trim();
    int wordsCount = text.split(' ').length;
    // 根据单词数量设置不同的鼓励消息
    message = 'Keep speaking until you get 100%.';
    if (wordsCount > 10) {
      message = 'Keep going, you are doing great';
    } else if (wordsCount > 25) {
      message = 'Great job, you are almost there';
    } else if (wordsCount > 40) {
      message = 'So close, just a little more';
    }
    notifyListeners();
  }

  /// 关闭所有连接和资源
  ///
  /// 清理所有订阅、流和状态，停止WebSocket连接
  Future close() async {
    connectionStateListener?.cancel();
    _bleBytesStream?.cancel();
    forceCompletionTimer?.cancel();
    segments.clear();
    text = '';
    startedRecording = false;
    percentageCompleted = 0;
    uploadingProfile = false;
    profileCompleted = false;
    await _socket?.stop(reason: 'closing');
    notifyListeners();
  }

  @override
  void dispose() {
    // 注意：除非provider从widget树中移除，否则此方法不会被调用。
    // 因此需要在widget的dispose方法中手动调用此方法。

    // 取消所有订阅和流
    connectionStateListener?.cancel();
    _bleBytesStream?.cancel();
    forceCompletionTimer?.cancel();
    _finalizedCallback = null;
    _socket?.unsubscribe(this);
    ServiceManager.instance().device.unsubscribe(this);

    super.dispose();
  }

  /// 设备连接状态变化回调
  ///
  /// [deviceId] 设备ID
  /// [state] 连接状态
  @override
  void onDeviceConnectionStateChanged(String deviceId, DeviceConnectionState state) async {
    switch (state) {
      case DeviceConnectionState.connected:
        // 设备已连接，确保连接建立并启动音频流
        var connection = await ServiceManager.instance().device.ensureConnection(deviceId);
        if (connection == null) {
          return;
        }
        device = connection.device;
        notifyListeners();
        initiateFriendAudioStreaming();
        break;
      case DeviceConnectionState.disconnected:
        // 设备已断开，清除设备引用
        if (deviceId == device?.id) {
          device = null;
          notifyListeners();
        }
        break;
    }
  }

  /// 设备列表更新回调（未实现）
  @override
  void onDevices(List<BtDevice> devices) {}

  /// 设备服务状态变化回调（未实现）
  @override
  void onStatusChanged(DeviceServiceStatus status) {}

  /// WebSocket关闭回调
  ///
  /// [closeCode] 关闭代码
  @override
  void onClosed([int? closeCode]) {
    // TODO: 实现onClosed
  }

  /// WebSocket错误回调
  ///
  /// [err] 错误对象
  @override
  void onError(Object err) {
    notifyError('WS_ERR');
  }

  /// 消息事件接收回调（未实现）
  ///
  /// [event] 消息事件
  @override
  void onMessageEventReceived(MessageEvent event) {
    // TODO: 实现onMessageEventReceived
  }

  /// 转录片段接收回调
  ///
  /// 当从WebSocket接收到新的转录片段时调用。
  /// 处理片段更新、验证说话人、更新进度并检查是否完成。
  ///
  /// [newSegments] 新接收到的转录片段列表
  @override
  void onSegmentReceived(List<TranscriptSegment> newSegments) {
    if (newSegments.isEmpty) return;

    // 如果是第一个片段，移除片段开始前的音频帧
    if (segments.isEmpty) {
      audioStorage.removeFramesRange(fromSecond: 0, toSecond: newSegments[0].start.toInt());
    }
    // 记录音频流开始时间
    streamStartedAtSecond ??= newSegments[0].start;

    // 更新片段列表
    var remainSegments = TranscriptSegment.updateSegments(segments, newSegments);
    // 合并片段
    TranscriptSegment.combineSegments(
      segments,
      remainSegments,
      toRemoveSeconds: streamStartedAtSecond ?? 0,
    );

    // 更新进度消息
    updateProgressMessage();
    // 验证是否为单一说话人
    _validateSingleSpeaker();
    // 处理完成逻辑
    _handleCompletion();
    notifyInfo('SCROLL_DOWN');
    debugPrint('Conversation creation timer restarted');
  }

  /// WebSocket连接成功回调（未实现）
  @override
  void onConnected() {}
}
