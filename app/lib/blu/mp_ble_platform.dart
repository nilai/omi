import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// MemoPin BLE 平台门面：权限由 [OmiPermissionService] 负责，本类统一
/// [FlutterReactiveBle] 单例、适配器就绪等待与扫描生命周期，避免与 GATT 层双栈切换。
class MPBlePlatform {
  MPBlePlatform._();

  /// 全局共享实例。
  static final MPBlePlatform instance = MPBlePlatform._();

  final FlutterReactiveBle ble = FlutterReactiveBle();

  StreamSubscription<DiscoveredDevice>? _activeScanSub;
  bool _isScanning = false;

  /// 当前主机 BLE 子系统状态。
  BleStatus get currentStatus => ble.status;

  /// 主机 BLE 状态流。
  Stream<BleStatus> get statusStream => ble.statusStream;

  /// 是否正在扫描。
  bool get isScanningNow => _isScanning;

  /// 硬件/系统是否支持 BLE（非 [BleStatus.unsupported]）。
  Future<bool> get isBleSupported async {
    BleStatus status = ble.status;
    if (status == BleStatus.unknown) {
      try {
        status = await ble.statusStream
            .where((BleStatus s) => s != BleStatus.unknown)
            .first
            .timeout(const Duration(seconds: 3));
      } on TimeoutException {
        status = ble.status;
      }
    }
    return status != BleStatus.unsupported;
  }

  /// 等待 [BleStatus.ready]；超时返回当前是否已为 ready。
  Future<bool> waitUntilBleReady({Duration timeout = const Duration(seconds: 10)}) async {
    if (ble.status == BleStatus.ready) {
      return true;
    }
    try {
      await ble.statusStream
          .where((BleStatus s) => s == BleStatus.ready)
          .first
          .timeout(timeout);
      return true;
    } on TimeoutException {
      return ble.status == BleStatus.ready;
    }
  }

  /// reactive_ble 无法代开系统蓝牙；由 UI 引导用户手动开启。
  Future<void> tryTurnBluetoothOn() async {
    debugPrint('------>>>memopin MPBlePlatform.tryTurnBluetoothOn: not supported, prompt user');
  }

  /// 停止当前扫描订阅。
  Future<void> stopScan() async {
    _isScanning = false;
    await _activeScanSub?.cancel();
    _activeScanSub = null;
  }

  /// 在 [duration] 内扫描；每发现一台设备调用 [onDevice]。
  Future<void> runScan({
    required Duration duration,
    List<Uuid> withServices = const <Uuid>[],
    required void Function(DiscoveredDevice device) onDevice,
  }) async {
    await stopScan();
    _isScanning = true;
    final Completer<void> scanDone = Completer<void>();
    _activeScanSub = ble
        .scanForDevices(withServices: withServices, scanMode: ScanMode.lowLatency)
        .listen(
          onDevice,
          onError: (Object e) {
            debugPrint('------>>>memopin MPBlePlatform.runScan error: $e');
          },
          onDone: () {
            if (!scanDone.isCompleted) {
              scanDone.complete();
            }
          },
          cancelOnError: false,
        );
    try {
      await Future.any<void>(<Future<void>>[
        Future<void>.delayed(duration),
        scanDone.future,
      ]);
    } finally {
      await stopScan();
    }
  }

  /// 扫描直到 [matches] 命中或 [duration] 到期。
  ///
  /// 用于冷启动自动重连：一旦发现历史设备便立即停止扫描并返回该广播，
  /// 避免先收集完整列表再发起连接。
  Future<DiscoveredDevice?> runScanUntil({
    required Duration duration,
    List<Uuid> withServices = const <Uuid>[],
    required bool Function(DiscoveredDevice device) matches,
  }) async {
    await stopScan();
    _isScanning = true;
    final Completer<DiscoveredDevice?> result = Completer<DiscoveredDevice?>();
    _activeScanSub = ble
        .scanForDevices(withServices: withServices, scanMode: ScanMode.lowLatency)
        .listen(
          (DiscoveredDevice device) {
            if (!result.isCompleted && matches(device)) {
              result.complete(device);
            }
          },
          onError: (Object e) {
            debugPrint('------>>>memopin MPBlePlatform.runScanUntil error: $e');
            if (!result.isCompleted) {
              result.complete(null);
            }
          },
          onDone: () {
            if (!result.isCompleted) {
              result.complete(null);
            }
          },
          cancelOnError: false,
        );
    try {
      return await result.future.timeout(duration, onTimeout: () => null);
    } finally {
      await stopScan();
    }
  }
}
