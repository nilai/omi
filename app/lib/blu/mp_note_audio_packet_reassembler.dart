import 'dart:async';

import 'package:flutter/foundation.dart';

/// 与 `ble/note_ble_transport.dart` 中 `AudioPacketConstants` 对齐的 V1.0 常量（不依赖 `package:omi`）。
abstract class MPAudioPacketConstants {
  static const int headerSizeSeqOnly = 4;
  static const int frameSize = 480;
  static const int headerSizeWithFlag = 5;
  static const int reassemblyTimeoutMs = 500;

  static int parseSeq(List<int> raw) {
    return ((raw[0] & 0xff) << 24) |
        ((raw[1] & 0xff) << 16) |
        ((raw[2] & 0xff) << 8) |
        (raw[3] & 0xff);
  }

  /// Flag 高 4 位：子包总数；`0` 表示单包（与 `AudioPacketReassembler` 行为一致）。
  static int getFlagTotal(int flag) => (flag >> 4) & 0x0f;

  /// Flag 低 4 位：当前子包序号（从 0 起）。
  static int getFlagIndex(int flag) => flag & 0x0f;
}

/// 与 `ble/note_ble_transport.dart` 中 `AudioPacketReassembler` 行为对齐：301 原始 notify → 480B Opus 帧。
///
/// 用于 [MPBleTransport] 路径下与 `NoteBleTransport.audioStream` 对齐的重组层。
class MPAudioPacketReassembler {
  MPAudioPacketReassembler({
    this.tag = 'RT',
    required this.onFrameComplete,
    required this.onSeqGap,
  });

  final Map<int, Map<int, List<int>>> _pending = <int, Map<int, List<int>>>{};
  Timer? _timeoutTimer;
  int _lastCompletedSeq = -1;
  String? _currentFileName;
  int _completedFrameCount = 0;
  DateTime? _lastDetailLogTime;
  int _discardedFrameCount = 0;

  final String tag;
  final void Function(int seq, List<int> frame) onFrameComplete;
  final void Function(int expectedSeq, int receivedSeq) onSeqGap;

  /// 与 `AudioPacketReassembler.lastCompletedSeq` 一致。
  int get lastCompletedSeq => _lastCompletedSeq;

  /// 与 `AudioPacketReassembler.completedFrameCount` 一致。
  int get completedFrameCount => _completedFrameCount;

  void _log(String msg) => debugPrint('[$tag] $msg');

