import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../audio/import/mp_audio_import_utils.dart';
import '../audio/record/mp_audio_local_records_util.dart';
import '../audio/record/mp_home_audio_task_queue.dart';
import '../audio/record/mp_audio_upload_manger.dart';
import '../audio/record/mp_audio_upload_service.dart';
import '../common/mp_home_notification.dart';
import '../utils/mp_opus_to_mp3_util.dart';
import '../utils/mp_time_utils.dart';

import 'mp_ble_transport.dart';
import 'mp_ble_connection_helper.dart';
import 'mp_device_transport.dart';
import 'mp_note_ble_gatt_client.dart';
import 'mp_note_ble_protocol.dart';
import 'note_device.dart';

/// BLE 设备导出复制进度（当前文件序号、总数、0–100）。
typedef MPBleFileUtilCopyProgress =
    void Function({required int fileIndex, required int fileTotal, required int progressPercent});

/// 设备批量导入过程中尚未完整落库的文件痕迹（断连时清理）。
class _DeviceImportScratch {
  String? opusPath;
  String? txtPath;
  String? mp3Path;
  MPAudioLocalRecord? registeredRecord;

  void clear() {
    opusPath = null;
    txtPath = null;
    mp3Path = null;
    registeredRecord = null;
  }
}

class _DeviceSyncSession {
  _DeviceSyncSession(this.transport);

  final BleTransport transport;
  final Completer<void> abortCompleter = Completer<void>();
  final _DeviceImportScratch scratch = _DeviceImportScratch();
  final List<MPAudioLocalRecord> completedRecords = <MPAudioLocalRecord>[];
  StreamSubscription<MPDeviceTransportState>? connectionSub;
}

/// MemoPin 设备文件：列表拆分、沙盒落盘、Opus→MP3、本地记录与上传。
class MPBleFileUtil {
  MPBleFileUtil._();

  static const String kMemoPinRecordSource = 'MemoPin';
  static const String _kSandboxDirName = 'mp_memopin_device_audio';
  static const Duration _kIdleDone = Duration(seconds: 2);

  static _DeviceSyncSession? _activeDeviceSync;
  static List<MPAudioLocalRecord> _pendingUploadAfterAbort = <MPAudioLocalRecord>[];

  /// 中止进行中的设备文件导入，清理未完成文件；已成功登记项可通过 [takePendingUploadAfterAbort] 取出。
  static Future<void> cancelActiveDeviceSync() async {
    final _DeviceSyncSession? session = _activeDeviceSync;
    if (session == null) {
      return;
    }
    if (!session.abortCompleter.isCompleted) {
      session.abortCompleter.complete();
    }
    await _cleanupIncompleteDeviceImportScratch(session.scratch);
    session.scratch.clear();
    _pendingUploadAfterAbort = List<MPAudioLocalRecord>.from(session.completedRecords);
    debugPrint(
      '------>>>memopin cancelActiveDeviceSync: pendingUpload=${_pendingUploadAfterAbort.length}',
    );
  }

  /// 取回 [cancelActiveDeviceSync] 时本会话已完成登记、待上传的记录（取出后清空缓存）。
  static List<MPAudioLocalRecord> takePendingUploadAfterAbort() {
    final List<MPAudioLocalRecord> pending = List<MPAudioLocalRecord>.from(_pendingUploadAfterAbort);
    _pendingUploadAfterAbort = <MPAudioLocalRecord>[];
    return pending;
  }

  static bool _isDeviceSyncAborted() {
    final _DeviceSyncSession? session = _activeDeviceSync;
    return session != null && session.abortCompleter.isCompleted;
  }

  static Future<void> _endDeviceSyncSession(_DeviceSyncSession session) async {
    await session.connectionSub?.cancel();
    session.connectionSub = null;
    if (identical(_activeDeviceSync, session)) {
      _activeDeviceSync = null;
    }
  }

  static Future<void> _cleanupIncompleteDeviceImportScratch(_DeviceImportScratch scratch) async {
    final MPAudioLocalRecord? registered = scratch.registeredRecord;
    if (registered != null) {
      await MPAudioLocalRecordsUtil.instance.removeHard(registered);
      await MPAudioUploadService.deleteLocalRecordingArtifacts(registered.path);
      await _deleteLocalFileQuietly(registered.txtPath);
      final String? opus = scratch.opusPath?.trim();
      if (opus != null && opus.isNotEmpty && opus != registered.path.trim()) {
        await _deleteLocalFileQuietly(opus);
      }
      return;
    }
    await _deleteLocalFileQuietly(scratch.opusPath);
    await _deleteLocalFileQuietly(scratch.txtPath);
    await _deleteLocalFileQuietly(scratch.mp3Path);
  }

  static Future<void> _deleteLocalFileQuietly(String? path) async {
    final String trimmed = path?.trim() ?? '';
    if (trimmed.isEmpty) {
      return;
    }
    try {
      final File file = File(trimmed);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('MPBleFileUtil: delete local file failed ($trimmed): $e');
    }
  }

  /// 诊断用：打印本地音频 name / 大小 / 可读时长（及可选设备侧时长、导出字节数）。
  static Future<void> _debugPrintLocalAudioMeta(
    String stage,
    String filePath, {
    int? deviceDurationSec,
    int? exportedBytes,
  }) async {
    final String name = p.basename(filePath);
    int? sizeBytes;
    try {
      final File f = File(filePath);
      if (await f.exists()) {
        sizeBytes = await f.length();
      }
    } catch (_) {}
    final int? durationSec = await MPAudioImportUtils.readAudioDurationSeconds(filePath);
    final StringBuffer buf = StringBuffer(
      '------hjj>>>memopin syncDeviceOpusTxt: $stage name=$name sizeBytes=$sizeBytes durationSec=$durationSec',
    );
    if (deviceDurationSec != null) {
      buf.write(' deviceDurationSec=$deviceDurationSec');
    }
    if (exportedBytes != null) {
      buf.write(' exportedBytes=$exportedBytes');
    }
    debugPrint(buf.toString());
  }

