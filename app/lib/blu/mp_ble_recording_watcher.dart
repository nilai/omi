// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../common/mp_home_notification.dart';
import 'mp_ble_preferences.dart';
import 'mp_ble_transport.dart';
import 'mp_ble_file_util.dart';
import 'mp_device_transport.dart';
import 'mp_note_ble_gatt_client.dart';
import 'mp_note_ble_protocol.dart';

/// 订阅 **response `e2c1a303`** 与 **audioData `e2c1a301`**（与 `ble/note_ble_debug_provider.dart` [NoteBleDebugProvider] 使用
/// `bleTransport.responseStream` / `bleTransport.audioStream` 的语义一致：先等待 GATT notify 就绪，再监听重组后的 301 帧流）。
///
/// 按 `ble/doc/ble-api-documentation.md` 解析 **Cmd / Op / Result**，
/// 在「开始录音成功」「结束录音成功」、BLE 断开、[detach] 时更新 [lastEmitted] 并
/// [MPHomeNotification.notifyBleMemopinRecordingStateChanged]。
///
/// **实时音频落盘**（对齐 [MPBleLiveRecordingSession] / [NoteBleTransport] 边录边传）：
/// - 订阅 **301 原始 notify** + [MPBleRtOpusBuffer] 组 480B 帧；Seq 间隙发 `0x20` 补传；
/// - 303 **开始录音成功** 后打开沙盒 `.opus`；**停止** 后关闭并清除续传持久化。
///
/// **重连续传**（使用中 BLE 闪断、App 冷启动后 [attach]）：
/// - 录制中每 N 帧 [checkpoint] 持久化 Seq/路径（应对进程强杀）；
/// - 续传前 [MPBleFileUtil.trimRawOpusToLastCompletedSeq] 裁剪本地裸 Opus 再 append；
/// - 链路丢失时 checkpoint + App 通知 `bleDisconnected`；重连后恢复落盘并再发 `deviceRecordingStarted`。
///
/// **设备停止录音（303 停止成功）**：[MPBleFileUtil.finalizeRealtimeOpusToLocalRecordAndUpload]（转 MP3、登记、上传），
/// 与批量导入单条成功路径一致；设备端文件仍由连接成功后的 [syncDeviceOpusTxtToSandboxRegisterAndUpload] 拉取删除。
class MPBleRecordingWatcher {
  static const int _kCheckpointEveryNFrames = 10;
  StreamSubscription<List<int>>? _responseSub;
  StreamSubscription<List<int>>? _rawAudioSub;
  StreamSubscription<MPDeviceTransportState>? _connSub;

