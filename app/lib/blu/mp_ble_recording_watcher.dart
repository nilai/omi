// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../common/mp_home_notification.dart';
import 'mp_ble_transport.dart';
import 'mp_ble_file_util.dart';
import 'mp_device_transport.dart';
import 'mp_note_ble_protocol.dart';

/// 订阅 **response `e2c1a303`** 与 **audioData `e2c1a301`**（与 `ble/note_ble_debug_provider.dart` [NoteBleDebugProvider] 使用
/// `bleTransport.responseStream` / `bleTransport.audioStream` 的语义一致：先等待 GATT notify 就绪，再监听重组后的 301 帧流）。
///
/// 按 `ble/doc/ble-api-documentation.md` 解析 **Cmd / Op / Result**，
/// 在「开始录音成功」「结束录音成功」、BLE 断开、[detach] 时更新 [lastEmitted] 并
/// [MPHomeNotification.notifyBleMemopinRecordingStateChanged]。
///
/// **实时音频落盘**（与 [NoteBleTransport.audioStream] → [NoteBleDebugProvider.startSavingAudio] 等价）：
/// - [MPBleTransport.ensureGattSubscriptionsReady] 后订阅 [MPBleTransport.audioStream]（等同 `startSavingAudio` 内对 `audioStream` 的订阅）；
/// - 在 303 **开始录音成功** 后打开 [MPBleFileUtil.ensureMemoPinDeviceAudioDirectoryPath] 下 `.opus` 写句柄，
///   对重组帧执行与 `startSavingAudio` 中 `listen` 回调相同的计数、`IOSink.add`、前 10 包 + 每 10 秒 `print`、`cancelOnError: false`；
/// - **停止录音成功** 后 `flush`/`close`；`onError`/`onDone` 与 Debug Provider 相同 `[AudioDebug]` 文案。
///
/// **连接状态**：与 [NoteBleDebugProvider._setupConnectionStateListener] 一致，监听 [MPBleTransport.connectionStateStream]，
/// 在 [MPDeviceTransportState.disconnected] 时取消 301/303 订阅并关闭落盘句柄（不断开物理链路由上层决定）。
class MPBleRecordingWatcher {
  StreamSubscription<List<int>>? _responseSub;
  StreamSubscription<List<int>>? _audioSub;
  StreamSubscription<MPDeviceTransportState>? _connSub;

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

  /// 最近一次关闭实时落盘后的本地路径（停止 / 断连 / detach 后仍保留，直至下次开始录音）。
  String? _lastRealtimeAudioLocalPath;

  /// 最近一次已对外通知的快照（默认未录音）。
  MPBleMemopinRecordingStateChangedPayload get lastEmitted => _lastEmitted;

  /// 外接 MemoPin 是否正在录音（与 [lastEmitted.isRecording] 一致）。
  bool get isRecording => _lastEmitted.isRecording;

  /// 当前会话文件名（设备 303 上报；未录音时多为 `null`）。
  String? get activeFileName => _lastEmitted.activeFileName;

  /// 当前会话 mode：`0x00` memory / `0x01` memo。
  int? get sessionModeByte => _lastSessionModeByte;

  /// 已绑定传输的设备 ID；未 [attach] 时为 `null`。
  String? get boundDeviceId => _boundTransport?.deviceId;

  /// 是否已绑定传输并建立 301/303 订阅。
  bool get isWatcherAttached => _boundTransport != null;

  /// 最近一次实时落盘文件路径（见 [MPBleMemopinRecordingStateChangedPayload.lastRealtimeAudioLocalPath]）。
  String? get lastRealtimeAudioLocalPath => _lastRealtimeAudioLocalPath;

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
    final bool wasRecording = _lastEmitted.isRecording;
    await _connSub?.cancel();
    _connSub = null;
    await _cancelSubscriptions();
    await _closeAudioSavingSink();
    _boundTransport = null;
    if (wasRecording) {
      _emitRecordingStopped(
        changeReason: MPBleMemopinRecordingChangeReason.watcherDetached,
        keepActiveFileName: true,
      );
    }
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

