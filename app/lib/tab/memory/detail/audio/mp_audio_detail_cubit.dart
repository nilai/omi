import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:memo_pin/audio/record/mp_audio_local_records_util.dart';
import 'package:memo_pin/cache/omi_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/http/api/mp_memory.dart';
import 'package:memo_pin/http/schema/mp_data_model.dart';
import 'package:memo_pin/http/schema/mp_memory.dart';

import '../memory/card/mp_memory_generate_summary_sheet.dart';

enum MPAudioDetailPhase { loading, error, loaded }

class MPAudioDetailData {
  const MPAudioDetailData({
    required this.title,
    required this.subtitle,
    required this.leftTime,
    required this.rightTime,
    required this.total,
    this.recordFile,
    this.recordUri,
  });

  final String title;
  final String subtitle;
  final String leftTime;
  final String rightTime;
  final Duration total;

  /// [MPOnlyRecordMemoryStruct.record_file]，供后续播放器使用。
  final String? recordFile;

  /// [MPOnlyRecordMemoryStruct.record_uri]
  final String? recordUri;

  MPAudioDetailData copyWith({
    String? title,
    String? subtitle,
    String? leftTime,
    String? rightTime,
    Duration? total,
    String? recordFile,
    String? recordUri,
  }) {
    return MPAudioDetailData(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      leftTime: leftTime ?? this.leftTime,
      rightTime: rightTime ?? this.rightTime,
      total: total ?? this.total,
      recordFile: recordFile ?? this.recordFile,
      recordUri: recordUri ?? this.recordUri,
    );
  }
}

class MPAudioDetailState {
  const MPAudioDetailState({
    required this.phase,
    this.data,
    this.errorMessage,
    this.isPlaying = false,
    this.progress = 0,
    this.elapsedLabel = '0:00',
    this.playPreparing = false,
  });

  final MPAudioDetailPhase phase;
  final MPAudioDetailData? data;
  final String? errorMessage;
  final bool isPlaying;

  /// 0..1（与 [AudioPlayer.position] / 总时长对齐）
  final double progress;

  /// 左上已播放时长文案（`M:SS` 或 `H:MM:SS`）
  final String elapsedLabel;

  /// 点击播放后：下载 / 绑定解码器 / [play] 完成前的等待态
  final bool playPreparing;

  MPAudioDetailState copyWith({
    MPAudioDetailPhase? phase,
    MPAudioDetailData? data,
    String? errorMessage,
    bool? isPlaying,
    double? progress,
    String? elapsedLabel,
    bool? playPreparing,
  }) {
    return MPAudioDetailState(
      phase: phase ?? this.phase,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      isPlaying: isPlaying ?? this.isPlaying,
      progress: progress ?? this.progress,
      elapsedLabel: elapsedLabel ?? this.elapsedLabel,
      playPreparing: playPreparing ?? this.playPreparing,
    );
  }
}

/// Audio 详情页 Cubit：拉取 [getMemoryDetail]，展示数据来自 [MPMemoryStruct.onlyRecordMemory]（JSON `only_record_content`）。
class MPAudioDetailCubit extends Cubit<MPAudioDetailState> {
  MPAudioDetailCubit({required this.memoryId})
    : super(const MPAudioDetailState(phase: MPAudioDetailPhase.loading));

  final String memoryId;

  final AudioPlayer _audioPlayer = AudioPlayer();

  /// 进度 UI：定时器轮询 [AudioPlayer.position]（播中即可读，不依赖「整段播完」）。
  /// 首次常走 [bindLocalAudioForPlayback] 换源；第二次同路径多跳过换源，状态更简单。
  /// 注意：开定时器时 [MPAudioDetailState.playPreparing] 须已为 false，否则首帧 tick 会自停定时器。
  Timer? _playbackUiTimer;
  StreamSubscription<Duration>? _positionStreamSub;
  String? _playingLocalPath;

  /// [bindLocalAudioForPlayback] / [stop] 后一段时间内忽略 [ProcessingState.completed]。
  int _suppressPlaybackCompletedUntilMs = 0;

  static const Duration _kPlaybackUiTick = Duration(milliseconds: 200);
  static const int _kEndSlackMs = 160;
  static const int _kSuppressCompletedAfterSourceMs = 900;

  /// 总时长过短时不能用 `pos >= total - slack`，否则 `pos==0` 也会误判为已播完（接口时长偶发远小于真实文件）。
  static bool _reachedEndByPosition(Duration pos, Duration total, int marginMs) {
    final int t = total.inMilliseconds;
    if (t <= marginMs) {
      return false;
    }
    return pos.inMilliseconds >= t - marginMs;
  }

  void _armSuppressPlaybackCompleted() {
    _suppressPlaybackCompletedUntilMs =
        DateTime.now().millisecondsSinceEpoch + _kSuppressCompletedAfterSourceMs;
  }

