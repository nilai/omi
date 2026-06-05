import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:memo_pin/common/mp_home_notification.dart';
import 'package:memo_pin/permission/omi_permission_service.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:permission_manager/permission_manager.dart';

import 'mp_ble_platform.dart';
import 'mp_ble_file_util.dart';
import 'mp_ble_transport.dart';
import 'mp_ble_recording_watcher.dart';
import 'mp_device_transport.dart';
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

  /// BLE 设备 ID（与 [BleTransport.deviceId] 一致）。
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
/// 封装 [MPBlePlatform] 与权限申请，供连接页等模块调用。
class MPBleConnectionHelper {
  MPBleConnectionHelper._();

  static final MPBleRecordingWatcher _memopinRecordingWatcher = MPBleRecordingWatcher();

  /// 串行化 MemoPin GATT 命令，避免电量查询与文件列表等并发抢占同一 notify 导致误解析（如电量显示 100%）。
  static Future<void> _gattExclusiveChain = Future<void>.value();

  /// 在全局链上执行单次 GATT 相关操作。
  static Future<T> _runGattExclusive<T>(Future<T> Function() action) {
    final Future<T> run = _gattExclusiveChain.then((_) => action());
    _gattExclusiveChain = run.whenComplete(() {});
    return run;
  }

  /// 供 [MPBleFileUtil] 等设备文件命令串行调用（删除与列表/导出互斥）。
  static Future<T> runMemoPinGattExclusive<T>(Future<T> Function() action) => _runGattExclusive(action);

  /// MemoPin 外接设备正在录音时，阻止本机开录/恢复的英文提示。
  static const String memoPinDeviceRecordingBlockMessage =
      'MemoPin device is recording. Please try again later.';

  /// 若外接 MemoPin 正在录音则弹出 [memoPinDeviceRecordingBlockMessage] 并返回 `true`。
  static Future<bool> showBlockMessageIfMemoPinDeviceIsRecording({BuildContext? context}) async {
    if (!await isMemoPinDeviceRecordingForLocalRecordingGuard()) {
      return false;
    }
    MPToastUtils.showMessage(memoPinDeviceRecordingBlockMessage, context: context);
    return true;
  }

  /// 外接 MemoPin 是否正在录音：用于禁止本机开录 / 恢复采集。
  ///
  /// 仅依据 [memoPinRecordingStateSnapshot]（由 [MPBleRecordingWatcher] 通知流维护）。
  static Future<bool> isMemoPinDeviceRecordingForLocalRecordingGuard() async {
    if (memoPinRecordingStateSnapshot.isRecording) {
      debugPrint('------>>>memopin recordingGuard: block (snapshot recording=true)');
      return true;
    }
    return false;
  }

  /// 最近一次对外通知的录音状态快照（默认未录音，见 [MPBleRecordingWatcher.lastEmitted]）。
  static MPBleMemopinRecordingStateChangedPayload get memoPinRecordingStateSnapshot =>
      _memopinRecordingWatcher.lastEmitted;

  /// 外接 MemoPin 是否正在录音（与 [memoPinRecordingStateSnapshot.isRecording] 一致）。
  static bool get isMemoPinDeviceRecording => _memopinRecordingWatcher.isRecording;

  /// 当前外接录音文件名（设备 303 上报）。
  static String? get memoPinActiveRecordingFileName => _memopinRecordingWatcher.activeFileName;

  /// 最近一次实时落盘本地路径。
  static String? get memoPinLastRealtimeAudioLocalPath => _memopinRecordingWatcher.lastRealtimeAudioLocalPath;

  /// 与 [MPHomeNotification.bleMemopinRecordingStateEvents] 相同，便于仅从 Helper 引用。
  static Stream<MPBleMemopinRecordingStateChangedPayload> get memoPinRecordingStateChangedStream =>
      MPHomeNotification.bleMemopinRecordingStateEvents;

