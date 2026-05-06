import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:memo_pin/audio/record/mp_audio_local_records_util.dart';
import 'package:memo_pin/cache/omi_cache_manager.dart';
import 'package:memo_pin/common/mp_date_utils.dart';
import 'package:memo_pin/common/mp_todo_priority_utils.dart';
import 'package:memo_pin/common/mp_memory_notification.dart';
import 'package:memo_pin/http/api/mp_memory.dart';
import 'package:memo_pin/http/api/mp_todo.dart' as MPTodo;
import 'package:memo_pin/http/schema/mp_data_model.dart';
import 'package:memo_pin/http/schema/mp_memory.dart';
import 'package:memo_pin/http/schema/mp_todo.dart';
import 'package:path/path.dart' as p;
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_detail_content_card.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_feed_block.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_insight_card.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_my_memos_card.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_resummary_card.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_todos_created_models.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_you_asked_card.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/omi_memory_action_content.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/omi_memory_transcript_item.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';

enum OmiMemoryDetailPhase { loading, loaded, error }

/// 详情主内容（转写 / Overview / Actions）的数据来源。
enum OmiMemoryDetailSource {
  /// 与 Feed 会话一致：取 [MPMemoryStruct.memoryFeed] 内 [MPMemoryFeedStruct.summaryMemory]。
  memoryFeedSummary,

  /// Memo 等：取根级 [MPMemoryStruct.summaryMemory]。
  rootSummaryMemory,
}

class OmiMemoryDetailState {
  const OmiMemoryDetailState({
    required this.phase,
    this.data,
    this.errorMessage,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.feedHasMore = false,
    this.isSummaryGenerating = false,
    this.isAudioPlaying = false,
  });

  final OmiMemoryDetailPhase phase;
  final MPMemoryDetailCardData? data;
  final String? errorMessage;

  /// 下拉刷新中（保持 [data] 展示）
  final bool isRefreshing;

  /// 底部加载更多中
  final bool isLoadingMore;

  /// 是否仍可请求更多 Feed（由详情首屏与 [getMemoryFeed] 的 `has_more` 更新）
  final bool feedHasMore;

  /// Memo 等场景：summary 正在生成时展示过渡 UI。
  final bool isSummaryGenerating;

  /// 播放器是否正在播放（用于同步 UI 的播放/暂停按钮状态）。
  final bool isAudioPlaying;

  OmiMemoryDetailState copyWith({
    OmiMemoryDetailPhase? phase,
    MPMemoryDetailCardData? data,
    String? errorMessage,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? feedHasMore,
    bool? isSummaryGenerating,
    bool? isAudioPlaying,
  }) {
    return OmiMemoryDetailState(
      phase: phase ?? this.phase,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      feedHasMore: feedHasMore ?? this.feedHasMore,
      isSummaryGenerating: isSummaryGenerating ?? this.isSummaryGenerating,
      isAudioPlaying: isAudioPlaying ?? this.isAudioPlaying,
    );
  }
}

const int _kMemoryFeedPageSize = 20;

class OmiMemoryDetailCubit extends Cubit<OmiMemoryDetailState> {
  OmiMemoryDetailCubit({required this.memoryId, this.detailSource = OmiMemoryDetailSource.memoryFeedSummary})
    : super(const OmiMemoryDetailState(phase: OmiMemoryDetailPhase.loading)) {
    _decoderDurationSub = _audioPlayer.durationStream.listen(_applyDecoderDurationToState);
    _playerStateSub = _audioPlayer.playerStateStream.listen((PlayerState ps) {
      if (isClosed) {
        return;
      }
      if (ps.processingState == ProcessingState.completed && !_audioPlayer.playing) {
        scheduleMicrotask(_tickMemoryDetailPlaybackUi);
      }
    });
  }

  /// 列表页传入，对应接口 `memory_id`。
  final String memoryId;

  /// 决定 [getMemoryDetail] 结果如何映射为 [MPMemoryDetailCardData]。
  final OmiMemoryDetailSource detailSource;

  String _feedCursor = '';
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration?>? _decoderDurationSub;
  String? _playingLocalPath;
  bool _isAudioPlaying = false;

  void _syncAudioPlayingFlag() {
    final OmiMemoryDetailState s = state;
    if (s.isAudioPlaying == _isAudioPlaying) {
      return;
    }
    emit(s.copyWith(isAudioPlaying: _isAudioPlaying));
  }

  Timer? _playbackUiTimer;
  StreamSubscription<Duration>? _positionStreamSub;

  int _suppressPlaybackCompletedUntilMs = 0;
  int _lastPlaybackEmitBucket = -1;

  Timer? _resummaryPollTimer;
  final Set<String> _pendingResummaryIds = <String>{};

  static const Duration _kPlaybackUiTick = Duration(milliseconds: 200);
  static const int _kEndSlackMs = 160;
  static const int _kSuppressCompletedAfterSourceMs = 900;
  static const int _kPlaybackEmitBucketMs = 500;

  /// 接口里的 [MPMemoryDetailCardData.audioTimeEnd] 多为 `5m3s`，与解码器 `5:03` 展示不一致；
  /// [just_audio] 的 [AudioPlayer.duration] 往往在 [setAudioSource] 后稍晚才就绪，
  /// 若仅依赖 [AudioPlayer.durationStream] 的首次事件，可能早于详情 [loaded] 被丢弃或错过，导致首播后总时长不刷新。
  void _applyDecoderDurationToState(Duration? d) {
    if (isClosed) {
      return;
    }
    if (d == null || d <= Duration.zero) {
      return;
    }
    final OmiMemoryDetailState s = state;
    if (s.phase != OmiMemoryDetailPhase.loaded || s.data == null) {
      return;
    }
    final MPMemoryDetailCardData cur = s.data!;
    final String nextEnd = _memoryPlaybackFormatMmSs(d);
    if (cur.audioTimeEnd == nextEnd) {
      return;
    }
    emit(s.copyWith(data: cur.copyWith(audioTimeEnd: nextEnd)));
    if (_isAudioPlaying) {
      scheduleMicrotask(_tickMemoryDetailPlaybackUi);
    }
  }

  /// 绑定音源后主动拉取时长（补足 [durationStream] 时机问题）。
  void _schedulePlayerDurationSync() {
    void tick() {
      if (isClosed) {
        return;
      }
      _applyDecoderDurationToState(_audioPlayer.duration);
    }

    tick();
    scheduleMicrotask(tick);
    Future<void>.delayed(const Duration(milliseconds: 120), tick);
  }

  static bool _reachedEndByPosition(Duration pos, Duration total, int marginMs) {
    final int t = total.inMilliseconds;
    if (t <= marginMs) {
      return false;
    }
    return pos.inMilliseconds >= t - marginMs;
  }

