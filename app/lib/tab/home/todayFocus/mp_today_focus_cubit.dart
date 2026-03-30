import 'package:flutter_bloc/flutter_bloc.dart';

import 'cards/mp_today_focus_card.dart';
import 'cards/mp_today_focus_todo_grouped_list.dart';

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
  });

  final MPTodayFocusPhase phase;
  final String? errorMessage;
  final MPTodayFocusCardData focusCard;
  final List<MPTodayFocusTodoRowData> todayItems;
  final List<MPTodayFocusTodoRowData> upcomingItems;
  final List<MPTodayFocusTodoRowData> futureItems;
  final List<MPTodayFocusTodoRowData> overdueItems;
  final List<MPTodayFocusTodoRowData> completedItems;

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
          const MPTodayFocusCardItem(
            title: 'Follow up with Sarah about design feedback',
            subtext: 'Design feedback pending',
            timeLabel: '14:00',
          ),
          const MPTodayFocusCardItem(
            title: 'Finalize API migration timeline',
            subtext: 'Project deadline soon',
            timeLabel: '16:30',
          ),
        ],
      ),
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
}