  /// 连接页关闭后仍要保持的 GATT 会话（不断开 physical link）。
  ///
  /// 由 [MPConnectDeviceCubit] 在 `close` 时 [parkBackgroundBleTransport]，重新进入时
  /// [takeBackgroundBleTransport] 取回；**仅**用户主动断开 / 登出时由 [disconnectBackgroundBleTransportUserInitiated] 清理。
  static BleTransport? _backgroundBleTransport;

  static StreamSubscription<MPDeviceTransportState>? _backgroundConnSub;

  /// 将当前已连接的 [transport] 存为背景会话（仅持有引用，不 disconnect）。
  static Future<void> parkBackgroundBleTransport(BleTransport? transport) async {
    debugPrint(
      '------>>>memopin parkBackgroundBleTransport: ${transport == null ? "null" : "deviceId=${transport.deviceId}"}',
    );
    _backgroundBleTransport = transport;
    if (transport != null) {
      _attachBackgroundConnectionMonitor(transport);
    } else {
      _detachBackgroundConnectionMonitor();
    }
    await _memopinRecordingWatcher.attach(transport);
    await _memopinRecordingWatcher.waitForConnectProbe();
  }

  /// 当前背景持有的 [BleTransport]（未停放时为 `null`）；与连接页 [_transport] 可能指向同一实例。
  static BleTransport? get backgroundBleTransport => _backgroundBleTransport;

  /// 取出背景会话引用（取出后 helper 不再持有，一般由连接页 Cubit 接管）。
  static BleTransport? takeBackgroundBleTransport() {
    debugPrint('------>>>memopin takeBackgroundBleTransport');
    final BleTransport? t = _backgroundBleTransport;
    _backgroundBleTransport = null;
    _detachBackgroundConnectionMonitor();
    // 不断开 [MPBleRecordingWatcher]：连接页接管同一 [BleTransport] 时仍需监听 303/301。
    return t;
  }

  /// 背景会话链路监听：设备关机/超出范围时通知首页更新顶栏图标（连接页关闭后仍生效）。
  static void _attachBackgroundConnectionMonitor(BleTransport transport) {
    unawaited(_backgroundConnSub?.cancel());
    _backgroundConnSub = transport.connectionStateStream.listen((MPDeviceTransportState s) {
      if (s == MPDeviceTransportState.disconnected || s == MPDeviceTransportState.disconnecting) {
        unawaited(_onBackgroundTransportLinkLost());
      }
    });
  }

  static void _detachBackgroundConnectionMonitor() {
    unawaited(_backgroundConnSub?.cancel());
    _backgroundConnSub = null;
  }