  void _armSuppressPlaybackCompleted() {
    _suppressPlaybackCompletedUntilMs = DateTime.now().millisecondsSinceEpoch + _kSuppressCompletedAfterSourceMs;
  }

  void _stopPlaybackUiTimer() {
    _playbackUiTimer?.cancel();
    _playbackUiTimer = null;
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
    _lastPlaybackEmitBucket = -1;
  }

  void _startPlaybackUiTimer() {
    _stopPlaybackUiTimer();
    _playbackUiTimer = Timer.periodic(_kPlaybackUiTick, (_) {
      _tickMemoryDetailPlaybackUi();
    });
    _positionStreamSub = _audioPlayer.positionStream.listen((Duration _) {
      if (isClosed) {
        return;
      }
      scheduleMicrotask(_tickMemoryDetailPlaybackUi);
    });
    _tickMemoryDetailPlaybackUi();
  }

  Duration _cardAudioTotal(MPMemoryDetailCardData d) {
    final int? sec = _parseDurationSeconds(d.audioTimeEnd);
    if (sec != null && sec > 0) {
      return Duration(seconds: sec);
    }
    return Duration.zero;
  }

  void _tickMemoryDetailPlaybackUi() {
    if (isClosed) {
      return;
    }
    final OmiMemoryDetailState s = state;
    if (s.phase != OmiMemoryDetailPhase.loaded || s.data == null) {
      _stopPlaybackUiTimer();
      return;
    }
    if (!_isAudioPlaying) {
      _stopPlaybackUiTimer();
      return;
    }

    final bool suppressCompleted = DateTime.now().millisecondsSinceEpoch < _suppressPlaybackCompletedUntilMs;

    final Duration pos = _audioPlayer.position;
    final Duration? dur = _audioPlayer.duration;
    final Duration totalFromCard = _cardAudioTotal(s.data!);
    final Duration totalRef = (dur != null && dur > Duration.zero) ? dur : totalFromCard;

    if (!suppressCompleted && _audioPlayer.processingState == ProcessingState.completed && !_audioPlayer.playing) {
      final bool nearEnd = _reachedEndByPosition(pos, totalRef, _kEndSlackMs * 4);
      final bool nearEndByDecoder =
          dur != null && dur > Duration.zero && _reachedEndByPosition(pos, dur, _kEndSlackMs * 4);
      final bool completedWithoutTotal = totalRef <= Duration.zero && (dur == null || dur <= Duration.zero);
      if (nearEnd || nearEndByDecoder || completedWithoutTotal) {
        _stopPlaybackUiTimer();
        _isAudioPlaying = false;
        _syncAudioPlayingFlag();
        final Duration end = totalRef > Duration.zero ? totalRef : (dur != null && dur > Duration.zero ? dur : pos);
        final String endMs = '${end.inMilliseconds}';
        final MPMemoryDetailCardData d = s.data!;
        final String nextAudioTimeEnd = completedWithoutTotal && end > Duration.zero
            ? _memoryPlaybackFormatMmSs(end)
            : d.audioTimeEnd;
        emit(
          s.copyWith(
            data: d.copyWith(audioTimeStart: endMs, audioTimeEnd: nextAudioTimeEnd),
          ),
        );
        return;
      }
    }

    if (_reachedEndByPosition(pos, totalRef, _kEndSlackMs)) {
      _stopPlaybackUiTimer();
      _isAudioPlaying = false;
      _syncAudioPlayingFlag();
      final String endMs = '${totalRef.inMilliseconds}';
      emit(s.copyWith(data: s.data!.copyWith(audioTimeStart: endMs)));
      return;
    }

    final String msStr = '${pos.inMilliseconds}';
    final int bucket = pos.inMilliseconds ~/ _kPlaybackEmitBucketMs;
    if (bucket == _lastPlaybackEmitBucket || msStr == s.data!.audioTimeStart) {
      return;
    }
    _lastPlaybackEmitBucket = bucket;
    emit(s.copyWith(data: s.data!.copyWith(audioTimeStart: msStr)));
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

  ({MPMemoryDetailCardData data, String feedCursor, bool feedHasMore, bool isSummaryGenerating})?
  _loadCachedDetailBundleIfAllowed() {
    if (!_isInCachedFirstPage()) return null;
    final dynamic cached = OmiCacheManager().getMemoryDetail(memoryId);
    if (cached is! Map) return null;
    try {
      final MPMemoryStruct m = MPMemoryStruct.fromJson(Map<String, dynamic>.from(cached));
      return _mapDetailResponse(m);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    final ({MPMemoryDetailCardData data, String feedCursor, bool feedHasMore, bool isSummaryGenerating})? cached =
        _loadCachedDetailBundleIfAllowed();
    final bool hasCached = cached != null;
    if (hasCached) {
      _feedCursor = cached.feedCursor;
      emit(
        OmiMemoryDetailState(
          phase: OmiMemoryDetailPhase.loaded,
          data: cached.data,
          feedHasMore: cached.feedHasMore,
          isSummaryGenerating: cached.isSummaryGenerating,
        ),
      );
    } else {
      emit(const OmiMemoryDetailState(phase: OmiMemoryDetailPhase.loading));
    }
    try {
      final MPGetMemoryV2DetailResponse? resp = await getMemoryDetail(MPGetMemoryV2DetailRequest(memoryId: memoryId));
      if (resp == null) {
        throw StateError('getMemoryDetail failed');
      }
      final ({MPMemoryDetailCardData data, String feedCursor, bool feedHasMore, bool isSummaryGenerating}) bundle =
          _mapDetailResponse(resp.memoryDetail);
      if (_isInCachedFirstPage()) {
        OmiCacheManager().putMemoryDetail(memoryId, resp.memoryDetail.toJson());
      }
      _feedCursor = bundle.feedCursor;
      emit(
        OmiMemoryDetailState(
          phase: OmiMemoryDetailPhase.loaded,
          data: bundle.data,
          feedHasMore: bundle.feedHasMore,
          isSummaryGenerating: bundle.isSummaryGenerating,
        ),
      );
    } catch (e) {
      if (!hasCached) {
        emit(OmiMemoryDetailState(phase: OmiMemoryDetailPhase.error, errorMessage: e.toString()));
      }
    }
  }

  /// Memory / Memo 详情：确认生成后请求 [summaryRecord]（无全页 loading，仅 [OmiAudioDetailPage] 有）。
  Future<void> runSummaryRegeneration(MPSummaryRecordRequest req) async {
    final OmiMemoryDetailState cur = state;
    if (cur.phase != OmiMemoryDetailPhase.loaded || cur.data == null) {
      return;
    }
    if (isClosed) return;
    try {
      final MPSummaryRecordResponse? summary = await summaryRecord(req);
      if (isClosed) return;
      if (summary == null || summary.baseResp.code != 0) {
        MPToastUtils.showMessage(summary?.baseResp.message ?? 'Generation failed. Please try again later.');
        return;
      }
      final String sid = (summary.summaryId ?? '').trim();
      if (sid.isEmpty) {
        MPToastUtils.showMessage('Generation failed. Please try again later.');
        return;
      }
      _pendingResummaryIds.add(sid);
      _insertResummaryLoadingCard(summaryMemoryId: sid);
      _ensureResummaryPolling();
    } catch (_) {
      if (!isClosed) {
        MPToastUtils.showMessage('Generation failed. Please try again later.');
      }
    }
  }

  void _insertResummaryLoadingCard({required String summaryMemoryId}) {
    final OmiMemoryDetailState cur = state;
    if (cur.phase != OmiMemoryDetailPhase.loaded || cur.data == null) return;
    final MPMemoryDetailCardData d = cur.data!;
    final bool already = d.feedBlocks.any((MPMemoryFeedBlock b) {
      return b is MPMemoryFeedResummaryLoadingBlock && b.data.summaryMemoryId == summaryMemoryId;
    });
    if (already) return;
    final List<MPMemoryFeedBlock> blocks = <MPMemoryFeedBlock>[
      MPMemoryFeedResummaryLoadingBlock(
        MPMemoryResummaryLoadingCardData(headerTimeLabel: 'Just now', summaryMemoryId: summaryMemoryId),
      ),
      ...d.feedBlocks,
    ];
    emit(cur.copyWith(data: d.copyWith(feedBlocks: blocks)));
  }

  void _cancelResummaryPolling() {
    _resummaryPollTimer?.cancel();
    _resummaryPollTimer = null;
  }

  void _ensureResummaryPolling() {
    if (_resummaryPollTimer != null) return;
    _resummaryPollTimer = Timer.periodic(const Duration(seconds: 3), (Timer _) async {
      if (isClosed) {
        _cancelResummaryPolling();
        return;
      }

      final MPGetMemorySummaryStatusResponse? resp = await getMemorySummaryStatus(
        MPGetMemorySummaryStatusRequest(memoryId: memoryId),
      );
      if (isClosed) {
        _cancelResummaryPolling();
        return;
      }
      if (resp == null || resp.baseResp.code != 0) {
        return;
      }
      final bool anyCompleted = await _applyResummaryStatuses(resp);
      if (anyCompleted && !isClosed) {
        // 任意任务从「进行中」变为「已完成」：刷新列表 + 整体刷新详情页
        //（避免只局部替换导致与服务端 feeds 不一致）
        MPMemoryNotification.notifyMemoryListRefresh();
        await refresh();
      }
      if (_pendingResummaryIds.isEmpty) _cancelResummaryPolling();
    });
  }

  Future<bool> _applyResummaryStatuses(MPGetMemorySummaryStatusResponse resp) async {
    // 只处理本地 [_pendingResummaryIds] 中的任务；以 items 里对应 resummary_memory_id + resummary_status 为准。
    final List<MPMemorySummaryStatusItem> items = resp.resummaryMemoriesStatus;
    if (items.isEmpty) {
      return false;
    }
    bool anyCompleted = false;
    for (final MPMemorySummaryStatusItem it in items) {
      final String id = it.summaryMemoryId.trim();
      if (id.isEmpty || !_pendingResummaryIds.contains(id)) {
        continue;
      }
      final bool done = _applyOneResummaryStatus(summaryMemoryId: id, status: it.summaryStatus);
      if (done) {
        anyCompleted = true;
      }
    }
    return anyCompleted;
  }

  bool _applyOneResummaryStatus({required String summaryMemoryId, required int status}) {
    final String id = summaryMemoryId.trim();
    if (id.isEmpty || !_pendingResummaryIds.contains(id)) {
      return false;
    }
    if (status != 2) {
      return false;
    }
    final OmiMemoryDetailState cur = state;
    if (cur.phase != OmiMemoryDetailPhase.loaded || cur.data == null) {
      return false;
    }
    _pendingResummaryIds.remove(id);
    return true;
  }

  Future<void> retry() => load();

  /// 重命名成功后更新本地标题（接口由 [MPMemoryUpdateNameDialog] 调用）。
  void updateTitle(String newTitle) {
    if (state.phase != OmiMemoryDetailPhase.loaded || state.data == null) {
      return;
    }
    final String t = newTitle.trim();
    if (t.isEmpty) {
      return;
    }
    emit(state.copyWith(data: state.data!.copyWith(title: t)));
  }

  /// 返回 `true` 表示已暂停或已开始播放；`false` 表示未执行（如下载失败）。
  Future<bool> onPlayTap() async {
    final OmiMemoryDetailState cur = state;
    if (cur.phase != OmiMemoryDetailPhase.loaded || cur.data == null) {
      return false;
    }
    if (_isAudioPlaying) {
      _stopPlaybackUiTimer();
      await _audioPlayer.pause();
      _isAudioPlaying = false;
      _syncAudioPlayingFlag();
      _lastPlaybackEmitBucket = -1;
      return true;
    }
    final String? localPath = await _ensurePlayableLocalPath(cur.data!);
    if (localPath == null || localPath.isEmpty) {
      MPToastUtils.showMessage('Failed to download audio. Please try again later.');
      return false;
    }
    bool shouldRunPlaybackUi = false;
    try {
      final bool rebound = _playingLocalPath != localPath;
      if (rebound) {
        _armSuppressPlaybackCompleted();
        await MPAudioLocalRecordsUtil.bindLocalAudioForPlayback(_audioPlayer, localPath);
        _playingLocalPath = localPath;
      }
      _schedulePlayerDurationSync();
      if (_audioPlayer.processingState == ProcessingState.completed) {
        await _audioPlayer.seek(Duration.zero);
      }
      unawaited(
        _audioPlayer.play().catchError((Object e, StackTrace st) {
          if (isClosed) {
            return;
          }
          debugPrint('OmiMemoryDetailCubit.onPlayTap play future: $e\n$st');
          _stopPlaybackUiTimer();
          _isAudioPlaying = false;
          _syncAudioPlayingFlag();
          MPToastUtils.showMessage('Failed to play audio.');
        }),
      );
      _isAudioPlaying = true;
      _syncAudioPlayingFlag();
      _lastPlaybackEmitBucket = -1;
      shouldRunPlaybackUi = true;
      return true;
    } catch (e, st) {
      debugPrint('OmiMemoryDetailCubit.onPlayTap: $e\n$st');
      MPToastUtils.showMessage('Failed to play audio.');
      return false;
    } finally {
      if (!isClosed && shouldRunPlaybackUi) {
        _startPlaybackUiTimer();
      }
    }
  }

  Future<bool> _prepareBoundPlayerForSeek(MPMemoryDetailCardData data) async {
    final String? localPath = await _ensurePlayableLocalPath(data);
    if (localPath == null || localPath.isEmpty) {
      MPToastUtils.showMessage('Failed to download audio. Please try again later.');
      return false;
    }
    final bool rebound = _playingLocalPath != localPath;
    if (rebound) {
      _armSuppressPlaybackCompleted();
      await MPAudioLocalRecordsUtil.bindLocalAudioForPlayback(_audioPlayer, localPath);
      _playingLocalPath = localPath;
    }
    _schedulePlayerDurationSync();
    return true;
  }

  /// 绑定音源后 [AudioPlayer.duration] 可能略晚于首帧，短暂轮询以对齐 Transcript / 波形 seek。
  Future<Duration> _resolveTotalRef(MPMemoryDetailCardData data) async {
    Duration totalRef = _audioPlayer.duration ?? _cardAudioTotal(data);
    if (totalRef > Duration.zero) {
      return totalRef;
    }
    for (int i = 0; i < 8; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 64));
      totalRef = _audioPlayer.duration ?? _cardAudioTotal(data);
      if (totalRef > Duration.zero) {
        return totalRef;
      }
    }
    return totalRef;
  }

