import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// 适配器「已开启」状态简写，与历史代码中的 [BluetoothAdapterStateHelper.on] 用法对齐。
class BluetoothAdapterStateHelper {
  BluetoothAdapterStateHelper._();

  /// 系统蓝牙已打开。
  static BluetoothAdapterState get on => BluetoothAdapterState.on;
}

/// 对 [FlutterBluePlus] 的薄封装：统一扫描、适配器状态与开关入口。
///
/// 供 [BleTransport]、[BluetoothDeviceDiscoverer] 及 [MPBleConnectionHelper] 复用。
class BluetoothAdapter {
  BluetoothAdapter._();

  /// 当前设备是否支持 BLE。
  static Future<bool> get isSupported => FlutterBluePlus.isSupported;

  /// 适配器状态流（未开、开启中等）。
  static Stream<BluetoothAdapterState> get adapterState => FlutterBluePlus.adapterState;

  /// 扫描结果流（列表为当前聚合结果）。
  static Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  /// 是否正在扫描。
  static bool get isScanningNow => FlutterBluePlus.isScanningNow;

  /// 发起扫描；[timeout] 到达后由插件自动 [stopScan]。
  static Future<void> startScan({
    Duration? timeout,
    List<Guid> withServices = const [],
    List<String> withNames = const [],
    List<String> withKeywords = const [],
    bool continuousUpdates = false,
  }) {
    return FlutterBluePlus.startScan(
      timeout: timeout,
      withServices: withServices,
      withNames: withNames,
      withKeywords: withKeywords,
      continuousUpdates: continuousUpdates,
    );
  }

  /// 停止扫描。
  static Future<void> stopScan() => FlutterBluePlus.stopScan();

  /// 请求打开系统蓝牙（若平台支持）。
  static Future<void> turnOn() => FlutterBluePlus.turnOn();
}
