import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:omi/common/mp_date_utils.dart';
import 'package:omi/common/mp_todo_priority_utils.dart';
import 'package:omi/audio/mp_local_records_util.dart';
import 'package:omi/http/api/mp_memory.dart';
import 'package:omi/http/schema/mp_data_model.dart';
import 'package:omi/http/schema/mp_memory.dart';
import 'package:path_provider/path_provider.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_detail_content_card.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_feed_block.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_insight_card.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_my_memos_card.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_resummary_card.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_todos_created_models.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_you_asked_card.dart';
import 'package:omi/tab/memory/detail/memory/card/omi_memory_action_content.dart';
import 'package:omi/tab/memory/detail/memory/card/omi_memory_transcript_item.dart';
import 'package:omi/utils/mp_toast_utils.dart';

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

  OmiMemoryDetailState copyWith({
    OmiMemoryDetailPhase? phase,
    MPMemoryDetailCardData? data,
    String? errorMessage,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? feedHasMore,
  }) {
    return OmiMemoryDetailState(
      phase: phase ?? this.phase,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      feedHasMore: feedHasMore ?? this.feedHasMore,
    );
  }
}

const int _kMemoryFeedPageSize = 20;

class OmiMemoryDetailCubit extends Cubit<OmiMemoryDetailState> {
  OmiMemoryDetailCubit({
    required this.memoryId,
    this.detailSource = OmiMemoryDetailSource.memoryFeedSummary,
  }) : super(const OmiMemoryDetailState(phase: OmiMemoryDetailPhase.loading)) {
    _playerStateSub = _audioPlayer.playerStateStream.listen((PlayerState ps) {
      if (ps.processingState == ProcessingState.completed) {
        _isAudioPlaying = false;
      }
    });
  }

  /// 列表页传入，对应接口 `memory_id`。
  final String memoryId;

  /// 决定 [getMemoryDetail] 结果如何映射为 [MPMemoryDetailCardData]。
  final OmiMemoryDetailSource detailSource;

  int _unknownInsightIndex = 0;
  String _feedCursor = '';
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;
  String? _playingLocalPath;
  bool _isAudioPlaying = false;

  Future<void> initData() => load();

