import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:memo_pin/audio/record/mp_audio_local_records_util.dart';
import 'package:memo_pin/cache/omi_cache_manager.dart';
import 'package:memo_pin/cache/omi_server_cache.dart';
import 'package:memo_pin/common/mp_memory_notification.dart';
import 'package:path/path.dart' as p;
import 'package:memo_pin/common/mp_date_utils.dart';
import 'package:memo_pin/utils/mp_time_utils.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/http/api/mp_memory.dart';
import 'package:memo_pin/http/schema/mp_data_model.dart';
import 'package:memo_pin/http/schema/mp_memory.dart';

import '../../../../main.dart';
import '../memory/card/mp_memory_generate_summary_sheet.dart';
import '../mp_transcription_limit_sheet.dart';

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
    this.isSummaryGenerating = false,
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

  /// 仅 [OmiAudioDetailPage]：[summaryRecord] 进行中展示 [MPSummaryGeneratingPanel]。
  final bool isSummaryGenerating;

  MPAudioDetailState copyWith({
    MPAudioDetailPhase? phase,
    MPAudioDetailData? data,
    String? errorMessage,
    bool? isPlaying,
    double? progress,
    String? elapsedLabel,
    bool? playPreparing,
    bool? isSummaryGenerating,
  }) {
    return MPAudioDetailState(
      phase: phase ?? this.phase,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      isPlaying: isPlaying ?? this.isPlaying,
      progress: progress ?? this.progress,
      elapsedLabel: elapsedLabel ?? this.elapsedLabel,
      playPreparing: playPreparing ?? this.playPreparing,
      isSummaryGenerating: isSummaryGenerating ?? this.isSummaryGenerating,
    );
  }
}

/// Audio 详情页 Cubit：拉取 [getMemoryDetail]，展示数据来自 [MPMemoryStruct.onlyRecordMemory]（JSON `only_record_content`）。
class MPAudioDetailCubit extends Cubit<MPAudioDetailState> {
  MPAudioDetailCubit({required this.memoryId})
    : super(const MPAudioDetailState(phase: MPAudioDetailPhase.loading)) {
    _decoderDurationSub = _audioPlayer.durationStream.listen((Duration? d) {
      if (isClosed) {
        return;
      }
      if (d == null || d <= Duration.zero) {
        return;
      }
      final MPAudioDetailState s = state;
      if (s.phase != MPAudioDetailPhase.loaded || s.data == null) {
        return;
      }
      final MPAudioDetailData cur = s.data!;
      if (cur.total == d) {
        return;
      }
      emit(
        s.copyWith(
          data: cur.copyWith(
            total: d,
            rightTime: _formatDurationLabel(d.inSeconds),
          ),
        ),
      );
      if (s.isPlaying && !s.playPreparing) {
        scheduleMicrotask(_tickPlaybackUiFromPlayer);
      }
    });
  }

  final String memoryId;

  final AudioPlayer _audioPlayer = AudioPlayer();

  /// 解码器上报时长后补齐 [MPAudioDetailData.total]（接口 [MPMemoryStruct.duration] 在仅录音类型下可能为 0）。
  StreamSubscription<Duration?>? _decoderDurationSub;

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
        MPTimeUtils.nowUnixMilliseconds() + _kSuppressCompletedAfterSourceMs;
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

  Future<bool> _ensureBoundLocalPath() async {
    final String? localPath = await _ensurePlayableLocalPath();
    if (localPath == null || localPath.isEmpty) {
      MPToastUtils.showMessage('Failed to download audio. Please try again later.');
      return false;
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
    return true;
  }

  /// 绑定音源后 [AudioPlayer.duration] 可能略晚就绪，短暂轮询以对齐波形 seek。
  Future<Duration> _resolveTotalRef() async {
    final MPAudioDetailData? data = state.data;
    if (data == null) {
      return Duration.zero;
    }
    Duration totalRef = _audioPlayer.duration ?? data.total;
    if (totalRef > Duration.zero) {
      return totalRef;
    }
    for (int i = 0; i < 8; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 64));
      totalRef = _audioPlayer.duration ?? data.total;
      if (totalRef > Duration.zero) {
        return totalRef;
      }
    }
    return totalRef;
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

