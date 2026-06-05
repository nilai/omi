import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../cache/omi_cache_manager.dart';
import '../../../common/mp_date_utils.dart';
import '../../../utils/mp_time_utils.dart';
import '../../../http/api/mp_insight.dart';
import '../../../http/schema/mp_insight.dart';

/// Insights 卡片类型（四类：Daily / Weekly / Monthly / Pattern）
enum MPInsightCardType {
  daily,
  weekly,
  monthly,
  pattern;

  static MPInsightCardType fromServerString(String value) {
    return switch (value) {
      'DAILY' => daily,
      'WEEKLY' => weekly,
      'MONTHLY' => monthly,
      'PATTERN' => pattern,
      _ => throw Exception('Invalid insight card type: $value'),
    };
  }
}

/// Insights 列表项（用于列表卡片展示 + 点击后详情页初始化）
class MPInsightListItem {
  const MPInsightListItem({
    required this.id,
    required this.type,
    required this.periodLabel,
    required this.title,
    required this.subtitle,
    required this.content,
    this.unreadCount = 0,
    this.showPatternDeepLine = false,
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

  /// 列表卡片内容（点击进入详情页）
  final String content;

  /// 列表卡片右上角角标（模拟动态数）
  final int unreadCount;


  /// pattern 卡片左侧深色竖线开关（用于区分两种状态）
  final bool showPatternDeepLine;

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

  static const int _pageSize = 20;

  /// 当前分页索引（从 0 开始；next page = [_cursorPage]）
  int _cursorPage = 0;

  /// 首次进入 / 刷新第一页
  Future<void> initData() => load();

  /// 刷新第一页：先读本地缓存展示，再拉取后端并更新缓存
  Future<void> load() async {
    final List<MPInsightListItem> before = List<MPInsightListItem>.from(state.items);
    bool hasData = before.isNotEmpty;
    bool bootstrappedFromCache = false;

    if (!hasData) {
      await OmiCacheManager().initialize();
      final _PageResult? cached = _loadCachedFirstPage();
      if (cached != null && cached.items.isNotEmpty) {
        emit(
          MPInsightsListState(
            phase: MPInsightsListPhase.loaded,
            items: cached.items,
            hasMore: true,
          ),
        );
        hasData = true;
        bootstrappedFromCache = true;
      } else {
        emit(const MPInsightsListState(phase: MPInsightsListPhase.loading));
      }
    } else {
      emit(
        state.copyWith(
          phase: MPInsightsListPhase.loaded,
          errorMessage: null,
          isLoadingMore: false,
        ),
      );
    }

    try {
      _cursorPage = 0;
      final _PageResult result = await _fetchPage(page: _cursorPage);
      if (result.items.isEmpty) {
        emit(
          const MPInsightsListState(
            phase: MPInsightsListPhase.empty,
            hasMore: false,
          ),
        );
        return;
      }

      emit(
        MPInsightsListState(
          phase: MPInsightsListPhase.loaded,
          items: result.items,
          hasMore: result.hasMore,
        ),
      );
    } catch (e) {
      if (hasData || bootstrappedFromCache) {
        return;
      }
      emit(
        MPInsightsListState(
          phase: MPInsightsListPhase.error,
          errorMessage: e.toString(),
          hasMore: false,
        ),
      );
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

  /// 时间戳 → 列表日期文案：当年为 `Feb 2`，非当年为 `2024 Feb 2`。
  String _formatInsightPeriodLabel(int timestamp) {
    final DateTime? dt = MPDateUtils.dateTimeFromUnixEpoch(timestamp);
    if (dt == null) {
      return '';
    }
    final int currentYear = MPTimeUtils.nowInTimeZone().year;
    if (dt.year == currentYear) {
      return DateFormat('MMM d').format(dt);
    }
    return DateFormat('y MMM d').format(dt);
  }

  _PageResult? _loadCachedFirstPage() {
    final dynamic cached = OmiCacheManager().getInsightFeedFirstPage();
    if (cached is! Map) {
      return null;
    }
    try {
      final MPGetInsightFeedListResponse response = MPGetInsightFeedListResponse.fromJson(
        Map<String, dynamic>.from(cached),
      );
      if (response.baseResp.code != 0) {
        return null;
      }
      final List<MPInsightListItem> items = _mapCardsToItems(response.cards);
      if (items.isEmpty) {
        return null;
      }
      return _PageResult(items: items, hasMore: response.hasMore);
    } catch (_) {
      return null;
    }
  }

  void _persistFirstPageCache(MPGetInsightFeedListResponse response) {
    OmiCacheManager().putInsightFeedFirstPage(response.toJson());
  }

  List<MPInsightListItem> _mapCardsToItems(List<MPInsightCardStruct> cards) {
    final List<MPInsightListItem> list = <MPInsightListItem>[];
    for (final MPInsightCardStruct card in cards) {
      if (card.id.isEmpty) continue;
      if (card.cycleType <= 0) continue;
      if (card.cycleType > 4) continue;
      list.add(
        MPInsightListItem(
          id: card.id,
          type: MPInsightCardType.values[card.cycleType - 1],
          periodLabel: _formatInsightPeriodLabel(card.createAt),
          title: card.title,
          subtitle: card.subTitle,
          content: card.content,
          unreadCount: 0,
          showPatternDeepLine: false,
          decisionsCount: 0,
          followUpsCount: 0,
          risksCount: 0,
          completedCount: 0,
          pendingCount: 0,
          recommendationsCount: 0,
        ),
      );
    }
    return list;
  }

  Future<_PageResult> _fetchPage({required int page}) async {
    final MPGetInsightFeedListResponse? response = await getInsightFeedList(
      MPGetInsightFeedListRequest(
        pageSize: _pageSize,
        cursor: page == 0 ? null : '${page * _pageSize}',
      ),
    );
    if (response == null) {
      throw StateError('getInsightFeedList failed');
    }
    if (response.baseResp.code != 0) {
      throw StateError(response.baseResp.message);
    }
    if (page == 0) {
      _persistFirstPageCache(response);
    }
    return _PageResult(
      items: _mapCardsToItems(response.cards),
      hasMore: response.hasMore,
    );
  }
}

class _PageResult {
  const _PageResult({required this.items, required this.hasMore});
  final List<MPInsightListItem> items;
  final bool hasMore;
}

