/// Note BLE 传输层
/// 使用 flutter_reactive_ble 实现的 BLE 通信层
library;

import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:omi/backend/schema/bt_device/bt_device.dart';
import 'package:omi/services/devices/note_commands.dart';
import 'device_transport.dart';

/// MTU 配置常量
const int _kNoteMtuSize = 517;

/// 连接稳定等待时间 (ms)
const int _kConnectionStabilizeDelayMs = 200;

/// 服务发现超时时间 (秒)
const int _kServiceDiscoveryTimeoutSec = 10;

/// 设备广播验证超时时间 (秒)
const int _kAdvertisementVerifyTimeoutSec = 5;

// ============ 音频包重组器 (V1.0 协议) ============

/// 音频帧分包重组器
///
/// 处理 UUID 301 (rt_file) 上的音频数据包:
/// - 解析 [Seq 4B] [Flag 1B] [Data] 包头
/// - 单包 (Flag高4位=0) 直接输出
/// - 分包 (Flag高4位>0) 缓存并重组为完整 480B Opus 帧
/// - 检测 Seq 间隙 (用于触发补传)
class AudioPacketReassembler {
  /// 分包重组缓存: seq -> {index -> data}
  final Map<int, Map<int, List<int>>> _pending = {};

  /// 分包重组超时定时器
  Timer? _timeoutTimer;

  /// 最后完成的帧序号 (-1 表示尚未收到任何帧)
  int _lastCompletedSeq = -1;

  /// 当前录音文件名 (Seq 按文件重置)
  String? _currentFileName;

  /// 已完成帧计数 (用于日志控制)
  int _completedFrameCount = 0;

  /// 上次详细日志时间
  DateTime? _lastDetailLogTime;

  /// 丢弃的不完整帧计数
  int _discardedFrameCount = 0;

  /// 日志标签 (区分实时音频/文件上传)
  final String tag;

  /// 完整帧输出回调
  final void Function(int seq, List<int> frame) onFrameComplete;

  /// Seq 间隙检测回调
  final void Function(int expectedSeq, int receivedSeq) onSeqGap;

  AudioPacketReassembler({this.tag = 'RT', required this.onFrameComplete, required this.onSeqGap});

  /// 获取最后完成的 Seq
  int get lastCompletedSeq => _lastCompletedSeq;

  /// 获取当前文件名
  String? get currentFileName => _currentFileName;

  /// 获取已完成帧计数
  int get completedFrameCount => _completedFrameCount;

