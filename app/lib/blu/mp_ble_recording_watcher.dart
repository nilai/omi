import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../common/mp_home_notification.dart';
import 'ble_transport.dart';
import 'mp_ble_file_util.dart';
import 'mp_note_ble_protocol.dart';

/// 将 `e2c1a301` 无 Flag 的 `[Seq 4B BE][480B]` 流切成 480B 裸 Opus 帧（与 [MPBleFileUtil] 内实时缓冲一致）。
class _WatcherRtOpus301Buffer {
  final List<int> _buf = <int>[];

  /// [onFrame480] 每次收到完整 480B 帧时调用。
  void feed(List<int> data, void Function(List<int> frame480) onFrame480) {
    _buf.addAll(data);
    while (_buf.length >= 484) {
      onFrame480(List<int>.from(_buf.sublist(4, 484)));
      _buf.removeRange(0, 484);
    }
  }
}

/// 订阅 **response `e2c1a303`** 与 **audioData `e2c1a301`**，按 `ble/doc/ble-api-documentation.md` 解析 **Cmd / Op / Result**，
/// 在「开始录音成功」「结束录音成功」时更新 [lastEmitted] 并 [MPHomeNotification.notifyBleMemopinRecordingStateChanged]。
///
/// **实时音频落盘**（对齐 `note-debug-realtime-audio-reception.md` 与 `ble/note_ble_debug_provider.dart` 的 `startSavingAudio`）：
/// 在 303 确认 **开始录音成功** 后打开 `ensureMemoPinDeviceAudioDirectoryPath` 下 `.opus` 写句柄；301 重组帧写入；
/// **停止录音成功** 后 `flush`/`close`。节流日志逻辑同 `startSavingAudio` 内对 `data` 的处理（前 10 包 + 每 10 秒）。
///
/// **与 APP 下发指令的区别**：`0x01` / `0x02` 作为 **command** 写帧首字节表示「发起开始/停止」；
/// 303 上同数值出现在 **Cmd** 列；第二字节为 **Op**。
///
/// 订阅顺序与 [BleTransport.getCharacteristicStreamWhenReady] 一致：先 await GATT notify 就绪再 `listen`，
/// 并统一 `cancelOnError: false` 与 `onDone` 日志。
class MPBleRecordingWatcher {
  StreamSubscription<List<int>>? _responseSub;
  StreamSubscription<List<int>>? _audioSub;

  final _WatcherRtOpus301Buffer _audio301Buffer = _WatcherRtOpus301Buffer();

  IOSink? _audioDebugSink;
  String? _audioDebugPath;
  int _audioPacketsReceived = 0;
  int _audioBytesSaved = 0;
  DateTime? _lastAudioLogTime;

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
    await _closeAudioDebugSink();
  }

  Future<void> _cancelSubscriptions() async {
    final StreamSubscription<List<int>>? r = _responseSub;
    final StreamSubscription<List<int>>? a = _audioSub;
    _responseSub = null;
    _audioSub = null;
    await Future.wait<void>(<Future<void>>[
      if (r != null) r.cancel(),
      if (a != null) a.cancel(),
    ]);
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

      final Stream<List<int>> audioStream = await transport.getCharacteristicStreamWhenReady(
        MPNoteBleUUIDs.service.toString(),
        MPNoteBleUUIDs.audioData.toString(),
      );
      _audioSub = audioStream.listen(
        _onAudio301Raw,
        onError: (Object e, StackTrace st) =>
            debugPrint('------>>>memopin recording watcher 301 audio stream: $e\n$st'),
        onDone: () => debugPrint('------>>>memopin recording watcher 301 audio stream: onDone'),
        cancelOnError: false,
      );
    } catch (e, st) {
      debugPrint('------>>>memopin recording watcher _start: subscribe failed: $e\n$st');
      await _cancelSubscriptions();
    }
  }

  void _onAudio301Raw(List<int> raw) {
    _audio301Buffer.feed(raw, _appendAudioDebugLikeStartSavingAudio661674);
  }

  /// 与 `note_ble_debug_provider.dart` `startSavingAudio` 监听体内（661–674）一致：计数、落盘、前 10 包 + 每 10 秒日志。
  void _appendAudioDebugLikeStartSavingAudio661674(List<int> data) {
    final IOSink? sink = _audioDebugSink;
    if (sink == null) {
      return;
    }
    _audioPacketsReceived++;
    _audioBytesSaved += data.length;
    sink.add(data);

    final DateTime now = DateTime.now();
    final bool shouldLog = _audioPacketsReceived <= 10 ||
        _lastAudioLogTime == null ||
        now.difference(_lastAudioLogTime!).inSeconds >= 10;
    if (shouldLog) {
      debugPrint(
        '[MemopinAudioWatcher] 保存包#$_audioPacketsReceived: ${data.length}bytes, 总计=$_audioBytesSaved bytes '
        'path=$_audioDebugPath',
      );
      _lastAudioLogTime = now;
    }
  }

  Future<void> _ensureAudioDebugSinkOpen() async {
    if (_audioDebugSink != null) {
      return;
    }
    try {
      final String dir = await MPBleFileUtil.ensureMemoPinDeviceAudioDirectoryPath();
      final String ts = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      _audioDebugPath = p.join(dir, 'mp_recording_watcher_rt_$ts.opus');
      _audioDebugSink = File(_audioDebugPath!).openWrite();
      _audioPacketsReceived = 0;
      _audioBytesSaved = 0;
      _lastAudioLogTime = null;
      debugPrint('------>>>memopin recording watcher: audio debug save → $_audioDebugPath');
    } catch (e) {
      debugPrint('------>>>memopin recording watcher: audio sink open failed: $e');
    }
  }

  Future<void> _closeAudioDebugSink() async {
    try {
      await _audioDebugSink?.flush();
      await _audioDebugSink?.close();
    } catch (_) {
      // ignore
    }
    _audioDebugSink = null;
    _audioDebugPath = null;
  }

  /// 处理 303 notify：识别 **开始录音成功** / **结束录音成功**；开始成功时打开实时 Opus 落盘，停止成功时关闭。
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
      unawaited(_ensureAudioDebugSinkOpen());
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
      unawaited(_closeAudioDebugSink());
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
