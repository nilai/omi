import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:omi/common/mp_todo_priority_utils.dart';
import 'package:omi/http/api/mp_memory.dart';
import 'package:omi/http/schema/mp_data_model.dart';
import 'package:omi/http/schema/mp_memory.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_detail_content_card.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_feed_block.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_insight_card.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_my_memos_card.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_resummary_card.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_todos_created_models.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_you_asked_card.dart';
import 'package:omi/tab/memory/detail/memory/card/omi_memory_action_content.dart';
import 'package:omi/tab/memory/detail/memory/card/omi_memory_transcript_item.dart';

enum OmiMemoryDetailPhase { loading, loaded, error }

class OmiMemoryDetailState {
  const OmiMemoryDetailState({
    required this.phase,
    this.data,
    this.errorMessage,
  });

  final OmiMemoryDetailPhase phase;
  final MPMemoryDetailCardData? data;
  final String? errorMessage;
}

class OmiMemoryDetailCubit extends Cubit<OmiMemoryDetailState> {
  OmiMemoryDetailCubit({required this.memoryId})
    : super(const OmiMemoryDetailState(phase: OmiMemoryDetailPhase.loading));

  /// 列表页传入，对应接口 `memory_id`。
  final String memoryId;

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
      final MPMemoryDetailCardData data =
          mpMemoryStructToDetailCardData(resp.memoryDetail);
      emit(
        OmiMemoryDetailState(phase: OmiMemoryDetailPhase.loaded, data: data),
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
                    deadlineLabel: 'No deadline',
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
      waveformHeights: d.waveformHeights,
      speakerLabels: d.speakerLabels,
      overviewText: d.overviewText,
      transcriptItems: d.transcriptItems,
      actionItems: d.actionItems,
      initialSegment: d.initialSegment,
      feedBlocks: nextBlocks,
    );

    emit(
      OmiMemoryDetailState(phase: OmiMemoryDetailPhase.loaded, data: nextData),
    );
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
                lines: <String>[line],
              ),
            ),
          );

    final MPMemoryDetailCardData nextData = MPMemoryDetailCardData(
      title: d.title,
      metaLine: d.metaLine,
      audioTimeStart: d.audioTimeStart,
      audioTimeEnd: d.audioTimeEnd,
      waveformHeights: d.waveformHeights,
      speakerLabels: d.speakerLabels,
      overviewText: d.overviewText,
      transcriptItems: d.transcriptItems,
      actionItems: d.actionItems,
      initialSegment: d.initialSegment,
      feedBlocks: nextBlocks,
    );

    emit(
      OmiMemoryDetailState(phase: OmiMemoryDetailPhase.loaded, data: nextData),
    );
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
      waveformHeights: d.waveformHeights,
      speakerLabels: d.speakerLabels,
      overviewText: d.overviewText,
      transcriptItems: d.transcriptItems,
      actionItems: d.actionItems,
      initialSegment: d.initialSegment,
      feedBlocks: nextBlocks,
    );

    emit(
      OmiMemoryDetailState(phase: OmiMemoryDetailPhase.loaded, data: nextData),
    );
    return true;
  }
}