  /// 处理一个 BLE notification 原始数据包
  ///
  /// 自动检测两种格式:
  /// - 无 Flag 格式: [Seq 4B] [Data 480B] → 总长 484 (当前固件实际行为)
  /// - 有 Flag 格式: [Seq 4B] [Flag 1B] [Data 变长] → 总长 485+ (协议文档定义)
  void process(List<int> rawPacket) {
    // 前10个包打印原始信息，便于确认实际包格式
    if (_completedFrameCount + _discardedFrameCount < 10) {
      final hexHead = rawPacket.take(8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      print(
        '[$tag] 原始包#${_completedFrameCount + _discardedFrameCount}: '
        'len=${rawPacket.length}, head=[$hexHead${rawPacket.length > 8 ? " ..." : ""}]',
      );
    }

    if (rawPacket.length < AudioPacketConstants.headerSizeSeqOnly + 1) {
      print('[$tag] ⚠️ 包太小: ${rawPacket.length} bytes');
      return;
    }

    final seq = AudioPacketConstants.parseSeq(rawPacket);

    // 自动检测格式: 4+480=484 表示无 Flag (Seq + 完整帧)
    final isNoFlagFormat =
        (rawPacket.length == AudioPacketConstants.headerSizeSeqOnly + AudioPacketConstants.frameSize);

    if (isNoFlagFormat) {
      // 无 Flag 格式: [Seq 4B] [Data 480B]
      final data = rawPacket.sublist(AudioPacketConstants.headerSizeSeqOnly);

      if (_completedFrameCount < 10 || _shouldLogByTime()) {
        print(
          '[$tag] 完整帧 seq=$seq, dataSize=${data.length}, '
          '已完成帧=$_completedFrameCount (无Flag格式)',
        );
      }

      _onFrameReady(seq, data);
      return;
    }

    // 有 Flag 格式: [Seq 4B] [Flag 1B] [Data 变长]
    if (rawPacket.length < AudioPacketConstants.headerSizeWithFlag + 1) {
      print('[$tag] ⚠️ 有Flag格式但包太小: ${rawPacket.length} bytes');
      return;
    }

    final flag = rawPacket[4];
    final totalParts = AudioPacketConstants.getFlagTotal(flag);
    final partIndex = AudioPacketConstants.getFlagIndex(flag);
    final data = rawPacket.sublist(AudioPacketConstants.headerSizeWithFlag);

    if (_completedFrameCount < 10 || _shouldLogByTime()) {
      if (totalParts == 0) {
        print(
          '[$tag] 单包 seq=$seq, flag=0x${flag.toRadixString(16)}, '
          'dataSize=${data.length}, 已完成帧=$_completedFrameCount',
        );
      } else {
        print(
          '[$tag] 分包 seq=$seq, flag=0x${flag.toRadixString(16)}, '
          'part=${partIndex + 1}/$totalParts, dataSize=${data.length}',
        );
      }
    }

    if (totalParts == 0) {
      // Flag=0x00: 不分包，直接输出
      _onFrameReady(seq, data);
    } else {
      // 分包重组
      if (_pending.length >= 50 && !_pending.containsKey(seq)) {
        final oldestSeq = _pending.keys.first;
        print('[$tag] ⚠️ 缓存已满(50), 丢弃最旧 seq=$oldestSeq');
        _pending.remove(oldestSeq);
        _discardedFrameCount++;
      }

      _pending.putIfAbsent(seq, () => <int, List<int>>{});
      _pending[seq]![partIndex] = data;

      if (_pending[seq]!.length == totalParts) {
        final frame = <int>[];
        for (int i = 0; i < totalParts; i++) {
          final part = _pending[seq]![i];
          if (part != null) {
            frame.addAll(part);
          } else {
            print('[$tag] ⚠️ seq=$seq 缺少子包 #$i/$totalParts，丢弃该帧');
            _pending.remove(seq);
            _discardedFrameCount++;
            return;
          }
        }
        _pending.remove(seq);
        print('[$tag] 分包重组完成 seq=$seq, ${totalParts}个子包 → ${frame.length} bytes');
        _onFrameReady(seq, frame);
      } else {
        _ensureTimeout();
      }
    }
  }

  /// 节流日志: 每10秒允许一次 (仅在需要时调用 DateTime.now())
  bool _shouldLogByTime() {
    final now = DateTime.now();
    if (_lastDetailLogTime == null || now.difference(_lastDetailLogTime!).inSeconds >= 10) {
      _lastDetailLogTime = now;
      return true;
    }
    return false;
  }

  void _onFrameReady(int seq, List<int> frame) {
    if (_lastCompletedSeq >= 0 && seq > _lastCompletedSeq + 1) {
      final gapStart = _lastCompletedSeq + 1;
      final gapCount = seq - gapStart;
      print(
        '[$tag] ⚠️ Seq 间隙! 期望=$gapStart, 收到=$seq, '
        '缺失${gapCount}帧, 文件=$_currentFileName',
      );
      onSeqGap(gapStart, seq);
    }

    _lastCompletedSeq = seq;
    _completedFrameCount++;
    onFrameComplete(seq, frame);
  }

  /// 确保有超时定时器运行 (避免高频创建/销毁)
  void _ensureTimeout() {
    if (_timeoutTimer?.isActive == true) return;
    _timeoutTimer = Timer(Duration(milliseconds: AudioPacketConstants.reassemblyTimeoutMs), () {
      if (_pending.isNotEmpty) {
        final seqs = _pending.keys.toList();
        print('[$tag] ⚠️ 分包超时! 丢弃 ${_pending.length} 个不完整帧: seqs=$seqs');
        _discardedFrameCount += _pending.length;
        _pending.clear();
      }
    });
  }

  /// 重置状态 (新文件开始或重连时调用)
  ///
  /// [fileName] 非空时表示新录音文件开始，Seq 重置
  void reset({String? fileName}) {
    _pending.clear();
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    if (fileName != null) {
      final oldFile = _currentFileName;
      _currentFileName = fileName;
      _lastCompletedSeq = -1;
      _completedFrameCount = 0;
      _discardedFrameCount = 0;
      _lastDetailLogTime = null;
      print('[$tag] 重置: 文件切换 $oldFile → $fileName, Seq 归零');
    } else {
      print(
        '[$tag] 重置: 清除缓存 (lastSeq=$_lastCompletedSeq, '
        '已完成=$_completedFrameCount, 已丢弃=$_discardedFrameCount)',
      );
    }
  }

  /// 从持久化状态恢复 lastCompletedSeq（不重置其他状态）
  /// 用于重连后使间隙检测能正确检测到断连期间丢失的帧
  void restoreLastCompletedSeq(int seq) {
    _lastCompletedSeq = seq;
    print('[$tag] 恢复 lastCompletedSeq=$seq');
  }

  /// 释放资源
  void dispose() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _pending.clear();
    print('[$tag] 已释放 (总完成=$_completedFrameCount, 总丢弃=$_discardedFrameCount)');
  }
}

// ============ Note 设备 BLE 传输层 ============

/// Note 设备 BLE 传输层
///
/// 负责:
/// - BLE 设备连接管理
/// - 特征订阅和数据流管理
/// - 命令发送和响应接收
/// - OTA 文件传输
/// - 音频包协议解析 (V1.0: Seq+Flag+Data)
class NoteBleTransport implements MPDeviceTransport {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final BtDevice device;