  Future<void> load() async {
    emit(const OmiMemoryDetailState(phase: OmiMemoryDetailPhase.loading));
    try {
      final MPGetMemoryV2DetailResponse? resp = await getMemoryDetail(
        MPGetMemoryV2DetailRequest(memoryId: memoryId),
      );
      if (resp == null) {
        throw StateError('getMemoryDetail failed');
      }
      final ({
        MPMemoryDetailCardData data,
        int nextUnknownInsightIndex,
        String feedCursor,
        bool feedHasMore,
      }) bundle = _mapDetailResponse(resp.memoryDetail);
      _unknownInsightIndex = bundle.nextUnknownInsightIndex;
      _feedCursor = bundle.feedCursor;
      emit(
        OmiMemoryDetailState(
          phase: OmiMemoryDetailPhase.loaded,
          data: bundle.data,
          feedHasMore: bundle.feedHasMore,
        ),
      );
    } catch (e) {
      emit(
        OmiMemoryDetailState(
          phase: OmiMemoryDetailPhase.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> retry() => load();

  Future<void> onPlayTap() async {
    final OmiMemoryDetailState cur = state;
    if (cur.phase != OmiMemoryDetailPhase.loaded || cur.data == null) {
      return;
    }
    if (_isAudioPlaying) {
      await _audioPlayer.pause();
      _isAudioPlaying = false;
      return;
    }
    final String? localPath = await _ensurePlayableLocalPath(cur.data!);
    if (localPath == null || localPath.isEmpty) {
      MPToastUtils.showMessage('音频下载失败，请稍后重试');
      return;
    }
    try {
      if (_playingLocalPath != localPath) {
        await _audioPlayer.setFilePath(localPath);
        _playingLocalPath = localPath;
      }
      await _audioPlayer.play();
      _isAudioPlaying = true;
    } catch (_) {
      MPToastUtils.showMessage('音频播放失败');
    }
  }

  Future<String?> _ensurePlayableLocalPath(MPMemoryDetailCardData data) async {
    final String recordFile = (data.recordFile ?? '').trim();
    if (recordFile.isEmpty) {
      return null;
    }
    final String? localPath = await MPLocalRecordsUtil.instance.getLocalRecordPath(
      recordFile,
    );
    if (localPath != null && localPath.isNotEmpty) {
      return localPath;
    }
    final String? downloadUrl = _resolveRecordDownloadUrl(
      recordFile: recordFile,
      recordUri: (data.recordUri ?? '').trim(),
    );
    if (downloadUrl == null || downloadUrl.isEmpty) {
      return null;
    }
    return _downloadRecordToLocal(
      downloadUrl: downloadUrl,
      recordFile: recordFile,
      durationLabel: data.audioTimeEnd,
    );
  }

  String? _resolveRecordDownloadUrl({
    required String recordFile,
    required String recordUri,
  }) {
    final Uri? recordFileUri = Uri.tryParse(recordFile);
    if (recordFileUri != null &&
        recordFileUri.hasScheme &&
        recordFileUri.host.isNotEmpty) {
      return recordFile;
    }
    final Uri? recordUriParsed = Uri.tryParse(recordUri);
    if (recordUriParsed != null &&
        recordUriParsed.hasScheme &&
        recordUriParsed.host.isNotEmpty) {
      return recordFileUri == null
          ? recordUri
          : recordUriParsed.resolveUri(recordFileUri).toString();
    }
    return null;
  }

  Future<String?> _downloadRecordToLocal({
    required String downloadUrl,
    required String recordFile,
    required String durationLabel,
  }) async {
    try {
      final Uri uri = Uri.parse(downloadUrl);
      final http.Response response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final Directory docs = await getApplicationDocumentsDirectory();
      final Directory audioDir = Directory('${docs.path}/mp_audio_records');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      final String sourceForId =
          recordFile.isNotEmpty ? recordFile : downloadUrl;
      String fileId = MPLocalRecordsUtil.getFileIdFromUrl(sourceForId).trim();
      if (fileId.isEmpty) {
        fileId = DateTime.now().millisecondsSinceEpoch.toString();
      }
      String ext = '.m4a';
      final String path = uri.path;
      final int dot = path.lastIndexOf('.');
      if (dot > 0 && dot < path.length - 1) {
        ext = path.substring(dot);
      }
      final String filePath =
          '${audioDir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileId$ext';
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes, flush: true);

      await MPLocalRecordsUtil.instance.loadLocalRecords();
      await MPLocalRecordsUtil.instance.addLocalRecord(
        filePath,
        duration: _parseDurationSeconds(durationLabel),
        source: 'mp',
        createAt: DateTime.now().millisecondsSinceEpoch,
        fileId: fileId,
      );
      return filePath;
    } catch (_) {
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

  ({
    MPMemoryDetailCardData data,
    int nextUnknownInsightIndex,
    String feedCursor,
    bool feedHasMore,
  }) _mapDetailResponse(MPMemoryStruct m) {
    return switch (detailSource) {
      OmiMemoryDetailSource.memoryFeedSummary => mpMemoryStructToDetailBundle(m),
      OmiMemoryDetailSource.rootSummaryMemory => mpMemoryStructToMemoDetailBundle(m),
    };
  }

  /// 下拉刷新：重新拉详情，不打断全屏 loading 态以外的已展示内容。
  Future<void> refresh() async {
    final OmiMemoryDetailState cur = state;
    if (cur.phase == OmiMemoryDetailPhase.loading) {
      return;
    }
    if (cur.phase == OmiMemoryDetailPhase.loaded && cur.data != null) {
      emit(cur.copyWith(isRefreshing: true));
    }
    try {
      final MPGetMemoryV2DetailResponse? resp = await getMemoryDetail(
        MPGetMemoryV2DetailRequest(memoryId: memoryId),
      );
      if (resp == null) {
        throw StateError('getMemoryDetail failed');
      }
      final ({
        MPMemoryDetailCardData data,
        int nextUnknownInsightIndex,
        String feedCursor,
        bool feedHasMore,
      }) bundle = _mapDetailResponse(resp.memoryDetail);
      _unknownInsightIndex = bundle.nextUnknownInsightIndex;
      _feedCursor = bundle.feedCursor;
      emit(
        OmiMemoryDetailState(
          phase: OmiMemoryDetailPhase.loaded,
          data: bundle.data,
          feedHasMore: bundle.feedHasMore,
          isRefreshing: false,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (state.phase == OmiMemoryDetailPhase.loaded && state.data != null) {
        emit(state.copyWith(isRefreshing: false));
        MPToastUtils.showMessage('刷新失败，请稍后重试');
      } else {
        emit(
          OmiMemoryDetailState(
            phase: OmiMemoryDetailPhase.error,
            errorMessage: e.toString(),
          ),
        );
      }
    }
  }

  /// 上拉加载更多 Feed 块，追加到 [MPMemoryDetailCardData.feedBlocks]。
  Future<void> loadMoreFeeds() async {
    final OmiMemoryDetailState cur = state;
    if (cur.phase != OmiMemoryDetailPhase.loaded || cur.data == null) {
      return;
    }
    if (!cur.feedHasMore || cur.isLoadingMore) {
      return;
    }

    emit(cur.copyWith(isLoadingMore: true));
    try {
      final MPGetMemoryFeedResponse? resp = await getMemoryFeed(
        MPGetMemoryFeedRequest(
          memoryId: memoryId,
          pageSize: _kMemoryFeedPageSize,
          cursor: _feedCursor,
        ),
      );
      if (resp == null) {
        emit(state.copyWith(isLoadingMore: false, feedHasMore: false));
        MPToastUtils.showMessage('加载更多失败');
        return;
      }
      final List<MPFeedCardStruct> cards = resp.feeds ?? const <MPFeedCardStruct>[];
      if (cards.isEmpty) {
        emit(
          state.copyWith(
            isLoadingMore: false,
            feedHasMore: resp.hasMore ?? false,
          ),
        );
        return;
      }
      final _FeedBlocksBuildResult built = _buildFeedBlocksFromCards(
        cards,
        _unknownInsightIndex,
      );
      _unknownInsightIndex = built.nextUnknownInsightIndex;
      final String? lastId = _lastFeedCardId(cards);
      if (lastId != null && lastId.isNotEmpty) {
        _feedCursor = lastId;
      }

      final MPMemoryDetailCardData d = state.data!;
      final List<MPMemoryFeedBlock> merged =
          List<MPMemoryFeedBlock>.from(d.feedBlocks)..addAll(built.blocks);
      final MPMemoryDetailCardData nextData = MPMemoryDetailCardData(
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
        feedBlocks: merged,
      );
      emit(
        state.copyWith(
          data: nextData,
          isLoadingMore: false,
          feedHasMore: resp.hasMore ?? false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
      MPToastUtils.showMessage('加载更多失败');
    }
  }

  /// 快捷输入新增 Todo：在 [MPMemoryDetailCardData.feedBlocks] 末尾追加一条 TODOS CREATED。
  void addTodoFromQuickInput(String text) {
    final String title = text.trim();
    if (title.isEmpty) return;
    final OmiMemoryDetailState cur = state;
    if (cur.phase != OmiMemoryDetailPhase.loaded || cur.data == null) return;

    final MPMemoryDetailCardData d = cur.data!;
    final List<MPMemoryFeedBlock> nextBlocks =
        List<MPMemoryFeedBlock>.from(d.feedBlocks)
          ..add(
            MPMemoryFeedTodosCreatedBlock(
              MPMemoryTodosCreatedCardData(
                headerTimeLabel: 'Just now',
                items: <MPMemoryCreatedTodoLineData>[
                  MPMemoryCreatedTodoLineData(
                    id: '',
                    title: title,
                    priority: MPMemoryTodoPriorityKind.medium,
                    deadlineLabel: null,
                  ),
                ],
              ),
            ),
          );

    final MPMemoryDetailCardData nextData = MPMemoryDetailCardData(
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

  /// 快捷输入新增 Memo：在 [MPMemoryDetailCardData.feedBlocks] 末尾追加一条 MY MEMOS。
  void addMemoFromQuickInput(String text) {
    final String line = text.trim();
    if (line.isEmpty) return;
    final OmiMemoryDetailState cur = state;
    if (cur.phase != OmiMemoryDetailPhase.loaded || cur.data == null) return;

    final MPMemoryDetailCardData d = cur.data!;
    final List<MPMemoryFeedBlock> nextBlocks =
        List<MPMemoryFeedBlock>.from(d.feedBlocks)
          ..add(
            MPMemoryFeedMyMemoBlock(
              MPMemoryMyMemosCardData(
                headerTimeLabel: 'Just now',
                lines: <MPMemoryMyMemoLine>[
                  MPMemoryMyMemoLine(
                    text: line,
                    type: MPMemoType.manualMemo,
                  ),
                ],
              ),
            ),
          );

    final MPMemoryDetailCardData nextData = MPMemoryDetailCardData(
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
    // TODO: 替换为真实删除接口
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return true;
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

    final List<MPMemoryCreatedTodoLineData> nextItems =
        List<MPMemoryCreatedTodoLineData>.from(todos.items)..removeAt(itemIndex);

    final List<MPMemoryFeedBlock> nextBlocks =
        List<MPMemoryFeedBlock>.from(d.feedBlocks);
    if (nextItems.isEmpty) {
      nextBlocks.removeAt(feedBlockIndex);
    } else {
      nextBlocks[feedBlockIndex] = MPMemoryFeedTodosCreatedBlock(
        MPMemoryTodosCreatedCardData(
          headerTimeLabel: todos.headerTimeLabel,
          items: nextItems,
        ),
      );
    }

    final MPMemoryDetailCardData nextData = MPMemoryDetailCardData(
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
    _playerStateSub?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}

class _FeedBlocksBuildResult {
  const _FeedBlocksBuildResult({
    required this.blocks,
    required this.nextUnknownInsightIndex,
  });

  final List<MPMemoryFeedBlock> blocks;
  final int nextUnknownInsightIndex;
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

_FeedBlocksBuildResult _buildFeedBlocksFromCards(
  List<MPFeedCardStruct> feeds,
  int unknownInsightStart,
) {
  int unknownInsightIndex = unknownInsightStart;
  final List<MPMemoryFeedBlock> feedBlocks = <MPMemoryFeedBlock>[];
  for (final MPFeedCardStruct f in feeds) {
    final int kind = _resolveFeedCardKind(f);
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
            userMessage: f.title ?? ' ',
            aiReply: ' ',
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

    final MPInsightCardTone tone;
    if (kind == MPFeedCardType.executionInsight) {
      tone = MPInsightCardTone.execution;
    } else if (kind == MPFeedCardType.businessInsight) {
      tone = MPInsightCardTone.business;
    } else if (kind == MPFeedCardType.creativeInsight) {
      tone = MPInsightCardTone.creative;
    } else if (kind == MPFeedCardType.wellnessInsight) {
      tone = MPInsightCardTone.wellness;
    } else {
      tone = _kInsightToneCycle[unknownInsightIndex % _kInsightToneCycle.length];
      unknownInsightIndex++;
    }

    final String insightTitle = (f.title ?? '').trim();
    final String insightBody = (f.content ?? '').trim();

    feedBlocks.add(
      MPMemoryFeedInsightBlock(
        MPMemoryInsightItemData(
          tone: tone,
          timeLabel: _feedCardTimeLabel(f.createAt),
          bodyText: insightBody,
          categoryTitle: insightTitle,
        ),
      ),
    );
  }
  return _FeedBlocksBuildResult(
    blocks: feedBlocks,
    nextUnknownInsightIndex: unknownInsightIndex,
  );
}

/// 详情映射结果：主卡片数据 + 分页加载 Feed 所需的游标与 unknown insight 计数。
({
  MPMemoryDetailCardData data,
  int nextUnknownInsightIndex,
  String feedCursor,
  bool feedHasMore,
}) _mpMemoryStructToDetailBundleFromSources(
  MPMemoryStruct m, {
  required MPSummaryMemoryStruct? sm,
  required List<MPFeedCardStruct> feedCards,
}) {
  final String rawTitle = (sm?.title ?? '').trim();
  final String title = rawTitle.isNotEmpty ? rawTitle : m.title.trim();

  final String overviewText = sm?.summary?.trim() ?? '';

  final List<String> speakerLabels = sm == null || (sm.participants ?? []).isEmpty
      ? <String>[]
      : (sm.participants ?? []).map((MPSpeakerStruct p) => p.name).toList();

  final List<MPMemoryTranscriptItemData> transcriptItems =
      sm == null
          ? const <MPMemoryTranscriptItemData>[]
          : (sm.transcript ?? [])
              .map(
                (MPRecordConversationStruct t) {
                  final int sec = t.time ?? 0;
                  return MPMemoryTranscriptItemData(
                    timestamp: MPDateUtils.formatTranscriptSecondsToMmSs(sec),
                    timeSeconds: sec,
                    speakerName: t.speaker.name,
                    transcriptText: t.content,
                    id: t.id,
                  );
                },
              )
              .toList(growable: false);

  final List<MPMemoryActionItemData> actionItems =
      sm == null
          ? const <MPMemoryActionItemData>[]
          : (sm.todos ?? [])
              .map(
                (MPTodoStruct t) => MPMemoryActionItemData(
                  id: t.id,
                  title: t.title,
                  status: t.status == 1
                      ? MPMemoryActionItemStatus.pending
                      : MPMemoryActionItemStatus.created,
                  priority: t.priority,
                  deadline: t.deadline,
                ),
              )
              .toList(growable: false);

  final _FeedBlocksBuildResult built = _buildFeedBlocksFromCards(feedCards, 0);

  final int metaCreateAt = sm?.createAt ?? m.createAt;
  final DateTime dt = _detailServerTime(metaCreateAt);
  final String durationLabel = _formatDetailDuration(sm?.duration ?? m.duration);
  final String sourceLabel = (sm?.source ?? m.source ?? '').trim();
  final String metaLine =
      '${DateFormat('MMM d, y, h:mm a').format(dt)} • $durationLabel • $sourceLabel';

  final MPMemoryDetailCardData data = MPMemoryDetailCardData(
    title: title,
    metaLine: metaLine,
    audioTimeStart: '0:00',
    audioTimeEnd: durationLabel,
    recordFile: sm?.recordUrl,
    recordUri: sm?.recordUri,
    speakerLabels: speakerLabels,
    initialSegment: MPMemoryDetailSegment.transcript,
    overviewText: overviewText,
    transcriptItems: transcriptItems,
    actionItems: actionItems,
    feedBlocks: built.blocks,
  );

  final String feedCursor = _lastFeedCardId(feedCards) ?? '';
  final bool feedHasMore = feedCards.isNotEmpty;

  return (
    data: data,
    nextUnknownInsightIndex: built.nextUnknownInsightIndex,
    feedCursor: feedCursor,
    feedHasMore: feedHasMore,
  );
}

/// Memory 会话详情：正文来自 [MPMemoryStruct.memoryFeed] 内 [MPMemoryFeedStruct.summaryMemory]，Feed 列表同 [MPMemoryFeedStruct.feeds]。
({
  MPMemoryDetailCardData data,
  int nextUnknownInsightIndex,
  String feedCursor,
  bool feedHasMore,
}) mpMemoryStructToDetailBundle(MPMemoryStruct m) {
  final MPMemoryFeedStruct? mf = m.memoryFeed;
  return _mpMemoryStructToDetailBundleFromSources(
    m,
    sm: mf?.summaryMemory,
    feedCards: mf?.feeds ?? const <MPFeedCardStruct>[],
  );
}

/// Memo 详情：正文来自根级 [MPMemoryStruct.summaryMemory]；下方活动区仍可使用 [MPMemoryStruct.memoryFeed] 的 [MPMemoryFeedStruct.feeds]（若有）。
({
  MPMemoryDetailCardData data,
  int nextUnknownInsightIndex,
  String feedCursor,
  bool feedHasMore,
}) mpMemoryStructToMemoDetailBundle(MPMemoryStruct m) {
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
MPMemoryDetailCardData mpMemoryStructToDetailCardData(MPMemoryStruct m) =>
    mpMemoryStructToDetailBundle(m).data;

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

/// 非 1–4 的 [MPFeedCardStruct.type] 视为 insight；未知 type 在多种 [MPInsightCardTone] 间轮换。
const int _kFeedUnknownInsight = -1;

const List<MPInsightCardTone> _kInsightToneCycle = <MPInsightCardTone>[
  MPInsightCardTone.business,
  MPInsightCardTone.execution,
  MPInsightCardTone.creative,
  MPInsightCardTone.wellness,
  MPInsightCardTone.strategic,
  MPInsightCardTone.growth,
];

int _resolveFeedCardKind(MPFeedCardStruct f) {
  if (f.type != null) {
    final int v = f.type!;
    if (v == MPFeedCardType.businessInsight ||
        v == MPFeedCardType.executionInsight ||
        v == MPFeedCardType.creativeInsight ||
        v == MPFeedCardType.wellnessInsight ||
        v == MPFeedCardType.todosCreated ||
        v == MPFeedCardType.myMemo ||
        v == MPFeedCardType.youAsked ||
        v == MPFeedCardType.resummary) {
      return v;
    }
    return _kFeedUnknownInsight;
  }
  return MPFeedCardType.businessInsight;
}
