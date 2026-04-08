import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../http/api/mp_insight.dart';
import '../../../http/schema/mp_insight.dart';
import 'mp_insights_list_cubit.dart';

/// Insights 详情页状态
enum MPInsightDetailPhase { loading, loaded, error }

/// 详情页状态
class MPInsightDetailState {
  const MPInsightDetailState({required this.phase, this.data, this.errorMessage});

  final MPInsightDetailPhase phase;
  final MPInsightDetailData? data;
  final String? errorMessage;

  factory MPInsightDetailState.loading() => const MPInsightDetailState(phase: MPInsightDetailPhase.loading);

  factory MPInsightDetailState.loaded(MPInsightDetailData data) =>
      MPInsightDetailState(phase: MPInsightDetailPhase.loaded, data: data);

  factory MPInsightDetailState.error(String message) =>
      MPInsightDetailState(phase: MPInsightDetailPhase.error, errorMessage: message);
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
  const MPDailyFocusItem({required this.text});

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
  const MPWeeklyMetricItem({required this.value, required this.label});

  final String value;
  final String label;
}

/// Weekly 详情页中的优先事项
class MPWeeklyPriorityItem {
  const MPWeeklyPriorityItem({required this.text, required this.subtitle, this.visible = true});

  final String text;
  final String subtitle;
  final bool visible;
}

/// Weekly 详情页中的完成项
class MPWeeklyAccomplishmentItem {
  const MPWeeklyAccomplishmentItem({required this.title, required this.description});

  final String title;
  final String description;
}

/// Weekly 详情页中的专家反馈条目
class MPWeeklyExpertFeedbackItem {
  const MPWeeklyExpertFeedbackItem({
    required this.title,
    required this.content,
    required this.iconKey,
    required this.iconColorValue,
    this.visible = true,
  });

  final String title;
  final String content;
  final String iconKey;
  final int iconColorValue;
  final bool visible;
}

/// Weekly 详情页中的 Challenges/Learnings 子项
class MPWeeklyChallengeLearningItem {
  const MPWeeklyChallengeLearningItem({
    required this.title,
    required this.description,
    required this.backgroundColorValue,
    required this.borderColorValue,
  });

  final String title;
  final String description;
  final int backgroundColorValue;
  final int borderColorValue;
}

/// Weekly 详情页中的 pending item
class MPWeeklyPendingItem {
  const MPWeeklyPendingItem({required this.text, required this.visible});

  final String text;
  final bool visible;
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
    required this.challengeLearningItems,
    required this.pendingItems,
    required this.pendingItemCards,
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
  final List<MPWeeklyChallengeLearningItem> challengeLearningItems;
  final List<String> pendingItems;
  final List<MPWeeklyPendingItem> pendingItemCards;
  final List<MPWeeklyPriorityItem> nextWeekPriorities;
  final List<MPWeeklyExpertFeedbackItem> expertWeeklyFeedback;
  final String askAiButtonText;
}

/// Monthly 详情页卡片中的条目：注意力分布
class MPMonthlyBarItem {
  const MPMonthlyBarItem({required this.label, required this.value});

  /// 左侧标签，如 `Product`
  final String label;

  /// 数值 0-100，用于渲染条形长度
  final int value;
}

/// Monthly 详情页卡片中的条目：关键人物
class MPMonthlyKeyPersonItem {
  const MPMonthlyKeyPersonItem({required this.name, required this.count, required this.value});

  final String name;
  final int count;

  /// 进度条长度 0-100
  final int value;
}

/// Monthly 详情页卡片中的条目：Topics
class MPMonthlyTopicItem {
  const MPMonthlyTopicItem({required this.label, required this.value});

  final String label;

  /// 进度条长度 0-100
  final int value;
}

/// Monthly 详情页卡片中的条目：决策项
class MPMonthlyDecisionItem {
  const MPMonthlyDecisionItem({required this.rank, required this.text});

  final int rank;
  final String text;
}

/// Monthly 详情页卡片中的条目：下月关注建议
class MPMonthlySuggestedFocusItem {
  const MPMonthlySuggestedFocusItem({required this.rank, required this.text});

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
  MPInsightDetailCubit({required MPInsightListItem item}) : _item = item, super(MPInsightDetailState.loading());

  final MPInsightListItem _item;

  /// 页面初始化：拉取详情
  Future<void> initData() async {
    emit(MPInsightDetailState.loading());
    try {
      await Future<void>.delayed(const Duration(milliseconds: 520));
      final MPInsightDetailData loaded = await _buildDetailData(_item);
      emit(MPInsightDetailState.loaded(loaded));
    } catch (e) {
      emit(MPInsightDetailState.error(e.toString()));
    }
  }

