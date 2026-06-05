import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:memo_pin/blu/mp_ble_transport.dart';
import 'package:memo_pin/blu/mp_device_transport.dart';
import 'package:memo_pin/blu/mp_ble_preferences.dart';
import 'package:memo_pin/blu/mp_ble_connection_helper.dart';
import 'package:memo_pin/common/mp_home_notification.dart';
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

  /// 远端 BLE 设备 ID 字符串。
  final String id;
  final String name;

  /// 电量 0–100；未读取时为 0
  final int batteryPercent;
  final int signalPercent;
  final bool isConnected;

  MPConnectDeviceItem copyWith({String? id, String? name, int? batteryPercent, int? signalPercent, bool? isConnected}) {
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
      connectingDeviceId: clearConnectingDeviceId ? null : (connectingDeviceId ?? this.connectingDeviceId),
    );
  }
}

/// 连接页 Cubit：BLE 扫描、[BleTransport] 连接与断开
class MPConnectDeviceCubit extends Cubit<MPConnectDeviceState> {
  /// 创建 Cubit；初始不扫描，列表为空，由 [initData] / [startScan] 驱动
  MPConnectDeviceCubit() : super(const MPConnectDeviceState(isScanning: false));

  BleTransport? _transport;
  StreamSubscription<MPDeviceTransportState>? _transportConnectionSub;
  int _scanGeneration = 0;

  /// 单轮扫描阶段时长；两阶段（UUID 过滤 + 全量）合计最长约 `2 *` 该值。
  static const Duration _scanPhaseDuration = Duration(seconds: 5);

  /// 进入页面后：复用 [MPBleConnectionHelper.activeBleTransport]（不 take，避免子页/返回首页后状态丢失）。
  void initData() {
    _transport = MPBleConnectionHelper.activeBleTransport;
    unawaited(_restoreParkedConnectionThenScan());
  }

