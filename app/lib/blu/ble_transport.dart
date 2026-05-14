import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:memo_pin/utils/bluetooth/bluetooth_adapter.dart';

import 'device_transport.dart';

class BleTransport extends DeviceTransport {
  final BluetoothDevice _bleDevice;
  final StreamController<DeviceTransportState> _connectionStateController;
  final Map<String, StreamController<List<int>>> _streamControllers = {};
  final Map<String, StreamSubscription<dynamic>> _characteristicSubscriptions = {};
  final Map<String, Future<void>> _characteristicNotifySetupFutures = {};

  /// 在 [disconnect] / [dispose] 时递增，用于丢弃尚未完成的 [_setupCharacteristicListener] 结果。
  int _gattListenerEpoch = 0;

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
    final String key = '$serviceUuid:$characteristicUuid';

    if (!_streamControllers.containsKey(key)) {
      _streamControllers[key] = StreamController<List<int>>.broadcast();
      _characteristicNotifySetupFutures[key] = _setupCharacteristicListener(serviceUuid, characteristicUuid, key);
    }

    return _streamControllers[key]!.stream;
  }

  /// 先完成 `setNotifyValue(true)` 与 `lastValueStream` 订阅，再返回与 [getCharacteristicStream] 相同的广播流。
  ///
  /// 与 `lib/blu/ble/note_ble_transport.dart` 中 `_subscribeCharacteristics` 及
  /// `note-debug-realtime-audio-reception.md` 描述一致：避免 notify 尚未建立时即 `listen` 造成首包丢失。
  Future<Stream<List<int>>> getCharacteristicStreamWhenReady(
    String serviceUuid,
    String characteristicUuid,
  ) async {
    final String key = '$serviceUuid:$characteristicUuid';
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

    for (final StreamSubscription<dynamic> subscription in _characteristicSubscriptions.values) {
      await subscription.cancel();
    }
    _characteristicSubscriptions.clear();

    for (final StreamController<List<int>> controller in _streamControllers.values) {
      await controller.close();
    }
    _streamControllers.clear();

    await _connectionStateController.close();
  }
}
