// Note BLE Debug Provider (Note BLE 调试提供者)
// Manages BLE debug state: log entries, drawer visibility, command execution (管理 BLE 调试状态：日志条目、抽屉可见性、命令执行)

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:omi/backend/schema/bt_device/note_device.dart';
import 'package:omi/pages/note_debug/models/ble_log_entry.dart';
import 'package:omi/services/devices/note_commands.dart';
import 'package:omi/services/devices/note_connection.dart';
import 'package:omi/services/devices/transports/device_transport.dart';
import 'package:omi/services/devices/transports/note_ble_transport.dart';
import 'package:omi/providers/note_device_provider.dart';
import 'package:omi/utils/audio_converter_utils.dart';
import 'package:path_provider/path_provider.dart';

import 'base_provider.dart';

/// Provider for BLE debug functionality (BLE 调试功能的提供者)
class NoteBleDebugProvider extends BaseProvider {
  /// Device connection reference (设备连接引用)
  NoteDeviceConnection? _connection;

  /// Response stream subscription (响应流订阅)
  StreamSubscription<List<int>>? _responseSubscription;

  /// Recording stop event subscription (录音停止事件订阅)
  StreamSubscription<Map<String, dynamic>>? _recordingStopSubscription;

  /// Connection state subscription (连接状态订阅)
  StreamSubscription? _connectionStateSubscription;

  /// Pending download subscription (待下载文件订阅)
  StreamSubscription? _pendingDownloadSubscription;

  /// 待下载文件列表 (断连期间停止的录音)
  List<String> _pendingDownloadFiles = [];

  /// 实际 BLE 连接状态
  MPDeviceTransportState _bleConnectionState = MPDeviceTransportState.disconnected;

  /// Log entries list (newest first) (日志条目列表（最新的在前）)
  final List<BleLogEntry> _logEntries = [];

  /// Maximum log entries to keep (保留的最大日志条目数)
  static const int _maxLogEntries = 500;

  /// Drawer visibility state (抽屉可见性状态)
  bool _isDrawerOpen = false;

  /// Last error message (最后的错误消息)
  String? _lastError;

  /// Whether a command is being executed (是否正在执行命令)
  bool _isExecuting = false;

  // ============ Device Status ============

  /// Battery level (0-100, -1 = unknown) (电池电量（0-100，-1 = 未知）)
  int _batteryLevel = -1;

  /// Firmware version string (固件版本字符串)
  String? _firmwareVersion;

  /// Storage info (存储信息)
  NoteStorageInfo? _storageInfo;

  /// Recording state (null = unknown, true = recording, false = not recording) (录音状态（null = 未知，true = 正在录音，false = 未录音）)
  bool? _isRecording;

  // ============ Audio Debug Save ============

  /// Audio stream subscription for saving (音频流订阅，用于保存)
  StreamSubscription<List<int>>? _audioSaveSubscription;

  /// Whether audio is being saved (是否正在保存音频)
  bool _isSavingAudio = false;

  /// File for saving audio data (保存音频数据的文件)
  IOSink? _audioFileSink;

  /// Path to saved audio file (保存的音频文件路径)
  String? _savedAudioPath;

  /// Bytes saved count (已保存字节数)
  int _audioBytesSaved = 0;

  /// Packets received count (已接收包数)
  int _audioPacketsReceived = 0;

  // ============ 文件下载转码状态 ============

  /// 当前下载转码阶段 (null = 未进行)
  DownloadConvertStage? _downloadConvertStage;

  /// 下载转码进度 (0.0 - 1.0)
  double _downloadConvertProgress = 0.0;

  /// 转码完成的 MP3 路径
  String? _convertedMp3Path;

  /// 下载转码错误
  String? _downloadConvertError;

  // ============ Getters ============

  /// Get log entries (unmodifiable) (获取日志条目（不可修改）)
  List<BleLogEntry> get logEntries => List.unmodifiable(_logEntries);

  /// Whether the drawer is open (抽屉是否打开)
  bool get isDrawerOpen => _isDrawerOpen;

  /// Last error message (最后的错误消息)
  String? get lastError => _lastError;

  /// Whether a command is being executed (是否正在执行命令)
  bool get isExecuting => _isExecuting;

  /// Whether connected to a device (是否已连接到设备)
  bool get isConnected => _bleConnectionState == MPDeviceTransportState.connected;

