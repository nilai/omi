import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Insights 卡片类型（四类：Daily / Weekly / Monthly / Pattern）
enum MPInsightCardType {
  daily,
  weekly,
  monthly,
  pattern,
}

/// Insights 列表项（用于列表卡片展示 + 点击后详情页初始化）
class MPInsightListItem {
  const MPInsightListItem({
    required this.id,
    required this.type,
    required this.periodLabel,
    required this.title,
    required this.subtitle,
    required this.summary,
    this.unreadCount = 0,
    this.bullets = const <String>[],
    this.decisionsCount,
    this.followUpsCount,
    this.risksCount,
    this.completedCount,
    this.pendingCount,
    this.recommendationsCount,
    this.recurringThemes = const <String>[],
    this.patternMemoryTitles = const <String>[],
  });

  final String id;
  final MPInsightCardType type;

  /// 列表卡片顶部相对时间，如 `Mar 30`
  final String periodLabel;

  /// 例如 Daily/Weekly/Monthly 的大标题
  final String title;

  /// 例如 subtitle：End-of-day reflection / Week of ...
  final String subtitle;

  /// 列表卡片摘要（点击进入详情页）
  final String summary;

  /// 列表卡片右上角角标（模拟动态数）
  final int unreadCount;

  /// 卡片底部 bullet 列表（与截图对齐）
  final List<String> bullets;

  /// Daily counts
  final int? decisionsCount;
  final int? followUpsCount;
  final int? risksCount;

  /// Weekly/Monthly counts
  final int? completedCount;
  final int? pendingCount;
  final int? recommendationsCount;

  /// Pattern recurring themes
  final List<String> recurringThemes;

  /// Pattern 相关记忆（展示用）
  final List<String> patternMemoryTitles;
}

/// Insights 列表阶段
enum MPInsightsListPhase { loading, empty, error, loaded }

