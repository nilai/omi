/// MemoPin BLE 传输层：与 `ble/note_ble_transport.dart` [NoteBleTransport] 行为对齐，
/// 使用 `flutter_reactive_ble` 连接与 GATT；扫描侧仍可用 `flutter_blue_plus` 的 [fbp.BluetoothDevice] 携带 `remoteId`。
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'mp_device_transport.dart';
import 'mp_note_audio_packet_reassembler.dart';
import 'mp_note_ble_protocol.dart';

const int _kNoteMtuSize = 517;
const int _kConnectionStabilizeDelayMs = 200;
const int _kServiceDiscoveryTimeoutSec = 10;
const int _kAdvertisementVerifyTimeoutSec = 5;
/// FBP 停扫后等待射频释放，再交给 reactive_ble 扫描/连接。
const int _kBleRadioSettleDelayMs = 400;
const int _kAdvertisementVerifyMaxAttempts = 3;

/// MemoPin Note 服务 BLE 传输实现（与 [NoteBleTransport] 能力对齐）。
class MPBleTransport extends MPDeviceTransport {
  /// 使用已发现的 FBP 设备构造；连接时以 [fbp.BluetoothDevice.remoteId] 作为 `flutter_reactive_ble` 设备 ID。
  MPBleTransport(this._fbpDevice) : _deviceId = _fbpDevice.remoteId.str {
    _reassembler = MPAudioPacketReassembler(
      tag: 'MPBle',
      onFrameComplete: (int seq, List<int> frame) {
        if (!_audioDataController.isClosed) {
          _audioDataController.add(frame);
        }
        if (!_seqAudioController.isClosed) {
          _seqAudioController.add((seq: seq, frame: frame));
        }
      },
      onSeqGap: (int expectedSeq, int receivedSeq) {
        _seqGaps.add(MPSeqGapRecord(startSeq: expectedSeq, endSeq: receivedSeq - 1, detectedAt: DateTime.now()));
        if (_seqGaps.length > 100) {
          _seqGaps.removeRange(0, _seqGaps.length - 100);
        }
        debugPrint('MPBleTransport audio seq gap: expected=$expectedSeq received=$receivedSeq deviceId=$_deviceId');
      },
    );
  }

  final fbp.BluetoothDevice _fbpDevice;
  final String _deviceId;
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  final StreamController<MPDeviceTransportState> _connectionStateController =
      StreamController<MPDeviceTransportState>.broadcast();
  final StreamController<List<int>> _audioDataController = StreamController<List<int>>.broadcast();
  final StreamController<({int seq, List<int> frame})> _seqAudioController =
      StreamController<({int seq, List<int> frame})>.broadcast();
  final StreamController<List<int>> _responseDataController = StreamController<List<int>>.broadcast();
  final StreamController<List<int>> _fileDataController = StreamController<List<int>>.broadcast();
  final StreamController<List<int>> _logDataController = StreamController<List<int>>.broadcast();
  final StreamController<List<int>> _raw301Controller = StreamController<List<int>>.broadcast();

  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _audioSubscription;
  StreamSubscription<List<int>>? _responseSubscription;
  StreamSubscription<List<int>>? _fileSubscription;
  StreamSubscription<List<int>>? _logSubscription;

  MPDeviceTransportState _currentState = MPDeviceTransportState.disconnected;
  int _negotiatedMtu = 23;
  Completer<void>? _connectionCompleter;
  Completer<void>? _gattSubscriptionsCompleter;

  late final MPAudioPacketReassembler _reassembler;

  final List<MPSeqGapRecord> _seqGaps = <MPSeqGapRecord>[];

  int _filePacketCount = 0;
  List<int> _fileChunkBuffer = <int>[];
  bool _isRawFileTransfer = false;

  /// 与 [NoteBleTransport.negotiatedMtu] 一致。
  int get negotiatedMtu => _negotiatedMtu;

  /// 与 [NoteBleTransport.audioStream] 一致：301 重组后的 480B Opus 帧。
  Stream<List<int>> get audioStream => _audioDataController.stream;