  /// 与 [NoteBleDebugProvider] 在 `bleTransport.connectionStateStream` 收到 `disconnected` 时的清理语义对齐（本类不 dispose transport）。
  Future<void> _onBleDisconnectedByStream() async {
    debugPrint('------>>>memopin recording watcher: BLE disconnected → cancel 301/303 subs, close sink');
    final bool wasRecording = _lastEmitted.isRecording;
    await _connSub?.cancel();
    _connSub = null;
    await _cancelSubscriptions();
    await _closeAudioSavingSink();
    _boundTransport = null;
    if (wasRecording) {
      _emitRecordingStopped(
        changeReason: MPBleMemopinRecordingChangeReason.bleDisconnected,
        keepActiveFileName: true,
      );
    }
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

    debugPrint('------>>>memopin recording watcher _start: ensureGattSubscriptionsReady → response/audioStream');

    try {
      await transport.ensureGattSubscriptionsReady();

      _connSub = transport.connectionStateStream.listen(
        (MPDeviceTransportState s) {
          if (s == MPDeviceTransportState.disconnected) {
            unawaited(_onBleDisconnectedByStream());
          }
        },
        onError: (Object e, StackTrace st) =>
            debugPrint('------>>>memopin recording watcher connectionStateStream: $e\n$st'),
      );

      _responseSub = transport.responseStream.listen(
        _onResponsePacket,
        onError: (Object e, StackTrace st) =>
            debugPrint('------>>>memopin recording watcher 303 response stream: $e\n$st'),
        onDone: () => debugPrint('------>>>memopin recording watcher 303 response stream: onDone'),
        cancelOnError: false,
      );

      print('[AudioDebug] 开始订阅 bleTransport.audioStream...');
      _audioSub = transport.audioStream.listen(
        _onMemopinAudioStreamDataLikeStartSavingAudio,
        onError: (Object error, StackTrace stackTrace) {
          print('[AudioDebug] ❌ 音频流错误: $error');
          print('[AudioDebug] ❌ 堆栈: $stackTrace');
          print('[AudioDebug] ❌ 已收到 $_audioPacketsReceived 包后出错');
        },
        onDone: () {
          print('[AudioDebug] ⚠️ 音频流结束(onDone)! 共收到 $_audioPacketsReceived 包, $_audioBytesSaved bytes');
          print('[AudioDebug] ⚠️ 这可能表示: 1)设备停止发送 2)BLE订阅被取消 3)设备断开连接');
        },
        cancelOnError: false,
      );
      print('[AudioDebug] ✓ 音频流订阅已建立');
      _boundTransport = transport;
    } catch (e, st) {
      debugPrint('------>>>memopin recording watcher _start: subscribe failed: $e\n$st');
      _boundTransport = null;
      await _connSub?.cancel();
      _connSub = null;
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
      print('[AudioDebug] 保存包#$_audioPacketsReceived: ${data.length}bytes, 总计=$_audioBytesSaved bytes');
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
      print('[AudioDebug] 开始保存音频到: $_savedAudioPath');
    } catch (e) {
      debugPrint('------>>>memopin recording watcher: audio sink open failed: $e');
    }
  }

  Future<void> _closeAudioSavingSink() async {
    final String? closedPath = _savedAudioPath;
    try {
      await _audioFileSink?.flush();
      await _audioFileSink?.close();
    } catch (_) {
      // ignore
    }
    _audioFileSink = null;
    _savedAudioPath = null;
    if (closedPath != null && closedPath.isNotEmpty) {
      _lastRealtimeAudioLocalPath = closedPath;
    }
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
      _lastRealtimeAudioLocalPath = null;
      String? fileLabel;
      try {
        fileLabel = utf8.decode(p.sublist(4));
        _emitIfChanged(
          MPBleMemopinRecordingStateChangedPayload(
            isRecording: true,
            activeFileName: fileLabel.isEmpty ? null : fileLabel,
            sessionModeByte: _lastSessionModeByte,
            changeReason: MPBleMemopinRecordingChangeReason.deviceRecordingStarted,
          ),
        );
      } catch (_) {
        fileLabel = null;
        _emitIfChanged(
          MPBleMemopinRecordingStateChangedPayload(
            isRecording: true,
            sessionModeByte: _lastSessionModeByte,
            changeReason: MPBleMemopinRecordingChangeReason.deviceRecordingStarted,
          ),
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
      print('[AudioDebug] 停止保存音频');
      print('[AudioDebug] 总计: $_audioPacketsReceived 包, $_audioBytesSaved bytes');
      print('[AudioDebug] 文件: $_savedAudioPath');
      unawaited(_closeAudioSavingSink());
      String? stopFileName;
      try {
        final String name = utf8.decode(p.sublist(4));
        stopFileName = name.isEmpty ? null : name;
      } catch (_) {
        stopFileName = null;
      }
      _emitRecordingStopped(
        changeReason: MPBleMemopinRecordingChangeReason.deviceRecordingStopped,
        activeFileName: stopFileName,
      );
    }
  }

  void _emitRecordingStopped({
    required MPBleMemopinRecordingChangeReason changeReason,
    String? activeFileName,
    bool keepActiveFileName = false,
  }) {
    _emitIfChanged(
      MPBleMemopinRecordingStateChangedPayload(
        isRecording: false,
        activeFileName: activeFileName ?? (keepActiveFileName ? _lastEmitted.activeFileName : null),
        sessionModeByte: _lastSessionModeByte,
        changeReason: changeReason,
        lastRealtimeAudioLocalPath: _lastRealtimeAudioLocalPath,
      ),
      forceEmit: true,
    );
  }

  void _emitIfChanged(MPBleMemopinRecordingStateChangedPayload next, {bool forceEmit = false}) {
    if (!forceEmit &&
        next.isRecording == _lastEmitted.isRecording &&
        next.activeFileName == _lastEmitted.activeFileName &&
        next.sessionModeByte == _lastEmitted.sessionModeByte &&
        next.changeReason == _lastEmitted.changeReason &&
        next.lastRealtimeAudioLocalPath == _lastEmitted.lastRealtimeAudioLocalPath) {
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