  // 连接订阅
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;

  // 特征数据订阅
  StreamSubscription<List<int>>? _audioSubscription;
  StreamSubscription<List<int>>? _responseSubscription;
  StreamSubscription<List<int>>? _fileSubscription;
  StreamSubscription<List<int>>? _logSubscription;

  // 数据流控制器
  final _connectionStateController = StreamController<MPDeviceTransportState>.broadcast();
  final _audioDataController = StreamController<List<int>>.broadcast();
  final _seqAudioController = StreamController<({int seq, List<int> frame})>.broadcast();
  final _responseDataController = StreamController<List<int>>.broadcast();
  final _fileDataController = StreamController<List<int>>.broadcast();
  final _logDataController = StreamController<List<int>>.broadcast();

  // 当前连接状态
  MPDeviceTransportState _currentState = MPDeviceTransportState.disconnected;

  // 当前协商的 MTU 值
  int _negotiatedMtu = 23; // 默认 BLE MTU

  // 文件上传 BLE 通知计数 (用于诊断日志)
  int _filePacketCount = 0;

  // 文件上传分帧缓冲区
  // 设备发送格式: [Seq 4B][Audio 480B] = 484 字节/chunk，与 BLE 通知边界不对齐
  static const int _fileChunkSize = 484;
  static const int _fileSeqSize = 4;
  List<int> _fileChunkBuffer = [];

  // 当前文件传输是否为纯字节流模式 (.txt 等非音频文件)
  // true: BLE notification 内容直接作为文件数据，无 Seq 前缀
  // false: 按 [Seq 4B][Audio 480B] 分帧 (opus 文件)
  bool _isRawFileTransfer = false;

  // 连接完成器 - 用于等待连接流程完成
  Completer<void>? _connectionCompleter;

  // 实时音频包重组器 (UUID 301 rt_file)
  late final AudioPacketReassembler _reassembler;

  // 文件上传音频包重组器 (UUID 305 tx_file)
  // 文件上传数据包格式与实时音频相同: [Seq 4B] [Flag 1B] [Data]
  // MTU 无需固定 — 重组器通过包长度自动检测是否有 Flag 字节
  late final AudioPacketReassembler _fileReassembler;

  // Seq 间隙记录 (供 connection 层查询)
  final List<SeqGapRecord> _seqGaps = [];

  NoteBleTransport(this.device) {
    _reassembler = AudioPacketReassembler(
      tag: 'RT',
      onFrameComplete: (seq, frame) {
        _audioDataController.add(frame);
        _seqAudioController.add((seq: seq, frame: frame));
      },
      onSeqGap: (expectedSeq, receivedSeq) {
        _seqGaps.add(SeqGapRecord(startSeq: expectedSeq, endSeq: receivedSeq - 1, detectedAt: DateTime.now()));
        // 保留最近 100 条间隙记录，防止内存泄漏
        if (_seqGaps.length > 100) {
          _seqGaps.removeRange(0, _seqGaps.length - 100);
        }
      },
    );
    _fileReassembler = AudioPacketReassembler(
      tag: 'FILE',
      onFrameComplete: (seq, frame) {
        _fileDataController.add(frame);
      },
      onSeqGap: (expectedSeq, receivedSeq) {
        // 文件上传是顺序传输，间隙仅用于日志诊断
        print('[NoteBleTransport] ⚠️ 文件上传 Seq 间隙: 期望=$expectedSeq, 收到=$receivedSeq');
      },
    );
  }

  /// 获取当前协商的 MTU 值
  int get negotiatedMtu => _negotiatedMtu;

  /// 处理补传音频数据包 (供 connection 层调用)
  /// 格式与实时音频包一致: [Seq 4B] [Flag 1B] [Data]
  void processRetransmitAudioData(List<int> audioPacketData) {
    _reassembler.process(audioPacketData);
  }

  /// 重置实时音频重组器 (新文件开始或重连时调用)
  void resetReassembler({String? fileName}) {
    _reassembler.reset(fileName: fileName);
  }

  /// 重置文件上传状态 (新文件上传开始时调用)
  ///
  /// 根据文件扩展名自动切换传输模式:
  /// - .txt: 纯字节流 (_isRawFileTransfer=true)
  /// - 其他 (如 .opus): [Seq 4B][Audio 480B] 分帧
  void resetFileReassembler({String? fileName}) {
    _fileReassembler.reset(fileName: fileName);
    _filePacketCount = 0;
    _fileChunkBuffer.clear();
    _isRawFileTransfer = fileName != null && fileName.toLowerCase().endsWith('.txt');
    print(
      '[NoteBleTransport] 文件传输模式: '
      '${_isRawFileTransfer ? "纯字节流 (txt)" : "[Seq][480B] 分帧 (opus)"} '
      'file=$fileName',
    );
  }