  Future<bool> _seekToTargetAndStartUi(
    MPMemoryDetailCardData data,
    Duration position, {
    Duration? prefetchedTotalRef,
  }) async {
    final Duration totalRef = prefetchedTotalRef ?? await _resolveTotalRef(data);
    Duration target = position;
    if (target.isNegative) {
      target = Duration.zero;
    }
    if (totalRef > Duration.zero && target > totalRef) {
      target = totalRef;
    }
    await _audioPlayer.seek(target);
    _lastPlaybackEmitBucket = -1;

    if (!_audioPlayer.playing) {
      unawaited(
        _audioPlayer.play().catchError((Object e, StackTrace st) {
          if (isClosed) {
            return;
          }
          debugPrint('OmiMemoryDetailCubit seek play future: $e\n$st');
          _stopPlaybackUiTimer();
          _isAudioPlaying = false;
          _syncAudioPlayingFlag();
          MPToastUtils.showMessage('Failed to play audio.');
        }),
      );
    }
    _isAudioPlaying = true;
    _syncAudioPlayingFlag();
    _lastPlaybackEmitBucket = -1;
    scheduleMicrotask(_tickMemoryDetailPlaybackUi);
    return true;
  }

  /// 从指定位置开始播放（点击 Transcript 跳转）；若已在播放则仅 seek 并保持播放中。
  Future<bool> onSeekPlay(Duration position) async {
    final OmiMemoryDetailState cur = state;
    if (cur.phase != OmiMemoryDetailPhase.loaded || cur.data == null) {
      return false;
    }
    bool shouldRunPlaybackUi = false;
    try {
      if (!await _prepareBoundPlayerForSeek(cur.data!)) {
        return false;
      }
      shouldRunPlaybackUi = true;
      return await _seekToTargetAndStartUi(cur.data!, position);
    } catch (e, st) {
      debugPrint('OmiMemoryDetailCubit.onSeekPlay: $e\n$st');
      MPToastUtils.showMessage('Failed to play audio.');
      return false;
    } finally {
      if (!isClosed && shouldRunPlaybackUi) {
        _startPlaybackUiTimer();
      }
    }
  }