/// 将详情接口返回的 [MPMemoryStruct] 转为页面 [MPMemoryDetailCardData]。
///
/// 会话/Feed 正文与转写等取自 [MPMemoryStruct.memoryFeed] 内嵌的 [MPMemoryFeedStruct.summaryMemory]，
/// 不使用根级 [MPMemoryStruct.summaryMemory]、[MPMemoryStruct.onlyRecordMemory]。
///
/// [MPMemoryFeedStruct.feeds] 顺序映射为 [MPMemoryDetailCardData.feedBlocks]（Insight / Todos / Memos / You asked 等可混合）。
MPMemoryDetailCardData mpMemoryStructToDetailCardData(MPMemoryStruct m) {
  final MPMemoryFeedStruct? mf = m.memoryFeed;
  final MPSummaryMemoryStruct? sm = mf?.summaryMemory;
  final String title = m.title.trim().isNotEmpty ? m.title : 'Memory';

  final String overviewText = sm?.summary.trim() ?? '';

  final List<String> speakerLabels = sm == null || sm.participants.isEmpty
      ? <String>['Speaker']
      : sm.participants.map((MPSpeakerStruct p) => p.name).toList();

  final List<MPMemoryTranscriptItemData> transcriptItems =
      sm == null
          ? const <MPMemoryTranscriptItemData>[]
          : sm.transcript
              .map(
                (MPRecordConversationStruct t) => MPMemoryTranscriptItemData(
                  timestamp: t.time,
                  speakerName: t.speaker.name,
                  transcriptText: t.content,
                  id: t.id,
                ),
              )
              .toList(growable: false);

  final List<MPMemoryActionItemData> actionItems =
      sm == null
          ? const <MPMemoryActionItemData>[]
          : sm.todos
              .map(
                (MPTodoStruct t) => MPMemoryActionItemData(
                  id: t.id,
                  title: t.title,
                  status: t.status == 1
                      ? MPMemoryActionItemStatus.pending
                      : MPMemoryActionItemStatus.created,
                ),
              )
              .toList(growable: false);

  final List<MPMemoryFeedBlock> feedBlocks = <MPMemoryFeedBlock>[];

  if (mf != null) {
    int unknownInsightIndex = 0;
    for (final MPFeedCardStruct f in mf.feeds) {
      final int kind = _resolveFeedCardKind(f);
      if (kind == MPFeedCardType.myMemo) {
        final String line = (f.content ?? '').trim();
        if (line.isNotEmpty) {
          feedBlocks.add(
            MPMemoryFeedMyMemoBlock(
              MPMemoryMyMemosCardData(
                headerTimeLabel: _feedCardHeaderTimeLabel(f.createAt),
                lines: <String>[line],
              ),
            ),
          );
        }
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

      final String body = (f.content ?? '').trim();
      if (body.isEmpty) {
        continue;
      }

      final MPInsightCardTone tone;
      if (kind == MPFeedCardType.executionInsight) {
        tone = MPInsightCardTone.execution;
      } else if (kind == MPFeedCardType.businessInsight) {
        tone = MPInsightCardTone.business;
      } else {
        tone = unknownInsightIndex.isEven
            ? MPInsightCardTone.business
            : MPInsightCardTone.execution;
        unknownInsightIndex++;
      }

      feedBlocks.add(
        MPMemoryFeedInsightBlock(
          MPMemoryInsightItemData(
            tone: tone,
            timeLabel: _feedCardTimeLabel(f.createAt),
            bodyText: body,
            categoryTitle: f.title,
          ),
        ),
      );
    }
  }

  final DateTime dt = _detailServerTime(m.createAt);
  final String durationLabel = _formatDetailDuration(m.duration);
  final String sourceLabel =
      m.source?.trim().isNotEmpty == true ? m.source!.trim() : 'MemoPin';
  final String metaLine =
      '${DateFormat('MMM d, y, h:mm a').format(dt)} • $durationLabel • $sourceLabel';

  return MPMemoryDetailCardData(
    title: title,
    metaLine: metaLine,
    audioTimeStart: '0:00',
    audioTimeEnd: durationLabel,
    speakerLabels: speakerLabels,
    initialSegment: MPMemoryDetailSegment.transcript,
    overviewText: overviewText.isNotEmpty ? overviewText : ' ',
    transcriptItems: transcriptItems,
    actionItems: actionItems,
    feedBlocks: feedBlocks,
  );
}

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
    priority: MPTodoPriorityUtils.fromServerString(t.priority),
    deadlineLabel: t.deadline,
  );
}

/// 非 1–4 的 [MPFeedCardStruct.type] 视为 insight，按序交替 Business / Execution。
const int _kFeedUnknownInsight = -1;

int _resolveFeedCardKind(MPFeedCardStruct f) {
  if (f.type != null) {
    final int v = f.type!;
    if (v == MPFeedCardType.businessInsight ||
        v == MPFeedCardType.executionInsight ||
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