  final MPBleRtOpusBuffer _rtBuffer = MPBleRtOpusBuffer();
  String? _activeFileNameForRetransmit;
  bool _linkWasLost = false;

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
    await _cancelStreamSubscriptions();
    await _closeAudioSavingSink(persistSeqSidecar: wasRecording);
    await MPBlePreferences.instance.clearInterruptedRecording();
    _boundTransport = null;
    _linkWasLost = false;
    _activeFileNameForRetransmit = null;
    if (wasRecording) {
      _emitRecordingStopped(
        changeReason: MPBleMemopinRecordingChangeReason.watcherDetached,
        keepActiveFileName: true,
      );
    }
  }

  Future<void> _cancelStreamSubscriptions() async {
    final StreamSubscription<List<int>>? r = _responseSub;
    final StreamSubscription<List<int>>? a = _rawAudioSub;
    _responseSub = null;
    _rawAudioSub = null;
    await Future.wait<void>(<Future<void>>[
      if (r != null) r.cancel(),
      if (a != null) a.cancel(),
    ]);
  }

  /// BLE 链路丢失：持久化待续传会话，并向 App 通知「外接录音已中断」（不向设备发停录命令）。
  Future<void> _onBleLinkLost() async {
    debugPrint('------>>>memopin recording watcher: BLE link lost');
    final bool wasRecording = _lastEmitted.isRecording;
    if (wasRecording) {
      await _persistInterruptedSession();
    }
    await _cancelStreamSubscriptions();
    await _closeAudioSavingSink(persistSeqSidecar: wasRecording);
    if (wasRecording) {
      _emitRecordingStopped(
        changeReason: MPBleMemopinRecordingChangeReason.bleDisconnected,
        keepActiveFileName: true,
      );
    }
  }

  /// BLE 重新 connected（同一 [BleTransport] 实例）：重新订阅 301/303 并续传落盘。
  Future<void> _onBleLinkRestored(BleTransport transport) async {
    debugPrint('------>>>memopin recording watcher: BLE link restored deviceId=${transport.deviceId}');
    try {
      if (!await transport.isConnected()) {
        return;
      }
      await transport.ensureGattSubscriptionsReady();
      await _subscribeStreams(transport);
      await _tryResumeInterruptedCapture(transport);
    } catch (e, st) {
      debugPrint('------>>>memopin recording watcher link restored failed: $e\n$st');
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
      _boundTransport = transport;

      await _restoreRecordingStateFromDiskIfNeeded(transport.deviceId);

      _connSub = transport.connectionStateStream.listen(
        (MPDeviceTransportState s) {
          if (s == MPDeviceTransportState.disconnected) {
            _linkWasLost = true;
            unawaited(_onBleLinkLost());
          } else if (s == MPDeviceTransportState.connected && _linkWasLost) {
            _linkWasLost = false;
            unawaited(_onBleLinkRestored(transport));
          }
        },
        onError: (Object e, StackTrace st) =>
            debugPrint('------>>>memopin recording watcher connectionStateStream: $e\n$st'),
      );

      await _subscribeStreams(transport);
      await _tryResumeInterruptedCapture(transport);
    } catch (e, st) {
      debugPrint('------>>>memopin recording watcher _start: subscribe failed: $e\n$st');
      _boundTransport = null;
      await _connSub?.cancel();
      _connSub = null;
      await _cancelStreamSubscriptions();
    }
  }

  Future<void> _subscribeStreams(BleTransport transport) async {
    await _cancelStreamSubscriptions();

    _responseSub = transport.responseStream.listen(
      _onResponsePacket,
      onError: (Object e, StackTrace st) =>
          debugPrint('------>>>memopin recording watcher 303 response stream: $e\n$st'),
      onDone: () => debugPrint('------>>>memopin recording watcher 303 response stream: onDone'),
      cancelOnError: false,
    );

    print('[AudioDebug] 开始订阅 bleTransport raw 301 (续传/边录边传)...');
    final Stream<List<int>> raw301 = await transport.getRawCharacteristicNotifyStreamWhenReady(
      MPNoteBleUUIDs.service.toString(),
      MPNoteBleUUIDs.audioData.toString(),
    );
    _rawAudioSub = raw301.listen(
      _onRawAudio301,
      onError: (Object error, StackTrace stackTrace) {
        print('[AudioDebug] ❌ 301 原始流错误: $error');
        print('[AudioDebug] ❌ 堆栈: $stackTrace');
      },
      onDone: () {
        print('[AudioDebug] ⚠️ 301 原始流结束(onDone)! 共收到 $_audioPacketsReceived 帧');
      },
      cancelOnError: false,
    );
    print('[AudioDebug] ✓ 301 原始流订阅已建立');
  }

  void _onRawAudio301(List<int> packet) {
    if (_audioFileSink == null) {
      return;
    }
    _rtBuffer.feed(
      packet,
      onGap: (int from, int to) {
        unawaited(_requestRetransmit(from, to));
      },
      onFrame480: _onOpusFrame480Saved,
    );
  }

  void _onOpusFrame480Saved(List<int> frame) {
    _audioPacketsReceived++;
    _audioBytesSaved += frame.length;
    _audioFileSink?.add(frame);

    final DateTime now = DateTime.now();
    final bool shouldLog = _audioPacketsReceived <= 10 ||
        _lastLogTime == null ||
        now.difference(_lastLogTime!).inSeconds >= 10;
    if (shouldLog) {
      print('[AudioDebug] 保存帧#$_audioPacketsReceived: ${frame.length}bytes, 总计=$_audioBytesSaved bytes');
      _lastLogTime = now;
    }
    if (_audioPacketsReceived % _kCheckpointEveryNFrames == 0) {
      unawaited(_checkpointInterruptedSession());
    }
  }

  Future<void> _requestRetransmit(int startSeq, int endSeq) async {
    final String? name = _activeFileNameForRetransmit;
    final BleTransport? transport = _boundTransport;
    if (name == null || name.isEmpty || transport == null) {
      return;
    }
    final MPNoteBleGattClient client = MPNoteBleGattClient(transport);
    try {
      await client.sendRetransmitAudioRequest(name, startSeq, endSeq);
    } catch (e) {
      debugPrint('------>>>memopin recording watcher retransmit: $e');
    } finally {
      await client.dispose();
    }
  }

  Future<void> _restoreRecordingStateFromDiskIfNeeded(String deviceId) async {
    final MPBleInterruptedRecordingRecord? record = MPBlePreferences.instance.readInterruptedRecording();
    if (record == null || record.remoteId != deviceId) {
      return;
    }
    debugPrint(
      '------>>>memopin recording watcher: restore interrupted session file=${record.activeFileName} path=${record.localOpusPath}',
    );
    _lastSessionModeByte = record.sessionModeByte;
    _savedAudioPath = record.localOpusPath;
    _activeFileNameForRetransmit = record.activeFileName;
    _emitIfChanged(
      MPBleMemopinRecordingStateChangedPayload(
        isRecording: true,
        activeFileName: record.activeFileName,
        sessionModeByte: record.sessionModeByte,
        changeReason: MPBleMemopinRecordingChangeReason.deviceRecordingStarted,
      ),
      forceEmit: true,
    );
  }

  /// 录制中/断连前：落盘 `.seq` sidecar 并写入 [MPBlePreferences]（供强杀后冷启动续传）。
  Future<void> _checkpointInterruptedSession() async {
    final BleTransport? transport = _boundTransport;
    final String? path = _savedAudioPath;
    final String? fileName = _lastEmitted.activeFileName ?? _activeFileNameForRetransmit;
    if (transport == null || path == null || path.isEmpty || fileName == null || fileName.isEmpty) {
      return;
    }
    try {
      await _audioFileSink?.flush();
    } catch (_) {
      // ignore
    }
    await _rtBuffer.persistLastSeqSidecar(path);
    await MPBlePreferences.instance.saveInterruptedRecording(
      MPBleInterruptedRecordingRecord(
        remoteId: transport.deviceId,
        activeFileName: fileName,
        localOpusPath: path,
        sessionModeByte: _lastSessionModeByte,
        lastCompletedSeq: _rtBuffer.lastCompletedSeq,
      ),
    );
  }

  Future<void> _persistInterruptedSession() async {
    await _checkpointInterruptedSession();
    debugPrint('------>>>memopin recording watcher: persisted interrupted recording seq=${_rtBuffer.lastCompletedSeq}');
  }

  Future<void> _tryResumeInterruptedCapture(BleTransport transport) async {
    final MPBleInterruptedRecordingRecord? interrupted =
        MPBlePreferences.instance.readInterruptedRecording();
    if (interrupted != null && interrupted.remoteId == transport.deviceId) {
      _savedAudioPath = interrupted.localOpusPath;
      _activeFileNameForRetransmit = interrupted.activeFileName;
      _lastSessionModeByte = interrupted.sessionModeByte;
    } else if (!_lastEmitted.isRecording) {
      return;
    }

    final bool shouldNotifyRecordingStarted = !_lastEmitted.isRecording;
    final String? path = _savedAudioPath;
    final String? fileName = _lastEmitted.activeFileName ?? _activeFileNameForRetransmit;
    if (path == null || path.isEmpty || fileName == null || fileName.isEmpty) {
      return;
    }
    final File local = File(path);
    if (!await local.exists()) {
      debugPrint('------>>>memopin recording watcher: resume aborted, local file missing $path');
      return;
    }

    _activeFileNameForRetransmit = fileName;
    transport.resetRealtimeAudioReassembly(fileName: fileName);
    await _rtBuffer.loadLastSeqFromSidecar(path);
    final int trimSeq = interrupted?.lastCompletedSeq ?? _rtBuffer.lastCompletedSeq;
    if (trimSeq >= 0) {
      await MPBleFileUtil.trimRawOpusToLastCompletedSeq(path, trimSeq);
      await _rtBuffer.loadLastSeqFromSidecar(path);
    }
    if (_rtBuffer.lastCompletedSeq >= 0) {
      transport.restoreLastCompletedSeq(_rtBuffer.lastCompletedSeq);
    }

    if (_audioFileSink == null) {
      _audioFileSink = local.openWrite(mode: FileMode.append);
      _lastLogTime = null;
      print('[AudioDebug] 续传落盘 append: $path seq=${_rtBuffer.lastCompletedSeq}');
    }

    await MPBlePreferences.instance.clearInterruptedRecording();
    debugPrint('------>>>memopin recording watcher: capture resumed after reconnect');

    if (shouldNotifyRecordingStarted) {
      _emitIfChanged(
        MPBleMemopinRecordingStateChangedPayload(
          isRecording: true,
          activeFileName: fileName,
          sessionModeByte: _lastSessionModeByte,
          changeReason: MPBleMemopinRecordingChangeReason.deviceRecordingStarted,
        ),
        forceEmit: true,
      );
    }
  }

  Future<void> _ensureAudioSavingSinkOpen({bool appendIfPathExists = false}) async {
    if (_audioFileSink != null) {
      return;
    }
    try {
      if (appendIfPathExists && _savedAudioPath != null && _savedAudioPath!.isNotEmpty) {
        final File existing = File(_savedAudioPath!);
        if (await existing.exists()) {
          _audioFileSink = existing.openWrite(mode: FileMode.append);
          print('[AudioDebug] 续写音频: $_savedAudioPath');
          return;
        }
      }
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

  Future<void> _closeAudioSavingSink({bool persistSeqSidecar = false}) async {
    final String? closedPath = _savedAudioPath;
    if (persistSeqSidecar && closedPath != null && closedPath.isNotEmpty) {
      await _rtBuffer.persistLastSeqSidecar(closedPath);
    }
    try {
      await _audioFileSink?.flush();
      await _audioFileSink?.close();
    } catch (_) {
      // ignore
    }
    _audioFileSink = null;
    if (!persistSeqSidecar) {
      _savedAudioPath = null;
    }
    if (closedPath != null && closedPath.isNotEmpty) {
      _lastRealtimeAudioLocalPath = closedPath;
    }
  }

  /// 处理 303 notify：补传载荷 / **开始录音成功** / **结束录音成功**。
  void _onResponsePacket(List<int> p) {
    if (p.isEmpty) {
      return;
    }
    if (p[0] == MPNoteBleCommands.retransmitAudio) {
      if (MPBleRtOpusBuffer.isRetransmitCompletionPacket(p) || _audioFileSink == null) {
        return;
      }
      if (p.length >= 9) {
        _onRawAudio301(p.sublist(1));
      }
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
      _activeFileNameForRetransmit = fn;
      final bool sameSessionAsResume =
          _savedAudioPath != null && _lastEmitted.activeFileName?.toLowerCase() == fn.toLowerCase();
      _boundTransport?.resetRealtimeAudioReassembly(fileName: fn);
      if (!sameSessionAsResume) {
        _rtBuffer.reset();
        unawaited(_ensureAudioSavingSinkOpen());
      } else if (_rtBuffer.lastCompletedSeq >= 0) {
        _boundTransport?.restoreLastCompletedSeq(_rtBuffer.lastCompletedSeq);
        unawaited(_ensureAudioSavingSinkOpen(appendIfPathExists: true));
      } else {
        unawaited(_ensureAudioSavingSinkOpen(appendIfPathExists: true));
      }
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
      String? stopFileName;
      try {
        final String name = utf8.decode(p.sublist(4));
        stopFileName = name.isEmpty ? null : name;
      } catch (_) {
        stopFileName = null;
      }
      final String? opusPath = _savedAudioPath;
      unawaited(_closeAudioSavingSink());
      _activeFileNameForRetransmit = null;
      _rtBuffer.reset();
      unawaited(MPBlePreferences.instance.clearInterruptedRecording());
      if (opusPath != null && opusPath.isNotEmpty) {
        unawaited(
          _finalizeStoppedRealtimeCapture(
            opusPath: opusPath,
            deviceFileName: stopFileName ?? _lastEmitted.activeFileName,
          ),
        );
      }
      _emitRecordingStopped(
        changeReason: MPBleMemopinRecordingChangeReason.deviceRecordingStopped,
        activeFileName: stopFileName,
      );
    }
  }

  /// 303 停止成功后：转 MP3、写入本地 record、触发上传（与批量导入登记路径一致）。
  Future<void> _finalizeStoppedRealtimeCapture({
    required String opusPath,
    String? deviceFileName,
  }) async {
    try {
      await MPBleFileUtil.finalizeRealtimeOpusToLocalRecordAndUpload(
        opusPath: opusPath,
        deviceFileName: deviceFileName,
      );
    } catch (e, st) {
      debugPrint('------>>>memopin recording watcher finalize after stop failed: $e\n$st');
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