  void _stopPlaybackUiTimer() {
    _playbackUiTimer?.cancel();
    _playbackUiTimer = null;
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
  }

  void _startPlaybackUiTimer() {
    _stopPlaybackUiTimer();
    _playbackUiTimer = Timer.periodic(_kPlaybackUiTick, (_) {
      _tickPlaybackUiFromPlayer();
    });
    _positionStreamSub = _audioPlayer.positionStream.listen((Duration _) {
      if (isClosed) {
        return;
      }
      scheduleMicrotask(_tickPlaybackUiFromPlayer);
    });
    _tickPlaybackUiFromPlayer();
  }

  void _tickPlaybackUiFromPlayer() {
    if (isClosed) {
      return;
    }
    final MPAudioDetailState s = state;
    if (s.phase != MPAudioDetailPhase.loaded || s.data == null) {
      _stopPlaybackUiTimer();
      return;
    }
    if (s.playPreparing || !s.isPlaying) {
      _stopPlaybackUiTimer();
      return;
    }

    final bool suppressCompleted = DateTime.now().millisecondsSinceEpoch <
        _suppressPlaybackCompletedUntilMs;

    final Duration pos = _audioPlayer.position;
    final Duration? dur = _audioPlayer.duration;
    final Duration totalRef =
        (dur != null && dur > Duration.zero) ? dur : s.data!.total;

    // 不在 [playerStateStream] 里直接 emit：会与 [onPlayTap] 的 emit 同栈重入，首帧把 isPlaying 打掉。
    if (!suppressCompleted &&
        _audioPlayer.processingState == ProcessingState.completed &&
        !_audioPlayer.playing) {
      final bool nearEnd = _reachedEndByPosition(pos, totalRef, _kEndSlackMs * 4);
      final bool nearEndByDecoder = dur != null &&
          dur > Duration.zero &&
          _reachedEndByPosition(pos, dur, _kEndSlackMs * 4);
      if (nearEnd || nearEndByDecoder) {
        _stopPlaybackUiTimer();
        final Duration end = totalRef > Duration.zero
            ? totalRef
            : (dur != null && dur > Duration.zero ? dur : pos);
        emit(
          s.copyWith(
            isPlaying: false,
            progress: 1,
            elapsedLabel: end > Duration.zero
                ? _formatMmSs(end)
                : _formatMmSs(pos),
          ),
        );
        return;
      }
    }

    if (_reachedEndByPosition(pos, totalRef, _kEndSlackMs)) {
      _stopPlaybackUiTimer();
      emit(
        s.copyWith(
          isPlaying: false,
          progress: 1,
          elapsedLabel: _formatMmSs(totalRef),
        ),
      );
      return;
    }

    double prog = s.progress;
    if (totalRef > Duration.zero) {
      prog = (pos.inMilliseconds / totalRef.inMilliseconds).clamp(0.0, 1.0);
    }
    final String elapsed = _formatMmSs(pos);
    if (elapsed == s.elapsedLabel && (prog - s.progress).abs() < 0.003) {
      return;
    }
    emit(s.copyWith(progress: prog, elapsedLabel: elapsed));
  }

  Future<void> initData() => load();

  bool _isInCachedFirstPage() {
    final dynamic cached = OmiCacheManager().getMemoryFirstPage();
    if (cached is! Map) return false;
    final dynamic rawList = cached['memorys'];
    if (rawList is! List) return false;
    for (final dynamic e in rawList) {
      if (e is Map) {
        final dynamic id = e['id'];
        if (id is String && id == memoryId) {
          return true;
        }
      }
    }
    return false;
  }

