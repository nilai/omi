import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../common/mp_home_notification.dart';
import 'ble_transport.dart';
import 'mp_ble_scan_uuids.dart';
import 'mp_note_ble_protocol.dart';

/// 订阅 `e2c1a303` / 轮询 `e2c1a310`，在录音中/空闲变化时 [MPHomeNotification.notifyBleMemopinRecordingStateChanged]。
class MPBleMemopinRecordingStateWatcher {
  BleTransport? _transport;
  StreamSubscription<List<int>>? _responseSub;
  StreamSubscription<List<int>>? _statusSub;
  Timer? _pollTimer;

  MPBleMemopinRecordingStateChangedPayload _lastEmitted = const MPBleMemopinRecordingStateChangedPayload(
    isRecording: false,
  );

  int? _lastSessionModeByte;

  /// 最近一次已对外通知的快照（默认未录音）。
  MPBleMemopinRecordingStateChangedPayload get lastEmitted => _lastEmitted;

  /// 主动读取 `e2c1a310`（与 `ble/note_ble_transport.dart` 中 `queryRecordStatus` / `readCharacteristic` 语义对齐）。
  ///
  /// 使用与扫描层一致的 `aiNoteService` 字符串，避免 `Uuid.toString()` 与 `flutter_blue_plus` 的 `str128`
  /// 在边界情况下不一致导致 [BleTransport.readCharacteristic] 找不到特征、返回空包。
  /// 载荷格式：`[Status 1B][FileNameLen 1B][FileName 变长]`；不足 2 字节视为未就绪，按未录音处理。
  static Future<MPBleMemopinRecordStatus310> readStatus310(BleTransport transport) async {
    const String serviceUuid = MPBleScanFilterUuids.aiNoteService;
    final String characteristicUuid = MPNoteBleUUIDs.recordStatus.toString();
    List<int> data = const <int>[];
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        data = await transport.readCharacteristic(serviceUuid, characteristicUuid);
      } catch (e, st) {
        debugPrint('------>>>memopin readStatus310: read failed attempt=${attempt + 1} $e\n$st');
        data = const <int>[];
      }
      if (data.isNotEmpty) {
        break;
      }
      if (attempt < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
    }
    if (data.isEmpty) {
      debugPrint('------>>>memopin readStatus310: empty after retries deviceId=${transport.deviceId}');
    }
    final MPBleMemopinRecordStatus310 out = _parseRecordStatus310ReadPayload(data);
    debugPrint(
      '------>>>memopin readStatus310: result deviceId=${transport.deviceId} isRecording=${out.isRecording} '
      'file=${out.activeFileName} rawLen=${data.length}',
    );
    return out;
  }

  /// 解析 `e2c1a310` 读回载荷（与参考实现 [queryRecordStatus] 一致：`>=2` 才取状态字节）。
  static MPBleMemopinRecordStatus310 _parseRecordStatus310ReadPayload(List<int> data) {
    if (data.length < 2) {
      debugPrint('------>>>memopin _parseRecordStatus310ReadPayload: short payload len=${data.length} → idle');
      return const MPBleMemopinRecordStatus310(isRecording: false);
    }
    final int status = data[0] & 0xff;
    final int nameLen = data[1] & 0xff;
    final bool recording = status == 0x01;
    if (nameLen <= 0 || data.length < 2 + nameLen) {
      return MPBleMemopinRecordStatus310(isRecording: recording);
    }
    final List<int> nameBytes = data.sublist(2, 2 + nameLen);
    String? fileName;
    try {
      fileName = utf8.decode(nameBytes);
    } catch (_) {
      fileName = String.fromCharCodes(nameBytes);
    }
    if (fileName.isEmpty) {
      fileName = null;
    }
    return MPBleMemopinRecordStatus310(isRecording: recording, activeFileName: fileName);
  }

  /// 绑定传输层并开始监听；`transport == null` 等价于 [detach]。
  Future<void> attach(BleTransport? transport) async {
    debugPrint(
      '------>>>memopin recording watcher attach: ${transport == null ? "detach" : "deviceId=${transport.deviceId}"}',
    );
    await detach();
    _transport = transport;
    if (transport == null) {
      return;
    }
    await _start(transport);
  }

  /// 取消订阅与轮询。
  Future<void> detach() async {
    debugPrint('------>>>memopin recording watcher detach');
    await _responseSub?.cancel();
    _responseSub = null;
    await _statusSub?.cancel();
    _statusSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _transport = null;
  }

  Future<void> _start(BleTransport transport) async {
    debugPrint('------>>>memopin recording watcher _start: deviceId=${transport.deviceId}');
    try {
      if (!await transport.isConnected()) {
        debugPrint('------>>>memopin recording watcher _start: not connected, abort');
        return;
      }
    } catch (_) {
      debugPrint('------>>>memopin recording watcher _start: isConnected check failed, abort');
      return;
    }

    await _apply310Snapshot(await readStatus310(transport), forceEmit: true);
    debugPrint('------>>>memopin recording watcher _start: initial 310 snapshot applied, subs starting');

    _responseSub = transport
        .getCharacteristicStream(MPNoteBleUUIDs.service.toString(), MPNoteBleUUIDs.response.toString())
        .listen(_onResponsePacket, onError: (Object e) => debugPrint('------>>>memopin recording watcher response stream: $e'));

    try {
      _statusSub = transport
          .getCharacteristicStream(MPNoteBleUUIDs.service.toString(), MPNoteBleUUIDs.recordStatus.toString())
          .listen(_onRecordStatusNotify, onError: (_) {});
    } catch (e) {
      debugPrint('------>>>memopin recording watcher _start: recordStatus notify setup failed: $e');
    }

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_poll310());
    });
  }

  void _onRecordStatusNotify(List<int> raw) {
    final MPBleMemopinRecordStatus310 st = MPBleMemopinRecordStatus310.parse(raw);
    debugPrint(
      '------>>>memopin recording watcher notify310 len=${raw.length} parsed recording=${st.isRecording}',
    );
    unawaited(_apply310Snapshot(st));
  }

  void _onResponsePacket(List<int> p) {
    if (p.isEmpty) {
      return;
    }
    if (p.length >= 5 && p[0] == MPNoteBleCommands.startRecording && p[1] == 0x01) {
      debugPrint('------>>>memopin recording watcher 303: startRecording ok mode=${p[3] & 0xff}');
      _lastSessionModeByte = p[3] & 0xff;
      try {
        final String name = utf8.decode(p.sublist(4));
        _emitIfChanged(
          MPBleMemopinRecordingStateChangedPayload(
            isRecording: true,
            activeFileName: name.isEmpty ? null : name,
            sessionModeByte: _lastSessionModeByte,
          ),
        );
      } catch (_) {
        _emitIfChanged(
          MPBleMemopinRecordingStateChangedPayload(
            isRecording: true,
            sessionModeByte: _lastSessionModeByte,
          ),
        );
      }
      return;
    }
    if (p.length >= 5 && p[0] == MPNoteBleCommands.stopRecording && p[2] == 0x01) {
      debugPrint('------>>>memopin recording watcher 303: stopRecording ok');
      try {
        final String name = utf8.decode(p.sublist(4));
        _emitIfChanged(
          MPBleMemopinRecordingStateChangedPayload(
            isRecording: false,
            activeFileName: name.isEmpty ? null : name,
            sessionModeByte: _lastSessionModeByte,
          ),
        );
      } catch (_) {
        _emitIfChanged(
          MPBleMemopinRecordingStateChangedPayload(
            isRecording: false,
            sessionModeByte: _lastSessionModeByte,
          ),
        );
      }
    }
  }

  Future<void> _poll310() async {
    final BleTransport? t = _transport;
    if (t == null) {
      return;
    }
    try {
      if (!await t.isConnected()) {
        return;
      }
    } catch (_) {
      return;
    }
    try {
      await _apply310Snapshot(await readStatus310(t));
    } catch (e) {
      debugPrint('------>>>memopin recording watcher _poll310 error: $e');
    }
  }

  Future<void> _apply310Snapshot(MPBleMemopinRecordStatus310 st, {bool forceEmit = false}) async {
    _emitIfChanged(
      MPBleMemopinRecordingStateChangedPayload(
        isRecording: st.isRecording,
        activeFileName: st.activeFileName,
        sessionModeByte: _lastSessionModeByte,
      ),
      forceEmit: forceEmit,
    );
  }

  void _emitIfChanged(MPBleMemopinRecordingStateChangedPayload next, {bool forceEmit = false}) {
    if (!forceEmit &&
        next.isRecording == _lastEmitted.isRecording &&
        next.activeFileName == _lastEmitted.activeFileName &&
        next.sessionModeByte == _lastEmitted.sessionModeByte) {
      return;
    }
    debugPrint(
      '------>>>memopin recording state emit: recording=${next.isRecording} file=${next.activeFileName} '
      'mode=${next.sessionModeByte} force=$forceEmit',
    );
    _lastEmitted = next;
    MPHomeNotification.notifyBleMemopinRecordingStateChanged(next);
  }
}