  /// 实际 BLE 连接状态
  MPDeviceTransportState get bleConnectionState => _bleConnectionState;

  /// Battery level (0-100, -1 = unknown) (电池电量（0-100，-1 = 未知）)
  int get batteryLevel => _batteryLevel;

  /// Firmware version (固件版本)
  String? get firmwareVersion => _firmwareVersion;

  /// Storage info (存储信息)
  NoteStorageInfo? get storageInfo => _storageInfo;

  /// Recording state (null = unknown) (录音状态（null = 未知）)
  bool? get isRecording => _isRecording;

  /// Whether audio is being saved (是否正在保存音频)
  bool get isSavingAudio => _isSavingAudio;

  /// Path to saved audio file (保存的音频文件路径)
  String? get savedAudioPath => _savedAudioPath;

  /// Bytes saved (已保存字节数)
  int get audioBytesSaved => _audioBytesSaved;

  /// Packets received (已接收包数)
  int get audioPacketsReceived => _audioPacketsReceived;

  /// 下载转码阶段 (null = 未进行)
  DownloadConvertStage? get downloadConvertStage => _downloadConvertStage;

  /// 下载转码进度 (0.0 - 1.0)
  double get downloadConvertProgress => _downloadConvertProgress;

  /// 转码完成的 MP3 路径
  String? get convertedMp3Path => _convertedMp3Path;

  /// 下载转码错误
  String? get downloadConvertError => _downloadConvertError;

  /// 是否正在下载转码
  bool get isDownloadConverting => _downloadConvertStage != null;

  /// 待下载文件列表
  List<String> get pendingDownloadFiles => _pendingDownloadFiles;

  // ============ Seq 状态 (供补传调试) ============

  /// 当前实时音频 lastSeq
  int get lastCompletedSeq => _connection?.bleTransport.lastCompletedSeq ?? -1;

  /// 已完成帧数
  int get completedFrameCount => _connection?.bleTransport.completedFrameCount ?? 0;

  /// Seq 间隙列表
  List<SeqGapRecord> get seqGaps => _connection?.getSeqGaps() ?? [];

  // ============ Connection Management ============

  /// Set the device connection (设置设备连接)
  void setConnection(NoteDeviceConnection? connection) {
    _connection = connection;
    _setupResponseListener();
    _setupRecordingStopListener();
    _setupConnectionStateListener();
    _setupPendingDownloadListener();
    if (_connection != null) {
      _bleConnectionState = MPDeviceTransportState.connected;
    }
    notifyListeners();
  }

  /// Setup response stream listener (设置响应流监听器)
  void _setupResponseListener() {
    _responseSubscription?.cancel();
    if (_connection != null) {
      _responseSubscription = _connection!.bleTransport.responseStream.listen(
        (data) => _addLogEntry(BleLogDirection.received, data),
      );
    }
  }

  /// 监听设备主动停止录音事件 (unsolicited 0x02 通知)
  void _setupRecordingStopListener() {
    _recordingStopSubscription?.cancel();
    if (_connection != null) {
      _recordingStopSubscription = _connection!.onRecordingStopped.listen((result) {
        print('[NoteBleDebugProvider] 收到设备主动停止录音: $result');
        if (result['success'] == true) {
          _isRecording = false;
          _lastRecordingFileName = result['fileName'] as String?;
          notifyListeners();

          // 自动触发下载转码
          if (_lastRecordingFileName != null && _lastRecordingFileName!.isNotEmpty) {
            _startDownloadAndConvert(_lastRecordingFileName!);
          }
        }
      });
    }
  }

  /// 监听实际 BLE 连接状态变化
  void _setupConnectionStateListener() {
    _connectionStateSubscription?.cancel();
    if (_connection != null) {
      _connectionStateSubscription = _connection!.bleTransport.connectionStateStream.listen((state) {
        final oldState = _bleConnectionState;
        _bleConnectionState = state;
        if (oldState != state) {
          print('[NoteBleDebugProvider] BLE 状态变化: $oldState → $state');
          _addLogEntry(BleLogDirection.received, [], name: 'BLE: ${state.name}');
          notifyListeners();
        }
      });
    }
  }

