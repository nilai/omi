// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../audio/record/mp_audio_local_records_util.dart';
import '../common/mp_home_notification.dart';
import 'mp_ble_preferences.dart';
import 'mp_ble_connection_helper.dart';
import 'mp_ble_transport.dart';
import 'mp_ble_file_util.dart';
import 'mp_device_transport.dart';
import 'mp_note_ble_gatt_client.dart';
import 'mp_note_ble_protocol.dart';
import 'note_device.dart';

/// 订阅 **response `e2c1a303`** 与 **audioData `e2c1a301`**（与 `ble/note_ble_debug_provider.dart` [NoteBleDebugProvider] 使用
/// `bleTransport.responseStream` / `bleTransport.audioStream` 的语义一致：先等待 GATT notify 就绪，再监听重组后的 301 帧流）。
///
/// 按 `ble/doc/ble-api-documentation.md` 解析 **Cmd / Op / Result**，
/// 在「开始录音成功」、BLE 断开、[detach] 时立即更新 [lastEmitted] 并
/// [MPHomeNotification.notifyBleMemopinRecordingStateChanged]；
/// 「结束录音成功」：先转 MP3 / 删设备文件 / 登记本地 record，**完成后再**通知停录；
/// Home 收到后跑批量 sync，sync 全部结束后再统一上传。
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
/// **设备停止录音（303 停止成功）**：
/// 1. 转 MP3 → 导 txt → 删设备文件 → 登记本地 record（**不** [uploadRecords]）
/// 2. emit 停录 → Home 开始 [syncDeviceOpusTxtToSandboxRegisterAndUpload]
/// 3. sync 完成后统一上传（含本条实时 record + 批量新导入）
class MPBleRecordingWatcher {
  static const int _kCheckpointEveryNFrames = 10;

  /// 303 停录后正在转 MP3 / 登记 / 上传，尚未对外通知停录。
  bool _finalizeAfterStopInProgress = false;
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

  Completer<void>? _connectProbeCompleter;

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

  /// 等待 [attach] 内录音连接探测结束（[MPBleConnectionHelper.parkBackgroundBleTransport] 会 await）。
  Future<void> waitForConnectProbe() async {
    final Completer<void>? c = _connectProbeCompleter;
    if (c != null) {
      await c.future;
    }
  }

  void _completeConnectProbe() {
    final Completer<void>? c = _connectProbeCompleter;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
    _connectProbeCompleter = null;
  }

  /// 最近一次实时落盘文件路径（见 [MPBleMemopinRecordingStateChangedPayload.lastRealtimeAudioLocalPath]）。
  String? get lastRealtimeAudioLocalPath => _lastRealtimeAudioLocalPath;