  /// 恢复 lastCompletedSeq（从持久化状态恢复，供重连后间隙检测）
  void restoreLastCompletedSeq(int seq) {
    _reassembler.restoreLastCompletedSeq(seq);
  }

  /// 获取重组器统计信息
  int get completedFrameCount => _reassembler.completedFrameCount;
  int get lastCompletedSeq => _reassembler.lastCompletedSeq;

  /// 获取 Seq 间隙记录列表
  List<SeqGapRecord> get seqGaps => List.unmodifiable(_seqGaps);

  /// 清除 Seq 间隙记录
  void clearSeqGaps() => _seqGaps.clear();

  @override
  String get deviceId => device.id;

  @override
  Stream<MPDeviceTransportState> get connectionStateStream => _connectionStateController.stream;

  /// 音频数据流 (设备→APP, 已解析的纯 Opus 帧)
  Stream<List<int>> get audioStream => _audioDataController.stream;

  /// 带 Seq 的音频流 (供文件写入使用)
  Stream<({int seq, List<int> frame})> get seqAudioStream => _seqAudioController.stream;

  /// 响应数据流 (设备→APP)
  Stream<List<int>> get responseStream => _responseDataController.stream;

  /// 文件数据流 (设备→APP)
  Stream<List<int>> get fileStream => _fileDataController.stream;

  /// 日志数据流 (设备→APP)
  Stream<List<int>> get logStream => _logDataController.stream;

  /// 验证设备是否正在广播
  /// 返回: 是否找到设备广播
  Future<bool> _verifyDeviceAdvertisement() async {
    print('[NoteBleTransport] ════════ 广播验证开始 ════════');
    print('[NoteBleTransport]   目标设备: ${device.name} (${device.id})');
    print('[NoteBleTransport]   期望服务: ${NoteUUIDs.service}');
    print('[NoteBleTransport]   超时: ${_kAdvertisementVerifyTimeoutSec}秒');

    final completer = Completer<bool>();
    StreamSubscription<DiscoveredDevice>? scanSubscription;

    try {
      scanSubscription = _ble
          .scanForDevices(
            withServices: [], // 扫描所有设备
            scanMode: ScanMode.lowLatency,
          )
          .listen(
            (discoveredDevice) {
              // 检查是否是目标设备
              if (discoveredDevice.id.toLowerCase() == device.id.toLowerCase()) {
                print('[NoteBleTransport] -------- 发现目标设备 --------');
                print('[NoteBleTransport]   名称: ${discoveredDevice.name}');
                print('[NoteBleTransport]   MAC: ${discoveredDevice.id}');
                print('[NoteBleTransport]   RSSI: ${discoveredDevice.rssi} dBm');
                print('[NoteBleTransport]   可连接: ${discoveredDevice.connectable}');

                // 打印广播的服务 UUID
                if (discoveredDevice.serviceUuids.isNotEmpty) {
                  print('[NoteBleTransport]   广播服务UUID:');
                  for (final uuid in discoveredDevice.serviceUuids) {
                    final isNoteService = uuid.toString().toLowerCase() == NoteUUIDs.service.toString().toLowerCase();
                    print('[NoteBleTransport]     - $uuid ${isNoteService ? "✓ Note服务" : ""}');
                  }
                } else {
                  print('[NoteBleTransport]   广播服务UUID: (无)');
                }

                // 打印制造商数据 (原始字节)
                if (discoveredDevice.manufacturerData.isNotEmpty) {
                  final hexData = discoveredDevice.manufacturerData
                      .map((e) => e.toRadixString(16).padLeft(2, '0'))
                      .join(' ');
                  print('[NoteBleTransport]   制造商数据: $hexData');
                }

                // 打印服务数据
                if (discoveredDevice.serviceData.isNotEmpty) {
                  print('[NoteBleTransport]   服务数据:');
                  discoveredDevice.serviceData.forEach((uuid, value) {
                    final hexData = value.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
                    print('[NoteBleTransport]     $uuid: $hexData');
                  });
                }

                print('[NoteBleTransport] --------------------------------');

                if (!completer.isCompleted) {
                  completer.complete(true);
                }
              }
            },
            onError: (error) {
              print('[NoteBleTransport] 扫描错误: $error');
              if (!completer.isCompleted) {
                completer.complete(false);
              }
            },
          );

      // 等待超时或找到设备
      final found = await completer.future.timeout(
        Duration(seconds: _kAdvertisementVerifyTimeoutSec),
        onTimeout: () {
          print('[NoteBleTransport] ✗ 广播验证超时: 未发现目标设备');
          print('[NoteBleTransport]   可能原因:');
          print('[NoteBleTransport]   1. 设备未开机或不在广播状态');
          print('[NoteBleTransport]   2. 设备已被其他手机连接');
          print('[NoteBleTransport]   3. 设备不在蓝牙范围内');
          print('[NoteBleTransport]   4. 设备MAC地址不匹配');
          return false;
        },
      );

      print('[NoteBleTransport] ════════ 广播验证结束 ════════');
      print('[NoteBleTransport]   结果: ${found ? "✓ 设备在广播" : "✗ 未发现设备"}');

      return found;
    } finally {
      await scanSubscription?.cancel();
    }
  }