  MPAudioDetailData? _loadCachedAudioDetailIfAllowed() {
    if (!_isInCachedFirstPage()) return null;
    final dynamic cached = OmiCacheManager().getMemoryDetail(memoryId);
    if (cached is! Map) return null;
    try {
      final MPMemoryStruct m =
          MPMemoryStruct.fromJson(Map<String, dynamic>.from(cached));
      final MPOnlyRecordMemoryStruct? only = m.onlyRecordContent;
      if (only == null) return null;
      return _mapOnlyRecordToAudioData(m, only);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    final MPAudioDetailData? cached = _loadCachedAudioDetailIfAllowed();
    final bool hasCached = cached != null;
    if (hasCached) {
      emit(MPAudioDetailState(phase: MPAudioDetailPhase.loaded, data: cached));
    } else {
      emit(const MPAudioDetailState(phase: MPAudioDetailPhase.loading));
    }
    try {
      final MPGetMemoryV2DetailResponse? resp = await getMemoryDetail(
        MPGetMemoryV2DetailRequest(memoryId: memoryId),
      );
      if (resp == null) {
        throw StateError('getMemoryDetail failed');
      }
      final MPMemoryStruct m = resp.memoryDetail;
      final MPOnlyRecordMemoryStruct? only = m.onlyRecordContent;
      if (only == null) {
        throw StateError('only_record_content is empty');
      }
      if (_isInCachedFirstPage()) {
        OmiCacheManager().putMemoryDetail(memoryId, m.toJson());
      }
      final MPAudioDetailData data = _mapOnlyRecordToAudioData(m, only);
      emit(MPAudioDetailState(phase: MPAudioDetailPhase.loaded, data: data));
    } catch (e) {
      if (!hasCached) {
        emit(
          MPAudioDetailState(
            phase: MPAudioDetailPhase.error,
            errorMessage: e.toString(),
          ),
        );
      }
    }
  }

  Future<void> retry() => load();

  /// 重命名成功后更新本地标题（接口由 [MPMemoryUpdateNameDialog] 调用）。
  void updateTitle(String newTitle) {
    if (state.phase != MPAudioDetailPhase.loaded || state.data == null) {
      return;
    }
    emit(
      state.copyWith(
        data: state.data!.copyWith(title: newTitle.trim()),
      ),
    );
  }

  Future<void> onPlayTap() async {
    if (state.phase != MPAudioDetailPhase.loaded) return;
    final bool next = !state.isPlaying;
    if (!next) {
      _stopPlaybackUiTimer();
      await _audioPlayer.pause();
      emit(state.copyWith(isPlaying: false));
      return;
    }

    emit(state.copyWith(playPreparing: true));
    bool shouldRunPlaybackUi = false;
    try {
      final String? localPath = await _ensurePlayableLocalPath();
      if (localPath == null || localPath.isEmpty) {
        MPToastUtils.showMessage('音频下载失败，请稍后重试');
        return;
      }
      final bool rebound = _playingLocalPath != localPath;
      if (rebound) {
        _armSuppressPlaybackCompleted();
        await MPAudioLocalRecordsUtil.bindLocalAudioForPlayback(
          _audioPlayer,
          localPath,
        );
        _playingLocalPath = localPath;
      }
      if (_audioPlayer.processingState == ProcessingState.completed) {
        await _audioPlayer.seek(Duration.zero);
      }
      await _audioPlayer.play();

      if (kDebugMode) {
        debugPrint(
          'MPAudioDetailCubit.play: rebound=$rebound '
          'pos=${_audioPlayer.position.inMilliseconds}ms '
          'dur=${_audioPlayer.duration?.inMilliseconds}ms '
          'processing=${_audioPlayer.processingState}',
        );
      }

      double p = state.progress;
      if (p >= 1) {
        p = 0;
      }
      // 必须一次 emit 同时关掉 playPreparing：否则首帧 tick 会因 playPreparing==true
      // 直接 _stopPlaybackUiTimer()，表现为「第一次定时器不生效」。
      emit(
        state.copyWith(
          isPlaying: true,
          playPreparing: false,
          progress: p,
          elapsedLabel: _formatMmSs(_audioPlayer.position),
        ),
      );
      shouldRunPlaybackUi = true;
    } catch (e, st) {
      debugPrint('MPAudioDetailCubit.onPlayTap: $e\n$st');
      MPToastUtils.showMessage('音频播放失败');
    } finally {
      if (!isClosed && !shouldRunPlaybackUi) {
        emit(state.copyWith(playPreparing: false));
      }
    }
    if (!isClosed && shouldRunPlaybackUi && state.isPlaying) {
      _startPlaybackUiTimer();
    }
  }

  Future<String?> _ensurePlayableLocalPath() async {
    final MPAudioDetailData? data = state.data;
    if (data == null) {
      return null;
    }
    final String recordFile = (data.recordFile ?? '').trim();
    final String recordUri = (data.recordUri ?? '').trim();

    if (recordFile.isNotEmpty) {
      final String? localPath =
          await MPAudioLocalRecordsUtil.instance.getLocalRecordPath(recordFile);
      if (localPath != null && localPath.isNotEmpty) {
        return localPath;
      }
    }

    final String? downloadUrl = _resolveRecordDownloadUrl(
      recordFile: recordFile,
      recordUri: recordUri,
    );
    if (downloadUrl == null) {
      return null;
    }

    return _downloadRecordToLocal(
      downloadUrl: downloadUrl,
      recordFile: recordFile,
      total: data.total,
    );
  }

  String? _resolveRecordDownloadUrl({
    required String recordFile,
    required String recordUri,
  }) {
    final String rf = recordFile.trim();
    final String ru = recordUri.trim();

    if (rf.isNotEmpty) {
      final Uri? recordFileUri = Uri.tryParse(rf);
      if (recordFileUri != null &&
          recordFileUri.hasScheme &&
          recordFileUri.host.isNotEmpty) {
        return rf;
      }
    }

    final Uri? recordUriParsed = Uri.tryParse(ru);
    if (recordUriParsed != null &&
        recordUriParsed.hasScheme &&
        recordUriParsed.host.isNotEmpty) {
      if (rf.isEmpty) {
        return ru;
      }
      final Uri? ref = Uri.tryParse(rf);
      if (ref == null) {
        return ru;
      }
      return recordUriParsed.resolveUri(ref).toString();
    }
    return null;
  }

  Future<String?> _downloadRecordToLocal({
    required String downloadUrl,
    required String recordFile,
    required Duration total,
  }) async {
    try {
      final Uri uri = Uri.parse(downloadUrl);
      final http.Response? response =
          await MPAudioLocalRecordsUtil.httpGetAudioDownloadUrl(downloadUrl);
      if (response == null ||
          response.statusCode < 200 ||
          response.statusCode >= 300) {
        return null;
      }
      final String audioDirPath =
          await MPAudioLocalRecordsUtil.ensureLocalStorageDirectoryPath();
      final String sourceForId =
          recordFile.isNotEmpty ? recordFile : downloadUrl;
      String fileId =
          MPAudioLocalRecordsUtil.getFileIdFromUrl(sourceForId).trim();
      if (fileId.isEmpty) {
        fileId = DateTime.now().millisecondsSinceEpoch.toString();
      }
      String ext = '.m4a';
      final String path = uri.path;
      final int dot = path.lastIndexOf('.');
      if (dot > 0 && dot < path.length - 1) {
        ext = path.substring(dot);
      }
      final String filePath = p.join(
        audioDirPath,
        '${DateTime.now().millisecondsSinceEpoch}_$fileId$ext',
      );
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes, flush: true);
      final String? playablePath =
          await MPAudioLocalRecordsUtil.adjustAudioFileIfWrongExtension(filePath);
      if (playablePath == null) {
        return null;
      }

      await MPAudioLocalRecordsUtil.instance.load();
      await MPAudioLocalRecordsUtil.instance.add(
        MPAudioLocalRecord(
          path: playablePath,
          fileName: fileId,
          createAt: DateTime.now().millisecondsSinceEpoch,
          duration: total.inSeconds > 0 ? total.inSeconds : null,
          source: 'mp',
          fileId: fileId,
        ),
      );
      return playablePath;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> close() {
    _stopPlaybackUiTimer();
    _audioPlayer.dispose();
    return super.close();
  }

  void onSummarizeTap(BuildContext context) {
    showMPMemoryGenerateSummarySheet(
      context,
      onGenerateResummary: () {
        // TODO: 调用生成 resummary 接口
      },
      onChangeMode: () {
        // TODO: 切换 Autopilot / 其它模式
      },
    );
  }
}

DateTime _audioDetailDateTime(int raw) {
  if (raw > 10000000000) {
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }
  return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
}

/// 已播放/总时长角标（`M:SS` 或 `H:MM:SS`）。
String _formatMmSs(Duration d) {
  Duration x = d;
  if (x.isNegative) {
    x = Duration.zero;
  }
  final int totalSeconds = x.inSeconds;
  final int h = totalSeconds ~/ 3600;
  final int m = (totalSeconds % 3600) ~/ 60;
  final int s = totalSeconds % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

String _formatDurationLabel(int? seconds) {
  if (seconds == null || seconds <= 0) {
    return '0s';
  }
  final int m = seconds ~/ 60;
  final int s = seconds % 60;
  if (m > 60) {
    final int h = m ~/ 60;
    final int mm = m % 60;
    return '${h}h${mm}m${s}s';
  }
  if (m > 0) {
    return '${m}m${s}s';
  }
  return '${s}s';
}

MPAudioDetailData _mapOnlyRecordToAudioData(
  MPMemoryStruct m,
  MPOnlyRecordMemoryStruct only,
) {
  final DateTime dt = _audioDetailDateTime(m.createAt);
  final String title = DateFormat('MMM d, y, h:mm a').format(dt);
  final String longDate =
      '${DateFormat('MMMM d, y').format(dt)} at ${DateFormat('h:mm a').format(dt)}';
  final String source = (only.source ?? m.source ?? '').trim();
  final String subtitle =
      source.isNotEmpty ? '$longDate  ·  $source' : longDate;

  final int? sec = m.duration;
  final Duration total = Duration(
    seconds: sec != null && sec > 0 ? sec : 0,
  );
  final String rightTime = _formatDurationLabel(sec);

  return MPAudioDetailData(
    title: title,
    subtitle: subtitle,
    leftTime: '0:00',
    rightTime: rightTime,
    total: total,
    recordFile: only.recordFile,
    recordUri: only.recordUri,
  );
}
