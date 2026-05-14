// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../common/mp_home_notification.dart';
import 'ble_transport.dart';
import 'mp_ble_file_util.dart';
import 'mp_note_ble_protocol.dart';

/// 订阅 **response `e2c1a303`** 与 **audioData `e2c1a301`**（经 [BleTransport] 与 [NoteBleTransport] 对齐的管线），
/// 按 `ble/doc/ble-api-documentation.md` 解析 **Cmd / Op / Result**，
/// 在「开始录音成功」「结束录音成功」时更新 [lastEmitted] 并 [MPHomeNotification.notifyBleMemopinRecordingStateChanged]。
///
/// **实时音频落盘**（与 `note-debug-realtime-audio-reception.md` / [NoteBleTransport.audioStream] →
/// `note_ble_debug_provider.dart` [NoteBleDebugProvider.startSavingAudio] 等价）：
/// - [BleTransport.getCharacteristicStreamWhenReady] 对 `e2c1a301` 返回 **已重组** 的 480B Opus 帧（等同 `audioStream`）；
/// - 在 303 **开始录音成功** 后打开 [MPBleFileUtil.ensureMemoPinDeviceAudioDirectoryPath] 下 `.opus` 写句柄，
///   对重组帧执行与 `startSavingAudio` 中 `listen` 回调相同的计数、`IOSink.add`、前 10 包 + 每 10 秒 `print`、`cancelOnError: false`；
/// - **停止录音成功** 后 `flush`/`close`；`onError`/`onDone` 文案风格与 Debug Provider 一致。
///
/// 订阅顺序与 [BleTransport.getCharacteristicStreamWhenReady] 一致。
class MPBleRecordingWatcher {
  StreamSubscription<List<int>>? _responseSub;
  StreamSubscription<List<int>>? _audioSub;

  /// 当前 [_start] 绑定的传输，供 303 回调中调用 [BleTransport.resetRealtimeAudioReassembly]。
  BleTransport? _boundTransport;

  IOSink? _audioFileSink;
  String? _savedAudioPath;
  int _audioPacketsReceived = 0;
  int _audioBytesSaved = 0;
  DateTime? _lastLogTime;

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
    await _closeAudioSavingSink();
    _boundTransport = null;
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

      print('[MemopinAudioWatcher] 开始订阅 301 → 重组帧流（等同 BleTransport.audioStream）...');
      _audioSub = audioStream.listen(
        _onMemopinAudioStreamDataLikeStartSavingAudio,
        onError: (Object error, StackTrace stackTrace) {
          print('[MemopinAudioWatcher] ❌ 音频流错误: $error');
          print('[MemopinAudioWatcher] ❌ 堆栈: $stackTrace');
          print('[MemopinAudioWatcher] ❌ 已收到 $_audioPacketsReceived 包后出错');
        },
        onDone: () {
          print(
            '[MemopinAudioWatcher] ⚠️ 音频流结束(onDone)! 共收到 $_audioPacketsReceived 包, $_audioBytesSaved bytes',
          );
          print('[MemopinAudioWatcher] ⚠️ 这可能表示: 1)设备停止发送 2)BLE订阅被取消 3)设备断开连接');
        },
        cancelOnError: false,
      );
      print('[MemopinAudioWatcher] ✓ 音频流订阅已建立（重组后与 audioStream 对齐）');
      _boundTransport = transport;
    } catch (e, st) {
      debugPrint('------>>>memopin recording watcher _start: subscribe failed: $e\n$st');
      _boundTransport = null;
      await _cancelSubscriptions();
    }
  }

  /// 与 `note_ble_debug_provider.dart` `startSavingAudio` 中 `audioStream.listen((data) { … })`（661–674）一致。
  void _onMemopinAudioStreamDataLikeStartSavingAudio(List<int> data) {
    _audioPacketsReceived++;
    _audioBytesSaved += data.length;
    _audioFileSink?.add(data);

    final DateTime now = DateTime.now();
    final bool shouldLog = _audioPacketsReceived <= 10 ||
        _lastLogTime == null ||
        now.difference(_lastLogTime!).inSeconds >= 10;
    if (shouldLog) {
      print('[MemopinAudioWatcher] 保存包#$_audioPacketsReceived: ${data.length}bytes, 总计=$_audioBytesSaved bytes');
      _lastLogTime = now;
    }
  }

  Future<void> _ensureAudioSavingSinkOpen() async {
    if (_audioFileSink != null) {
      return;
    }
    try {
      final String dir = await MPBleFileUtil.ensureMemoPinDeviceAudioDirectoryPath();
      final String ts = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      _savedAudioPath = p.join(dir, 'mp_recording_watcher_rt_$ts.opus');
      _audioFileSink = File(_savedAudioPath!).openWrite();
      _audioPacketsReceived = 0;
      _audioBytesSaved = 0;
      _lastLogTime = null;
      print('[MemopinAudioWatcher] 开始保存音频到: $_savedAudioPath');
    } catch (e) {
      debugPrint('------>>>memopin recording watcher: audio sink open failed: $e');
    }
  }

  Future<void> _closeAudioSavingSink() async {
    try {
      await _audioFileSink?.flush();
      await _audioFileSink?.close();
    } catch (_) {
      // ignore
    }
    _audioFileSink = null;
    _savedAudioPath = null;
  }

  /// 处理 303 notify：识别 **开始录音成功** / **结束录音成功**；开始成功时打开落盘并重置重组器 Seq，停止成功时关闭。
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
      String? fileLabel;
      try {
        fileLabel = utf8.decode(p.sublist(4));
        _emitIfChanged(
          MPBleMemopinRecordingStateChangedPayload(
            isRecording: true,
            activeFileName: fileLabel.isEmpty ? null : fileLabel,
            sessionModeByte: _lastSessionModeByte,
          ),
        );
      } catch (_) {
        fileLabel = null;
        _emitIfChanged(
          MPBleMemopinRecordingStateChangedPayload(isRecording: true, sessionModeByte: _lastSessionModeByte),
        );
      }
      final String fn = (fileLabel != null && fileLabel.isNotEmpty) ? fileLabel : 'session.opus';
      _boundTransport?.resetRealtimeAudioReassembly(fileName: fn);
      unawaited(_ensureAudioSavingSinkOpen());
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
      print('[MemopinAudioWatcher] 停止保存音频');
      print('[MemopinAudioWatcher] 总计: $_audioPacketsReceived 包, $_audioBytesSaved bytes');
      print('[MemopinAudioWatcher] 文件: $_savedAudioPath');
      unawaited(_closeAudioSavingSink());
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
