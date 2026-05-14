import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../audio/import/mp_audio_import_utils.dart';
import '../audio/record/mp_audio_local_records_util.dart';
import '../audio/record/mp_audio_upload_manger.dart';
import '../common/mp_home_notification.dart';
import '../utils/mp_opus_to_mp3_util.dart';

import 'ble_transport.dart';
import 'mp_ble_connection_helper.dart';
import 'mp_note_ble_gatt_client.dart';
import 'mp_note_ble_protocol.dart';
import 'note_device.dart';

/// BLE 设备导出复制进度（当前文件序号、总数、0–100）。
typedef MPBleFileUtilCopyProgress =
    void Function({required int fileIndex, required int fileTotal, required int progressPercent});

/// MemoPin 设备文件：列表拆分、沙盒落盘、Opus→MP3、本地记录与上传。
class MPBleFileUtil {
  MPBleFileUtil._();

  static const String kMemoPinRecordSource = 'MemoPin';
  static const String _kSandboxDirName = 'mp_memopin_device_audio';
  static const Duration _kIdleDone = Duration(seconds: 2);

  /// 应用 Documents 下 MemoPin 设备音频目录（导出 `.opus` / `.txt` / `.mp3`）。
  static Future<String> ensureMemoPinDeviceAudioDirectoryPath() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final String dir = p.join(docs.path, _kSandboxDirName);
    await Directory(dir).create(recursive: true);
    return dir;
  }

  static Duration _maxExportWaitForFile(NoteFileInfo info) {
    final int sec = info.durationSeconds;
    if (sec <= 0) {
      return const Duration(seconds: 120);
    }
    final int capped = (sec * 5).clamp(60, 600);
    return Duration(seconds: capped);
  }

  /// 拉取列表 → 按 Opus 逐条导出 `.opus` 与同名 `.txt` 至 [ensureMemoPinDeviceAudioDirectoryPath] → 转 MP3 →
  /// 写入 [MPAudioLocalRecord]（含 [MPAudioLocalRecord.mp3Path] / [MPAudioLocalRecord.txtPath]）→
  /// [MPHomeNotification.notifyHomeListRefresh] → 上传队列（与 [MPBleDeviceAudioImportUtils.syncUploadAndDeleteDeviceFiles] 类似，但含 txt 与 MP3 字段）。
  static Future<void> syncDeviceOpusTxtToSandboxRegisterAndUpload({
    required BleTransport transport,
    required MPBleFileUtilCopyProgress onSyncProgress,
  }) async {
    try {
      if (!await transport.isConnected()) {
        debugPrint('MPBleFileUtil: Bluetooth is not connected.');
        return;
      }

      debugPrint('MPBleFileUtil: fetching file list from device...');
      final List<NoteFileInfo> allFiles = await MPBleConnectionHelper.fetchMemoPinFileList(transport);
      if (allFiles.isEmpty) {
        debugPrint('MPBleFileUtil: no files on the device.');
        return;
      }

      final List<NoteFileInfo> opusList = allFiles
          .where((NoteFileInfo e) => e.name.toLowerCase().endsWith('.opus'))
          .toList(growable: false);
      final List<NoteFileInfo> txtList = allFiles
          .where((NoteFileInfo e) => e.name.toLowerCase().endsWith('.txt'))
          .toList(growable: false);

      if (opusList.isEmpty) {
        debugPrint('MPBleFileUtil: no opus files on the device.');
        return;
      }

      final String deviceDir = await ensureMemoPinDeviceAudioDirectoryPath();
      debugPrint('MPBleFileUtil: device audio dir: $deviceDir');

      final int total = opusList.length;
      for (int i = 0; i < total; i++) {
        if (!await transport.isConnected()) {
          debugPrint('MPBleFileUtil: Bluetooth disconnected during sync.');
          break;
        }

        final NoteFileInfo opusInfo = opusList[i];
        onSyncProgress(fileIndex: i + 1, fileTotal: total, progressPercent: 0);

        final MPNoteBleGattClient opusClient = MPNoteBleGattClient(transport);
        String? opusPath;
        try {
          final List<int>? opusBytes =
              await _collectExportPayloads(client: opusClient, fileName: opusInfo.name, info: opusInfo);
          if (opusBytes == null || opusBytes.isEmpty) {
            debugPrint('MPBleFileUtil: failed to export opus: ${opusInfo.name}');
            onSyncProgress(fileIndex: i + 1, fileTotal: total, progressPercent: 100);
            continue;
          }

          onSyncProgress(fileIndex: i + 1, fileTotal: total, progressPercent: 35);

          opusPath = await _writeBytesToDir(
            directoryPath: deviceDir,
            fileName: opusInfo.name,
            bytes: opusBytes,
          );
        } finally {
          await opusClient.dispose();
        }

        if (opusPath == null) {
          debugPrint('MPBleFileUtil: failed to write opus: ${opusInfo.name}');
          onSyncProgress(fileIndex: i + 1, fileTotal: total, progressPercent: 100);
          continue;
        }

        String? txtPathWritten;
        final NoteFileInfo? txtMatch = _findTxtForOpus(txtList, opusInfo.name);
        if (txtMatch != null) {
          final MPNoteBleGattClient txtClient = MPNoteBleGattClient(transport);
          try {
            final List<int>? txtBytes =
                await _collectExportPayloads(client: txtClient, fileName: txtMatch.name, info: txtMatch);
            if (txtBytes != null && txtBytes.isNotEmpty) {
              txtPathWritten = await _writeBytesToDir(
                directoryPath: deviceDir,
                fileName: txtMatch.name,
                bytes: txtBytes,
              );
            }
          } finally {
            await txtClient.dispose();
          }
        }

        onSyncProgress(fileIndex: i + 1, fileTotal: total, progressPercent: 55);

        final String? mp3Path = await MPOpusToMp3Util.convertMemoPinBleOpusExportToMp3(opusPath);
        final File primaryFile = File((mp3Path != null && mp3Path.isNotEmpty) ? mp3Path : opusPath);
        if (!await primaryFile.exists()) {
          debugPrint('MPBleFileUtil: primary audio missing after convert: ${opusInfo.name}');
          onSyncProgress(fileIndex: i + 1, fileTotal: total, progressPercent: 100);
          continue;
        }

        onSyncProgress(fileIndex: i + 1, fileTotal: total, progressPercent: 80);

        final String audioPathForRecord = primaryFile.path;
        final int? durAudio = await MPAudioImportUtils.readAudioDurationSeconds(audioPathForRecord);
        int durationSec = (durAudio != null && durAudio > 0) ? durAudio : opusInfo.durationSeconds;
        if (durationSec <= 0) {
          durationSec = 1;
        }
        final int createAtSec = (await primaryFile.lastModified()).millisecondsSinceEpoch ~/ 1000;

        await MPAudioLocalRecordsUtil.instance.add(
          MPAudioLocalRecord(
            path: audioPathForRecord,
            txtPath: txtPathWritten,
            fileName: opusInfo.name,
            createAt: createAtSec,
            duration: durationSec,
            source: kMemoPinRecordSource,
            isRemoved: false,
          ),
        );

        MPHomeNotification.notifyHomeListRefresh();

        if (await transport.isConnected()) {
          final bool deleted = await MPBleConnectionHelper.deleteMemoPinFile(transport, opusInfo.name);
          if (!deleted) {
            debugPrint('MPBleFileUtil: could not delete opus on device: ${opusInfo.name}');
          }
        } else {
          debugPrint('MPBleFileUtil: Bluetooth disconnected; skipped device delete for ${opusInfo.name}.');
        }

        onSyncProgress(fileIndex: i + 1, fileTotal: total, progressPercent: 100);
      }

      debugPrint('MPBleFileUtil: uploading recordings...');
      await MPAudioUploadManager.instance.uploadAllRecordingFiles(rightNowTranscribe: false);
    } catch (e, st) {
      debugPrint('MPBleFileUtil device import failed: $e\n$st');
    }
  }

  static NoteFileInfo? _findTxtForOpus(List<NoteFileInfo> txtList, String opusFileName) {
    final String stem = p.basenameWithoutExtension(opusFileName);
    final String target = '$stem.txt';
    for (final NoteFileInfo t in txtList) {
      if (t.name.toLowerCase() == target.toLowerCase()) {
        return t;
      }
    }
    return null;
  }

  static Future<String?> _writeBytesToDir({
    required String directoryPath,
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      if (bytes.isEmpty) {
        return null;
      }
      final String targetPath = p.join(directoryPath, fileName);
      final File targetFile = File(targetPath);
      await targetFile.writeAsBytes(bytes, flush: true);
      return targetFile.path;
    } catch (e) {
      debugPrint('MPBleFileUtil._writeBytesToDir failed: $e');
      return null;
    }
  }

  static Future<List<int>?> _collectExportPayloads({
    required MPNoteBleGattClient client,
    required String fileName,
    required NoteFileInfo info,
  }) async {
    client.prepareFileExport(fileName);
    final List<int> buffer = <int>[];
    Timer? idleTimer;
    final Completer<void> idleDone = Completer<void>();
    bool receivedPayload = false;

    void armIdleTimer() {
      idleTimer?.cancel();
      idleTimer = Timer(_kIdleDone, () {
        if (!idleDone.isCompleted) {
          idleDone.complete();
        }
      });
    }

    late final StreamSubscription<List<int>> sub;
    sub = client.recordFilePayloadStream.listen(
      (List<int> chunk) {
        if (chunk.isNotEmpty) {
          receivedPayload = true;
        }
        buffer.addAll(chunk);
        if (receivedPayload) {
          armIdleTimer();
        }
      },
      onError: (Object e, StackTrace st) {
        debugPrint('MPBleFileUtil BLE export stream error: $e\n$st');
      },
    );

    try {
      final bool accepted = await client.requestFileExport(fileName);
      if (!accepted) {
        idleTimer?.cancel();
        await sub.cancel();
        return null;
      }

      await Future.any<void>(<Future<void>>[idleDone.future, Future<void>.delayed(_maxExportWaitForFile(info))]);
      idleTimer?.cancel();

      for (final List<int> tail in client.flushFileExportAssemblerTail()) {
        buffer.addAll(tail);
      }
      await sub.cancel();

      if (!receivedPayload && buffer.isEmpty) {
        return null;
      }
      return buffer;
    } catch (e, st) {
      debugPrint('MPBleFileUtil BLE export collect failed: $e\n$st');
      idleTimer?.cancel();
      await sub.cancel();
      return null;
    }
  }

  // —— 设备端文件删除 / 本地沙盒删除 ——

  /// 删除设备端指定文件名（`0x05`）。
  static Future<bool> deleteDeviceRecordingFile(BleTransport transport, String fileName) {
    return MPBleConnectionHelper.deleteMemoPinFile(transport, fileName);
  }

  /// 删除沙盒内文件及可选 `.seq` 续传侧车文件。
  static Future<bool> deleteLocalSandboxAudioFile(String absolutePath) async {
    try {
      final File f = File(absolutePath);
      if (await f.exists()) {
        await f.delete();
      }
      final File seq = File('$absolutePath.seq');
      if (await seq.exists()) {
        await seq.delete();
      }
      return true;
    } catch (e) {
      debugPrint('MPBleFileUtil.deleteLocalSandboxAudioFile: $e');
      return false;
    }
  }

  /// 开启实时 Opus 写入（`e2c1a301`）；[kind] 决定 `0x0D` 为仅录音或边录边传；[appendResume] 为 `true` 时续写并尝试 Seq 间隙补传。
  ///
  /// [opusFileName] 须含 `.opus` 后缀，写入目录为 [ensureMemoPinDeviceAudioDirectoryPath]。
  static Future<MPBleLiveRecordingSession?> startLiveOpusRecording({
    required BleTransport transport,
    required MPBleLiveRecordingKind kind,
    required bool appendResume,
    required String opusFileName,
  }) async {
    try {
      if (!await transport.isConnected()) {
        return null;
      }
    } catch (_) {
      return null;
    }
    if (!opusFileName.toLowerCase().endsWith('.opus')) {
      debugPrint('MPBleFileUtil.startLiveOpusRecording: opusFileName must end with .opus');
      return null;
    }
    final String dir = await ensureMemoPinDeviceAudioDirectoryPath();
    final String opusPath = p.join(dir, opusFileName);
    final MPBleLiveRecordingSession session = MPBleLiveRecordingSession._(
      transport: transport,
      kind: kind,
      appendResume: appendResume,
      opusPath: opusPath,
    );
    final bool ok = await session._start();
    if (!ok) {
      await session.dispose();
      return null;
    }
    return session;
  }
}

