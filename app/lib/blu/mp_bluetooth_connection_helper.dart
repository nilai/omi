import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:memo_pin/permission/omi_permission_service.dart';
import 'package:memo_pin/utils/bluetooth/bluetooth_adapter.dart';

import 'ble_transport.dart';
import 'mp_ble_preferences.dart';

/// 单次扫描聚合结果：用于 UI 列表，无需依赖完整 [BtDevice] 模型。
class MPBleScanEntry {
  /// 创建扫描条目。
  const MPBleScanEntry({
    required this.remoteId,
    required this.displayName,
    required this.rssi,
    required this.signalPercent,
  });

  /// [BluetoothDevice.remoteId] 字符串。
  final String remoteId;

  /// 展示用名称（与广播名一致，可为空时由调用方兜底）。
  final String displayName;

  /// 原始 RSSI（dBm）。
  final int rssi;

  /// 映射后的信号百分比 0–100。
  final int signalPercent;
}

/// 应用层 BLE 扫描、设备筛选与 [BleTransport] 创建入口。
///
/// 封装 [BluetoothAdapter] 与权限申请，供连接页等模块调用。
class MPBluetoothConnectionHelper {
  MPBluetoothConnectionHelper._();

  /// 连接页关闭后仍要保持的 GATT 会话（不断开 physical link）。
  ///
  /// 由 [MPConnectDeviceCubit] 在 `close` 时 [parkBackgroundBleTransport]，重新进入时
  /// [takeBackgroundBleTransport] 取回；用户主动断开时由 [disposeBackgroundBleTransportIfAny] 清理。
  static BleTransport? _backgroundBleTransport;

  /// 将当前已连接的 [transport] 存为背景会话（仅持有引用，不 disconnect）。
  static void parkBackgroundBleTransport(BleTransport? transport) {
    _backgroundBleTransport = transport;
  }

  /// 取出背景会话引用（取出后 helper 不再持有，一般由连接页 Cubit 接管）。
  static BleTransport? takeBackgroundBleTransport() {
    final BleTransport? t = _backgroundBleTransport;
    _backgroundBleTransport = null;
    return t;
  }

  /// 释放背景会话并断开 BLE（用户主动断开或连接新设备前清理）。
  static Future<void> disposeBackgroundBleTransportIfAny() async {
    final BleTransport? t = _backgroundBleTransport;
    _backgroundBleTransport = null;
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
  }

  /// 登出或需要彻底释放应用侧 BLE 时调用。
  ///
  /// 先 [disposeBackgroundBleTransportIfAny]，再对 [FlutterBluePlus.connectedDevices] 执行 [BluetoothDevice.disconnect]，
  /// 以覆盖仅通过系统栈连接、未托管在 [BleTransport] 中的情况。
  static Future<void> disconnectAppBleForLogout() async {
    await disposeBackgroundBleTransportIfAny();
    try {
      final List<BluetoothDevice> connected = FlutterBluePlus.connectedDevices;
      for (final BluetoothDevice d in connected) {
        try {
          await d.disconnect();
        } catch (_) {
          // ignore
        }
      }
    } catch (_) {
      // ignore
    }
  }