/// Insights 列表状态（游标分页：加载更多）
class MPInsightsListState {
  const MPInsightsListState({
    required this.phase,
    this.items = const <MPInsightListItem>[],
    this.errorMessage,
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  final MPInsightsListPhase phase;
  final List<MPInsightListItem> items;
  final String? errorMessage;
  final bool isLoadingMore;
  final bool hasMore;

  MPInsightsListState copyWith({
    MPInsightsListPhase? phase,
    List<MPInsightListItem>? items,
    String? errorMessage,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return MPInsightsListState(
      phase: phase ?? this.phase,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Insights 列表：首屏加载、下拉刷新、上拉更多
///
/// 备注：当前为 mock 数据；接真实接口时替换 `_fetchPage` 即可。
class MPInsightsListCubit extends Cubit<MPInsightsListState> {
  MPInsightsListCubit() : super(const MPInsightsListState(phase: MPInsightsListPhase.loading));

  static const int _pageSize = 8;
  static const int _maxPages = 4;

  /// 当前分页索引（从 0 开始；next page = [_cursorPage]）
  int _cursorPage = 0;

  /// 首次进入 / 刷新第一页
  Future<void> initData() => load();

  /// 刷新第一页：重置游标并拉取
  Future<void> load() async {
    final List<MPInsightListItem> before = List<MPInsightListItem>.from(state.items);
    final bool hasData = before.isNotEmpty;

    if (!hasData) {
      emit(const MPInsightsListState(phase: MPInsightsListPhase.loading));
    } else {
      emit(state.copyWith(
        phase: MPInsightsListPhase.loaded,
        errorMessage: null,
        isLoadingMore: false,
      ));
    }

    try {
      _cursorPage = 0;
      final _PageResult result = await _fetchPage(page: _cursorPage);
      if (result.items.isEmpty) {
        emit(const MPInsightsListState(
          phase: MPInsightsListPhase.empty,
          hasMore: false,
        ));
        return;
      }

      emit(MPInsightsListState(
        phase: MPInsightsListPhase.loaded,
        items: result.items,
        hasMore: result.hasMore,
      ));
    } catch (e) {
      emit(MPInsightsListState(
        phase: hasData ? MPInsightsListPhase.loaded : MPInsightsListPhase.error,
        items: hasData ? before : const <MPInsightListItem>[],
        errorMessage: e.toString(),
        hasMore: hasData ? state.hasMore : false,
      ));
    }
  }

  /// 上拉更多
  Future<void> loadMore() async {
    if (state.phase != MPInsightsListPhase.loaded) return;
    if (state.isLoadingMore) return;
    if (!state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final int nextPage = _cursorPage + 1;
      final _PageResult result = await _fetchPage(page: nextPage);
      final List<MPInsightListItem> current = List<MPInsightListItem>.from(state.items);

      if (result.items.isEmpty) {
        emit(state.copyWith(isLoadingMore: false, hasMore: false));
        return;
      }

      _cursorPage = nextPage;
      emit(state.copyWith(
        isLoadingMore: false,
        hasMore: result.hasMore,
        items: <MPInsightListItem>[...current, ...result.items],
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

}

class _PageResult {
  const _PageResult({required this.items, required this.hasMore});
  final List<MPInsightListItem> items;
  final bool hasMore;
}

/// Mock：模拟后台分页拉取
Future<_PageResult> _fetchPage({
  required int page,
}) async {
  // 模拟网络延迟
  await Future<void>.delayed(const Duration(milliseconds: 520));

  if (page < 0 || page >= MPInsightsListCubit._maxPages) {
    return const _PageResult(items: <MPInsightListItem>[], hasMore: false);
  }

  final DateTime base = DateTime(2026, 3, 30);
  final List<MPInsightListItem> list = <MPInsightListItem>[];

  for (int i = 0; i < MPInsightsListCubit._pageSize; i++) {
    final int globalIndex = page * MPInsightsListCubit._pageSize + i;
    final MPInsightCardType type = switch (globalIndex % 4) {
      0 => MPInsightCardType.daily,
      1 => MPInsightCardType.weekly,
      2 => MPInsightCardType.monthly,
      _ => MPInsightCardType.pattern,
    };

    final int unread = globalIndex % 3 == 0 ? (1 + globalIndex % 4) : 0;

    final String id = '${type.name}-$globalIndex';

    switch (type) {
      case MPInsightCardType.daily: {
        final DateTime d = base.subtract(Duration(days: globalIndex));
        final String month = _monthShortEn(d.month);
        final String period = '$month ${d.day}';
        final int decisions = 1 + (globalIndex % 3);
        final int followUps = 1 + (globalIndex % 4);
        final int risks = 1 + (globalIndex % 2);
        final String time = _timeLabelFromIndex(globalIndex);

        list.add(
          MPInsightListItem(
            id: id,
            type: type,
            periodLabel: period,
            title: 'Daily Insight',
            subtitle: 'End-of-day reflection · $time',
            summary:
                'You reviewed your day and noticed patterns in what helped you focus.',
            unreadCount: unread,
            bullets: <String>[
              '$decisions decisions made',
              '$followUps follow-ups pending',
              '$risks risk to watch',
            ],
            decisionsCount: decisions,
            followUpsCount: followUps,
            risksCount: risks,
          ),
        );
        break;
      }

      case MPInsightCardType.weekly: {
        final DateTime d = base.subtract(Duration(days: globalIndex * 3));
        final String month = _monthShortEn(d.month);
        final String period = '$month ${d.day}';
        final int completed = 6 + (globalIndex % 7);
        final int pending = 2 + (globalIndex % 5);
        final int recommendations = 1 + (globalIndex % 4);
        final String time = _timeLabelFromIndex(globalIndex);

        list.add(
          MPInsightListItem(
            id: id,
            type: type,
            periodLabel: period,
            title: 'Weekly Insight',
            subtitle: 'Week of your progress · $time',
            summary:
                'A productive week: your focus improved when you grouped follow-ups together.',
            unreadCount: unread,
            bullets: <String>[
              '$completed tasks completed',
              '$pending pending for next week',
              '$recommendations recommendations',
            ],
            completedCount: completed,
            pendingCount: pending,
            recommendationsCount: recommendations,
          ),
        );
        break;
      }

      case MPInsightCardType.monthly: {
        final DateTime d = base.subtract(Duration(days: globalIndex * 15));
        final String monthName = _monthShortEn(d.month);
        final String period = '$monthName ${d.day}';
        final String time = _timeLabelFromIndex(globalIndex);
        final int completed = 10 + (globalIndex % 10);
        final int pending = 5 + (globalIndex % 8);
        final int recommendations = 2 + (globalIndex % 5);

        list.add(
          MPInsightListItem(
            id: id,
            type: type,
            periodLabel: period,
            title: 'Monthly Insight',
            subtitle: 'January 2026 · $time',
            summary:
                'You made steady progress over the month—your best results came from consistent capture.',
            unreadCount: unread,
            bullets: <String>[
              'Focus concentrated on product & delivery',
              '${3 + (globalIndex % 5)} long-running threads still unresolved',
              'Momentum improving, but decisions lagging behind throughout the month',
            ],
            completedCount: completed,
            pendingCount: pending,
            recommendationsCount: recommendations,
          ),
        );
        break;
      }

      case MPInsightCardType.pattern: {
        final DateTime d = base.subtract(Duration(days: globalIndex));
        final String month = _monthShortEn(d.month);
        final String period = '$month ${d.day}';
        final int discussions = 4 + (globalIndex % 5);
        final String time = _timeLabelFromIndex(globalIndex);

        list.add(
          MPInsightListItem(
            id: id,
            type: type,
            periodLabel: period,
            title: 'Pattern detected',
            subtitle: 'Cross-memory insight - Emerging pattern · $time',
            summary:
                'MemoPin noticed recurring themes across multiple memories and turns them into actionable insights.',
            unreadCount: unread,
            bullets: <String>[
              'Appeared in $discussions discussions this week',
              'Issue still unresolved',
              'Ownership remains unclear',
            ],
            recurringThemes: <String>[
              'Execution overload',
              'Timeline pressure',
              if (globalIndex % 2 == 0) 'Authentication risks',
            ],
            patternMemoryTitles: <String>[
              'Team standup discussion on API migration',
              'Client feedback call about new dashboard features',
            ],
          ),
        );
        break;
      }
    }
  }

  final bool hasMore = page < MPInsightsListCubit._maxPages - 1;
  return _PageResult(items: list, hasMore: hasMore);
}

String _monthShortEn(int month) {
  return switch (month) {
    1 => 'Jan',
    2 => 'Feb',
    3 => 'Mar',
    4 => 'Apr',
    5 => 'May',
    6 => 'Jun',
    7 => 'Jul',
    8 => 'Aug',
    9 => 'Sep',
    10 => 'Oct',
    11 => 'Nov',
    12 => 'Dec',
    _ => 'Mon',
  };
}

String _timeLabelFromIndex(int index) {
  const List<String> times = <String>[
    '10:00 AM',
    '11:00 AM',
    '02:00 PM',
    '05:30 PM',
    '10:00 PM',
    '11:00 PM',
  ];
  return times[index % times.length];
}

