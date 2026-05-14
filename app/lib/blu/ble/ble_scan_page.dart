import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:omi/backend/schema/bt_device/bt_device.dart';
import 'package:omi/pages/note_debug/note_ble_debug_page.dart';
import 'package:omi/providers/device_provider.dart';
import 'package:omi/services/devices.dart';
import 'package:omi/services/services.dart';
import 'package:provider/provider.dart';

/// Raw BLE scan page for debug builds.
/// Shows ALL nearby BLE devices without any filtering,
/// allowing manual connection to devices that don't advertise service UUIDs.
class BleScanPage extends StatefulWidget {
  const BleScanPage({super.key});

  @override
  State<BleScanPage> createState() => _BleScanPageState();
}

class _BleScanPageState extends State<BleScanPage> {
  final Map<String, ScanResult> _scanResults = {};
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool _isScanning = false;

  // Connection state
  bool _isConnecting = false;
  String? _connectingDeviceId;
  String _connectingDeviceName = '';
  String _connectionStatus = '';
  List<_ConnectionStep> _connectionSteps = [];

  @override
  void initState() {
    super.initState();
    debugPrint('[BLE_SCAN] initState() called, hashCode=$hashCode');
    _startScan();
  }

  @override
  void dispose() {
    debugPrint('[BLE_SCAN] dispose() called');
    _stopScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    debugPrint('[BLE_SCAN] _startScan called, _isScanning=$_isScanning, mounted=$mounted');
    if (_isScanning) {
      debugPrint('[BLE_SCAN] _startScan SKIPPED (already scanning)');
      return;
    }

    // Cancel any previous subscription before starting new scan
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    setState(() {
      _isScanning = true;
      _scanResults.clear();
      debugPrint('[BLE_SCAN] setState: cleared map, _isScanning=true');
    });

    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      debugPrint('[BLE_SCAN] onScanResults callback: ${results.length} items, map size before: ${_scanResults.length}');
      if (results.isEmpty) {
        debugPrint('[BLE_SCAN] onScanResults: EMPTY list received, skipping');
        return;
      }
      for (final r in results) {
        final name = r.device.platformName.isNotEmpty ? r.device.platformName : r.device.remoteId.str;
        debugPrint('[BLE_SCAN]   device: $name rssi=${r.rssi}');
        _scanResults[r.device.remoteId.str] = r;
      }
      debugPrint('[BLE_SCAN] map size after: ${_scanResults.length}, mounted=$mounted');
      if (mounted) {
        setState(() {
          debugPrint('[BLE_SCAN] setState from listener, map size=${_scanResults.length}');
        });
      }
    }, onError: (e) {
      debugPrint('[BLE_SCAN] onScanResults ERROR: $e');
    }, onDone: () {
      debugPrint('[BLE_SCAN] onScanResults stream DONE');
    });

    debugPrint('[BLE_SCAN] calling FlutterBluePlus.startScan...');
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    debugPrint('[BLE_SCAN] startScan completed (timeout reached)');

    if (mounted) {
      setState(() {
        _isScanning = false;
        debugPrint('[BLE_SCAN] setState: _isScanning=false, map size=${_scanResults.length}');
      });
    }
  }

  Future<void> _stopScan() async {
    debugPrint('[BLE_SCAN] _stopScan called, subscription=${_scanSubscription != null}');
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    if (FlutterBluePlus.isScanningNow) {
      debugPrint('[BLE_SCAN] stopping FlutterBluePlus scan...');
      await FlutterBluePlus.stopScan();
    }
    debugPrint('[BLE_SCAN] _stopScan done');
  }

  void _updateStep(int index, _StepState state, [String? detail]) {
    if (!mounted) return;
    setState(() {
      _connectionSteps[index] = _ConnectionStep(
        _connectionSteps[index].label,
        state,
        detail: detail,
      );
    });
  }

  Future<void> _connectToDevice(ScanResult result) async {
    if (_isConnecting) return;

    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : result.device.remoteId.str;

    setState(() {
      _isConnecting = true;
      _connectingDeviceId = result.device.remoteId.str;
      _connectingDeviceName = name;
      _connectionStatus = '正在连接...';
      _connectionSteps = [
        _ConnectionStep('停止扫描', _StepState.running),
        _ConnectionStep('创建连接', _StepState.pending),
        _ConnectionStep('发现服务', _StepState.pending),
        _ConnectionStep('订阅特征', _StepState.pending),
        _ConnectionStep('初始化设备', _StepState.pending),
      ];
    });

    await _stopScan();
    _updateStep(0, _StepState.done);

    try {
      // Step 1: Create BtDevice
      _updateStep(1, _StepState.running);
      _connectionStatus = '正在建立 GATT 连接...';
      setState(() {});

      final btDevice = BtDevice(
        name: result.device.platformName,
        id: result.device.remoteId.str,
        type: DeviceType.aiNote,
        rssi: result.rssi,
      );

      // Set device in DeviceProvider
      final deviceProvider = context.read<DeviceProvider>();
      deviceProvider.setConnectedDevice(btDevice);

      // Register device with DeviceService so ensureConnection can find it
      ServiceManager.instance().device.addDevice(btDevice);

      // Connect via ServiceManager
      final connection = await ServiceManager.instance().device.ensureConnection(
        btDevice.id,
        force: true,
      );

      _updateStep(1, _StepState.done);

      // Step 2: Service discovery
      _updateStep(2, _StepState.running);
      _connectionStatus = '正在发现 BLE 服务...';
      setState(() {});

      // Give a moment for service discovery (already happened in ensureConnection)
      await Future.delayed(const Duration(milliseconds: 500));
      _updateStep(2, _StepState.done);

      // Step 3: Subscribe characteristics
      _updateStep(3, _StepState.running);
      _connectionStatus = '正在订阅数据通道...';
      setState(() {});

      await Future.delayed(const Duration(milliseconds: 500));
      _updateStep(3, _StepState.done);

      // Step 4: Initialize
      _updateStep(4, _StepState.running);
      _connectionStatus = '正在初始化设备...';
      setState(() {});

      if (connection != null && (connection.status == DeviceConnectionState.connected || await connection.isConnected())) {
        deviceProvider.setIsConnected(true);
        _updateStep(4, _StepState.done);
        _connectionStatus = '连接成功!';
        setState(() {});

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const NoteBleDebugPage()),
          );
        }
      } else {
        throw Exception('连接未建立');
      }
    } catch (e) {
      debugPrint('Connection error: $e');
      if (mounted) {
        // Mark current running step as failed
        for (int i = 0; i < _connectionSteps.length; i++) {
          if (_connectionSteps[i].state == _StepState.running) {
            _updateStep(i, _StepState.failed, e.toString());
            break;
          }
        }
        _connectionStatus = '连接失败';
        setState(() {});

        // Show failure for 2 seconds, then return to scan
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _connectingDeviceId = null;
            _connectionSteps.clear();
          });
          _startScan();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedResults = _scanResults.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    debugPrint('[BLE_SCAN] build(): map=${_scanResults.length}, sorted=${sortedResults.length}, scanning=$_isScanning, connecting=$_isConnecting');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'BLE 设备扫描',
          style: TextStyle(color: Color(0xFF1D1D1F)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1D1D1F)),
        actions: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (!_isConnecting)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScan,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Device list
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFF5F5F5),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF666666)),
                    const SizedBox(width: 8),
                    Text(
                      '发现 ${sortedResults.length} 个设备${_isScanning ? '，扫描中...' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: sortedResults.isEmpty
                    ? Center(
                        child: _isScanning
                            ? const CircularProgressIndicator()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bluetooth_disabled,
                                      size: 48, color: Color(0xFFCCCCCC)),
                                  const SizedBox(height: 16),
                                  const Text('未发现设备',
                                      style: TextStyle(color: Color(0xFF666666))),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _startScan,
                                    child: const Text('重新扫描'),
                                  ),
                                ],
                              ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final result in sortedResults)
                              _buildDeviceItem(result),
                          ],
                        ),
                      ),
              ),
            ],
          ),

          // Connection overlay
          if (_isConnecting)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Device name
                      Row(
                        children: [
                          const Icon(Icons.bluetooth_connected,
                              color: Color(0xFF007AFF), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _connectingDeviceName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1D1D1F),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _connectingDeviceId ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Status text
                      Text(
                        _connectionStatus,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Step list
                      ..._connectionSteps.map((step) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                _buildStepIcon(step.state),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step.label,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: step.state == _StepState.pending
                                              ? const Color(0xFFBBBBBB)
                                              : const Color(0xFF333333),
                                        ),
                                      ),
                                      if (step.detail != null)
                                        Text(
                                          step.detail!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.red,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),

                      const SizedBox(height: 16),

                      // Cancel button (only when not failed/done)
                      if (_connectionSteps.every(
                          (s) => s.state != _StepState.failed))
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _isConnecting = false;
                                _connectingDeviceId = null;
                                _connectionSteps.clear();
                              });
                              _startScan();
                            },
                            child: const Text(
                              '取消',
                              style: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(ScanResult result) {
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : result.device.remoteId.str;
    final rssi = result.rssi;
    final rssiColor = rssi > -60
        ? const Color(0xFF34C759)
        : rssi > -80
            ? const Color(0xFFFF9500)
            : const Color(0xFFFF3B30);
    final serviceUuids = result.advertisementData.serviceUuids
        .map((e) => e.str.length > 8 ? '${e.str.substring(0, 8)}...' : e.str)
        .toList();

    return GestureDetector(
      onTap: _isConnecting ? null : () => _connectToDevice(result),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.bluetooth, color: rssiColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.device.remoteId}  RSSI: $rssi dBm',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  if (serviceUuids.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'UUIDs: ${serviceUuids.join(", ")}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIcon(_StepState state) {
    switch (state) {
      case _StepState.pending:
        return const SizedBox(
          width: 20,
          height: 20,
          child: Icon(Icons.circle_outlined, size: 16, color: Color(0xFFDDDDDD)),
        );
      case _StepState.running:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case _StepState.done:
        return const SizedBox(
          width: 20,
          height: 20,
          child: Icon(Icons.check_circle, size: 20, color: Color(0xFF34C759)),
        );
      case _StepState.failed:
        return const SizedBox(
          width: 20,
          height: 20,
          child: Icon(Icons.error, size: 20, color: Colors.red),
        );
    }
  }
}

enum _StepState { pending, running, done, failed }

class _ConnectionStep {
  final String label;
  final _StepState state;
  final String? detail;

  _ConnectionStep(this.label, this.state, {this.detail});
}