  /// 应用 Documents 下 MemoPin 设备音频目录（导出 `.opus` / `.txt` / `.mp3`）。
  static Future<String> ensureMemoPinDeviceAudioDirectoryPath() async {
    debugPrint('------>>>memopin ensureMemoPinDeviceAudioDirectoryPath');
    final Directory docs = await getApplicationDocumentsDirectory();
    final String dir = p.join(docs.path, _kSandboxDirName);
    await Directory(dir).create(recursive: true);
    return dir;
  }

  /// 将裸 Opus 文件裁到 `(lastCompletedSeq + 1) × 480` 字节，去掉崩溃/断连后可能多写的残帧。
  static Future<void> trimRawOpusToLastCompletedSeq(String opusPath, int lastCompletedSeq) async {
    if (lastCompletedSeq < 0) {
      return;
    }
    final File file = File(opusPath);
    if (!await file.exists()) {
      return;
    }
    final int targetBytes = (lastCompletedSeq + 1) * MPNoteBleFileTransferConstants.opusFrameBytes;
    final int length = await file.length();
    if (length <= targetBytes) {
      return;
    }
    debugPrint(
      '------>>>memopin trimRawOpus: $opusPath ${length}B → ${targetBytes}B (lastSeq=$lastCompletedSeq)',
    );
    final RandomAccessFile raf = await file.open(mode: FileMode.write);
    try {
      await raf.truncate(targetBytes);
      await raf.flush();
    } finally {
      await raf.close();
    }
  }

  /// 实时边录边传 `.opus` 结束后：转 MP3 → 从设备导入同名 `.txt`（与 MP3 同目录）→ 写入 [MPAudioLocalRecord] →
  /// （可选）[onAfterMp3Converted]（宜在停录 notification 前调用，使导入耗时仍计为 recording）→ 删除设备端文件。
  ///
  /// 不上传；调用方使用 [MPAudioUploadManager.uploadRecords] 按返回的记录上传。
  static Future<MPAudioLocalRecord?> finalizeRealtimeOpusToLocalRecord({
    required String opusPath,
    String? deviceFileName,
    BleTransport? transport,
    Future<void> Function()? onAfterMp3Converted,
    bool deferDeviceFileCleanup = false,
  }) async {
    debugPrint('------>>>memopin finalizeRealtimeOpus: $opusPath deviceFile=$deviceFileName');
    final File opusFile = File(opusPath);
    if (!await opusFile.exists() || await opusFile.length() == 0) {
      debugPrint('MPBleFileUtil: realtime opus missing or empty: $opusPath');
      return null;
    }

    final String? mp3Path = await MPOpusToMp3Util.convertMemoPinBleOpusExportToMp3(opusPath);
    final File primary = File((mp3Path != null && mp3Path.isNotEmpty) ? mp3Path : opusPath);
    if (!await primary.exists()) {
      debugPrint('MPBleFileUtil: realtime finalize primary missing: $opusPath');
      return null;
    }

    final String audioPath = primary.path;
    final int? durAudio = await MPAudioImportUtils.readAudioDurationSeconds(audioPath);
    final int durationSec = (durAudio != null && durAudio > 0) ? durAudio : 1;
    final int createAtSec = MPTimeUtils.unixSecondsFromDateTime(await primary.lastModified());
    final String recordFileName = deviceFileName != null && deviceFileName.isNotEmpty
        ? deviceFileName
        : p.basename(opusPath);

    final BleTransport? ble = transport ?? MPBleConnectionHelper.backgroundBleTransport;

    String? txtPathOnPhone;
    String? deviceTxtFileName;
    final String? deviceOpusFileName = _deviceOpusFileNameForBleCleanup(deviceFileName, opusPath);
    // deferDeviceFileCleanup：停录后 Home 会立刻批量导入，此处不再占 GATT 拉 txt。
    if (!deferDeviceFileCleanup &&
        ble != null &&
        deviceOpusFileName != null &&
        deviceOpusFileName.isNotEmpty &&
        await _isTransportConnectedSafe(ble)) {
      final ({String? localTxtPath, String? deviceTxtName}) imported = await _importPairedTxtFromDeviceIfExists(
        transport: ble,
        opusFileName: deviceOpusFileName,
        localOutputDirectory: p.dirname(audioPath),
        skipPreListDelay: true,
      );
      txtPathOnPhone = imported.localTxtPath;
      deviceTxtFileName = imported.deviceTxtName;
    }

    final MPAudioLocalRecord record = MPAudioLocalRecord(
      path: audioPath,
      mp3Path: mp3Path,
      txtPath: txtPathOnPhone,
      fileName: recordFileName,
      createAt: createAtSec,
      duration: durationSec,
      source: kMemoPinRecordSource,
      isRemoved: false,
    );
    await MPAudioLocalRecordsUtil.instance.add(record);
    MPHomeNotification.notifyHomeListRefresh();

    if (onAfterMp3Converted != null) {
      await onAfterMp3Converted();
    }

    if (!deferDeviceFileCleanup &&
        ble != null &&
        deviceOpusFileName != null &&
        deviceOpusFileName.isNotEmpty &&
        await _isTransportConnectedSafe(ble)) {
      await _deleteDeviceFilesAfterRealtimeFinalize(
        transport: ble,
        deviceOpusFileName: deviceOpusFileName,
        deviceTxtFileName: txtPathOnPhone != null ? deviceTxtFileName : null,
      );
    }

    debugPrint(
      '------>>>memopin finalizeRealtimeOpus: local record path=$audioPath txtPath=$txtPathOnPhone '
      'deferCleanup=$deferDeviceFileCleanup',
    );
    return record;
  }

