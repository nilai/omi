/// Note 设备连接层
/// 实现设备级别的命令控制、响应处理、状态管理
library;

import 'dart:async';
import 'dart:convert';
import 'package:omi/backend/schema/bt_device/bt_device.dart';
import 'package:omi/backend/schema/bt_device/note_device.dart';
import 'package:omi/services/devices.dart';
import 'package:omi/services/devices/device_connection.dart';
import 'package:omi/services/devices/models.dart';
import 'package:omi/services/devices/transports/note_ble_transport.dart';
import 'package:omi/services/devices/transports/device_transport.dart';
import 'package:omi/services/devices/note_commands.dart';
import 'package:omi/services/devices/note_audio_file_writer.dart';
import 'package:omi/services/devices/note_storage_manager.dart';

/// 录音开始结果枚举
enum RecordingStartResult {
  /// 录音成功开始
  success,
  /// 设备已在录音
  alreadyRecording,
  /// 录音失败
  failed,
}

/// Note 设备连接类
///
/// 功能:
/// - 设备连接初始化(RTC同步、绑定检查)
/// - 设备信息查询(电量、版本、存储)
/// - 设备配置(录音模式)
/// - 录音控制(开始、停止)
/// - 文件管理(列表、上传、删除)
/// - 设备管理(绑定、解绑、重启、恢复出厂)
class NoteDeviceConnection extends DeviceConnection {
  final NoteBleTransport _transport;
  final NoteStorageManager _storage = NoteStorageManager();

  /// 自动重连定时器
  Timer? _autoReconnectTimer;

  /// 响应等待队列
  Completer<List<int>>? _responseCompleter;

  /// 连接初始化标志
  bool _isInitialized = false;

  // ============ #2: 文件列表分包处理 ============

  /// 文件列表响应缓存（用于收集多个分包）
  final List<List<int>> _fileListPackets = [];

  /// 分包超时定时器
  Timer? _packetTimeoutTimer;

  /// 文件列表分包超时时间 (毫秒)
  static const int _kFileListTimeoutMs = 500;

  // ============ #7: 自动重连相关 ============

  /// 自动重连间隔 (秒)
  static const int _kAutoReconnectIntervalSec = 5;

  /// 是否启用自动重连
  bool _autoReconnectEnabled = false;

  /// 连接状态回调
  void Function(String deviceId, DeviceConnectionState state)? _connectionStateCallback;

  // ============ 录音停止事件 ============

  /// 录音停止事件流 (含 unsolicited 设备主动停止)
  /// 事件数据格式同 stopRecording() 返回的 Map
  final _recordingStopController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onRecordingStopped => _recordingStopController.stream;

  /// 重连后需要下载的文件事件流
  final _pendingDownloadController = StreamController<List<String>>.broadcast();
  Stream<List<String>> get onPendingDownloads => _pendingDownloadController.stream;

  /// 获取待下载文件列表
  List<String> get pendingDownloadFiles => List.unmodifiable(_pendingDownloadFiles);

  /// 清除待下载文件列表
  void clearPendingDownloads() => _pendingDownloadFiles.clear();

  NoteDeviceConnection(BtDevice device, this._transport) : super(device, _transport) {
    _setupResponseListener();
    _setupConnectionStateListener();
  }

  /// 当前录音文件名 (开始录音时记录，用于断连时保存补传状态)
  String? _currentRecordingFileName;

  /// 当前录音业务类型 (normal / memo)，从开始录音通知 byte[3] 解析
  NoteRecordingType? _currentRecordingType;

  /// 当前录音业务类型 (供上层只读)
  NoteRecordingType? get currentRecordingType => _currentRecordingType;

  /// 录音开始事件流 (含 unsolicited 设备按键触发 / split 续录)
  final _recordingStartController =
      StreamController<({String fileName, NoteRecordingType type})>.broadcast();
  Stream<({String fileName, NoteRecordingType type})> get onRecordingStarted =>
      _recordingStartController.stream;

  /// 待下载的文件列表 (断连期间停止的录音文件，需从设备下载完整版)
  final List<String> _pendingDownloadFiles = [];

  /// 实时音频文件写入器
  NoteAudioFileWriter? _audioFileWriter;

  /// 带 Seq 的音频流订阅 (用于写文件)
  StreamSubscription? _seqAudioSubscription;

  /// 设置连接状态监听器（用于自动重连）
  void _setupConnectionStateListener() {
    _transport.connectionStateStream.listen((state) async {
      if (state == DeviceTransportState.disconnected) {
        // 断连时保存 Seq 状态，供重连后补传使用
        await _saveRetransmitStateOnDisconnect();

        if (_autoReconnectEnabled) {
          print('[NoteConnection] 连接断开，启动自动重连');
          _startAutoReconnect();
        }
      }
    });
  }

  /// 断连时保存补传状态
  Future<void> _saveRetransmitStateOnDisconnect() async {
    final lastSeq = _transport.lastCompletedSeq;
    final fileName = _currentRecordingFileName;
    if (fileName != null && fileName.isNotEmpty && lastSeq >= 0) {
      await _storage.saveRetransmitState(fileName, lastSeq);
      print('[NoteConnection] 断连，已保存补传状态: file=$fileName, lastSeq=$lastSeq');
    }
  }

  /// 设置响应监听器
  void _setupResponseListener() {
    _transport.responseStream.listen((response) {
      _handleIncomingPacket(response);
    });
  }

