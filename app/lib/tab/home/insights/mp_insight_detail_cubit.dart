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
    this.daily,
    this.weekly,
    this.monthly,
  });

  final MPInsightListItem item;
  final List<String> paragraphs;
  final List<String> tips;

  /// Daily 详情页专用结构化数据（其它类型为 null）
  final MPDailyInsightDetailData? daily;

  /// Weekly 详情页专用结构化数据（其它类型为 null）
  final MPWeeklyInsightDetailData? weekly;

  /// Monthly 详情页专用结构化数据（其它类型为 null）
  final MPMonthlyInsightDetailData? monthly;
}

/// Daily 详情页中的可执行建议（Tomorrow's focus）
class MPDailyFocusItem {
  const MPDailyFocusItem({
    required this.text,
  });

  final String text;
}

/// Daily 详情页结构化数据
class MPDailyInsightDetailData {
  const MPDailyInsightDetailData({
    required this.dateLabel,
    required this.narrativeTitle,
    required this.narrativeBody,
    required this.decisionsMade,
    required this.openQuestions,
    required this.patternsEmerging,
    required this.ideasCaptured,
    required this.tomorrowFocus,
    required this.askAiButtonText,
  });

  /// 顶部提示，如 `Daily Insight · Jan 28`
  final String dateLabel;

  /// Today's narrative 标题
  final String narrativeTitle;

  /// Today's narrative 正文
  final String narrativeBody;

  /// Decisions made
  final List<String> decisionsMade;

  /// Open questions
  final List<String> openQuestions;

  /// Patterns emerging
  final String patternsEmerging;

  /// Ideas captured
  final List<String> ideasCaptured;

  /// Tomorrow's focus（支持 Add to Todo）
  final List<MPDailyFocusItem> tomorrowFocus;

  /// 底部按钮文案
  final String askAiButtonText;
}

