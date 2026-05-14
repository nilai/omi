import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:omi/backend/schema/bt_device/bt_device.dart';
import 'package:omi/services/devices/models.dart';
import 'package:omi/utils/bluetooth/bluetooth_adapter.dart';

import 'device_discoverer.dart';

class BluetoothDeviceDiscoverer extends DeviceDiscoverer {
  @override
  String get name => 'Bluetooth';

  @override
  bool get isSupported => true;

  @override
  Future<DeviceDiscoveryResult> discover({int timeout = 5}) async {
    if (!(await BluetoothAdapter.isSupported)) {
      debugPrint('Bluetooth not supported, skipping discovery');
      return const DeviceDiscoveryResult(devices: []);
    }

    final List<ScanResult> bleResults = [];
    late final StreamSubscription sub;

    sub = BluetoothAdapter.scanResults.listen((results) {
      final list = results.cast<ScanResult>().where((r) => r.device.platformName.isNotEmpty).toList();

      // Debug: 打印所有扫描到的设备
      for (final r in list) {
        debugPrint('[BluetoothDiscoverer] 扫描到: name="${r.device.platformName}", '
            'mac=${r.device.remoteId}, rssi=${r.rssi}, '
            'serviceUuids=${r.advertisementData.serviceUuids.map((u) => u.toString()).toList()}');
      }

      bleResults
        ..clear()
        ..addAll(list);
    }, onError: (e) {
      debugPrint('BLE discovery error: $e');
    });

    try {
      await BluetoothAdapter.adapterState.where((v) => v == BluetoothAdapterStateHelper.on).first;

      debugPrint('[BluetoothDiscoverer] ════════════════════════════════════════');
      debugPrint('[BluetoothDiscoverer] 开始扫描 BLE 设备');
      debugPrint('[BluetoothDiscoverer] Note Service UUID: $aiNoteServiceUuid');
      debugPrint('[BluetoothDiscoverer] 扫描超时: ${timeout}秒');
      debugPrint('[BluetoothDiscoverer] ════════════════════════════════════════');

      // 第一次扫描：使用 Service UUID 过滤（更精准）
      final serviceUuids = [
        BluetoothAdapter.createGuid(aiNoteServiceUuid),
        BluetoothAdapter.createGuid(omiServiceUuid),
        BluetoothAdapter.createGuid(friendPendantServiceUuid),
      ];

      debugPrint('[BluetoothDiscoverer] 第1次扫描: 使用 UUID 过滤');
      await BluetoothAdapter.startScan(
        timeout: Duration(seconds: timeout),
        withServices: serviceUuids,
      );
      await Future.delayed(Duration(seconds: timeout));

      List<BtDevice> devices = bleResults
          .where((r) => BtDevice.isSupportedDevice(r))
          .sorted((a, b) => b.rssi.compareTo(a.rssi))
          .map<BtDevice>((r) => BtDevice.fromScanResult(r))
          .toList();

      debugPrint('[BluetoothDiscoverer] 第1次扫描结果: ${devices.length} 个设备');

      // 如果没找到设备，进行第二次扫描（不过滤 UUID）
      if (devices.isEmpty) {
        debugPrint('[BluetoothDiscoverer] 第2次扫描: 无 UUID 过滤（设备可能不广播 Service UUID）');
        bleResults.clear();

        await BluetoothAdapter.startScan(
          timeout: Duration(seconds: timeout),
          // 不传 withServices，扫描所有设备
        );
        await Future.delayed(Duration(seconds: timeout));

        devices = bleResults
            .where((r) => BtDevice.isSupportedDevice(r))
            .sorted((a, b) => b.rssi.compareTo(a.rssi))
            .map<BtDevice>((r) => BtDevice.fromScanResult(r))
            .toList();

        debugPrint('[BluetoothDiscoverer] 第2次扫描结果: ${devices.length} 个设备');
      }

      debugPrint('[BluetoothDiscoverer] 扫描完成，共发现 ${devices.length} 个支持的设备');

      return DeviceDiscoveryResult(
        devices: devices,
        metadata: {
          'bleResults': bleResults,
        },
      );
    } finally {
      await sub.cancel();
    }
  }

  @override
  Future<void> stop() async {
    if (BluetoothAdapter.isScanningNow) {
      await BluetoothAdapter.stopScan();
    }
  }
}