  /// 实时停录 [uploadRecords] 完成后，后台删除设备端 opus/txt（txt 已在登记前导入）。
  static Future<void> completeRealtimeDeviceFileCleanup({
    required BleTransport? transport,
    String? deviceFileName,
    required String opusPath,
    String? importedDeviceTxtFileName,
  }) async {
    final BleTransport? ble = transport ?? MPBleConnectionHelper.backgroundBleTransport;
    final String? deviceOpusFileName = _deviceOpusFileNameForBleCleanup(deviceFileName, opusPath);
    if (ble == null ||
        deviceOpusFileName == null ||
        deviceOpusFileName.isEmpty ||
        !await _isTransportConnectedSafe(ble)) {
      return;
    }
    try {
      await _deleteDeviceFilesAfterRealtimeFinalize(
        transport: ble,
        deviceOpusFileName: deviceOpusFileName,
        deviceTxtFileName: importedDeviceTxtFileName,
      );
    } catch (e, st) {
      debugPrint('------>>>memopin completeRealtimeDeviceFileCleanup failed: $e\n$st');
    }
  }

  /// 转 MP3、登记本地记录后，按 [uploadRecords] 上传（默认仅本条；[uploadAllPending] 为 true 时上传全部待传队列）。
  static Future<bool> finalizeRealtimeOpusToLocalRecordAndUpload({
    required String opusPath,
    String? deviceFileName,
    BleTransport? transport,
    bool runUploadQueue = true,
    bool uploadAllPending = false,
    Future<void> Function()? onAfterMp3Converted,
  }) async {
    final MPAudioLocalRecord? record = await finalizeRealtimeOpusToLocalRecord(
      opusPath: opusPath,
      deviceFileName: deviceFileName,
      transport: transport,
      onAfterMp3Converted: onAfterMp3Converted,
    );
    if (record == null) {
      return false;
    }
    if (runUploadQueue) {
      if (uploadAllPending) {
        await MPHomeAudioTaskQueue.instance.seedPendingUploadsFromLocal();
      } else {
        await MPHomeAudioTaskQueue.instance.enqueueUploadRecord(record, rightNowTranscribe: false);
      }
    }
    debugPrint('------>>>memopin finalizeRealtimeOpus: upload done');
    return true;
  }

  static Future<bool> _isTransportConnectedSafe(BleTransport transport) async {
    try {
      return await transport.isConnected();
    } catch (_) {
      return false;
    }
  }

