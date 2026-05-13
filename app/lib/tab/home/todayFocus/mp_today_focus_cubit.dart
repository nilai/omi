import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../cache/omi_cache_manager.dart';
import 'package:memo_pin/cache/mp_hive_util.dart';
import 'package:memo_pin/common/mp_home_notification.dart';
import 'package:memo_pin/common/mp_todo_manager.dart';
import 'package:memo_pin/http/api/mp_memory.dart';
import 'package:memo_pin/http/api/mp_todo.dart';
import 'package:memo_pin/http/schema/mp_data_model.dart';
import 'package:memo_pin/http/schema/mp_memory.dart';
import 'package:memo_pin/http/schema/mp_todo.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';

import 'cards/mp_today_focus_card.dart';
import 'cards/mp_today_focus_todo_grouped_list.dart';

/// Hive：`memory_id` → [MPGetMemoryV2SimpleInfoResponse.toJson]（与首页 / Insight 共用 key）。
String _todayFocusMemorySimpleInfoHiveKey(int memoryId) => 'mp_insight_memory_simple_info_v1_$memoryId';

/// AI 推荐加入 Focus 的一条建议（标题 + 展示用时间 + 对应 todo id，用于 [replaceTodayFocus]）。
class MPTodayFocusAISuggestionItem {
  const MPTodayFocusAISuggestionItem({
    required this.title,
    required this.scheduledTimeLabel,
    required this.todoId,
  });

  final String title;
  final String scheduledTimeLabel;

  /// 与 [MPTodoStruct.id] 一致，用于 [MPReplaceTodayFocusRequest.todoId]。
  final String todoId;
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
    this.isGroupedTodosRefreshing = false,
    this.isBlockingGlobalLoading = false,
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

  /// 正在重新拉取分组待办（如编辑 Todo 关闭后同步）；首屏加载看 [phase]==loading。
  final bool isGroupedTodosRefreshing;