  Future<MPInsightDetailData> _buildDetailData(MPInsightListItem item) async {
    final MPGetInsightDetailResponse? response = await getInsightDetail(MPGetInsightDetailRequest(insightId: item.id));
    if (response == null) {
      throw Exception('insight detail response is null');
    }
    if (response.baseResp.code != 0) {
      throw Exception(response.baseResp.message);
    }

    switch (item.type) {
      case MPInsightCardType.daily:
        return _buildDailyDetailData(item, response.insightDetail.dailyDetail);

      case MPInsightCardType.weekly:
        return _buildWeeklyDetailData(item, response.insightDetail.weeklyDetail);

      case MPInsightCardType.monthly:
        return _buildMonthlyDetailData(item, response.insightDetail.monthlyDetail);

      case MPInsightCardType.pattern:
        return _buildPatternDetailData(item, response.insightDetail.patternDetail);
    }
  }

  MPInsightDetailData _buildDailyDetailData(
    MPInsightListItem item,
    MPDailyInsightDetailStruct? detail,
  ) {
    if (detail == null) {
      throw Exception('daily_detail is null');
    }
    debugPrint('-----hjj-----daily_detail: ${detail.toJson()}');
    final List<String> decisionsMade = detail.decisionsMade.items
        .map((MPDailyInsightTextItemStruct e) => e.content)
        .where((String e) => e.isNotEmpty)
        .toList();
    final List<String> openQuestions = detail.openQuestions.items
        .map((MPDailyInsightTextItemStruct e) => e.content)
        .where((String e) => e.isNotEmpty)
        .toList();
    final List<String> ideasCaptured = detail.ideasCaptured.items
        .map((MPDailyInsightTextItemStruct e) => e.content)
        .where((String e) => e.isNotEmpty)
        .toList();
    final List<MPDailyFocusItem> tomorrowFocus = detail.tomorrowFocus
        .map((String e) => MPDailyFocusItem(text: e))
        .toList();

    return MPInsightDetailData(
      item: item,
      paragraphs: <String>[
        item.content,
        detail.narrative.content,
      ].where((String e) => e.isNotEmpty).toList(),
      tips: [],
      daily: MPDailyInsightDetailData(
        dateLabel: 'Daily Insight · ${item.periodLabel}',
        narrativeTitle: detail.narrative.content.isNotEmpty
            ? detail.decisionsMade.title
            : 'Today\'s narrative',
        narrativeBody: detail.narrative.content,
        decisionsMade: decisionsMade,
        openQuestions: openQuestions,
        patternsEmerging: detail.patternsEmerging.content,
        ideasCaptured: ideasCaptured,
        tomorrowFocus: tomorrowFocus,
        askAiButtonText: 'Ask AI about today',
      ),
    );
  }

  MPInsightDetailData _buildWeeklyDetailData(
    MPInsightListItem item,
    MPWeeklyInsightDetailStruct? detail,
  ) {
    if (detail == null) {
      throw Exception('weekly_detail is null');
    }
    debugPrint('-----hjj-----weekly_detail: ${detail.toJson()}');
    final List<MPWeeklyMetricItem> metrics = detail.weekSummary.keyMetrics
        .map(
          (MPWeeklyInsightMetricItemStruct e) => MPWeeklyMetricItem(
            value: '${e.value}',
            label: e.label,
          ),
        )
        .toList();
    final List<MPWeeklyAccomplishmentItem> accomplishmentItems = detail.accomplishments
        .map(
          (MPWeeklyInsightAccomplishmentItemStruct e) =>
              MPWeeklyAccomplishmentItem(title: e.title, description: e.description),
        )
        .toList();
    final List<String> accomplishments = detail.accomplishments
        .map((MPWeeklyInsightAccomplishmentItemStruct e) => e.title)
        .where((String e) => e.isNotEmpty)
        .toList();
    final List<String> pendingItems = detail.pendingItems
        .map((MPWeeklyInsightPendingItemStruct e) => e.content)
        .where((String e) => e.isNotEmpty)
        .toList();
    final List<MPWeeklyPendingItem> pendingItemCards = detail.pendingItems
        .map((MPWeeklyInsightPendingItemStruct e) => MPWeeklyPendingItem(text: e.content, visible: true))
        .toList();
    final List<MPWeeklyChallengeLearningItem> challengeLearningItems = detail.challengesAndLearnings
        .map(
          (MPWeeklyInsightChallengeItemStruct e) => MPWeeklyChallengeLearningItem(
            title: e.title,
            description: e.description,
            backgroundColorValue: 0xFFF5F1E7,
            borderColorValue: 0xFFECD8A5,
          ),
        )
        .toList();
    final List<MPWeeklyPriorityItem> nextWeekPriorities = detail.nextWeekPriorities
        .map(
          (MPWeeklyInsightPriorityItemStruct e) => MPWeeklyPriorityItem(
            text: e.title,
            subtitle: e.subTitle ?? '',
            visible: true,
          ),
        )
        .toList();
    final List<MPWeeklyExpertFeedbackItem> expertFeedback = detail.expertWeeklyFeedback
        .map(
          (MPWeeklyInsightExpertFeedbackItemStruct e) => MPWeeklyExpertFeedbackItem(
            title: e.expertName,
            content: e.feedback,
            iconKey: 'business',
            iconColorValue: 0xFF3A75F0,
          ),
        )
        .toList();

    return MPInsightDetailData(
      item: item,
      paragraphs: <String>[
        item.content,
        detail.header.summary,
      ].where((String e) => e.isNotEmpty).toList(),
      tips: [],
      weekly: MPWeeklyInsightDetailData(
        titleLabel: detail.header.title.isNotEmpty ? detail.header.title : 'Week of ${item.periodLabel}',
        subLabel: detail.header.subTitle,
        headerSummary: detail.header.summary,
        weekSummaryText: detail.weekSummary.focusAreas,
        metrics: metrics,
        accomplishmentItems: accomplishmentItems,
        accomplishments: accomplishments,
        challengesAndLearnings:
            detail.challengesAndLearnings.map((MPWeeklyInsightChallengeItemStruct e) => e.description).join('\n'),
        challengeLearningItems: challengeLearningItems,
        pendingItems: pendingItems,
        pendingItemCards: pendingItemCards,
        nextWeekPriorities: nextWeekPriorities,
        expertWeeklyFeedback: expertFeedback,
        askAiButtonText: 'Ask AI about this week',
      ),
    );
  }

