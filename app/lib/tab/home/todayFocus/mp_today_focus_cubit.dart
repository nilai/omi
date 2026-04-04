import 'package:flutter_bloc/flutter_bloc.dart';

import 'cards/mp_today_focus_card.dart';
import 'cards/mp_today_focus_todo_grouped_list.dart';

/// AI 推荐加入 Focus 的一条建议（标题 + 展示用时间）
class MPTodayFocusAISuggestionItem {
  const MPTodayFocusAISuggestionItem({
    required this.title,
    required this.scheduledTimeLabel,
  });

  final String title;
  final String scheduledTimeLabel;
}

/// Today Focus 页阶段（与 [MPTristatePage] 对应，对齐 Memory All 等页）
enum MPTodayFocusPhase {
  loading,
  empty,
  error,
  loaded,
}

/// Today Focus 页状态
class MPTodayFocusState {
  const MPTodayFocusState({
    required this.phase,
    this.errorMessage,
    required this.focusCard,
    this.todayItems = const <MPTodayFocusTodoRowData>[],
    this.upcomingItems = const <MPTodayFocusTodoRowData>[],
    this.futureItems = const <MPTodayFocusTodoRowData>[],
    this.overdueItems = const <MPTodayFocusTodoRowData>[],
    this.completedItems = const <MPTodayFocusTodoRowData>[],
    this.aiFocusSuggestions = const <MPTodayFocusAISuggestionItem>[],
    this.aiFocusSuggestionIndex = 0,
  });

  final MPTodayFocusPhase phase;
  final String? errorMessage;
  final MPTodayFocusCardData focusCard;
  final List<MPTodayFocusTodoRowData> todayItems;
  final List<MPTodayFocusTodoRowData> upcomingItems;
  final List<MPTodayFocusTodoRowData> futureItems;
  final List<MPTodayFocusTodoRowData> overdueItems;
  final List<MPTodayFocusTodoRowData> completedItems;

  /// 当 [focusCard] 少于 3 条时，供 AI 推荐卡片轮播使用。
  final List<MPTodayFocusAISuggestionItem> aiFocusSuggestions;

  /// 当前展示的推荐在 [aiFocusSuggestions] 中的下标。
  final int aiFocusSuggestionIndex;

  /// 当前应展示的 AI 推荐；[focusCard] ≥3 或队列为空时为 `null`。
  MPTodayFocusAISuggestionItem? get currentAiFocusSuggestion {
    if (focusCard.items.length >= 3) {
      return null;
    }
    if (aiFocusSuggestions.isEmpty) {
      return null;
    }
    if (aiFocusSuggestionIndex < 0 ||
        aiFocusSuggestionIndex >= aiFocusSuggestions.length) {
      return null;
    }
    return aiFocusSuggestions[aiFocusSuggestionIndex];
  }

  bool get _hasAnyTodo =>
      todayItems.isNotEmpty ||
      upcomingItems.isNotEmpty ||
      futureItems.isNotEmpty ||
      overdueItems.isNotEmpty ||
      completedItems.isNotEmpty;

  bool get hasRenderableContent =>
      focusCard.items.isNotEmpty || _hasAnyTodo;

  MPTodayFocusState copyWith({
    MPTodayFocusPhase? phase,
    String? errorMessage,
    bool clearErrorMessage = false,
    MPTodayFocusCardData? focusCard,
    List<MPTodayFocusTodoRowData>? todayItems,
    List<MPTodayFocusTodoRowData>? upcomingItems,
    List<MPTodayFocusTodoRowData>? futureItems,
    List<MPTodayFocusTodoRowData>? overdueItems,
    List<MPTodayFocusTodoRowData>? completedItems,
    List<MPTodayFocusAISuggestionItem>? aiFocusSuggestions,
    int? aiFocusSuggestionIndex,
  }) {
    return MPTodayFocusState(
      phase: phase ?? this.phase,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      focusCard: focusCard ?? this.focusCard,
      todayItems: todayItems ?? this.todayItems,
      upcomingItems: upcomingItems ?? this.upcomingItems,
      futureItems: futureItems ?? this.futureItems,
      overdueItems: overdueItems ?? this.overdueItems,
      completedItems: completedItems ?? this.completedItems,
      aiFocusSuggestions: aiFocusSuggestions ?? this.aiFocusSuggestions,
      aiFocusSuggestionIndex:
          aiFocusSuggestionIndex ?? this.aiFocusSuggestionIndex,
    );
  }
}