  /// 设备端用于 `0x05` 删除的 `.opus` 文件名（优先 303 上报名）。
  static String? _deviceOpusFileNameForBleCleanup(String? deviceFileName, String localOpusPath) {
    final String trimmed = deviceFileName?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      if (trimmed.toLowerCase().endsWith('.opus')) {
        return trimmed;
      }
      return '$trimmed.opus';
    }
    final String base = p.basename(localOpusPath);
    if (base.toLowerCase().endsWith('.opus')) {
      return base;
    }
    return null;
  }

  /// 在设备文件列表中查找与 [opusFileName] 同 stem 的 `.txt`，导出并写入沙盒。
  ///
  /// [localOutputDirectory] 非空时 txt 与 MP3 等同目录；否则写入 [ensureMemoPinDeviceAudioDirectoryPath]。
  static Future<({String? localTxtPath, String? deviceTxtName})> _importPairedTxtFromDeviceIfExists({
    required BleTransport transport,
    required String opusFileName,
    String? localOutputDirectory,
    bool skipPreListDelay = false,
  }) async {
    try {
      if (!skipPreListDelay) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      final List<NoteFileInfo> allFiles = await MPBleConnectionHelper.fetchMemoPinFileList(transport);
      final List<NoteFileInfo> txtList = allFiles
          .where((NoteFileInfo e) => e.name.toLowerCase().endsWith('.txt'))
          .toList(growable: false);
      final NoteFileInfo? txtMatch = _findTxtForOpus(txtList, opusFileName);
      if (txtMatch == null) {
        debugPrint('------>>>memopin finalizeRealtimeOpus: no paired txt on device for $opusFileName');
        return (localTxtPath: null, deviceTxtName: null);
      }

      debugPrint('------>>>memopin finalizeRealtimeOpus: importing txt ${txtMatch.name}');
      final MPNoteBleGattClient txtClient = MPNoteBleGattClient(transport);
      String? localPath;
      try {
        final List<int>? txtBytes = await _collectExportPayloads(
          client: txtClient,
          fileName: txtMatch.name,
          info: txtMatch,
        );
        if (txtBytes == null || txtBytes.isEmpty) {
          debugPrint('MPBleFileUtil: realtime txt export empty: ${txtMatch.name}');
          return (localTxtPath: null, deviceTxtName: txtMatch.name);
        }
        final String deviceDir = (localOutputDirectory != null && localOutputDirectory.isNotEmpty)
            ? localOutputDirectory
            : await ensureMemoPinDeviceAudioDirectoryPath();
        localPath = await _writeBytesToDir(
          directoryPath: deviceDir,
          fileName: txtMatch.name,
          bytes: txtBytes,
        );
      } finally {
        await txtClient.dispose();
      }

      if (localPath == null) {
        debugPrint('MPBleFileUtil: realtime txt write failed: ${txtMatch.name}');
        return (localTxtPath: null, deviceTxtName: txtMatch.name);
      }
      debugPrint('------>>>memopin finalizeRealtimeOpus: txt saved $localPath');
      return (localTxtPath: localPath, deviceTxtName: txtMatch.name);
    } catch (e, st) {
      debugPrint('------>>>memopin finalizeRealtimeOpus: txt import failed $e\n$st');
      return (localTxtPath: null, deviceTxtName: null);
    }
  }

  /// 实时录音落盘登记后清理设备端文件：有配对 txt 且已导入则删 opus+txt，否则仅删 opus。
  static Future<void> _deleteDeviceFilesAfterRealtimeFinalize({
    required BleTransport transport,
    required String deviceOpusFileName,
    String? deviceTxtFileName,
  }) async {
    final String? txtName = deviceTxtFileName?.trim();
    if (txtName != null && txtName.isNotEmpty) {
      debugPrint(
        '------>>>memopin finalizeRealtimeOpus: delete device opus+txt opus=$deviceOpusFileName txt=$txtName',
      );
      await _deleteDeviceOpusAndPairedTxt(
        transport: transport,
        opusFileName: deviceOpusFileName,
        pairedTxtFileName: txtName,
      );
      return;
    }
    debugPrint('------>>>memopin finalizeRealtimeOpus: delete device opus only $deviceOpusFileName');
    final bool deleted = await deleteDeviceRecordingFile(transport, deviceOpusFileName);
    if (!deleted) {
      debugPrint('MPBleFileUtil: could not delete opus on device after realtime: $deviceOpusFileName');
    }
  }

  static Duration _maxExportWaitForFile(NoteFileInfo info) {
    final int sec = info.durationSeconds;
    if (sec <= 0) {
      return const Duration(seconds: 120);
    }
    final int capped = (sec * 5).clamp(60, 600);
    return Duration(seconds: capped);
  }

  /// 设备 import 进度同步至回调与 [MPHomeAudioTaskQueue]。
  static void _reportDeviceImportProgress(
    MPBleFileUtilCopyProgress onSyncProgress, {
    required int fileIndex,
    required int fileTotal,
    required int progressPercent,
  }) {
    onSyncProgress(fileIndex: fileIndex, fileTotal: fileTotal, progressPercent: progressPercent);
    MPHomeAudioTaskQueue.instance.reportImportProgress(
      fileIndex: fileIndex,
      fileTotal: fileTotal,
      progressPercent: progressPercent,
    );
  }

  /// 拉取列表 → 按 Opus 逐条导出 `.opus` 与同名 `.txt` 至 [ensureMemoPinDeviceAudioDirectoryPath] → 转 MP3 →
  /// 写入 [MPAudioLocalRecord]（含 [MPAudioLocalRecord.mp3Path]、[MPAudioLocalRecord.txtPath]、转码后主路径）→
  /// 删除设备端对应 `.opus` 与同名 `.txt`（若存在）→ [MPHomeNotification.notifyHomeListRefresh] → 上传队列。
  static Future<void> syncDeviceOpusTxtToSandboxRegisterAndUpload({
    required BleTransport transport,
    required MPBleFileUtilCopyProgress onSyncProgress,
  }) async {
    debugPrint('------>>>memopin syncDeviceOpusTxt: begin deviceId=${transport.deviceId}');
    if (_activeDeviceSync != null) {
      debugPrint('MPBleFileUtil: device import already in progress.');
      return;
    }

    final _DeviceSyncSession session = _DeviceSyncSession(transport);
    _activeDeviceSync = session;
    _pendingUploadAfterAbort = <MPAudioLocalRecord>[];
    var syncAborted = false;

    try {
      session.connectionSub = transport.connectionStateStream.listen((MPDeviceTransportState s) {
        if (s == MPDeviceTransportState.disconnected || s == MPDeviceTransportState.disconnecting) {
          unawaited(cancelActiveDeviceSync());
        }
      });

      if (!await transport.isConnected()) {
        debugPrint('------>>>memopin syncDeviceOpusTxt: not connected, abort');
        debugPrint('MPBleFileUtil: Bluetooth is not connected.');
        return;
      }

      debugPrint('MPBleFileUtil: fetching file list from device...');
      final List<NoteFileInfo> allFiles = await MPBleConnectionHelper.fetchMemoPinFileList(transport);
      if (_isDeviceSyncAborted()) {
        syncAborted = true;
        return;
      }
      debugPrint('------>>>memopin syncDeviceOpusTxt: file list total=${allFiles.length}');
      if (allFiles.isEmpty) {
        debugPrint('MPBleFileUtil: no files on the device.');
        return;
      }

      final List<NoteFileInfo> zeroDurationOpusList = _zeroDurationOpusList(allFiles);
      final List<NoteFileInfo> opusList = _filterOpusListForDeviceSync(allFiles);
      final Set<String> zeroDurationOpusStems = zeroDurationOpusList
          .map((NoteFileInfo e) => p.basenameWithoutExtension(e.name).toLowerCase())
          .toSet();
      final List<NoteFileInfo> txtList = allFiles
          .where((NoteFileInfo e) => e.name.toLowerCase().endsWith('.txt'))
          .where(
            (NoteFileInfo e) =>
                !zeroDurationOpusStems.contains(p.basenameWithoutExtension(e.name).toLowerCase()),
          )
          .toList(growable: false);

      if (zeroDurationOpusList.isNotEmpty) {
        debugPrint(
          '------>>>memopin syncDeviceOpusTxt: excluded zeroDurationOpus=${zeroDurationOpusList.length} '
          'from import total',
        );
      }

      if (opusList.isEmpty) {
        debugPrint('------>>>memopin syncDeviceOpusTxt: no opus files');
        debugPrint('MPBleFileUtil: no opus files on the device.');
        if (!_isDeviceSyncAborted() && zeroDurationOpusList.isNotEmpty) {
          await _deleteZeroDurationDeviceFiles(
            transport: transport,
            allFiles: allFiles,
            zeroDurationOpusList: zeroDurationOpusList,
          );
        }
        return;
      }

      final String deviceDir = await ensureMemoPinDeviceAudioDirectoryPath();
      debugPrint('------>>>memopin syncDeviceOpusTxt: opus=${opusList.length} txt=${txtList.length} dir=$deviceDir');

      final int total = opusList.length;
      MPHomeAudioTaskQueue.instance.beginImportBatch(total);
      for (int i = 0; i < total; i++) {
        if (_isDeviceSyncAborted() || !await transport.isConnected()) {
          syncAborted = true;
          debugPrint('------>>>memopin syncDeviceOpusTxt: disconnected mid-sync at index=${i + 1}/$total');
          debugPrint('MPBleFileUtil: Bluetooth disconnected during sync.');
          break;
        }

        session.scratch.clear();
        final NoteFileInfo opusInfo = opusList[i];
        debugPrint('------>>>memopin syncDeviceOpusTxt: processing [$i+1/$total] ${opusInfo.name}');
        _reportDeviceImportProgress(onSyncProgress, fileIndex: i + 1, fileTotal: total, progressPercent: 0);

        final MPNoteBleGattClient opusClient = MPNoteBleGattClient(transport);
        try {
          final List<int>? opusBytes =
              await _collectExportPayloads(client: opusClient, fileName: opusInfo.name, info: opusInfo);
          if (_isDeviceSyncAborted()) {
            syncAborted = true;
            break;
          }
          if (opusBytes == null || opusBytes.isEmpty) {
            debugPrint('------>>>memopin syncDeviceOpusTxt: export opus empty ${opusInfo.name}');
            debugPrint('MPBleFileUtil: failed to export opus: ${opusInfo.name}');
            _reportDeviceImportProgress(onSyncProgress, fileIndex: i + 1, fileTotal: total, progressPercent: 100);
            MPHomeAudioTaskQueue.instance.skipImportFile();
            continue;
          }

          _reportDeviceImportProgress(onSyncProgress, fileIndex: i + 1, fileTotal: total, progressPercent: 35);

          final String? opusPath = await _writeBytesToDir(
            directoryPath: deviceDir,
            fileName: opusInfo.name,
            bytes: opusBytes,
          );

          if (opusPath == null) {
            debugPrint('------>>>memopin syncDeviceOpusTxt: write opus failed ${opusInfo.name}');
            debugPrint('MPBleFileUtil: failed to write opus: ${opusInfo.name}');
            _reportDeviceImportProgress(onSyncProgress, fileIndex: i + 1, fileTotal: total, progressPercent: 100);
            MPHomeAudioTaskQueue.instance.skipImportFile();
            continue;
          }
          session.scratch.opusPath = opusPath;
          await _debugPrintLocalAudioMeta(
            'opus imported',
            opusPath,
            deviceDurationSec: opusInfo.durationSeconds,
            exportedBytes: opusBytes.length,
          );

          if (_isDeviceSyncAborted()) {
            syncAborted = true;
            break;
          }

          String? txtPathWritten;
          final NoteFileInfo? txtMatch = _findTxtForOpus(txtList, opusInfo.name);
          if (txtMatch != null) {
            final MPNoteBleGattClient txtClient = MPNoteBleGattClient(transport);
            try {
              final List<int>? txtBytes =
                  await _collectExportPayloads(client: txtClient, fileName: txtMatch.name, info: txtMatch);
              if (_isDeviceSyncAborted()) {
                syncAborted = true;
                break;
              }
              if (txtBytes != null && txtBytes.isNotEmpty) {
                txtPathWritten = await _writeBytesToDir(
                  directoryPath: deviceDir,
                  fileName: txtMatch.name,
                  bytes: txtBytes,
                );
                session.scratch.txtPath = txtPathWritten;
              }
            } finally {
              await txtClient.dispose();
            }
          }

          if (syncAborted || _isDeviceSyncAborted()) {
            syncAborted = true;
            break;
          }

          _reportDeviceImportProgress(onSyncProgress, fileIndex: i + 1, fileTotal: total, progressPercent: 55);

          final String? mp3Path = await MPOpusToMp3Util.convertMemoPinBleOpusExportToMp3(opusPath);
          session.scratch.mp3Path = mp3Path;
          final File primaryFile = File((mp3Path != null && mp3Path.isNotEmpty) ? mp3Path : opusPath);
          if (!await primaryFile.exists()) {
            debugPrint('------>>>memopin syncDeviceOpusTxt: primary missing after convert ${opusInfo.name}');
            debugPrint('MPBleFileUtil: primary audio missing after convert: ${opusInfo.name}');
            _reportDeviceImportProgress(onSyncProgress, fileIndex: i + 1, fileTotal: total, progressPercent: 100);
            MPHomeAudioTaskQueue.instance.skipImportFile();
            continue;
          }
          if (mp3Path != null && mp3Path.isNotEmpty) {
            await _debugPrintLocalAudioMeta('opus→mp3', mp3Path);
          } else {
            debugPrint(
              '------>>>memopin syncDeviceOpusTxt: opus→mp3 failed, fallback primary=${p.basename(opusPath)}',
            );
          }

          if (_isDeviceSyncAborted()) {
            syncAborted = true;
            break;
          }

          _reportDeviceImportProgress(onSyncProgress, fileIndex: i + 1, fileTotal: total, progressPercent: 80);

          final String audioPathForRecord = primaryFile.path;
          final int? durAudio = await MPAudioImportUtils.readAudioDurationSeconds(audioPathForRecord);
          int durationSec = (durAudio != null && durAudio > 0) ? durAudio : opusInfo.durationSeconds;
          if (durationSec <= 0) {
            durationSec = 1;
          }
          final int createAtSec = MPTimeUtils.unixSecondsFromDateTime(await primaryFile.lastModified());

          final MPAudioLocalRecord record = MPAudioLocalRecord(
            path: audioPathForRecord,
            mp3Path: mp3Path,
            txtPath: txtPathWritten,
            fileName: opusInfo.name,
            createAt: createAtSec,
            duration: durationSec,
            source: kMemoPinRecordSource,
            isRemoved: false,
          );
          session.scratch.registeredRecord = record;
          await MPAudioLocalRecordsUtil.instance.add(record);
          session.completedRecords.add(record);
          session.scratch.registeredRecord = null;
          session.scratch.clear();

          MPHomeNotification.notifyHomeListRefresh();

          if (await transport.isConnected()) {
            await _deleteDeviceOpusAndPairedTxt(
              transport: transport,
              gattClient: opusClient,
              opusFileName: opusInfo.name,
              pairedTxtFileName: txtMatch?.name,
            );
          } else {
            debugPrint('MPBleFileUtil: Bluetooth disconnected; skipped device delete for ${opusInfo.name}.');
          }

          _reportDeviceImportProgress(onSyncProgress, fileIndex: i + 1, fileTotal: total, progressPercent: 100);
          await MPHomeAudioTaskQueue.instance.completeImportFile(record, source: kMemoPinRecordSource);
        } finally {
          if (syncAborted || _isDeviceSyncAborted()) {
            await _cleanupIncompleteDeviceImportScratch(session.scratch);
            session.scratch.clear();
          }
          await opusClient.dispose();
        }
        if (syncAborted || _isDeviceSyncAborted()) {
          syncAborted = true;
          break;
        }
      }

      if (syncAborted || _isDeviceSyncAborted()) {
        debugPrint('------>>>memopin syncDeviceOpusTxt: aborted');
        MPHomeAudioTaskQueue.instance.cancelAllImportTasks();
        return;
      }

      if (zeroDurationOpusList.isNotEmpty) {
        await _deleteZeroDurationDeviceFiles(
          transport: transport,
          allFiles: allFiles,
          zeroDurationOpusList: zeroDurationOpusList,
        );
      }

      debugPrint('------>>>memopin syncDeviceOpusTxt: done');
    } catch (e, st) {
      syncAborted = true;
      MPHomeAudioTaskQueue.instance.cancelAllImportTasks();
      debugPrint('------>>>memopin syncDeviceOpusTxt: FAILED $e\n$st');
      debugPrint('MPBleFileUtil device import failed: $e\n$st');
    } finally {
      if (syncAborted || _isDeviceSyncAborted()) {
        await _cleanupIncompleteDeviceImportScratch(session.scratch);
        session.scratch.clear();
      }
      await _endDeviceSyncSession(session);
    }
  }

  /// 已确认在录音时，从文件列表解析「进行中」Opus（`durationSeconds == 0`）；取 index 最大者。
  /// 不可单独用本结果判定是否在录音。
  static NoteFileInfo? findInProgressRecordingOpus(List<NoteFileInfo> allFiles) {
    NoteFileInfo? best;
    for (final NoteFileInfo info in allFiles) {
      if (!info.name.toLowerCase().endsWith('.opus')) {
        continue;
      }
      if (info.durationSeconds > 0) {
        continue;
      }
      if (best == null || info.index > best.index) {
        best = info;
      }
    }
    return best;
  }

  /// 文件列表中 index 最大的 Opus（设备录音中时长可能已 > 0，此时作候选）。
  static NoteFileInfo? findLatestOpusFile(List<NoteFileInfo> allFiles) {
    NoteFileInfo? best;
    for (final NoteFileInfo info in allFiles) {
      if (!info.name.toLowerCase().endsWith('.opus')) {
        continue;
      }
      if (best == null || info.index > best.index) {
        best = info;
      }
    }
    return best;
  }

  /// 按设备端文件名在列表中查找；未命中时合成 [NoteFileInfo] 供导出。
  static NoteFileInfo resolveOpusFileInfo(List<NoteFileInfo> allFiles, String deviceFileName) {
    final String target = deviceFileName.trim();
    for (final NoteFileInfo info in allFiles) {
      if (info.name.toLowerCase() == target.toLowerCase()) {
        return info;
      }
    }
    return NoteFileInfo(index: 0, name: target, durationSeconds: 0);
  }

  /// 裸 Opus 字节数对应的最后完成 Seq（无完整帧时返回 -1）。
  static int lastCompletedSeqForRawOpusBytes(int byteLength) {
    if (byteLength < MPNoteBleFileTransferConstants.opusFrameBytes) {
      return -1;
    }
    return (byteLength ~/ MPNoteBleFileTransferConstants.opusFrameBytes) - 1;
  }

  /// 导出设备端单个 Opus 至 [ensureMemoPinDeviceAudioDirectoryPath]，返回本地路径。
  static Future<String?> exportDeviceOpusFileToSandbox({
    required BleTransport transport,
    required NoteFileInfo info,
  }) async {
    return MPBleConnectionHelper.runMemoPinGattExclusive(() async {
      final String dir = await ensureMemoPinDeviceAudioDirectoryPath();
      final MPNoteBleGattClient client = MPNoteBleGattClient(transport);
      try {
        final List<int>? bytes =
            await _collectExportPayloads(client: client, fileName: info.name, info: info);
        if (bytes == null || bytes.isEmpty) {
          return null;
        }
        return _writeBytesToDir(directoryPath: dir, fileName: info.name, bytes: bytes);
      } finally {
        await client.dispose();
      }
    });
  }

  /// 设备文件列表中 `durationSeconds == 0` 的 Opus（不参与导入总数，导出完成后从设备删除）。
  static List<NoteFileInfo> _zeroDurationOpusList(List<NoteFileInfo> allFiles) {
    return allFiles
        .where(
          (NoteFileInfo e) =>
              e.name.toLowerCase().endsWith('.opus') && e.durationSeconds <= 0,
        )
        .toList(growable: false);
  }

  /// 导出完成后删除设备端零时长 Opus 及列表中同名 stem 的 `.txt`。
  static Future<void> _deleteZeroDurationDeviceFiles({
    required BleTransport transport,
    required List<NoteFileInfo> allFiles,
    required List<NoteFileInfo> zeroDurationOpusList,
  }) async {
    if (zeroDurationOpusList.isEmpty) {
      return;
    }
    if (!await transport.isConnected()) {
      debugPrint('MPBleFileUtil: skip zero-duration delete — Bluetooth disconnected.');
      return;
    }

    final List<NoteFileInfo> txtList = allFiles
        .where((NoteFileInfo e) => e.name.toLowerCase().endsWith('.txt'))
        .toList(growable: false);

    debugPrint(
      '------>>>memopin syncDeviceOpusTxt: delete zeroDurationOpus count=${zeroDurationOpusList.length}',
    );
    for (final NoteFileInfo opusInfo in zeroDurationOpusList) {
      final NoteFileInfo? txtMatch = _findTxtForOpus(txtList, opusInfo.name);
      await _deleteDeviceOpusAndPairedTxt(
        transport: transport,
        opusFileName: opusInfo.name,
        pairedTxtFileName: txtMatch?.name,
      );
    }
  }

  /// 设备批量导入用 Opus 列表：仅 `.opus`、时长 > 0、按文件名（忽略大小写）去重（保留时长更长者，相同时保留 index 更大者）。
  static List<NoteFileInfo> _filterOpusListForDeviceSync(List<NoteFileInfo> allFiles) {
    final List<NoteFileInfo> opusOnly = allFiles
        .where((NoteFileInfo e) => e.name.toLowerCase().endsWith('.opus'))
        .toList(growable: false);
    final int rawOpus = opusOnly.length;

    final Map<String, NoteFileInfo> dedupedByName = <String, NoteFileInfo>{};
    var skippedZeroDuration = 0;
    for (final NoteFileInfo info in opusOnly) {
      if (info.durationSeconds <= 0) {
        skippedZeroDuration++;
        continue;
      }
      final String key = info.name.toLowerCase();
      final NoteFileInfo? existing = dedupedByName[key];
      if (existing == null) {
        dedupedByName[key] = info;
        continue;
      }
      final bool preferCurrent = info.durationSeconds > existing.durationSeconds ||
          (info.durationSeconds == existing.durationSeconds && info.index > existing.index);
      if (preferCurrent) {
        dedupedByName[key] = info;
      }
    }

    final List<NoteFileInfo> result = dedupedByName.values.toList(growable: false)
      ..sort((NoteFileInfo a, NoteFileInfo b) => a.index.compareTo(b.index));
    final int skippedDup = rawOpus - skippedZeroDuration - result.length;
    if (skippedZeroDuration > 0 || skippedDup > 0) {
      debugPrint(
        '------>>>memopin filterOpusForDeviceSync: raw=$rawOpus importable=${result.length} '
        'skippedZeroDuration=$skippedZeroDuration skippedDuplicateName=$skippedDup',
      );
    }
    return result;
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

  /// 导入成功后删除设备端 `.opus`；若列表中存在同名 stem 的 `.txt` 则一并删除。
  ///
  /// [gattClient] 可与导出共用同一实例，避免 303 订阅反复销毁导致错过 `0x05` 应答。
  static Future<void> _deleteDeviceOpusAndPairedTxt({
    required BleTransport transport,
    required String opusFileName,
    String? pairedTxtFileName,
    MPNoteBleGattClient? gattClient,
  }) async {
    final bool opusDeleted = await deleteDeviceRecordingFile(
      transport,
      opusFileName,
      client: gattClient,
    );
    debugPrint('------>>>memopin syncDeviceOpusTxt: device delete $opusFileName → $opusDeleted');
    if (!opusDeleted) {
      debugPrint('MPBleFileUtil: could not delete opus on device: $opusFileName');
    }

    final String? txtName = pairedTxtFileName?.trim();
    if (txtName == null || txtName.isEmpty) {
      return;
    }

    final bool txtDeleted = await deleteDeviceRecordingFile(
      transport,
      txtName,
      client: gattClient,
    );
    debugPrint('------>>>memopin syncDeviceOpusTxt: device delete $txtName → $txtDeleted');
    if (!txtDeleted) {
      debugPrint('MPBleFileUtil: could not delete txt on device: $txtName');
    }
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
        debugPrint('------>>>memopin _collectExportPayloads stream error: $e\n$st');
        debugPrint('MPBleFileUtil BLE export stream error: $e\n$st');
      },
    );

    try {
      final bool accepted = await client.requestFileExport(fileName);
      if (!accepted) {
        debugPrint('------>>>memopin _collectExportPayloads: requestFileExport rejected $fileName');
        idleTimer?.cancel();
        await sub.cancel();
        return null;
      }

      final Future<void>? abortFuture = _activeDeviceSync?.abortCompleter.future;
      final List<Future<void>> waitTargets = <Future<void>>[
        idleDone.future,
        Future<void>.delayed(_maxExportWaitForFile(info)),
      ];
      if (abortFuture != null) {
        waitTargets.add(abortFuture);
      }
      await Future.any<void>(waitTargets);
      idleTimer?.cancel();

      if (_isDeviceSyncAborted()) {
        await sub.cancel();
        debugPrint('------>>>memopin _collectExportPayloads: aborted $fileName');
        return null;
      }

      for (final List<int> tail in client.flushFileExportAssemblerTail()) {
        buffer.addAll(tail);
      }
      await sub.cancel();

      if (_isDeviceSyncAborted()) {
        return null;
      }

      final bool transferComplete = await client.waitForUploadTransferComplete(
        timeout: _maxExportWaitForFile(info),
      );
      if (!transferComplete) {
        debugPrint('------>>>memopin _collectExportPayloads: no 0x04 0x02 for $fileName (idle-only end)');
      }

      if (_isDeviceSyncAborted()) {
        return null;
      }

      if (!receivedPayload && buffer.isEmpty) {
        debugPrint('------>>>memopin _collectExportPayloads: no payload $fileName');
        return null;
      }
      debugPrint('------>>>memopin _collectExportPayloads: ok $fileName bytes=${buffer.length}');
      return buffer;
    } catch (e, st) {
      debugPrint('------>>>memopin _collectExportPayloads: exception $fileName $e\n$st');
      debugPrint('MPBleFileUtil BLE export collect failed: $e\n$st');
      idleTimer?.cancel();
      await sub.cancel();
      return null;
    }
  }

  // —— 设备端文件删除 / 本地沙盒删除 ——

  /// 删除设备端指定文件名（命令 `0x05` + UTF-8 文件名）。
  ///
  /// [client] 非空时复用导出阶段的 GATT 客户端（勿在此处 [MPNoteBleGattClient.dispose]）。
  static Future<bool> deleteDeviceRecordingFile(
    BleTransport transport,
    String fileName, {
    MPNoteBleGattClient? client,
  }) async {
    return MPBleConnectionHelper.runMemoPinGattExclusive(() async {
      final bool ownClient = client == null;
      final MPNoteBleGattClient gatt = client ?? MPNoteBleGattClient(transport);
      try {
        for (int attempt = 1; attempt <= 3; attempt++) {
          debugPrint('------>>>memopin deleteDeviceRecordingFile: attempt=$attempt $fileName');
          final bool ok = await gatt.deleteFile(fileName);
          if (ok) {
            debugPrint('------>>>memopin deleteDeviceRecordingFile: result=true $fileName');
            return true;
          }
          if (attempt < 3) {
            await Future<void>.delayed(const Duration(milliseconds: 200));
          }
        }
        debugPrint('------>>>memopin deleteDeviceRecordingFile: result=false $fileName');
        return false;
      } finally {
        if (ownClient) {
          await gatt.dispose();
        }
      }
    });
  }

  /// 显式发起的实时 Opus 会话（非 [MPBleRecordingWatcher] 自动路径）。
  ///
  /// 与 Watcher 区别见 [MPBleLiveRecordingSession] 文档：Watcher 在连接后自动监听 303/301；
  /// 本 API 需业务在「开始录」时主动调用，并自行 [MPBleLiveRecordingSession.finalizeToMp3AndRecord]。
  ///
  /// 开启实时 Opus 写入（`e2c1a301`）；[kind] 决定 `0x0D` 为仅录音或边录边传；[appendResume] 为 `true` 时续写并尝试 Seq 间隙补传。
  ///
  /// [opusFileName] 须含 `.opus` 后缀，写入目录为 [ensureMemoPinDeviceAudioDirectoryPath]。
  static Future<MPBleLiveRecordingSession?> startLiveOpusRecording({
    required BleTransport transport,
    required MPBleLiveRecordingKind kind,
    required bool appendResume,
    required String opusFileName,
  }) async {
    debugPrint(
      '------>>>memopin startLiveOpusRecording: kind=$kind append=$appendResume name=$opusFileName device=${transport.deviceId}',
    );
    try {
      if (!await transport.isConnected()) {
        debugPrint('------>>>memopin startLiveOpusRecording: transport not connected');
        return null;
      }
    } catch (_) {
      debugPrint('------>>>memopin startLiveOpusRecording: not connected');
      return null;
    }
    if (!opusFileName.toLowerCase().endsWith('.opus')) {
      debugPrint('------>>>memopin startLiveOpusRecording: invalid file name (need .opus)');
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
      debugPrint('------>>>memopin startLiveOpusRecording: session._start failed');
      await session.dispose();
      return null;
    }
    debugPrint('------>>>memopin startLiveOpusRecording: session started path=${session.opusPath}');
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

/// 业务侧显式控制的实时录音写入会话。
///
/// **与 [MPBleRecordingWatcher] 的关系（边界说明）**：
/// - **Watcher**：连接 MemoPin 后由 [MPBleConnectionHelper] 自动 attach，监听设备 303 开始/停止与 301 边录边传，
///   含断连续传 checkpoint、停止后 [finalizeRealtimeOpusToLocalRecordAndUpload]。
/// - **本 Session**：若产品要在 App 内按钮「开始/结束」并指定文件名时，才需调用 [startLiveOpusRecording]；
///   二者不要对同一 transport 重复开 301 落盘，否则可能双写。默认产品路径只用 Watcher 即可。
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
  final MPBleRtOpusBuffer _buffer = MPBleRtOpusBuffer();
  String? _activeFileNameForRetransmit;

  /// 是否已成功订阅并开始写入。
  bool _started = false;

  /// 底层传输（用于外部判断连接等）。
  BleTransport get transport => _transport;

  Future<bool> _start() async {
    debugPrint('------>>>memopin MPBleLiveRecordingSession._start: mode=$kind append=$appendResume');
    final MPNoteBleGattClient cmd = MPNoteBleGattClient(_transport);
    try {
      final int modeByte = kind == MPBleLiveRecordingKind.memo
          ? MPNoteBleRecordingTransportModes.recordOnly
          : MPNoteBleRecordingTransportModes.recordAndStream;
      final bool modeOk = await cmd.setRecordingTransportMode(modeByte);
      if (!modeOk) {
        debugPrint('------>>>memopin MPBleLiveRecordingSession._start: setRecordingTransportMode failed mode=$modeByte');
        debugPrint('MPBleLiveRecordingSession: setRecordingTransportMode failed');
        return false;
      }
      debugPrint('------>>>memopin MPBleLiveRecordingSession._start: transport mode OK modeByte=$modeByte');
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

    _audioSub = (await _transport.getRawCharacteristicNotifyStreamWhenReady(
          MPNoteBleUUIDs.service.toString(),
          MPNoteBleUUIDs.audioData.toString(),
        ))
        .listen(_onAudio301, onError: (Object e) => debugPrint('MPBleLiveRecordingSession audio301: $e'));

    _retransmitSub = _transport
        .getCharacteristicStream(MPNoteBleUUIDs.service.toString(), MPNoteBleUUIDs.response.toString())
        .listen(_onResponse303Retransmit, onError: (_) {});

    _started = true;
    debugPrint('------>>>memopin MPBleLiveRecordingSession._start: subscriptions ready opusPath=$opusPath');
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
    if (MPBleRtOpusBuffer.isRetransmitCompletionPacket(p)) {
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
    debugPrint('------>>>memopin MPBleLiveRecordingSession.dispose');
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
    debugPrint('------>>>memopin MPBleLiveRecordingSession.finalizeToMp3AndRecord runUpload=$runUploadQueue');
    if (!_started) {
      debugPrint('------>>>memopin MPBleLiveRecordingSession.finalize: not started');
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

    return MPBleFileUtil.finalizeRealtimeOpusToLocalRecordAndUpload(
      opusPath: opusPath,
      deviceFileName: p.basename(opusPath),
      transport: _transport,
      runUploadQueue: runUploadQueue,
    );
  }
}

/// 解析 `e2c1a301` 无 Flag 的 `[Seq 4B BE][480B]` 帧流，检测 Seq 间隙并输出裸 Opus 包。
///
/// 供 [MPBleLiveRecordingSession]、[MPBleRecordingWatcher] 边录边传与重连续传共用。
class MPBleRtOpusBuffer {
  /// 是否为 `0x20` 补传完成包（无音频载荷）。
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

  /// 最近完成的 Seq（-1 表示尚无帧）；与 `.seq` sidecar 一致。
  int get lastCompletedSeq => _lastSeq;

  /// 新录音会话开始前清空缓冲（不影响 sidecar 文件）。
  void reset() {
    _buf.clear();
    _lastSeq = -1;
  }

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
      debugPrint('MPBleRtOpusBuffer.persistLastSeqSidecar: $e');
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