/// memo：配置为「仅录音」推流（`0x0D` `recordOnly`）；memory：「边录边传」并落盘 opus（`recordAndStream`）。
enum MPBleLiveRecordingKind {
  /// 短按类备忘录场景：侧向仅录音上行。
  memo,

  /// 普通长录音：实时 opus 帧写入（与 `e2c1a301` 协议一致）。
  memory,
}

/// 实时录音写入会话；调用 [finalizeToMp3AndRecord] 结束并落库。
class MPBleLiveRecordingSession {
  MPBleLiveRecordingSession._({
    required BleTransport transport,
    required this.kind,
    required this.appendResume,
    required this.opusPath,
  }) : _transport = transport;

  final BleTransport _transport;
  final MPBleLiveRecordingKind kind;
  final bool appendResume;
  final String opusPath;

  IOSink? _sink;
  StreamSubscription<List<int>>? _audioSub;
  StreamSubscription<List<int>>? _retransmitSub;
  final _MPBleRtOpusBuffer _buffer = _MPBleRtOpusBuffer();
  String? _activeFileNameForRetransmit;

  /// 是否已成功订阅并开始写入。
  bool _started = false;

  /// 底层传输（用于外部判断连接等）。
  BleTransport get transport => _transport;

  Future<bool> _start() async {
    final MPNoteBleGattClient cmd = MPNoteBleGattClient(_transport);
    try {
      final int modeByte = kind == MPBleLiveRecordingKind.memo
          ? MPNoteBleRecordingTransportModes.recordOnly
          : MPNoteBleRecordingTransportModes.recordAndStream;
      final bool modeOk = await cmd.setRecordingTransportMode(modeByte);
      if (!modeOk) {
        debugPrint('MPBleLiveRecordingSession: setRecordingTransportMode failed');
        return false;
      }
    } finally {
      await cmd.dispose();
    }

    final File out = File(opusPath);
    if (!appendResume && await out.exists()) {
      await out.delete();
    }
    _sink = out.openWrite(mode: appendResume ? FileMode.append : FileMode.write);

    if (appendResume) {
      await _buffer.loadLastSeqFromSidecar(opusPath);
    }

    _activeFileNameForRetransmit = p.basename(opusPath);

    _audioSub = _transport
        .getCharacteristicStream(MPNoteBleUUIDs.service, MPNoteBleUUIDs.audioData)
        .listen(_onAudio301, onError: (Object e) => debugPrint('MPBleLiveRecordingSession audio301: $e'));

    _retransmitSub = _transport
        .getCharacteristicStream(MPNoteBleUUIDs.service, MPNoteBleUUIDs.response)
        .listen(_onResponse303Retransmit, onError: (_) {});

    _started = true;
    return true;
  }

