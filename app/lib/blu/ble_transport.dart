import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:memo_pin/utils/bluetooth/bluetooth_adapter.dart';

import 'device_transport.dart';
import 'mp_note_audio_packet_reassembler.dart';
import 'mp_note_ble_protocol.dart';

class BleTransport extends DeviceTransport {
  final BluetoothDevice _bleDevice;
  final StreamController<DeviceTransportState> _connectionStateController;
  final Map<String, StreamController<List<int>>> _streamControllers = {};
  final Map<String, StreamSubscription<dynamic>> _characteristicSubscriptions = {};
  final Map<String, Future<void>> _characteristicNotifySetupFutures = {};

  /// 在 [disconnect] / [dispose] 时递增，用于丢弃尚未完成的 [_setupCharacteristicListener] 结果。
  int _gattListenerEpoch = 0;

  /// 与 `ble/note_ble_transport.dart` 一致：`301` 重组后的 **480B Opus 帧**；`303` 原始 notify；
  /// `305` / `306` 为文件流与日志流（与 [NoteBleTransport] 分帧/txt 模式一致）。
  final StreamController<List<int>> _audioDataController = StreamController<List<int>>.broadcast();
  final StreamController<List<int>> _responseDataController = StreamController<List<int>>.broadcast();
  final StreamController<List<int>> _fileDataController = StreamController<List<int>>.broadcast();
  final StreamController<List<int>> _logDataController = StreamController<List<int>>.broadcast();

  MPAudioPacketReassembler? _audioReassembler;

  /// `true` 表示已完成 `301`–`306` notify 订阅（与 [NoteBleTransport] 连接后一次性订阅语义一致）。
  bool _noteBleNotifyBound = false;

  /// 避免并发多次 [_runNoteEnsureSetup]；与 `NoteBleTransport` 单路订阅语义一致。
  Future<void>? _noteEnsuring;

  final List<StreamSubscription<dynamic>> _notePipelineSubscriptions = <StreamSubscription<dynamic>>[];

  /// 与 [NoteBleTransport] `_fileChunkBuffer` / `_isRawFileTransfer` 一致。
  List<int> _fileChunkBuffer = <int>[];
  bool _isRawFileTransfer = false;
  int _filePacketCount = 0;

  List<BluetoothService> _services = [];
  DeviceTransportState _state = DeviceTransportState.disconnected;
  StreamSubscription<BluetoothConnectionState>? _bleConnectionSubscription;

  BleTransport(this._bleDevice) : _connectionStateController = StreamController<DeviceTransportState>.broadcast() {
    _bleConnectionSubscription = _bleDevice.connectionState.listen((BluetoothConnectionState state) {
      // BluetoothConnectionState 与 DeviceTransportState 成员名一致，按 name 映射。
      _updateState(DeviceTransportState.values.byName(state.name));
    });
  }

  @override
  String get deviceId => _bleDevice.remoteId.str;

  @override
  Stream<DeviceTransportState> get connectionStateStream => _connectionStateController.stream;

  /// 与 [NoteBleTransport.audioStream] 一致：实时 **重组后** Opus 帧（非 301 原始 notify）。
  Stream<List<int>> get audioStream => _audioDataController.stream;

  /// 与 [NoteBleTransport.responseStream] 一致：`e2c1a303` 原始字节。
  Stream<List<int>> get responseStream => _responseDataController.stream;

  /// 与 [NoteBleTransport.fileStream] 一致：`e2c1a305` — txt 为 notify 原文，opus 为剥离 Seq 后的 480B 帧。
  Stream<List<int>> get fileStream => _fileDataController.stream;

  /// 与 [NoteBleTransport.logStream] 一致：`e2c1a306` 原始 notify。
  Stream<List<int>> get logStream => _logDataController.stream;

  void _updateState(DeviceTransportState newState) {
    if (_state != newState) {
      _state = newState;
      _connectionStateController.add(_state);
    }
  }