  /// 点击波形：按 0..1 宽度比例 seek（与解码器总时长对齐，不依赖卡片解析出的总时长）。
  Future<bool> onSeekByWaveFraction(double rawFraction) async {
    final double fraction = rawFraction.clamp(0.0, 1.0);
    final OmiMemoryDetailState cur = state;
    if (cur.phase != OmiMemoryDetailPhase.loaded || cur.data == null) {
      return false;
    }
    bool shouldRunPlaybackUi = false;
    try {
      if (!await _prepareBoundPlayerForSeek(cur.data!)) {
        return false;
      }
      final Duration totalRef = await _resolveTotalRef(cur.data!);
      if (totalRef <= Duration.zero) {
        MPToastUtils.showMessage('Failed to play audio.');
        return false;
      }
      final int ms = (totalRef.inMilliseconds * fraction).round();
      shouldRunPlaybackUi = true;
      return await _seekToTargetAndStartUi(
        cur.data!,
        Duration(milliseconds: ms),
        prefetchedTotalRef: totalRef,
      );
    } catch (e, st) {
      debugPrint('OmiMemoryDetailCubit.onSeekByWaveFraction: $e\n$st');
      MPToastUtils.showMessage('Failed to play audio.');
      return false;
    } finally {
      if (!isClosed && shouldRunPlaybackUi) {
        _startPlaybackUiTimer();
      }
    }
  }

  Future<String?> _ensurePlayableLocalPath(MPMemoryDetailCardData data) async {
    // 本地是否有对应的文件
    final String recordUri = (data.recordUri ?? '').trim();
    final String fileId = MPAudioLocalRecordsUtil.getFileIdFromRecordFile(recordUri);
    final MPAudioLocalRecord? record = await MPAudioLocalRecordsUtil.instance.queryByFileId(fileId);
    final String localPath = record?.path ?? '';
    if (localPath.isNotEmpty) {
      return localPath;
    }
    // 本地没有对应的文件，则下载
    final String downloadUrl = (data.recordFile ?? '').trim();
    if (downloadUrl.isEmpty) {
      return '';
    }
    return _downloadRecordToLocal(downloadUrl: downloadUrl, fileId: fileId, durationLabel: data.audioTimeEnd);
  }

  /// 下载录音到本地
  Future<String?> _downloadRecordToLocal({
    required String downloadUrl,
    required String fileId,
    required String durationLabel,
  }) async {
    try {
      final Uri uri = Uri.parse(downloadUrl);
      final http.Response? response = await MPAudioLocalRecordsUtil.httpGetAudioDownloadUrl(downloadUrl);
      if (response == null || response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final String audioDirPath = await MPAudioLocalRecordsUtil.ensureLocalStorageDirectoryPath();
      if (fileId.isEmpty) {
        fileId = DateTime.now().millisecondsSinceEpoch.toString();
      }
      String ext = '.m4a';
      final String path = uri.path;
      final int dot = path.lastIndexOf('.');
      if (dot > 0 && dot < path.length - 1) {
        ext = path.substring(dot);
      }
      final String filePath = p.join(audioDirPath, '$fileId$ext');
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes, flush: true);
      final String? playablePath = await MPAudioLocalRecordsUtil.adjustAudioFileIfWrongExtension(filePath);
      if (playablePath == null) {
        return null;
      }

      await MPAudioLocalRecordsUtil.instance.load();
      await MPAudioLocalRecordsUtil.instance.add(
        MPAudioLocalRecord(
          path: playablePath,
          fileName: '$fileId$ext',
          createAt: DateTime.now().millisecondsSinceEpoch,
          duration: _parseDurationSeconds(durationLabel),
          source: 'mobilePhone',
          fileId: fileId,
          isRemoved: true,
        ),
      );
      return playablePath;
    } catch (e, st) {
      debugPrint('OmiMemoryDetailCubit._downloadRecordToLocal: $e\n$st');
      return null;
    }
  }

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