  void _onAudio301(List<int> packet) {
    _buffer.feed(
      packet,
      onGap: (int from, int to) {
        unawaited(_requestRetransmit(from, to));
      },
      onFrame480: (List<int> frame) {
        _sink?.add(frame);
      },
    );
  }

  void _onResponse303Retransmit(List<int> p) {
    if (p.isEmpty || p[0] != MPNoteBleCommands.retransmitAudio) {
      return;
    }
    if (_MPBleRtOpusBuffer.isRetransmitCompletionPacket(p)) {
      return;
    }
    if (p.length < 9) {
      return;
    }
    _onAudio301(p.sublist(1));
  }

  Future<void> _requestRetransmit(int startSeq, int endSeq) async {
    final String? name = _activeFileNameForRetransmit;
    if (name == null || name.isEmpty) {
      return;
    }
    final MPNoteBleGattClient c = MPNoteBleGattClient(_transport);
    try {
      await c.sendRetransmitAudioRequest(name, startSeq, endSeq);
    } catch (e) {
      debugPrint('MPBleLiveRecordingSession retransmit: $e');
    } finally {
      await c.dispose();
    }
  }

  /// 取消订阅并删除未完成的 sink（不写 MP3、不登记 record）。
  Future<void> dispose() async {
    await _audioSub?.cancel();
    _audioSub = null;
    await _retransmitSub?.cancel();
    _retransmitSub = null;
    try {
      await _sink?.flush();
      await _sink?.close();
    } catch (_) {}
    _sink = null;
    _started = false;
  }