  @override
  Future<void> connect() async {
    if (_state == DeviceTransportState.connected) {
      return;
    }

    _updateState(DeviceTransportState.connecting);

    try {
      // Wait for Bluetooth adapter to be ready
      await BluetoothAdapter.adapterState.where((val) => val == BluetoothAdapterStateHelper.on).first;

      // Connect to device
      await _bleDevice.connect();
      await _bleDevice.connectionState.where((val) => val == BluetoothConnectionState.connected).first;

      // Note 设备侧常用 517；Android / iOS 均在连接后协商更大 ATT MTU，利于文件导出与长包。
      if (_bleDevice.mtuNow < 517) {
        try {
          await _bleDevice.requestMtu(517);
        } catch (e) {
          debugPrint('BleTransport.requestMtu: $e');
        }
      }

      // Discover services
      _services = await _bleDevice.discoverServices();

      // 与 `note_ble_transport` 中连接稳定等待一致，减轻首帧 GATT 命令与导入失败。
      await Future<void>.delayed(const Duration(milliseconds: 200));

      _updateState(DeviceTransportState.connected);
    } catch (e) {
      _updateState(DeviceTransportState.disconnected);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    if (_state == DeviceTransportState.disconnected) {
      return;
    }

    _updateState(DeviceTransportState.disconnecting);

    try {
      _gattListenerEpoch++;
      _characteristicNotifySetupFutures.clear();

      for (final StreamSubscription<dynamic> subscription in _characteristicSubscriptions.values) {
        await subscription.cancel();
      }
      _characteristicSubscriptions.clear();

      for (final StreamController<List<int>> controller in _streamControllers.values) {
        await controller.close();
      }
      _streamControllers.clear();

      await _tearDownNoteBleNotifyPipelines();

      await _bleDevice.disconnect();

      _updateState(DeviceTransportState.disconnected);
    } catch (e) {
      _updateState(DeviceTransportState.disconnected);
      rethrow;
    }
  }

  @override
  Future<bool> isConnected() async {
    return _bleDevice.isConnected;
  }

  @override
  Future<bool> ping() async {
    try {
      await _bleDevice.readRssi(timeout: 10);
      return true;
    } catch (e) {
      debugPrint('BLE Transport ping failed: $e');
      return false;
    }
  }

  @override
  Stream<List<int>> getCharacteristicStream(String serviceUuid, String characteristicUuid) {
    final String cu = characteristicUuid.toLowerCase();
    if (cu == MPNoteBleUUIDs.audioData.toString().toLowerCase()) {
      unawaited(_ensureNoteBleNotifyPipelines());
      return _audioDataController.stream;
    }
    if (cu == MPNoteBleUUIDs.response.toString().toLowerCase()) {
      unawaited(_ensureNoteBleNotifyPipelines());
      return _responseDataController.stream;
    }
    if (cu == MPNoteBleUUIDs.recordFile.toString().toLowerCase()) {
      unawaited(_ensureNoteBleNotifyPipelines());
      return _fileDataController.stream;
    }
    if (cu == MPNoteBleUUIDs.logFile.toString().toLowerCase()) {
      unawaited(_ensureNoteBleNotifyPipelines());
      return _logDataController.stream;
    }
    return const Stream<List<int>>.empty();
  }

  /// 先完成 `setNotifyValue(true)` 与 `lastValueStream` 订阅，再返回与 [getCharacteristicStream] 相同的广播流。
  ///
  /// 与 `lib/blu/ble/note_ble_transport.dart` 中 `_subscribeCharacteristics` 及
  /// `note-debug-realtime-audio-reception.md` 描述一致：避免 notify 尚未建立时即 `listen` 造成首包丢失。
  Future<Stream<List<int>>> getCharacteristicStreamWhenReady(
    String serviceUuid,
    String characteristicUuid,
  ) async {
    final String cu = characteristicUuid.toLowerCase();
    if (cu == MPNoteBleUUIDs.audioData.toString().toLowerCase() ||
        cu == MPNoteBleUUIDs.response.toString().toLowerCase() ||
        cu == MPNoteBleUUIDs.recordFile.toString().toLowerCase() ||
        cu == MPNoteBleUUIDs.logFile.toString().toLowerCase()) {
      await _ensureNoteBleNotifyPipelines();
      return getCharacteristicStream(serviceUuid, characteristicUuid);
    }
    return const Stream<List<int>>.empty();
  }

  /// 重置实时音频重组器（新一段录音开始时由上层调用，与 `AudioPacketReassembler.reset` 语义一致）。
  void resetRealtimeAudioReassembly({String? fileName}) {
    _audioReassembler?.reset(fileName: fileName);
  }

  /// 与 [NoteBleTransport.resetFileReassembler] 一致：按扩展名切换 `305` txt 透传 / opus `[Seq][480B]` 分帧。
  void resetFileReassembler({String? fileName}) {
    _filePacketCount = 0;
    _fileChunkBuffer.clear();
    _isRawFileTransfer = fileName != null && fileName.toLowerCase().endsWith('.txt');
    debugPrint(
      'BleTransport 文件传输模式: ${_isRawFileTransfer ? "纯字节流 (txt)" : "[Seq][480B] 分帧 (opus)"} file=$fileName',
    );
  }

  Future<void> _ensureNoteBleNotifyPipelines() async {
    if (_noteBleNotifyBound) {
      return;
    }
    final Future<void> run = _noteEnsuring ??= _runNoteEnsureSetup();
    await run;
  }

  Future<void> _runNoteEnsureSetup() async {
    try {
      for (int attempt = 0; attempt < 2 && !_noteBleNotifyBound; attempt++) {
        await _setupNoteBleNotifyPipelines();
      }
    } finally {
      _noteEnsuring = null;
    }
  }

  /// 301 等特征的 **原始 notify**（不经 [MPAudioPacketReassembler]）。
  ///
  /// 与 [getCharacteristicStream] 分流：同 UUID 下 [MPNoteBleUUIDs.audioData] 在后者中返回重组帧，
  /// 本方法供 [MPBleLiveRecordingSession] 等需 Seq/分包自行解析的路径使用。
  Stream<List<int>> getRawCharacteristicNotifyStream(String serviceUuid, String characteristicUuid) {
    final String key = _rawNotifyStreamKey(serviceUuid, characteristicUuid);
    if (!_streamControllers.containsKey(key)) {
      _streamControllers[key] = StreamController<List<int>>.broadcast();
      _characteristicNotifySetupFutures[key] = _setupCharacteristicListener(serviceUuid, characteristicUuid, key);
    }
    return _streamControllers[key]!.stream;
  }

  /// 先完成 `setNotifyValue(true)` 再返回 [getRawCharacteristicNotifyStream] 的流。
  Future<Stream<List<int>>> getRawCharacteristicNotifyStreamWhenReady(
    String serviceUuid,
    String characteristicUuid,
  ) async {
    final String key = _rawNotifyStreamKey(serviceUuid, characteristicUuid);
    if (!_streamControllers.containsKey(key)) {
      _streamControllers[key] = StreamController<List<int>>.broadcast();
      _characteristicNotifySetupFutures[key] = _setupCharacteristicListener(serviceUuid, characteristicUuid, key);
    }
    final Future<void>? pending = _characteristicNotifySetupFutures[key];
    if (pending != null) {
      await pending;
    }
    return _streamControllers[key]!.stream;
  }

  static String _rawNotifyStreamKey(String serviceUuid, String characteristicUuid) =>
      'raw:${serviceUuid.toLowerCase()}:${characteristicUuid.toLowerCase()}';

  Future<void> _setupNoteBleNotifyPipelines() async {
    if (_noteBleNotifyBound) {
      return;
    }
    final int setupEpoch = _gattListenerEpoch;
    StreamSubscription<List<int>>? audioSub;
    StreamSubscription<List<int>>? responseSub;
    StreamSubscription<List<int>>? fileSub;
    StreamSubscription<List<int>>? logSub;
    try {
      _audioReassembler ??= MPAudioPacketReassembler(
        tag: 'BleTransport',
        onFrameComplete: (_, List<int> frame) {
          if (!_audioDataController.isClosed) {
            _audioDataController.add(frame);
          }
        },
        onSeqGap: (int expectedSeq, int receivedSeq) {
          debugPrint(
            'BleTransport audio seq gap: expected=$expectedSeq received=$receivedSeq deviceId=$deviceId',
          );
        },
      );

      final BluetoothCharacteristic? audioChar =
          await _getCharacteristic(MPNoteBleUUIDs.service.toString(), MPNoteBleUUIDs.audioData.toString());
      final BluetoothCharacteristic? responseChar =
          await _getCharacteristic(MPNoteBleUUIDs.service.toString(), MPNoteBleUUIDs.response.toString());
      if (setupEpoch != _gattListenerEpoch) {
        return;
      }
      if (audioChar == null || responseChar == null) {
        debugPrint('BleTransport: Note audio/response characteristic missing');
        return;
      }

      await audioChar.setNotifyValue(true);
      if (setupEpoch != _gattListenerEpoch) {
        try {
          await audioChar.setNotifyValue(false);
        } catch (_) {}
        return;
      }
      await responseChar.setNotifyValue(true);
      if (setupEpoch != _gattListenerEpoch) {
        try {
          await audioChar.setNotifyValue(false);
          await responseChar.setNotifyValue(false);
        } catch (_) {}
        return;
      }

      audioSub = audioChar.lastValueStream.listen(
        _audioReassembler!.process,
        onError: (Object e, StackTrace st) =>
            debugPrint('BleTransport 301 audio notify: $e\n$st'),
        onDone: () => debugPrint('BleTransport 301 audio notify: onDone'),
        cancelOnError: false,
      );
      responseSub = responseChar.lastValueStream.listen(
        (List<int> value) {
          if (!_responseDataController.isClosed) {
            _responseDataController.add(value);
          }
        },
        onError: (Object e, StackTrace st) =>
            debugPrint('BleTransport 303 response notify: $e\n$st'),
        onDone: () => debugPrint('BleTransport 303 response notify: onDone'),
        cancelOnError: false,
      );

      if (setupEpoch != _gattListenerEpoch) {
        await audioSub.cancel();
        await responseSub.cancel();
        return;
      }

      final BluetoothCharacteristic? fileChar =
          await _getCharacteristic(MPNoteBleUUIDs.service.toString(), MPNoteBleUUIDs.recordFile.toString());
      final BluetoothCharacteristic? logChar =
          await _getCharacteristic(MPNoteBleUUIDs.service.toString(), MPNoteBleUUIDs.logFile.toString());
      if (setupEpoch != _gattListenerEpoch) {
        await audioSub.cancel();
        await responseSub.cancel();
        return;
      }

      if (fileChar != null) {
        await fileChar.setNotifyValue(true);
        if (setupEpoch != _gattListenerEpoch) {
          try {
            await fileChar.setNotifyValue(false);
          } catch (_) {}
          await audioSub.cancel();
          await responseSub.cancel();
          return;
        }
        fileSub = fileChar.lastValueStream.listen(
          (List<int> data) {
            if (_filePacketCount < 3 && kDebugMode) {
              final String headHex =
                  data.take(8).map((int b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
              debugPrint(
                'BLE FILE notify#$_filePacketCount: len=${data.length}, head=[$headHex'
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
          onError: (Object e, StackTrace st) => debugPrint('BleTransport 305 file notify: $e\n$st'),
          onDone: () => debugPrint('BleTransport 305 file notify: onDone'),
          cancelOnError: false,
        );
      }

      if (logChar != null) {
        await logChar.setNotifyValue(true);
        if (setupEpoch != _gattListenerEpoch) {
          try {
            await logChar.setNotifyValue(false);
          } catch (_) {}
          await audioSub.cancel();
          await responseSub.cancel();
          await fileSub?.cancel();
          return;
        }
        logSub = logChar.lastValueStream.listen(
          (List<int> data) {
            if (!_logDataController.isClosed) {
              _logDataController.add(data);
            }
          },
          onError: (Object e, StackTrace st) => debugPrint('BleTransport 306 log notify: $e\n$st'),
          onDone: () => debugPrint('BleTransport 306 log notify: onDone'),
          cancelOnError: false,
        );
      }

      if (setupEpoch != _gattListenerEpoch) {
        await audioSub.cancel();
        await responseSub.cancel();
        await fileSub?.cancel();
        await logSub?.cancel();
        return;
      }

      _notePipelineSubscriptions.add(audioSub);
      _notePipelineSubscriptions.add(responseSub);
      _bleDevice.cancelWhenDisconnected(audioSub);
      _bleDevice.cancelWhenDisconnected(responseSub);
      if (fileSub != null) {
        _notePipelineSubscriptions.add(fileSub);
        _bleDevice.cancelWhenDisconnected(fileSub);
      }
      if (logSub != null) {
        _notePipelineSubscriptions.add(logSub);
        _bleDevice.cancelWhenDisconnected(logSub);
      }
      _noteBleNotifyBound = true;
    } catch (e) {
      debugPrint('BleTransport: _setupNoteBleNotifyPipelines failed: $e');
      await audioSub?.cancel();
      await responseSub?.cancel();
      await fileSub?.cancel();
      await logSub?.cancel();
    }
  }

  Future<void> _tearDownNoteBleNotifyPipelines() async {
    for (final StreamSubscription<dynamic> s in _notePipelineSubscriptions) {
      await s.cancel();
    }
    _notePipelineSubscriptions.clear();
    _noteBleNotifyBound = false;
    _fileChunkBuffer.clear();
    _filePacketCount = 0;
    _audioReassembler?.dispose();
    _audioReassembler = null;
  }

  Future<void> _setupCharacteristicListener(String serviceUuid, String characteristicUuid, String key) async {
    final int setupEpoch = _gattListenerEpoch;
    try {
      final BluetoothCharacteristic? characteristic = await _getCharacteristic(serviceUuid, characteristicUuid);
      if (setupEpoch != _gattListenerEpoch) {
        return;
      }
      if (characteristic == null) {
        debugPrint('BLE Transport: Characteristic not found: $serviceUuid:$characteristicUuid');
        return;
      }

      await characteristic.setNotifyValue(true);
      if (setupEpoch != _gattListenerEpoch) {
        try {
          await characteristic.setNotifyValue(false);
        } catch (_) {
          // ignore
        }
        return;
      }

      final StreamSubscription<List<int>> subscription = characteristic.lastValueStream.listen(
        (List<int> value) {
          final StreamController<List<int>>? c = _streamControllers[key];
          if (c != null && !c.isClosed) {
            c.add(value);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('BLE Transport characteristic stream error ($key): $error\n$stackTrace');
        },
        onDone: () {
          debugPrint('BLE Transport characteristic notify stream done: $key');
        },
        cancelOnError: false,
      );

      if (setupEpoch != _gattListenerEpoch) {
        await subscription.cancel();
        return;
      }

      _characteristicSubscriptions[key] = subscription;
      _bleDevice.cancelWhenDisconnected(subscription);
    } catch (e) {
      debugPrint('BLE Transport: Failed to setup characteristic listener: $e');
    }
  }

  @override
  Future<List<int>> readCharacteristic(String serviceUuid, String characteristicUuid) async {
    // 与 [connect] 同一 FBP 会话读 GATT；勿与 reactive_ble 混读（Android 易 service_discovery_failure）。
    debugPrint('------>>>memopin readCharacteristic: $serviceUuid $characteristicUuid deviceId=$deviceId');
    Future<List<int>?> tryRead() async {
      final BluetoothCharacteristic? characteristic =
          await _getCharacteristic(serviceUuid, characteristicUuid);
      if (characteristic == null) {
        return null;
      }
      try {
        return await characteristic.read();
      } catch (e) {
        debugPrint('------>>>memopin readCharacteristic: FBP read failed $e');
        return null;
      }
    }

    List<int>? data = await tryRead();
    if (data != null) {
      return data;
    }
    if (!_bleDevice.isConnected) {
      debugPrint('------>>>memopin readCharacteristic: not connected → []');
      return <int>[];
    }
    try {
      debugPrint('------>>>memopin readCharacteristic: rediscoverServices then retry');
      _services = await _bleDevice.discoverServices();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      data = await tryRead();
    } catch (e) {
      debugPrint('------>>>memopin readCharacteristic: rediscover failed $e');
    }
    return data ?? <int>[];
  }

  @override
  Future<void> writeCharacteristic(String serviceUuid, String characteristicUuid, List<int> data) async {
    await writeCharacteristicImpl(
      serviceUuid,
      characteristicUuid,
      data,
      withoutResponse: false,
    );
  }

  /// Note 协议命令特征需 **Write Without Response**（与 `ble/note_ble_transport.dart` 一致）。
  Future<void> writeCharacteristicWithoutResponse(
    String serviceUuid,
    String characteristicUuid,
    List<int> data,
  ) {
    return writeCharacteristicImpl(
      serviceUuid,
      characteristicUuid,
      data,
      withoutResponse: true,
    );
  }

  /// 内部写入实现；[withoutResponse] 为 `true` 时使用无响应写。
  Future<void> writeCharacteristicImpl(
    String serviceUuid,
    String characteristicUuid,
    List<int> data, {
    required bool withoutResponse,
  }) async {
    final characteristic = await _getCharacteristic(serviceUuid, characteristicUuid);
    if (characteristic == null) {
      throw Exception('Characteristic not found: $serviceUuid:$characteristicUuid');
    }

    try {
      await characteristic.write(data, withoutResponse: withoutResponse);
    } catch (e) {
      debugPrint('BLE Transport: Failed to write characteristic: $e');
      rethrow;
    }
  }

  /// 标准 BLE Battery Service（UUID `0x180F`）的电量百分比（`0x2A19` 首字节 0–100）。
  ///
  /// 设备未实现该服务或读失败时返回 `null`。
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
      debugPrint('BleTransport.readStandardBatteryPercent: $e');
      return null;
    }
  }

  Future<BluetoothCharacteristic?> _getCharacteristic(String serviceUuid, String characteristicUuid) async {
    final service = _services.firstWhereOrNull(
      (service) => service.uuid.str128.toLowerCase() == serviceUuid.toLowerCase(),
    );

    if (service == null) {
      return null;
    }

    return service.characteristics.firstWhereOrNull(
      (characteristic) => characteristic.uuid.str128.toLowerCase() == characteristicUuid.toLowerCase(),
    );
  }

  @override
  Future<void> dispose() async {
    await _bleConnectionSubscription?.cancel();

    _gattListenerEpoch++;
    _characteristicNotifySetupFutures.clear();

    await _tearDownNoteAudioResponsePipelines();

    for (final StreamSubscription<dynamic> subscription in _characteristicSubscriptions.values) {
      await subscription.cancel();
    }
    _characteristicSubscriptions.clear();

    for (final StreamController<List<int>> controller in _streamControllers.values) {
      await controller.close();
    }
    _streamControllers.clear();

    if (!_audioDataController.isClosed) {
      await _audioDataController.close();
    }
    if (!_responseDataController.isClosed) {
      await _responseDataController.close();
    }

    await _connectionStateController.close();
  }
}
