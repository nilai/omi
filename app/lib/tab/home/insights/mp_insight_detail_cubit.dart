import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'mp_insights_list_cubit.dart';

/// Insights 详情页状态
enum MPInsightDetailPhase { loading, loaded, error }

/// 详情页状态
class MPInsightDetailState {
  const MPInsightDetailState({
    required this.phase,
    this.data,
    this.errorMessage,
  });

  final MPInsightDetailPhase phase;
  final MPInsightDetailData? data;
  final String? errorMessage;

  factory MPInsightDetailState.loading() => const MPInsightDetailState(
        phase: MPInsightDetailPhase.loading,
      );

  factory MPInsightDetailState.loaded(MPInsightDetailData data) =>
      MPInsightDetailState(
        phase: MPInsightDetailPhase.loaded,
        data: data,
      );

  factory MPInsightDetailState.error(String message) => MPInsightDetailState(
        phase: MPInsightDetailPhase.error,
        errorMessage: message,
      );
}

/// 详情页数据（不同类型会在 `paragraphs` / `tips` 等字段中体现差异）
class MPInsightDetailData {
  const MPInsightDetailData({
    required this.item,
    required this.paragraphs,
    required this.tips,
    this.monthly,
  });

  final MPInsightListItem item;
  final List<String> paragraphs;
  final List<String> tips;

  /// Monthly 详情页专用结构化数据（其它类型为 null）
  final MPMonthlyInsightDetailData? monthly;
}

/// Monthly 详情页卡片中的条目：注意力分布
class MPMonthlyBarItem {
  const MPMonthlyBarItem({
    required this.label,
    required this.value,
  });

  /// 左侧标签，如 `Product`
  final String label;

  /// 数值 0-100，用于渲染条形长度
  final int value;
}

/// Monthly 详情页卡片中的条目：关键人物
class MPMonthlyKeyPersonItem {
  const MPMonthlyKeyPersonItem({
    required this.name,
    required this.count,
  });

  final String name;
  final int count;
}

/// Monthly 详情页卡片中的条目：决策项
class MPMonthlyDecisionItem {
  const MPMonthlyDecisionItem({
    required this.rank,
    required this.text,
  });

  final int rank;
  final String text;
}

/// Monthly 详情页卡片中的条目：下月关注建议
class MPMonthlySuggestedFocusItem {
  const MPMonthlySuggestedFocusItem({
    required this.rank,
    required this.text,
  });

  final int rank;
  final String text;
}

/// Monthly 详情页结构化数据
class MPMonthlyInsightDetailData {
  const MPMonthlyInsightDetailData({
    required this.monthSubtitle,
    required this.monthOverviewSummary,
    required this.attentionDistribution,
    required this.keyPeopleThisMonth,
    required this.topicsSurfacing,
    required this.longRunningOpenThreads,
    required this.monthToMonthTrend,
    required this.decisionsThatCannotSlipAgain,
    required this.suggestedFocusNextMonth,
    required this.askAiButtonText,
  });

  /// 顶部 bar 第二行，如 `Jan 2026`
  final String monthSubtitle;

  /// Month Overview 文案
  final String monthOverviewSummary;

  /// Attention Distribution
  final List<MPMonthlyBarItem> attentionDistribution;

  /// Key People This Month
  final List<MPMonthlyKeyPersonItem> keyPeopleThisMonth;

  /// Topics Surfacing
  final List<String> topicsSurfacing;

  /// Long-running Open Threads
  final List<String> longRunningOpenThreads;

  /// Month-to-Month Trend
  final List<String> monthToMonthTrend;

  /// Decisions That Cannot Slip Again
  final List<MPMonthlyDecisionItem> decisionsThatCannotSlipAgain;

  /// Suggested Focus Next Month
  final List<MPMonthlySuggestedFocusItem> suggestedFocusNextMonth;

  /// 底部按钮文案
  final String askAiButtonText;
}

/// 详情页 Cubit：根据列表项类型模拟后台拉取详情
class MPInsightDetailCubit extends Cubit<MPInsightDetailState> {
  MPInsightDetailCubit({
    required MPInsightListItem item,
  })  : _item = item,
        super(MPInsightDetailState.loading());

  final MPInsightListItem _item;

  /// 页面初始化：拉取详情
  Future<void> initData() async {
    emit(MPInsightDetailState.loading());
    try {
      await Future<void>.delayed(const Duration(milliseconds: 520));
      final MPInsightDetailData loaded = _buildDetailData(_item);
      emit(MPInsightDetailState.loaded(loaded));
    } catch (e) {
      emit(MPInsightDetailState.error(e.toString()));
    }
  }