  ({MPMemoryDetailCardData data, String feedCursor, bool feedHasMore, bool isSummaryGenerating}) _mapDetailResponse(
    MPMemoryStruct m,
  ) {
    return switch (detailSource) {
      OmiMemoryDetailSource.memoryFeedSummary => mpMemoryStructToDetailBundle(m),
      OmiMemoryDetailSource.rootSummaryMemory => mpMemoryStructToMemoDetailBundle(m),
    };
  }

  /// 下拉刷新：重新拉详情，不打断已展示内容。
  Future<void> refresh() async {
    final OmiMemoryDetailState cur = state;
    if (cur.phase == OmiMemoryDetailPhase.loading) {
      return;
    }
    if (cur.phase == OmiMemoryDetailPhase.loaded && cur.data != null) {
      emit(cur.copyWith(isRefreshing: true));
    }
    try {
      final MPGetMemoryV2DetailResponse? resp = await getMemoryDetail(MPGetMemoryV2DetailRequest(memoryId: memoryId));
      if (resp == null) {
        throw StateError('getMemoryDetail failed');
      }
      final ({MPMemoryDetailCardData data, String feedCursor, bool feedHasMore, bool isSummaryGenerating}) bundle =
          _mapDetailResponse(resp.memoryDetail);
      if (_isInCachedFirstPage()) {
        OmiCacheManager().putMemoryDetail(memoryId, resp.memoryDetail.toJson());
      }
      _feedCursor = bundle.feedCursor;
      emit(
        OmiMemoryDetailState(
          phase: OmiMemoryDetailPhase.loaded,
          data: bundle.data,
          feedHasMore: bundle.feedHasMore,
          isRefreshing: false,
          isLoadingMore: false,
          isSummaryGenerating: bundle.isSummaryGenerating,
        ),
      );
    } catch (e) {
      if (state.phase == OmiMemoryDetailPhase.loaded && state.data != null) {
        emit(state.copyWith(isRefreshing: false));
        MPToastUtils.showMessage('Refresh failed. Please try again later.');
      } else {
        emit(OmiMemoryDetailState(phase: OmiMemoryDetailPhase.error, errorMessage: e.toString()));
      }
    }
  }

  // /// 上拉加载更多 Feed 块，追加到 [MPMemoryDetailCardData.feedBlocks]。
  // Future<void> loadMoreFeeds() async {
  //   final OmiMemoryDetailState cur = state;
  //   if (cur.phase != OmiMemoryDetailPhase.loaded || cur.data == null) {
  //     return;
  //   }
  //   if (!cur.feedHasMore || cur.isLoadingMore) {
  //     return;
  //   }
  //
  //   emit(cur.copyWith(isLoadingMore: true));
  //   try {
  //     final MPGetMemoryFeedResponse? resp = await getMemoryFeed(
  //       MPGetMemoryFeedRequest(
  //         memoryId: memoryId,
  //         pageSize: _kMemoryFeedPageSize,
  //         cursor: _feedCursor,
  //       ),
  //     );
  //     if (resp == null) {
  //       emit(state.copyWith(isLoadingMore: false, feedHasMore: false));
  //       MPToastUtils.showMessage('Couldn\'t load more.');
  //       return;
  //     }
  //     final List<MPFeedCardStruct> cards = resp.feeds ?? const <MPFeedCardStruct>[];
  //     if (cards.isEmpty) {
  //       emit(
  //         state.copyWith(
  //           isLoadingMore: false,
  //           feedHasMore: resp.hasMore ?? false,
  //         ),
  //       );
  //       return;
  //     }
  //     final List<MPMemoryFeedBlock> built = _buildFeedBlocksFromCards(cards, cur.data?.title);
  //     final String? lastId = _lastFeedCardId(cards);
  //     if (lastId != null && lastId.isNotEmpty) {
  //       _feedCursor = lastId;
  //     }
  //
  //     final MPMemoryDetailCardData d = state.data!;
  //     final List<MPMemoryFeedBlock> merged =
  //         List<MPMemoryFeedBlock>.from(d.feedBlocks)..addAll(built);
  //     final MPMemoryDetailCardData nextData = MPMemoryDetailCardData(
  //       memoryId: d.memoryId,
  //       title: d.title,
  //       metaLine: d.metaLine,
  //       audioTimeStart: d.audioTimeStart,
  //       audioTimeEnd: d.audioTimeEnd,
  //       recordFile: d.recordFile,
  //       recordUri: d.recordUri,
  //       waveformHeights: d.waveformHeights,
  //       speakerLabels: d.speakerLabels,
  //       overviewText: d.overviewText,
  //       transcriptItems: d.transcriptItems,
  //       actionItems: d.actionItems,
  //       initialSegment: d.initialSegment,
  //       feedBlocks: merged,
  //     );
  //     emit(
  //       state.copyWith(
  //         data: nextData,
  //         isLoadingMore: false,
  //         feedHasMore: resp.hasMore ?? false,
  //       ),
  //     );
  //   } catch (_) {
  //     emit(state.copyWith(isLoadingMore: false));
  //     MPToastUtils.showMessage('Couldn\'t load more.');
  //   }
  // }

  /// 快捷输入新增 Todo：在 [MPMemoryDetailCardData.feedBlocks] 末尾追加一条 TODOS CREATED。
  void addTodoFromQuickInput(String text) {
    final String title = text.trim();
    if (title.isEmpty) return;
    final OmiMemoryDetailState cur = state;
    if (cur.phase != OmiMemoryDetailPhase.loaded || cur.data == null) return;

    final MPMemoryDetailCardData d = cur.data!;
    final MPMemoryCreatedTodoLineData newItem = MPMemoryCreatedTodoLineData(
      id: '',
      title: title,
      priority: MPMemoryTodoPriorityKind.medium,
      deadlineLabel: null,
    );

    final List<MPMemoryFeedBlock> nextBlocks = List<MPMemoryFeedBlock>.from(d.feedBlocks);
    int existingIndex = -1;
    for (int i = nextBlocks.length - 1; i >= 0; i--) {
      if (nextBlocks[i] is MPMemoryFeedTodosCreatedBlock) {
        existingIndex = i;
        break;
      }
    }
    if (existingIndex >= 0) {
      final MPMemoryFeedTodosCreatedBlock block = nextBlocks[existingIndex] as MPMemoryFeedTodosCreatedBlock;
      final MPMemoryTodosCreatedCardData old = block.data;
      final List<MPMemoryCreatedTodoLineData> items = List<MPMemoryCreatedTodoLineData>.from(old.items)..add(newItem);
      nextBlocks[existingIndex] = MPMemoryFeedTodosCreatedBlock(
        MPMemoryTodosCreatedCardData(
          headerTimeLabel: old.headerTimeLabel.isNotEmpty ? old.headerTimeLabel : 'Just now',
          items: items,
        ),
      );
    } else {
      nextBlocks.add(
        MPMemoryFeedTodosCreatedBlock(
          MPMemoryTodosCreatedCardData(headerTimeLabel: 'Just now', items: <MPMemoryCreatedTodoLineData>[newItem]),
        ),
      );
    }

    final MPMemoryDetailCardData nextData = MPMemoryDetailCardData(
      memoryId: d.memoryId,
      title: d.title,
      metaLine: d.metaLine,
      audioTimeStart: d.audioTimeStart,
      audioTimeEnd: d.audioTimeEnd,
      recordFile: d.recordFile,
      recordUri: d.recordUri,
      waveformHeights: d.waveformHeights,
      speakerLabels: d.speakerLabels,
      overviewText: d.overviewText,
      transcriptItems: d.transcriptItems,
      actionItems: d.actionItems,
      initialSegment: d.initialSegment,
      feedBlocks: nextBlocks,
    );

    emit(cur.copyWith(data: nextData));
  }