  /// 监听重连后待下载文件通知
  void _setupPendingDownloadListener() {
    _pendingDownloadSubscription?.cancel();
    if (_connection != null) {
      _pendingDownloadSubscription = _connection!.onPendingDownloads.listen((files) {
        _pendingDownloadFiles = List.from(files);
        print('[NoteBleDebugProvider] 重连后待下载文件: $files');
        _addLogEntry(BleLogDirection.received, [], name: '重连: ${files.length} 个文件待下载');

        // 自动下载转码待下载文件
        for (final fileName in files) {
          _startDownloadAndConvert(fileName);
        }
        _connection?.clearPendingDownloads();
        notifyListeners();
      });
    }
  }

  // ============ Log Management ============

  /// Add a log entry (添加日志条目)
  void _addLogEntry(BleLogDirection direction, List<int> data, {String? name}) {
    _logEntries.insert(
      0,
      BleLogEntry(timestamp: DateTime.now(), direction: direction, data: List<int>.from(data), commandName: name),
    );

    // Keep max entries (保持最大条目数)
    if (_logEntries.length > _maxLogEntries) {
      _logEntries.removeLast();
    }

    notifyListeners();
  }

  /// Clear all log entries (清除所有日志条目)
  void clearLogs() {
    _logEntries.clear();
    notifyListeners();
  }

  // ============ Drawer Control ============

  /// Toggle drawer visibility (切换抽屉可见性)
  void toggleDrawer() {
    _isDrawerOpen = !_isDrawerOpen;
    notifyListeners();
  }

  /// Open the drawer (打开抽屉)
  void openDrawer() {
    _isDrawerOpen = true;
    notifyListeners();
  }

  /// Close the drawer (关闭抽屉)
  void closeDrawer() {
    _isDrawerOpen = false;
    notifyListeners();
  }

  // ============ Command Execution ============