    final bool suppressCompleted = MPTimeUtils.nowUnixMilliseconds() <
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
      // 接口/解码器均未给出有效总时长时，nearEnd 恒为 false，需仍结束播放态以免波纹不停。
      final bool completedWithoutTotal =
          totalRef <= Duration.zero && (dur == null || dur <= Duration.zero);
      if (nearEnd || nearEndByDecoder || completedWithoutTotal) {
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
    if (elapsed == s.elapsedLabel && (prog - s.progress).abs() < 0.0008) {
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
    final dynamic cached = OmiCacheManager().getMemoryDetail(
      memoryId,
      OmiCacheKeys.memoryDetailKindOnlyRecord,
    );
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
      final MPAudioDetailState beforeCache = state;
      if (beforeCache.phase == MPAudioDetailPhase.loaded) {
        emit(beforeCache.copyWith(data: cached, isSummaryGenerating: false));
      } else {
        emit(
          MPAudioDetailState(
            phase: MPAudioDetailPhase.loaded,
            data: cached,
            isSummaryGenerating: false,
          ),
        );
      }
    } else {
      emit(const MPAudioDetailState(phase: MPAudioDetailPhase.loading));
    }
    try {
      final MPGetMemoryV2DetailResponse? resp = await getMemoryDetail(
        MPGetMemoryV2DetailRequest(memoryId: memoryId),
      );
      if (isClosed) {
        return;
      }
      if (resp == null) {
        throw StateError('getMemoryDetail failed');
      }
      final MPMemoryStruct m = resp.memoryDetail;
      final MPOnlyRecordMemoryStruct? only = m.onlyRecordContent;
      if (only == null) {
        throw StateError('only_record_content is empty');
      }
      if (_isInCachedFirstPage()) {
        OmiCacheManager().putMemoryDetail(
          memoryId,
          OmiCacheKeys.memoryDetailKindOnlyRecord,
          m.toJson(),
        );
      }
      final MPAudioDetailData data = _mapOnlyRecordToAudioData(m, only);
      if (isClosed) {
        return;
      }
      // 勿用「全新 MPAudioDetailState」覆盖：用户在等接口时若已开始播，
      // 会把 isPlaying/progress/elapsedLabel 打回默认，出现「只有声音在播、时间和波纹不动」。
      final MPAudioDetailState cur = state;
      if (cur.phase == MPAudioDetailPhase.loaded) {
        emit(cur.copyWith(data: data, isSummaryGenerating: false));
      } else {
        emit(
          MPAudioDetailState(
            phase: MPAudioDetailPhase.loaded,
            data: data,
            isSummaryGenerating: false,
          ),
        );
      }
    } catch (e) {
      if (isClosed) {
        return;
      }
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

  /// 与 [MPMemoryTransitionCubit] 一致：`status == 2` 表示服务端总结已完成。
  static const Duration _kSummaryPollInterval = Duration(seconds: 5);
  static const int _kSummaryPollMaxAttempts = 120;

  Future<bool> _pollSummaryUntilComplete() async {
    for (int attempt = 0; attempt < _kSummaryPollMaxAttempts; attempt++) {
      if (isClosed) {
        return false;
      }
      final MPGetSummaryStatusResponse? res = await getSummaryStatus(
        MPGetSummaryStatusRequest(memoryId: memoryId),
      );
      if (isClosed) {
        return false;
      }
      if (res == null) {
        if (attempt < _kSummaryPollMaxAttempts - 1) {
          await Future<void>.delayed(_kSummaryPollInterval);
        }
        continue;
      }
      if (res.baseResp.code != 0) {
        MPToastUtils.showMessage(
          res.baseResp.message.isEmpty
            ? 'Failed to check summary status.'
            : res.baseResp.message,
        );
        return false;
      }
      if (res.status == 2) {
        return true;
      }
      if (attempt < _kSummaryPollMaxAttempts - 1) {
        await Future<void>.delayed(_kSummaryPollInterval);
      }
    }
    MPToastUtils.showMessage('Generation timed out. Please try again later.');
    return false;
  }

  Future<void> runSummaryRegeneration(MPSummaryRecordRequest req) async {
    if (state.phase != MPAudioDetailPhase.loaded || state.data == null) {
      return;
    }
    if (isClosed) return;
    emit(state.copyWith(isSummaryGenerating: true));
    try {
      final MPSummaryRecordResponse? summary = await summaryRecord(req);
      if (isClosed) return;
      if (summary == null || summary.baseResp.code != 0) {
        emit(state.copyWith(isSummaryGenerating: false));
        if (summary?.baseResp.code == kMPSummaryRecordTranscriptionLimitCode) {
          await mpHandleSummaryRecordTranscriptionLimit(summary!.baseResp);
          return;
        }
        MPToastUtils.showMessage(
          summary?.baseResp.message ?? 'Generation failed. Please try again later.',
        );
        return;
      }
      MPMemoryNotification.notifyMemoryListRefresh();
      final bool completed = await _pollSummaryUntilComplete();
      if (isClosed) return;
      if (completed) {
        final NavigatorState? nav = MyApp.navigatorKey.currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        }
        return;
      }
      emit(state.copyWith(isSummaryGenerating: false));
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(isSummaryGenerating: false));
        MPToastUtils.showMessage('Generation failed. Please try again later.');
      }
    }
  }

  Future<void> retry() => load();

  Future<void> pauseIfPlaying() async {
    if (state.phase != MPAudioDetailPhase.loaded) return;
    if (!state.isPlaying) return;
    _stopPlaybackUiTimer();
    try {
      await _audioPlayer.pause();
    } catch (_) {}
    if (!isClosed) {
      emit(
        state.copyWith(
          isPlaying: false,
          playPreparing: false,
        ),
      );
    }
  }

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
      if (!await _ensureBoundLocalPath()) {
        return;
      }
      if (_audioPlayer.processingState == ProcessingState.completed) {
        await _audioPlayer.seek(Duration.zero);
      }
      // 首次换源后 [play] 返回的 Future 在部分机型上会拖到「整段播完」才完成，
      // 若 await 则 emit / 定时器要等播完才执行，表现为时间与波纹全程不动。
      unawaited(
        _audioPlayer.play().catchError((Object e, StackTrace st) {
          if (isClosed) {
            return;
          }
          debugPrint('MPAudioDetailCubit.onPlayTap play future: $e\n$st');
          _stopPlaybackUiTimer();
          MPToastUtils.showMessage('Failed to play audio.');
          emit(
            state.copyWith(
              isPlaying: false,
              playPreparing: false,
            ),
          );
        }),
      );

      if (kDebugMode) {
        debugPrint(
          'MPAudioDetailCubit.play: '
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
      MPToastUtils.showMessage('Failed to play audio.');
    } finally {
      if (!isClosed && !shouldRunPlaybackUi) {
        emit(state.copyWith(playPreparing: false));
      }
    }
    // 勿依赖此处的 state.isPlaying：emit 后个别时机下读到的 state 可能尚未更新，会导致定时器未启动。
    if (!isClosed && shouldRunPlaybackUi) {
      _startPlaybackUiTimer();
    }
  }

  /// 点击波形：按宽度比例 0..1 seek 并从该处播放。
  Future<void> onSeekByWaveFraction(double rawFraction) async {
    final double fraction = rawFraction.clamp(0.0, 1.0);
    if (state.phase != MPAudioDetailPhase.loaded || state.data == null) {
      return;
    }
    if (state.playPreparing) {
      return;
    }

    emit(state.copyWith(playPreparing: true));
    bool shouldRunPlaybackUi = false;
    try {
      if (!await _ensureBoundLocalPath()) {
        return;
      }
      final Duration totalRef = await _resolveTotalRef();
      if (totalRef <= Duration.zero) {
        MPToastUtils.showMessage('Failed to play audio.');
        return;
      }
      final int ms = (totalRef.inMilliseconds * fraction).round();
      final Duration target = Duration(milliseconds: ms);
      await _audioPlayer.seek(target);

      unawaited(
        _audioPlayer.play().catchError((Object e, StackTrace st) {
          if (isClosed) {
            return;
          }
          debugPrint('MPAudioDetailCubit.onSeekByWaveFraction play: $e\n$st');
          _stopPlaybackUiTimer();
          MPToastUtils.showMessage('Failed to play audio.');
          emit(
            state.copyWith(
              isPlaying: false,
              playPreparing: false,
            ),
          );
        }),
      );

      final double prog =
          (target.inMilliseconds / totalRef.inMilliseconds).clamp(0.0, 1.0);
      emit(
        state.copyWith(
          isPlaying: true,
          playPreparing: false,
          progress: prog,
          elapsedLabel: _formatMmSs(target),
        ),
      );
      shouldRunPlaybackUi = true;
    } catch (e, st) {
      debugPrint('MPAudioDetailCubit.onSeekByWaveFraction: $e\n$st');
      MPToastUtils.showMessage('Failed to play audio.');
    } finally {
      if (!isClosed && !shouldRunPlaybackUi) {
        emit(state.copyWith(playPreparing: false));
      }
    }
    if (!isClosed && shouldRunPlaybackUi) {
      _startPlaybackUiTimer();
    }
  }

  /// 与 [OmiMemoryDetailCubit._ensurePlayableLocalPath] 对齐：`recordUri` → fileId → 本地库命中则直接播放，否则用 `recordFile` 下载。
  Future<String?> _ensurePlayableLocalPath() async {
    final MPAudioDetailData? data = state.data;
    if (data == null) {
      return null;
    }
    final String recordUri = (data.recordUri ?? '').trim();
    final String fileId =
        MPAudioLocalRecordsUtil.getFileIdFromRecordFile(recordUri);
    final MPAudioLocalRecord? record =
        await MPAudioLocalRecordsUtil.instance.queryByFileId(fileId);
    final String localPath = record?.path ?? '';
    if (localPath.isNotEmpty) {
      return localPath;
    }
    final String downloadUrl = (data.recordFile ?? '').trim();
    if (downloadUrl.isEmpty) {
      return '';
    }
    return _downloadRecordToLocal(
      downloadUrl: downloadUrl,
      fileId: fileId,
      durationLabel: data.rightTime,
    );
  }

  /// 下载录音到本地（与 [OmiMemoryDetailCubit._downloadRecordToLocal] 对齐）。
  Future<String?> _downloadRecordToLocal({
    required String downloadUrl,
    required String fileId,
    required String durationLabel,
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
      String resolvedFileId = fileId.trim();
      if (resolvedFileId.isEmpty) {
        resolvedFileId = MPTimeUtils.nowUnixMilliseconds().toString();
      }
      String ext = '.m4a';
      final String path = uri.path;
      final int dot = path.lastIndexOf('.');
      if (dot > 0 && dot < path.length - 1) {
        ext = path.substring(dot);
      }
      final String filePath = p.join(audioDirPath, '$resolvedFileId$ext');
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
          fileName: '$resolvedFileId$ext',
          createAt: MPTimeUtils.nowUnixMilliseconds(),
          duration: _parseDurationSeconds(durationLabel),
          source: 'mobilePhone',
          fileId: resolvedFileId,
          isRemoved: true,
        ),
      );
      return playablePath;
    } catch (e, st) {
      debugPrint('MPAudioDetailCubit._downloadRecordToLocal: $e\n$st');
      return null;
    }
  }

  /// 与 [OmiMemoryDetailCubit._parseDurationSeconds] 一致，解析界面时长文案为秒。
  int? _parseDurationSeconds(String raw) {
    final String s = raw.trim().toLowerCase();
    if (s.isEmpty) {
      return null;
    }
    final RegExp mmss = RegExp(r'^(\d+):(\d{2})$');
    final RegExpMatch? mm = mmss.firstMatch(s);
    if (mm != null) {
      final int m = int.tryParse(mm.group(1) ?? '') ?? 0;
      final int sec = int.tryParse(mm.group(2) ?? '') ?? 0;
      return m * 60 + sec;
    }
    final RegExp hms = RegExp(r'(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?');
    final RegExpMatch? hm = hms.firstMatch(s);
    if (hm != null) {
      final int h = int.tryParse(hm.group(1) ?? '') ?? 0;
      final int m = int.tryParse(hm.group(2) ?? '') ?? 0;
      final int sec = int.tryParse(hm.group(3) ?? '') ?? 0;
      final int total = h * 3600 + m * 60 + sec;
      return total > 0 ? total : null;
    }
    return null;
  }

  @override
  Future<void> close() {
    _decoderDurationSub?.cancel();
    _decoderDurationSub = null;
    _stopPlaybackUiTimer();
    _audioPlayer.dispose();
    return super.close();
  }

  Future<void> onSummarizeTap(BuildContext context) async {
    final String recordUrl = (state.data?.recordUri ?? '').trim();
    final MPSummaryRecordRequest? req = await showMPMemoryGenerateSummarySheet(
      context,
      memoryId: memoryId,
      recordUrl: recordUrl,
      isRegen: false,
      onChangeMode: () {
        // TODO: 切换 Autopilot / 其它模式
      },
    );
    if (!context.mounted) return;
    if (req == null) return;
    await runSummaryRegeneration(req);
  }
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

String _formatDurationLabel(int? seconds) =>
    MPDateUtils.formatMemoryDurationCompact(seconds);

MPAudioDetailData _mapOnlyRecordToAudioData(
  MPMemoryStruct m,
  MPOnlyRecordMemoryStruct only,
) {
  final ({String primary, String secondary}) labels =
      MPDateUtils.resolveAudioRecordingLabels(
    title: m.title,
    content: m.content,
    showTime: m.showTime,
    createAt: m.createAt,
  );
  final String source = (only.source ?? m.source ?? '').trim();
  final String subtitle = labels.secondary.trim().isEmpty
      ? source
      : source.isNotEmpty
          ? '${labels.secondary}  ·  $source'
          : labels.secondary;

  final int? sec = m.duration;
  final Duration total = Duration(
    seconds: sec != null && sec > 0 ? sec : 0,
  );
  final String rightTime = _formatDurationLabel(sec);

  return MPAudioDetailData(
    title: labels.primary,
    subtitle: subtitle,
    leftTime: '0:00',
    rightTime: rightTime,
    total: total,
    recordFile: only.recordFile,
    recordUri: only.recordUri,
  );
}