  /// 绑定传输层并开始监听；`transport == null` 等价于 [detach]。
  Future<void> attach(BleTransport? transport) async {
    debugPrint(
      '------>>>memopin recording watcher attach: ${transport == null ? "detach" : "deviceId=${transport.deviceId}"}',
    );
    if (transport == null) {
      await detach();
      return;
    }
    if (_boundTransport?.deviceId == transport.deviceId && _responseSub != null) {
      debugPrint('------>>>memopin recording watcher attach: same device already subscribed, re-probe only');
      _connectProbeCompleter = Completer<void>();
      try {
        await _probeAndJoinActiveDeviceRecordingOnConnect(transport);
      } finally {
        _completeConnectProbe();
      }
      return;
    }
    await detach();
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

  /// BLE 重新 connected（同一 [BleTransport] 实例）：重新订阅后重新读取设备录音状态。
  Future<void> _onBleLinkRestored(BleTransport transport) async {
    debugPrint('------>>>memopin recording watcher: BLE link restored deviceId=${transport.deviceId}');
    try {
      if (!await transport.isConnected()) {
        return;
      }
      await transport.ensureGattSubscriptionsReady();
      await _subscribeStreams(transport);
      await _probeAndJoinActiveDeviceRecordingOnConnect(transport);
    } catch (e, st) {
      debugPrint('------>>>memopin recording watcher link restored failed: $e\n$st');
    }
  }

  Future<void> _start(BleTransport transport) async {
    debugPrint('------>>>memopin recording watcher _start: deviceId=${transport.deviceId}');
    _connectProbeCompleter = Completer<void>();
    try {
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
        await _probeAndJoinActiveDeviceRecordingOnConnect(transport);
      } catch (e, st) {
        debugPrint('------>>>memopin recording watcher _start: subscribe failed: $e\n$st');
        _boundTransport = null;
        await _connSub?.cancel();
        _connSub = null;
        await _cancelStreamSubscriptions();
      }
    } finally {
      _completeConnectProbe();
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

  /// 连接后以 `e2c1a310` 的状态读取判定录音，不依赖 301 帧间隔的观察窗。
  Future<void> _probeAndJoinActiveDeviceRecordingOnConnect(BleTransport transport) async {
    MPNoteBleRecordStatus status = MPNoteBleRecordStatus.idle;

    try {
      await MPBleConnectionHelper.runMemoPinGattExclusive(() async {
        final MPNoteBleGattClient client = MPNoteBleGattClient(transport);
        try {
          await client.syncRtc();
          await client.setRecordingTransportMode(MPNoteBleRecordingTransportModes.recordAndStream);
          status = await client.readRecordingStatus();
        } finally {
          await client.dispose();
        }
      });
    } catch (e) {
      debugPrint('------>>>memopin recording watcher: connection handshake failed: $e');
    }

    if (!status.isRecording || status.fileName.trim().isEmpty) {
      debugPrint('------>>>memopin recording watcher: device idle on connect');
      await _discardInterruptedRecordingState();
      return;
    }

    final String activeFileName = status.fileName.trim();
    final MPBleInterruptedRecordingRecord? interrupted = MPBlePreferences.instance.readInterruptedRecording();
    final bool resumeSameFile = interrupted != null &&
        interrupted.remoteId == transport.deviceId &&
        interrupted.activeFileName.toLowerCase() == activeFileName.toLowerCase();
    _emitIfChanged(
      MPBleMemopinRecordingStateChangedPayload(
        isRecording: true,
        activeFileName: activeFileName,
        sessionModeByte: resumeSameFile ? interrupted.sessionModeByte : _lastSessionModeByte,
        changeReason: MPBleMemopinRecordingChangeReason.deviceRecordingStarted,
      ),
      forceEmit: true,
    );

    if (resumeSameFile) {
      await _tryResumeInterruptedCapture(transport);
      return;
    }

    // 新文件不允许 append 到旧会话；旧文件保留给停录后的批量导入。
    if (interrupted != null) {
      await MPBlePreferences.instance.clearInterruptedRecording();
    }
    await _joinActiveRecordingSession(
      transport,
      NoteFileInfo(index: 0, name: activeFileName, durationSeconds: 0),
    );
  }

  Future<void> _discardInterruptedRecordingState() async {
    if (_audioFileSink != null) {
      await _closeAudioSavingSink(persistSeqSidecar: true);
    }
    _savedAudioPath = null;
    _activeFileNameForRetransmit = null;
    _rtBuffer.reset();
    await MPBlePreferences.instance.clearInterruptedRecording();
  }

  /// 导出设备端正在录的 Opus、续接 301 实时落盘。
  Future<void> _joinActiveRecordingSession(BleTransport transport, NoteFileInfo active) async {
    final String dir = await MPBleFileUtil.ensureMemoPinDeviceAudioDirectoryPath();
    String localPath = p.join(dir, active.name);

    await _closeAudioSavingSink(persistSeqSidecar: false);

    final String? exported = await MPBleFileUtil.exportDeviceOpusFileToSandbox(
      transport: transport,
      info: active,
    );
    if (exported != null && exported.isNotEmpty) {
      localPath = exported;
    } else {
      final File placeholder = File(localPath);
      if (!await placeholder.exists()) {
        await placeholder.create(recursive: true);
      }
    }

    final File localFile = File(localPath);
    final int rawBytes = await localFile.exists() ? await localFile.length() : 0;
    final int lastSeq = MPBleFileUtil.lastCompletedSeqForRawOpusBytes(rawBytes);
    if (lastSeq >= 0) {
      await MPBleFileUtil.trimRawOpusToLastCompletedSeq(localPath, lastSeq);
    }

    _savedAudioPath = localPath;
    _activeFileNameForRetransmit = active.name;
    _rtBuffer.reset();
    await _rtBuffer.loadLastSeqFromSidecar(localPath);
    if (_rtBuffer.lastCompletedSeq < 0 && lastSeq >= 0) {
      await File('$localPath.seq').writeAsString('$lastSeq', flush: true);
      await _rtBuffer.loadLastSeqFromSidecar(localPath);
    }

    transport.resetRealtimeAudioReassembly(fileName: active.name);
    if (_rtBuffer.lastCompletedSeq >= 0) {
      transport.restoreLastCompletedSeq(_rtBuffer.lastCompletedSeq);
    }

    _audioPacketsReceived = 0;
    _audioBytesSaved = await localFile.exists() ? await localFile.length() : 0;
    _lastLogTime = null;
    _audioFileSink = localFile.openWrite(mode: FileMode.append);
    debugPrint(
      '------>>>memopin recording watcher: joined active recording path=$localPath '
      'lastSeq=${_rtBuffer.lastCompletedSeq} bytes=$_audioBytesSaved',
    );
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
    if (p.length >= 4 && p[0] == MPNoteBleRecordingWire.cmdRecordingStart) {
      final int op = p[1] & 0xff;
      final int recordState = p[2] & 0xff;
      final bool startBranch = op == MPNoteBleRecordingWire.opStartRecordingAck || recordState == 0x01;
      if (!startBranch) {
        return;
      }
      debugPrint(
        '------>>>memopin recording watcher 303: start-ok Cmd/Op/State=${p[0]} ${p[1]} ${p[2]} mode=${p[3] & 0xff}',
      );
      final String? previousActiveFileName = _activeFileNameForRetransmit ?? _lastEmitted.activeFileName;
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
          forceEmit: true,
        );
      } catch (_) {
        fileLabel = null;
        _emitIfChanged(
          MPBleMemopinRecordingStateChangedPayload(
            isRecording: true,
            sessionModeByte: _lastSessionModeByte,
            changeReason: MPBleMemopinRecordingChangeReason.deviceRecordingStarted,
          ),
          forceEmit: true,
        );
      }
      final String fn = (fileLabel != null && fileLabel.isNotEmpty) ? fileLabel : 'session.opus';
      if (MPNoteBleRecordingSessionMode.fromWireValue(_lastSessionModeByte!) != null) {
        unawaited(MPBlePreferences.instance.saveRecordingSessionMode(fileName: fn, modeByte: _lastSessionModeByte!));
      }
      _activeFileNameForRetransmit = fn;
      final bool sameSessionAsResume =
          _savedAudioPath != null && previousActiveFileName?.toLowerCase() == fn.toLowerCase();
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
      unawaited(_handleDeviceRecordingStoppedOk(p));
    }
  }