/// Today Focus：拉取数据 + 与页面三态 / 下拉刷新联动（占位请求可替换真实接口）
class MPTodayFocusCubit extends Cubit<MPTodayFocusState> {
  MPTodayFocusCubit() : super(_loadingState());

  /// 勿用外层 const，避免与 [initData] 再次 emit 时与 bloc 去重逻辑撞同一实例。
  static MPTodayFocusState _loadingState() {
    return MPTodayFocusState(
      phase: MPTodayFocusPhase.loading,
      focusCard: const MPTodayFocusCardData(items: <MPTodayFocusCardItem>[]),
    );
  }

  /// 首次进入 / [retry] / 下拉刷新
  Future<void> initData() async {
    final bool showFullScreenLoading =
        state.phase != MPTodayFocusPhase.loaded;
    if (showFullScreenLoading) {
      emit(_loadingState());
    }
    try {
      // TODO: 替换为真实接口
      await Future<void>.delayed(const Duration(milliseconds: 280));
      final MPTodayFocusState loaded = _mockLoadedState();
      if (!loaded.hasRenderableContent) {
        emit(
          loaded.copyWith(
            phase: MPTodayFocusPhase.empty,
            clearErrorMessage: true,
          ),
        );
        return;
      }
      emit(
        loaded.copyWith(
          phase: MPTodayFocusPhase.loaded,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        _loadingState().copyWith(
          phase: MPTodayFocusPhase.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// 与 OmiAll / MemorySearch 等页的 [retry] 一致
  Future<void> retry() => initData();

  static const List<MPTodayFocusAISuggestionItem> _kMockAiSuggestions =
      <MPTodayFocusAISuggestionItem>[
    MPTodayFocusAISuggestionItem(
      title: 'Revise marketing deck with ADHD-focused messaging',
      scheduledTimeLabel: '14:00',
    ),
    MPTodayFocusAISuggestionItem(
      title: 'Block 25 minutes for inbox zero before standup',
      scheduledTimeLabel: '08:30',
    ),
    MPTodayFocusAISuggestionItem(
      title: 'Draft one-paragraph summary for stakeholders',
      scheduledTimeLabel: '17:00',
    ),
  ];

  static MPTodayFocusState _mockLoadedState() {
    return MPTodayFocusState(
      phase: MPTodayFocusPhase.loaded,
      focusCard: MPTodayFocusCardData(
        items: <MPTodayFocusCardItem>[
          const MPTodayFocusCardItem(
            title: 'Review migration milestones with infrastructure team',
            subtext: 'Meeting scheduled today',
            timeLabel: '09:00',
          ),
        ],
      ),
      aiFocusSuggestions: _kMockAiSuggestions,
      aiFocusSuggestionIndex: 0,
      todayItems: <MPTodayFocusTodoRowData>[
        const MPTodayFocusTodoRowData(
          title: 'Update API documentation for v2 endpoints',
          timeLabel: '09:00',
        ),
        const MPTodayFocusTodoRowData(
          title:
              'Review the new product roadmap and prepare feedback for tomorrow\'s meeting',
          timeLabel: '14:00',
        ),
      ],
      upcomingItems: <MPTodayFocusTodoRowData>[
        const MPTodayFocusTodoRowData(
          title: 'Research new collaboration tools',
          timeLabel: 'Mon 11:30',
        ),
        const MPTodayFocusTodoRowData(
          title: 'Schedule team building event',
          timeLabel: 'Thu 16:00',
        ),
      ],
      futureItems: <MPTodayFocusTodoRowData>[
        const MPTodayFocusTodoRowData(
          title: 'Quarterly planning draft',
          timeLabel: 'Apr 2',
        ),
      ],
      overdueItems: <MPTodayFocusTodoRowData>[
        const MPTodayFocusTodoRowData(
          title: 'Send invoice',
          timeLabel: 'Mar 3 14:00',
        ),
        const MPTodayFocusTodoRowData(
          title: 'Submit expense report',
          timeLabel: 'Mar 5 10:00',
          highlighted: true,
        ),
      ],
      completedItems: <MPTodayFocusTodoRowData>[
        const MPTodayFocusTodoRowData(
          title: 'Update API documentation for v2 endpoints',
          timeLabel: '09:00',
          isChecked: true,
        ),
      ],
    );
  }

  bool get _isInteractive => state.phase == MPTodayFocusPhase.loaded;

  void addTodoFromInput(String text) {
    if (!_isInteractive) return;
    final String t = text.trim();
    if (t.isEmpty) return;
    final List<MPTodayFocusTodoRowData> next = List<MPTodayFocusTodoRowData>.of(
      state.todayItems,
    );
    next.insert(
      0,
      MPTodayFocusTodoRowData(title: t, timeLabel: ''),
    );
    emit(state.copyWith(todayItems: next));
  }

  void setTodoChecked(
    MPTodayFocusTodoSection section,
    int index,
    bool isChecked,
  ) {
    if (!_isInteractive) return;
    List<MPTodayFocusTodoRowData> listFor(MPTodayFocusTodoSection s) {
      switch (s) {
        case MPTodayFocusTodoSection.today:
          return state.todayItems;
        case MPTodayFocusTodoSection.upcomingWithinSevenDays:
          return state.upcomingItems;
        case MPTodayFocusTodoSection.futureBeyondSevenDays:
          return state.futureItems;
        case MPTodayFocusTodoSection.overdue:
          return state.overdueItems;
        case MPTodayFocusTodoSection.completed:
          return state.completedItems;
      }
    }

    final List<MPTodayFocusTodoRowData> src = listFor(section);
    if (index < 0 || index >= src.length) return;
    final MPTodayFocusTodoRowData row = src[index];
    final MPTodayFocusTodoRowData updated = MPTodayFocusTodoRowData(
      title: row.title,
      timeLabel: row.timeLabel,
      isChecked: isChecked,
      highlighted: row.highlighted,
    );
    final List<MPTodayFocusTodoRowData> replaced = List<
        MPTodayFocusTodoRowData>.generate(
      src.length,
      (int i) => i == index ? updated : src[i],
    );

    switch (section) {
      case MPTodayFocusTodoSection.today:
        emit(state.copyWith(todayItems: replaced));
      case MPTodayFocusTodoSection.upcomingWithinSevenDays:
        emit(state.copyWith(upcomingItems: replaced));
      case MPTodayFocusTodoSection.futureBeyondSevenDays:
        emit(state.copyWith(futureItems: replaced));
      case MPTodayFocusTodoSection.overdue:
        emit(state.copyWith(overdueItems: replaced));
      case MPTodayFocusTodoSection.completed:
        emit(state.copyWith(completedItems: replaced));
    }
  }

  void clearOverdue() {
    if (!_isInteractive) return;
    emit(state.copyWith(overdueItems: const <MPTodayFocusTodoRowData>[]));
  }

  /// 将当前 AI 推荐加入 Today's Focus；**TODO: 替换为真实加 Focus 接口**。
  /// 成功后 Focus 列表增加一条，并切换到队列中下一条标题（仍不足 3 条时卡片继续展示）。
  Future<bool> addCurrentAiSuggestionToFocus() async {
    if (!_isInteractive) {
      return false;
    }
    final MPTodayFocusAISuggestionItem? cur = state.currentAiFocusSuggestion;
    if (cur == null) {
      return false;
    }
    try {
      await Future<void>.delayed(const Duration(milliseconds: 420));

      final List<MPTodayFocusCardItem> nextItems =
          List<MPTodayFocusCardItem>.of(state.focusCard.items)
            ..add(
              MPTodayFocusCardItem(
                title: cur.title,
                subtext: 'Suggested by AI',
                timeLabel: cur.scheduledTimeLabel,
              ),
            );

      final List<MPTodayFocusAISuggestionItem> queue = state.aiFocusSuggestions;
      final int nextIndex = queue.isEmpty
          ? 0
          : (state.aiFocusSuggestionIndex + 1) % queue.length;

      emit(
        state.copyWith(
          focusCard: state.focusCard.copyWith(items: nextItems),
          aiFocusSuggestionIndex: nextIndex,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