  /// 被动掉线：二次确认后通知首页（忽略 GATT 瞬时 disconnected）。
  static Future<void> _onBackgroundTransportLinkLost() async {
    final BleTransport? t = _backgroundBleTransport;
    if (t == null) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!identical(_backgroundBleTransport, t)) {
      return;
    }
    try {
      if (await t.isConnected()) {
        return;
      }
    } catch (_) {
      // treat as disconnected
    }
    debugPrint('------>>>memopin background BLE link lost deviceId=${t.deviceId}');
    MPHomeNotification.notifyBleDisconnected();
  }

  /// 释放背景会话并断开 BLE（**仅**用户主动断开、切换设备前清理、登出）。
  static Future<void> disconnectBackgroundBleTransportUserInitiated() async {
    debugPrint('------>>>memopin disconnectBackgroundBleTransportUserInitiated');
    _detachBackgroundConnectionMonitor();
    await MPBleFileUtil.cancelActiveDeviceSync();
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
    MPHomeNotification.notifyBleDisconnected();
  }

  /// 对已有背景 [BleTransport] 尝试重连（不因瞬时掉线而 dispose）。
  static Future<bool> tryReconnectBackgroundTransport(String remoteId) async {
    final BleTransport? bg = _backgroundBleTransport;
    if (bg == null || bg.deviceId != remoteId) {
      return false;
    }
    try {
      if (await bg.isConnected()) {
        _attachBackgroundConnectionMonitor(bg);
        return true;
      }
      debugPrint('------>>>memopin tryReconnectBackgroundTransport: reconnect remoteId=$remoteId');
      await bg.connect();
      await _memopinRecordingWatcher.attach(bg);
      await _memopinRecordingWatcher.waitForConnectProbe();
      _attachBackgroundConnectionMonitor(bg);
      return true;
    } catch (e) {
      debugPrint('------>>>memopin tryReconnectBackgroundTransport failed: $e');
      return false;
    }
  }

  /// 登出或需要彻底释放应用侧 BLE 时调用。
  static Future<void> disconnectAppBleForLogout() async {
    debugPrint('------>>>memopin disconnectAppBleForLogout');
    await MPBlePlatform.instance.stopScan();
    await disconnectBackgroundBleTransportUserInitiated();
  }

  /// 确保 [_backgroundBleTransport] 链路可用（必要时尝试 GATT 探测 / 重连）。
  static Future<bool> ensureBackgroundTransportReady() async {
    final BleTransport? bg = _backgroundBleTransport;
    if (bg == null) {
      return false;
    }
    try {
      if (await bg.isConnected()) {
        return true;
      }
    } catch (_) {
      // ignore
    }
    final MPLastBleDeviceRecord? r = MPBlePreferences.instance.readLastConnectedBleDevice();
    if (r != null && r.remoteId == bg.deviceId) {
      return tryReconnectBackgroundTransport(r.remoteId);
    }
    return false;
  }

  /// 供连接页 / 调试页等共用的当前 [BleTransport]（始终读 [_backgroundBleTransport]）。
  static BleTransport? get activeBleTransport => _backgroundBleTransport;

  /// 首页顶栏等 UI：仅当应用仍持有 [backgroundBleTransport] 且 GATT 可用时为 `true`（不因系统层仍连着而误判）。
  static Future<bool> hasConnectedBleDevice() async {
    final BleTransport? bg = _backgroundBleTransport;
    if (bg == null) {
      return false;
    }
    try {
      return await bg.isConnected();
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
    if (bg != null && bg.deviceId == r.remoteId) {
      try {
        if (await bg.isConnected()) {
          debugPrint('------>>>memopin tryConnectLastRecordedBleDevice: reuse bg remoteId=${r.remoteId}');
          _attachBackgroundConnectionMonitor(bg);
          return true;
        }
      } catch (_) {
        // ignore
      }
      if (await tryReconnectBackgroundTransport(r.remoteId)) {
        debugPrint('------>>>memopin tryConnectLastRecordedBleDevice: reconnected bg remoteId=${r.remoteId}');
        return true;
      }
      debugPrint('------>>>memopin tryConnectLastRecordedBleDevice: bg present but not connected, keep session (no auto disconnect)');
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

    final BleTransport transport = createBleTransport(r.remoteId);
    try {
      debugPrint('------>>>memopin tryConnectLastRecordedBleDevice: connecting remoteId=${r.remoteId}');
      await transport.connect();
      await MPBleConnectionHelper.parkBackgroundBleTransport(transport);
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
  static Future<bool> get isBleSupported => MPBlePlatform.instance.isBleSupported;

  /// 适配器是否已就绪（[BleStatus.ready]）。
  static Future<bool> get isAdapterPoweredOn async {
    return waitForAdapterOn(timeout: const Duration(seconds: 5));
  }

  /// 当前主机 BLE 子系统状态。
  static BleStatus get bleStatus => MPBlePlatform.instance.currentStatus;

  /// 等待 [BleStatus.ready]；冷启动时需监听 [MPBlePlatform.statusStream] 而非同步 getter。
  static Future<bool> waitForAdapterOn({Duration timeout = const Duration(seconds: 10)}) async {
    return MPBlePlatform.instance.waitUntilBleReady(timeout: timeout);
  }

  /// reactive_ble 无法代开蓝牙；保留入口供 UI 在 [BleStatus.poweredOff] 时调用（实际引导用户手动开启）。
  static Future<void> tryTurnBluetoothOn() => MPBlePlatform.instance.tryTurnBluetoothOn();

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

  /// 停止当前 BLE 扫描（[MPBlePlatform.runScan] 结束时亦会调用）。
  static Future<void> stopScan() => MPBlePlatform.instance.stopScan();

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
  static bool isMemoPinLikeDiscoveredDevice(DiscoveredDevice device) {
    if (MPBleScanFilterUuids.matchesMemoPinAdvertisedService(device.serviceUuids)) {
      return true;
    }
    final String aiNote = MPBleScanFilterUuids.aiNoteService.toLowerCase();
    final bool hasAiNoteUuid = device.serviceUuids.any(
      (Uuid uuid) => uuid.toString().toLowerCase() == aiNote,
    );
    if (hasAiNoteUuid) {
      return true;
    }
    return _isAiNoteLikeDeviceName(device.name);
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

  /// 等到 [BleStatus.ready] 再扫。
  static Future<bool> _waitAdapterOnForDiscovery({Duration timeout = const Duration(seconds: 30)}) async {
    return MPBlePlatform.instance.waitUntilBleReady(timeout: timeout);
  }

  /// 从当前 [devices] 去重并筛选 [isMemoPinLikeDiscoveredDevice]，按 RSSI 降序。
  static List<MPBleScanEntry> entriesFromDiscoveredDevices(Iterable<DiscoveredDevice> devices) {
    final Map<String, DiscoveredDevice> bestById = <String, DiscoveredDevice>{};
    for (final DiscoveredDevice d in devices) {
      if (!isMemoPinLikeDiscoveredDevice(d)) {
        continue;
      }
      final String id = d.id;
      final DiscoveredDevice? prev = bestById[id];
      if (prev == null || d.rssi > prev.rssi) {
        bestById[id] = d;
      }
    }
    final List<DiscoveredDevice> sorted = bestById.values.toList()
      ..sort((DiscoveredDevice a, DiscoveredDevice b) => b.rssi.compareTo(a.rssi));
    final List<MPBleScanEntry> entries = sorted.map((DiscoveredDevice d) {
      final String rawName = d.name.trim();
      final String display = rawName.isEmpty ? 'MemoPin (${d.id})' : rawName;
      return MPBleScanEntry(
        remoteId: d.id,
        displayName: display,
        rssi: d.rssi,
        signalPercent: rssiToSignalPercent(d.rssi),
      );
    }).toList();
    debugPrint('------>>>memopin entriesFromDiscoveredDevices: raw=${devices.length} → entries=${entries.length}');
    return entries;
  }

  /// 创建 GATT 传输实例（连接成功后可用于读写特征）。
  static BleTransport createBleTransport(String remoteId, {String displayName = ''}) =>
      BleTransport(remoteId, displayName: displayName);

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

  /// 与 `BluetoothDeviceDiscoverer.discover` 两阶段策略一致；设备筛选规则见 [isMemoPinLikeDiscoveredDevice]（对齐 [BtDevice.isAiNoteDevice]）。
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

    debugPrint('------>>>memopin scanMemoPinLikeEntriesPhased: adapter ready, reactive_ble scan');
    final Map<String, DiscoveredDevice> bestById = <String, DiscoveredDevice>{};

    void bufferDevice(DiscoveredDevice d) {
      final String id = d.id;
      final DiscoveredDevice? prev = bestById[id];
      if (prev == null || d.rssi > prev.rssi) {
        bestById[id] = d;
      }
    }

    List<MPBleScanEntry> finishFromBuffer() {
      return entriesFromDiscoveredDevices(bestById.values);
    }

    final MPBlePlatform platform = MPBlePlatform.instance;
    try {
      debugPrint(
        '------>>>memopin scanMemoPinLikeEntriesPhased: phase1 withServices count=${MPBleScanFilterUuids.scanFilterUuids.length} timeout=${perPhase.inSeconds}s',
      );
      await platform.runScan(
        duration: perPhase,
        withServices: MPBleScanFilterUuids.scanFilterUuids,
        onDevice: bufferDevice,
      );

      List<MPBleScanEntry> entries = finishFromBuffer();
      debugPrint('------>>>memopin scanMemoPinLikeEntriesPhased: phase1 filtered count=${entries.length}');

      if (entries.isNotEmpty) {
        debugPrint('------>>>memopin scanMemoPinLikeEntriesPhased: phase1 has results → return');
        return entries;
      }

      bestById.clear();
      debugPrint('------>>>memopin scanMemoPinLikeEntriesPhased: phase2 no service filter');
      await platform.runScan(duration: perPhase, onDevice: bufferDevice);
      entries = finishFromBuffer();
      debugPrint('------>>>memopin scanMemoPinLikeEntriesPhased: phase2 filtered count=${entries.length}');
      return entries;
    } finally {
      await platform.stopScan();
    }
  }

  /// 解析展示名：优先本地持久化记录，否则返回 `MemoPin ($remoteId)`。
  static Future<String> resolveMemoPinDisplayName(String remoteId) async {
    final MPLastBleDeviceRecord? r = MPBlePreferences.instance.readLastConnectedBleDevice();
    if (r != null && r.remoteId == remoteId && r.displayName.trim().isNotEmpty) {
      return r.displayName;
    }
    return 'MemoPin ($remoteId)';
  }

  /// 构造 Note 协议 GATT 客户端；导出文件期间须持续持有直至传输结束，再调用 [MPNoteBleGattClient.dispose]。
  static MPNoteBleGattClient createMemoPinGattClient(BleTransport transport) => MPNoteBleGattClient(transport);

  /// 读取 MemoPin / AI_NOTE 电量：优先走自定义命令 [MPNoteBleCommands.queryBattery]，失败则回退标准 BAS。
  static Future<int?> readMemoPinBatteryPercent(BleTransport transport) {
    return _runGattExclusive(() => _readMemoPinBatteryPercentImpl(transport));
  }

  static Future<int?> _readMemoPinBatteryPercentImpl(BleTransport transport) async {
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

  /// 录音连接探测用：返回设备上全部 `.opus`（含录音中、文件名未带 `_` 的项）。
  static Future<List<NoteFileInfo>> fetchMemoPinFileListForRecordingProbe(BleTransport transport) {
    return _runGattExclusive(() => _fetchMemoPinFileListForRecordingProbeImpl(transport));
  }

  static Future<List<NoteFileInfo>> _fetchMemoPinFileListForRecordingProbeImpl(BleTransport transport) async {
    debugPrint('------>>>memopin fetchMemoPinFileListForRecordingProbe: deviceId=${transport.deviceId}');
    final MPNoteBleGattClient client = MPNoteBleGattClient(transport);
    try {
      final List<NoteFileInfo> list = await client.getFileListForRecordingProbe();
      debugPrint('------>>>memopin fetchMemoPinFileListForRecordingProbe: count=${list.length}');
      return list;
    } finally {
      await client.dispose();
    }
  }

  /// 等待本次 [parkBackgroundBleTransport] 触发的录音连接探测结束（供首页同步顶栏）。
  static Future<void> waitForRecordingConnectProbe() {
    return _memopinRecordingWatcher.waitForConnectProbe();
  }

  /// 获取设备端录音文件列表（命令 `0x03`，含多包拼接）。
  static Future<List<NoteFileInfo>> fetchMemoPinFileList(BleTransport transport) {
    return _runGattExclusive(() => _fetchMemoPinFileListImpl(transport));
  }

  static Future<List<NoteFileInfo>> _fetchMemoPinFileListImpl(BleTransport transport) async {
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
