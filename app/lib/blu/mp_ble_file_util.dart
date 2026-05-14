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
import 'note_device.dart';

/// BLE 设备导出复制进度（当前文件序号、总数、0–100）。
typedef MPBleFileUtilCopyProgress =
    void Function({required int fileIndex, required int fileTotal, required int progressPercent});

/// MemoPin 设备文件：列表拆分、沙盒落盘、Opus→MP3、本地记录与上传。
class MPBleFileUtil {
  MPBleFileUtil._();

  static const String _kSourceMemoPin = 'MemoPin';
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
            source: _kSourceMemoPin,
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
}
