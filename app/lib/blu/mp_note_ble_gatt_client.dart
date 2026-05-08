import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'ble_transport.dart';
import 'mp_note_ble_protocol.dart';
import 'note_device.dart';

/// 将 `recordFile` 特征上的原始通知重组为 Opus 帧（480B）或透传文本字节（与 `ble/note_ble_transport.dart` 行为对齐）。
class MPNoteBleFilePayloadAssembler {
  /// [fileName] 用于判断是否 `.txt` 纯字节流模式。
  MPNoteBleFilePayloadAssembler({required String fileName})
      : _rawTxt = fileName.toLowerCase().endsWith('.txt');

  static const int _chunkSize = 484;
  static const int _seqSize = 4;

  final bool _rawTxt;
  List<int> _buffer = <int>[];

  /// 是否在导出 `.txt` 时直接输出通知载荷。
  bool get isRawTxtMode => _rawTxt;

  /// 重置缓冲区（开始新的导出前应调用）。
  void reset() => _buffer.clear();

  /// 喂入一帧 BLE 通知，输出 0 或多个载荷块（Opus 帧或文本片段）。
  List<List<int>> push(List<int> data) {
    if (_rawTxt) {
      return <List<int>>[List<int>.from(data)];
    }
    _buffer.addAll(data);
    final List<List<int>> out = <List<int>>[];
    while (_buffer.length >= _chunkSize) {
      out.add(_buffer.sublist(_seqSize, _chunkSize));
      _buffer = List<int>.from(_buffer.sublist(_chunkSize));
    }
    return out;
  }

  /// 流传输静止后调用：输出 Opus 模式下末尾不足一整帧的字节（不含 txt 透传模式）。
  List<List<int>> flushTail() {
    if (_rawTxt) {
      return <List<int>>[];
    }
    if (_buffer.length <= _seqSize) {
      _buffer.clear();
      return <List<int>>[];
    }
    if (_buffer.length < _chunkSize) {
      final List<int> tail = List<int>.from(_buffer.sublist(_seqSize));
      _buffer.clear();
      return tail.isEmpty ? <List<int>>[] : <List<int>>[tail];
    }
    return <List<int>>[];
  }
}

enum _AwaitKind { none, generic, fileList }

/// 基于已连接的 [BleTransport]，按 Note 协议发送命令并解析响应；文件导出通过 [recordFilePayloadStream] 订阅。
///
/// 使用完毕后请调用 [dispose] 释放对响应流的订阅。
class MPNoteBleGattClient {
  /// 创建客户端（尚未订阅响应流，首次发送命令前会建立订阅）。
  MPNoteBleGattClient(this._transport);

  final BleTransport _transport;

  static const int _kFileListTimeoutMs = 500;

  StreamSubscription<List<int>>? _responseSub;
  Completer<List<int>>? _responseCompleter;
  _AwaitKind _awaitKind = _AwaitKind.none;

  final List<List<int>> _fileListPackets = <List<int>>[];
  Timer? _packetTimeoutTimer;

  /// 用于文件导出 payload 组装的装配器；通过 [prepareFileExport] 配置。
  MPNoteBleFilePayloadAssembler? _fileAssembler;

  /// 释放订阅；导出进行中请先取消对 payload 流的监听。
  Future<void> dispose() async {
    _cancelPacketTimeout();
    await _responseSub?.cancel();
    _responseSub = null;
    _fileListPackets.clear();
    _responseCompleter = null;
    _awaitKind = _AwaitKind.none;
    _fileAssembler = null;
  }