  @override
  Future<void> connect() async {
    if (_currentState == MPDeviceTransportState.connected) {
      print('[NoteBleTransport] 设备已连接,跳过连接');
      return;
    }

    // 停止 flutter_blue_plus 的扫描，避免库冲突
    if (fbp.FlutterBluePlus.isScanningNow) {
      await fbp.FlutterBluePlus.stopScan();
      print('[NoteBleTransport] 已停止 flutter_blue_plus 扫描');
    }

    await _connectionSubscription?.cancel();
    _updateState(MPDeviceTransportState.connecting);

    // 重置重组器状态 (重连时清除旧缓存)
    _reassembler.reset();
    _fileReassembler.reset();
    _seqGaps.clear();

    print('[NoteBleTransport] ════════════════════════════════════════');
    print('[NoteBleTransport] 开始连接设备');
    print('[NoteBleTransport]   名称: ${device.name}');
    print('[NoteBleTransport]   MAC: ${device.id}');
    print('[NoteBleTransport]   类型: ${device.type}');
    print('[NoteBleTransport]   期望服务UUID: ${NoteUUIDs.service}');
    print('[NoteBleTransport]   连接超时: 10秒');
    print('[NoteBleTransport]   当前时间: ${DateTime.now()}');
    print('[NoteBleTransport] ════════════════════════════════════════');

    // 先验证设备是否正在广播
    final isAdvertising = await _verifyDeviceAdvertisement();
    if (!isAdvertising) {
      _updateState(MPDeviceTransportState.disconnected);
      throw Exception(
        '设备未在广播状态，无法连接。请确认:\n'
        '1. 设备已开机\n'
        '2. 设备未被其他手机连接\n'
        '3. 设备在蓝牙范围内',
      );
    }

    print('[NoteBleTransport] ✓ 广播验证通过，开始GATT连接...');

    // 创建连接完成器
    _connectionCompleter = Completer<void>();

    _connectionSubscription = _ble
        .connectToDevice(id: device.id, connectionTimeout: const Duration(seconds: 10))
        .listen(
          (state) async {
            print('[NoteBleTransport] -------- 状态变化 --------');
            print('[NoteBleTransport]   状态: ${state.connectionState}');
            print('[NoteBleTransport]   设备ID: ${state.deviceId}');
            if (state.failure != null) {
              print('[NoteBleTransport]   失败码: ${state.failure!.code}');
              print('[NoteBleTransport]   失败信息: ${state.failure!.message}');
            }
            print('[NoteBleTransport] --------------------------');

            if (state.connectionState == DeviceConnectionState.connected) {
              try {
                print('[NoteBleTransport] 设备连接成功');

                // #5: 连接稳定等待
                await Future.delayed(const Duration(milliseconds: _kConnectionStabilizeDelayMs));
                print('[NoteBleTransport] 连接稳定等待完成');

                // #1: MTU 交换
                await _exchangeMtu();

                // #3 & #8: 服务发现和验证
                await _discoverAndValidateServices();

                // 订阅特征
                await _subscribeCharacteristics();

                _updateState(MPDeviceTransportState.connected);
                print('[NoteBleTransport] 连接流程完成');

                // 通知连接完成
                if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
                  _connectionCompleter!.complete();
                }
              } catch (e) {
                print('[NoteBleTransport] 连接初始化失败: $e');
                if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
                  _connectionCompleter!.completeError(e);
                }
              }
            } else if (state.connectionState == DeviceConnectionState.disconnected) {
              _updateState(MPDeviceTransportState.disconnected);
              if (state.failure != null) {
                print('[NoteBleTransport] ════════ 连接失败详情 ════════');
                print('[NoteBleTransport]   错误类型: ${state.failure.runtimeType}');
                print('[NoteBleTransport]   错误码: ${state.failure!.code}');
                print('[NoteBleTransport]   错误信息: ${state.failure!.message}');
                print('[NoteBleTransport]   设备ID: ${state.deviceId}');
                print('[NoteBleTransport]   时间: ${DateTime.now()}');
                print('[NoteBleTransport] ════════════════════════════════');
                if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
                  _connectionCompleter!.completeError(state.failure!);
                }
              } else {
                print('[NoteBleTransport] 设备断开连接 (无错误信息)');
              }
            }
          },
          onError: (error) {
            print('[NoteBleTransport] ════════ 连接流错误 ════════');
            print('[NoteBleTransport]   错误类型: ${error.runtimeType}');
            print('[NoteBleTransport]   错误内容: $error');
            print('[NoteBleTransport]   时间: ${DateTime.now()}');
            print('[NoteBleTransport] ══════════════════════════════');
            _handleBleError(error);
            if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
              _connectionCompleter!.completeError(error);
            }
          },
        );

    // 等待连接完成（带超时）
    await _connectionCompleter!.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        print('[NoteBleTransport] ════════ 连接超时 ════════');
        print('[NoteBleTransport]   设备: ${device.name} (${device.id})');
        print('[NoteBleTransport]   超时时间: 15秒');
        print('[NoteBleTransport]   当前状态: $_currentState');
        print('[NoteBleTransport] ══════════════════════════');
        throw Exception('连接超时: 设备未能在15秒内完成连接');
      },
    );
  }

  /// #1: MTU 交换
  Future<void> _exchangeMtu() async {
    try {
      _negotiatedMtu = await _ble.requestMtu(deviceId: device.id, mtu: _kNoteMtuSize);
      print('[NoteBleTransport] MTU 协商成功: $_negotiatedMtu');

      // 计算音频包分包预期
      final payloadPerPacket = _negotiatedMtu - 3 - AudioPacketConstants.headerSizeWithFlag; // ATT header + 音频包头(含Flag)
      final expectedParts = (AudioPacketConstants.frameSize / payloadPerPacket).ceil();
      final noFlagFits =
          (_negotiatedMtu - 3) >= (AudioPacketConstants.headerSizeSeqOnly + AudioPacketConstants.frameSize);
      print(
        '[NoteBleTransport] 音频分包预期: MTU=$_negotiatedMtu, '
        '每包载荷=${payloadPerPacket}B, 预计分${expectedParts}包/帧'
        '${noFlagFits ? " (无Flag单包可行)" : ""}',
      );
    } catch (e) {
      print('[NoteBleTransport] MTU 协商失败: $e, 使用默认值');
      // MTU 协商失败不中断连接，使用默认值
      _negotiatedMtu = 23;
    }
  }

  /// #3 & #8: 服务发现和验证
  Future<void> _discoverAndValidateServices() async {
    try {
      print('[NoteBleTransport] ======== 服务发现开始 ========');
      print('[NoteBleTransport] 超时设置: ${_kServiceDiscoveryTimeoutSec}秒');

      // 显式发现服务（带超时）
      await _ble.discoverAllServices(device.id).timeout(const Duration(seconds: _kServiceDiscoveryTimeoutSec));

      // 获取已发现的服务列表
      final discoveredServices = await _ble.getDiscoveredServices(device.id);
      print('[NoteBleTransport] -------- 发现 ${discoveredServices.length} 个服务 --------');

      // 打印所有服务 UUID（详细对比）
      final expectedUuid = NoteUUIDs.service.toString().toLowerCase();
      bool foundNoteService = false;

      for (int i = 0; i < discoveredServices.length; i++) {
        final service = discoveredServices[i];
        final serviceUuid = service.id.toString().toLowerCase();
        final isMatch = serviceUuid == expectedUuid;
        final marker = isMatch ? '✓ MATCH' : '';
        print('[NoteBleTransport]   [$i] $serviceUuid $marker');
        if (isMatch) foundNoteService = true;
      }

      print('[NoteBleTransport] -------- UUID 对比 --------');
      print('[NoteBleTransport]   期望: $expectedUuid');
      print('[NoteBleTransport]   匹配: ${foundNoteService ? "是 ✓" : "否 ✗"}');

      // 打印所有服务 UUID
      for (int i = 0; i < discoveredServices.length; i++) {
        final service = discoveredServices[i];
        print('[NoteBleTransport] 服务[$i]: ${service.id}');
      }

      // 验证 Note 服务是否存在
      if (!foundNoteService) {
        print('[NoteBleTransport] ✗ 服务验证失败!');
        throw Exception('设备不支持 Note 服务 (UUID: ${NoteUUIDs.service})');
      }
      print('[NoteBleTransport] ✓ Note 服务验证通过');
      print('[NoteBleTransport] ======== 服务发现完成 ========');
    } catch (e) {
      print('[NoteBleTransport] ✗ 服务发现/验证失败: $e');
      await disconnect();
      rethrow;
    }
  }

  /// 订阅所有特征
  Future<void> _subscribeCharacteristics() async {
    try {
      // ======== 订阅音频数据特征 (V1.0 协议: Seq+Flag+Data) ========
      final audioChar = QualifiedCharacteristic(
        serviceId: NoteUUIDs.service,
        characteristicId: NoteUUIDs.audioData,
        deviceId: device.id,
      );
      int rawPacketCount = 0;
      print('[BLE Audio] 开始订阅 UUID301 音频特征 (V1.0 协议)...');
      _audioSubscription = _ble
          .subscribeToCharacteristic(audioChar)
          .listen(
            (data) {
              rawPacketCount++;

              // 前10个包打印原始信息便于调试格式
              if (rawPacketCount <= 10) {
                String headerInfo = '';
                if (data.length >= AudioPacketConstants.headerSizeSeqOnly) {
                  final seq = AudioPacketConstants.parseSeq(data);
                  final isNoFlag =
                      (data.length == AudioPacketConstants.headerSizeSeqOnly + AudioPacketConstants.frameSize);
                  if (isNoFlag) {
                    headerInfo = 'seq=$seq (无Flag格式, ${data.length}B)';
                  } else if (data.length >= AudioPacketConstants.headerSizeWithFlag) {
                    final flag = data[4];
                    final total = AudioPacketConstants.getFlagTotal(flag);
                    final index = AudioPacketConstants.getFlagIndex(flag);
                    headerInfo =
                        'seq=$seq, flag=0x${flag.toRadixString(16)}'
                        '${total > 0 ? " (part ${index + 1}/$total)" : " (单包)"}';
                  }
                } else {
                  headerInfo = '包太小(${data.length}B)!';
                }
                print('[BLE Audio] 原始包#$rawPacketCount: ${data.length}bytes, $headerInfo');
              }

              _reassembler.process(data);
            },
            onError: (error) {
              print('[BLE Audio] ❌ 订阅错误: $error');
              print(
                '[BLE Audio] ❌ 已收到 $rawPacketCount 原始包, '
                '已完成 ${_reassembler.completedFrameCount} 帧后出错',
              );
              _handleSubscriptionError('音频', error);
            },
            onDone: () {
              print(
                '[BLE Audio] ⚠️ 音频流结束! 共收到 $rawPacketCount 原始包, '
                '已完成 ${_reassembler.completedFrameCount} 帧',
              );
            },
            cancelOnError: false,
          );
      print('[BLE Audio] ✓ UUID301 订阅已建立 (V1.0 协议)');

      // 订阅响应特征
      final responseChar = QualifiedCharacteristic(
        serviceId: NoteUUIDs.service,
        characteristicId: NoteUUIDs.response,
        deviceId: device.id,
      );
      _responseSubscription = _ble
          .subscribeToCharacteristic(responseChar)
          .listen(
            (data) => _responseDataController.add(data),
            onError: (error) => _handleSubscriptionError('响应', error),
          );

      // 订阅文件数据特征
      final fileChar = QualifiedCharacteristic(
        serviceId: NoteUUIDs.service,
        characteristicId: NoteUUIDs.recordFile,
        deviceId: device.id,
      );
      _fileSubscription = _ble.subscribeToCharacteristic(fileChar).listen((data) {
        if (_filePacketCount < 3) {
          final headHex = data.take(8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
          print(
            '[FILE-BLE] 通知#$_filePacketCount: len=${data.length}, head=[$headHex]'
            '${_isRawFileTransfer ? " (raw)" : ""}',
          );
        }
        _filePacketCount++;

        // 纯字节流模式 (txt): 直接输出 BLE notification 内容
        if (_isRawFileTransfer) {
          _fileDataController.add(List<int>.from(data));
          return;
        }

        // 音频分帧模式 (opus): 格式 [Seq 4B][Audio 480B] = 484B/chunk
        // chunk 边界与 BLE 通知不对齐，需要流式分帧
        _fileChunkBuffer.addAll(data);
        while (_fileChunkBuffer.length >= _fileChunkSize) {
          final audioData = _fileChunkBuffer.sublist(_fileSeqSize, _fileChunkSize);
          _fileDataController.add(audioData);
          _fileChunkBuffer = _fileChunkBuffer.sublist(_fileChunkSize);
        }
      }, onError: (error) => _handleSubscriptionError('文件', error));

      // 订阅日志数据特征
      final logChar = QualifiedCharacteristic(
        serviceId: NoteUUIDs.service,
        characteristicId: NoteUUIDs.logFile,
        deviceId: device.id,
      );
      _logSubscription = _ble
          .subscribeToCharacteristic(logChar)
          .listen((data) => _logDataController.add(data), onError: (error) => _handleSubscriptionError('日志', error));

      print('[NoteBleTransport] 所有特征订阅完成');
    } catch (e) {
      print('[NoteBleTransport] 订阅特征失败: $e');
      rethrow;
    }
  }

  /// #6: 处理订阅错误
  void _handleSubscriptionError(String name, dynamic error) {
    print('[NoteBleTransport] $name订阅错误: $error');
    // 只记录错误，不断开连接
    // 部分特征可能不存在（取决于设备固件版本），这不应该影响整体连接
  }

  /// #6: 统一处理 BLE 错误
  void _handleBleError(dynamic error) {
    // 检查是否为断开连接异常
    if (error.toString().contains('Disconnected') || error.toString().contains('disconnected')) {
      print('[NoteBleTransport] 检测到设备断开连接');
      _updateState(MPDeviceTransportState.disconnected);
      _cancelAllSubscriptions();
    } else {
      _updateState(MPDeviceTransportState.disconnected);
    }
  }

  @override
  Future<void> disconnect() async {
    if (_currentState == MPDeviceTransportState.disconnected) {
      return;
    }

    _updateState(MPDeviceTransportState.disconnecting);
    print(
      '[NoteBleTransport] 断开连接 (重组器状态: 已完成=${completedFrameCount}帧, '
      'lastSeq=$lastCompletedSeq)',
    );

    _reassembler.reset();
    _fileReassembler.reset();

    await _cancelAllSubscriptions();

    // #4: 清理 GATT 缓存
    try {
      await _ble.clearGattCache(device.id);
      print('[NoteBleTransport] GATT 缓存已清理');
    } catch (e) {
      print('[NoteBleTransport] 清理 GATT 缓存失败: $e');
    }

    _updateState(MPDeviceTransportState.disconnected);
  }

  /// 取消所有订阅
  Future<void> _cancelAllSubscriptions() async {
    await _connectionSubscription?.cancel();
    await _audioSubscription?.cancel();
    await _responseSubscription?.cancel();
    await _fileSubscription?.cancel();
    await _logSubscription?.cancel();

    _connectionSubscription = null;
    _audioSubscription = null;
    _responseSubscription = null;
    _fileSubscription = null;
    _logSubscription = null;
  }

  @override
  Future<bool> isConnected() async {
    return _currentState == MPDeviceTransportState.connected;
  }

  @override
  Future<bool> ping() async {
    // Note 设备可以通过查询电量来验证连接
    try {
      await sendCommand([NoteCommands.queryBattery]);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<List<int>> getCharacteristicStream(String serviceUuid, String characteristicUuid) {
    // 根据特征 UUID 返回对应的流
    final uuid = characteristicUuid.toLowerCase();

    if (uuid == NoteUUIDs.audioData.toString().toLowerCase()) {
      return audioStream;
    } else if (uuid == NoteUUIDs.response.toString().toLowerCase()) {
      return responseStream;
    } else if (uuid == NoteUUIDs.recordFile.toString().toLowerCase()) {
      return fileStream;
    } else if (uuid == NoteUUIDs.logFile.toString().toLowerCase()) {
      return logStream;
    }

    // 不支持的特征,返回空流
    return const Stream<List<int>>.empty();
  }

  @override
  Future<List<int>> readCharacteristic(String serviceUuid, String characteristicUuid) async {
    // flutter_reactive_ble 主要通过订阅来读取数据
    // 这里可以实现一个简单的读取逻辑
    final char = QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(characteristicUuid),
      deviceId: device.id,
    );

    try {
      return await _ble.readCharacteristic(char);
    } catch (e) {
      print('[NoteBleTransport] 读取特征失败: $e');
      return [];
    }
  }

  @override
  Future<void> writeCharacteristic(String serviceUuid, String characteristicUuid, List<int> data) async {
    final char = QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(characteristicUuid),
      deviceId: device.id,
    );

    try {
      await _ble.writeCharacteristicWithoutResponse(char, value: data);
    } catch (e) {
      print('[NoteBleTransport] 写入特征失败: $e');
      rethrow;
    }
  }

  /// 发送命令 (写入命令特征,无需响应)
  Future<void> sendCommand(List<int> command) async {
    final commandChar = QualifiedCharacteristic(
      serviceId: NoteUUIDs.service,
      characteristicId: NoteUUIDs.command,
      deviceId: device.id,
    );

    await _ble.writeCharacteristicWithoutResponse(commandChar, value: command);

    final hexString = command.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
    print('[NoteBleTransport] 命令已发送: $hexString');
  }

  /// 发送 OTA 文件数据 (使用有响应写入)
  Future<void> sendOtaData(List<int> data) async {
    final otaChar = QualifiedCharacteristic(
      serviceId: NoteUUIDs.service,
      characteristicId: NoteUUIDs.otaFile,
      deviceId: device.id,
    );

    await _ble.writeCharacteristicWithResponse(otaChar, value: data);
  }

  /// 更新连接状态
  void _updateState(MPDeviceTransportState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _connectionStateController.add(newState);
    }
  }

  @override
  Future<void> dispose() async {
    _reassembler.dispose();
    _fileReassembler.dispose();
    await disconnect();
    await _connectionStateController.close();
    await _audioDataController.close();
    await _seqAudioController.close();
    await _responseDataController.close();
    await _fileDataController.close();
    await _logDataController.close();
  }
}

/// Seq 间隙记录
///
/// 记录检测到的 Seq 不连续事件，供补传逻辑使用
class SeqGapRecord {
  /// 缺失的起始 Seq (含)
  final int startSeq;

  /// 缺失的结束 Seq (含)
  final int endSeq;

  /// 检测时间
  final DateTime detectedAt;

  SeqGapRecord({required this.startSeq, required this.endSeq, required this.detectedAt});

  /// 缺失帧数
  int get missingCount => endSeq - startSeq + 1;

  @override
  String toString() => 'SeqGap($startSeq~$endSeq, ${missingCount}帧, $detectedAt)';
}
