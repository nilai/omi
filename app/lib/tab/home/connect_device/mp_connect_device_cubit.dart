import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// 连接页设备模型（mock 数据）
class MPConnectDeviceItem {
  const MPConnectDeviceItem({
    required this.id,
    required this.name,
    required this.batteryPercent,
    required this.signalPercent,
    this.isConnected = false,
  });

  final String id;
  final String name;
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
  const MPConnectDeviceState({
    required this.isScanning,
    this.devices = const <MPConnectDeviceItem>[],
  });

  final bool isScanning;
  final List<MPConnectDeviceItem> devices;

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
  }) {
    return MPConnectDeviceState(
      isScanning: isScanning ?? this.isScanning,
      devices: devices ?? this.devices,
    );
  }
}

/// 连接页 Cubit：模拟扫描、连接和断开
class MPConnectDeviceCubit extends Cubit<MPConnectDeviceState> {
  MPConnectDeviceCubit()
      : super(
          MPConnectDeviceState(
            isScanning: true,
            devices: _mockDevices,
          ),
        ) {
    _scheduleScanStop();
  }

  static const Duration _scanDuration = Duration(seconds: 2);

  Timer? _scanTimer;

  /// 首次进入时调用
  void initData() {
    startScan();
  }

  /// 扫描设备，结束后进入结果态
  void startScan() {
    _scanTimer?.cancel();
    emit(state.copyWith(isScanning: true));
    _scheduleScanStop();
  }

  /// 切换设备连接状态
  void toggleConnection(String id) {
    final bool willConnect = !state.devices.any(
      (MPConnectDeviceItem item) => item.id == id && item.isConnected,
    );
    final List<MPConnectDeviceItem> next = state.devices
        .map(
          (MPConnectDeviceItem item) => item.copyWith(
            isConnected: willConnect ? item.id == id : false,
          ),
        )
        .toList();
    emit(state.copyWith(devices: next));
  }

  void _scheduleScanStop() {
    _scanTimer = Timer(_scanDuration, () {
      emit(state.copyWith(isScanning: false));
    });
  }

  @override
  Future<void> close() {
    _scanTimer?.cancel();
    return super.close();
  }
}

const List<MPConnectDeviceItem> _mockDevices = <MPConnectDeviceItem>[
  MPConnectDeviceItem(
    id: '4A2B',
    name: 'MemoPin #4A2B',
    batteryPercent: 80,
    signalPercent: 80,
  ),
  MPConnectDeviceItem(
    id: '7F8C',
    name: 'MemoPin #7F8C',
    batteryPercent: 40,
    signalPercent: 40,
  ),
  MPConnectDeviceItem(
    id: '1D9E',
    name: 'MemoPin #1D9E',
    batteryPercent: 10,
    signalPercent: 10,
  ),
];
