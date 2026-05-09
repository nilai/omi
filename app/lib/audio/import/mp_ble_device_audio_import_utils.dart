import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:memo_pin/audio/record/mp_audio_local_records_util.dart';

import '../../blu/ble_transport.dart';
import '../../blu/mp_bluetooth_connection_helper.dart';
import '../../blu/mp_note_ble_gatt_client.dart';
import '../../blu/note_device.dart';
import '../record/mp_audio_upload_manger.dart';
import 'mp_audio_import_utils.dart';

/// BLE 设备导出时的复制进度（当前文件序号、总数、0–100）。
typedef MPBleDeviceImportCopyProgress =
    void Function({required int fileIndex, required int fileTotal, required int progressPercent});

/// MemoPin 设备录音：拉列表 → BLE 导出至沙盒并登记 → 随即删设备端文件 → 逐条上传。
class MPBleDeviceAudioImportUtils {
  MPBleDeviceAudioImportUtils._();

  static const String _kSourceMemoPin = 'MemoPin';
  static const Duration _kIdleDone = Duration(seconds: 2);

  static Duration _maxExportWaitForFile(NoteFileInfo info) {
    final int sec = info.durationSeconds;
    if (sec <= 0) {
      return const Duration(seconds: 120);
    }
    final int capped = (sec * 5).clamp(60, 600);
    return Duration(seconds: capped);
  }

  /// 对 [transport] 执行完整导入流水线（进度类信息走 [debugPrint]）。
  static Future<void> syncUploadAndDeleteDeviceFiles({
    required BleTransport transport,
    required MPBleDeviceImportCopyProgress onSyncProgress,
  }) async {
    try {
      if (!await transport.isConnected()) {
        debugPrint('MPBleDeviceAudioImportUtils: Bluetooth is not connected.');
        return;
      }

      debugPrint('MPBleDeviceAudioImportUtils: fetching file list from device...');
      final List<NoteFileInfo> files = await MPBluetoothConnectionHelper.fetchMemoPinFileList(transport);
      if (files.isEmpty) {
        debugPrint('MPBleDeviceAudioImportUtils: no files on the device.');
        return;
      }

      debugPrint('MPBleDeviceAudioImportUtils: starting sync from device...');
      final int total = files.length;

      for (int i = 0; i < total; i++) {
        if (!await transport.isConnected()) {
          debugPrint('MPBleDeviceAudioImportUtils: Bluetooth disconnected during sync.');
          break;
        }

        final NoteFileInfo fi = files[i];
        debugPrint('MPBleDeviceAudioImportUtils: syncing file ${i + 1}/$total...');
        onSyncProgress(fileIndex: i + 1, fileTotal: total, progressPercent: 0);

        final MPNoteBleGattClient client = MPNoteBleGattClient(transport);
        try {
          final List<int>? bytes = await _collectExportPayloads(client: client, fileName: fi.name, info: fi);
          if (bytes == null || bytes.isEmpty) {
            debugPrint('MPBleDeviceAudioImportUtils: failed to sync: ${fi.name}');
            onSyncProgress(fileIndex: i + 1, fileTotal: total, progressPercent: 100);
            continue;
          }

          onSyncProgress(fileIndex: i + 1, fileTotal: total, progressPercent: 70);

          final String? path = await MPAudioImportUtils.writeExportBytesToSandbox(
            bytes: bytes,
            originalFileName: fi.name,
          );
          if (path == null) {
            debugPrint('MPBleDeviceAudioImportUtils: failed to save file: ${fi.name}');
            onSyncProgress(fileIndex: i + 1, fileTotal: total, progressPercent: 100);
            continue;
          }

          final File sandboxFile = File(path);
          final int? durAudio = await MPAudioImportUtils.readAudioDurationSeconds(path);
          int durationSec = (durAudio != null && durAudio > 0) ? durAudio : fi.durationSeconds;
          if (durationSec <= 0) {
            durationSec = 1;
          }
          final int createAtSec = (await sandboxFile.lastModified()).millisecondsSinceEpoch ~/ 1000;

          await MPAudioLocalRecordsUtil.instance.add(
            MPAudioLocalRecord(
              path: path,
              fileName: fi.name,
              createAt: createAtSec,
              duration: durationSec,
              source: _kSourceMemoPin,
              isRemoved: false,
            ),
          );

          if (await transport.isConnected()) {
            final bool deleted =
                await MPBluetoothConnectionHelper.deleteMemoPinFile(transport, fi.name);
            if (!deleted) {
              debugPrint('MPBleDeviceAudioImportUtils: could not delete on device: ${fi.name}');
            }else {
              debugPrint('MPBleDeviceAudioImportUtils: deleted on device: ${fi.name}');
            }
          } else {
            debugPrint(
              'MPBleDeviceAudioImportUtils: Bluetooth disconnected; skipped device delete for ${fi.name}.',
            );
          }

          onSyncProgress(fileIndex: i + 1, fileTotal: total, progressPercent: 100);
        } finally {
          await client.dispose();
        }
      }

      debugPrint('MPBleDeviceAudioImportUtils: uploading recordings...');
      await MPAudioUploadManager.instance.uploadAllRecordingFiles(rightNowTranscribe: false);
    } catch (e, st) {
      debugPrint('MPBleDeviceAudioImportUtils device import failed: $e\n$st');
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
        debugPrint('BLE export stream error: $e\n$st');
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
      debugPrint('BLE export collect failed: $e\n$st');
      idleTimer?.cancel();
      await sub.cancel();
      return null;
    }
  }
}