  /// #2: 处理接收到的数据包（支持文件列表分包和补传响应）
  void _handleIncomingPacket(List<int> packet) {
    if (packet.isEmpty) return;

    final hexString = packet.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
    print('[NoteConnection] 收到数据包: $hexString');

    // 处理文件列表命令 (0x03) 的分包
    if (packet[0] == 0x03) {
      // 03 00 = 无文件, 03 ff = 结束标记
      if (packet.length == 2 && (packet[1] == 0x00 || packet[1] == 0xff)) {
        _cancelPacketTimeout();
        _completeFileListResponse();
        return;
      }

      // 文件数据包（03 [本包数量] [文件信息...]），收集起来
      if (packet.length > 2) {
        _fileListPackets.add(List.from(packet));
        // 重置超时，等待更多包
        _startPacketTimeout();
        print('[NoteConnection] 收集文件包，本包数量: ${packet[1]}');
        return;
      }
    }

    // 处理补传响应 (0x20/0x21/0x22 via tx UUID 303)
    if (packet[0] == NoteCommands.retransmitRequest ||
        packet[0] == NoteCommands.retransmitErrorNoFile ||
        packet[0] == NoteCommands.retransmitErrorBadRange) {
      _handleRetransmitResponse(packet);
      return;
    }

    // 开始录音通知: 可能是 APP 主动 startRecording 的回复，也可能是设备按键 / split 续录的 unsolicited
    // 协议: 01 01 [record_state] [mode] [file_name...]
    if (packet[0] == 0x01 && packet.length >= 4 && packet[1] == 0x01) {
      _cancelPacketTimeout();
      if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
        // 有等待者 (APP 主动调用) — 交给 startRecordingWithStatus 解析
        _responseCompleter!.complete(packet);
      } else {
        // 无等待者 — 设备按键启动 / split 续录
        final mode = NoteRecordingType.fromValue(packet[3]);
        final fileName = packet.length > 4
            ? String.fromCharCodes(packet.sublist(4))
            : '';
        print('[NoteConnection] 设备主动开始录音 (${mode.description}): $fileName');
        _applyRecordingStarted(fileName, mode);
      }
      _handleResponse(packet);
      return;
    }