  /// 快捷输入新增 Memo：合并进同一「MY MEMOS」块（与 [addTodoFromQuickInput] 行为一致）。
  void addMemoFromQuickInput(String text) {
    final String line = text.trim();
    if (line.isEmpty) return;
    final OmiMemoryDetailState cur = state;
    if (cur.phase != OmiMemoryDetailPhase.loaded || cur.data == null) return;

    final MPMemoryDetailCardData d = cur.data!;
    final MPMemoryMyMemoLine newLine = MPMemoryMyMemoLine(text: line, type: MPMemoType.manualMemo);

    final List<MPMemoryFeedBlock> nextBlocks = List<MPMemoryFeedBlock>.from(d.feedBlocks);
    int existingIndex = -1;
    for (int i = nextBlocks.length - 1; i >= 0; i--) {
      if (nextBlocks[i] is MPMemoryFeedMyMemoBlock) {
        existingIndex = i;
        break;
      }
    }
    if (existingIndex >= 0) {
      final MPMemoryFeedMyMemoBlock block = nextBlocks[existingIndex] as MPMemoryFeedMyMemoBlock;
      final MPMemoryMyMemosCardData old = block.data;
      final List<MPMemoryMyMemoLine> lines = List<MPMemoryMyMemoLine>.from(old.lines)..add(newLine);
      nextBlocks[existingIndex] = MPMemoryFeedMyMemoBlock(
        MPMemoryMyMemosCardData(
          headerTimeLabel: old.headerTimeLabel.isNotEmpty ? old.headerTimeLabel : 'Just now',
          sourceLine: old.sourceLine,
          lines: lines,
        ),
      );
    } else {
      nextBlocks.add(
        MPMemoryFeedMyMemoBlock(
          MPMemoryMyMemosCardData(headerTimeLabel: 'Just now', lines: <MPMemoryMyMemoLine>[newLine]),
        ),
      );
    }

    final MPMemoryDetailCardData nextData = MPMemoryDetailCardData(
      memoryId: d.memoryId,
      title: d.title,
      metaLine: d.metaLine,
      audioTimeStart: d.audioTimeStart,
      audioTimeEnd: d.audioTimeEnd,
      recordFile: d.recordFile,
      recordUri: d.recordUri,
      waveformHeights: d.waveformHeights,
      speakerLabels: d.speakerLabels,
      overviewText: d.overviewText,
      transcriptItems: d.transcriptItems,
      actionItems: d.actionItems,
      initialSegment: d.initialSegment,
      feedBlocks: nextBlocks,
    );

    emit(cur.copyWith(data: nextData));
  }

  Future<bool> _deleteTodoApi(MPMemoryCreatedTodoLineData item) async {
    final String? todoId = item.id?.trim();
    if (todoId == null || todoId.isEmpty) {
      // 本地临时项（未落库）无需调接口，直接返回成功以保持 UI 行为一致。
      return true;
    }

    final MPDeleteTodoResponse? resp = await MPTodo.deleteTodo(MPDeleteTodoRequest(todoId: todoId));
    return resp != null && resp.baseResp.code == 0;
  }

  /// 删除「TODOS CREATED」里指定块中的条目（接口成功后更新 UI）。
  Future<bool> deleteCreatedTodoAt(int feedBlockIndex, int itemIndex) async {
    final OmiMemoryDetailState cur = state;
    if (cur.phase != OmiMemoryDetailPhase.loaded || cur.data == null) {
      return false;
    }
    final MPMemoryDetailCardData d = cur.data!;
    if (feedBlockIndex < 0 || feedBlockIndex >= d.feedBlocks.length) {
      return false;
    }
    final MPMemoryFeedBlock block = d.feedBlocks[feedBlockIndex];
    if (block is! MPMemoryFeedTodosCreatedBlock) return false;
    final MPMemoryTodosCreatedCardData todos = block.data;
    if (itemIndex < 0 || itemIndex >= todos.items.length) return false;

    final MPMemoryCreatedTodoLineData target = todos.items[itemIndex];
    final bool ok = await _deleteTodoApi(target);
    if (!ok) return false;

    final List<MPMemoryCreatedTodoLineData> nextItems = List<MPMemoryCreatedTodoLineData>.from(todos.items)
      ..removeAt(itemIndex);

    final List<MPMemoryFeedBlock> nextBlocks = List<MPMemoryFeedBlock>.from(d.feedBlocks);
    if (nextItems.isEmpty) {
      nextBlocks.removeAt(feedBlockIndex);
    } else {
      nextBlocks[feedBlockIndex] = MPMemoryFeedTodosCreatedBlock(
        MPMemoryTodosCreatedCardData(headerTimeLabel: todos.headerTimeLabel, items: nextItems),
      );
    }

    final MPMemoryDetailCardData nextData = MPMemoryDetailCardData(
      memoryId: d.memoryId,
      title: d.title,
      metaLine: d.metaLine,
      audioTimeStart: d.audioTimeStart,
      audioTimeEnd: d.audioTimeEnd,
      recordFile: d.recordFile,
      recordUri: d.recordUri,
      waveformHeights: d.waveformHeights,
      speakerLabels: d.speakerLabels,
      overviewText: d.overviewText,
      transcriptItems: d.transcriptItems,
      actionItems: d.actionItems,
      initialSegment: d.initialSegment,
      feedBlocks: nextBlocks,
    );

    emit(cur.copyWith(data: nextData));
    return true;
  }

