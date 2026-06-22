import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/cache/omi_cache_manager.dart';
import 'package:memo_pin/common/mp_memory_notification.dart';
import 'package:memo_pin/http/api/mp_memory.dart';
import 'package:memo_pin/http/schema/mp_data_model.dart';
import 'package:memo_pin/http/schema/mp_memory.dart';

import 'package:memo_pin/common/mp_date_utils.dart';
import 'card/mp_audio_recording_card.dart';
import 'card/mp_memo_group_card.dart';
import 'card/mp_memory_card.dart';


/// Memory 页展示阶段（与 [MPTristatePage] 对应）
enum OmiAllPhase {
  /// 加载中
  loading,

  /// 无数据
  empty,

  /// 无网络（或其它网络类错误）
  noNetwork,

  /// 业务/服务器错误
  error,

  /// 有列表数据
  loaded,
}

/// Memory 页 Cubit 状态
class OmiAllState {
  /// 当前阶段
  final OmiAllPhase phase;

  /// 列表数据（仅 [OmiAllPhase.loaded] 有意义）
  final List<MPMemoryEntry> items;

  /// 错误说明（[OmiAllPhase.error] 时展示）
  final String? errorMessage;

  /// [loadMore] 拉取更多时为 `true`，在列表底部展示加载中（对应 Provider 的 isFetching）
  final bool isLoadingMore;

  /// 是否还有更多（由接口 [hasMore] 决定）
  final bool hasMore;

  const OmiAllState({
    required this.phase,
    this.items = const [],
    this.errorMessage,
    this.isLoadingMore = false,
    this.hasMore = true,
  });
}

/// 游标分页单次请求结果（对齐 MemoryProvider：列表 + hasMore）
typedef _CursorFetchResult = ({List<MPMemoryEntry> items, bool hasMore});