  /// 当前是否存在可用的 BLE 连接（优先检查应用托管会话，其次检查系统已连接设备）。
  static Future<bool> hasConnectedBleDevice() async {
    final BleTransport? bg = _backgroundBleTransport;
    if (bg != null) {
      try {
        if (await bg.isConnected()) {
          return true;
        }
      } catch (_) {
        // ignore
      }
    }
    try {
      return FlutterBluePlus.connectedDevices.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// 若有本地记录的 BLE 设备：申请权限、短扫 MemoPin 类广播，再对记录 [remoteId] 建立 [BleTransport] 并 [parkBackgroundBleTransport]。
  ///
  /// 返回最终连接状态：
  /// - `true`：已连接（复用已有连接或本次连接成功）
  /// - `false`：无记录、无权限、蓝牙未开、连接失败
  static Future<bool> tryConnectLastRecordedBleDevice() async {
    final MPLastBleDeviceRecord? r = MPBlePreferences.instance.readLastConnectedBleDevice();
    if (r == null) {
      return false;
    }

    final BleTransport? bg = _backgroundBleTransport;
    if (bg != null) {
      try {
        if (bg.deviceId == r.remoteId && await bg.isConnected()) {
          return true;
        }
      } catch (_) {
        // ignore
      }
      await disposeBackgroundBleTransportIfAny();
    }

    final bool supported = await isBleSupported;
    if (!supported) {
      return false;
    }

    final bool permitted = await ensureBlePermissions();
    if (!permitted) {
      return false;
    }

    // 短扫 MemoPin 类设备（discoverMemoPinLikeDevices 内会等待适配器上电），再按记录的 remoteId 直接建链。
    await discoverMemoPinLikeDevices(duration: const Duration(seconds: 100));

    final BluetoothDevice device = bluetoothDeviceFromRemoteId(r.remoteId);
    final BleTransport transport = createBleTransport(device);
    try {
      await transport.connect();
      parkBackgroundBleTransport(transport);
      return true;
    } catch (_) {
      try {
        await transport.dispose();
      } catch (_) {
        // ignore
      }
      return false;
    }
  }

  /// 是否支持 BLE（硬件/系统能力）。
  static Future<bool> get isBleSupported => BluetoothAdapter.isSupported;

  /// 适配器是否已上电（系统蓝牙已开）。
  ///
  /// 内部使用 [waitForAdapterOn]，避免 [FlutterBluePlus.adapterStateNow] 在启动初期为
  /// [BluetoothAdapterState.unknown] 时误判。
  static Future<bool> get isAdapterPoweredOn async {
    return waitForAdapterOn(timeout: const Duration(seconds: 5));
  }

  /// 等待系统蓝牙为 [BluetoothAdapterState.on]。
  ///
  /// 初次进入页面时 [FlutterBluePlus.adapterStateNow] 常仍为 [BluetoothAdapterState.unknown]
  ///（原生尚未回调），若仅用同步 getter 会误判为未开蓝牙，必须监听 [FlutterBluePlus.adapterState]。
  static Future<bool> waitForAdapterOn({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on) {
      return true;
    }
    try {
      await FlutterBluePlus.adapterState
          .where((BluetoothAdapterState s) => s == BluetoothAdapterState.on)
          .first
          .timeout(timeout);
      return true;
    } on TimeoutException {
      return FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on;
    }
  }

  /// 尝试打开系统蓝牙（可能抛错或需用户到系统设置处理）。
  static Future<void> tryTurnBluetoothOn() => BluetoothAdapter.turnOn();

  /// 申请 BLE 扫描/连接所需权限；全部授予返回 `true`。
  static Future<bool> ensureBlePermissions() {
    return OmiPermissionService.requestBlePermissionsForScanAndConnect();
  }

  /// 开始扫描；[timeout] 到达后由插件自动停止本轮扫描。
  static Future<void> startScan({
    Duration? timeout,
    List<Guid> withServices = const [],
    List<String> withNames = const [],
    List<String> withKeywords = const [],
    bool continuousUpdates = false,
  }) {
    return BluetoothAdapter.startScan(
      timeout: timeout,
      withServices: withServices,
      withNames: withNames,
      withKeywords: withKeywords,
      continuousUpdates: continuousUpdates,
    );
  }

  /// 停止扫描。
  static Future<void> stopScan() => BluetoothAdapter.stopScan();

  /// 扫描结果流（与 [FlutterBluePlus.scanResults] 行为一致）。
  static Stream<List<ScanResult>> get scanResultsStream => BluetoothAdapter.scanResults;

  /// 将 RSSI（常见约 -100～0 dBm）映射为 0～100 的展示用信号强度。
  static int rssiToSignalPercent(int rssi) {
    const int minRssi = -100;
    const int maxRssi = -40;
    final int clamped = rssi.clamp(minRssi, maxRssi);
    return (((clamped - minRssi) / (maxRssi - minRssi)) * 100).round();
  }

  /// 是否视为本项目目标硬件（MemoPin / AI_NOTE / AI_PEN 等命名或广播特征）。
  ///
  /// 若后续固件固定 Service UUID，可在此集中补充判断。
  static bool isMemoPinLikeScanResult(ScanResult result) {
    final String name = result.device.platformName.trim();
    if (name.isEmpty) {
      return false;
    }
    final String upper = name.toUpperCase();
    if (upper.contains('MEMOPIN')) {
      return true;
    }
    if (upper.startsWith('AI_NOTE') || upper.startsWith('AI_PEN')) {
      return true;
    }
    return false;
  }

  /// 从当前 [results] 去重并筛选 [isMemoPinLikeScanResult]，按 RSSI 降序。
  static List<MPBleScanEntry> entriesFromScanResults(List<ScanResult> results) {
    final Map<String, ScanResult> bestById = <String, ScanResult>{};
    for (final ScanResult r in results) {
      if (!isMemoPinLikeScanResult(r)) {
        continue;
      }
      final String id = r.device.remoteId.str;
      final ScanResult? prev = bestById[id];
      if (prev == null || r.rssi > prev.rssi) {
        bestById[id] = r;
      }
    }
    final List<ScanResult> sorted = bestById.values.toList()
      ..sort((ScanResult a, ScanResult b) => b.rssi.compareTo(a.rssi));
    return sorted.map((ScanResult r) {
      final String rawName = r.device.platformName.trim();
      final String display = rawName.isEmpty ? 'MemoPin (${r.device.remoteId.str})' : rawName;
      return MPBleScanEntry(
        remoteId: r.device.remoteId.str,
        displayName: display,
        rssi: r.rssi,
        signalPercent: rssiToSignalPercent(r.rssi),
      );
    }).toList();
  }

  /// 创建 GATT 传输实例（连接成功后可用于读写特征）。
  static BleTransport createBleTransport(BluetoothDevice device) => BleTransport(device);

  /// 通过远程 ID 获取 [BluetoothDevice]。
  static BluetoothDevice bluetoothDeviceFromRemoteId(String remoteId) => BluetoothDevice.fromId(remoteId);

  /// 在 [duration] 内扫描并返回 MemoPin 类设备列表（已按信号排序）。
  ///
  /// 内部会 [ensureBlePermissions]，并等待适配器处于 [BluetoothAdapterState.on]。
  static Future<List<MPBleScanEntry>> discoverMemoPinLikeDevices({
    Duration duration = const Duration(seconds: 5),
  }) async {
    final bool ok = await OmiPermissionService.requestBlePermissionsForScanAndConnect();
    if (!ok) {
      return <MPBleScanEntry>[];
    }
    final bool on = await waitForAdapterOn(timeout: const Duration(seconds: 15));
    if (!on) {
      return <MPBleScanEntry>[];
    }
    final List<ScanResult> buffer = <ScanResult>[];
    late final StreamSubscription<List<ScanResult>> sub;
    sub = BluetoothAdapter.scanResults.listen((List<ScanResult> list) {
      buffer
        ..clear()
        ..addAll(list);
    });
    try {
      await BluetoothAdapter.startScan(timeout: duration);
      await Future<void>.delayed(duration);
      return entriesFromScanResults(List<ScanResult>.from(buffer));
    } finally {
      await sub.cancel();
      if (BluetoothAdapter.isScanningNow) {
        await BluetoothAdapter.stopScan();
      }
    }
  }
}
