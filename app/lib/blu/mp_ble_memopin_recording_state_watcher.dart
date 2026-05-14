import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../common/mp_home_notification.dart';
import 'ble_transport.dart';
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

  /// 主动读取 `e2c1a310`。
  static Future<MPBleMemopinRecordStatus310> readStatus310(BleTransport transport) async {
    final List<int> raw = await transport.readCharacteristic(
      MPNoteBleUUIDs.service.toString(),
      MPNoteBleUUIDs.recordStatus.toString(),
    );
    return MPBleMemopinRecordStatus310.parse(raw);
  }

  /// 绑定传输层并开始监听；`transport == null` 等价于 [detach]。
  Future<void> attach(BleTransport? transport) async {
    await detach();
    _transport = transport;
    if (transport == null) {
      return;
    }
    await _start(transport);
  }

  /// 取消订阅与轮询。
  Future<void> detach() async {
    await _responseSub?.cancel();
    _responseSub = null;
    await _statusSub?.cancel();
    _statusSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _transport = null;
  }

  Future<void> _start(BleTransport transport) async {
    try {
      if (!await transport.isConnected()) {
        return;
      }
    } catch (_) {
      return;
    }

    await _apply310Snapshot(await readStatus310(transport), forceEmit: true);

    _responseSub = transport
        .getCharacteristicStream(MPNoteBleUUIDs.service.toString(), MPNoteBleUUIDs.response.toString())
        .listen(_onResponsePacket, onError: (Object e) => debugPrint('MPBleMemopinRecordingStateWatcher response: $e'));

    try {
      _statusSub = transport
          .getCharacteristicStream(MPNoteBleUUIDs.service.toString(), MPNoteBleUUIDs.recordStatus.toString())
          .listen(_onRecordStatusNotify, onError: (_) {});
    } catch (e) {
      debugPrint('MPBleMemopinRecordingStateWatcher: recordStatus notify unavailable: $e');
    }

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_poll310());
    });
  }

  void _onRecordStatusNotify(List<int> raw) {
    final MPBleMemopinRecordStatus310 st = MPBleMemopinRecordStatus310.parse(raw);
    unawaited(_apply310Snapshot(st));
  }

  void _onResponsePacket(List<int> p) {
    if (p.isEmpty) {
      return;
    }
    if (p.length >= 5 && p[0] == MPNoteBleCommands.startRecording && p[1] == 0x01) {
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
      debugPrint('MPBleMemopinRecordingStateWatcher._poll310: $e');
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
    _lastEmitted = next;
    MPHomeNotification.notifyBleMemopinRecordingStateChanged(next);
  }
}