    // 停止录音响应: 可能是手动停止的回复，也可能是设备主动停止 (unsolicited)
    if (packet[0] == 0x02 && packet.length >= 3) {
      _cancelPacketTimeout();
      if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
        // 有等待者 (手动 stopRecording 调用) — 交给 completer，stopRecording() 自行解析
        _responseCompleter!.complete(packet);
      } else {
        // 无等待者 — 设备主动停止 (unsolicited)，解析并通知
        final result = _parseStopRecordingResponse(packet);
        if (result['success'] == true) {
          _stopAudioFileWriter();
          _currentRecordingFileName = null;
          _currentRecordingType = null;
          _storage.clearRetransmitState();
        }
        print('[NoteConnection] 设备主动停止录音: $result');
        _recordingStopController.add(result);
      }
      _handleResponse(packet);
      return;
    }

    // 其他命令正常处理
    _cancelPacketTimeout();
    if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
      _responseCompleter!.complete(packet);
    }
    _handleResponse(packet);
  }

  /// 处理补传响应
  void _handleRetransmitResponse(List<int> packet) {
    final cmd = packet[0];

    if (cmd == NoteCommands.retransmitRequest && packet.length >= 6) {
      // 补传数据包: [Cmd=0x20] [Seq 4B] [Flag 1B] [Data...]
      // 或补传完成通知: [Cmd=0x20] [FileNameLen] [FileName] [StartSeq 4B] [EndSeq 4B]
      if (packet.length > 6) {
        // 区分数据包和完成通知:
        // 数据包第5字节是 Flag (分包标志)，完成通知第1字节是 FileNameLen (较小值)
        final possibleNameLen = packet[1];

        // 如果第1字节 <= 32 (合法文件名长度) 且总长度匹配文件名+8字节(StartSeq+EndSeq)
        if (possibleNameLen > 0 && possibleNameLen <= 32 &&
            packet.length == 2 + possibleNameLen + 8) {
          // 补传完成通知 — 验证文件名是否为可打印字符
          final nameLen = possibleNameLen;
          final nameBytes = packet.sublist(2, 2 + nameLen);
          final looksLikeFileName = nameBytes.every((b) => b >= 0x20 && b < 0x7F);
          if (!looksLikeFileName) {
            // 不像文件名，当作补传数据包处理
            _transport.processRetransmitAudioData(packet.sublist(1));
            return;
          }
          final fileName = String.fromCharCodes(nameBytes);
          final startSeq = AudioPacketConstants.parseSeq(packet, 2 + nameLen);
          final endSeq = AudioPacketConstants.parseSeq(packet, 6 + nameLen);
          print('[NoteConnection] ✓ 补传完成: file=$fileName, range=$startSeq~$endSeq');
          return;
        }

        // 补传数据包 — 交给传输层重组器处理 (跳过 Cmd 字节)
        _transport.processRetransmitAudioData(packet.sublist(1));
        return;
      }
    }

    if (cmd == NoteCommands.retransmitErrorNoFile) {
      print('[NoteConnection] ❌ 补传错误: 文件不存在');
    } else if (cmd == NoteCommands.retransmitErrorBadRange) {
      print('[NoteConnection] ❌ 补传错误: 序号范围无效');
    }
  }

  /// #2: 完成文件列表响应（合并多个分包）
  void _completeFileListResponse() {
    // 如果没有收集到任何文件包，返回无文件响应
    if (_fileListPackets.isEmpty) {
      final noFileResponse = <int>[0x03, 0x00];
      if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
        _responseCompleter!.complete(noFileResponse);
      }
      _handleResponse(noFileResponse);
      return;
    }

    // 合并所有包的文件信息
    final allFiles = <int>[0x03];  // 命令字节
    int totalCount = 0;

    for (final packet in _fileListPackets) {
      if (packet.length > 2) {
        final pkgCount = packet[1];
        totalCount += pkgCount;
        allFiles.addAll(packet.sublist(2));  // 添加文件数据（跳过命令和本包数量）
      }
    }

    // 插入总文件数
    allFiles.insert(1, totalCount);

    print('[NoteConnection] 文件列表拼接完成，总文件数: $totalCount');
    _fileListPackets.clear();

    if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
      _responseCompleter!.complete(allFiles);
    }
    _handleResponse(allFiles);
  }

  /// #2: 开始分包超时计时（用于文件列表分包收集）
  void _startPacketTimeout() {
    _cancelPacketTimeout();
    _packetTimeoutTimer = Timer(const Duration(milliseconds: _kFileListTimeoutMs), () {
      // 超时后完成文件列表响应
      if (_fileListPackets.isNotEmpty) {
        print('[NoteConnection] 文件列表接收超时，返回已收集数据');
        _completeFileListResponse();
      }
    });
  }

  /// #2: 取消分包超时计时
  void _cancelPacketTimeout() {
    _packetTimeoutTimer?.cancel();
    _packetTimeoutTimer = null;
  }

  @override
  Future<void> connect({
    void Function(String deviceId, DeviceConnectionState state)? onConnectionStateChanged,
  }) async {
    print('[NoteConnection] 开始连接设备: ${device.name}');

    // 保存回调供自动重连使用
    _connectionStateCallback = onConnectionStateChanged;

    // 停止自动重连定时器（如果正在运行）
    _stopAutoReconnect();

    // 调用父类连接方法
    await super.connect(onConnectionStateChanged: onConnectionStateChanged);

    // Note 设备特有的初始化
    if (!_isInitialized) {
      await _initialize();
      _isInitialized = true;
    }

    // 重连后恢复补传状态
    await _restoreRetransmitStateOnReconnect();

    // 连接成功后启用自动重连
    _autoReconnectEnabled = true;
  }

  /// 重连后根据设备录音状态决定处理策略
  ///
  /// 场景判断:
  /// A. 设备仍在录同一个文件 → 恢复 lastSeq，补传间隙
  /// B. 设备在录新文件 → 旧文件需从设备下载，新文件正常接收
  /// C. 设备空闲 → 旧文件需从设备下载
  Future<void> _restoreRetransmitStateOnReconnect() async {
    final savedState = await _storage.loadRetransmitState();
    if (savedState == null) {
      print('[NoteConnection] 无持久化补传状态，跳过恢复');
      return;
    }

    print('[NoteConnection] 持久化状态: file=${savedState.fileName}, lastSeq=${savedState.lastSeq}');

    // 查询设备当前录音状态
    RecordStatus deviceStatus;
    try {
      deviceStatus = await queryRecordStatus();
    } catch (e) {
      print('[NoteConnection] 查询录音状态失败，按空闲处理: $e');
      deviceStatus = RecordStatus(status: RecordStatusValues.idle, fileName: '');
    }

    if (deviceStatus.isRecording && deviceStatus.fileName == savedState.fileName) {
      // 场景 A: 设备仍在录同一个文件 → 恢复 Seq 状态，等实时流恢复后检测间隙
      _currentRecordingFileName = savedState.fileName;
      _transport.restoreLastCompletedSeq(savedState.lastSeq);
      // 恢复文件写入（追加模式，保留断连前已写入的数据）
      _startAudioFileWriter(savedState.fileName, append: true);
      print('[NoteConnection] 场景A: 设备继续录音同文件，恢复 lastSeq=${savedState.lastSeq}');

    } else if (deviceStatus.isRecording && deviceStatus.fileName != savedState.fileName) {
      // 场景 B: 设备在录新文件 → 旧文件需下载，新文件正常接收
      _currentRecordingFileName = deviceStatus.fileName;
      _pendingDownloadFiles.add(savedState.fileName);
      // 新文件从 Seq 0 开始，不恢复旧 lastSeq
      _startAudioFileWriter(deviceStatus.fileName);
      print('[NoteConnection] 场景B: 设备在录新文件 ${deviceStatus.fileName}，'
          '旧文件 ${savedState.fileName} 待下载');

    } else {
      // 场景 C: 设备空闲 → 旧文件需从设备下载完整版
      _currentRecordingFileName = null;
      _pendingDownloadFiles.add(savedState.fileName);
      print('[NoteConnection] 场景C: 设备空闲，旧文件 ${savedState.fileName} 待下载');
    }

    // 清除持久化状态（已处理）
    await _storage.clearRetransmitState();

    // 通知上层有待下载的文件
    if (_pendingDownloadFiles.isNotEmpty) {
      _pendingDownloadController.add(List.from(_pendingDownloadFiles));
    }
  }

  // ============ #7: 自动重连方法 ============

  /// 启动自动重连
  void _startAutoReconnect() async {
    // 检查是否已绑定设备
    final isBound = await _storage.isDeviceBound();
    if (!isBound) {
      print('[NoteConnection] 设备未绑定，不启动自动重连');
      return;
    }

    _stopAutoReconnect();
    print('[NoteConnection] 启动自动重连定时器 ($_kAutoReconnectIntervalSec秒间隔)');

    _autoReconnectTimer = Timer.periodic(
      const Duration(seconds: _kAutoReconnectIntervalSec),
      (timer) async {
        if (!_autoReconnectEnabled) {
          timer.cancel();
          return;
        }

        print('[NoteConnection] 尝试自动重连...');
        try {
          await connect(onConnectionStateChanged: _connectionStateCallback);
          print('[NoteConnection] 自动重连成功');
          timer.cancel();
        } catch (e) {
          print('[NoteConnection] 自动重连失败: $e, 将继续重试');
        }
      },
    );
  }

  /// 停止自动重连
  void _stopAutoReconnect() {
    _autoReconnectTimer?.cancel();
    _autoReconnectTimer = null;
  }

  /// 启用/禁用自动重连
  void setAutoReconnectEnabled(bool enabled) {
    _autoReconnectEnabled = enabled;
    if (!enabled) {
      _stopAutoReconnect();
    }
    print('[NoteConnection] 自动重连已${enabled ? "启用" : "禁用"}');
  }

  /// 连接初始化流程
  ///
  /// 1. RTC 时间同步
  /// 2. 检查设备绑定状态
  /// 3. 设置录音模式(可选)
  Future<void> _initialize() async {
    try {
      print('[NoteConnection] 开始设备初始化');

      // 1. RTC 时间同步
      await syncRTC();
      await Future.delayed(const Duration(milliseconds: 50));

      // 2. 检查绑定状态
      final isBound = await _storage.isDeviceBound();
      if (!isBound) {
        print('[NoteConnection] 设备未绑定,执行绑定流程');
        await bindDevice();
      } else {
        print('[NoteConnection] 设备已绑定');
      }

      // 3. 保存设备类型
      await _storage.saveDeviceType('AI Note');

      print('[NoteConnection] 设备初始化完成');
    } catch (e) {
      print('[NoteConnection] 设备初始化失败: $e');
    }
  }

  // ============ 设备信息查询 ============

  @override
  Future<int> performRetrieveBatteryLevel() async {
    try {
      final response = await _sendCommandWithResponse([NoteCommands.queryBattery]);
      // 协议: E1 + 电量% + 充电状态(1=充电中/2=未充电/3=已充满)
      if (response.length >= 2 && response[0] == NoteCommands.queryBattery) {
        final batteryLevel = response[1];
        // 充电状态在 response[2]，可选返回
        if (response.length >= 3) {
          final chargingState = response[2];
          print('[NoteConnection] 电量: $batteryLevel%, 充电状态: $chargingState');
        }
        return batteryLevel;
      }
      return -1;
    } catch (e) {
      print('[NoteConnection] 查询电量失败: $e');
      return -1;
    }
  }

  /// 查询固件版本
  ///
  /// 协议: 命令 E3，返回 E3 + 版本号字符串 (如 v10.39.40)
  /// 返回格式: "vX.Y.Z"
  Future<String> queryFirmwareVersion() async {
    try {
      final response = await _sendCommandWithResponse([NoteCommands.queryVersion]);
      // 检查响应长度，至少需要 2 字节 (命令 + 至少1字节版本)
      if (response.length >= 2 && response[0] == NoteCommands.queryVersion) {
        // 读取剩余所有字节作为版本号
        final versionBytes = response.sublist(1);
        // 过滤掉 0 字节和非打印字符
        final filtered = versionBytes.where((b) => b >= 0x20 && b < 0x7F).toList();
        return String.fromCharCodes(filtered).trim();
      }
      return 'Unknown';
    } catch (e) {
      print('[NoteConnection] 查询版本失败: $e');
      return 'Unknown';
    }
  }

  /// 查询存储空间
  ///
  /// 协议: 命令 E8
  /// 返回: E8 + 长度 + 录音文件数量 + 已用空间(KB)/总容量(KB)
  /// 返回存储信息对象
  Future<NoteStorageInfo> queryStorage() async {
    try {
      final response = await _sendCommandWithResponse([NoteCommands.queryStorage]);
      // 响应格式: E8 + 长度 + 文件数量 + 空间信息字符串
      if (response.length >= 3 && response[0] == NoteCommands.queryStorage) {
        final dataLength = response[1];
        final fileCount = response[2];
        // 空间信息从 response[3] 开始，长度为 dataLength - 1 (减去文件数量字节)
        if (response.length >= 3 + dataLength - 1) {
          final spaceBytes = response.sublist(3, 3 + dataLength - 1);
          final spaceInfo = String.fromCharCodes(spaceBytes).trim();

          // 格式: "usedKB/totalKB"
          final parts = spaceInfo.split('/');
          if (parts.length == 2) {
            return NoteStorageInfo(
              usedKB: int.tryParse(parts[0]) ?? 0,
              totalKB: int.tryParse(parts[1]) ?? 0,
              fileCount: fileCount,
            );
          }
        }
      }
      return NoteStorageInfo(usedKB: 0, totalKB: 0);
    } catch (e) {
      print('[NoteConnection] 查询存储失败: $e');
      return NoteStorageInfo(usedKB: 0, totalKB: 0);
    }
  }

  // ============ 设备配置 ============

  /// RTC 时间同步
  ///
  /// 将当前系统时间同步到设备
  Future<void> syncRTC() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final command = [
        NoteCommands.syncRTC,
        (timestamp >> 24) & 0xFF,
        (timestamp >> 16) & 0xFF,
        (timestamp >> 8) & 0xFF,
        timestamp & 0xFF,
      ];

      await _sendCommand(command);
      print('[NoteConnection] RTC 时间已同步: ${DateTime.now()}');
    } catch (e) {
      print('[NoteConnection] RTC 同步失败: $e');
      rethrow;
    }
  }

  /// 设置录音模式
  ///
  /// 协议: 命令 F7 + 模式(02=双数字麦)
  /// 返回: F7 + 00(成功)/01(失败) - 只有 2 字节
  /// mode: NoteRecordingMode.recordOnly 或 NoteRecordingMode.recordAndUpload
  /// 返回: true 成功, false 失败
  Future<bool> setRecordingMode(NoteRecordingMode mode) async {
    try {
      final response = await _sendCommandWithResponse([NoteCommands.setRecordingMode, mode.value]);
      // 协议响应格式: 0x0D + 模式值回显 + 0x01(成功)/0x00(失败)
      if (response.length >= 3 && response[0] == NoteCommands.setRecordingMode && response[2] == 0x01) {
        print('[NoteConnection] 录音模式已设置: ${mode.description}');
        return true;
      }
      print('[NoteConnection] 设置录音模式失败，响应: ${response.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');
      return false;
    } catch (e) {
      print('[NoteConnection] 设置录音模式失败: $e');
      return false;
    }
  }

  /// 设置U盘模式
  ///
  /// enabled: true 开启, false 关闭
  Future<void> setUsbMode(bool enabled) async {
    try {
      await _sendCommand([NoteCommands.usbMode, enabled ? 0x01 : 0x00]);
      print('[NoteConnection] U盘模式已设置: ${enabled ? "开启" : "关闭"}');
    } catch (e) {
      print('[NoteConnection] 设置U盘模式失败: $e');
      rethrow;
    }
  }

  // ============ 录音控制 ============

  /// 开始录音
  ///
  /// 返回: true 成功, false 失败(设备正在录音)
  Future<bool> startRecording() async {
    final result = await startRecordingWithStatus();
    return result == RecordingStartResult.success;
  }

  /// 开始录音（带详细状态）
  ///
  /// 协议: 命令 01 00 00
  /// 成功通知: 01 01 [record_state] [mode] [file_name...]
  ///   - byte[2] = record_state (通常 0x01)
  ///   - byte[3] = mode (0x00 normal / 0x01 memo)
  ///   - byte[4..] = file_name
  /// 失败响应: 01 00 [current_record_state]
  Future<RecordingStartResult> startRecordingWithStatus() async {
    try {
      // 协议要求: 01 00 00
      final response = await _sendCommandWithResponse([NoteCommands.startRecording, 0x00, 0x00]);
      if (response.length >= 3 && response[0] == 0x01) {
        if (response[1] == 0x01 && response.length >= 4) {
          // 成功 — 解析 mode 和 fileName
          final mode = NoteRecordingType.fromValue(response[3]);
          final fileName = response.length > 4
              ? String.fromCharCodes(response.sublist(4))
              : '';
          _applyRecordingStarted(fileName, mode);
          return RecordingStartResult.success;
        } else if (response[1] == 0x00 && response[2] == 0x01) {
          // 01 00 01 = 失败，设备正在录音
          print('[NoteConnection] 设备正在录音');
          return RecordingStartResult.alreadyRecording;
        }
      }
      print('[NoteConnection] 录音失败，响应: ${response.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');
      return RecordingStartResult.failed;
    } catch (e) {
      print('[NoteConnection] 开始录音失败: $e');
      return RecordingStartResult.failed;
    }
  }

  /// 应用"录音已开始"状态（APP 主动启动 / 设备按键 unsolicited / split 续录共用）
  ///
  /// 1. 更新 _currentRecordingFileName / _currentRecordingType
  /// 2. 启动音频文件写入器
  /// 3. 落 (fileName → mode) 索引
  /// 4. 广播 onRecordingStarted 事件
  void _applyRecordingStarted(String fileName, NoteRecordingType type) {
    if (fileName.isEmpty) {
      print('[NoteConnection] 开始录音通知缺 fileName，跳过应用');
      return;
    }
    _currentRecordingFileName = fileName;
    _currentRecordingType = type;
    print('[NoteConnection] 录音已开始 (${type.description}): $fileName');

    _startAudioFileWriter(fileName);
    _storage.appendRecordingMode(fileName, type);

    if (!_recordingStartController.isClosed) {
      _recordingStartController.add((fileName: fileName, type: type));
    }
  }

  /// 停止录音
  ///
  /// 协议: 命令 [0x02, 0x00] (00=结束录音, 01=继续, 02=暂停)
  /// 响应: [Cmd=0x02][Op][Result][FileID][FileName...]
  /// - Result: 0x01=成功, 0x02=文件异常, 0x03=超时分片
  /// - FileID: 设备全局文件计数器 (从 1 递增)
  /// - FileName: ASCII 直到包尾
  Future<Map<String, dynamic>> stopRecording() async {
    try {
      final response = await _sendCommandWithResponse([NoteCommands.stopRecording, 0x00]);
      final result = _parseStopRecordingResponse(response);
      if (result['success'] == true) {
        await _stopAudioFileWriter();
        _currentRecordingFileName = null;
        _currentRecordingType = null;
        _storage.clearRetransmitState();
      }
      return result;
    } catch (e) {
      print('[NoteConnection] 停止录音失败: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 解析停止录音响应
  /// 格式: [Cmd=0x02][Op][Result][FileID][FileName...]
  /// 供 stopRecording() 和 unsolicited 通知共用
  Map<String, dynamic> _parseStopRecordingResponse(List<int> response) {
    if (response.length < 3 || response[0] != 0x02) {
      print('[NoteConnection] 停止录音响应格式异常: ${response.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');
      return {'success': false};
    }

    final operation = response[1];  // 操作码回显
    final result = response[2];     // 0x01=成功, 0x02=文件异常, 0x03=超时分片

    if (result == 0x02) {
      print('[NoteConnection] 录音停止，文件异常');
      return {'success': false, 'error': 'file_error'};
    }

    if ((result == 0x01 || result == 0x03) && response.length >= 5) {
      // byte[3] = FileID (设备全局文件计数)
      // byte[4..] = FileName (ASCII 直到包尾)
      final fileId = response[3];
      final fileName = String.fromCharCodes(response.sublist(4));
      final isSplit = result == 0x03;

      print('[NoteConnection] 录音已停止 (op=$operation, fileId=$fileId, split=$isSplit)，文件: $fileName');
      return {
        'success': true,
        'fileName': fileName,
        'fileId': fileId,
        if (isSplit) 'split': true,
      };
    }

    print('[NoteConnection] 停止录音失败，响应: ${response.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');
    return {'success': false};
  }

  // ============ 实时音频文件写入 ============

  /// 获取当前音频文件写入器 (供 Debug 查看状态)
  NoteAudioFileWriter? get audioFileWriter => _audioFileWriter;

  /// 开始写入音频文件
  ///
  /// [append] 为 true 时追加写入（重连恢复同文件场景）
  Future<void> _startAudioFileWriter(String fileName, {bool append = false}) async {
    await _stopAudioFileWriter();

    try {
      final basePath = await _storage.getStoragePath();
      final filePath = '$basePath/NoteDownloads/$fileName';
      _audioFileWriter = NoteAudioFileWriter(mainFilePath: filePath);
      await _audioFileWriter!.open(append: append);

      // 订阅带 Seq 的音频流
      _seqAudioSubscription = _transport.seqAudioStream.listen((data) {
        _audioFileWriter?.writeFrame(data.seq, data.frame);
      });

      print('[NoteConnection] 音频文件写入已开始: $filePath');
    } catch (e) {
      print('[NoteConnection] 启动音频文件写入失败: $e');
      _audioFileWriter = null;
    }
  }

  /// 停止写入音频文件
  Future<void> _stopAudioFileWriter() async {
    _seqAudioSubscription?.cancel();
    _seqAudioSubscription = null;

    if (_audioFileWriter != null) {
      await _audioFileWriter!.close();
      print('[NoteConnection] 音频文件写入已停止: '
          '${_audioFileWriter!.framesWritten} 帧, '
          '${_audioFileWriter!.bytesWritten} bytes, '
          '${_audioFileWriter!.gapCount} 个间隙');
      _audioFileWriter = null;
    }
  }

  // ============ 文件管理 ============

  /// 获取文件列表
  ///
  /// 返回设备上所有录音文件的信息列表
  Future<List<NoteFileInfo>> getFileList() async {
    try {
      final response = await _sendCommandWithResponse([NoteCommands.getFileList]);
      if (response.isEmpty || response[0] != 0x03) return [];

      final fileCount = response[1];
      if (fileCount == 0 || fileCount == 255) {
        print('[NoteConnection] 没有文件');
        return [];
      }

      final files = <NoteFileInfo>[];
      int offset = 2;

      for (int i = 0; i < fileCount; i++) {
        final index = response[offset];
        final duration = (response[offset + 1] << 8) + response[offset + 2];
        final nameLength = response[offset + 3];
        final fileNameBytes = response.sublist(offset + 4, offset + 4 + nameLength);
        final name = utf8.decode(fileNameBytes);

        // 验证文件名格式
        if (name.isNotEmpty && name.length >= 15 && name.contains('_')) {
          files.add(NoteFileInfo(
            index: index,
            name: name,
            durationSeconds: duration,
          ));
        }

        offset += 4 + nameLength;
      }

      print('[NoteConnection] 获取文件列表成功,共 ${files.length} 个文件');
      return files;
    } catch (e) {
      print('[NoteConnection] 获取文件列表失败: $e');
      return [];
    }
  }

  /// 请求上传文件
  ///
  /// 协议: 命令 04 + 文件名长度 + 文件名
  /// 返回: 04 01 请求成功, 04 00 请求失败, 04 02 传输结束
  /// fileName: 要上传的文件名
  /// 文件内容会通过 fileStream (UUID 305) 接收
  Future<bool> uploadFile(String fileName) async {
    try {
      // 重置文件传输状态 (Seq 计数、诊断日志)
      _transport.resetFileReassembler(fileName: fileName);

      final fileNameBytes = utf8.encode(fileName);
      final command = [NoteCommands.uploadFile, fileNameBytes.length, ...fileNameBytes];
      final response = await _sendCommandWithResponse(command);

      // 验证响应: 04 01 = 请求成功
      if (response.length >= 2 && response[0] == 0x04 && response[1] == 0x01) {
        print('[NoteConnection] 文件请求成功，等待数据传输: $fileName');
        return true;
      } else if (response.length >= 2 && response[0] == 0x04 && response[1] == 0x00) {
        print('[NoteConnection] 文件请求失败，文件不存在: $fileName');
        return false;
      }
      print('[NoteConnection] 文件请求异常，响应: ${response.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');
      return false;
    } catch (e) {
      print('[NoteConnection] 上传文件失败: $e');
      rethrow;
    }
  }

  /// 删除文件
  ///
  /// 协议: 命令 05 + 文件名长度(1B) + 文件名
  /// 返回: 05 01 删除成功, 05 00 删除失败
  /// fileName: 要删除的文件名(从文件列表获取的 name 字段)
  Future<bool> deleteFile(String fileName) async {
    try {
      final fileNameBytes = fileName.codeUnits;
      final command = [
        NoteCommands.deleteFile,
        fileNameBytes.length,  // 文件名长度
        ...fileNameBytes,      // 文件名
      ];
      final response = await _sendCommandWithResponse(command);

      // 验证响应: 05 01 = 删除成功
      if (response.length >= 2 && response[0] == 0x05 && response[1] == 0x01) {
        print('[NoteConnection] 文件已删除: $fileName');
        return true;
      }
      print('[NoteConnection] 删除文件失败，响应: ${response.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');
      return false;
    } catch (e) {
      print('[NoteConnection] 删除文件失败: $e');
      rethrow;
    }
  }

  // ============ 设备管理 ============

  /// 从设备 MAC 地址生成 6 字节 ID
  ///
  /// MAC 格式: "AA:BB:CC:DD:EE:FF" 或 "AA-BB-CC-DD-EE-FF"
  List<int> _getDeviceIdBytes() {
    final macAddress = device.id;
    // 移除分隔符，解析为 6 字节
    final cleanMac = macAddress.replaceAll(RegExp(r'[:\-]'), '');
    if (cleanMac.length >= 12) {
      return List.generate(6, (i) {
        final hex = cleanMac.substring(i * 2, i * 2 + 2);
        return int.parse(hex, radix: 16);
      });
    }
    // 如果 MAC 格式不正确，返回 6 个 0xFF
    return List.filled(6, 0xFF);
  }

  /// 设备绑定
  ///
  /// 协议: 0b + 01 + 6字节ID
  /// 返回: 0b + 01 + 00/01 (失败/成功)
  Future<void> bindDevice() async {
    try {
      final deviceIdBytes = _getDeviceIdBytes();
      final response = await _sendCommandWithResponse([
        NoteCommands.bindDevice,
        0x01,  // 绑定操作
        ...deviceIdBytes,
      ]);
      // 验证响应
      if (response.length >= 3 && response[0] == NoteCommands.bindDevice &&
          response[1] == 0x01 && response[2] == 0x01) {
        await _storage.saveDeviceBinding(device.id, device.name);
        print('[NoteConnection] 设备绑定成功');
      } else {
        print('[NoteConnection] 设备绑定失败，响应: ${response.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');
        throw Exception('设备绑定失败');
      }
    } catch (e) {
      print('[NoteConnection] 设备绑定失败: $e');
      rethrow;
    }
  }

  /// 设备解绑
  ///
  /// 协议: 0b + 00 + 6字节ID
  /// 返回: 0b + 00 + 00/01 (失败/成功)
  Future<void> unbindDevice() async {
    try {
      final deviceIdBytes = _getDeviceIdBytes();
      final response = await _sendCommandWithResponse([
        NoteCommands.bindDevice,
        0x00,  // 解绑操作
        ...deviceIdBytes,
      ]);
      // 验证响应
      if (response.length >= 3 && response[0] == NoteCommands.bindDevice &&
          response[1] == 0x00 && response[2] == 0x01) {
        await _storage.clearDeviceBinding();
        print('[NoteConnection] 设备解绑成功');
      } else {
        print('[NoteConnection] 设备解绑失败，响应: ${response.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');
        throw Exception('设备解绑失败');
      }
    } catch (e) {
      print('[NoteConnection] 设备解绑失败: $e');
      rethrow;
    }
  }

  /// 设备重启
  Future<void> reboot() async {
    try {
      await _sendCommand([NoteCommands.reboot]);
      print('[NoteConnection] 设备重启命令已发送');
    } catch (e) {
      print('[NoteConnection] 设备重启失败: $e');
      rethrow;
    }
  }

  /// 恢复出厂设置
  ///
  /// keepRecordings: true 保留录音文件, false 删除录音文件
  /// 返回: true 成功, false 失败
  Future<bool> factoryReset({bool keepRecordings = false}) async {
    try {
      final param = keepRecordings ? 0x00 : 0xFF;
      final response = await _sendCommandWithResponse([NoteCommands.factoryReset, param]);

      if (response.isNotEmpty && response[0] == 0xE9 && response[1] == 0x01) {
        await _storage.clearDeviceBinding();
        print('[NoteConnection] 恢复出厂设置成功');
        return true;
      }
      return false;
    } catch (e) {
      print('[NoteConnection] 恢复出厂设置失败: $e');
      return false;
    }
  }

  // ============ 音频流监听 ============

  @override
  Future<StreamSubscription?> performGetBleAudioBytesListener({
    required void Function(List<int>) onAudioBytesReceived,
  }) async {
    return _transport.audioStream.listen(onAudioBytesReceived);
  }

  /// 获取文件数据流
  ///
  /// 用于接收设备上传的文件数据
  Future<StreamSubscription?> getFileDataListener({
    required void Function(List<int>) onFileDataReceived,
  }) async {
    return _transport.fileStream.listen(onFileDataReceived);
  }

  // ============ 录音状态查询 (V1.0 协议) ============

  /// 查询录音状态
  ///
  /// 读取 record_status 特征 (UUID e2c1a310)
  /// 格式: [Status 1B] [FileNameLen 1B] [FileName 变长]
  /// 返回: RecordStatus 对象
  Future<RecordStatus> queryRecordStatus() async {
    try {
      final data = await _transport.readCharacteristic(
        NoteUUIDs.service.toString(),
        NoteUUIDs.recordStatus.toString(),
      );

      if (data.length >= 2) {
        final status = data[0];
        final nameLen = data[1];
        final fileName = (nameLen > 0 && data.length >= 2 + nameLen)
            ? String.fromCharCodes(data.sublist(2, 2 + nameLen))
            : '';

        final result = RecordStatus(status: status, fileName: fileName);
        print('[NoteConnection] 录音状态查询: $result');
        return result;
      }

      print('[NoteConnection] 录音状态查询: 响应数据不足 (${data.length} bytes)');
      return RecordStatus(status: RecordStatusValues.idle, fileName: '');
    } catch (e) {
      print('[NoteConnection] 录音状态查询失败: $e');
      return RecordStatus(status: RecordStatusValues.idle, fileName: '');
    }
  }

  // ============ 音频补传 (V1.0 协议) ============

  /// 发送补传请求
  ///
  /// 协议: [Cmd=0x20] [FileNameLen 1B] [FileName] [StartSeq 4B Big-Endian] [EndSeq 4B Big-Endian]
  /// 通过 rx 特征 (UUID e2c1a302) 发送
  ///
  /// [fileName] 需要补传的录音文件名
  /// [startSeq] 补传起始帧序号 (含)
  /// [endSeq] 补传结束帧序号 (含)
  Future<bool> requestRetransmit(String fileName, int startSeq, int endSeq) async {
    try {
      final nameBytes = utf8.encode(fileName);
      if (nameBytes.length > 32) {
        print('[NoteConnection] 补传请求失败: 文件名超过32字节 (${nameBytes.length})');
        return false;
      }

      final command = [
        NoteCommands.retransmitRequest,
        nameBytes.length,
        ...nameBytes,
        // StartSeq Big-Endian
        (startSeq >> 24) & 0xFF,
        (startSeq >> 16) & 0xFF,
        (startSeq >> 8) & 0xFF,
        startSeq & 0xFF,
        // EndSeq Big-Endian
        (endSeq >> 24) & 0xFF,
        (endSeq >> 16) & 0xFF,
        (endSeq >> 8) & 0xFF,
        endSeq & 0xFF,
      ];

      await _sendCommand(command);
      print('[NoteConnection] 补传请求已发送: file=$fileName, '
          'range=$startSeq~$endSeq (${endSeq - startSeq + 1}帧)');
      return true;
    } catch (e) {
      print('[NoteConnection] 补传请求失败: $e');
      return false;
    }
  }

  /// 获取 Seq 间隙记录 (供补传逻辑查询)
  List<SeqGapRecord> getSeqGaps() => _transport.seqGaps;

  /// 清除 Seq 间隙记录 (补传完成后调用)
  void clearSeqGaps() => _transport.clearSeqGaps();

  /// 重置音频重组器 (新文件开始时调用)
  void resetAudioReassembler({String? fileName}) {
    _transport.resetReassembler(fileName: fileName);
    print('[NoteConnection] 音频重组器已重置, 文件=$fileName');
  }

  // ============ OTA 相关方法 (供 NoteOtaService 使用) ============

  /// 发送命令并等待响应 (公开方法,供 OTA 服务使用)
  ///
  /// timeout: 超时时间
  /// 返回: 响应数据
  Future<List<int>> sendCommandWithResponse(
    List<int> command, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return await _sendCommandWithResponse(command, timeout: timeout);
  }

  /// 发送 OTA 文件数据 (供 OTA 服务使用)
  ///
  /// data: 固件数据块
  Future<void> sendOtaData(List<int> data) async {
    await _transport.sendOtaData(data);
  }

  // ============ 未实现的抽象方法(Note设备不需要) ============

  @override
  Future<List<int>> performGetButtonState() async {
    // Note 设备没有按钮状态
    return [];
  }

  @override
  Future<StreamSubscription?> performGetBleButtonListener({
    required void Function(List<int>) onButtonReceived,
  }) async {
    // Note 设备没有按钮监听
    return null;
  }

  @override
  Future<BleAudioCodec> performGetAudioCodec() async {
    // Note 设备使用 Opus 编码
    return BleAudioCodec.opus;
  }

  @override
  Future<bool> performPlayToSpeakerHaptic(int mode) async {
    // Note 设备不支持扬声器/触觉反馈
    return false;
  }

  @override
  Future<List<int>> performGetStorageList() async {
    // Note 设备使用自己的文件管理系统
    return [];
  }

  @override
  Future<bool> performWriteToStorage(int numFile, int command, int offset) async {
    // Note 设备使用自己的文件传输协议
    return false;
  }

  @override
  Future<StreamSubscription?> performGetBleStorageBytesListener({
    required void Function(List<int>) onStorageBytesReceived,
  }) async {
    // Note 设备使用自己的文件数据流
    return _transport.fileStream.listen(onStorageBytesReceived);
  }

  @override
  Future performCameraStartPhotoController() async {
    // Note 设备不支持相机
    throw UnimplementedError('Camera not supported on Note device');
  }

  @override
  Future performCameraStopPhotoController() async {
    // Note 设备不支持相机
    throw UnimplementedError('Camera not supported on Note device');
  }

  @override
  Future<bool> performHasPhotoStreamingCharacteristic() async {
    // Note 设备不支持相机
    return false;
  }

  @override
  Future<StreamSubscription?> performGetImageListener({
    required void Function(OrientedImage) onImageReceived,
  }) async {
    // Note 设备不支持相机
    return null;
  }

  @override
  Future<StreamSubscription<List<int>>?> performGetAccelListener({
    void Function(int)? onAccelChange,
  }) async {
    // Note 设备不支持加速度计
    return null;
  }

  @override
  Future<int> performGetFeatures() async {
    // Note 设备特性标志(可根据实际需要设置)
    return 0;
  }

  @override
  Future<void> performSetLedDimRatio(int ratio) async {
    // Note 设备不支持LED控制
  }

  @override
  Future<int?> performGetLedDimRatio() async {
    // Note 设备不支持LED控制
    return null;
  }

  @override
  Future<void> performSetMicGain(int gain) async {
    // Note 设备不支持麦克风增益控制
  }

  @override
  Future<int?> performGetMicGain() async {
    // Note 设备不支持麦克风增益控制
    return null;
  }

  // ============ 命令发送辅助方法 ============

  /// 发送命令(无需响应)
  Future<void> _sendCommand(List<int> command) async {
    await _transport.sendCommand(command);
    final hexString = command.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
    print('[NoteConnection] 命令已发送: $hexString');
  }

  /// 发送命令并等待响应
  ///
  /// timeout: 超时时间(默认10秒)
  /// 返回: 响应数据
  Future<List<int>> _sendCommandWithResponse(
    List<int> command, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _responseCompleter = Completer<List<int>>();

    await _transport.sendCommand(command);
    final hexString = command.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
    print('[NoteConnection] 命令已发送(等待响应): $hexString');

    try {
      final response = await _responseCompleter!.future.timeout(
        timeout,
        onTimeout: () {
          print('[NoteConnection] 等待响应超时');
          return [];
        },
      );
      return response;
    } finally {
      _responseCompleter = null;
    }
  }

  /// 处理响应数据
  ///
  /// 可在这里添加通用的响应处理逻辑
  void _handleResponse(List<int> response) {
    final hexString = response.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
    print('[NoteConnection] 收到响应: $hexString');
  }

  // ============ 连接管理 ============

  @override
  Future<void> disconnect() async {
    print('[NoteConnection] 断开连接');
    // 主动断开时禁用自动重连
    _autoReconnectEnabled = false;
    _stopAutoReconnect();
    _cancelPacketTimeout();
    _fileListPackets.clear();
    _isInitialized = false;
    await super.disconnect();
  }

  /// 释放资源
  void dispose() {
    _autoReconnectTimer?.cancel();
    _cancelPacketTimeout();
    _fileListPackets.clear();
    _recordingStartController.close();
    _recordingStopController.close();
    _pendingDownloadController.close();
    _seqAudioSubscription?.cancel();
    _transport.dispose();
  }

  /// 获取存储管理器(用于外部访问)
  NoteStorageManager get storageManager => _storage;

  /// 获取传输层(用于OTA服务访问)
  NoteBleTransport get bleTransport => _transport;
}