  @override
  Future<void> close() {
    _cancelResummaryPolling();
    _decoderDurationSub?.cancel();
    _decoderDurationSub = null;
    _stopPlaybackUiTimer();
    _playerStateSub?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}

/// 解码器时长写入 [MPMemoryDetailCardData.audioTimeEnd]（与详情页波形右侧总时长解析一致，支持 `h:mm:ss` / `m:ss`）。
String _memoryPlaybackFormatMmSs(Duration d) {
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

String? _lastFeedCardId(List<MPFeedCardStruct> feeds) {
  for (int i = feeds.length - 1; i >= 0; i--) {
    final String? id = feeds[i].id;
    if (id != null && id.isNotEmpty) {
      return id;
    }
  }
  return null;
}

List<MPMemoryFeedBlock> _buildFeedBlocksFromCards(List<MPFeedCardStruct> feeds, String? title) {
  final List<MPMemoryFeedBlock> feedBlocks = <MPMemoryFeedBlock>[];
  for (final MPFeedCardStruct f in feeds) {
    final int kind = _resolveFeedCardKind(f);
    if (kind == _kFeedUnknownInsight) {
      continue;
    }
    if (kind == MPFeedCardType.myMemo) {
      final List<MPMemoStruct> memos = f.memos ?? const <MPMemoStruct>[];
      if (memos.isEmpty) {
        continue;
      }
      feedBlocks.add(
        MPMemoryFeedMyMemoBlock(
          MPMemoryMyMemosCardData(
            headerTimeLabel: _feedCardHeaderTimeLabel(f.createAt),
            lines: memos
                .map(
                  (MPMemoStruct memo) => MPMemoryMyMemoLine(
                    text: memo.title,
                    type: memo.type ?? MPMemoType.highlightMemo,
                    memoId: memo.id.trim().isEmpty ? null : memo.id,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      );
      continue;
    }
    if (kind == MPFeedCardType.todosCreated) {
      final List<MPTodoStruct> todos = f.todos ?? const <MPTodoStruct>[];
      if (todos.isEmpty) {
        continue;
      }
      feedBlocks.add(
        MPMemoryFeedTodosCreatedBlock(
          MPMemoryTodosCreatedCardData(
            headerTimeLabel: _feedCardHeaderTimeLabel(f.createAt),
            items: todos.map(_mptodoToCreatedLine).toList(growable: false),
          ),
        ),
      );
      continue;
    }
    if (kind == MPFeedCardType.youAsked) {
      feedBlocks.add(
        MPMemoryFeedYouAskedBlock(
          MPMemoryYouAskedCardData(
            headerTimeLabel: _feedCardHeaderTimeLabel(f.createAt),
            userMessage: f.askAICard?.ask ?? '',
            aiReply: f.askAICard?.answer ?? '',
            count: f.askAICard?.count
          ),
        ),
      );
      continue;
    }
    if (kind == MPFeedCardType.resummary) {
      final String mainTitle = (f.title ?? '').trim();
      final String body = (f.content ?? '').trim();
      if (mainTitle.isEmpty && body.isEmpty) {
        continue;
      }
      feedBlocks.add(
        MPMemoryFeedResummaryBlock(
          MPMemoryResummaryCardData(
            headerTimeLabel: _feedCardHeaderTimeLabel(f.createAt),
            mainTitle: mainTitle.isNotEmpty ? mainTitle : 'Resummary',
            sectionTitle: 'Summary',
            bodyText: body.isNotEmpty ? body : ' ',
          ),
        ),
      );
      continue;
    }

    final String categoryTitle;
    final String bodyText;
    if (kind == MPFeedCardType.followUpList) {
      final String titleRaw = (f.title ?? '').trim();
      bodyText = (f.content ?? '').trim();
      // if (bodyText.isEmpty) {
      //   continue;
      // }
      categoryTitle = titleRaw.isNotEmpty ? titleRaw : 'FOLLOW-UP HIGHLIGHTS';
    } else {
      // MPFeedCardType.insight：纯文本 content + suggestion（卡片内分段展示，非 Markdown）
      categoryTitle = (f.title ?? '').trim();
      final String content = (f.content ?? '').trim();
      final String suggestion = (f.suggestion ?? '').trim();
      if (content.isEmpty && suggestion.isEmpty) {
        continue;
      }
      final String bodyForTodo = <String>[
        if (content.isNotEmpty) content,
        if (suggestion.isNotEmpty) 'Suggestion: $suggestion',
      ].join('\n\n');
      feedBlocks.add(
        MPMemoryFeedInsightBlock(
          MPMemoryInsightItemData(
            tone: MPInsightCardTone.business,
            timeLabel: _feedCardTimeLabel(f.createAt),
            bodyText: bodyForTodo,
            categoryTitle: categoryTitle,
            title: title ?? '',
            useMarkdown: false,
            insightContent: content.isNotEmpty ? content : null,
            insightSuggestion: suggestion.isNotEmpty ? suggestion : null,
            hasAddedTodo: f.hasAddedTodo == true,
          ),
        ),
      );
      continue;
    }

    feedBlocks.add(
      MPMemoryFeedInsightBlock(
        MPMemoryInsightItemData(
          tone: MPInsightCardTone.followUp,
          timeLabel: _feedCardTimeLabel(f.createAt),
          bodyText: bodyText,
          title: title ?? '',
          categoryTitle: categoryTitle,
          hasAddedTodo: f.hasAddedTodo == true,
        ),
      ),
    );
  }
  return feedBlocks;
}

/// 依次取第一个非空（trim 后）字符串；用于录音路径：`summary` 与 `only_record` 可能分开展示字段。
String? _firstNonEmptyDetailString(Iterable<String?> candidates) {
  for (final String? c in candidates) {
    final String t = (c ?? '').trim();
    if (t.isNotEmpty) {
      return t;
    }
  }
  return null;
}

/// 详情映射结果：主卡片数据 + 分页加载 Feed 所需的游标与 unknown insight 计数。
({MPMemoryDetailCardData data, String feedCursor, bool feedHasMore, bool isSummaryGenerating})
_mpMemoryStructToDetailBundleFromSources(
  MPMemoryStruct m, {
  required MPSummaryMemoryStruct? sm,
  required List<MPFeedCardStruct> feedCards,
}) {
  final bool isSummaryGenerating = (sm?.status ?? 0) == 1;
  final String rawTitle = (sm?.title ?? '').trim();
  final String title = rawTitle.isNotEmpty ? rawTitle : m.title ?? ''.trim();

  final String overviewText = sm?.summary?.trim() ?? '';

  final List<String> speakerLabels = sm == null || (sm.participants ?? []).isEmpty
      ? <String>[]
      : (sm.participants ?? []).map((MPSpeakerStruct p) => p.name).toList();

  final List<MPMemoryTranscriptItemData> transcriptItems = sm == null
      ? const <MPMemoryTranscriptItemData>[]
      : (sm.transcript ?? [])
            .map((MPRecordConversationStruct t) {
              final int sec = t.time ?? 0;
              return MPMemoryTranscriptItemData(
                timestamp: MPDateUtils.formatTranscriptSecondsToMmSs(sec),
                timeSeconds: sec,
                speakerName: t.speaker.name,
                transcriptText: t.content,
                id: t.id,
              );
            })
            .toList(growable: false);

  final List<MPMemoryActionItemData> actionItems = sm == null
      ? const <MPMemoryActionItemData>[]
      : (sm.todos ?? [])
            .map(
              (MPTodoStruct t) => MPMemoryActionItemData(
                id: t.id,
                title: t.title,
                status: t.status == 1 ? MPMemoryActionItemStatus.pending : MPMemoryActionItemStatus.created,
                priority: t.priority,
                deadline: t.deadline,
              ),
            )
            .toList(growable: false);

  final List<MPMemoryFeedBlock> built = _buildFeedBlocksFromCards(feedCards, title);

  final int metaCreateAt = sm?.createAt ?? m.createAt;
  final DateTime dt = _detailServerTime(metaCreateAt);
  final String durationLabel = _formatDetailDuration(sm?.duration ?? m.duration);
  final String sourceLabel = (sm?.source ?? m.source ?? '').trim();
  final String metaLine = '${DateFormat('MMM d, y, h:mm a').format(dt)} • $durationLabel • $sourceLabel';

  final MPOnlyRecordMemoryStruct? only = m.onlyRecordContent;
  // audio/xxxx
  final String? recordFileForPlay = _firstNonEmptyDetailString(<String?>[sm?.recordUrl, only?.recordFile]);
  // https://xxxx.com/audio/xxxx
  final String? recordUriForPlay = _firstNonEmptyDetailString(<String?>[sm?.recordUri, only?.recordUri]);

  final MPMemoryDetailCardData data = MPMemoryDetailCardData(
    memoryId: m.id ?? '',
    title: title,
    metaLine: metaLine,
    audioTimeStart: '0:00',
    audioTimeEnd: durationLabel,
    recordFile: recordFileForPlay,
    recordUri: recordUriForPlay,
    speakerLabels: speakerLabels,
    initialSegment: MPMemoryDetailSegment.overview,
    overviewText: overviewText,
    transcriptItems: transcriptItems,
    actionItems: actionItems,
    feedBlocks: built,
  );

  final String feedCursor = _lastFeedCardId(feedCards) ?? '';
  final bool feedHasMore = feedCards.isNotEmpty;

  return (data: data, feedCursor: feedCursor, feedHasMore: feedHasMore, isSummaryGenerating: isSummaryGenerating);
}

/// Memory 会话详情：正文来自 [MPMemoryStruct.memoryFeed] 内 [MPMemoryFeedStruct.summaryMemory]，Feed 列表同 [MPMemoryFeedStruct.feeds]。
({MPMemoryDetailCardData data, String feedCursor, bool feedHasMore, bool isSummaryGenerating})
mpMemoryStructToDetailBundle(MPMemoryStruct m) {
  final MPMemoryFeedStruct? mf = m.memoryFeed;
  return _mpMemoryStructToDetailBundleFromSources(
    m,
    sm: mf?.summaryMemory,
    feedCards: mf?.feeds ?? const <MPFeedCardStruct>[],
  );
}

/// Memo 详情：正文来自根级 [MPMemoryStruct.summaryMemory]；下方活动区仍可使用 [MPMemoryStruct.memoryFeed] 的 [MPMemoryFeedStruct.feeds]（若有）。
({MPMemoryDetailCardData data, String feedCursor, bool feedHasMore, bool isSummaryGenerating})
mpMemoryStructToMemoDetailBundle(MPMemoryStruct m) {
  return _mpMemoryStructToDetailBundleFromSources(
    m,
    sm: m.summaryContent,
    feedCards: m.memoryFeed?.feeds ?? const <MPFeedCardStruct>[],
  );
}

/// 将详情接口返回的 [MPMemoryStruct] 转为页面 [MPMemoryDetailCardData]。
///
/// 会话/Feed 正文与转写等取自 [MPMemoryStruct.memoryFeed] 内嵌的 [MPMemoryFeedStruct.summaryMemory]，
/// 不使用根级 [MPMemoryStruct.summaryMemory]、[MPMemoryStruct.onlyRecordMemory]。
///
/// [MPMemoryFeedStruct.feeds] 顺序映射为 [MPMemoryDetailCardData.feedBlocks]（Insight / Todos / Memos / You asked 等可混合）。
MPMemoryDetailCardData mpMemoryStructToDetailCardData(MPMemoryStruct m) => mpMemoryStructToDetailBundle(m).data;

DateTime _detailServerTime(int createAt) {
  if (createAt > 10000000000) {
    return DateTime.fromMillisecondsSinceEpoch(createAt);
  }
  return DateTime.fromMillisecondsSinceEpoch(createAt * 1000);
}

String _formatDetailDuration(int? seconds) {
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

String _feedCardTimeLabel(int? createAt) {
  if (createAt == null) {
    return ' ';
  }
  final DateTime dt = createAt > 10000000000
      ? DateTime.fromMillisecondsSinceEpoch(createAt)
      : DateTime.fromMillisecondsSinceEpoch(createAt * 1000);
  return DateFormat('MMM d, h:mm a').format(dt);
}

String _feedCardHeaderTimeLabel(int? createAt) {
  if (createAt == null) {
    return 'Just now';
  }
  final DateTime dt = createAt > 10000000000
      ? DateTime.fromMillisecondsSinceEpoch(createAt)
      : DateTime.fromMillisecondsSinceEpoch(createAt * 1000);
  return DateFormat('MMM d, h:mm a').format(dt);
}

MPMemoryCreatedTodoLineData _mptodoToCreatedLine(MPTodoStruct t) {
  return MPMemoryCreatedTodoLineData(
    id: t.id,
    title: t.title,
    priority: MPTodoPriorityUtils.fromServerString(t.priority ?? 'normal'),
    deadlineLabel: t.deadline,
  );
}

/// 未在 [MPFeedCardType] 中声明的 [MPFeedCardStruct.type] 忽略，不生成 Feed 块。
const int _kFeedUnknownInsight = -1;

int _resolveFeedCardKind(MPFeedCardStruct f) {
  if (f.type != null) {
    final int v = f.type!;
    if (v == MPFeedCardType.insight ||
        v == MPFeedCardType.todosCreated ||
        v == MPFeedCardType.myMemo ||
        v == MPFeedCardType.resummary ||
        v == MPFeedCardType.youAsked ||
        v == MPFeedCardType.followUpList) {
      return v;
    }
    return _kFeedUnknownInsight;
  }
  return MPFeedCardType.insight;
}