  void process(List<int> rawPacket) {
    if (_completedFrameCount + _discardedFrameCount < 10) {
      final String hexHead =
          rawPacket.take(8).map((int b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      _log(
        '原始包#${_completedFrameCount + _discardedFrameCount}: len=${rawPacket.length}, head=[$hexHead'
        '${rawPacket.length > 8 ? " ..." : ""}]',
      );
    }

    if (rawPacket.length < MPAudioPacketConstants.headerSizeSeqOnly + 1) {
      _log('⚠️ 包太小: ${rawPacket.length} bytes');
      return;
    }

    final int seq = MPAudioPacketConstants.parseSeq(rawPacket);
    final bool isNoFlagFormat = rawPacket.length ==
        MPAudioPacketConstants.headerSizeSeqOnly + MPAudioPacketConstants.frameSize;

    if (isNoFlagFormat) {
      final List<int> data = rawPacket.sublist(MPAudioPacketConstants.headerSizeSeqOnly);
      if (_completedFrameCount < 10 || _shouldLogByTime()) {
        _log('完整帧 seq=$seq, dataSize=${data.length}, 已完成帧=$_completedFrameCount (无Flag格式)');
      }
      _onFrameReady(seq, data);
      return;
    }

    if (rawPacket.length < MPAudioPacketConstants.headerSizeWithFlag + 1) {
      _log('⚠️ 有Flag格式但包太小: ${rawPacket.length} bytes');
      return;
    }

    final int flag = rawPacket[4];
    final int totalParts = MPAudioPacketConstants.getFlagTotal(flag);
    final int partIndex = MPAudioPacketConstants.getFlagIndex(flag);
    final List<int> data = rawPacket.sublist(MPAudioPacketConstants.headerSizeWithFlag);

    if (_completedFrameCount < 10 || _shouldLogByTime()) {
      if (totalParts == 0) {
        _log('单包 seq=$seq, flag=0x${flag.toRadixString(16)}, dataSize=${data.length}, 已完成帧=$_completedFrameCount');
      } else {
        _log('分包 seq=$seq, flag=0x${flag.toRadixString(16)}, part=${partIndex + 1}/$totalParts, dataSize=${data.length}');
      }
    }

    if (totalParts == 0) {
      _onFrameReady(seq, data);
    } else {
      if (_pending.length >= 50 && !_pending.containsKey(seq)) {
        final int oldestSeq = _pending.keys.first;
        _log('⚠️ 缓存已满(50), 丢弃最旧 seq=$oldestSeq');
        _pending.remove(oldestSeq);
        _discardedFrameCount++;
      }

      _pending.putIfAbsent(seq, () => <int, List<int>>{});
      _pending[seq]![partIndex] = data;

      if (_pending[seq]!.length == totalParts) {
        final List<int> frame = <int>[];
        for (int i = 0; i < totalParts; i++) {
          final List<int>? part = _pending[seq]![i];
          if (part != null) {
            frame.addAll(part);
          } else {
            _log('⚠️ seq=$seq 缺少子包 #$i/$totalParts，丢弃该帧');
            _pending.remove(seq);
            _discardedFrameCount++;
            return;
          }
        }
        _pending.remove(seq);
        _log('分包重组完成 seq=$seq, $totalParts个子包 → ${frame.length} bytes');
        _onFrameReady(seq, frame);
      } else {
        _ensureTimeout();
      }
    }
  }

  bool _shouldLogByTime() {
    final DateTime now = DateTime.now();
    if (_lastDetailLogTime == null || now.difference(_lastDetailLogTime!).inSeconds >= 10) {
      _lastDetailLogTime = now;
      return true;
    }
    return false;
  }

  void _onFrameReady(int seq, List<int> frame) {
    if (_lastCompletedSeq >= 0 && seq > _lastCompletedSeq + 1) {
      final int gapStart = _lastCompletedSeq + 1;
      final int gapCount = seq - gapStart;
      _log('⚠️ Seq 间隙! 期望=$gapStart, 收到=$seq, 缺失$gapCount帧, 文件=$_currentFileName');
      onSeqGap(gapStart, seq);
    }

    _lastCompletedSeq = seq;
    _completedFrameCount++;
    onFrameComplete(seq, frame);
  }

  void _ensureTimeout() {
    if (_timeoutTimer?.isActive == true) {
      return;
    }
    _timeoutTimer = Timer(
      Duration(milliseconds: MPAudioPacketConstants.reassemblyTimeoutMs),
      () {
        if (_pending.isNotEmpty) {
          final List<int> seqs = _pending.keys.toList();
          _log('⚠️ 分包超时! 丢弃 ${_pending.length} 个不完整帧: seqs=$seqs');
          _discardedFrameCount += _pending.length;
          _pending.clear();
        }
      },
    );
  }

  /// 从持久化状态恢复 lastCompletedSeq（与 `AudioPacketReassembler.restoreLastCompletedSeq` 对齐）。
  void restoreLastCompletedSeq(int seq) {
    _lastCompletedSeq = seq;
    _log('恢复 lastCompletedSeq=$seq');
  }

  /// 新录音文件开始时重置 Seq（与 `AudioPacketReassembler.reset` 对齐）。
  void reset({String? fileName}) {
    _pending.clear();
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    if (fileName != null) {
      _currentFileName = fileName;
      _lastCompletedSeq = -1;
      _completedFrameCount = 0;
      _discardedFrameCount = 0;
      _lastDetailLogTime = null;
      _log('重置: 文件切换 → $fileName, Seq 归零');
    } else {
      _log('重置: 清除缓存 (lastSeq=$_lastCompletedSeq, 已完成=$_completedFrameCount, 已丢弃=$_discardedFrameCount)');
    }
  }

  void dispose() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _pending.clear();
    _log('已释放 (总完成=$_completedFrameCount, 总丢弃=$_discardedFrameCount)');
  }
}