  /// 刷尾、关流、`opus`→`mp3`、写入 [MPAudioLocalRecord] 并触发刷新与上传队列。
  Future<bool> finalizeToMp3AndRecord({
    bool runUploadQueue = true,
  }) async {
    if (!_started) {
      return false;
    }
    await _audioSub?.cancel();
    _audioSub = null;
    await _retransmitSub?.cancel();
    _retransmitSub = null;

    for (final List<int> tail in _buffer.flushTailFrames()) {
      _sink?.add(tail);
    }
    try {
      await _sink?.flush();
      await _sink?.close();
    } catch (_) {}
    _sink = null;
    _started = false;

    await _buffer.persistLastSeqSidecar(opusPath);

    final String? mp3Path = await MPOpusToMp3Util.convertMemoPinBleOpusExportToMp3(opusPath);
    final File primary = File((mp3Path != null && mp3Path.isNotEmpty) ? mp3Path : opusPath);
    if (!await primary.exists()) {
      debugPrint('MPBleLiveRecordingSession: output file missing');
      return false;
    }

    final String audioPath = primary.path;
    final int? durAudio = await MPAudioImportUtils.readAudioDurationSeconds(audioPath);
    int durationSec = (durAudio != null && durAudio > 0) ? durAudio : 1;
    final int createAtSec = (await primary.lastModified()).millisecondsSinceEpoch ~/ 1000;

    await MPAudioLocalRecordsUtil.instance.add(
      MPAudioLocalRecord(
        path: audioPath,
        fileName: p.basename(opusPath),
        createAt: createAtSec,
        duration: durationSec,
        source: MPBleFileUtil.kMemoPinRecordSource,
        isRemoved: false,
      ),
    );
    MPHomeNotification.notifyHomeListRefresh();
    if (runUploadQueue) {
      await MPAudioUploadManager.instance.uploadAllRecordingFiles(rightNowTranscribe: false);
    }
    return true;
  }
}