  MPInsightDetailData _buildMonthlyDetailData(
    MPInsightListItem item,
    MPMonthlyInsightDetailStruct? detail,
  ) {
    if (detail == null) {
      throw Exception('monthly_detail is null');
    }
    debugPrint('-----hjj-----monthly_detail: ${detail.toJson()}');
    final List<MPMonthlyBarItem> attentionDistribution = detail.attentionDistribution.items
        .map((MPMonthlyInsightDistributionItemStruct e) => MPMonthlyBarItem(label: e.name, value: e.value))
        .toList();
    final List<MPMonthlyKeyPersonItem> keyPeople = detail.keyPeople.items
        .map(
          (MPMonthlyInsightDistributionItemStruct e) => MPMonthlyKeyPersonItem(
            name: e.name,
            count: e.value,
            value: e.value,
          ),
        )
        .toList();
    final List<MPMonthlyTopicItem> topicsSurfacing = detail.topicsResurfacing.items
        .map((MPMonthlyInsightDistributionItemStruct e) => MPMonthlyTopicItem(label: e.name, value: e.value))
        .toList();
    final List<String> longRunningOpenThreads =
        detail.openThreads.items.map((MPMonthlyInsightOpenThreadItemStruct e) => e.content).toList();
    final List<MPMonthlyDecisionItem> decisionsCannotSlip = detail.decisions.items
        .asMap()
        .entries
        .map((MapEntry<int, String> e) => MPMonthlyDecisionItem(rank: e.key + 1, text: e.value))
        .toList();
    final List<MPMonthlySuggestedFocusItem> suggestedFocusNextMonth = detail.suggestedFocusNextMonth
        .asMap()
        .entries
        .map((MapEntry<int, String> e) => MPMonthlySuggestedFocusItem(rank: e.key + 1, text: e.value))
        .toList();

    return MPInsightDetailData(
      item: item,
      paragraphs: <String>[
        item.content,
        detail.overview.contentMd,
      ].where((String e) => e.isNotEmpty).toList(),
      tips:[],
      monthly: MPMonthlyInsightDetailData(
        monthSubtitle: item.periodLabel,
        monthOverviewSummary: detail.overview.contentMd,
        attentionDistribution: attentionDistribution,
        keyPeopleThisMonth: keyPeople,
        topicsSurfacing: topicsSurfacing,
        attentionDistributionSummary: detail.attentionDistribution.summary ?? '',
        keyPeopleThisMonthSummary: detail.keyPeople.summary ?? '',
        topicsSurfacingSummary: detail.topicsResurfacing.summary ?? '',
        longRunningOpenThreads: longRunningOpenThreads,
        longRunningOpenThreadsSummary: detail.openThreads.summary ?? '',
        monthToMonthTrend: detail.monthToMonthTrend,
        decisionsThatCannotSlipAgain: decisionsCannotSlip,
        decisionsThatCannotSlipAgainSummary: detail.decisions.intro,
        suggestedFocusNextMonth: suggestedFocusNextMonth,
        askAiButtonText: 'Ask AI about this month',
      ),
    );
  }

  MPInsightDetailData _buildPatternDetailData(
    MPInsightListItem item,
    MPPatternInsightDetailStruct? detail,
  ) {
    if (detail == null) {
      throw Exception('pattern_detail is null');
    }
    debugPrint('-----hjj-----pattern_detail: ${detail.toJson()}');
    return MPInsightDetailData(
      item: item,
      paragraphs: <String>[
        detail.detected.contentMd,
        detail.whyThisMatters,
      ].where((String e) => e.isNotEmpty).toList(),
      tips: <String>[
        ...detail.nextStep,
      ],
    );
  }

}