  /// 与 [NoteBleTransport.seqAudioStream] 一致。
  Stream<({int seq, List<int> frame})> get seqAudioStream => _seqAudioController.stream;

  /// 与 [NoteBleTransport.responseStream] 一致：303 原始 notify。
  Stream<List<int>> get responseStream => _responseDataController.stream;

  /// 与 [NoteBleTransport.fileStream] 一致：305 重组/透传后的载荷。
  Stream<List<int>> get fileStream => _fileDataController.stream;

  /// 与 [NoteBleTransport.logStream] 一致：306 原始 notify。
  Stream<List<int>> get logStream => _logDataController.stream;

  /// 与 [NoteBleTransport.lastCompletedSeq] 一致。
  int get lastCompletedSeq => _reassembler.lastCompletedSeq;

  /// 与 [NoteBleTransport.completedFrameCount] 一致。
  int get completedFrameCount => _reassembler.completedFrameCount;

  /// 与 [NoteBleTransport.seqGaps] 一致。
  List<MPSeqGapRecord> get seqGaps => List<MPSeqGapRecord>.unmodifiable(_seqGaps);

  /// 与 [NoteBleTransport.clearSeqGaps] 一致。
  void clearSeqGaps() => _seqGaps.clear();

  /// 与 [NoteBleTransport.processRetransmitAudioData] 一致。
  void processRetransmitAudioData(List<int> audioPacketData) {
    _reassembler.process(audioPacketData);
  }

  @override
  String get deviceId => _deviceId;

  @override
  Stream<MPDeviceTransportState> get connectionStateStream => _connectionStateController.stream;

  Future<void> _awaitGattSubscriptionsReady() async {
    final Completer<void>? c = _gattSubscriptionsCompleter;
    if (c != null && !c.isCompleted) {
      await c.future;
    }
  }

  /// 与连接后 notify 管线就绪语义一致；等价于在订阅 [audioStream]/[responseStream] 前完成 `NoteBleTransport` 侧 `_subscribeCharacteristics`。
  Future<void> ensureGattSubscriptionsReady() => _awaitGattSubscriptionsReady();

  /// 与 [NoteBleTransport.resetReassembler] 一致。
  void resetRealtimeAudioReassembly({String? fileName}) {
    _reassembler.reset(fileName: fileName);
  }

  /// 与 [NoteBleTransport.resetFileReassembler] 一致（仅重置 305 文件流分帧状态，不影响 301 实时重组器）。
  void resetFileReassembler({String? fileName}) {
    _filePacketCount = 0;
    _fileChunkBuffer.clear();
    _isRawFileTransfer = fileName != null && fileName.toLowerCase().endsWith('.txt');
    debugPrint(
      'MPBleTransport 文件传输模式: ${_isRawFileTransfer ? "纯字节流 (txt)" : "[Seq][480B] 分帧 (opus)"} file=$fileName',
    );
  }

  /// 与 [NoteBleTransport.restoreLastCompletedSeq] 一致。
  void restoreLastCompletedSeq(int seq) {
    _reassembler.restoreLastCompletedSeq(seq);
  }