/// Weekly 详情页中的统计项
class MPWeeklyMetricItem {
  const MPWeeklyMetricItem({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

/// Weekly 详情页中的优先事项
class MPWeeklyPriorityItem {
  const MPWeeklyPriorityItem({
    required this.text,
  });

  final String text;
}

/// Weekly 详情页中的完成项
class MPWeeklyAccomplishmentItem {
  const MPWeeklyAccomplishmentItem({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

/// Weekly 详情页中的专家反馈条目
class MPWeeklyExpertFeedbackItem {
  const MPWeeklyExpertFeedbackItem({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;
}

/// Weekly 详情页结构化数据
class MPWeeklyInsightDetailData {
  const MPWeeklyInsightDetailData({
    required this.titleLabel,
    required this.subLabel,
    required this.headerSummary,
    required this.weekSummaryText,
    required this.metrics,
    required this.accomplishmentItems,
    required this.accomplishments,
    required this.challengesAndLearnings,
    required this.pendingItems,
    required this.nextWeekPriorities,
    required this.expertWeeklyFeedback,
    required this.askAiButtonText,
  });

  final String titleLabel;
  final String subLabel;
  final String headerSummary;
  final String weekSummaryText;
  final List<MPWeeklyMetricItem> metrics;
  final List<MPWeeklyAccomplishmentItem> accomplishmentItems;
  final List<String> accomplishments;
  final String challengesAndLearnings;
  final List<String> pendingItems;
  final List<MPWeeklyPriorityItem> nextWeekPriorities;
  final List<MPWeeklyExpertFeedbackItem> expertWeeklyFeedback;
  final String askAiButtonText;
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
    required this.value,
  });

  final String name;
  final int count;

  /// 进度条长度 0-100
  final int value;
}

/// Monthly 详情页卡片中的条目：Topics
class MPMonthlyTopicItem {
  const MPMonthlyTopicItem({
    required this.label,
    required this.value,
  });

  final String label;

  /// 进度条长度 0-100
  final int value;
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
    required this.attentionDistributionSummary,
    required this.keyPeopleThisMonthSummary,
    required this.topicsSurfacingSummary,
    required this.longRunningOpenThreads,
    required this.longRunningOpenThreadsSummary,
    required this.monthToMonthTrend,
    required this.decisionsThatCannotSlipAgain,
    required this.decisionsThatCannotSlipAgainSummary,
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
  final List<MPMonthlyTopicItem> topicsSurfacing;

  /// Attention Distribution 底部说明
  final String attentionDistributionSummary;

  /// Key People 底部说明
  final String keyPeopleThisMonthSummary;

  /// Topics 底部说明
  final String topicsSurfacingSummary;

  /// Long-running Open Threads
  final List<String> longRunningOpenThreads;

  /// Long-running Open Threads 底部说明
  final String longRunningOpenThreadsSummary;

  /// Month-to-Month Trend
  final List<String> monthToMonthTrend;

  /// Decisions That Cannot Slip Again
  final List<MPMonthlyDecisionItem> decisionsThatCannotSlipAgain;

  /// Decisions That Cannot Slip Again 底部说明
  final String decisionsThatCannotSlipAgainSummary;

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
        final List<String> decisionsMade = <String>[
          'Delay external rollout until recording is stable',
          'Prioritize audio reliability over new features',
          'Proceed with phased API migration to reduce risk',
        ];
        final List<String> openQuestions = <String>[
          'Migration timeline still unclear under infra limits',
          'User segmentation strategy not aligned yet',
          'Who owns onboarding improvements is undefined',
        ];
        final List<String> ideasCaptured = <String>[
          'Simplify onboarding steps for ADHD users',
          'Add a lightweight daily review loop',
          'Improve hardware status feedback clarity',
        ];
        final List<MPDailyFocusItem> tomorrowFocus = <MPDailyFocusItem>[
          const MPDailyFocusItem(text: 'Review migration milestones'),
          const MPDailyFocusItem(text: 'Align infrastructure support priorities'),
        ];

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
          daily: MPDailyInsightDetailData(
            dateLabel: 'Daily Insight · ${item.periodLabel}',
            narrativeTitle: 'Today\'s narrative',
            narrativeBody:
                'Today\'s conversations centered on API architecture and product positioning. Several threads returned to the same tension: shipping fast vs. stabilizing recording reliability. Concerns about scalability and team bandwidth kept resurfacing.',
            decisionsMade: decisionsMade,
            openQuestions: openQuestions,
            patternsEmerging:
                'Architecture concerns have surfaced repeatedly for several days, suggesting systemic friction rather than isolated implementation issues.',
            ideasCaptured: ideasCaptured,
            tomorrowFocus: tomorrowFocus,
            askAiButtonText: 'Ask AI about today',
          ),
        );

      case MPInsightCardType.weekly:
        final List<MPWeeklyMetricItem> metrics = <MPWeeklyMetricItem>[
          const MPWeeklyMetricItem(value: '8', label: 'tasks'),
          const MPWeeklyMetricItem(value: '5', label: 'decisions'),
          const MPWeeklyMetricItem(value: '12', label: 'meetings'),
        ];
        final List<MPWeeklyAccomplishmentItem> accomplishmentItems =
            <MPWeeklyAccomplishmentItem>[
          const MPWeeklyAccomplishmentItem(
            title: 'API Migration Completed',
            description:
                'Successfully migrated 3 core endpoints to new architecture',
          ),
          const MPWeeklyAccomplishmentItem(
            title: 'Design System Updates',
            description: 'Shipped 12 new components with documentation',
          ),
          const MPWeeklyAccomplishmentItem(
            title: 'Client Onboarding',
            description: 'Completed onboarding for 2 new enterprise clients',
          ),
        ];

        final List<String> accomplishments = <String>[
          'API Migration Completed',
          'Design System Updates',
          'Client Onboarding',
        ];
        final List<String> pendingItems = <String>[
          'Resolve migration bottlenecks with infra team',
          'Update API documentation for V2 endpoints',
          'Schedule follow-up with sales thread',
        ];
        final List<MPWeeklyPriorityItem> nextWeekPriorities =
            <MPWeeklyPriorityItem>[
          const MPWeeklyPriorityItem(text: 'Launch Mobile Beta'),
          const MPWeeklyPriorityItem(text: 'Q1 Planning Session'),
          const MPWeeklyPriorityItem(text: 'Performance Optimization'),
        ];
        final List<MPWeeklyExpertFeedbackItem> expertFeedback =
            <MPWeeklyExpertFeedbackItem>[
          const MPWeeklyExpertFeedbackItem(
            title: 'Business Expert',
            content:
                'Pricing strategy shows strong signal, but decision checkpoints should tighten across stakeholders.',
          ),
          const MPWeeklyExpertFeedbackItem(
            title: 'Growth Expert',
            content:
                'Weekly activation dipped in onboarding; simplify the first-session flow and instrument drop-off.',
          ),
          const MPWeeklyExpertFeedbackItem(
            title: 'Execution Expert',
            content:
                'Team absorbed high context-switch cost; protect one deep-work block each day for core delivery.',
          ),
        ];

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
          weekly: MPWeeklyInsightDetailData(
            titleLabel: 'Week of ${item.periodLabel}',
            subLabel: 'Jan 19, 08:00 AM - Jan 25, 06:00 PM',
            headerSummary:
                'A productive week with strong momentum on the product roadmap. You balanced strategic planning with hands-on execution, improving delivery for key initiatives.',
            weekSummaryText:
                'Product development, team coordination, and client engagement dominated this week. You spent approximately 60% of time in execution and 40% in delivery/meetings.',
            metrics: metrics,
            accomplishmentItems: accomplishmentItems,
            accomplishments: accomplishments,
            challengesAndLearnings:
                'Resource constraints and transition pressure surfaced repeatedly. Clearer role alignment reduced execution friction by week end.',
            pendingItems: pendingItems,
            nextWeekPriorities: nextWeekPriorities,
            expertWeeklyFeedback: expertFeedback,
            askAiButtonText: 'Ask AI about this week',
          ),
        );

      case MPInsightCardType.monthly:
        final List<MPMonthlyBarItem> attentionDistribution =
            <MPMonthlyBarItem>[
          const MPMonthlyBarItem(label: 'Product', value: 70),
          const MPMonthlyBarItem(label: 'Engineering', value: 55),
          const MPMonthlyBarItem(label: 'Hiring', value: 35),
        ];

        final List<MPMonthlyKeyPersonItem> keyPeople =
            <MPMonthlyKeyPersonItem>[
          MPMonthlyKeyPersonItem(
            name: 'Jordan',
            count: 12 + (seed % 3),
            value: 72,
          ),
          MPMonthlyKeyPersonItem(
            name: 'Alex',
            count: 10 + (seed % 4),
            value: 58,
          ),
          MPMonthlyKeyPersonItem(
            name: 'Sarah',
            count: 8 + (seed % 5),
            value: 42,
          ),
        ];

        final List<MPMonthlyTopicItem> topicsSurfacing = <MPMonthlyTopicItem>[
          const MPMonthlyTopicItem(label: 'API migration', value: 68),
          const MPMonthlyTopicItem(label: 'Hiring bandwidth', value: 52),
          const MPMonthlyTopicItem(label: 'Pricing strategy', value: 32),
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
            attentionDistributionSummary:
                'Most effort went into execution, while hiring constraints continued to slow delivery.',
            keyPeopleThisMonthSummary:
                'Conversations repeatedly involved delivery ownership and coordination.',
            topicsSurfacingSummary:
                'These topics appeared across multiple weeks without clear resolution.',
            longRunningOpenThreads: longRunningOpenThreads,
            longRunningOpenThreadsSummary:
                'These issues repeatedly delayed progress.',
            monthToMonthTrend: monthToMonthTrend,
            decisionsThatCannotSlipAgain: decisionsCannotSlip,
            decisionsThatCannotSlipAgainSummary:
                'If unresolved next month, these will continue to slow execution.',
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