  MPInsightDetailData _buildDetailData(MPInsightListItem item) {
    final int seed = item.id.hashCode & 0x7fffffff;
    final Random r = Random(seed);

    switch (item.type) {
      case MPInsightCardType.daily:
        return MPInsightDetailData(
          item: item,
          paragraphs: <String>[
            item.summary,
            'Today’s focus worked best when you reduced context switching and kept your next steps visible.',
            'If you get stuck, try capturing the “why” behind the task—clarity usually restores momentum.',
          ],
          tips: <String>[
            '把下一步写成一句可执行句',
            '将后续提醒合并到同一个时间窗口',
            if (r.nextBool()) '为高消耗任务留出缓冲 15 分钟',
          ],
        );

      case MPInsightCardType.weekly:
        return MPInsightDetailData(
          item: item,
          paragraphs: <String>[
            item.summary,
            'Over the week, your progress correlated with short capture sessions followed by one deep work block.',
            'Follow-ups were most effective when they were grouped and scheduled right after key work.',
          ],
          tips: <String>[
            '把 follow-up 放到“工作后立刻做”',
            '每周复盘一次，删掉低价值任务',
            if (r.nextBool()) '设置任务上限：一次只追求 1 个关键目标',
          ],
        );

      case MPInsightCardType.monthly:
        final List<MPMonthlyBarItem> attentionDistribution =
            <MPMonthlyBarItem>[
          const MPMonthlyBarItem(label: 'Product Engineering', value: 62),
          const MPMonthlyBarItem(label: 'Hiring', value: 38),
          const MPMonthlyBarItem(label: 'Operations', value: 54),
        ];

        final List<MPMonthlyKeyPersonItem> keyPeople =
            <MPMonthlyKeyPersonItem>[
          MPMonthlyKeyPersonItem(name: 'Jordan', count: 12 + (seed % 3)),
          MPMonthlyKeyPersonItem(name: 'Sarah', count: 9 + (seed % 4)),
          MPMonthlyKeyPersonItem(name: 'Alex', count: 7 + (seed % 5)),
        ];

        final List<String> topicsSurfacing = <String>[
          'API migration',
          'Hiring ongoing',
          'Pricing inquiry',
        ];

        final List<String> longRunningOpenThreads = <String>[
          'Hiring planning reflects ongoing bottlenecks',
          'Pricing model needs alignment with unit economics',
          'API ownership still unclear since December',
        ];

        final List<String> monthToMonthTrend = <String>[
          'Execution spent improved vs last month',
          'Team coordination reduced after decisions stabilized',
          'Still track unresolved follow-ups from early month',
        ];

        final List<MPMonthlyDecisionItem> decisionsCannotSlip =
            <MPMonthlyDecisionItem>[
          MPMonthlyDecisionItem(rank: 1, text: 'Stabilize hiring capacity'),
          MPMonthlyDecisionItem(rank: 2, text: 'Record pricing decision'),
          MPMonthlyDecisionItem(rank: 3, text: 'Clarify API ownership'),
        ];

        final List<MPMonthlySuggestedFocusItem> suggestedFocusNextMonth =
            <MPMonthlySuggestedFocusItem>[
          MPMonthlySuggestedFocusItem(
            rank: 1,
            text: 'Close ownership loop this month to unblock delivery',
          ),
          MPMonthlySuggestedFocusItem(
            rank: 2,
            text: 'Reduce hiring friction with weekly checkpoints',
          ),
          MPMonthlySuggestedFocusItem(
            rank: 3,
            text: 'Align pricing assumptions with unit economics early',
          ),
        ];

        return MPInsightDetailData(
          item: item,
          paragraphs: <String>[
            item.summary,
            'The month showed stable capture habits paired with improved execution focus.',
          ],
          tips: <String>[
            'Use suggested focus items to generate action todos for next month.',
          ],
          monthly: MPMonthlyInsightDetailData(
            monthSubtitle: item.periodLabel,
            monthOverviewSummary: item.summary,
            attentionDistribution: attentionDistribution,
            keyPeopleThisMonth: keyPeople,
            topicsSurfacing: topicsSurfacing,
            longRunningOpenThreads: longRunningOpenThreads,
            monthToMonthTrend: monthToMonthTrend,
            decisionsThatCannotSlipAgain: decisionsCannotSlip,
            suggestedFocusNextMonth: suggestedFocusNextMonth,
            askAiButtonText: 'Ask AI about this month',
          ),
        );

      case MPInsightCardType.pattern:
        return MPInsightDetailData(
          item: item,
          paragraphs: <String>[
            'API migration blockers have resurfaced across multiple conversations over the past two weeks. Ownership and delivery sequencing remain unclear, causing repeated execution friction.',
            'Continued ambiguity may delay rollout and increase cross-team coordination costs, affecting delivery confidence.',
          ],
          tips: <String>[
            'Clarify API ownership and rollout sequence in next infrastructure sync.',
            if (r.nextBool()) 'Capture the outcome of each meeting and connect it back to this pattern.',
          ],
        );
    }
  }
}