  /// 从 [parkBackgroundBleTransport] 恢复的 [BleTransport] 同步 UI，并与 [startScan] 衔接。
  Future<void> _restoreParkedConnectionThenScan() async {
    if (_transport != null) {
      try {
        final bool connected = await _transport!.isConnected();
        if (!connected) {
          final String remoteId = _transport!.deviceId;
          final bool reconnected = await MPBleConnectionHelper.tryReconnectBackgroundTransport(remoteId);
          if (!reconnected && !isClosed) {
            await MPBleConnectionHelper.parkBackgroundBleTransport(_transport);
            _transport = null;
            _emitAllDevicesDisconnected();
          }
        }
        if (_transport != null && await _transport!.isConnected()) {
          final MPConnectDeviceItem row = await _connectedDeviceItemForActiveTransport();
          if (!isClosed) {
            _attachTransportConnectionListener(_transport!);
            final int? batteryPct = await _readBatteryPercentForTransport(_transport!, row.id);
            if (!isClosed) {
              emit(
                state.copyWith(
                  devices: <MPConnectDeviceItem>[
                    row.copyWith(batteryPercent: batteryPct ?? 0),
                  ],
                ),
              );
            }
          }
        }
      } catch (_) {
        await MPBleConnectionHelper.parkBackgroundBleTransport(_transport);
        _transport = null;
        if (!isClosed) {
          _emitAllDevicesDisconnected();
        }
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
      await MPBlePreferences.instance.setLastConnectedBleDevice(remoteId: id, displayName: displayName);
    }
    return MPConnectDeviceItem(id: id, name: displayName, batteryPercent: 0, signalPercent: 0, isConnected: true);
  }

  /// 解析展示名：优先本地记录，其次广播名，最后退回占位文案。
  Future<String> _displayNameForBleRemoteId(String remoteId) async {
    final MPLastBleDeviceRecord? r = MPBlePreferences.instance.readLastConnectedBleDevice();
    if (r != null && r.remoteId == remoteId) {
      return r.displayName;
    }
    return MPBleConnectionHelper.resolveMemoPinDisplayName(remoteId);
  }

  /// 当前 [_transport] 若仍在线则返回其 remoteId，否则 `null`。
  Future<String?> _currentConnectedRemoteId() async {
    final BleTransport? t = _transport;
    if (t == null) {
      return null;
    }
    try {
      if (await t.isConnected()) {
        return t.deviceId;
      }
    } catch (_) {
      // ignore
    }
    return null;
  }

  /// 断开/被动掉线后：列表全部标为未连接，已连接行电量清零。
  void _emitAllDevicesDisconnected() {
    emit(
      state.copyWith(
        clearConnectingDeviceId: true,
        devices: state.devices
            .map(
              (MPConnectDeviceItem d) =>
                  d.copyWith(isConnected: false, batteryPercent: d.isConnected ? 0 : d.batteryPercent),
            )
            .toList(),
      ),
    );
  }

  /// 若状态里尚无「已连接」行但 [_transport] 仍在线，则补齐（扫描列表依赖实时 GATT 连接态）。
  Future<List<MPConnectDeviceItem>> _keepConnectedRowsForScan() async {
    final List<MPConnectDeviceItem> fromState = state.devices.where((MPConnectDeviceItem d) => d.isConnected).toList();
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
  List<MPConnectDeviceItem> _devicesToShowWhileScanning({required List<MPConnectDeviceItem> keepConnected}) {
    final List<MPConnectDeviceItem> out = List<MPConnectDeviceItem>.from(keepConnected);
    final MPLastBleDeviceRecord? r = MPBlePreferences.instance.readLastConnectedBleDevice();
    if (r == null) {
      return out;
    }
    if (out.any((MPConnectDeviceItem d) => d.id == r.remoteId)) {
      return out;
    }
    out.add(
      MPConnectDeviceItem(id: r.remoteId, name: r.displayName, batteryPercent: 0, signalPercent: 0, isConnected: false),
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
      MPConnectDeviceItem(id: r.remoteId, name: r.displayName, batteryPercent: 0, signalPercent: 0, isConnected: false),
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
    await _stopScanSafe();

    final bool supported = await MPBleConnectionHelper.isBleSupported;
    if (!supported) {
      MPToastUtils.showMessage('Bluetooth is not supported on this device.', duration: const Duration(seconds: 5));
      if (!isClosed) {
        emit(state.copyWith(isScanning: false));
      }
      return;
    }

    final bool permitted = await MPBleConnectionHelper.ensureBlePermissions();
    if (!permitted) {
      if (!isClosed) {
        emit(state.copyWith(isScanning: false));
      }
      return;
    }

    bool adapterOn = await MPBleConnectionHelper.waitForAdapterOn(timeout: const Duration(seconds: 8));
    if (!adapterOn) {
      try {
        await MPBleConnectionHelper.tryTurnBluetoothOn();
      } catch (_) {
        // 用户拒绝或平台不支持弹窗
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      adapterOn = await MPBleConnectionHelper.waitForAdapterOn(timeout: const Duration(seconds: 5));
    }
    if (!adapterOn) {
      final BleStatus s = MPBleConnectionHelper.bleStatus;
      if (s == BleStatus.unauthorized) {
        MPToastUtils.showMessage(
          'Bluetooth is off or access was denied. Turn on Bluetooth or allow access in Settings.',
          duration: const Duration(seconds: 5),
        );
      } else if (s == BleStatus.locationServicesDisabled) {
        MPToastUtils.showMessage(
          'Location services are disabled. Turn on Location to scan for Bluetooth devices.',
          duration: const Duration(seconds: 5),
        );
      } else {
        MPToastUtils.showMessage('Please turn on Bluetooth.', duration: const Duration(seconds: 5));
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
    emit(state.copyWith(isScanning: true, devices: _devicesToShowWhileScanning(keepConnected: keepConnected)));

    try {
      final List<MPBleScanEntry> entries = await MPBleConnectionHelper.scanMemoPinLikeEntriesPhased(
        perPhase: _scanPhaseDuration,
        requirePermissionsAndAdapter: false,
      );
      if (generation != _scanGeneration || isClosed) {
        return;
      }
      final String? activeConnectedId = await _currentConnectedRemoteId();
      final List<MPConnectDeviceItem> next = entries.map((MPBleScanEntry e) {
        return MPConnectDeviceItem(
          id: e.remoteId,
          name: e.displayName,
          batteryPercent: 0,
          signalPercent: e.signalPercent,
          isConnected: activeConnectedId != null && activeConnectedId == e.remoteId,
        );
      }).toList();

      if (activeConnectedId != null && !next.any((MPConnectDeviceItem i) => i.id == activeConnectedId)) {
        final MPConnectDeviceItem? prev = state.devices.firstWhereOrNull(
          (MPConnectDeviceItem d) => d.id == activeConnectedId && d.isConnected,
        );
        if (prev != null) {
          next.insert(0, prev);
        } else {
          try {
            final MPConnectDeviceItem row = await _connectedDeviceItemForActiveTransport();
            final int? batteryPct = await _readBatteryPercentForTransport(_transport!, activeConnectedId);
            next.insert(0, row.copyWith(batteryPercent: batteryPct ?? 0));
          } catch (_) {
            // ignore
          }
        }
      }

      _appendPersistedLastDeviceIfMissing(next);

      if (!isClosed) {
        emit(state.copyWith(isScanning: false, devices: next));
        if (activeConnectedId != null) {
          unawaited(_refreshConnectedDeviceBattery(activeConnectedId));
        }
      }
    } catch (e) {
      if (generation == _scanGeneration && !isClosed) {
        MPToastUtils.showMessage('Scan failed. Please try again.');
        emit(state.copyWith(isScanning: false, devices: _mergeLastIntoList(keepConnected)));
      }
    } finally {
      // 必须无条件停止扫描：helper 内已 stopScan；此处兜底防止页面关闭时代次交错遗留扫描。
      await _stopScanSafe();
    }
  }

  /// 连接或断开指定设备
  Future<void> toggleConnection(String id) async {
    // 列表中可能出现相同 remoteId 的多行（例如扫描占位与已连接行并存），
    // 须用「是否存在已连接行」判断断开，否则 firstWhereOrNull 会先命中未连接行并误判为去连接。
    final bool anyConnectedWithId = state.devices.any((MPConnectDeviceItem d) => d.id == id && d.isConnected);
    final MPConnectDeviceItem? target = state.devices.firstWhereOrNull((MPConnectDeviceItem d) => d.id == id);
    if (target == null) {
      return;
    }

    if (anyConnectedWithId) {
      _scanGeneration++;
      await _stopScanSafe();
      await _disconnectActive();
      await MPBlePreferences.instance.clearLastConnectedBleDevice();
      if (!isClosed) {
        _emitAllDevicesDisconnected();
      }
      return;
    }

    if (state.connectingDeviceId != null) {
      return;
    }

    emit(state.copyWith(connectingDeviceId: id));
    _scanGeneration++;
    await _stopScanSafe();
    await _disconnectActive();

    emit(
      state.copyWith(devices: state.devices.map((MPConnectDeviceItem d) => d.copyWith(isConnected: false)).toList()),
    );

    /// 扫描结果中 RSSI 已映射为 signalPercent；仅持久化占位行 signalPercent 为 0。
    final bool recentlyScanned = target.signalPercent > 0;

    try {
      _transport = MPBleConnectionHelper.createBleTransport(id, displayName: target.name);
      await _transport!.connect(skipAdvertisementVerify: recentlyScanned);
      await MPBleConnectionHelper.parkBackgroundBleTransport(_transport);
      _attachTransportConnectionListener(_transport!);
      // 须在 notifyBleConnectedSuccess（首页 GATT 拉文件列表）之前读电量，避免 303 响应被抢占导致误显示 100%。
      final int? batteryPct = await _readBatteryPercentForTransport(_transport!, id);
      await MPBlePreferences.instance.setLastConnectedBleDevice(remoteId: id, displayName: target.name);
      if (!isClosed) {
        emit(
          state.copyWith(
            clearConnectingDeviceId: true,
            devices: state.devices
                .map(
                  (MPConnectDeviceItem d) => d.id == id
                      ? d.copyWith(isConnected: true, batteryPercent: batteryPct ?? 0)
                      : d.copyWith(isConnected: false, batteryPercent: 0),
                )
                .toList(),
          ),
        );
      }
      MPHomeNotification.notifyBleConnectedSuccess();
    } catch (e) {
      MPToastUtils.showMessage('Connection failed. Move closer to the device and try again.');
      await _disconnectActive();
    } finally {
      if (!isClosed && state.connectingDeviceId != null) {
        emit(state.copyWith(clearConnectingDeviceId: true));
      }
    }
  }

  /// GATT 就绪后读取电量；连接稳定前略作等待，并对疑似误读的 100% 做二次确认。
  Future<int?> _readBatteryPercentForTransport(BleTransport transport, String remoteId) async {
    if (transport.deviceId != remoteId) {
      return null;
    }
    try {
      if (!await transport.isConnected()) {
        return null;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!await transport.isConnected()) {
        return null;
      }
      final int? first = await MPBleConnectionHelper.readMemoPinBatteryPercent(transport);
      if (first != null && first != 100) {
        return first;
      }
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!await transport.isConnected()) {
        return first;
      }
      final int? second = await MPBleConnectionHelper.readMemoPinBatteryPercent(transport);
      if (first == 100 && second != null && second != 100) {
        return second;
      }
      return first ?? second;
    } catch (_) {
      return null;
    }
  }

  /// 从 [_transport] 读取 MemoPin 自定义电量或标准 BAS，并写回 [MPConnectDeviceItem.batteryPercent]。
  Future<void> _refreshConnectedDeviceBattery(String remoteId) async {
    if (isClosed) {
      return;
    }
    final BleTransport? t = _transport;
    if (t == null || t.deviceId != remoteId) {
      return;
    }
    final int? pct = await _readBatteryPercentForTransport(t, remoteId);
    if (pct == null || isClosed || _transport != t) {
      return;
    }
    emit(
      state.copyWith(
        devices: state.devices
            .map((MPConnectDeviceItem d) => d.id == remoteId ? d.copyWith(batteryPercent: pct) : d)
            .toList(),
      ),
    );
  }

  /// 订阅当前 [_transport] 的链路状态；外围关机、断距等会进入 [MPDeviceTransportState.disconnected]，用于刷新卡片 UI。
  void _attachTransportConnectionListener(BleTransport transport) {
    _detachTransportConnectionListener();
    _transportConnectionSub = transport.connectionStateStream.listen((MPDeviceTransportState s) {
      if (isClosed || s != MPDeviceTransportState.disconnected) {
        return;
      }
      unawaited(_onPassiveBleDisconnected());
    });
  }

  void _detachTransportConnectionListener() {
    _transportConnectionSub?.cancel();
    _transportConnectionSub = null;
  }

  /// 设备侧掉线（关机、超出范围等）：仅刷新 UI，**不**主动 disconnect；忽略 GATT 误报的瞬时 disconnected。
  Future<void> _onPassiveBleDisconnected() async {
    if (isClosed) {
      return;
    }
    final BleTransport? t = _transport ?? MPBleConnectionHelper.activeBleTransport;
    if (t != null) {
      try {
        if (await t.isConnected()) {
          if (_transport == null) {
            _transport = MPBleConnectionHelper.activeBleTransport;
            _attachTransportConnectionListener(_transport!);
          }
          return;
        }
      } catch (_) {
        // ignore
      }
    }

    _detachTransportConnectionListener();
    _transport = null;
    MPHomeNotification.notifyBleDisconnected();

    if (isClosed) {
      return;
    }
    _scanGeneration++;
    _emitAllDevicesDisconnected();
  }

  /// 用户主动断开（连接页「Disconnect」、切换设备前清理）。
  Future<void> _disconnectActive() async {
    _detachTransportConnectionListener();
    _transport = null;
    await MPBleConnectionHelper.disconnectBackgroundBleTransportUserInitiated();
  }

  /// 停止 BLE 扫描；始终调用插件 [stopScan]（内部已对未在扫的情况做处理），避免仅依赖 [isScanningNow] 漏停。
  Future<void> _stopScanSafe() async {
    try {
      await MPBleConnectionHelper.stopScan();
    } catch (_) {
      // ignore
    }
  }

  @override
  Future<void> close() async {
    _scanGeneration++;
    await _stopScanSafe();
    _detachTransportConnectionListener();
    // 退出页面：不断开 BLE；会话仍由 [MPBleConnectionHelper.activeBleTransport] 持有。
    _transport = null;
    await super.close();
  }
}