/// Memory 页逻辑：刷新第一页 [load]、上拉更多 [loadMore]，均使用 **cursor** 而非 page
class OmiAllCubit extends Cubit<OmiAllState> {
  OmiAllCubit() : super(const OmiAllState(phase: OmiAllPhase.loading)) {
    _recordCreatedSub = MPMemoryNotification.listenMemoryRecordCreated((_) {
      load();
    });
    _memoryDeletedSub = MPMemoryNotification.listenMemoryDeleted((String id) {
      unawaited(_handleMemoryDeleted(id));
    });
    _memoryTitleUpdatedSub =
        MPMemoryNotification.listenMemoryTitleUpdated((MPMemoryTitleUpdatedPayload p) {
      updateLocalTitle(p.memoryId, p.title);
    });
    _unreadPollTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(_pollUnreadCounts());
    });
  }

  StreamSubscription<MPMemoryRecordCreatedPayload>? _recordCreatedSub;
  StreamSubscription<String>? _memoryDeletedSub;
  StreamSubscription<MPMemoryTitleUpdatedPayload>? _memoryTitleUpdatedSub;

  /// 每分钟拉取未读数并刷新列表（仅 [OmiAllPhase.loaded] 且列表非空时生效）。
  Timer? _unreadPollTimer;

  /// 下一页请求的游标；首屏为空字符串，首屏成功后为当前列表最后一条的 [MPMemoryEntry.id]
  String _cursor = '';

  /// 进行中的首屏刷新（[load] 去重：initData 与 Tab 切回等并发调用共享同一次执行）
  Future<void>? _loadInFlight;

  /// 进行中的加载更多（[loadMore] 去重）
  Future<void>? _loadMoreInFlight;

  /// 按 cursor 去重的进行中的列表网络请求（同一游标并发时复用同一 [Future]）
  final Map<String, Future<_CursorFetchResult>> _fetchMemoryListInFlight =
      <String, Future<_CursorFetchResult>>{};

  /// 每页条数（对接真实接口时传入请求体，如 pageSize: 20）
  static const int pageSize = 20;

  /// 首次进入：等价于 [load]
  Future<void> initData() => load();

  bool _isRenderableEntry(MPMemoryEntry e) {
    switch (e.kind) {
      case MPMemoryEntryKind.conversation:
        return e.variant != null && e.data != null && e.conversationKind != null;
      case MPMemoryEntryKind.memoGroup:
        return e.memoVariant != null && e.memoData != null;
      case MPMemoryEntryKind.audioRecording:
        return e.audioData != null;
    }
  }

  List<MPMemoryEntry> _loadCachedFirstPage() {
    final dynamic cached = OmiCacheManager().getMemoryFirstPage();
    if (cached is! Map) return const <MPMemoryEntry>[];
    final dynamic rawList = cached['memorys'];
    if (rawList is! List) return const <MPMemoryEntry>[];

    final List<MPMemoryStruct> structs = <MPMemoryStruct>[];
    for (final dynamic e in rawList) {
      if (e is Map) {
        try {
          structs.add(MPMemoryStruct.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {
          // ignore malformed entry
        }
      }
    }
    if (structs.isEmpty) return const <MPMemoryEntry>[];
    final List<MPMemoryEntry> entries = structs
        .where(_shouldIncludeMemoryStructInAllList)
        .map(_mpMemoryStructToEntry)
        .toList(growable: false);
    return entries.where(_isRenderableEntry).toList(growable: false);
  }

  /// 刷新第一页：重置 cursor、hasMore，再拉首屏（`getMemoryList`）。
  ///
  /// - **当前无列表数据**：先检测网络，离线则 [OmiAllPhase.noNetwork]；在线则全屏 loading 再请求
  /// - **当前已有列表**（含 [OmiAllPage] 的 [RefreshIndicator] 手动下拉与程序化 [RefreshIndicatorState.show]）：不展示三态图，保持列表；失败则仍显示原数据
  /// - [listenMemoryRecordCreated] 等无列表场景仍直接调用本方法
  ///
  /// 并发调用时复用同一次 [_loadImpl]，避免重复首屏请求与状态互相覆盖。
  Future<void> load() async {
    final Future<void>? inFlight = _loadInFlight;
    if (inFlight != null) {
      return inFlight;
    }
    final Future<void> task = _loadImpl();
    _loadInFlight = task;
    try {
      await task;
    } finally {
      if (identical(_loadInFlight, task)) {
        _loadInFlight = null;
      }
    }
  }

  Future<void> _loadImpl() async {
    final List<MPMemoryEntry> before = List<MPMemoryEntry>.from(state.items);
    bool hasData = before.isNotEmpty;

    // 首屏无数据时，优先用缓存兜底展示（离线也能看到上次列表）。
    if (!hasData) {
      // 确保缓存已从持久化介质恢复到内存，否则冷启动/重进时可能读到空导致离线白屏。
      await OmiCacheManager().initialize();
      final List<MPMemoryEntry> cachedItems = _loadCachedFirstPage();
      if (cachedItems.isNotEmpty) {
        emit(
          OmiAllState(
            phase: OmiAllPhase.loaded,
            items: cachedItems,
            // 首屏缓存只兜底展示，hasMore 仍以真实接口为准；这里默认 true 以允许后续网络刷新/加载更多。
            hasMore: true,
          ),
        );
        hasData = true;
      }
    }

    final bool online = await _hasNetworkConnectivity();
    if (!online) {
      // 无网络：若已展示缓存则保持当前列表；否则进入 noNetwork 三态页。
      if (!hasData) {
        emit(const OmiAllState(phase: OmiAllPhase.noNetwork));
      }
      return;
    }
    if (!hasData) {
      emit(const OmiAllState(phase: OmiAllPhase.loading));
    }

    try {
      _cursor = '';
      final _CursorFetchResult result = await _fetchMemoryList(cursor: _cursor);
      final List<MPMemoryEntry> list = result.items;

      if (list.isEmpty) {
        emit(
          const OmiAllState(
            phase: OmiAllPhase.empty,
            hasMore: false,
          ),
        );
        return;
      }

      _cursor = list.last.id;
      emit(
        OmiAllState(
          phase: OmiAllPhase.loaded,
          items: list,
          hasMore: result.hasMore,
        ),
      );
    } on SocketException catch (_) {
      if (!hasData) {
        emit(const OmiAllState(phase: OmiAllPhase.noNetwork));
      } else {
        emit(
          OmiAllState(
            phase: OmiAllPhase.loaded,
            items: before,
            hasMore: state.hasMore,
          ),
        );
      }
    } on TimeoutException catch (_) {
      if (!hasData) {
        emit(const OmiAllState(phase: OmiAllPhase.noNetwork));
      } else {
        emit(
          OmiAllState(
            phase: OmiAllPhase.loaded,
            items: before,
            hasMore: state.hasMore,
          ),
        );
      }
    } catch (e) {
      if (!hasData) {
        emit(
          OmiAllState(
            phase: OmiAllPhase.error,
            errorMessage: e.toString(),
          ),
        );
      } else {
        emit(
          OmiAllState(
            phase: OmiAllPhase.loaded,
            items: before,
            hasMore: state.hasMore,
          ),
        );
      }
    }
  }

  /// 加载更多：使用当前 [_cursor] 请求（对齐 [MemoryProvider.loadMoreMemories]）
  Future<void> loadMore() async {
    if (state.phase != OmiAllPhase.loaded) return;
    if (state.isLoadingMore) return;
    if (!state.hasMore) return;

    final Future<void>? inFlight = _loadMoreInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final Future<void> task = _loadMoreImpl();
    _loadMoreInFlight = task;
    try {
      await task;
    } finally {
      if (identical(_loadMoreInFlight, task)) {
        _loadMoreInFlight = null;
      }
    }
  }

  Future<void> _loadMoreImpl() async {
    if (state.phase != OmiAllPhase.loaded) return;
    if (state.isLoadingMore) return;
    if (!state.hasMore) return;

    final List<MPMemoryEntry> current = List<MPMemoryEntry>.from(state.items);
    emit(
      OmiAllState(
        phase: OmiAllPhase.loaded,
        items: current,
        isLoadingMore: true,
        hasMore: state.hasMore,
      ),
    );

    try {
      final _CursorFetchResult result =
      await _fetchMemoryList(cursor: _cursor);
      final List<MPMemoryEntry> next = result.items;

      if (next.isEmpty) {
        emit(
          OmiAllState(
            phase: OmiAllPhase.loaded,
            items: current,
            isLoadingMore: false,
            hasMore: false,
          ),
        );
        return;
      }

      _cursor = next.last.id;
      emit(
        OmiAllState(
          phase: OmiAllPhase.loaded,
          items: <MPMemoryEntry>[...current, ...next],
          isLoadingMore: false,
          hasMore: result.hasMore,
        ),
      );
    } on SocketException catch (_) {
      emit(
        OmiAllState(
          phase: OmiAllPhase.loaded,
          items: current,
          isLoadingMore: false,
          hasMore: state.hasMore,
        ),
      );
    } on TimeoutException catch (_) {
      emit(
        OmiAllState(
          phase: OmiAllPhase.loaded,
          items: current,
          isLoadingMore: false,
          hasMore: state.hasMore,
        ),
      );
    } catch (_) {
      emit(
        OmiAllState(
          phase: OmiAllPhase.loaded,
          items: current,
          isLoadingMore: false,
          hasMore: state.hasMore,
        ),
      );
    }
  }

  /// 三态页重试：拉第一页
  Future<void> retry() => load();

  /// 是否有可用网络（Wi‑Fi / 蜂窝等，非 [ConnectivityResult.none]）
  Future<bool> _hasNetworkConnectivity() async {
    try {
      final List<ConnectivityResult> results =
      await Connectivity().checkConnectivity();
      if (results.isEmpty) return false;
      return results.any((ConnectivityResult r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  /// 游标分页：调用 [getMemoryList]，用返回的 `hasMore` 与列表最后一条 [MPMemoryEntry.id] 更新 [_cursor]。
  ///
  /// 相同 [cursor] 的并发请求复用同一进行中的 [Future]，避免重复打接口。
  Future<_CursorFetchResult> _fetchMemoryList({required String cursor}) async {
    final Future<_CursorFetchResult>? inFlight = _fetchMemoryListInFlight[cursor];
    if (inFlight != null) {
      return inFlight;
    }

    final Future<_CursorFetchResult> task = _fetchMemoryListOnce(cursor: cursor);
    _fetchMemoryListInFlight[cursor] = task;
    try {
      return await task;
    } finally {
      _fetchMemoryListInFlight.remove(cursor);
    }
  }

  Future<_CursorFetchResult> _fetchMemoryListOnce({required String cursor}) async {
    final MPGetMemoryListResponse? resp = await getMemoryList(
      MPGetMemoryV2ListRequest(
        pageSize: pageSize,
        cursor: cursor,
      ),
    );
    if (resp == null) {
      throw StateError('getMemoryList failed');
    }
    if (resp.baseResp.code != 0) {
      throw StateError(resp.baseResp.message);
    }
    // 仅缓存首屏（cursor 为空）数据：All 列表的第一页。
    if (cursor.isEmpty) {
      OmiCacheManager().putMemoryFirstPage(<String, Object?>{
        'memorys': resp.memorys.map((MPMemoryStruct e) => e.toJson()).toList(),
        'has_more': resp.hasMore,
      });
    }
    final List<MPMemoryEntry> items = resp.memorys
        .where(_shouldIncludeMemoryStructInAllList)
        .map(_mpMemoryStructToEntry)
        .toList(growable: false);
    return (items: items, hasMore: resp.hasMore);
  }

  @override
  Future<void> close() {
    _unreadPollTimer?.cancel();
    _unreadPollTimer = null;
    _recordCreatedSub?.cancel();
    _memoryDeletedSub?.cancel();
    _memoryDeletedSub = null;
    _memoryTitleUpdatedSub?.cancel();
    _memoryTitleUpdatedSub = null;
    return super.close();
  }

  Future<void> _handleMemoryDeleted(String memoryId) async {
    final String id = memoryId.trim();
    if (id.isEmpty) return;
    final OmiAllState s = state;
    if (s.phase != OmiAllPhase.loaded) {
      return;
    }

    final List<MPMemoryEntry> before = List<MPMemoryEntry>.from(s.items);
    final String cursorBefore = _cursor;
    final bool hasMoreBefore = s.hasMore;
    final bool loadingBefore = s.isLoadingMore;

    // 先本地移除
    final List<MPMemoryEntry> next =
        before.where((MPMemoryEntry e) => e.id != id).toList(growable: false);
    final bool removed = next.length != before.length;

    if (!removed) {
      // 本地未命中：为了与服务端对齐，直接拉下一页补齐（若还有更多且当前未在加载）。
      if (hasMoreBefore && !loadingBefore) {
        await loadMore();
      }
      return;
    }

    if (next.isNotEmpty) {
      _cursor = next.last.id;
      emit(
        OmiAllState(
          phase: OmiAllPhase.loaded,
          items: next,
          isLoadingMore: false,
          hasMore: hasMoreBefore,
        ),
      );
      return;
    }

    // 本地删完后为空：按“下一页数据”补齐（cursor 用删除前的 cursor）。
    if (!hasMoreBefore || loadingBefore) {
      emit(const OmiAllState(phase: OmiAllPhase.empty, items: <MPMemoryEntry>[]));
      return;
    }
    emit(
      const OmiAllState(
        phase: OmiAllPhase.loaded,
        items: <MPMemoryEntry>[],
        isLoadingMore: true,
        hasMore: true,
      ),
    );
    try {
      final _CursorFetchResult result =
          await _fetchMemoryList(cursor: cursorBefore);
      final List<MPMemoryEntry> fetched = result.items;
      if (fetched.isEmpty) {
        emit(const OmiAllState(phase: OmiAllPhase.empty, items: <MPMemoryEntry>[], hasMore: false));
        return;
      }
      _cursor = fetched.last.id;
      emit(
        OmiAllState(
          phase: OmiAllPhase.loaded,
          items: fetched,
          isLoadingMore: false,
          hasMore: result.hasMore,
        ),
      );
    } catch (_) {
      emit(const OmiAllState(phase: OmiAllPhase.empty, items: <MPMemoryEntry>[]));
    }
  }

  void updateLocalTitle(String memoryId, String title) {
    final String id = memoryId.trim();
    final String t = title.trim();
    if (id.isEmpty || t.isEmpty) return;
    final OmiAllState s = state;
    if (s.items.isEmpty) return;

    bool changed = false;
    final List<MPMemoryEntry> next = s.items.map((MPMemoryEntry e) {
      if (e.id != id) return e;
      changed = true;
      switch (e.kind) {
        case MPMemoryEntryKind.conversation:
          final MPMemoryCardData? d = e.data;
          if (d == null) return e;
          return MPMemoryEntry.conversation(
            id: e.id,
            conversationKind: e.conversationKind!,
            variant: e.variant!,
            type: e.type,
            data: MPMemoryCardData(
              title: t,
              timeLabel: d.timeLabel,
              preview: d.preview,
              createAt: d.createAt,
              badgeCount: d.badgeCount,
              statusLabel: d.statusLabel,
              showActivity: d.showActivity,
            ),
          );
        case MPMemoryEntryKind.memoGroup:
          final MPMemoGroupCardData? d = e.memoData;
          if (d == null) return e;
          return MPMemoryEntry.memoGroup(
            id: e.id,
            type: e.type,
            memoVariant: e.memoVariant!,
            memoData: MPMemoGroupCardData(
              title: t,
              items: d.items,
              itemMuted: d.itemMuted,
              subtitle: d.subtitle,
            ),
          );
        case MPMemoryEntryKind.audioRecording:
          // 音频卡片标题是时间/录音信息，不跟随编辑标题更新。
          return e;
      }
    }).toList(growable: false);

    if (!changed) return;
    emit(
      OmiAllState(
        phase: s.phase,
        items: next,
        errorMessage: s.errorMessage,
        isLoadingMore: s.isLoadingMore,
        hasMore: s.hasMore,
      ),
    );
  }

  /// [getMemoryV2UnreadCount]：`member_ids` 使用列表项 [MPMemoryEntry.id]；返回的 `unread_counts` key 与之对齐。
  Future<void> _pollUnreadCounts() async {
    if (isClosed) {
      return;
    }
    if (state.phase != OmiAllPhase.loaded || state.items.isEmpty) {
      return;
    }
    final List<String> memberIds = state.items
        .map((MPMemoryEntry e) => e.id.trim())
        .where((String id) => id.isNotEmpty)
        .toList();
    if (memberIds.isEmpty) {
      return;
    }
    try {
      final MPGetMemoryV2UnreadCountResponse? resp = await getMemoryV2UnreadCount(
        MPGetMemoryV2UnreadCountRequest(memberIds: memberIds),
      );
      if (isClosed || resp == null) {
        return;
      }
      if (resp.baseResp.code != 0) {
        return;
      }
      final Map<String, int> counts = resp.unreadCounts;
      final List<MPMemoryEntry> next = state.items.map((MPMemoryEntry e) {
        if (e.kind != MPMemoryEntryKind.conversation || e.data == null) {
          return e;
        }
        if (!counts.containsKey(e.id)) {
          return e;
        }
        final int unread = counts[e.id]!;
        final bool hasUnread = unread > 0;
        return MPMemoryEntry.conversation(
          id: e.id,
          type: e.type,
          conversationKind: e.conversationKind!,
          variant: hasUnread
              ? MPMemoryCardVariant.newUpdates
              : MPMemoryCardVariant.standard,
          data: MPMemoryCardData(
            title: e.data!.title,
            timeLabel: e.data!.timeLabel,
            preview: e.data!.preview,
            createAt: e.data!.createAt,
            showActivity: e.data!.showActivity,
            badgeCount: hasUnread ? unread : null,
            statusLabel: hasUnread ? 'New updates' : null,
          ),
        );
      }).toList();
      emit(
        OmiAllState(
          phase: OmiAllPhase.loaded,
          items: next,
          hasMore: state.hasMore,
          isLoadingMore: state.isLoadingMore,
        ),
      );
    } catch (_) {
      // 静默失败：不影响列表与下拉刷新主流程
    }
  }
}

/// `MEMO_LIST` 无条目时不展示该行（避免空白分组卡片）。
bool _shouldIncludeMemoryStructInAllList(MPMemoryStruct m) {
  if ((m.type ?? MPMemoryType.onlyRecord) == MPMemoryType.memoList) {
    return (m.memoList ?? []).isNotEmpty;
  }
  return true;
}

/// [MPMemoryStruct.unreadItemCnt] 后端约定主要对 MEMORY_FEED 有意义；为 `null` 或 `<0` 视为 0。
int _unreadItemCount(MPMemoryStruct m) {
  final int? u = m.unreadItemCnt;
  if (u == null || u < 0) {
    return 0;
  }
  return u;
}

/// 服务端 [MPMemoryStruct] → 列表 [MPMemoryEntry]（与 [OmiAllPage] 中按 [MPMemoryEntryKind] 分支的卡片一致）。
MPMemoryEntry _mpMemoryStructToEntry(MPMemoryStruct m) {
  switch (m.type ?? MPMemoryType.onlyRecord) {
    // onlyRecord → audioRecording → [MPAudioRecordingCard]
    case MPMemoryType.onlyRecord:
      final ({String primary, String secondary}) labels =
          MPDateUtils.resolveAudioRecordingLabels(
        title: m.title,
        content: m.content,
        showTime: m.showTime,
        createAt: m.createAt,
      );
      return MPMemoryEntry.audioRecording(
        id: m.id ?? '',
        type: m.type ?? MPMemoryType.onlyRecord,
        audioData: MPAudioRecordingCardData(
          primaryTimeLabel: labels.primary,
          secondaryTimeLabel: labels.secondary,
          sourceLabel: m.source ?? '',
          durationLabel: MPDateUtils.formatMemoryDurationCompact(m.duration),
          showProcessing: (m.status ?? 0) == 1,
        ),
      );
    case MPMemoryType.summary:
      final int unread = _unreadItemCount(m);
      final bool hasUnread = unread > 0;
      return MPMemoryEntry.conversation(
        id: m.id ?? '',
        type: m.type ?? MPMemoryType.summary,
        conversationKind: MPMemoryConversationKind.summary,
        variant: hasUnread
            ? MPMemoryCardVariant.newUpdates
            : MPMemoryCardVariant.standard,
        data: MPMemoryCardData(
          showActivity: false,
          title: m.title ?? '',
          timeLabel: MPDateUtils.formatMemoryShortTimeFromShowTime(
            m.showTime,
            fallbackCreateAt: m.createAt,
          ),
          createAt: m.createAt,
          preview: m.content ?? '',
          badgeCount: hasUnread ? unread : null,
          statusLabel: hasUnread ? 'New updates' : null,
        ),
      );
    case MPMemoryType.memoryFeed:
      final int unread = _unreadItemCount(m);
      final bool hasUnread = unread > 0;
      return MPMemoryEntry.conversation(
        id: m.id ?? '',
        type: m.type ?? MPMemoryType.memoryFeed,
        conversationKind: MPMemoryConversationKind.memoryFeed,
        variant: hasUnread
            ? MPMemoryCardVariant.newUpdates
            : MPMemoryCardVariant.standard,
        data: MPMemoryCardData(
          showActivity: true,
          title: m.title ?? '',
          timeLabel: MPDateUtils.formatMemoryShortTimeFromShowTime(
            m.showTime,
            fallbackCreateAt: m.createAt,
          ),
          createAt: m.createAt,
          preview: m.content ?? '',
          badgeCount: hasUnread ? unread : null,
          statusLabel: hasUnread ? 'New updates' : null,
        ),
      );
    case MPMemoryType.memoList:
      return _mpMemoryStructToMemoGroupEntry(m);
  }
}

/// `MEMO_LIST` → [MPMemoryEntryKind.memoGroup]（Memos 分组卡片）。
MPMemoryEntry _mpMemoryStructToMemoGroupEntry(MPMemoryStruct m) {
  final List<MPMemoStruct> memos = m.memoList ?? [];


  final MPMemoGroupCardVariant variant = memos.length == 1
      ? MPMemoGroupCardVariant.single
      : MPMemoGroupCardVariant.listFull;

  return MPMemoryEntry.memoGroup(
    id: m.id ?? '',
    type: m.type ?? MPMemoryType.memoList,
    memoVariant: variant,
    memoData: MPMemoGroupCardData(
      subtitle: m.subTitle,
      title: m.title ?? '',
      items: memos,
    ),
  );
}