  @override
  Future<void> connect({bool skipAdvertisementVerify = false}) async {
    if (_currentState == MPDeviceTransportState.connected) {
      return;
    }

    final bool wasScanning = fbp.FlutterBluePlus.isScanningNow;
    if (wasScanning) {
      await fbp.FlutterBluePlus.stopScan();
      debugPrint('MPBleTransport 已停止 flutter_blue_plus 扫描');
    }
    if (wasScanning || skipAdvertisementVerify) {
      await Future<void>.delayed(const Duration(milliseconds: _kBleRadioSettleDelayMs));
    }

    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _updateState(MPDeviceTransportState.connecting);

    _reassembler.reset();
    _seqGaps.clear();
    _fileChunkBuffer.clear();
    _filePacketCount = 0;
    _isRawFileTransfer = false;

    _connectionCompleter = Completer<void>();
    _gattSubscriptionsCompleter = Completer<void>();

    final bool advertising = skipAdvertisementVerify || await _verifyDeviceAdvertisement();
    if (!advertising) {
      _updateState(MPDeviceTransportState.disconnected);
      if (!_gattSubscriptionsCompleter!.isCompleted) {
        _gattSubscriptionsCompleter!.completeError(
          Exception(
            '设备未在广播状态，无法连接。请确认:\n'
            '1. 设备已开机\n'
            '2. 设备未被其他手机连接\n'
            '3. 设备在蓝牙范围内',
          ),
        );
      }
      if (!_connectionCompleter!.isCompleted) {
        _connectionCompleter!.completeError(Exception('设备未在广播状态'));
      }
      throw Exception('设备未在广播状态，无法连接');
    }

    _connectionSubscription = _ble
        .connectToDevice(id: _deviceId, connectionTimeout: const Duration(seconds: 10))
        .listen(
          (ConnectionStateUpdate state) async {
            debugPrint('MPBleTransport 连接状态: ${state.connectionState} device=${state.deviceId}');
            if (state.connectionState == DeviceConnectionState.connected) {
              try {
                await Future<void>.delayed(const Duration(milliseconds: _kConnectionStabilizeDelayMs));
                await _exchangeMtu();
                await _discoverAndValidateServices();
                await _subscribeCharacteristics();
                if (!_gattSubscriptionsCompleter!.isCompleted) {
                  _gattSubscriptionsCompleter!.complete();
                }
                _updateState(MPDeviceTransportState.connected);
                if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
                  _connectionCompleter!.complete();
                }
              } catch (e, st) {
                debugPrint('MPBleTransport 连接初始化失败: $e\n$st');
                if (!_gattSubscriptionsCompleter!.isCompleted) {
                  _gattSubscriptionsCompleter!.completeError(e);
                }
                if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
                  _connectionCompleter!.completeError(e);
                }
              }
            } else if (state.connectionState == DeviceConnectionState.disconnected) {
              _updateState(MPDeviceTransportState.disconnected);
              if (state.failure != null && _connectionCompleter != null && !_connectionCompleter!.isCompleted) {
                _connectionCompleter!.completeError(state.failure!);
              }
            }
          },
          onError: (Object error, StackTrace st) {
            debugPrint('MPBleTransport 连接流错误: $error\n$st');
            if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
              _connectionCompleter!.completeError(error, st);
            }
          },
        );

    await _connectionCompleter!.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('连接超时: 设备未能在15秒内完成连接');
      },
    );
  }

  /// 在连接前确认目标仍在广播；FBP 刚停扫时 reactive_ble 首轮可能漏检，故带有限次重试。
  Future<bool> _verifyDeviceAdvertisement() async {
    for (int attempt = 1; attempt <= _kAdvertisementVerifyMaxAttempts; attempt++) {
      final bool found = await _verifyDeviceAdvertisementOnce(attempt: attempt);
      if (found) {
        return true;
      }
      if (attempt < _kAdvertisementVerifyMaxAttempts) {
        debugPrint('MPBleTransport 广播验证第 $attempt 次未找到 $_deviceId，${_kBleRadioSettleDelayMs}ms 后重试');
        await Future<void>.delayed(const Duration(milliseconds: _kBleRadioSettleDelayMs));
      }
    }
    return false;
  }

  Future<bool> _verifyDeviceAdvertisementOnce({required int attempt}) async {
    debugPrint(
      'MPBleTransport 广播验证($attempt/$_kAdvertisementVerifyMaxAttempts): $_deviceId (${_fbpDevice.platformName})',
    );
    final Completer<bool> found = Completer<bool>();
    StreamSubscription<DiscoveredDevice>? sub;
    try {
      sub = _ble
          .scanForDevices(withServices: <Uuid>[], scanMode: ScanMode.lowLatency)
          .listen(
            (DiscoveredDevice d) {
              if (d.id.toLowerCase() == _deviceId.toLowerCase() && !found.isCompleted) {
                found.complete(true);
              }
            },
            onError: (Object e) {
              debugPrint('MPBleTransport 广播验证扫描错误: $e');
              if (!found.isCompleted) {
                found.complete(false);
              }
            },
          );
      return await found.future.timeout(
        Duration(seconds: _kAdvertisementVerifyTimeoutSec),
        onTimeout: () => false,
      );
    } finally {
      await sub?.cancel();
    }
  }

  Future<void> _exchangeMtu() async {
    try {
      _negotiatedMtu = await _ble.requestMtu(deviceId: _deviceId, mtu: _kNoteMtuSize);
      debugPrint('MPBleTransport MTU 协商成功: $_negotiatedMtu');
    } catch (e) {
      debugPrint('MPBleTransport MTU 协商失败: $e, 使用默认值');
      _negotiatedMtu = 23;
    }
  }

  Future<void> _discoverAndValidateServices() async {
    await _ble.discoverAllServices(_deviceId).timeout(Duration(seconds: _kServiceDiscoveryTimeoutSec));
    final List<Service> services = await _ble.getDiscoveredServices(_deviceId);
    final String expected = MPNoteBleUUIDs.service.toString().toLowerCase();
    final bool ok = services.any((Service s) => s.id.toString().toLowerCase() == expected);
    if (!ok) {
      throw Exception('设备不支持 Note 服务 (UUID: ${MPNoteBleUUIDs.service})');
    }
  }

  Future<void> _subscribeCharacteristics() async {
    final QualifiedCharacteristic audioChar = QualifiedCharacteristic(
      serviceId: MPNoteBleUUIDs.service,
      characteristicId: MPNoteBleUUIDs.audioData,
      deviceId: _deviceId,
    );
    int rawCount = 0;
    _audioSubscription = _ble.subscribeToCharacteristic(audioChar).listen(
      (List<int> data) {
        rawCount++;
        if (rawCount <= 10) {
          debugPrint('MPBleTransport BLE Audio 原始包#$rawCount: ${data.length}B');
        }
        if (!_raw301Controller.isClosed) {
          _raw301Controller.add(List<int>.from(data));
        }
        _reassembler.process(data);
      },
      onError: (Object e, StackTrace st) => debugPrint('MPBleTransport 301 订阅错误: $e\n$st'),
      cancelOnError: false,
    );

    final QualifiedCharacteristic responseChar = QualifiedCharacteristic(
      serviceId: MPNoteBleUUIDs.service,
      characteristicId: MPNoteBleUUIDs.response,
      deviceId: _deviceId,
    );
    _responseSubscription = _ble.subscribeToCharacteristic(responseChar).listen(
      (List<int> data) {
        if (!_responseDataController.isClosed) {
          _responseDataController.add(data);
        }
      },
      onError: (Object e, StackTrace st) => debugPrint('MPBleTransport 303 订阅错误: $e\n$st'),
      cancelOnError: false,
    );

    final QualifiedCharacteristic fileChar = QualifiedCharacteristic(
      serviceId: MPNoteBleUUIDs.service,
      characteristicId: MPNoteBleUUIDs.recordFile,
      deviceId: _deviceId,
    );
    _fileSubscription = _ble.subscribeToCharacteristic(fileChar).listen(
      (List<int> data) {
        if (_filePacketCount < 3) {
          final String headHex = data.take(8).map((int b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
          debugPrint(
            'MPBleTransport FILE notify#$_filePacketCount: len=${data.length}, head=[$headHex'
            '${_isRawFileTransfer ? " (raw)" : ""}]',
          );
        }
        _filePacketCount++;
        if (_isRawFileTransfer) {
          if (!_fileDataController.isClosed) {
            _fileDataController.add(List<int>.from(data));
          }
          return;
        }
        _fileChunkBuffer.addAll(data);
        while (_fileChunkBuffer.length >= MPNoteBleFileTransferConstants.notifyChunkBytes) {
          final List<int> opusFrame = _fileChunkBuffer.sublist(
            MPNoteBleFileTransferConstants.seqPrefixBytes,
            MPNoteBleFileTransferConstants.notifyChunkBytes,
          );
          if (!_fileDataController.isClosed) {
            _fileDataController.add(opusFrame);
          }
          _fileChunkBuffer = _fileChunkBuffer.sublist(MPNoteBleFileTransferConstants.notifyChunkBytes);
        }
      },
      onError: (Object e, StackTrace st) => debugPrint('MPBleTransport 305 订阅错误: $e\n$st'),
      cancelOnError: false,
    );

    final QualifiedCharacteristic logChar = QualifiedCharacteristic(
      serviceId: MPNoteBleUUIDs.service,
      characteristicId: MPNoteBleUUIDs.logFile,
      deviceId: _deviceId,
    );
    _logSubscription = _ble.subscribeToCharacteristic(logChar).listen(
      (List<int> data) {
        if (!_logDataController.isClosed) {
          _logDataController.add(data);
        }
      },
      onError: (Object e, StackTrace st) => debugPrint('MPBleTransport 306 订阅错误: $e\n$st'),
      cancelOnError: false,
    );
  }

  Future<void> _cancelCharacteristicSubscriptions() async {
    await _audioSubscription?.cancel();
    await _responseSubscription?.cancel();
    await _fileSubscription?.cancel();
    await _logSubscription?.cancel();
    _audioSubscription = null;
    _responseSubscription = null;
    _fileSubscription = null;
    _logSubscription = null;
  }

  void _updateState(MPDeviceTransportState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(newState);
      }
    }
  }

  @override
  Future<void> disconnect() async {
    if (_currentState == MPDeviceTransportState.disconnected) {
      return;
    }
    _updateState(MPDeviceTransportState.disconnecting);
    debugPrint(
      'MPBleTransport 断开连接 (已完成帧=$completedFrameCount, lastSeq=$lastCompletedSeq)',
    );
    _reassembler.reset();
    _fileChunkBuffer.clear();
    _filePacketCount = 0;
    await _cancelCharacteristicSubscriptions();
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    try {
      await _ble.clearGattCache(_deviceId);
    } catch (e) {
      debugPrint('MPBleTransport clearGattCache: $e');
    }
    _updateState(MPDeviceTransportState.disconnected);
  }

  @override
  Future<bool> isConnected() async {
    if (_currentState == MPDeviceTransportState.disconnected ||
        _currentState == MPDeviceTransportState.disconnecting) {
      return false;
    }
    if (_currentState == MPDeviceTransportState.connected) {
      return true;
    }
    // GATT 繁忙时 connectionState 可能瞬时上报 disconnected，但链路仍可用。
    if (_connectionSubscription == null) {
      return false;
    }
    try {
      final int? pct = await readStandardBatteryPercent();
      if (pct != null) {
        _updateState(MPDeviceTransportState.connected);
        return true;
      }
    } catch (_) {
      // ignore
    }
    return false;
  }

  @override
  Future<bool> ping() async {
    if (_currentState != MPDeviceTransportState.connected) {
      return false;
    }
    try {
      await writeCharacteristicWithoutResponse(
        MPNoteBleUUIDs.service.toString(),
        MPNoteBleUUIDs.command.toString(),
        <int>[MPNoteBleCommands.queryBattery],
      );
      return true;
    } catch (e) {
      debugPrint('MPBleTransport ping: $e');
      return false;
    }
  }

  bool _uuidEq(String characteristicUuid, Uuid u) =>
      characteristicUuid.toLowerCase() == u.toString().toLowerCase();

  @override
  Stream<List<int>> getCharacteristicStream(String serviceUuid, String characteristicUuid) {
    if (_uuidEq(characteristicUuid, MPNoteBleUUIDs.audioData)) {
      return _audioDataController.stream;
    }
    if (_uuidEq(characteristicUuid, MPNoteBleUUIDs.response)) {
      return _responseDataController.stream;
    }
    if (_uuidEq(characteristicUuid, MPNoteBleUUIDs.recordFile)) {
      return _fileDataController.stream;
    }
    if (_uuidEq(characteristicUuid, MPNoteBleUUIDs.logFile)) {
      return _logDataController.stream;
    }
    return const Stream<List<int>>.empty();
  }

  /// 与连接后 notify 管线就绪语义一致（对齐 [NoteBleTransport] 订阅完成后再监听）。
  Future<Stream<List<int>>> getCharacteristicStreamWhenReady(String serviceUuid, String characteristicUuid) async {
    if (_uuidEq(characteristicUuid, MPNoteBleUUIDs.audioData) ||
        _uuidEq(characteristicUuid, MPNoteBleUUIDs.response) ||
        _uuidEq(characteristicUuid, MPNoteBleUUIDs.recordFile) ||
        _uuidEq(characteristicUuid, MPNoteBleUUIDs.logFile)) {
      await _awaitGattSubscriptionsReady();
      return getCharacteristicStream(serviceUuid, characteristicUuid);
    }
    return const Stream<List<int>>.empty();
  }

  /// 301 **原始** notify（不经 [MPAudioPacketReassembler]），与历史 [BleTransport] API 对齐。
  Stream<List<int>> getRawCharacteristicNotifyStream(String serviceUuid, String characteristicUuid) {
    if (_uuidEq(characteristicUuid, MPNoteBleUUIDs.audioData)) {
      return _raw301Controller.stream;
    }
    return const Stream<List<int>>.empty();
  }

  /// 先完成 GATT 订阅再返回 [getRawCharacteristicNotifyStream]。
  Future<Stream<List<int>>> getRawCharacteristicNotifyStreamWhenReady(
    String serviceUuid,
    String characteristicUuid,
  ) async {
    await _awaitGattSubscriptionsReady();
    return getRawCharacteristicNotifyStream(serviceUuid, characteristicUuid);
  }

  @override
  Future<List<int>> readCharacteristic(String serviceUuid, String characteristicUuid) async {
    final QualifiedCharacteristic char = QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(characteristicUuid),
      deviceId: _deviceId,
    );
    try {
      return await _ble.readCharacteristic(char);
    } catch (e) {
      debugPrint('MPBleTransport readCharacteristic: $e');
      return <int>[];
    }
  }

  @override
  Future<void> writeCharacteristic(String serviceUuid, String characteristicUuid, List<int> data) {
    return writeCharacteristicWithoutResponse(serviceUuid, characteristicUuid, data);
  }

  /// Note 命令特征需 **Write Without Response**（与 [NoteBleTransport.writeCharacteristic] 一致）。
  Future<void> writeCharacteristicWithoutResponse(
    String serviceUuid,
    String characteristicUuid,
    List<int> data,
  ) async {
    final QualifiedCharacteristic char = QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(characteristicUuid),
      deviceId: _deviceId,
    );
    await _ble.writeCharacteristicWithoutResponse(char, value: data);
  }

  /// 标准 Battery Service 电量百分比（首字节 0–100）；失败返回 `null`。
  Future<int?> readStandardBatteryPercent() async {
    try {
      final List<int> data = await readCharacteristic(
        '0000180f-0000-1000-8000-00805f9b34fb',
        '00002a19-0000-1000-8000-00805f9b34fb',
      );
      if (data.isEmpty) {
        return null;
      }
      return data.first.clamp(0, 100);
    } catch (e) {
      debugPrint('MPBleTransport.readStandardBatteryPercent: $e');
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    _reassembler.dispose();
    await disconnect();
    await _connectionStateController.close();
    await _audioDataController.close();
    await _seqAudioController.close();
    await _responseDataController.close();
    await _fileDataController.close();
    await _logDataController.close();
    await _raw301Controller.close();
  }
}

/// 历史类型别名：连接页与各工具类仍使用 [BleTransport] 名称。
typedef BleTransport = MPBleTransport;
