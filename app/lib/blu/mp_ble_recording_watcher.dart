import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../common/mp_home_notification.dart';
import 'ble_transport.dart';
import 'mp_note_ble_protocol.dart';

/// 订阅 **response `e2c1a303`** notify，按 `ble/doc/ble-api-documentation.md` 解析 **Cmd / Op / Result**，
/// 在「开始录音成功」「结束录音成功」时更新 [lastEmitted] 并 [MPHomeNotification.notifyBleMemopinRecordingStateChanged]。
///
/// **与 APP 下发指令的区别**：`0x01` / `0x02` 作为 **command** 写帧首字节表示「发起开始/停止」；
/// 303 上同数值出现在 **Cmd** 列；第二字节为 **Op**（如开始成功时 `Op=0x01` 表示「开始录音」回显，**不是**把指令再回调一遍）。
///
/// 订阅顺序与 `lib/blu/note-debug-realtime-audio-reception.md` / [BleTransport.getCharacteristicStreamWhenReady]
/// 一致：先 await GATT notify 就绪再 `listen`，并统一 `cancelOnError: false` 与 `onDone` 日志。
class MPBleRecordingWatcher {
  StreamSubscription<List<int>>? _responseSub;

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
    await _cancelSubscriptions();
  }

  Future<void> _cancelSubscriptions() async {
    final StreamSubscription<List<int>>? r = _responseSub;
    _responseSub = null;
    await r?.cancel();
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

    debugPrint('------>>>memopin recording watcher _start: subs (notify-ready then listen)');

    try {
      final Stream<List<int>> responseStream = await transport.getCharacteristicStreamWhenReady(
        MPNoteBleUUIDs.service.toString(),
        MPNoteBleUUIDs.response.toString(),
      );
      _responseSub = responseStream.listen(
        _onResponsePacket,
        onError: (Object e, StackTrace st) =>
            debugPrint('------>>>memopin recording watcher 303 response stream: $e\n$st'),
        onDone: () => debugPrint('------>>>memopin recording watcher 303 response stream: onDone'),
        cancelOnError: false,
      );
    } catch (e, st) {
      debugPrint('------>>>memopin recording watcher _start: subscribe failed: $e\n$st');
      await _cancelSubscriptions();
    }
  }

  /// 处理 303 notify：识别 **开始录音成功** `[Cmd][Op][RecordState][Mode][File…]` 与 **结束录音成功**
  /// `[Cmd][Op][Result][FileId][File…]`（均见协议文档）。
  void _onResponsePacket(List<int> p) {
    if (p.isEmpty) {
      return;
    }
    if (p.length >= 5 &&
        p[0] == MPNoteBleRecordingWire.cmdRecordingStart &&
        p[1] == MPNoteBleRecordingWire.opStartRecordingAck) {
      debugPrint(
        '------>>>memopin recording watcher 303: start-ok Cmd/Op/State=${p[0]} ${p[1]} ${p[2]} mode=${p[3] & 0xff}',
      );
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
          MPBleMemopinRecordingStateChangedPayload(isRecording: true, sessionModeByte: _lastSessionModeByte),
        );
      }
      return;
    }
    if (p.length >= 5 &&
        p[0] == MPNoteBleRecordingWire.cmdRecordingStop &&
        p[1] == MPNoteBleRecordingWire.opEndRecording &&
        p[2] == MPNoteBleRecordingWire.resultSuccess) {
      debugPrint('------>>>memopin recording watcher 303: stop-ok Cmd/Op/Result=${p[0]} ${p[1]} ${p[2]}');
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
          MPBleMemopinRecordingStateChangedPayload(isRecording: false, sessionModeByte: _lastSessionModeByte),
        );
      }
    }
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
