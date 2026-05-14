import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:memo_pin/common/mp_home_notification.dart';
import 'package:memo_pin/permission/omi_permission_service.dart';
import 'package:memo_pin/utils/bluetooth/bluetooth_adapter.dart';
import 'package:permission_manager/permission_manager.dart';

import 'ble_transport.dart';
import 'mp_ble_memopin_recording_state_watcher.dart';
import 'mp_ble_preferences.dart';
import 'mp_ble_scan_uuids.dart';
import 'mp_note_ble_gatt_client.dart';
import 'mp_note_ble_protocol.dart';
import 'note_device.dart';

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
class MPBleConnectionHelper {
  MPBleConnectionHelper._();

  static final MPBleMemopinRecordingStateWatcher _memopinRecordingWatcher =
      MPBleMemopinRecordingStateWatcher();

  /// 外接 MemoPin 是否正在录音：用于禁止本机开录 / 恢复采集。
  ///
  /// 先读 [memoPinRecordingStateSnapshot]（通知可能早于 GATT 读）；再在有已连接
  /// [backgroundBleTransport] 时用 [readMemoPinRecordingStatus] 兜底，降低漏判。
  static Future<bool> isMemoPinDeviceRecordingForLocalRecordingGuard() async {
    if (memoPinRecordingStateSnapshot.isRecording) {
      debugPrint('------>>>memopin recordingGuard: block (snapshot recording=true)');
      return true;
    }
    final BleTransport? t = backgroundBleTransport;
    if (t == null) {
      return false;
    }
    try {
      if (!await t.isConnected()) {
        return false;
      }
    } catch (_) {
      return false;
    }
    try {
      final MPBleMemopinRecordStatus310 st = await readMemoPinRecordingStatus(t);
      if (st.isRecording) {
        debugPrint('------>>>memopin recordingGuard: block (GATT recording=true)');
      }
      return st.isRecording;
    } catch (_) {
      return memoPinRecordingStateSnapshot.isRecording;
    }
  }

  /// 主动读取 `e2c1a310` 录音状态（未连接时返回「未录音」解析结果）。
  static Future<MPBleMemopinRecordStatus310> readMemoPinRecordingStatus(BleTransport transport) async {
    try {
      if (!await transport.isConnected()) {
        debugPrint('------>>>memopin readMemoPinRecordingStatus: not connected → idle deviceId=${transport.deviceId}');
        return const MPBleMemopinRecordStatus310(isRecording: false);
      }
    } catch (_) {
      return const MPBleMemopinRecordStatus310(isRecording: false);
    }
    return MPBleMemopinRecordingStateWatcher.readStatus310(transport);
  }

  /// 最近一次对外通知的录音状态快照（默认未录音，见 [MPBleMemopinRecordingStateWatcher.lastEmitted]）。
  static MPBleMemopinRecordingStateChangedPayload get memoPinRecordingStateSnapshot =>
      _memopinRecordingWatcher.lastEmitted;

  /// 与 [MPHomeNotification.bleMemopinRecordingStateEvents] 相同，便于仅从 Helper 引用。
  static Stream<MPBleMemopinRecordingStateChangedPayload> get memoPinRecordingStateChangedStream =>
      MPHomeNotification.bleMemopinRecordingStateEvents;

  /// 连接页关闭后仍要保持的 GATT 会话（不断开 physical link）。
  ///
  /// 由 [MPConnectDeviceCubit] 在 `close` 时 [parkBackgroundBleTransport]，重新进入时
  /// [takeBackgroundBleTransport] 取回；用户主动断开时由 [disposeBackgroundBleTransportIfAny] 清理。
  static BleTransport? _backgroundBleTransport;

  /// 将当前已连接的 [transport] 存为背景会话（仅持有引用，不 disconnect）。
  static void parkBackgroundBleTransport(BleTransport? transport) {
    debugPrint(
      '------>>>memopin parkBackgroundBleTransport: ${transport == null ? "null" : "deviceId=${transport.deviceId}"}',
    );
    _backgroundBleTransport = transport;
    unawaited(_memopinRecordingWatcher.attach(transport));
  }