  /// Execute a command and log it (执行命令并记录日志)
  Future<void> executeCommand(List<int> command, String commandName) async {
    if (_connection == null) {
      _lastError = 'Device not connected';
      notifyListeners();
      return;
    }

    _isExecuting = true;
    _lastError = null;
    notifyListeners();

    try {
      // Log the sent command (记录发送的命令)
      _addLogEntry(BleLogDirection.sent, command, name: commandName);

      // Send command and wait for response (发送命令并等待响应)
      await _connection!.sendCommandWithResponse(command);
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  // ============ Recording Commands ============

  /// Send start recording command (0x01) and track state (发送开始录音命令（0x01）并跟踪状态)
  Future<void> sendStartRecording() async {
    if (_connection == null) {
      _lastError = 'Device not connected';
      notifyListeners();
      return;
    }

    _isExecuting = true;
    _lastError = null;
    notifyListeners();

    try {
      _addLogEntry(BleLogDirection.sent, [NoteCommands.startRecording], name: 'Start Recording');
      final result = await _connection!.startRecordingWithStatus();
      switch (result) {
        case RecordingStartResult.success:
          _isRecording = true;
          print('[NoteBleDebugProvider] Recording started');
          break;
        case RecordingStartResult.alreadyRecording:
          _isRecording = true;
          print('[NoteBleDebugProvider] Device already recording');
          break;
        case RecordingStartResult.failed:
          _isRecording = false;
          _lastError = 'Failed to start recording';
          print('[NoteBleDebugProvider] Recording failed');
          break;
      }
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  /// Send stop recording command (0x02) and track state (发送停止录音命令（0x02）并跟踪状态)
  Future<void> sendStopRecording() async {
    if (_connection == null) {
      _lastError = 'Device not connected';
      notifyListeners();
      return;
    }

    _isExecuting = true;
    _lastError = null;
    notifyListeners();

    try {
      _addLogEntry(BleLogDirection.sent, [NoteCommands.stopRecording], name: 'Stop Recording');
      final result = await _connection!.stopRecording();
      if (result['success'] == true) {
        _isRecording = false;
        _lastRecordingFileName = result['fileName'] as String?;
        print('[NoteBleDebugProvider] Recording stopped, file=$_lastRecordingFileName, lastSeq=$lastCompletedSeq');

        // 自动触发文件下载并转码为 MP3
        if (_lastRecordingFileName != null && _lastRecordingFileName!.isNotEmpty) {
          _isExecuting = false;
          notifyListeners();
          _startDownloadAndConvert(_lastRecordingFileName!);
          return;
        }
      }
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  Future<void> sendQueryRecordingStatus() async {
    if (_connection == null) {
      _lastError = 'Device not connected';
      notifyListeners();
      return;
    }

    _isExecuting = true;
    final status = await _connection!.queryRecordStatus();
    print('[NoteBleDebugProvider] Recording status: $status');
  }

  /// Send set recording mode command (0x0D + mode) (发送设置录音模式命令（0x0D + 模式）)
  Future<void> sendSetRecordingMode(NoteRecordingMode mode) async {
    if (_connection == null) {
      _lastError = 'Device not connected';
      notifyListeners();
      return;
    }

    _isExecuting = true;
    _lastError = null;
    notifyListeners();

    try {
      _addLogEntry(BleLogDirection.sent, [
        NoteCommands.setRecordingMode,
        mode.value,
      ], name: 'Set Mode: ${mode.description}');
      final success = await _connection!.setRecordingMode(mode);
      if (success) {
        print('[NoteBleDebugProvider] Recording mode set: ${mode.description}');
      } else {
        _lastError = 'Failed to set recording mode';
        print('[NoteBleDebugProvider] Failed to set recording mode');
      }
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  // ============ Device Info Commands ============

  /// Send query battery command (0xE1) and save result (发送查询电池命令（0xE1）并保存结果)
  Future<void> sendQueryBattery() async {
    if (_connection == null) {
      _lastError = 'Device not connected';
      notifyListeners();
      return;
    }

    _isExecuting = true;
    _lastError = null;
    notifyListeners();

    try {
      _addLogEntry(BleLogDirection.sent, [NoteCommands.queryBattery], name: 'Query Battery');
      _batteryLevel = await _connection!.performRetrieveBatteryLevel();
      print('[NoteBleDebugProvider] Battery level: $_batteryLevel%');
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  /// Send query version command (0xE3) and save result (发送查询版本命令（0xE3）并保存结果)
  Future<void> sendQueryVersion() async {
    if (_connection == null) {
      _lastError = 'Device not connected';
      notifyListeners();
      return;
    }

    _isExecuting = true;
    _lastError = null;
    notifyListeners();

    try {
      _addLogEntry(BleLogDirection.sent, [NoteCommands.queryVersion], name: 'Query Version');
      _firmwareVersion = await _connection!.queryFirmwareVersion();
      print('[NoteBleDebugProvider] Firmware version: $_firmwareVersion');
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  /// Send query storage command (0xE8) and save result (发送查询存储命令（0xE8）并保存结果)
  Future<void> sendQueryStorage() async {
    if (_connection == null) {
      _lastError = 'Device not connected';
      notifyListeners();
      return;
    }

    _isExecuting = true;
    _lastError = null;
    notifyListeners();

    try {
      _addLogEntry(BleLogDirection.sent, [NoteCommands.queryStorage], name: 'Query Storage');
      _storageInfo = await _connection!.queryStorage();
      print('[NoteBleDebugProvider] Storage: ${_storageInfo!.usedKB}/${_storageInfo!.totalKB} KB');
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  // ============ File Management Commands ============

  /// Send get file list command (0x03) (发送获取文件列表命令（0x03）)
  Future<void> sendGetFileList() async {
    await executeCommand([NoteCommands.getFileList], 'Get File List');
  }

  // ============ Device Control Commands ============

  /// Send sync RTC command (0xE5 + timestamp) (发送同步 RTC 命令（0xE5 + 时间戳）)
  Future<void> sendSyncRTC() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await executeCommand([
      NoteCommands.syncRTC,
      (timestamp >> 24) & 0xFF,
      (timestamp >> 16) & 0xFF,
      (timestamp >> 8) & 0xFF,
      timestamp & 0xFF,
    ], 'Sync RTC');
  }

  /// Send bind device command (0x0B 0x01) (发送绑定设备命令（0x0B 0x01）)
  Future<void> sendBindDevice() async {
    await executeCommand([NoteCommands.bindDevice, 0x01], 'Bind Device');
  }

  /// Send unbind device command (0x0B 0x00) (发送解绑设备命令（0x0B 0x00）)
  Future<void> sendUnbindDevice() async {
    await executeCommand([NoteCommands.bindDevice, 0x00], 'Unbind Device');
  }

  /// Send USB mode command (0xE4 + enabled) (发送 USB 模式命令（0xE4 + 启用状态）)
  Future<void> sendSetUsbMode(bool enabled) async {
    await executeCommand([NoteCommands.usbMode, enabled ? 0x01 : 0x00], 'USB Mode: ${enabled ? "ON" : "OFF"}');
  }

  /// Send reboot command (0x09) (发送重启命令（0x09）)
  Future<void> sendReboot() async {
    await executeCommand([NoteCommands.reboot], 'Reboot');
  }

  /// Send factory reset command (0xE9 + param) (发送恢复出厂设置命令（0xE9 + 参数）)
  Future<void> sendFactoryReset(bool keepRecordings) async {
    await executeCommand([
      NoteCommands.factoryReset,
      keepRecordings ? 0x00 : 0xFF,
    ], 'Factory Reset (keep=$keepRecordings)');
  }

  // ============ OTA Commands ============

  /// Send enter OTA command (0xE6 + module) (发送进入 OTA 命令（0xE6 + 模块）)
  Future<void> sendOtaEnter(NoteOtaModule module) async {
    await executeCommand([NoteCommands.otaEnter, module.value], 'Enter OTA: ${module.moduleName}');
  }

  // ============ Custom Command ============

  /// Send custom hex command (发送自定义十六进制命令)
  Future<void> sendCustomCommand(String hexString) async {
    try {
      final bytes = hexString.split(RegExp(r'[\s,]+')).where((s) => s.isNotEmpty).map((s) {
        // Support both "0xFF" and "FF" formats (支持 "0xFF" 和 "FF" 两种格式)
        final cleaned = s.startsWith('0x') || s.startsWith('0X') ? s.substring(2) : s;
        return int.parse(cleaned, radix: 16);
      }).toList();

      if (bytes.isEmpty) {
        _lastError = 'Invalid hex string';
        notifyListeners();
        return;
      }

      await executeCommand(bytes, 'Custom: $hexString');
    } catch (e) {
      _lastError = 'Parse error: $e';
      notifyListeners();
    }
  }

  // ============ Audio Debug Save ============

  /// Start saving audio stream to file (开始保存音频流到文件)
  Future<void> startSavingAudio() async {
    if (_connection == null) {
      _lastError = 'Device not connected';
      notifyListeners();
      return;
    }

    if (_isSavingAudio) {
      print('[AudioDebug] Already saving audio');
      return;
    }

    try {
      // Create file path with timestamp - save to sdcard (external storage)
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      }
      directory ??= await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      _savedAudioPath = '${directory.path}/audio_debug_$timestamp.opus';

      // Open file for writing
      final file = File(_savedAudioPath!);
      _audioFileSink = file.openWrite();

      // Reset counters
      _audioBytesSaved = 0;
      _audioPacketsReceived = 0;
      DateTime? _lastLogTime;

      // Subscribe to audio stream
      print('[AudioDebug] 开始订阅 bleTransport.audioStream...');
      _audioSaveSubscription = _connection!.bleTransport.audioStream.listen(
        (data) {
          _audioPacketsReceived++;
          _audioBytesSaved += data.length;
          _audioFileSink?.add(data);

          // 前10个包每个都打印，之后每10秒打印一次
          final now = DateTime.now();
          final shouldLog =
              _audioPacketsReceived <= 10 || _lastLogTime == null || now.difference(_lastLogTime!).inSeconds >= 10;
          if (shouldLog) {
            print('[AudioDebug] 保存包#$_audioPacketsReceived: ${data.length}bytes, 总计=$_audioBytesSaved bytes');
            _lastLogTime = now;
            notifyListeners();
          }
        },
        onError: (error, stackTrace) {
          print('[AudioDebug] ❌ 音频流错误: $error');
          print('[AudioDebug] ❌ 堆栈: $stackTrace');
          print('[AudioDebug] ❌ 已收到 $_audioPacketsReceived 包后出错');
          _lastError = 'Audio stream error: $error';
          notifyListeners();
        },
        onDone: () {
          print('[AudioDebug] ⚠️ 音频流结束(onDone)! 共收到 $_audioPacketsReceived 包, $_audioBytesSaved bytes');
          print('[AudioDebug] ⚠️ 这可能表示: 1)设备停止发送 2)BLE订阅被取消 3)设备断开连接');
          _lastError = '音频流已结束 (共 $_audioPacketsReceived 包)';
          notifyListeners();
        },
        cancelOnError: false,
      );
      print('[AudioDebug] ✓ 音频流订阅已建立');

      _isSavingAudio = true;
      print('[AudioDebug] 开始保存音频到: $_savedAudioPath');
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to start saving: $e';
      print('[AudioDebug] Error: $e');
      notifyListeners();
    }
  }

  /// Stop saving audio stream (停止保存音频流)
  Future<void> stopSavingAudio() async {
    if (!_isSavingAudio) {
      return;
    }

    try {
      // Cancel subscription
      await _audioSaveSubscription?.cancel();
      _audioSaveSubscription = null;

      // Close file
      await _audioFileSink?.flush();
      await _audioFileSink?.close();
      _audioFileSink = null;

      _isSavingAudio = false;

      print('[AudioDebug] 停止保存音频');
      print('[AudioDebug] 总计: $_audioPacketsReceived 包, $_audioBytesSaved bytes');
      print('[AudioDebug] 文件: $_savedAudioPath');

      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to stop saving: $e';
      print('[AudioDebug] Error: $e');
      notifyListeners();
    }
  }

  /// 转换已保存的实时音频文件为 WAV，验证正确性
  Future<void> convertSavedAudio() async {
    if (_savedAudioPath == null || _savedAudioPath!.isEmpty) {
      print('[AudioDebug] 没有已保存的音频文件');
      return;
    }

    final file = File(_savedAudioPath!);
    if (!file.existsSync()) {
      print('[AudioDebug] 文件不存在: $_savedAudioPath');
      return;
    }

    final fileSize = file.lengthSync();
    final expectedFrames = fileSize ~/ 40;
    final expectedDuration = expectedFrames * 0.02;
    print('[AudioDebug] 开始转换: $_savedAudioPath');
    print('[AudioDebug] 文件大小: $fileSize bytes, 预期: $expectedFrames 帧, ${expectedDuration.toStringAsFixed(1)}s');

    try {
      final converter = AudioConverterUtils();
      final mp3Path = await converter.convertOpusToMp3(
        opusFilePath: _savedAudioPath!,
        sampleRate: 16000,
        channels: 1,
        onProgress: (p) {
          if (p == 0.3 || p >= 1.0) {
            print('[AudioDebug] 转换进度: ${(p * 100).toInt()}%');
          }
        },
      );
      print('[AudioDebug] ✓ 转换完成: $mp3Path');

      // 检查 WAV 中间文件的时长
      final wavPath = _savedAudioPath!.replaceAll('.opus', '.wav');
      final wavFile = File(wavPath);
      if (wavFile.existsSync()) {
        final wavSize = wavFile.lengthSync();
        final pcmSize = wavSize - 44; // 减去 WAV 头
        final wavDuration = pcmSize / (16000 * 2); // 16kHz, 16bit mono
        print(
          '[AudioDebug] ✓ WAV 时长: ${wavDuration.toStringAsFixed(1)}s '
          '(预期: ${expectedDuration.toStringAsFixed(1)}s, '
          '误差: ${(wavDuration - expectedDuration).abs().toStringAsFixed(1)}s)',
        );
      }
    } catch (e) {
      print('[AudioDebug] ❌ 转换失败: $e');
    }
  }

  // ============ 文件下载转码 ============

  /// 自动下载并转码录音文件为 MP3
  /// 在 sendStopRecording 成功后自动调用
  Future<void> _startDownloadAndConvert(String fileName) async {
    if (_connection == null) return;

    // 重置状态
    _downloadConvertStage = DownloadConvertStage.downloading;
    _downloadConvertProgress = 0.0;
    _convertedMp3Path = null;
    _downloadConvertError = null;
    notifyListeners();

    try {
      // 复用 NoteDeviceProvider 的下载转码逻辑
      // 但直接使用 connection 避免 provider 依赖
      final downloadDir = await _getDownloadDirectory();
      final filePath = '${downloadDir.path}/$fileName';

      // 阶段 1: 下载
      await _downloadFile(fileName, filePath);

      // 阶段 2: 转码
      _downloadConvertStage = DownloadConvertStage.converting;
      _downloadConvertProgress = 0.0;
      notifyListeners();

      final converter = AudioConverterUtils();
      final mp3Path = await converter.convertOpusToMp3(
        opusFilePath: filePath,
        sampleRate: 16000,
        channels: 1,
        onProgress: (progress) {
          _downloadConvertProgress = progress;
          notifyListeners();
        },
      );

      _convertedMp3Path = mp3Path;
      _downloadConvertStage = null;
      _downloadConvertProgress = 1.0;
      print('[NoteBleDebugProvider] 转码完成: $mp3Path');
      _addLogEntry(BleLogDirection.received, [], name: 'MP3 ready: ${mp3Path.split('/').last}');
    } catch (e) {
      _downloadConvertError = e.toString();
      _downloadConvertStage = null;
      print('[NoteBleDebugProvider] 下载转码失败: $e');
    } finally {
      notifyListeners();
    }
  }

  /// 从设备下载文件到本地
  Future<void> _downloadFile(String fileName, String filePath) async {
    final outputFile = File(filePath);
    final sink = outputFile.openWrite();
    final completer = Completer<void>();
    int downloadedBytes = 0;

    final fileSubscription = _connection!.bleTransport.fileStream.listen((data) {
      sink.add(data is Uint8List ? data : Uint8List.fromList(data));
      downloadedBytes += data.length;
    });

    final responseSubscription = _connection!.bleTransport.responseStream.listen((data) {
      if (data.length >= 2 && data[0] == 0x04 && data[1] == 0x02) {
        if (!completer.isCompleted) completer.complete();
      }
    });

    try {
      final success = await _connection!.uploadFile(fileName);
      if (!success) throw Exception('文件请求失败: $fileName');

      _addLogEntry(BleLogDirection.sent, [0x04], name: 'Download: $fileName');

      await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw TimeoutException('文件下载超时: $fileName'),
      );

      await sink.flush();
      await sink.close();
      print('[NoteBleDebugProvider] 文件下载完成: $filePath ($downloadedBytes bytes)');

      _downloadConvertProgress = 1.0;
      notifyListeners();
    } catch (e) {
      await sink.close();
      if (await outputFile.exists()) await outputFile.delete();
      rethrow;
    } finally {
      await fileSubscription.cancel();
      await responseSubscription.cancel();
    }
  }

  /// 获取下载目录
  Future<Directory> _getDownloadDirectory() async {
    Directory? baseDir;
    if (Platform.isAndroid) {
      baseDir = await getExternalStorageDirectory();
      if (baseDir != null) baseDir = baseDir.parent;
    }
    baseDir ??= await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${baseDir.path}/NoteDownloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  // ============ 补传测试 ============

  /// 最近一次录音的文件名 (停止录音后记录)
  String? _lastRecordingFileName;
  String? get lastRecordingFileName => _lastRecordingFileName;

  /// 手动发起补传请求，用于验证补传数据格式
  Future<void> testRetransmit(String fileName, int startSeq, int endSeq) async {
    if (_connection == null) {
      print('[RetransmitTest] 设备未连接');
      return;
    }

    print('[RetransmitTest] ════════════════════════════════════');
    print('[RetransmitTest] 发起补传: file=$fileName, range=$startSeq~$endSeq');
    print('[RetransmitTest] 当前 lastSeq=$lastCompletedSeq, 完成帧=$completedFrameCount');

    final success = await _connection!.requestRetransmit(fileName, startSeq, endSeq);
    if (success) {
      print('[RetransmitTest] ✓ 补传请求已发送，等待 UUID 303 响应...');
    } else {
      print('[RetransmitTest] ❌ 补传请求发送失败');
    }
  }

  /// 模拟断开连接 (保留 seq 状态用于补传测试)
  Future<void> simulateDisconnect() async {
    if (_connection == null) return;

    final seq = lastCompletedSeq;
    final gaps = seqGaps;
    print('[RetransmitTest] 模拟断开: lastSeq=$seq, gaps=${gaps.length}');
    print('[RetransmitTest] 设备将继续录音，重连后可测试补传');

    await _connection!.bleTransport.disconnect();
    notifyListeners();
  }

  // ============ Lifecycle ============

  @override
  void dispose() {
    _responseSubscription?.cancel();
    _recordingStopSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _pendingDownloadSubscription?.cancel();
    _audioSaveSubscription?.cancel();
    _audioFileSink?.close();
    super.dispose();
  }
}
