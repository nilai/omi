import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_detail_content_card.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_insight_card.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_todos_created_card.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_my_memos_card.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_you_asked_card.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_resummary_card.dart';
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
  OmiMemoryDetailCubit()
    : super(const OmiMemoryDetailState(phase: OmiMemoryDetailPhase.loading));

  Future<void> initData() => load();

  Future<void> load() async {
    emit(const OmiMemoryDetailState(phase: OmiMemoryDetailPhase.loading));
    try {
      final MPMemoryDetailCardData data = await _mockFetchDetail();
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

  /// 快捷输入新增 Todo：更新「TODOS CREATED」卡片列表。
  void addTodoFromQuickInput(String text) {
    final String title = text.trim();
    if (title.isEmpty) return;
    final OmiMemoryDetailState cur = state;
    if (cur.phase != OmiMemoryDetailPhase.loaded || cur.data == null) return;

    final MPMemoryDetailCardData d = cur.data!;
    final MPMemoryTodosCreatedCardData currentTodos =
        d.todosCreated ??
        const MPMemoryTodosCreatedCardData(
          headerTimeLabel: 'Just now',
          items: <MPMemoryCreatedTodoLineData>[],
        );

    final List<MPMemoryCreatedTodoLineData> nextItems =
        <MPMemoryCreatedTodoLineData>[
          ...currentTodos.items,
          MPMemoryCreatedTodoLineData(
            title: title,
            priority: MPMemoryTodoPriorityKind.medium,
            deadlineLabel: 'No deadline',
          ),
        ];

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
      insightItems: d.insightItems,
      todosCreated: MPMemoryTodosCreatedCardData(
        headerTimeLabel: 'Just now',
        items: nextItems,
      ),
      myMemos: d.myMemos,
      youAsked: d.youAsked,
      resummaryItems: d.resummaryItems,
    );

    emit(
      OmiMemoryDetailState(phase: OmiMemoryDetailPhase.loaded, data: nextData),
    );
  }

  /// 快捷输入新增 Memo：更新「MY MEMOS」卡片列表（追加到最底部）。
  void addMemoFromQuickInput(String text) {
    final String line = text.trim();
    if (line.isEmpty) return;
    final OmiMemoryDetailState cur = state;
    if (cur.phase != OmiMemoryDetailPhase.loaded || cur.data == null) return;

    final MPMemoryDetailCardData d = cur.data!;
    final MPMemoryMyMemosCardData currentMemos =
        d.myMemos ??
        const MPMemoryMyMemosCardData(
          headerTimeLabel: 'Just now',
          lines: <String>[],
        );

    final MPMemoryMyMemosCardData nextMemos = MPMemoryMyMemosCardData(
      headerTimeLabel: 'Just now',
      sourceLine: currentMemos.sourceLine,
      lines: <String>[...currentMemos.lines, line],
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
      insightItems: d.insightItems,
      todosCreated: d.todosCreated,
      myMemos: nextMemos,
      youAsked: d.youAsked,
      resummaryItems: d.resummaryItems,
    );

    emit(
      OmiMemoryDetailState(phase: OmiMemoryDetailPhase.loaded, data: nextData),
    );
  }

  /// 模拟详情请求：
  /// - 延迟 900ms
  /// - 返回头部信息 + overview/transcript/actions 三段数据
  Future<MPMemoryDetailCardData> _mockFetchDetail() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return MPMemoryDetailCardData(
      insightItems: const <MPMemoryInsightItemData>[
        MPMemoryInsightItemData(
          tone: MPInsightCardTone.business,
          timeLabel: '2 min later',
          bodyText:
              'Product discussions repeatedly circle around interaction behavior and hardware constraints, suggesting product definition is still evolving while engineering implementation is already underway.',
        ),
        MPMemoryInsightItemData(
          tone: MPInsightCardTone.execution,
          timeLabel: '10 min later',
          bodyText:
              'Several implementation blockers surfaced: recording start/stop logic still conflicts between press timing and user expectation, timestamp behavior during recording not fully aligned across teams, and sleep mode and LED states confuse usage.',
        ),
      ],
      title: 'Investor meeting - Series A funding discussion',
      metaLine: 'Yesterday, 4:30 PM • 45m52s • MemoPin',
      audioTimeStart: '0:00',
      audioTimeEnd: '45m52s',
      speakerLabels: const <String>['Investor', 'You'],
      initialSegment: MPMemoryDetailSegment.transcript,
      overviewText: 'Investors认可近期增长，但要求在基础设施稳定性、鉴权安全测试和灰度发布计划上给出更明确里程碑。',
      transcriptItems: const <MPMemoryTranscriptItemData>[
        MPMemoryTranscriptItemData(
          timestamp: '00:00',
          speakerName: 'Investor',
          transcriptText:
              'Thanks for presenting today. Your growth numbers look impressive.',
        ),
        MPMemoryTranscriptItemData(
          timestamp: '02:15',
          speakerName: 'You',
          transcriptText:
              'We can walk through the Q3 pipeline and unit economics next.',
        ),
        MPMemoryTranscriptItemData(
          timestamp: '05:40',
          speakerName: 'Investor',
          transcriptText:
              'Please detail risk controls for phased rollout and auth migration.',
        ),
      ],
      actionItems: const <MPMemoryActionItemData>[
        MPMemoryActionItemData(
          title: 'Review migration milestones with infrastructure team',
          status: MPMemoryActionItemStatus.created,
        ),
        MPMemoryActionItemData(
          title: 'Schedule authentication service testing session',
          status: MPMemoryActionItemStatus.pending,
        ),
        MPMemoryActionItemData(
          title: 'Document rollout risks and mitigation strategies',
          status: MPMemoryActionItemStatus.pending,
        ),
      ],
      todosCreated: MPMemoryTodosCreatedCardData(
        headerTimeLabel: 'Just now',
        items: const <MPMemoryCreatedTodoLineData>[
          MPMemoryCreatedTodoLineData(
            title: 'Review migration milestones with infrastructure team',
            priority: MPMemoryTodoPriorityKind.high,
            deadlineLabel: 'Tomorrow',
          ),
          MPMemoryCreatedTodoLineData(
            title: 'Update API documentation for v2 endpoints',
            priority: MPMemoryTodoPriorityKind.high,
            deadlineLabel: 'This week',
          ),
          MPMemoryCreatedTodoLineData(
            title: 'eee',
            priority: MPMemoryTodoPriorityKind.medium,
            deadlineLabel: 'No deadline',
          ),
          MPMemoryCreatedTodoLineData(
            title: 'Review migration milestones with infrastructure team',
            priority: MPMemoryTodoPriorityKind.normal,
            deadlineLabel: 'Today',
          ),
          MPMemoryCreatedTodoLineData(
            title: 'Schedule authentication service testing session',
            priority: MPMemoryTodoPriorityKind.normal,
            deadlineLabel: 'No deadline',
          ),
        ],
      ),
      myMemos: MPMemoryMyMemosCardData(
        headerTimeLabel: 'Just now',
        lines: const <String>[
          'Infra team seems overloaded. Maybe we should loop in Sarah from the platform team to help?',
          'www',
        ],
      ),
      youAsked: const MPMemoryYouAskedCardData(
        headerTimeLabel: 'Just now',
        userMessage: 'eeee',
        aiReply:
            'I can help you understand your recent work, identify patterns, clarify decisions, or surface potential risks. What would you like to explore?',
      ),
      resummaryItems: const <MPMemoryResummaryCardData>[
        MPMemoryResummaryCardData(
          headerTimeLabel: 'Just now',
          badgeLabel: 'Autopilot mode',
          mainTitle: 'Strategic Investment Analysis',
          sectionTitle: 'Executive Summary',
          bodyText:
              'From an investment standpoint, this API migration discussion reveals both opportunities and red flags that warrant careful attention. The technical debt being addressed represents necessary infrastructure modernization, but execution risks appear higher than currently acknowledged.',
          expandedSectionTitle: 'Bottom Line',
          expandedSectionBody:
              'This is necessary technical work, but execution risk appears higher than team currently acknowledges. Consider whether additional infrastructure investment could derisk timeline and improve long-term operational leverage.',
        ),
        MPMemoryResummaryCardData(
          headerTimeLabel: '5 min ago',
          badgeLabel: 'Meeting secretary',
          mainTitle: 'Stakeholder alignment',
          sectionTitle: 'Key takeaways',
          bodyText:
              'Participants aligned on phased rollout timelines and agreed to revisit auth migration checkpoints weekly. Open items include load testing ownership and customer communication templates.',
        ),
      ],
    );
  }
}