/// 解析 `e2c1a301` 无 Flag 的 `[Seq 4B BE][480B]` 帧流，检测 Seq 间隙并输出裸 Opus 包。
class _MPBleRtOpusBuffer {
  static bool isRetransmitCompletionPacket(List<int> p) {
    if (p.isEmpty || p[0] != MPNoteBleCommands.retransmitAudio) {
      return false;
    }
    if (p.length < 11) {
      return false;
    }
    final int nl = p[1] & 0xff;
    if (nl < 1 || nl > 32) {
      return false;
    }
    return p.length == 2 + nl + 8;
  }

  final List<int> _buf = <int>[];
  int _lastSeq = -1;

  Future<void> loadLastSeqFromSidecar(String opusPath) async {
    try {
      final File f = File('$opusPath.seq');
      if (!await f.exists()) {
        return;
      }
      final String line = (await f.readAsString()).trim();
      if (line.isEmpty) {
        return;
      }
      _lastSeq = int.parse(line);
    } catch (_) {
      _lastSeq = -1;
    }
  }

  Future<void> persistLastSeqSidecar(String opusPath) async {
    try {
      if (_lastSeq < 0) {
        return;
      }
      final File f = File('$opusPath.seq');
      await f.writeAsString('$_lastSeq', flush: true);
    } catch (e) {
      debugPrint('_MPBleRtOpusBuffer.persistLastSeqSidecar: $e');
    }
  }

  void feed(
    List<int> data, {
    required void Function(List<int> frame480) onFrame480,
    void Function(int startSeq, int endSeq)? onGap,
  }) {
    _buf.addAll(data);
    while (_buf.length >= 484) {
      final int seq = _readU32Be(_buf, 0);
      if (_lastSeq >= 0 && seq > _lastSeq + 1) {
        onGap?.call(_lastSeq + 1, seq - 1);
      }
      _lastSeq = seq;
      onFrame480(List<int>.from(_buf.sublist(4, 484)));
      _buf.removeRange(0, 484);
    }
  }

  List<List<int>> flushTailFrames() {
    if (_buf.length <= 4) {
      _buf.clear();
      return <List<int>>[];
    }
    if (_buf.length < 484) {
      final List<int> tail = List<int>.from(_buf.sublist(4));
      _buf.clear();
      return tail.isEmpty ? <List<int>>[] : <List<int>>[tail];
    }
    return <List<int>>[];
  }

  static int _readU32Be(List<int> b, int o) {
    return ((b[o] & 0xff) << 24) |
        ((b[o + 1] & 0xff) << 16) |
        ((b[o + 2] & 0xff) << 8) |
        (b[o + 3] & 0xff);
  }
}