  /// 303 停止成功：先关闭落盘并同步通知停录，耗时 finalize 在其后使用快照执行。
  Future<void> _handleDeviceRecordingStoppedOk(List<int> p) async {
    if (_finalizeAfterStopInProgress) {
      debugPrint('------>>>memopin recording watcher 303: stop-ok ignored (finalize in progress)');
      return;
    }
    _finalizeAfterStopInProgress = true;

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
    final String? deviceFileName = stopFileName ?? _lastEmitted.activeFileName;
    final String? opusPath = _savedAudioPath;

    try {
      await _closeAudioSavingSink();
      final bool isCurrentSession = _lastEmitted.isRecording &&
          (deviceFileName == null ||
              _lastEmitted.activeFileName == null ||
              _lastEmitted.activeFileName!.toLowerCase() == deviceFileName.toLowerCase());
      if (isCurrentSession) {
        _activeFileNameForRetransmit = null;
        _rtBuffer.reset();
        await MPBlePreferences.instance.clearInterruptedRecording();
        _emitRecordingStopped(
          changeReason: MPBleMemopinRecordingChangeReason.deviceRecordingStopped,
          activeFileName: stopFileName,
        );
      }

      if (opusPath != null && opusPath.isNotEmpty) {
        MPBleFileUtil.claimRealtimeDeviceOpus(deviceFileName);
        await _finalizeStoppedRealtimeCapture(
          opusPath: opusPath,
          deviceFileName: deviceFileName,
        );
      }

    } catch (e, st) {
      debugPrint('------>>>memopin recording watcher stop finalize pipeline failed: $e\n$st');
      MPBleFileUtil.releaseRealtimeDeviceOpusClaim(deviceFileName);
      if (_lastEmitted.isRecording) {
        _emitRecordingStopped(
          changeReason: MPBleMemopinRecordingChangeReason.deviceRecordingStopped,
          activeFileName: stopFileName,
        );
      }
    } finally {
      _finalizeAfterStopInProgress = false;
    }
  }

  /// 303 停止成功后：转 MP3 → 导入 txt → 删设备文件 → 登记 record；**不上传**（交由 sync 结束后统一上传）。
  Future<void> _finalizeStoppedRealtimeCapture({
    required String opusPath,
    String? deviceFileName,
  }) async {
    final BleTransport? transport = _boundTransport;
    try {
      final MPAudioLocalRecord? record = await MPBleFileUtil.finalizeRealtimeOpusToLocalRecord(
        opusPath: opusPath,
        deviceFileName: deviceFileName,
        transport: transport,
        deferDeviceFileCleanup: false,
      );
      if (record == null) {
        MPBleFileUtil.releaseRealtimeDeviceOpusClaim(deviceFileName);
        return;
      }
      MPBleFileUtil.deferUploadUntilAfterDeviceSync(record);
    } catch (e, st) {
      MPBleFileUtil.releaseRealtimeDeviceOpusClaim(deviceFileName);
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
