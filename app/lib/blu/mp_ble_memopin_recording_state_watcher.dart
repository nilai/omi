import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../common/mp_home_notification.dart';
import 'ble_transport.dart';
import 'mp_note_ble_protocol.dart';

/// 订阅 `e2c1a303` 与 `e2c1a310` 通知，在录音中/空闲变化时 [MPHomeNotification.notifyBleMemopinRecordingStateChanged]。
class MPBleMemopinRecordingStateWatcher {
  StreamSubscription<List<int>>? _responseSub;
  StreamSubscription<List<int>>? _statusSub;

  MPBleMemopinRecordingStateChangedPayload _lastEmitted = const MPBleMemopinRecordingStateChangedPayload(
    isRecording: false,
  );

  int? _lastSessionModeByte;

  /// 最近一次已对外通知的快照（默认未录音）。
  MPBleMemopinRecordingStateChangedPayload get lastEmitted => _lastEmitted;

  /// 绑定传输层并开始监听；`transport == null` 等价于 [detach]。
  Future<void> attach(BleTransport? transport) async {
    debugPrint(
      '------>>>memopin recording watcher attach: ${transport == null ? "detach" : "deviceId=${transport.deviceId}"}',
    );
    await detach();
    if (transport == null) {
      return;
    }
    await _start(transport);
  }

  /// 取消订阅。
  Future<void> detach() async {
    debugPrint('------>>>memopin recording watcher detach');
    await _responseSub?.cancel();
    _responseSub = null;
    await _statusSub?.cancel();
    _statusSub = null;
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

    debugPrint('------>>>memopin recording watcher _start: subs starting (no initial 310 read)');

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
