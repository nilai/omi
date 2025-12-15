import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_provider_utilities/flutter_provider_utilities.dart';
import 'package:omi/backend/http/api/conversations.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/bt_device/bt_device.dart';
import 'package:omi/backend/schema/conversation.dart';
import 'package:omi/backend/schema/message.dart';
import 'package:omi/backend/schema/message_event.dart';
import 'package:omi/backend/schema/person.dart';
import 'package:omi/backend/schema/structured.dart';
import 'package:omi/backend/schema/transcript_segment.dart';
import 'package:omi/providers/conversation_provider.dart';
import 'package:omi/providers/message_provider.dart';
import 'package:omi/providers/people_provider.dart';
import 'package:omi/providers/usage_provider.dart';
import 'package:omi/services/connectivity_service.dart';
import 'package:omi/services/services.dart';
import 'package:omi/services/sockets/transcription_connection.dart';
import 'package:omi/services/wals.dart';
import 'package:omi/utils/alerts/app_snackbar.dart';
import 'package:omi/utils/analytics/mixpanel.dart';
import 'package:omi/utils/debug_log_manager.dart';
import 'package:omi/utils/enums.dart';
import 'package:omi/utils/image/image_utils.dart';
import 'package:omi/utils/logger.dart';
import 'package:omi/utils/platform/platform_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// 音频捕获提供者
/// 管理来自不同源的音频录制，包括蓝牙设备、系统音频和麦克风
/// 同时处理转录服务连接和WebSocket通信
/// 实现消息通知混入和应用生命周期观察者
class CaptureProvider extends ChangeNotifier
    with MessageNotifierMixin, WidgetsBindingObserver
    implements ITransctipSegmentSocketServiceListener {
  /// 会话提供者
  ConversationProvider? conversationProvider;
  
  /// 消息提供者
  MessageProvider? messageProvider;
  
  /// 人员提供者
  PeopleProvider? peopleProvider;
  
  /// 使用情况提供者
  UsageProvider? usageProvider;

  /// 转录段套接字服务
  TranscriptSegmentSocketService? _socket;
  
  /// 保活定时器
  Timer? _keepAliveTimer;
  
  /// 上次执行保活的时间
  DateTime? _keepAliveLastExecutedAt;

  // Method channel for system audio permissions
  /// 系统音频权限的方法通道
  static late MethodChannel _screenCaptureChannel;
  
  /// 控制栏的方法通道
  static late MethodChannel _controlBarChannel;

  /// 获取WAL服务实例
  IWalService get _wal => ServiceManager.instance().wal;

  /// 是否支持WAL
  bool _isWalSupported = false;

  /// 获取是否支持WAL
  bool get isWalSupported => _isWalSupported;

  /// 连接状态监听器
  StreamSubscription<bool>? _connectionStateListener;
  
  /// 是否已连接
  bool _isConnected = ConnectivityService().isConnected;

  /// 获取连接状态
  get isConnected => _isConnected;

  /// 麦克风名称
  String? microphoneName;
  
  /// 麦克风级别
  double microphoneLevel = 0.0;
  
  /// 系统音频级别
  double systemAudioLevel = 0.0;

  /// 是否正在自动重连
  bool _isAutoReconnecting = false;
  
  /// 获取是否正在自动重连
  bool get isAutoReconnecting => _isAutoReconnecting;

  /// 是否超出信用额度
  bool get outOfCredits => usageProvider?.isOutOfCredits ?? false;

  /// 重连定时器
  Timer? _reconnectTimer;
  
  /// 重连倒计时
  int _reconnectCountdown = 5;
  
  /// 获取重连倒计时
  int get reconnectCountdown => _reconnectCountdown;

  /// 录制定时器
  Timer? _recordingTimer;
  
  /// 录制持续时间（秒）
  int _recordingDuration = 0; // in seconds

  /// 获取录制持续时间
  int _getRecordingDuration() => _recordingDuration;

  /// 转录服务状态列表
  List<MessageEvent> _transcriptionServiceStatuses = [];
  
  /// 获取转录服务状态列表
  List<MessageEvent> get transcriptionServiceStatuses => _transcriptionServiceStatuses;

  /// 系统音频缓冲区
  List<int> _systemAudioBuffer = [];
  
  /// 是否缓存系统音频
  bool _systemAudioCaching = true;

  // BLE streaming metrics
  /// BLE接收字节数
  int _blesBytesReceived = 0;
  
  /// WebSocket发送字节数
  int _wsSocketBytesSent = 0;
  
  /// BLE接收速率（kbps）
  double _bleReceiveRateKbps = 0.0;
  
  /// WebSocket发送速率（kbps）
  double _wsSendRateKbps = 0.0;
  
  /// 上次计算指标的时间
  DateTime? _metricsLastCalculated;
  
  /// 指标定时器
  Timer? _metricsTimer;

  /// 获取BLE接收速率
  double get bleReceiveRateKbps => _bleReceiveRateKbps;
  
  /// 获取WebSocket发送速率
  double get wsSendRateKbps => _wsSendRateKbps;

  /// 构造函数
  /// 初始化连接状态监听器和平台特定功能
  CaptureProvider() {
    _connectionStateListener = ConnectivityService().onConnectionChange.listen((bool isConnected) {
      onConnectionStateChanged(isConnected);
    });

    if (PlatformService.isDesktop) {
      _screenCaptureChannel = const MethodChannel('screenCapturePlatform');
      _controlBarChannel = const MethodChannel('com.omi/floating_control_bar');

      _initializeAppLifecycleListener();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controlBarChannel.setMethodCallHandler(_handleFloatingControlBarMethodCall);
      });
    }
  }

  /// 初始化应用生命周期监听器
  void _initializeAppLifecycleListener() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  /// 应用生命周期状态改变回调
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  /// 处理应用恢复事件
  void _handleAppResumed() async {
    if (recordingState == RecordingState.systemAudioRecord) {
      try {
        // 检查原生录制是否仍在活动
        bool nativeRecording = await _screenCaptureChannel.invokeMethod('isRecording') ?? false;

        if (nativeRecording && recordingState != RecordingState.systemAudioRecord) {
          // 将由streamSystemAudioRecording错误处理中的现有逻辑处理
        } else if (!nativeRecording && recordingState == RecordingState.systemAudioRecord) {
          updateRecordingState(RecordingState.stop);
          await _socket?.stop(reason: 'native recording stopped during sleep');
          await DebugLogManager.logEvent('transcription_socket_stop_due_to_sleep', {});
        }
      } catch (e) {
        debugPrint('Could not check state during app resume: $e');
      }
    }
  }

  /// 更新提供者实例
  /// 设置会话、消息、人员和使用情况提供者的引用
  void updateProviderInstances(ConversationProvider? cp, MessageProvider? mp, PeopleProvider? pp, UsageProvider? up) {
    conversationProvider = cp;
    messageProvider = mp;
    peopleProvider = pp;
    usageProvider = up;

    notifyListeners();
  }

  /// 当前录制设备
  BtDevice? _recordingDevice;

  /// 根据设备类型获取会话来源
  String? _getConversationSourceFromDevice() {
    if (_recordingDevice == null) {
      return null;
    }
    switch (_recordingDevice!.type) {
      case DeviceType.friendPendant:
        return 'friend_com';
      case DeviceType.omi:
        return 'omi';
      case DeviceType.openglass:
        return 'openglass';
      case DeviceType.fieldy:
        return 'fieldy';
      case DeviceType.bee:
        return 'bee';
      case DeviceType.plaud:
        return 'plaud';
      case DeviceType.frame:
        return 'frame';
      case DeviceType.appleWatch:
        return 'apple_watch';
      case DeviceType.aiNote:
        return 'ai_note';
    }
  }

  /// 当前会话
  ServerConversation? _conversation;
  
  /// 转录段列表
  List<TranscriptSegment> segments = [];
  
  /// 会话照片列表
  List<ConversationPhoto> photos = [];
  
  /// 按段ID建议的说话者标签映射
  Map<String, SpeakerLabelSuggestionEvent> suggestionsBySegmentId = {};
  
  /// 正在标记的段ID列表
  List<String> taggingSegmentIds = [];

  /// 是否有转录内容
  bool hasTranscripts = false;

  /// BLE字节流订阅
  StreamSubscription? _bleBytesStream;
  
  /// BLE照片流订阅
  StreamSubscription? _blePhotoStream;

  /// 获取BLE字节流
  get bleBytesStream => _bleBytesStream;

  /// BLE按钮流订阅
  StreamSubscription? _bleButtonStream;
  
  /// 语音命令会话时间
  DateTime? _voiceCommandSession;
  
  /// 命令字节列表
  List<List<int>> _commandBytes = [];
  
  /// 是否正在处理按钮事件（防止重叠操作的保护标志）
  bool _isProcessingButtonEvent = false; // Guard to prevent overlapping button operations

  /// 存储流订阅
  StreamSubscription? _storageStream;

  /// 获取存储流
  get storageStream => _storageStream;

  /// 录制状态
  RecordingState recordingState = RecordingState.stop;

  /// 是否暂停
  bool _isPaused = false;
  
  /// 获取是否暂停
  bool get isPaused => _isPaused;

  /// 转录服务是否就绪
  bool _transcriptServiceReady = false;

  /// 获取转录服务是否就绪
  bool get transcriptServiceReady => _transcriptServiceReady && _isConnected;

  // having a connected device or using the phone's mic for recording
  /// 录制设备服务是否就绪
  /// 拥有连接的设备或使用手机麦克风进行录制
  bool get recordingDeviceServiceReady =>
      _recordingDevice != null ||
      recordingState == RecordingState.record ||
      recordingState == RecordingState.systemAudioRecord;

  /// 是否拥有录制设备
  bool get havingRecordingDevice => _recordingDevice != null;

  /// 设置是否有转录内容
  void setHasTranscripts(bool value) {
    hasTranscripts = value;
    notifyListeners();
  }

  /// 设置会话创建状态
  void setConversationCreating(bool value) {
    debugPrint('set Conversation creating $value');
    // ConversationCreating = value;
    notifyListeners();
  }

  /// 更新录制设备
  void _updateRecordingDevice(BtDevice? device) {
    debugPrint('connected device changed from ${_recordingDevice?.id} to ${device?.id}');
    _recordingDevice = device;
    notifyListeners();
  }

  /// 公开的更新录制设备方法
  void updateRecordingDevice(BtDevice? device) {
    _updateRecordingDevice(device);
  }

  /// 重置状态变量
  Future _resetStateVariables() async {
    segments = [];
    photos = [];
    hasTranscripts = false;
    suggestionsBySegmentId = {};
    _conversation = null;
    taggingSegmentIds = [];
    notifyListeners();
  }

  /// 录制配置更改时的回调
  Future<void> onRecordProfileSettingChanged() async {
    await _resetState();
  }

  /// 更改音频录制配置
  Future<void> changeAudioRecordProfile({
    required BleAudioCodec audioCodec,
    int? sampleRate,
    int? channels,
    bool? isPcm,
    String? source,
  }) async {
    await _resetState();
    await _initiateWebsocket(
        audioCodec: audioCodec, sampleRate: sampleRate, channels: channels, isPcm: isPcm, source: source);
  }

  /// 初始化WebSocket连接
  Future<void> _initiateWebsocket({
    required BleAudioCodec audioCodec,
    int? sampleRate,
    int? channels,
    bool? isPcm,
    bool force = false,
    String? source,
  }) async {
    Logger.debug('initiateWebsocket in capture_provider');

    BleAudioCodec codec = audioCodec;
    sampleRate ??= mapCodecToSampleRate(codec);
    channels ??= (codec == BleAudioCodec.pcm16 || codec == BleAudioCodec.pcm8) ? 1 : 2;

    Logger.debug('is ws null: ${_socket == null}');
    Logger.debug('Initiating WebSocket with: codec=$codec, sampleRate=$sampleRate, channels=$channels, isPcm=$isPcm');

    // Connect to the transcript socket
    String language =
        SharedPreferencesUtil().hasSetPrimaryLanguage ? SharedPreferencesUtil().userPrimaryLanguage : "multi";

    _socket = await ServiceManager.instance()
        .socket
        .conversation(codec: codec, sampleRate: sampleRate, language: language, force: force, source: source);
    if (_socket == null) {
      _startKeepAliveServices();
      debugPrint("Can not create new conversation socket");
      return;
    }
    _socket?.subscribe(this, this);
    _transcriptServiceReady = true;

    _loadInProgressConversation();

    notifyListeners();
  }

  /// 处理语音命令字节数据
  void _processVoiceCommandBytes(String deviceId, List<List<int>> data) async {
    if (data.isEmpty) {
      debugPrint("voice frames is empty");
      return;
    }

    BleAudioCodec codec = await _getAudioCodec(_recordingDevice!.id);
    if (messageProvider != null) {
      await messageProvider?.sendVoiceMessageStreamToServer(
        data,
        onFirstChunkRecived: () {
          _playSpeakerHaptic(deviceId, 2);
        },
        codec: codec,
      );
    }
  }

  // Just incase the ble connection get loss
  /// 监视语音命令（防止BLE连接丢失）
  void _watchVoiceCommands(String deviceId, DateTime session) {
    Timer.periodic(const Duration(seconds: 3), (t) async {
      debugPrint("voice command watch");
      if (session != _voiceCommandSession) {
        t.cancel();
        return;
      }
      var value = await _getBleButtonState(deviceId);
      if (value.isEmpty || value.length < 4) return;
      var buttonState = ByteData.view(Uint8List.fromList(value.sublist(0, 4).reversed.toList()).buffer).getUint32(0);
      debugPrint("watch device button $buttonState");

      // Force process
      if (buttonState == 5 && session == _voiceCommandSession) {
        _voiceCommandSession = null; // end session
        var data = List<List<int>>.from(_commandBytes);
        _commandBytes = [];
        _processVoiceCommandBytes(deviceId, data);
      }
    });
  }

  /// 流式传输按钮事件
  Future streamButton(String deviceId) async {
    debugPrint('streamButton in capture_provider');
    _bleButtonStream?.cancel();
    _bleButtonStream = await _getBleButtonListener(deviceId, onButtonReceived: (List<int> value) {
      final snapshot = List<int>.from(value);
      if (snapshot.isEmpty || snapshot.length < 4) return;
      var buttonState = ByteData.view(Uint8List.fromList(snapshot.sublist(0, 4).reversed.toList()).buffer).getUint32(0);
      debugPrint("device button $buttonState");

      // double tap
      if (buttonState == 2) {
        debugPrint("Double tap detected");

        // Guard: ignore if already processing a button event
        if (_isProcessingButtonEvent) {
          debugPrint("Double tap: already processing, ignoring");
          return;
        }

        if (SharedPreferencesUtil().doubleTapPausesMuting) {
          // Pause/resume recording
          debugPrint("Double tap: toggling pause/mute");
          _isProcessingButtonEvent = true;
          if (_isPaused) {
            resumeDeviceRecording().then((_) {
              _isProcessingButtonEvent = false;
            }).catchError((e) {
              debugPrint("Error resuming device recording: $e");
              _isProcessingButtonEvent = false;
            });
          } else {
            pauseDeviceRecording().then((_) {
              _isProcessingButtonEvent = false;
            }).catchError((e) {
              debugPrint("Error pausing device recording: $e");
              _isProcessingButtonEvent = false;
            });
          }
        } else {
          // End conversation and process (default)
          debugPrint("Double tap: processing conversation");
          forceProcessingCurrentConversation();
        }
        return;
      }

      // start long press (for voice commands)
      if (buttonState == 3 && _voiceCommandSession == null) {
        _voiceCommandSession = DateTime.now();
        _commandBytes = [];
        _watchVoiceCommands(deviceId, _voiceCommandSession!);
        _playSpeakerHaptic(deviceId, 1);
      }

      // release (end voice command)
      if (buttonState == 5 && _voiceCommandSession != null) {
        _voiceCommandSession = null; // end session
        var data = List<List<int>>.from(_commandBytes);
        _commandBytes = [];
        _processVoiceCommandBytes(deviceId, data);
      }
    });
  }

  /// 流式传输音频到WebSocket
  Future streamAudioToWs(String deviceId, BleAudioCodec codec) async {
    debugPrint('streamAudioToWs in capture_provider');
    _bleBytesStream?.cancel();
    _startMetricsTracking();
    _bleBytesStream = await _getBleAudioBytesListener(deviceId, onAudioBytesReceived: (List<int> value) {
      final snapshot = List<int>.from(value);
      if (snapshot.isEmpty || snapshot.length < 3) return;

      // Track bytes received from BLE
      _blesBytesReceived += snapshot.length;

      // Command button triggered
      bool voiceCommandSupported = _recordingDevice != null
          ? (_recordingDevice?.type == DeviceType.omi || _recordingDevice?.type == DeviceType.openglass)
          : false;
      if (_voiceCommandSession != null && voiceCommandSupported) {
        _commandBytes.add(snapshot.sublist(3));
      }

      // Local storage syncs
      var checkWalSupported =
          (_recordingDevice?.type == DeviceType.omi || _recordingDevice?.type == DeviceType.openglass) &&
              codec.isOpusSupported() &&
              (_socket?.state != SocketServiceState.connected || SharedPreferencesUtil().unlimitedLocalStorageEnabled);
      if (checkWalSupported != _isWalSupported) {
        setIsWalSupported(checkWalSupported);
      }
      if (_isWalSupported) {
        _wal.getSyncs().phone.onByteStream(snapshot);
      }

      // Send WS
      if (_socket?.state == SocketServiceState.connected) {
        final paddingLeft =
            (_recordingDevice?.type == DeviceType.omi || _recordingDevice?.type == DeviceType.openglass) ? 3 : 0;
        final trimmedValue = paddingLeft > 0 ? value.sublist(paddingLeft) : value;
        _socket?.send(trimmedValue);

        // Track bytes sent to websocket
        _wsSocketBytesSent += trimmedValue.length;

        // Mark as synced
        if (_isWalSupported) {
          _wal.getSyncs().phone.onBytesSync(value);
        }
      }
    });
    notifyListeners();
  }

  /// 重置状态
  Future<void> _resetState() async {
    debugPrint('resetState');
    await _cleanupCurrentState();

    // Always try to stream audio if a device is present
    await _ensureDeviceSocketConnection();
    await _initiateDeviceAudioStreaming();

    // Additionally, stream photos if the device supports it
    if (_recordingDevice != null) {
      var connection = await ServiceManager.instance().device.ensureConnection(_recordingDevice!.id);
      if (connection != null && await connection.hasPhotoStreamingCharacteristic()) {
        await _initiateDevicePhotoStreaming();
      }
    }

    notifyListeners();
  }

  /// 清理当前状态
  Future _cleanupCurrentState() async {
    await _closeBleStream();
    notifyListeners();
  }

  /// 获取音频编解码器
  Future<BleAudioCodec> _getAudioCodec(String deviceId) async {
    var connection = await ServiceManager.instance().device.ensureConnection(deviceId);
    if (connection == null) {
      return BleAudioCodec.pcm8;
    }
    return connection.getAudioCodec();
  }

  /// 播放扬声器触觉反馈
  Future<bool> _playSpeakerHaptic(String deviceId, int level) async {
    var connection = await ServiceManager.instance().device.ensureConnection(deviceId);
    if (connection == null) {
      return false;
    }
    return connection.performPlayToSpeakerHaptic(level);
  }

  /// 获取BLE音频字节监听器
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

  /// 获取BLE按钮监听器
  Future<StreamSubscription?> _getBleButtonListener(
    String deviceId, {
    required void Function(List<int>) onButtonReceived,
  }) async {
    var connection = await ServiceManager.instance().device.ensureConnection(deviceId);
    if (connection == null) {
      return Future.value(null);
    }
    return connection.getBleButtonListener(onButtonReceived: onButtonReceived);
  }

  /// 获取BLE按钮状态
  Future<List<int>> _getBleButtonState(String deviceId) async {
    var connection = await ServiceManager.instance().device.ensureConnection(deviceId);
    if (connection == null) {
      return Future.value(<int>[]);
    }
    return connection.getBleButtonState();
  }

  /// 确保设备套接字连接
  Future<void> _ensureDeviceSocketConnection() async {
    if (_recordingDevice == null) {
      return;
    }
    BleAudioCodec codec = await _getAudioCodec(_recordingDevice!.id);
    var language =
        SharedPreferencesUtil().hasSetPrimaryLanguage ? SharedPreferencesUtil().userPrimaryLanguage : "multi";
    if (language != _socket?.language || codec != _socket?.codec || _socket?.state != SocketServiceState.connected) {
      await _initiateWebsocket(audioCodec: codec, force: true, source: _getConversationSourceFromDevice());
    }
  }

  /// 启动设备音频流
  Future<void> _initiateDeviceAudioStreaming() async {
    if (_recordingDevice == null) {
      return;
    }
    final deviceId = _recordingDevice!.id;
    BleAudioCodec codec = await _getAudioCodec(deviceId);
    await _wal.getSyncs().phone.onAudioCodecChanged(codec);

    // Set device info for WAL creation
    var connection = await ServiceManager.instance().device.ensureConnection(_recordingDevice!.id);
    var pd = await _recordingDevice!.getDeviceInfo(connection);
    String deviceModel = pd.modelNumber.isNotEmpty ? pd.modelNumber : "Omi";
    _wal.getSyncs().phone.setDeviceInfo(_recordingDevice!.id, deviceModel);

    await streamButton(deviceId);
    await streamAudioToWs(deviceId, codec);

    // Set recording state to deviceRecord when device streaming starts
    updateRecordingState(RecordingState.deviceRecord);
    notifyListeners();
  }

  /// 启动设备照片流
  Future<void> _initiateDevicePhotoStreaming() async {
    if (_recordingDevice == null) return;
    final deviceId = _recordingDevice!.id;
    var connection = await ServiceManager.instance().device.ensureConnection(deviceId);
    if (connection == null) return;

    await connection.performCameraStartPhotoController();
    _blePhotoStream = await connection.performGetImageListener(onImageReceived: (orientedImage) async {
      final rotatedImageBytes = rotateImage(orientedImage);
      final String tempId = 'temp_img_${DateTime.now().millisecondsSinceEpoch}';
      final String base64Image = base64Encode(rotatedImageBytes);

      // Add placeholder to UI for immediate feedback
      photos.add(ConversationPhoto(id: tempId, base64: base64Image, createdAt: DateTime.now()));
      photos = List.from(photos);
      notifyListeners();

      // Chunking Logic
      const int chunkSize = 8192; // 8KB chunks
      final totalChunks = (base64Image.length / chunkSize).ceil();

      for (int i = 0; i < totalChunks; i++) {
        final start = i * chunkSize;
        final end = (start + chunkSize > base64Image.length) ? base64Image.length : start + chunkSize;
        final chunk = base64Image.substring(start, end);

        final payload = jsonEncode({
          'type': 'image_chunk',
          'id': tempId,
          'index': i,
          'total': totalChunks,
          'data': chunk,
        });

        if (_socket?.state == SocketServiceState.connected) {
          _socket?.send(payload); // Send the JSON string
        }
        await Future.delayed(const Duration(milliseconds: 20)); // Small delay to prevent flooding
      }
    });
    notifyListeners();
  }

  /// 清除转录内容
  void clearTranscripts() {
    segments = [];
    hasTranscripts = false;
    notifyListeners();
  }

  /// 开始指标跟踪
  void _startMetricsTracking() {
    _blesBytesReceived = 0;
    _wsSocketBytesSent = 0;
    _bleReceiveRateKbps = 0.0;
    _wsSendRateKbps = 0.0;
    _metricsLastCalculated = DateTime.now();

    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _calculateMetricsRates();
    });
  }

  /// 计算指标速率
  void _calculateMetricsRates() {
    final now = DateTime.now();
    if (_metricsLastCalculated == null) {
      _metricsLastCalculated = now;
      return;
    }

    final elapsedSeconds = now.difference(_metricsLastCalculated!).inMilliseconds / 1000.0;
    if (elapsedSeconds > 0) {
      // Calculate kbps (kilobits per second)
      _bleReceiveRateKbps = (_blesBytesReceived * 8) / (elapsedSeconds * 1000);
      _wsSendRateKbps = (_wsSocketBytesSent * 8) / (elapsedSeconds * 1000);

      // Reset counters for next interval
      _blesBytesReceived = 0;
      _wsSocketBytesSent = 0;
      _metricsLastCalculated = now;

      notifyListeners();
    }
  }

  /// 停止指标跟踪
  void _stopMetricsTracking() {
    _metricsTimer?.cancel();
    _metricsTimer = null;
    _blesBytesReceived = 0;
    _wsSocketBytesSent = 0;
    _bleReceiveRateKbps = 0.0;
    _wsSendRateKbps = 0.0;
    _metricsLastCalculated = null;
    notifyListeners();
  }

  /// 关闭BLE流
  Future _closeBleStream() async {
    await _bleBytesStream?.cancel();
    await _blePhotoStream?.cancel();
    _stopMetricsTracking();
    if (_recordingDevice != null) {
      var connection = await ServiceManager.instance().device.ensureConnection(_recordingDevice!.id);
      if (connection != null && await connection.hasPhotoStreamingCharacteristic()) {
        await connection.performCameraStopPhotoController();
      }
    }
    notifyListeners();
  }

  @override
  /// 销毁资源
  void dispose() {
    _bleBytesStream?.cancel();
    _blePhotoStream?.cancel();
    _socket?.unsubscribe(this);
    _keepAliveTimer?.cancel();
    _connectionStateListener?.cancel();
    _recordingTimer?.cancel();
    _metricsTimer?.cancel();

    // Remove lifecycle observer
    if (PlatformService.isDesktop) {
      WidgetsBinding.instance.removeObserver(this);
    }

    super.dispose();
  }

  /// 更新录制状态
  void updateRecordingState(RecordingState state) {
    recordingState = state;
    notifyListeners();
    _broadcastRecordingState();
  }

  /// 流式录制音频
  streamRecording() async {
    updateRecordingState(RecordingState.initialising);
    await Permission.microphone.request();

    // prepare
    await changeAudioRecordProfile(audioCodec: BleAudioCodec.pcm16, sampleRate: 16000);

    // record
    await ServiceManager.instance().mic.start(onByteReceived: (bytes) {
      if (_socket?.state == SocketServiceState.connected) {
        _socket?.send(bytes);
      }
    }, onRecording: () {
      updateRecordingState(RecordingState.record);
    }, onStop: () {
      updateRecordingState(RecordingState.stop);
    }, onInitializing: () {
      updateRecordingState(RecordingState.initialising);
    });
  }

  /// 停止流式录制音频
  stopStreamRecording() async {
    await _cleanupCurrentState();
    ServiceManager.instance().mic.stop();
    updateRecordingState(RecordingState.stop);
    await _socket?.stop(reason: 'stop stream recording');
  }

  /// 流式录制设备音频
  Future streamDeviceRecording({BtDevice? device}) async {
    debugPrint("streamDeviceRecording $device");
    if (device != null) _updateRecordingDevice(device);

    bool wasPaused = _isPaused;

    await _resetStateVariables();
    await _resetState();

    if (wasPaused) {
      await pauseDeviceRecording();
    }
  }

  /// 停止流式录制设备音频
  Future stopStreamDeviceRecording({bool cleanDevice = false}) async {
    await _cleanupCurrentState();
    if (cleanDevice) {
      _updateRecordingDevice(null);
    }
    updateRecordingState(RecordingState.stop);
    await _socket?.stop(reason: 'stop stream device recording');
  }

  /// 流式录制系统音频
  Future<void> streamSystemAudioRecording() async {
    if (!PlatformService.isDesktop) {
      notifyError('System audio recording is only available on macOS and Windows.');
      return;
    }

    updateRecordingState(RecordingState.initialising);

    _systemAudioBuffer = [];
    _systemAudioCaching = true;
    Future.delayed(const Duration(seconds: 3), () {
      _systemAudioCaching = false;
      _flushSystemAudioBuffer();
    });

    bool permissionsGranted = await _checkAndRequestSystemAudioPermissions();
    if (permissionsGranted) {
      await _startSystemAudioCapture();
    } else {
      updateRecordingState(RecordingState.stop);
    }
  }

  /// 启动系统音频捕获
  Future<void> _startSystemAudioCapture() async {
    await changeAudioRecordProfile(audioCodec: BleAudioCodec.pcm16, sampleRate: 16000);

    await ServiceManager.instance().systemAudio.start(
          onFormatReceived: (Map<String, dynamic> format) async {
            // This callback is for information only, no action needed.
          },
          onByteReceived: _processSystemAudioByteReceived,
          onRecording: () {
            updateRecordingState(RecordingState.systemAudioRecord);
            _startRecordingTimer();
            debugPrint('System audio recording started successfully.');
          },
          onStop: () {
            if (_isPaused) {
              updateRecordingState(RecordingState.pause);
            } else {
              updateRecordingState(RecordingState.stop);
            }
            _socket?.stop(reason: 'system audio stream ended from native');
          },
          onError: (error) {
            debugPrint('System audio capture error: $error');
            AppSnackbar.showSnackbarError('An error occurred during recording: $error');
            updateRecordingState(RecordingState.stop);
          },
          onSystemWillSleep: (wasRecording) {
            debugPrint('System will sleep - was recording: $wasRecording');
          },
          onSystemDidWake: (nativeIsRecording) async {
            debugPrint('System woke up - Native recording: $nativeIsRecording, Flutter state: $recordingState');
            if (!nativeIsRecording && recordingState == RecordingState.systemAudioRecord) {
              updateRecordingState(RecordingState.stop);
            }
          },
          onScreenDidLock: (wasRecording) {
            debugPrint('Screen locked - was recording: $wasRecording');
          },
          onScreenDidUnlock: () {
            debugPrint('Screen unlocked');
          },
          onDisplaySetupInvalid: (reason) {
            debugPrint('Display setup invalid: $reason');
            if (recordingState == RecordingState.systemAudioRecord) {
              updateRecordingState(RecordingState.stop);
              AppSnackbar.showSnackbarError(
                  'Recording stopped: $reason. You may need to reconnect external displays or restart recording.');
            }
          },
          onMicrophoneDeviceChanged: _onMicrophoneDeviceChanged,
          onMicrophoneStatus: _onMicrophoneStatus,
        );
  }

  /// 检查并请求系统音频权限
  Future<bool> _checkAndRequestSystemAudioPermissions() async {
    // Check microphone permission first
    String micStatus = await _screenCaptureChannel.invokeMethod('checkMicrophonePermission');
    debugPrint('Microphone permission status: $micStatus');

    if (micStatus != 'granted') {
      if (micStatus == 'undetermined' || micStatus == 'unavailable') {
        bool micGranted = await _screenCaptureChannel.invokeMethod('requestMicrophonePermission');
        if (!micGranted) {
          AppSnackbar.showSnackbarError('Microphone permission is required for system audio recording.');
          return false;
        }
      } else if (micStatus == 'denied') {
        AppSnackbar.showSnackbarError(
            'Microphone permission denied. Please grant permission in System Preferences > Privacy & Security > Microphone.');
        return false;
      }
    }

    // Check screen capture permission
    String screenStatus = await _screenCaptureChannel.invokeMethod('checkScreenCapturePermission');
    debugPrint('Screen capture permission status: $screenStatus');

    if (screenStatus != 'granted') {
      bool screenGranted = await _screenCaptureChannel.invokeMethod('requestScreenCapturePermission');
      if (!screenGranted) {
        AppSnackbar.showSnackbarError(
            'Screen recording permission is required. Please grant permission in System Preferences > Privacy & Security > Screen Recording.');
        return false;
      }
    }
    return true;
  }

  /// 处理麦克风设备变更
  Future<void> _onMicrophoneDeviceChanged() async {
    debugPrint('Microphone device changed. Restarting recording in 5 seconds...');
    bool nativeRecording = await _screenCaptureChannel.invokeMethod('isRecording') ?? false;
    if (nativeRecording) {
      _isAutoReconnecting = true;
      _reconnectCountdown = 5;
      notifyListeners();

      await pauseSystemAudioRecording(isAuto: true);

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_reconnectCountdown > 1) {
          _reconnectCountdown--;
          notifyListeners();
        } else {
          _reconnectTimer?.cancel();
          _reconnectTimer = null;
          if (_isAutoReconnecting) {
            resumeSystemAudioRecording().then((_) {
              _isAutoReconnecting = false;
              notifyListeners();
            });
          }
        }
      });
    }
  }

  /// 处理麦克风状态
  void _onMicrophoneStatus(String deviceName, double micLevel, double systemAudioLevel) {
    final bool needsUpdate = microphoneName != deviceName ||
        (microphoneLevel - micLevel).abs() > 0.001 ||
        (this.systemAudioLevel - systemAudioLevel).abs() > 0.001;

    if (needsUpdate) {
      microphoneName = deviceName;
      microphoneLevel = micLevel;
      this.systemAudioLevel = systemAudioLevel;
      notifyListeners();
    }
  }

  /// 刷新系统音频缓冲区
  void _flushSystemAudioBuffer() {
    if (_socket?.state == SocketServiceState.connected) {
      while (_systemAudioBuffer.length >= 320) {
        final chunk = _systemAudioBuffer.sublist(0, 320);
        _socket?.send(chunk);
        _systemAudioBuffer.removeRange(0, 320);
      }
    }
  }

  /// 停止系统音频录制
  Future<void> stopSystemAudioRecording() async {
    if (!PlatformService.isDesktop) return;
    _isAutoReconnecting = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    ServiceManager.instance().systemAudio.stop();
    _isPaused = false; // Clear paused state when stopping
    _stopRecordingTimer();
    await _socket?.stop(reason: 'stop system audio recording from Flutter');
    await _cleanupCurrentState();
  }

  /// 暂停系统音频录制
  Future<void> pauseSystemAudioRecording({bool isAuto = false}) async {
    if (!PlatformService.isDesktop) return;
    if (!isAuto) {
      _isAutoReconnecting = false;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
    }

    ServiceManager.instance().systemAudio.stop();
    _isPaused = true; // Set paused state
    notifyListeners();
    _broadcastRecordingState();
  }

  /// 恢复系统音频录制
  Future<void> resumeSystemAudioRecording() async {
    if (!PlatformService.isDesktop) return;
    _isPaused = false; // Clear paused state
    await streamSystemAudioRecording(); // Re-trigger the recording flow

    _broadcastRecordingState();
  }

  /// 处理浮动控制栏方法调用
  Future<void> _handleFloatingControlBarMethodCall(MethodCall call) async {
    if (!PlatformService.isDesktop) return;

    switch (call.method) {
      case 'togglePauseResume':
        if (isPaused) {
          await resumeSystemAudioRecording();
        } else if (recordingState == RecordingState.systemAudioRecord) {
          await pauseSystemAudioRecording();
        } else {
          await streamSystemAudioRecording();
        }
        break;
      default:
        Logger.debug('FloatingControlBarChannel: Unhandled method ${call.method}');
    }
  }

  @override
  /// 套接字关闭回调
  void onClosed([int? closeCode]) {
    _transcriptionServiceStatuses = [];
    _transcriptServiceReady = false;
    debugPrint('[Provider] Socket is closed with code: $closeCode');

    if (closeCode == 4002) {
      // Refresh subscription to get latest usage data which will reflect the out of credits status.
      usageProvider?.markAsOutOfCreditsAndRefresh();
    }

    notifyListeners();
    _startKeepAliveServices();
  }

  /// 启动保活服务
  void _startKeepAliveServices() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 15), (t) async {
      debugPrint("[Provider] keep alive");
      // rate 1/15s
      if (_keepAliveLastExecutedAt != null &&
          DateTime.now().subtract(const Duration(seconds: 15)).isBefore(_keepAliveLastExecutedAt!)) {
        debugPrint("[Provider] keep alive - hitting rate limits 1/15s");
        return;
      }

      _keepAliveLastExecutedAt = DateTime.now();
      if (!recordingDeviceServiceReady || _socket?.state == SocketServiceState.connected) {
        t.cancel();
        return;
      }

      if (_recordingDevice != null) {
        BleAudioCodec codec = await _getAudioCodec(_recordingDevice!.id);
        await _initiateWebsocket(audioCodec: codec, source: _getConversationSourceFromDevice());
        return;
      }
      if (recordingState == RecordingState.record) {
        await _initiateWebsocket(
            audioCodec: BleAudioCodec.pcm16, sampleRate: 16000, source: ConversationSource.phone.name);
        return;
      }
      if (recordingState == RecordingState.systemAudioRecord && PlatformService.isDesktop) {
        debugPrint("System audio socket disconnected, reconnecting...");
        await _initiateWebsocket(
            audioCodec: BleAudioCodec.pcm16, sampleRate: 16000, source: ConversationSource.desktop.name);
        return;
      }
    });
  }

  @override
  /// 套接字错误回调
  void onError(Object err) {
    _transcriptionServiceStatuses = [];
    _transcriptServiceReady = false;
    debugPrint('Socket error: $err');

    // Check for display-related errors
    if (err.toString().contains('Failed to find any displays or windows to capture')) {
      debugPrint('Display detection error in socket - likely external display disconnect');
      if (recordingState == RecordingState.systemAudioRecord) {
        AppSnackbar.showSnackbarError(
            'Display detection failed during recording. This often happens when external displays are disconnected. Recording will stop.');
        updateRecordingState(RecordingState.stop);
      }
    }

    notifyListeners();
    _startKeepAliveServices();
  }

  @override
  /// 套接字连接成功回调
  void onConnected() {
    _transcriptServiceReady = true;
    debugPrint('Socket connected');
    notifyListeners();
  }

  /// 刷新进行中的会话
  Future refreshInProgressConversations() async {
    _loadInProgressConversation();
  }

  /// 加载进行中的会话
  Future _loadInProgressConversation() async {
    var convos = await getConversations(statuses: [ConversationStatus.in_progress], limit: 1);
    _conversation = convos.isNotEmpty ? convos.first : null;
    if (_conversation != null) {
      segments = _conversation!.transcriptSegments;
      photos = _conversation!.photos;
    } else {
      segments = [];
      photos = [];
    }
    setHasTranscripts(segments.isNotEmpty);
    notifyListeners();
  }

  @override
  /// 接收到消息事件
  void onMessageEventReceived(MessageEvent event) {
    if (event is ConversationProcessingStartedEvent) {
      conversationProvider!.addProcessingConversation(event.memory);
      _resetStateVariables();
      return;
    }

    if (event is ConversationEvent) {
      event.memory.isNew = true;
      conversationProvider!.removeProcessingConversation(event.memory.id);
      _processConversationCreated(event.memory, event.messages.cast<ServerMessage>());
      return;
    }

    if (event is LastConversationEvent) {
      _handleLastConvoEvent(event.memoryId);
      return;
    }

    if (event is SpeakerLabelSuggestionEvent) {
      _handleSpeakerLabelSuggestionEvent(event);
      return;
    }

    if (event is TranslationEvent) {
      _handleTranslationEvent(event.segments);
      return;
    }

    if (event is MessageServiceStatusEvent) {
      _transcriptionServiceStatuses.add(event);
      _transcriptionServiceStatuses = List.from(_transcriptionServiceStatuses);
      notifyListeners();
      return;
    }

    if (event is PhotoProcessingEvent) {
      final tempId = event.tempId;
      final permanentId = event.photoId;
      final photoIndex = photos.indexWhere((p) => p.id == tempId);
      if (photoIndex != -1) {
        photos[photoIndex].id = permanentId;
        notifyListeners();
      }
      return;
    }

    if (event is PhotoDescribedEvent) {
      final photoId = event.photoId;
      final description = event.description;
      final discarded = event.discarded;
      final photoIndex = photos.indexWhere((p) => p.id == photoId);
      if (photoIndex != -1) {
        photos[photoIndex].description = description;
        photos[photoIndex].discarded = discarded;
        notifyListeners();
      }
      return;
    }
  }

  /// 强制处理当前会话
  Future<void> forceProcessingCurrentConversation() async {
    _resetStateVariables();
    conversationProvider!.addProcessingConversation(
      ServerConversation(
          id: '0', createdAt: DateTime.now(), structured: Structured('', ''), status: ConversationStatus.processing),
    );
    processInProgressConversation().then((result) {
      if (result == null || result.conversation == null) {
        conversationProvider!.removeProcessingConversation('0');
        return;
      }
      conversationProvider!.removeProcessingConversation('0');
      result.conversation!.isNew = true;
      _processConversationCreated(result.conversation, result.messages);
    });

    return;
  }

  /// 处理会话创建
  Future<void> _processConversationCreated(ServerConversation? conversation, List<ServerMessage> messages) async {
    if (conversation == null) return;
    conversationProvider?.upsertConversation(conversation);
    MixpanelManager().conversationCreated(conversation);
  }

  /// 处理最后的会话事件
  Future<void> _handleLastConvoEvent(String memoryId) async {
    bool conversationExists =
        conversationProvider?.conversations.any((conversation) => conversation.id == memoryId) ?? false;
    if (conversationExists) {
      return;
    }
    ServerConversation? conversation = await getConversationById(memoryId);
    if (conversation != null) {
      debugPrint("Adding last conversation to conversations: $memoryId");
      conversationProvider?.upsertConversation(conversation);
    } else {
      debugPrint("Failed to fetch last conversation: $memoryId");
    }
  }

  /// 处理翻译事件
  void _handleTranslationEvent(List<TranscriptSegment> translatedSegments) {
    try {
      if (translatedSegments.isEmpty) return;

      debugPrint("Received ${translatedSegments.length} translated segments");

      // Update the segments with the translated ones
      var remainSegments = TranscriptSegment.updateSegments(segments, translatedSegments);
      if (remainSegments.isNotEmpty) {
        debugPrint("Adding ${remainSegments.length} new translated segments");
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error handling translation event: $e");
    }
  }

  /// 处理说话者标签建议事件
  void _handleSpeakerLabelSuggestionEvent(SpeakerLabelSuggestionEvent event) {
    // Tagging
    if (taggingSegmentIds.contains(event.segmentId)) {
      return;
    }
    // If segment already exists, check if it's assigned. If so, ignore suggestion.
    var segment = segments.firstWhereOrNull((s) => s.id == event.segmentId);
    if (segment != null && segment.id.isNotEmpty && (segment.personId != null || segment.isUser)) {
      return;
    }

    // Auto-accept if enabled for new person suggestions
    if (SharedPreferencesUtil().autoCreateSpeakersEnabled) {
      assignSpeakerToConversation(event.speakerId, event.personId, event.personName, [event.segmentId]);
    } else {
      // Otherwise, store suggestion to be displayed.
      suggestionsBySegmentId[event.segmentId] = event;
      notifyListeners();
    }
  }

  /// 为会话分配说话者
  Future<void> assignSpeakerToConversation(
      int speakerId, String personId, String personName, List<String> segmentIds) async {
    if (segmentIds.isEmpty) return;

    taggingSegmentIds = List.from(segmentIds);
    notifyListeners();

    try {
      String finalPersonId = personId;

      // Create person if new
      if (finalPersonId.isEmpty) {
        Person? newPerson = await peopleProvider?.createPersonProvider(personName);
        if (newPerson != null) {
          finalPersonId = newPerson.id;
        }
      }

      // Find conversation id
      if (_conversation == null) return;

      final isAssigningToUser = finalPersonId == 'user';

      // Update local state for all segments with this speakerId
      for (var segment in segments) {
        if (segmentIds.contains(segment.id)) {
          segment.isUser = isAssigningToUser;
          segment.personId = isAssigningToUser ? null : finalPersonId;
        }
      }

      // Persist change
      await assignBulkConversationTranscriptSegments(
        _conversation!.id,
        segmentIds,
        isUser: isAssigningToUser,
        personId: isAssigningToUser ? null : finalPersonId,
      );

      // Notify backend session
      if (_socket?.state == SocketServiceState.connected) {
        final payload = jsonEncode({
          'type': 'speaker_assigned',
          'speaker_id': speakerId,
          'person_id': finalPersonId,
          'person_name': personName,
          'segment_ids': segmentIds,
        });
        _socket?.send(payload);
      }

      // Remove all suggestions for this speakerId
      suggestionsBySegmentId.removeWhere((key, value) => value.speakerId == speakerId);
    } finally {
      taggingSegmentIds = [];
      notifyListeners();
    }
  }

  @override
  /// 接收到转录段
  void onSegmentReceived(List<TranscriptSegment> newSegments) {
    _processNewSegmentReceived(newSegments);
  }

  /// 处理新接收到的转录段
  void _processNewSegmentReceived(List<TranscriptSegment> newSegments) async {
    if (newSegments.isEmpty) return;

    if (segments.isEmpty) {
      debugPrint('newSegments: ${newSegments.last}');
      if (!PlatformService.isDesktop) {
        FlutterForegroundTask.sendDataToTask(jsonEncode({'location': true}));
      }
      await _loadInProgressConversation();
    }
    var remainSegments = TranscriptSegment.updateSegments(segments, newSegments);
    segments.addAll(remainSegments);

    hasTranscripts = true;
    notifyListeners();
  }

  /// 连接状态改变
  void onConnectionStateChanged(bool isConnected) {
    debugPrint("[CaptureProvider] Internet connection changed $isConnected");
    _isConnected = isConnected;
    notifyListeners();
  }

  /// 设置是否支持WAL
  void setIsWalSupported(bool value) {
    _isWalSupported = value;
    notifyListeners();
  }

  /// 处理系统音频字节接收
  void _processSystemAudioByteReceived(Uint8List bytes) {
    _systemAudioBuffer.addAll(bytes);
    if (!_systemAudioCaching) {
      _flushSystemAudioBuffer();
    }
  }

  /// 广播录制状态
  void _broadcastRecordingState() {
    if (!PlatformService.isDesktop) return;

    final stateData = {
      'isRecording':
          recordingState == RecordingState.systemAudioRecord || recordingState == RecordingState.deviceRecord,
      'isPaused': _isPaused,
      'duration': _getRecordingDuration(),
      'isInitialising': recordingState == RecordingState.initialising,
    };

    _controlBarChannel.invokeMethod('updateRecordingState', stateData);
  }

  /// 启动录制定时器
  void _startRecordingTimer() {
    _recordingDuration = 0;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (recordingState == RecordingState.systemAudioRecord || recordingState == RecordingState.deviceRecord) {
        _recordingDuration++;
        _broadcastRecordingState();
      }
    });
  }

  /// 停止录制定时器
  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingDuration = 0;
  }

  /// 暂停设备录制
  Future<void> pauseDeviceRecording() async {
    if (_recordingDevice == null) return;

    // Pause the BLE stream but keep the device connection
    await _bleBytesStream?.cancel();
    _isPaused = true;
    updateRecordingState(RecordingState.pause);
    notifyListeners();
  }

  /// 恢复设备录制
  Future<void> resumeDeviceRecording() async {
    if (_recordingDevice == null) return;
    _isPaused = false;
    // Resume streaming from the device
    await _initiateDeviceAudioStreaming();

    final deviceId = _recordingDevice!.id;
    BleAudioCodec codec = await _getAudioCodec(deviceId);
    await _wal.getSyncs().phone.onAudioCodecChanged(codec);

    await streamAudioToWs(deviceId, codec);

    updateRecordingState(RecordingState.deviceRecord);
    notifyListeners();
  }
}