  /// 查询电量（命令 `0xE1`）。
  ///
  /// 响应：`E1` + 电量% + 可选充电状态字节。
  Future<MPNoteBatteryReading?> readBattery({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final List<int> response = await _sendCommandWithResponse(
      <int>[MPNoteBleCommands.queryBattery],
      awaitKind: _AwaitKind.generic,
      timeout: timeout,
    );
    if (response.length >= 2 && response[0] == MPNoteBleCommands.queryBattery) {
      final int pct = response[1].clamp(0, 100);
      final int? charging =
          response.length >= 3 ? response[2] : null;
      return MPNoteBatteryReading(percent: pct, chargingState: charging);
    }
    return null;
  }

  /// 获取设备端录音文件列表（命令 `0x03`，支持多包拼接）。
  Future<List<NoteFileInfo>> getFileList({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final List<int> response = await _sendCommandWithResponse(
      <int>[MPNoteBleCommands.getFileList],
      awaitKind: _AwaitKind.fileList,
      timeout: timeout,
    );
    return _parseFileList(response);
  }

  /// 请求导出文件（命令 `0x04`）；成功后设备通过 [recordFile] 特征推送数据。
  ///
  /// 返回 `true` 表示设备应答 `04 01`。请先调用 [prepareFileExport] 再监听 [recordFilePayloadStream]。
  Future<bool> requestFileExport(
    String fileName, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final List<int> nameBytes = utf8.encode(fileName);
    final List<int> command = <int>[
      MPNoteBleCommands.uploadFile,
      nameBytes.length,
      ...nameBytes,
    ];
    final List<int> response = await _sendCommandWithResponse(
      command,
      awaitKind: _AwaitKind.generic,
      timeout: timeout,
    );
    if (response.length >= 2 &&
        response[0] == MPNoteBleCommands.uploadFile &&
        response[1] == 0x01) {
      return true;
    }
    return false;
  }

  /// 删除文件（命令 `0x05` + UTF-8 文件名）。
  Future<bool> deleteFile(
    String fileName, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final List<int> fileNameBytes = utf8.encode(fileName);
    final List<int> command = <int>[
      MPNoteBleCommands.deleteFile,
      fileNameBytes.length,
      ...fileNameBytes,
    ];
    final List<int> response = await _sendCommandWithResponse(
      command,
      awaitKind: _AwaitKind.generic,
      timeout: timeout,
    );
    return response.length >= 2 &&
        response[0] == MPNoteBleCommands.deleteFile &&
        response[1] == 0x01;
  }

  /// 在开始导出前调用：重置装配器状态（按扩展名选择 txt 透传或 Opus 分帧）。
  void prepareFileExport(String fileName) {
    _fileAssembler = MPNoteBleFilePayloadAssembler(fileName: fileName);
    _fileAssembler!.reset();
  }

  /// 导出流判定结束后调用，拼接 [MPNoteBleFilePayloadAssembler.flushTail]。
  List<List<int>> flushFileExportAssemblerTail() {
    final MPNoteBleFilePayloadAssembler? assembler = _fileAssembler;
    if (assembler == null) {
      return <List<int>>[];
    }
    return assembler.flushTail();
  }

  /// `recordFile` 特征重组后的导出数据块（须先 [prepareFileExport] 并成功 [requestFileExport]）。
  ///
  /// 监听方需在适当时机 `cancel` 订阅；多个监听者共享同一底层 notify 流。
  Stream<List<int>> get recordFilePayloadStream {
    final MPNoteBleFilePayloadAssembler? assembler = _fileAssembler;
    if (assembler == null) {
      return const Stream<List<int>>.empty();
    }
    return _transport
        .getCharacteristicStream(MPNoteBleUUIDs.service, MPNoteBleUUIDs.recordFile)
        .expand((List<int> packet) => assembler.push(packet));
  }

  /// 底层原始 `recordFile` 通知（未按 Opus 帧切分）。
  Stream<List<int>> get recordFileRawStream =>
      _transport.getCharacteristicStream(MPNoteBleUUIDs.service, MPNoteBleUUIDs.recordFile);

  Future<void> _ensureResponseSubscription() async {
    if (_responseSub != null) {
      return;
    }
    _responseSub = _transport
        .getCharacteristicStream(MPNoteBleUUIDs.service, MPNoteBleUUIDs.response)
        .listen(
          _handleIncomingPacket,
          onError: (_) {},
        );
    await Future<void>.delayed(Duration.zero);
  }

  void _handleIncomingPacket(List<int> packet) {
    if (packet.isEmpty) {
      return;
    }

    if (_awaitKind == _AwaitKind.fileList && packet[0] == MPNoteBleCommands.getFileList) {
      if (packet.length == 2 &&
          (packet[1] == 0x00 || packet[1] == 0xff)) {
        _cancelPacketTimeout();
        _completeFileListResponse();
        return;
      }
      if (packet.length > 2) {
        _fileListPackets.add(List<int>.from(packet));
        _startPacketTimeout();
      }
      return;
    }

    if (_awaitKind == _AwaitKind.generic &&
        _responseCompleter != null &&
        !_responseCompleter!.isCompleted) {
      if (packet[0] == MPNoteBleCommands.getFileList) {
        return;
      }
      _responseCompleter!.complete(packet);
    }
  }

  void _completeFileListResponse() {
    if (_fileListPackets.isEmpty) {
      _completeWith(<int>[MPNoteBleCommands.getFileList, 0x00]);
      return;
    }

    final List<int> allFiles = <int>[MPNoteBleCommands.getFileList];
    int totalCount = 0;
    for (final List<int> p in _fileListPackets) {
      if (p.length > 2) {
        final int pkgCount = p[1];
        totalCount += pkgCount;
        allFiles.addAll(p.sublist(2));
      }
    }
    allFiles.insert(1, totalCount);
    _fileListPackets.clear();
    _completeWith(allFiles);
  }

  void _completeWith(List<int> data) {
    if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
      _responseCompleter!.complete(data);
    }
  }

  void _startPacketTimeout() {
    _cancelPacketTimeout();
    _packetTimeoutTimer = Timer(const Duration(milliseconds: _kFileListTimeoutMs), () {
      if (_fileListPackets.isNotEmpty) {
        _completeFileListResponse();
      }
    });
  }

  void _cancelPacketTimeout() {
    _packetTimeoutTimer?.cancel();
    _packetTimeoutTimer = null;
  }

  Future<List<int>> _sendCommandWithResponse(
    List<int> command, {
    required _AwaitKind awaitKind,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await _ensureResponseSubscription();

    _cancelPacketTimeout();
    _fileListPackets.clear();
    _awaitKind = awaitKind;
    _responseCompleter = Completer<List<int>>();

    await _transport.writeCharacteristicWithoutResponse(
      MPNoteBleUUIDs.service,
      MPNoteBleUUIDs.command,
      command,
    );

    try {
      final List<int> result = await _responseCompleter!.future.timeout(
        timeout,
        onTimeout: () => <int>[],
      );
      return result;
    } finally {
      _awaitKind = _AwaitKind.none;
      _responseCompleter = null;
      _cancelPacketTimeout();
    }
  }

  List<NoteFileInfo> _parseFileList(List<int> response) {
    if (response.isEmpty || response[0] != MPNoteBleCommands.getFileList) {
      return <NoteFileInfo>[];
    }
    final int fileCount = response[1];
    if (fileCount == 0 || fileCount == 255) {
      return <NoteFileInfo>[];
    }

    final List<NoteFileInfo> files = <NoteFileInfo>[];
    int offset = 2;
    for (int i = 0; i < fileCount; i++) {
      if (offset + 4 > response.length) {
        break;
      }
      final int index = response[offset];
      final int duration = (response[offset + 1] << 8) + response[offset + 2];
      final int nameLength = response[offset + 3];
      if (offset + 4 + nameLength > response.length) {
        break;
      }
      final List<int> fileNameBytes =
          response.sublist(offset + 4, offset + 4 + nameLength);
      final String name = utf8.decode(fileNameBytes);
      debugPrint('--->> fileName: $name, duration: $duration');
      if (name.isNotEmpty && name.length >= 15 && name.contains('_')) {
        files.add(
          NoteFileInfo(
            index: index,
            name: name,
            durationSeconds: duration,
          ),
        );
      }
      offset += 4 + nameLength;
    }
    return files;
  }
}
