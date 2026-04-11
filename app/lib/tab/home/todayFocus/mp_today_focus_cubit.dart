import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:memo_pin/common/mp_home_notification.dart';
import 'package:memo_pin/common/mp_todo_manager.dart';
import 'package:memo_pin/common/mp_todo_voice_input.dart';
import 'package:memo_pin/http/api/mp_memo.dart';
import 'package:memo_pin/http/api/mp_todo.dart';
import 'package:memo_pin/http/schema/mp_data_model.dart';
import 'package:memo_pin/http/schema/mp_memo.dart';
import 'package:memo_pin/http/schema/mp_todo.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';

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
      final GetTodoGroupedListResponse? raw = await getTodoList(
        GetTodoGroupedListRequest(pageSize: 200, pageno: 1),
      );
      if (raw == null) {
        throw StateError('getTodoList failed');
      }
      if (raw.baseResp.code != 0) {
        throw StateError(raw.baseResp.message);
      }
      final MPTodayFocusState loaded = _stateFromGroupedListResponse(raw);
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

  /// 在 [loaded] / [empty] 时重新拉取分组待办（供弹层关闭后同步等场景；失败 Toast）。
  Future<bool> refreshGroupedTodoLists() => _refreshTodoListsFromServer();

  /// 再次拉取分组待办并替换当前状态（不改变全屏 loading / error 页）。
  /// 用于添加/完成/删除/更新等成功后与服务端对齐；失败仅 Toast，返回 `false`。
  Future<bool> _refreshTodoListsFromServer() async {
    if (state.phase != MPTodayFocusPhase.loaded &&
        state.phase != MPTodayFocusPhase.empty) {
      return false;
    }
    final List<MPTodayFocusAISuggestionItem> keepAi = state.aiFocusSuggestions;
    final int keepAiIdx = state.aiFocusSuggestionIndex;
    try {
      final GetTodoGroupedListResponse? raw = await getTodoList(
        GetTodoGroupedListRequest(pageSize: 200, pageno: 1),
      );
      if (raw == null) {
        MPToastUtils.showMessage('刷新待办失败，请稍后重试');
        return false;
      }
      if (raw.baseResp.code != 0) {
        MPToastUtils.showMessage(
          raw.baseResp.message.isEmpty ? '刷新待办失败' : raw.baseResp.message,
        );
        return false;
      }
      final MPTodayFocusState loaded = _stateFromGroupedListResponse(raw)
          .copyWith(
            aiFocusSuggestions: keepAi,
            aiFocusSuggestionIndex: keepAiIdx,
          );
      if (!loaded.hasRenderableContent) {
        emit(
          loaded.copyWith(
            phase: MPTodayFocusPhase.empty,
            clearErrorMessage: true,
          ),
        );
      } else {
        emit(
          loaded.copyWith(
            phase: MPTodayFocusPhase.loaded,
            clearErrorMessage: true,
          ),
        );
      }
      MPHomeNotification.notifyHomeListRefresh();
      return true;
    } catch (_) {
      MPToastUtils.showMessage('刷新待办失败，请稍后重试');
      return false;
    }
  }

  /// `focus_items` → 顶部 Today's Focus；`sections` → 下方分组（按 [TodoListSectionType] 填入对应列表）。
  static MPTodayFocusState _stateFromGroupedListResponse(
    GetTodoGroupedListResponse resp,
  ) {
    final List<MPTodoStruct> focus = resp.focusItems ?? <MPTodoStruct>[];
    final List<MPTodayFocusCardItem> focusCards = focus
        .map(_mapTodoToFocusCardItem)
        .toList(growable: false);

    final List<MPTodayFocusTodoRowData> todayItems = <MPTodayFocusTodoRowData>[];
    final List<MPTodayFocusTodoRowData> upcomingItems =
        <MPTodayFocusTodoRowData>[];
    final List<MPTodayFocusTodoRowData> futureItems =
        <MPTodayFocusTodoRowData>[];
    final List<MPTodayFocusTodoRowData> overdueItems =
        <MPTodayFocusTodoRowData>[];
    final List<MPTodayFocusTodoRowData> completedItems =
        <MPTodayFocusTodoRowData>[];

    for (final TodoListSectionStruct sec in resp.sections ??
        const <TodoListSectionStruct>[]) {
      final MPTodayFocusTodoSection? uiSection =
          _mapTodoListSectionTypeToUi(sec.sectionType);
      if (uiSection == null) {
        continue;
      }
      final List<MPTodayFocusTodoRowData> bucket = switch (uiSection) {
        MPTodayFocusTodoSection.today => todayItems,
        MPTodayFocusTodoSection.upcomingWithinSevenDays => upcomingItems,
        MPTodayFocusTodoSection.futureBeyondSevenDays => futureItems,
        MPTodayFocusTodoSection.overdue => overdueItems,
        MPTodayFocusTodoSection.completed => completedItems,
      };
      for (final MPTodoStruct t in sec.todos) {
        bucket.add(_mapTodoToRow(t, uiSection));
      }
    }

    return MPTodayFocusState(
      phase: MPTodayFocusPhase.loaded,
      focusCard: MPTodayFocusCardData(items: focusCards),
      aiFocusSuggestions: const <MPTodayFocusAISuggestionItem>[],
      aiFocusSuggestionIndex: 0,
      todayItems: todayItems,
      upcomingItems: upcomingItems,
      futureItems: futureItems,
      overdueItems: overdueItems,
      completedItems: completedItems,
    );
  }

  static MPTodayFocusTodoSection? _mapTodoListSectionTypeToUi(
    TodoListSectionType type,
  ) {
    switch (type) {
      case TodoListSectionType.today:
        return MPTodayFocusTodoSection.today;
      case TodoListSectionType.upcomingSevenDays:
        return MPTodayFocusTodoSection.upcomingWithinSevenDays;
      case TodoListSectionType.future:
        return MPTodayFocusTodoSection.futureBeyondSevenDays;
      case TodoListSectionType.overdue:
        return MPTodayFocusTodoSection.overdue;
    }
  }

  static MPTodayFocusCardItem _mapTodoToFocusCardItem(MPTodoStruct t) {
    final String title = (t.title ?? '').trim();
    return MPTodayFocusCardItem(
      title: title.isEmpty ? '—' : title,
      subtext: 'scheduled for ${_formatDeadlineLabel(t.deadline)}',
      timeLabel: _formatDeadlineLabel(t.deadline),
      todoId: (t.id ?? '').trim(),
    );
  }

  static MPTodayFocusTodoRowData _mapTodoToRow(
    MPTodoStruct t,
    MPTodayFocusTodoSection section,
  ) {
    final int st = t.status ?? 1;
    final String title = (t.title ?? '').trim();
    return MPTodayFocusTodoRowData(
      title: title.isEmpty ? '—' : title,
      timeLabel: _formatDeadlineLabel(t.deadline),
      todoId: (t.id ?? '').trim(),
      status: st,
      priorityApi: (t.priority ?? 'normal').toLowerCase(),
      deadlineUnixSec: t.deadline,
      sourceSection: section,
      isChecked: st == 2,
      highlighted: st == 3,
    );
  }

  /// [MPTodoStruct.deadline] 为 Unix 秒。
  static String _formatDeadlineLabel(int? deadlineSec) {
    if (deadlineSec == null || deadlineSec <= 0) {
      return '';
    }
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
      deadlineSec * 1000,
    );
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) {
      return DateFormat('HH:mm').format(dt);
    }
    final int daysFromToday = day.difference(today).inDays;
    if (daysFromToday > 0 && daysFromToday <= 7) {
      return DateFormat('EEE HH:mm').format(dt);
    }
    return DateFormat('MMM d').format(dt);
  }

  bool get _isInteractive => state.phase == MPTodayFocusPhase.loaded;

  void addTodoFromInput(String text) {
    if (!_isInteractive) return;
    final String t = text.trim();
    if (t.isEmpty) return;
    _insertTodayTodo(t);
  }

  /// 文本走 [analyzeMemoText]，语音（已上传 [MPTodoVoiceInputResult.recordUrl]）走 [analyzeMemoRecord]。
  /// 返回 `true` 表示分析成功且 [getTodoList] 刷新成功；`false` 表示失败或刷新失败（可保留输入框内容）。
  Future<bool> addTodoFromAnalyzedInput(MPTodoVoiceInputResult r) async {
    if (!_isInteractive) return false;
    final int createAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (!r.fromVoice) {
      final String t = r.text.trim();
      if (t.isEmpty) return false;
      final MPAnalyzeMemoTextResponse? response = await analyzeMemoText(
        MPAnalyzeMemoTextRequest(content: t, createAt: createAt),
      );
      if (response == null || response.baseResp.code != 0) {
        MPToastUtils.showMessage(
          response?.baseResp.message ?? '分析失败，请稍后重试',
        );
        return false;
      }
      return _refreshTodoListsFromServer();
    }

    final String? url = r.recordUrl?.trim();
    if (url == null || url.isEmpty) {
      MPToastUtils.showMessage('录音无效');
      return false;
    }
    final MPAnalyzeMemoRecordResponse? response = await analyzeMemoRecord(
      MPAnalyzeMemoRecordRequest(recordUrl: url, createAt: createAt),
    );
    if (response == null || response.baseResp.code != 0) {
      MPToastUtils.showMessage(
        response?.baseResp.message ?? '分析失败，请稍后重试',
      );
      return false;
    }
    final String title = response.originalText.trim();
    if (title.isEmpty) {
      MPToastUtils.showMessage('未识别到有效内容');
      return false;
    }
    return _refreshTodoListsFromServer();
  }

  void _insertTodayTodo(String title) {
    final List<MPTodayFocusTodoRowData> next = List<MPTodayFocusTodoRowData>.of(
      state.todayItems,
    );
    next.insert(
      0,
      MPTodayFocusTodoRowData(title: title, timeLabel: '', todoId: ''),
    );
    emit(state.copyWith(todayItems: next));
  }

  List<MPTodayFocusTodoRowData> _itemsForSection(
    MPTodayFocusState s,
    MPTodayFocusTodoSection section,
  ) {
    switch (section) {
      case MPTodayFocusTodoSection.today:
        return s.todayItems;
      case MPTodayFocusTodoSection.upcomingWithinSevenDays:
        return s.upcomingItems;
      case MPTodayFocusTodoSection.futureBeyondSevenDays:
        return s.futureItems;
      case MPTodayFocusTodoSection.overdue:
        return s.overdueItems;
      case MPTodayFocusTodoSection.completed:
        return s.completedItems;
    }
  }

  void setTodoChecked(
    MPTodayFocusTodoSection section,
    int index,
    bool isChecked,
  ) {
    if (!_isInteractive) return;
    if (section == MPTodayFocusTodoSection.completed) {
      return;
    }
    if (!isChecked) {
      return;
    }
    _completeAndMoveToCompleted(section, index);
  }

  Future<void> _completeAndMoveToCompleted(
    MPTodayFocusTodoSection section,
    int index,
  ) async {
    final List<MPTodayFocusTodoRowData> src = _itemsForSection(state, section);
    if (index < 0 || index >= src.length) return;
    final String todoId = src[index].todoId.trim();
    if (todoId.isEmpty) {
      MPToastUtils.showMessage('任务ID不能为空');
      return;
    }
    final bool ok = await MPTodoManager().completeTodo(todoId);
    if (!ok || !_isInteractive) {
      return;
    }
    await _refreshTodoListsFromServer();
  }

  Future<bool> restoreCompletedAt(int index) async {
    if (!_isInteractive) {
      return false;
    }
    if (index < 0 || index >= state.completedItems.length) {
      return false;
    }
    final MPTodayFocusTodoRowData row = state.completedItems[index];
    final String todoId = row.todoId.trim();
    if (todoId.isEmpty) {
      MPToastUtils.showMessage('任务ID不能为空');
      return false;
    }
    final bool ok = await MPTodoManager().updateTodoWithRequest(
      todoId: todoId,
      title: row.title,
      priority: row.priorityApi.trim().isEmpty ? 'normal' : row.priorityApi,
      deadline: row.deadlineUnixSec != null ? '${row.deadlineUnixSec}' : '',
      isCompleted: false,
    );
    if (!ok) {
      return false;
    }
    return _refreshTodoListsFromServer();
  }

  Future<bool> deleteCompletedAt(int index) async {
    if (!_isInteractive) {
      return false;
    }
    if (index < 0 || index >= state.completedItems.length) {
      return false;
    }
    final String todoId = state.completedItems[index].todoId.trim();
    if (todoId.isEmpty) {
      final List<MPTodayFocusTodoRowData> next =
          List<MPTodayFocusTodoRowData>.of(state.completedItems)..removeAt(index);
      emit(state.copyWith(completedItems: next));
      return true;
    }
    final bool ok = await MPTodoManager().deleteTodo(todoId);
    if (!ok) {
      return false;
    }
    return _refreshTodoListsFromServer();
  }

  void clearOverdue() {
    if (!_isInteractive) return;
    emit(state.copyWith(overdueItems: const <MPTodayFocusTodoRowData>[]));
  }

  /// 从 Today's Focus 移除一条：先调删除接口，成功后再从列表移除。
  Future<bool> removeFocusItemAt(int index) async {
    if (!_isInteractive) {
      return false;
    }
    final List<MPTodayFocusCardItem> items = state.focusCard.items;
    if (index < 0 || index >= items.length) {
      return false;
    }
    final String todoId = items[index].todoId.trim();
    if (todoId.isEmpty) {
      MPToastUtils.showMessage('任务ID不能为空');
      return false;
    }
    final bool ok = await MPTodoManager().deleteTodo(todoId);
    if (!ok || !_isInteractive) {
      return false;
    }
    return _refreshTodoListsFromServer();
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
                todoId: '',
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