  /// 当前背景持有的 [BleTransport]（未停放时为 `null`）；与连接页 [_transport] 可能指向同一实例。
  static BleTransport? get backgroundBleTransport => _backgroundBleTransport;

  /// 取出背景会话引用（取出后 helper 不再持有，一般由连接页 Cubit 接管）。
  static BleTransport? takeBackgroundBleTransport() {
    debugPrint('------>>>memopin takeBackgroundBleTransport');
    final BleTransport? t = _backgroundBleTransport;
    _backgroundBleTransport = null;
    unawaited(_memopinRecordingWatcher.attach(null));
    return t;
  }

  /// 释放背景会话并断开 BLE（用户主动断开或连接新设备前清理）。
  static Future<void> disposeBackgroundBleTransportIfAny() async {
    debugPrint('------>>>memopin disposeBackgroundBleTransportIfAny');
    await _memopinRecordingWatcher.detach();
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
    debugPrint('------>>>memopin disconnectAppBleForLogout');
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
    debugPrint('------>>>memopin tryConnectLastRecordedBleDevice: begin');
    final MPLastBleDeviceRecord? r = MPBlePreferences.instance.readLastConnectedBleDevice();
    if (r == null) {
      debugPrint('------>>>memopin tryConnectLastRecordedBleDevice: no saved device');
      return false;
    }

    final BleTransport? bg = _backgroundBleTransport;
    if (bg != null) {
      try {
        if (bg.deviceId == r.remoteId && await bg.isConnected()) {
          debugPrint('------>>>memopin tryConnectLastRecordedBleDevice: reuse bg remoteId=${r.remoteId}');
          return true;
        }
      } catch (_) {
        // ignore
      }
      debugPrint('------>>>memopin tryConnectLastRecordedBleDevice: dispose stale bg');
      await disposeBackgroundBleTransportIfAny();
    }

    final bool supported = await isBleSupported;
    if (!supported) {
      debugPrint('------>>>memopin tryConnectLastRecordedBleDevice: BLE not supported');
      return false;
    }

    final bool permitted = await ensureBlePermissions();
    if (!permitted) {
      debugPrint('------>>>memopin tryConnectLastRecordedBleDevice: permission denied');
      return false;
    }

    // 两阶段短扫（带 Service UUID → 全量），再按记录的 remoteId 直接建链。
    debugPrint('------>>>memopin tryConnectLastRecordedBleDevice: discoverMemoPinLikeDevices');
    await discoverMemoPinLikeDevices(perPhase: const Duration(seconds: 5));

    final BluetoothDevice device = bluetoothDeviceFromRemoteId(r.remoteId);
    final BleTransport transport = createBleTransport(device);
    try {
      debugPrint('------>>>memopin tryConnectLastRecordedBleDevice: connecting remoteId=${r.remoteId}');
      await transport.connect();
      parkBackgroundBleTransport(transport);
      MPHomeNotification.notifyBleConnectedSuccess();
      debugPrint('------>>>memopin tryConnectLastRecordedBleDevice: connected OK');
      return true;
    } catch (e) {
      debugPrint('------>>>memopin tryConnectLastRecordedBleDevice: connect failed $e');
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
  static Future<bool> waitForAdapterOn({Duration timeout = const Duration(seconds: 10)}) async {
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
  ///
  /// 若未授予会弹出英文说明（含再次拒绝后仍可见的提示）。
  static Future<bool> ensureBlePermissions() async {
    final bool granted = await OmiPermissionService.requestBlePermissionsForScanAndConnect();
    if (!granted) {
      await _notifyBlePermissionDenied();
    }
    return granted;
  }

  static Future<void> _notifyBlePermissionDenied() async {
    final PermissionManagerStatus worst = await OmiPermissionService.bleScanConnectPermissionWorstStatus();
    if (worst == PermissionManagerStatus.permanentlyDenied) {
      debugPrint(
        'BLE permission: Bluetooth permission is required. Open Settings and allow Bluetooth access for this app.',
      );
    } else if (worst == PermissionManagerStatus.restricted) {
      debugPrint('BLE permission: Bluetooth access is restricted on this device.');
    } else {
      debugPrint(
        'BLE permission: Bluetooth permission is required to scan and connect. Tap Allow if prompted, or enable it in Settings.',
      );
    }
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

  /// 与 `lib/blu/ble/bt_device.dart` 中 [BtDevice.isAiNoteDevice] 等价（MemoPin 额外接受名称含 MEMOPIN）。
  ///
  /// 优先级：广播 Service UUID → 名称前缀（AI_PIN / AI_CARD / AI_PEN / AI_NOTE / AI_MIC / NOTE / TX_NOTE …）。
  /// 若固件仅广播 **新** Service UUID，须在 [MPBleScanFilterUuids.additionalMemoPinAdvertisementServices] 中登记。
  static bool isMemoPinLikeScanResult(ScanResult result) {
    if (MPBleScanFilterUuids.matchesMemoPinAdvertisedService(result.advertisementData.serviceUuids)) {
      return true;
    }
    // 与 ble 侧 `uuid.toString().toLowerCase() == aiNoteServiceUuid` 一致。
    final String aiNote = MPBleScanFilterUuids.aiNoteService.toLowerCase();
    final bool hasAiNoteUuid = result.advertisementData.serviceUuids.any(
      (Guid uuid) => uuid.toString().toLowerCase() == aiNote,
    );
    if (hasAiNoteUuid) {
      return true;
    }
    return _isAiNoteLikeDeviceName(result.device.platformName);
  }

  /// 对应 ble `BtDevice.isAiNoteDevice` 的名称分支；含 MemoPin 展示名。
  static bool _isAiNoteLikeDeviceName(String platformName) {
    final String name = platformName.trim().toUpperCase();
    if (name.isEmpty) {
      return false;
    }
    if (name.contains('MEMOPIN')) {
      return true;
    }
    return name.startsWith('AI_PIN') ||
        name.startsWith('AI_CARD') ||
        name.startsWith('AI_PEN') ||
        name.startsWith('AI_NOTE') ||
        name.startsWith('AI_MIC') ||
        name.startsWith('NOTE') ||
        name.startsWith('TX_NOTE');
  }

  /// 与 `lib/blu/ble/bluetooth_discoverer.dart` 一致：等到适配器 [BluetoothAdapterState.on] 再扫。
  static Future<bool> _waitAdapterOnForDiscovery({Duration timeout = const Duration(seconds: 30)}) async {
    if (FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on) {
      return true;
    }
    try {
      await BluetoothAdapter.adapterState
          .where((BluetoothAdapterState s) => s == BluetoothAdapterState.on)
          .first
          .timeout(timeout);
      return true;
    } on TimeoutException {
      return FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on;
    }
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
    final List<MPBleScanEntry> entries = sorted.map((ScanResult r) {
      final String rawName = r.device.platformName.trim();
      final String display = rawName.isEmpty ? 'MemoPin (${r.device.remoteId.str})' : rawName;
      return MPBleScanEntry(
        remoteId: r.device.remoteId.str,
        displayName: display,
        rssi: r.rssi,
        signalPercent: rssiToSignalPercent(r.rssi),
      );
    }).toList();
    debugPrint('------>>>memopin entriesFromScanResults: raw=${results.length} → entries=${entries.length}');
    return entries;
  }

  /// 创建 GATT 传输实例（连接成功后可用于读写特征）。
  static BleTransport createBleTransport(BluetoothDevice device) => BleTransport(device);

  /// 通过远程 ID 获取 [BluetoothDevice]。
  static BluetoothDevice bluetoothDeviceFromRemoteId(String remoteId) => BluetoothDevice.fromId(remoteId);

  /// 在至多 **两段** [perPhase] 扫描内返回 MemoPin / aiNote 类设备（已按信号排序）。
  ///
  /// 流程对齐 `lib/blu/ble/bluetooth_discoverer.dart`：适配器 ON → 首轮 `withServices`（仅 [MPBleScanFilterUuids]）→
  /// 若筛选后列表为空再第二轮 **无** UUID 过滤；第二轮开始前清空缓冲（与 ble 的 `bleResults.clear()` 一致）。
  /// 内部会 [ensureBlePermissions]（当 [requirePermissionsAndAdapter] 为真）。
  ///
  /// 总耗时：首轮有结果约 `perPhase`，否则约 `2 * perPhase`。
  static Future<List<MPBleScanEntry>> discoverMemoPinLikeDevices({
    Duration perPhase = const Duration(seconds: 5),
  }) async {
    return scanMemoPinLikeEntriesPhased(perPhase: perPhase, requirePermissionsAndAdapter: true);
  }

  /// 与 `BluetoothDeviceDiscoverer.discover` 两阶段策略一致；设备筛选规则见 [isMemoPinLikeScanResult]（对齐 [BtDevice.isAiNoteDevice]）。
  ///
  /// [requirePermissionsAndAdapter] 为 `false` 时由调用方保证已授权，此处仍 [_waitAdapterOnForDiscovery]。
  static Future<List<MPBleScanEntry>> scanMemoPinLikeEntriesPhased({
    Duration perPhase = const Duration(seconds: 5),
    bool requirePermissionsAndAdapter = true,
  }) async {
    if (requirePermissionsAndAdapter) {
      final bool ok = await OmiPermissionService.requestBlePermissionsForScanAndConnect();
      if (!ok) {
        await _notifyBlePermissionDenied();
        return <MPBleScanEntry>[];
      }
    }

    final bool adapterOn = await _waitAdapterOnForDiscovery();
    if (!adapterOn) {
      debugPrint('------>>>memopin scanMemoPinLikeEntriesPhased: adapter not on → empty');
      return <MPBleScanEntry>[];
    }

    debugPrint('------>>>memopin scanMemoPinLikeEntriesPhased: adapter on, subscribing scanResults');
    final Map<String, ScanResult> bestById = <String, ScanResult>{};
    late final StreamSubscription<List<ScanResult>> sub;
    // 与 ble 订阅方式一致；不按空名称丢弃，避免仅 UUID 广播、无 local name 的设备被漏掉。
    sub = BluetoothAdapter.scanResults.listen(
      (List<ScanResult> list) {
        for (final ScanResult r in list) {
          final String id = r.device.remoteId.str;
          final ScanResult? prev = bestById[id];
          if (prev == null || r.rssi > prev.rssi) {
            bestById[id] = r;
          }
        }
      },
      onError: (Object e) {
        debugPrint('------>>>memopin scanMemoPinLikeEntriesPhased: scanResults error: $e');
      },
    );

    List<MPBleScanEntry> finishFromBuffer() {
      return entriesFromScanResults(bestById.values.toList());
    }

    try {
      debugPrint(
        '------>>>memopin scanMemoPinLikeEntriesPhased: phase1 withServices count=${MPBleScanFilterUuids.scanFilterGuids.length} timeout=${perPhase.inSeconds}s',
      );
      await BluetoothAdapter.startScan(timeout: perPhase, withServices: MPBleScanFilterUuids.scanFilterGuids);
      await Future<void>.delayed(perPhase);

      List<MPBleScanEntry> entries = finishFromBuffer();
      debugPrint('------>>>memopin scanMemoPinLikeEntriesPhased: phase1 filtered count=${entries.length}');

      if (entries.isNotEmpty) {
        debugPrint('------>>>memopin scanMemoPinLikeEntriesPhased: phase1 has results → return');
        return entries;
      }

      bestById.clear();
      if (BluetoothAdapter.isScanningNow) {
        await BluetoothAdapter.stopScan();
      }

      debugPrint('------>>>memopin scanMemoPinLikeEntriesPhased: phase2 no service filter');
      await BluetoothAdapter.startScan(timeout: perPhase);
      await Future<void>.delayed(perPhase);
      entries = finishFromBuffer();
      debugPrint('------>>>memopin scanMemoPinLikeEntriesPhased: phase2 filtered count=${entries.length}');
      return entries;
    } finally {
      await sub.cancel();
      if (BluetoothAdapter.isScanningNow) {
        await BluetoothAdapter.stopScan();
      }
    }
  }

  /// 解析当前可见的 BLE 广播名（已连接或缓存于系统的设备）。
  ///
  /// 优先 [BluetoothDevice.platformName]，为空时返回 `MemoPin ($remoteId)`。
  static Future<String> resolveMemoPinDisplayName(String remoteId) async {
    try {
      final BluetoothDevice d = BluetoothDevice.fromId(remoteId);
      final String raw = d.platformName.trim();
      if (raw.isNotEmpty) {
        return raw;
      }
    } catch (_) {
      // ignore
    }
    return 'MemoPin ($remoteId)';
  }

  /// 构造 Note 协议 GATT 客户端；导出文件期间须持续持有直至传输结束，再调用 [MPNoteBleGattClient.dispose]。
  static MPNoteBleGattClient createMemoPinGattClient(BleTransport transport) => MPNoteBleGattClient(transport);

  /// 读取 MemoPin / AI_NOTE 电量：优先走自定义命令 [MPNoteBleCommands.queryBattery]，失败则回退标准 BAS。
  static Future<int?> readMemoPinBatteryPercent(BleTransport transport) async {
    debugPrint('------>>>memopin readMemoPinBatteryPercent: deviceId=${transport.deviceId}');
    try {
      if (!await transport.isConnected()) {
        return null;
      }
    } catch (_) {
      return null;
    }

    final MPNoteBleGattClient client = MPNoteBleGattClient(transport);
    try {
      final MPNoteBatteryReading? r = await client.readBattery();
      if (r != null && r.percent >= 0 && r.percent <= 100) {
        debugPrint('------>>>memopin readMemoPinBatteryPercent: custom cmd → ${r.percent}%');
        return r.percent;
      }
    } catch (_) {
      // ignore
    } finally {
      await client.dispose();
    }

    try {
      final int? bas = await transport.readStandardBatteryPercent();
      debugPrint('------>>>memopin readMemoPinBatteryPercent: BAS fallback → $bas');
      return bas;
    } catch (_) {
      return null;
    }
  }

  /// 获取设备端录音文件列表（命令 `0x03`，含多包拼接）。
  static Future<List<NoteFileInfo>> fetchMemoPinFileList(BleTransport transport) async {
    debugPrint('------>>>memopin fetchMemoPinFileList: deviceId=${transport.deviceId}');
    final MPNoteBleGattClient client = MPNoteBleGattClient(transport);
    try {
      final List<NoteFileInfo> list = await client.getFileList();
      debugPrint('------>>>memopin fetchMemoPinFileList: count=${list.length}');
      return list;
    } finally {
      await client.dispose();
    }
  }

  /// 发起文件导出：配置装配器并发送 `0x04`；成功后监听 [MPNoteBleGattClient.recordFilePayloadStream]。
  ///
  /// **同一 [client] 实例**在导出过程中必须保持存活，结束后 [MPNoteBleGattClient.dispose]。
  static Future<bool> startMemoPinFileExport(MPNoteBleGattClient client, String fileName) async {
    debugPrint('------>>>memopin startMemoPinFileExport: $fileName');
    client.prepareFileExport(fileName);
    final bool ok = await client.requestFileExport(fileName);
    debugPrint('------>>>memopin startMemoPinFileExport: accepted=$ok');
    return ok;
  }
}