  /// 全页遮罩 loading；为 true 时页面叠半透明层并阻断手势（与 [isGroupedTodosRefreshing] 细条互斥）。
  final bool isBlockingGlobalLoading;

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
    bool? isGroupedTodosRefreshing,
    bool? isBlockingGlobalLoading,
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
      isGroupedTodosRefreshing:
          isGroupedTodosRefreshing ?? this.isGroupedTodosRefreshing,
      isBlockingGlobalLoading:
          isBlockingGlobalLoading ?? this.isBlockingGlobalLoading,
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
      aiFocusSuggestions: [],
      aiFocusSuggestionIndex: 0,
    );
  }

  static const String _kTodayFocusCacheGrouped = 'grouped';
  static const String _kTodayFocusCacheCandidates = 'candidates';

  void _putTodayFocusCache(
    GetTodoGroupedListResponse raw,
    GetTodoListResponse? candidates,
  ) {
    OmiCacheManager().putTodayFocusBundle(<String, dynamic>{
      _kTodayFocusCacheGrouped: raw.toJson(),
      if (candidates != null) _kTodayFocusCacheCandidates: candidates.toJson(),
    });
  }

  MPTodayFocusState? _tryStateFromTodayFocusCache() {
    final dynamic decoded = OmiCacheManager().getTodayFocusBundle();
    if (decoded is! Map) {
      return null;
    }
    final dynamic groupedRaw = decoded[_kTodayFocusCacheGrouped];
    if (groupedRaw is! Map) {
      return null;
    }
    try {
      final GetTodoGroupedListResponse raw = GetTodoGroupedListResponse.fromJson(
        Map<String, dynamic>.from(groupedRaw),
      );
      if (raw.baseResp.code != 0) {
        return null;
      }
      GetTodoListResponse? candidates;
      final dynamic c = decoded[_kTodayFocusCacheCandidates];
      if (c is Map) {
        try {
          candidates = GetTodoListResponse.fromJson(Map<String, dynamic>.from(c));
        } catch (_) {
          candidates = null;
        }
      }
      return _buildTodayFocusUiState(raw, candidates);
    } catch (_) {
      return null;
    }
  }

  MPTodayFocusState _buildTodayFocusUiState(
    GetTodoGroupedListResponse raw,
    GetTodoListResponse? candidates,
  ) {
    final MPTodayFocusState merged = _stateFromGroupedListResponse(raw).copyWith(
      aiFocusSuggestions: _aiSuggestionsFromCandidates(candidates),
      aiFocusSuggestionIndex: 0,
      isGroupedTodosRefreshing: false,
    );
    if (!merged.hasRenderableContent) {
      return merged.copyWith(
        phase: MPTodayFocusPhase.empty,
        clearErrorMessage: true,
      );
    }
    return merged.copyWith(
      phase: MPTodayFocusPhase.loaded,
      clearErrorMessage: true,
    );
  }

  /// 首次进入 / [retry] / 下拉刷新
  Future<void> initData() async {
    /// 仅首屏（loading）与错误重试时全屏占位；已 loaded / empty 时下拉刷新不闪全屏。
    final bool useFullScreenLoading =
        state.phase == MPTodayFocusPhase.loading ||
        state.phase == MPTodayFocusPhase.error;

    bool bootstrappedFromCache = false;
    if (useFullScreenLoading) {
      final MPTodayFocusState? cached = _tryStateFromTodayFocusCache();
      if (cached != null) {
        emit(cached);
        bootstrappedFromCache = true;
      } else {
        emit(_loadingState());
      }
    }
    try {
      final List<Object?> bundled = await Future.wait<Object?>(<Future<Object?>>[
        getTodoList(GetTodoGroupedListRequest(pageSize: 200, pageno: 1)),
        getTodayFocusCandidates(const MPGetTodayFocusCandidatesRequest()),
      ]);
      final GetTodoGroupedListResponse? raw =
          bundled[0] as GetTodoGroupedListResponse?;
      final GetTodoListResponse? candidates = bundled[1] as GetTodoListResponse?;
      if (raw == null) {
        throw StateError('getTodoList failed');
      }
      if (raw.baseResp.code != 0) {
        throw StateError(raw.baseResp.message);
      }
      _putTodayFocusCache(raw, candidates);
      final MPTodayFocusState built = _buildTodayFocusUiState(raw, candidates);
      if (!isClosed) {
        emit(
          built.copyWith(isBlockingGlobalLoading: state.isBlockingGlobalLoading),
        );
      }
    } catch (e) {
      if (useFullScreenLoading && !bootstrappedFromCache) {
        emit(
          _loadingState().copyWith(
            phase: MPTodayFocusPhase.error,
            errorMessage: e.toString(),
          ),
        );
      } else if (!useFullScreenLoading) {
        MPToastUtils.showMessage('Couldn\'t refresh. Please try again later.');
      }
    }
  }

  /// 与 OmiAll / MemorySearch 等页的 [retry] 一致
  Future<void> retry() => initData();

  /// 拉取 Memory 简要信息（仅网络）。
  Future<MPGetMemoryV2SimpleInfoResponse?> fetchMemoryV2SimpleInfo(String memoryId) async {
    return getMemoryV2SimpleInfo(MPGetMemoryV2SimpleInfoRequest(memoryId: memoryId));
  }

  /// 获取 Memory 简要信息：网络成功则写入 Hive 并返回；失败则尝试 Hive 缓存。
  Future<MPGetMemoryV2SimpleInfoResponse?> loadMemorySimpleInfoNetworkOrHive(int? memoryId) async {
    if (memoryId == null) {
      return null;
    }
    final String idStr = '$memoryId';
    try {
      final MPGetMemoryV2SimpleInfoResponse? net = await fetchMemoryV2SimpleInfo(idStr);
      if (net != null && net.baseResp?.code == 0) {
        await MPHiveUtil.instance.putMap(key: _todayFocusMemorySimpleInfoHiveKey(memoryId), value: net.toJson());
        return net;
      }
    } catch (e, stackTrace) {
      debugPrint('MPTodayFocusCubit: loadMemorySimpleInfoNetworkOrHive network failed — $e\n$stackTrace');
    }
    try {
      final Map<String, dynamic>? cached =
          await MPHiveUtil.instance.getMap(_todayFocusMemorySimpleInfoHiveKey(memoryId));
      if (cached == null || cached.isEmpty) {
        return null;
      }
      final MPGetMemoryV2SimpleInfoResponse restored = MPGetMemoryV2SimpleInfoResponse.fromJson(cached);
      if (restored.baseResp?.code == 0) {
        return restored;
      }
    } catch (e, stackTrace) {
      debugPrint('MPTodayFocusCubit: loadMemorySimpleInfoNetworkOrHive hive read failed — $e\n$stackTrace');
    }
    return null;
  }

  /// 重新拉取分组待办（显式「刷新」：展示页面顶部 [LinearProgressIndicator]）。
  Future<bool> refreshGroupedTodoLists() => _refreshTodoListsFromServer();

  /// 创建/编辑等变更后静默对齐列表，并走全页 [isBlockingGlobalLoading]（供页面在提交成功后调用）。
  Future<bool> refreshListsAfterMutation() {
    return _runWithBlockingGlobalLoading(() => _silentResyncTodoListsFromServer());
  }

  /// 拉取分组列表 + candidates，写缓存并 [emit]；**不**修改 [isGroupedTodosRefreshing]。
  Future<bool> _fetchTodoListsBundleAndEmit() async {
    try {
      final List<Object?> bundled = await Future.wait<Object?>(<Future<Object?>>[
        getTodoList(GetTodoGroupedListRequest(pageSize: 200, pageno: 1)),
        getTodayFocusCandidates(const MPGetTodayFocusCandidatesRequest()),
      ]);
      final GetTodoGroupedListResponse? raw =
          bundled[0] as GetTodoGroupedListResponse?;
      final GetTodoListResponse? candidates = bundled[1] as GetTodoListResponse?;
      if (raw == null) {
        MPToastUtils.showMessage('Failed to refresh to-dos. Please try again later.');
        return false;
      }
      if (raw.baseResp.code != 0) {
        MPToastUtils.showMessage(
          raw.baseResp.message.isEmpty
              ? 'Failed to refresh to-dos.'
              : raw.baseResp.message,
        );
        return false;
      }
      _putTodayFocusCache(raw, candidates);
      final MPTodayFocusState built = _buildTodayFocusUiState(raw, candidates);
      if (!isClosed) {
        emit(
          built.copyWith(isBlockingGlobalLoading: state.isBlockingGlobalLoading),
        );
      }
      MPHomeNotification.notifyHomeListRefresh();
      return true;
    } catch (_) {
      MPToastUtils.showMessage('Failed to refresh to-dos. Please try again later.');
      return false;
    }
  }

  /// 再次拉取分组待办并替换当前状态（不改变全屏 loading / error 页）；**会**打开顶部细进度条直至请求结束。
  Future<bool> _refreshTodoListsFromServer() async {
    if (isClosed) {
      return false;
    }
    emit(state.copyWith(isGroupedTodosRefreshing: true));
    try {
      if (isClosed) {
        return false;
      }
      return await _fetchTodoListsBundleAndEmit();
    } finally {
      if (!isClosed && state.isGroupedTodosRefreshing) {
        emit(state.copyWith(isGroupedTodosRefreshing: false));
      }
    }
  }

  /// 与 [_refreshTodoListsFromServer] 相同数据请求，但不展示顶部进度条（如 [removeFocusItemAt] 乐观删卡后对齐）。
  Future<bool> _silentResyncTodoListsFromServer() async {
    if (isClosed) {
      return false;
    }
    return _fetchTodoListsBundleAndEmit();
  }

  static List<MPTodayFocusAISuggestionItem> _aiSuggestionsFromCandidates(
    GetTodoListResponse? resp,
  ) {
    if (resp == null || resp.baseResp.code != 0) {
      return const <MPTodayFocusAISuggestionItem>[];
    }
    final List<MPTodoStruct> items = resp.todos ?? <MPTodoStruct>[];
    return items
        .map((MPTodoStruct t) {
          final String title = (t.title ?? '').trim();
          final String id = (t.id ?? '').trim();
          return MPTodayFocusAISuggestionItem(
            title: title.isEmpty ? '—' : title,
            scheduledTimeLabel: _formatDeadlineLabel(t.deadline),
            todoId: id,
          );
        })
        .toList(growable: false);
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
      case TodoListSectionType.completed:
        return MPTodayFocusTodoSection.completed;
      case TodoListSectionType.unmapped:
        return null;
    }
  }

  static MPTodayFocusCardItem _mapTodoToFocusCardItem(MPTodoStruct t) {
    final String title = (t.title ?? '').trim();
    return MPTodayFocusCardItem(
      title: title.isEmpty ? '—' : title,
      subtext: 'scheduled for ${_formatDeadlineLabel(t.deadline)}',
      timeLabel: _formatDeadlineLabel(t.deadline),
      todoId: (t.id ?? '').trim(),
      memoryId: t.memoryId,
      slot: t.slot,
      insightId: t.insightId
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
      memoryId: t.memoryId,
      status: st,
      priorityApi: (t.priority ?? 'normal').toLowerCase(),
      deadlineUnixSec: t.deadline,
      sourceSection: section,
      isChecked: st == 2,
      highlighted: st == 3,
      slot: t.slot,
      insightId: t.insightId
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

  /// 页面在 loading/empty/error 时也常驻展示「ALL TO DOS」输入框，
  /// 因此提交/刷新等交互不应仅限于 [loaded]。
  bool get _isInteractive => true;

  /// 全页 loading 期间执行 [action]，结束后关闭 [MPTodayFocusState.isBlockingGlobalLoading]。
  Future<T> _runWithBlockingGlobalLoading<T>(Future<T> Function() action) async {
    if (!isClosed) {
      emit(state.copyWith(isBlockingGlobalLoading: true));
    }
    try {
      return await action();
    } finally {
      if (!isClosed) {
        emit(state.copyWith(isBlockingGlobalLoading: false));
      }
    }
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
      if (!isChecked) {
        unawaited(restoreCompletedAt(index));
      }
      return;
    }
    if (!isChecked) {
      return;
    }
    unawaited(_completeAndMoveToCompleted(section, index));
  }

  Future<void> _completeAndMoveToCompleted(
    MPTodayFocusTodoSection section,
    int index,
  ) async {
    final List<MPTodayFocusTodoRowData> src = _itemsForSection(state, section);
    if (index < 0 || index >= src.length) return;
    final String todoId = src[index].todoId.trim();
    if (todoId.isEmpty) {
      MPToastUtils.showMessage('Task ID cannot be empty.');
      return;
    }
    await _runWithBlockingGlobalLoading(() async {
      final bool ok = await MPTodoManager().completeTodo(todoId);
      if (!ok || !_isInteractive || isClosed) {
        return;
      }
      await _silentResyncTodoListsFromServer();
    });
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
      MPToastUtils.showMessage('Task ID cannot be empty.');
      return false;
    }
    return _runWithBlockingGlobalLoading(() async {
      final bool ok = await MPTodoManager().updateTodoWithRequest(
        todoId: todoId,
        title: row.title,
        priority: row.priorityApi.trim().isEmpty ? 'normal' : row.priorityApi,
        deadlineUnixSec: row.deadlineUnixSec,
        isCompleted: false,
      );
      if (!ok || isClosed) {
        return false;
      }
      return _silentResyncTodoListsFromServer();
    });
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
    return _runWithBlockingGlobalLoading(() async {
      final bool ok = await MPTodoManager().deleteTodo(todoId);
      if (!ok) {
        return false;
      }
      return _silentResyncTodoListsFromServer();
    });
  }

  void clearOverdue() {
    if (!_isInteractive) return;
    emit(state.copyWith(overdueItems: const <MPTodayFocusTodoRowData>[]));
  }

  /// Today's Focus 满槽时：用 [todo] 替换对应位（槽位取自 [MPTodayFocusTodoRowData.slot]，与接口 [MPTodoStruct.slot] 一致）。
  void replaceFocusItemWithTodo({
    required MPTodayFocusTodoRowData todo,
  }) {
    if (!_isInteractive) return;
    final int? slot = todo.slot;
    if (slot == null) {
      MPToastUtils.showMessage('Missing focus slot for this task.');
      return;
    }
    final List<MPTodayFocusCardItem> cur = state.focusCard.items;
    if (slot < 0 || slot >= cur.length) {
      return;
    }
    final String todoId = todo.todoId.trim();
    if (todoId.isEmpty) {
      MPToastUtils.showMessage('Task ID cannot be empty.');
      return;
    }
    final String title = todo.title.trim().isEmpty ? '—' : todo.title.trim();
    final String timeLabel = todo.timeLabel.trim();
    final String subtext =
        timeLabel.isEmpty ? 'scheduled for Today' : 'scheduled for $timeLabel';

    final List<MPTodayFocusCardItem> next = List<MPTodayFocusCardItem>.of(cur);
    next[slot] = MPTodayFocusCardItem(
      title: title,
      subtext: subtext,
      timeLabel: timeLabel,
      todoId: todoId,
      memoryId: todo.memoryId,
      slot: slot,
    );
    emit(state.copyWith(focusCard: state.focusCard.copyWith(items: next)));
  }

  /// 调用 [replaceTodayFocus]，将 [todoId] 写入 Today's Focus 的 [slot]；成功后刷新分组列表与 candidates。
  Future<bool> replaceTodayFocusSlot({int? slot, required String todoId}) async {
    if (!_isInteractive) {
      return false;
    }
    final String tid = todoId.trim();
    if (tid.isEmpty) {
      MPToastUtils.showMessage('Task ID cannot be empty.');
      return false;
    }
    return _runWithBlockingGlobalLoading(() async {
      try {
        final MPReplaceTodayFocusResponse? resp = await replaceTodayFocus(
          MPReplaceTodayFocusRequest(slot: slot, todoId: tid),
        );
        if (resp == null) {
          MPToastUtils.showMessage('Couldn\'t update Today\'s Focus. Please try again later.');
          return false;
        }
        if (resp.baseResp.code != 0) {
          MPToastUtils.showMessage(
            resp.baseResp.message.isEmpty
                ? 'Couldn\'t update Today\'s Focus.'
                : resp.baseResp.message,
          );
          return false;
        }
        return _silentResyncTodoListsFromServer();
      } catch (_) {
        MPToastUtils.showMessage('Couldn\'t update Today\'s Focus. Please try again later.');
        return false;
      }
    });
  }

  /// 右滑「Add to Today's Focus」：未满两槽时调用 [addTodayFocusSlot]；已满时由页面弹层选择槽位后调用 [replaceTodayFocusSlot]。
  Future<bool> addTodoToFocus(MPTodayFocusTodoSection section, int index) async {
    if (!_isInteractive) {
      return false;
    }
    if (section != MPTodayFocusTodoSection.today) {
      return false;
    }
    final List<MPTodayFocusTodoRowData> src = state.todayItems;
    if (index < 0 || index >= src.length) {
      return false;
    }
    final String todoId = src[index].todoId.trim();
    if (todoId.isEmpty) {
      MPToastUtils.showMessage('Task ID cannot be empty.');
      return false;
    }
    final int focusCount = state.focusCard.items.length;
    if (focusCount >= 2) {
      return false;
    }
    return addTodayFocusSlot(todoId: todoId);
  }

  /// 调用 [addTodayFocus] 将 [todoId] 写入 Today's Focus 下一空槽（[slot] 为 `null` 时用 [MPTodayFocusCardData.items.length]，须 &lt; 2）。
  Future<bool> addTodayFocusSlot({required String todoId}) async {
    if (!_isInteractive) {
      return false;
    }
    final String tid = todoId.trim();
    if (tid.isEmpty) {
      MPToastUtils.showMessage('Task ID cannot be empty.');
      return false;
    }

    return _runWithBlockingGlobalLoading(() async {
      try {
        final AddTodayFocusResponse? resp = await addTodayFocus(
          AddTodayFocusRequest(todoId: tid),
        );
        if (resp == null) {
          MPToastUtils.showMessage('Couldn\'t update Today\'s Focus. Please try again later.');
          return false;
        }
        if (resp.baseResp.code != 0) {
          MPToastUtils.showMessage(
            resp.baseResp.message.isEmpty
                ? 'Couldn\'t update Today\'s Focus.'
                : resp.baseResp.message,
          );
          return false;
        }
        return _silentResyncTodoListsFromServer();
      } catch (_) {
        MPToastUtils.showMessage('Couldn\'t update Today\'s Focus. Please try again later.');
        return false;
      }
    });
  }

  /// 从 Today's Focus 移除一条：调用 [removeTodayFocus] 按槽位移除，成功后更新本地卡片并静默拉列表对齐。
  Future<bool> removeFocusItemAt(int index) async {
    if (!_isInteractive) {
      return false;
    }
    final List<MPTodayFocusCardItem> items = state.focusCard.items;
    if (index < 0 || index >= items.length) {
      return false;
    }
    final MPTodayFocusCardItem item = items[index];
    final int focusSlot = item.slot ?? index;
    return _runWithBlockingGlobalLoading(() async {
      final MPRemoveTodayFocusResponse? resp = await removeTodayFocus(
        MPRemoveTodayFocusRequest(slot: focusSlot),
      );
      if (!_isInteractive || isClosed) {
        return false;
      }
      if (resp == null) {
        MPToastUtils.showMessage('Couldn\'t remove from Today\'s Focus. Please try again later.');
        return false;
      }
      if (resp.baseResp.code != 0) {
        final String msg = resp.baseResp.message.trim();
        MPToastUtils.showMessage(
          msg.isEmpty ? 'Couldn\'t remove from Today\'s Focus.' : msg,
        );
        return false;
      }
      final List<MPTodayFocusCardItem> next =
          List<MPTodayFocusCardItem>.of(state.focusCard.items)..removeAt(index);
      if (!isClosed) {
        emit(state.copyWith(focusCard: state.focusCard.copyWith(items: next)));
      }
      if (isClosed) {
        return false;
      }
      return _silentResyncTodoListsFromServer();
    });
  }

  /// 将当前 AI 推荐加入 Today's Focus：未满两槽时 [addTodayFocusSlot]；已满时 [replaceTodayFocusSlot]。
  ///
  /// [replaceSlot]：Focus 已满（两槽）时由页面弹层传入要替换的槽位下标；未满时传 `null` 表示追加到下一空槽。
  Future<bool> addCurrentAiSuggestionToFocus({int? replaceSlot}) async {
    if (!_isInteractive) {
      return false;
    }
    final MPTodayFocusAISuggestionItem? cur = state.currentAiFocusSuggestion;
    if (cur == null) {
      return false;
    }
    final String todoId = cur.todoId.trim();
    if (todoId.isEmpty) {
      return false;
    }
    return addTodayFocusSlot(todoId: todoId);
  }
}
