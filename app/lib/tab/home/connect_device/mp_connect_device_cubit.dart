import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:memo_pin/blu/ble_transport.dart';
import 'package:memo_pin/blu/mp_ble_preferences.dart';
import 'package:memo_pin/blu/mp_bluetooth_connection_helper.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';

/// 连接页设备模型
class MPConnectDeviceItem {
  /// 创建列表项
  const MPConnectDeviceItem({
    required this.id,
    required this.name,
    required this.batteryPercent,
    required this.signalPercent,
    this.isConnected = false,
  });

  /// 远端设备 ID（[BluetoothDevice.remoteId] 字符串）
  final String id;
  final String name;
  /// 电量 0–100；未读取时为 0
  final int batteryPercent;
  final int signalPercent;
  final bool isConnected;

  MPConnectDeviceItem copyWith({
    String? id,
    String? name,
    int? batteryPercent,
    int? signalPercent,
    bool? isConnected,
  }) {
    return MPConnectDeviceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      signalPercent: signalPercent ?? this.signalPercent,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

/// 连接页状态
class MPConnectDeviceState {
  /// 创建状态
  const MPConnectDeviceState({
    required this.isScanning,
    this.devices = const <MPConnectDeviceItem>[],
    this.connectingDeviceId,
  });

  final bool isScanning;
  final List<MPConnectDeviceItem> devices;

  /// 正在 BLE 连接中的设备 [MPConnectDeviceItem.id]；未在连接时为 `null`。
  final String? connectingDeviceId;

  MPConnectDeviceItem? get connectedDevice {
    for (final MPConnectDeviceItem item in devices) {
      if (item.isConnected) {
        return item;
      }
    }
    return null;
  }

  List<MPConnectDeviceItem> get otherDevices {
    return devices.where((MPConnectDeviceItem item) => !item.isConnected).toList();
  }

  MPConnectDeviceState copyWith({
    bool? isScanning,
    List<MPConnectDeviceItem>? devices,
    String? connectingDeviceId,
    bool clearConnectingDeviceId = false,
  }) {
    return MPConnectDeviceState(
      isScanning: isScanning ?? this.isScanning,
      devices: devices ?? this.devices,
      connectingDeviceId: clearConnectingDeviceId
          ? null
          : (connectingDeviceId ?? this.connectingDeviceId),
    );
  }
}

/// 连接页 Cubit：BLE 扫描、[BleTransport] 连接与断开
class MPConnectDeviceCubit extends Cubit<MPConnectDeviceState> {
  /// 创建 Cubit；初始不扫描，列表为空，由 [initData] / [startScan] 驱动
  MPConnectDeviceCubit() : super(const MPConnectDeviceState(isScanning: false));

  static const Duration _scanDuration = Duration(seconds: 10);

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BleTransport? _transport;
  int _scanGeneration = 0;

  /// 进入页面后：若有上次退出时停放的 BLE 会话则先恢复到列表，再首轮扫描。
  void initData() {
    if (_transport == null) {
      final BleTransport? adopted = MPBluetoothConnectionHelper.takeBackgroundBleTransport();
      if (adopted != null) {
        _transport = adopted;
      }
    }
    unawaited(_restoreParkedConnectionThenScan());
  }

  /// 从 [parkBackgroundBleTransport] 恢复的 [BleTransport] 同步 UI，并与 [startScan] 衔接。
  Future<void> _restoreParkedConnectionThenScan() async {
    if (_transport != null) {
      try {
        final bool connected = await _transport!.isConnected();
        if (!connected) {
          await _disconnectActive();
        } else {
          final MPConnectDeviceItem row = await _connectedDeviceItemForActiveTransport();
          if (!isClosed) {
            emit(
              state.copyWith(
                devices: <MPConnectDeviceItem>[row],
              ),
            );
            unawaited(_refreshConnectedDeviceBattery(row.id));
          }
        }
      } catch (_) {
        await _disconnectActive();
      }
    }
    if (!isClosed) {
      await startScan();
    }
  }

  /// 根据当前 [_transport] 构造「已连接」列表项，并与本地记录对齐（必要时写回 prefs）。
  ///
  /// 已连接设备往往不出现在扫描结果里，必须依赖 GATT 会话展示。
  Future<MPConnectDeviceItem> _connectedDeviceItemForActiveTransport() async {
    final String id = _transport!.deviceId;
    MPLastBleDeviceRecord? r = MPBlePreferences.instance.readLastConnectedBleDevice();
    String displayName;
    if (r != null && r.remoteId == id) {
      displayName = r.displayName;
    } else {
      displayName = await _displayNameForBleRemoteId(id);
      await MPBlePreferences.instance.setLastConnectedBleDevice(
        remoteId: id,
        displayName: displayName,
      );
    }
    return MPConnectDeviceItem(
      id: id,
      name: displayName,
      batteryPercent: 0,
      signalPercent: 0,
      isConnected: true,
    );
  }

  /// 解析展示名：优先本地记录，其次广播名，最后退回占位文案。
  Future<String> _displayNameForBleRemoteId(String remoteId) async {
    final MPLastBleDeviceRecord? r = MPBlePreferences.instance.readLastConnectedBleDevice();
    if (r != null && r.remoteId == remoteId) {
      return r.displayName;
    }
    try {
      final String raw = BluetoothDevice.fromId(remoteId).platformName.trim();
      if (raw.isNotEmpty) {
        return raw;
      }
    } catch (_) {
      // ignore
    }
    return 'MemoPin ($remoteId)';
  }

  /// 若状态里尚无「已连接」行但 [_transport] 仍在线，则补齐（扫描列表依赖 [preservedConnectedId]）。
  Future<List<MPConnectDeviceItem>> _keepConnectedRowsForScan() async {
    final List<MPConnectDeviceItem> fromState =
        state.devices.where((MPConnectDeviceItem d) => d.isConnected).toList();
    if (fromState.isNotEmpty) {
      return fromState;
    }
    if (_transport == null) {
      return fromState;
    }
    try {
      if (!await _transport!.isConnected()) {
        return fromState;
      }
      return <MPConnectDeviceItem>[await _connectedDeviceItemForActiveTransport()];
    } catch (_) {
      return fromState;
    }
  }

  /// 扫描过程中仍展示：已连接设备 + 本地持久化的上次设备（若尚未出现在已连接列表中）。
  List<MPConnectDeviceItem> _devicesToShowWhileScanning({
    required List<MPConnectDeviceItem> keepConnected,
  }) {
    final List<MPConnectDeviceItem> out = List<MPConnectDeviceItem>.from(keepConnected);
    final MPLastBleDeviceRecord? r = MPBlePreferences.instance.readLastConnectedBleDevice();
    if (r == null) {
      return out;
    }
    if (out.any((MPConnectDeviceItem d) => d.id == r.remoteId)) {
      return out;
    }
    out.add(
      MPConnectDeviceItem(
        id: r.remoteId,
        name: r.displayName,
        batteryPercent: 0,
        signalPercent: 0,
        isConnected: false,
      ),
    );
    return out;
  }

  /// 若本地有上次设备记录且本次扫描结果中尚无该 id，则追加一行（便于离线或未广播时仍显示）。
  void _appendPersistedLastDeviceIfMissing(List<MPConnectDeviceItem> next) {
    final MPLastBleDeviceRecord? r = MPBlePreferences.instance.readLastConnectedBleDevice();
    if (r == null) {
      return;
    }
    if (next.any((MPConnectDeviceItem d) => d.id == r.remoteId)) {
      return;
    }
    next.add(
      MPConnectDeviceItem(
        id: r.remoteId,
        name: r.displayName,
        batteryPercent: 0,
        signalPercent: 0,
        isConnected: false,
      ),
    );
  }

  /// 在 [base] 上合并持久化的上次设备（用于扫描失败等降级展示）。
  List<MPConnectDeviceItem> _mergeLastIntoList(List<MPConnectDeviceItem> base) {
    final List<MPConnectDeviceItem> out = List<MPConnectDeviceItem>.from(base);
    _appendPersistedLastDeviceIfMissing(out);
    return out;
  }

  /// 申请权限并开始扫描；结束后展示 MemoPin 类设备
  Future<void> startScan() async {
    final int generation = ++_scanGeneration;
    _scanSubscription?.cancel();
    _scanSubscription = null;
    await _stopScanSafe();

    final bool supported = await MPBluetoothConnectionHelper.isBleSupported;
    if (!supported) {
      MPToastUtils.showMessage('当前设备不支持蓝牙');
      if (!isClosed) {
        emit(state.copyWith(isScanning: false));
      }
      return;
    }

    final bool permitted = await MPBluetoothConnectionHelper.ensureBlePermissions();
    if (!permitted) {
      MPToastUtils.showMessage('需要蓝牙权限以扫描并连接设备');
      if (!isClosed) {
        emit(state.copyWith(isScanning: false));
      }
      return;
    }

    bool adapterOn = await MPBluetoothConnectionHelper.waitForAdapterOn(
      timeout: const Duration(seconds: 8),
    );
    if (!adapterOn) {
      try {
        await MPBluetoothConnectionHelper.tryTurnBluetoothOn();
      } catch (_) {
        // 用户拒绝或平台不支持弹窗
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      adapterOn = await MPBluetoothConnectionHelper.waitForAdapterOn(
        timeout: const Duration(seconds: 5),
      );
    }
    if (!adapterOn) {
      final BluetoothAdapterState s = FlutterBluePlus.adapterStateNow;
      if (s == BluetoothAdapterState.unauthorized) {
        MPToastUtils.showMessage('请在设置中允许本应用使用蓝牙');
      } else {
        MPToastUtils.showMessage('请先打开蓝牙');
      }
      if (!isClosed) {
        emit(state.copyWith(isScanning: false));
      }
      return;
    }

    if (isClosed) {
      return;
    }

    final List<MPConnectDeviceItem> keepConnected = await _keepConnectedRowsForScan();
    if (keepConnected.isNotEmpty &&
        state.devices.where((MPConnectDeviceItem d) => d.isConnected).isEmpty &&
        !isClosed) {
      emit(state.copyWith(devices: keepConnected));
    }
    final String? preservedConnectedId =
        keepConnected.isEmpty ? null : keepConnected.first.id;
    emit(
      state.copyWith(
        isScanning: true,
        devices: _devicesToShowWhileScanning(keepConnected: keepConnected),
      ),
    );

    final List<ScanResult> buffer = <ScanResult>[];
    _scanSubscription = MPBluetoothConnectionHelper.scanResultsStream.listen(
      (List<ScanResult> list) {
        buffer
          ..clear()
          ..addAll(list);
      },
    );

    try {
      await MPBluetoothConnectionHelper.startScan(timeout: _scanDuration);
      await Future<void>.delayed(_scanDuration);
      if (generation != _scanGeneration || isClosed) {
        return;
      }
      final List<MPBleScanEntry> entries =
          MPBluetoothConnectionHelper.entriesFromScanResults(List<ScanResult>.from(buffer));
      final List<MPConnectDeviceItem> next = entries.map((MPBleScanEntry e) {
        return MPConnectDeviceItem(
          id: e.remoteId,
          name: e.displayName,
          batteryPercent: 0,
          signalPercent: e.signalPercent,
          isConnected:
              preservedConnectedId != null && preservedConnectedId == e.remoteId,
        );
      }).toList();

      if (preservedConnectedId != null &&
          !next.any((MPConnectDeviceItem i) => i.id == preservedConnectedId)) {
        // 扫描期间可能已通过 GATT 更新电量，优先使用当前 state 中的已连接行。
        final MPConnectDeviceItem? prev = state.devices.firstWhereOrNull(
              (MPConnectDeviceItem d) =>
                  d.id == preservedConnectedId && d.isConnected,
            ) ??
            keepConnected.firstWhereOrNull(
              (MPConnectDeviceItem d) => d.id == preservedConnectedId,
            );
        if (prev != null) {
          next.insert(0, prev);
        }
      }

      _appendPersistedLastDeviceIfMissing(next);

      if (!isClosed) {
        emit(state.copyWith(isScanning: false, devices: next));
        if (preservedConnectedId != null) {
          unawaited(_refreshConnectedDeviceBattery(preservedConnectedId));
        }
      }
    } catch (e) {
      if (generation == _scanGeneration && !isClosed) {
        MPToastUtils.showMessage('扫描失败，请重试');
        emit(
          state.copyWith(
            isScanning: false,
            devices: _mergeLastIntoList(keepConnected),
          ),
        );
      }
    } finally {
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      // 必须无条件停止扫描：若仅按 generation 判断，在 close 递增代次后此处会跳过 stopScan，导致退出页面仍扫描。
      await _stopScanSafe();
    }
  }

  /// 连接或断开指定设备
  Future<void> toggleConnection(String id) async {
    final MPConnectDeviceItem? target =
        state.devices.firstWhereOrNull((MPConnectDeviceItem d) => d.id == id);
    if (target == null) {
      return;
    }

    if (target.isConnected) {
      await _disconnectActive();
      await MPBlePreferences.instance.clearLastConnectedBleDevice();
      emit(
        state.copyWith(
          devices: state.devices
              .map(
                (MPConnectDeviceItem d) => d.copyWith(isConnected: false),
              )
              .toList(),
        ),
      );
      return;
    }

    if (state.connectingDeviceId != null) {
      return;
    }

    emit(state.copyWith(connectingDeviceId: id));
    await _disconnectActive();

    emit(
      state.copyWith(
        devices: state.devices
            .map(
              (MPConnectDeviceItem d) => d.copyWith(isConnected: false),
            )
            .toList(),
      ),
    );

    try {
      final BluetoothDevice device = MPBluetoothConnectionHelper.bluetoothDeviceFromRemoteId(id);
      _transport = MPBluetoothConnectionHelper.createBleTransport(device);
      await _transport!.connect();
      await MPBlePreferences.instance.setLastConnectedBleDevice(
        remoteId: id,
        displayName: target.name,
      );
      emit(
        state.copyWith(
          clearConnectingDeviceId: true,
          devices: state.devices
              .map(
                (MPConnectDeviceItem d) => d.id == id
                    ? d.copyWith(isConnected: true)
                    : d.copyWith(isConnected: false),
              )
              .toList(),
        ),
      );
      unawaited(_refreshConnectedDeviceBattery(id));
    } catch (e) {
      MPToastUtils.showMessage('连接失败，请靠近设备后重试');
      await _disconnectActive();
    } finally {
      if (!isClosed && state.connectingDeviceId != null) {
        emit(state.copyWith(clearConnectingDeviceId: true));
      }
    }
  }

  /// 从 [_transport] 读取标准 BAS 电量并写回 [MPConnectDeviceItem.batteryPercent]。
  Future<void> _refreshConnectedDeviceBattery(String remoteId) async {
    if (isClosed) {
      return;
    }
    final BleTransport? t = _transport;
    if (t == null || t.deviceId != remoteId) {
      return;
    }
    try {
      if (!await t.isConnected()) {
        return;
      }
      final int? pct = await t.readStandardBatteryPercent();
      if (pct == null || isClosed) {
        return;
      }
      emit(
        state.copyWith(
          devices: state.devices
              .map(
                (MPConnectDeviceItem d) =>
                    d.id == remoteId ? d.copyWith(batteryPercent: pct) : d,
              )
              .toList(),
        ),
      );
    } catch (_) {
      // ignore
    }
  }

  Future<void> _disconnectActive() async {
    BleTransport? t = _transport;
    _transport = null;
    t ??= MPBluetoothConnectionHelper.takeBackgroundBleTransport();
    if (t != null) {
      try {
        await t.disconnect();
      } catch (_) {
        // ignore
      }
      try {
        await t.dispose();
      } catch (_) {
        // ignore
      }
    }
    await MPBluetoothConnectionHelper.disposeBackgroundBleTransportIfAny();
  }

  /// 停止 BLE 扫描；始终调用插件 [stopScan]（内部已对未在扫的情况做处理），避免仅依赖 [isScanningNow] 漏停。
  Future<void> _stopScanSafe() async {
    try {
      await MPBluetoothConnectionHelper.stopScan();
    } catch (_) {
      // ignore
    }
  }

  @override
  Future<void> close() async {
    _scanGeneration++;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await _stopScanSafe();
    // 仍在连接态时退出页面：不断开 BLE，仅将 BleTransport 存为背景会话。
    if (_transport != null) {
      try {
        if (await _transport!.isConnected()) {
          MPBluetoothConnectionHelper.parkBackgroundBleTransport(_transport);
          _transport = null;
        } else {
          await _disconnectActive();
        }
      } catch (_) {
        await _disconnectActive();
      }
    }
    await super.close();
  }
}
