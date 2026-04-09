import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:memo_pin/cache/omi_cache_manager.dart';
import 'package:memo_pin/common/mp_memory_notification.dart';
import 'package:memo_pin/http/api/mp_memory.dart';
import 'package:memo_pin/http/schema/mp_data_model.dart';
import 'package:memo_pin/http/schema/mp_memory.dart';

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
  }

  StreamSubscription<MPMemoryRecordCreatedPayload>? _recordCreatedSub;

  /// 下一页请求的游标；首屏为空字符串，首屏成功后为当前列表最后一条的 [MPMemoryEntry.id]
  String _cursor = '';

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
    final List<MPMemoryEntry> entries =
        structs.map(_mpMemoryStructToEntry).toList(growable: false);
    return entries.where(_isRenderableEntry).toList(growable: false);
  }

  /// 刷新第一页：重置 cursor、hasMore，再拉首屏（对齐 [MemoryProvider.loadMemories]）
  ///
  /// - **当前无列表数据**：先检测网络，离线则 [OmiAllPhase.noNetwork]；在线则全屏 loading 再请求
  /// - **当前已有列表**（下拉刷新）：不展示三态图，保持列表展示；请求失败则仍显示原数据
  Future<void> load() async {
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
  Future<_CursorFetchResult> _fetchMemoryList({required String cursor}) async {
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
    final List<MPMemoryEntry> items =
        resp.memorys.map(_mpMemoryStructToEntry).toList(growable: false);
    return (items: items, hasMore: resp.hasMore);
  }

  @override
  Future<void> close() {
    _recordCreatedSub?.cancel();
    return super.close();
  }
}

/// 服务端 [MPMemoryStruct] → 列表 [MPMemoryEntry]（与 [OmiAllPage] 中按 [MPMemoryEntryKind] 分支的卡片一致）。
MPMemoryEntry _mpMemoryStructToEntry(MPMemoryStruct m) {
  print('----------------memory struct to entry: ${m.toJson()}');
  switch (m.type ?? MPMemoryType.onlyRecord) {
    // onlyRecord → audioRecording → [MPAudioRecordingCard]
    case MPMemoryType.onlyRecord:
      return MPMemoryEntry.audioRecording(
        id: m.id ?? '',
        type: m.type ?? MPMemoryType.onlyRecord,
        audioData: MPAudioRecordingCardData(
          primaryTimeLabel: m.title ?? '',
          secondaryTimeLabel: m.content ?? '',
          sourceLabel: m.source ?? '',
          durationLabel: _formatDurationSeconds(m.duration ?? 0),
        ),
      );
    case MPMemoryType.summary:
      return MPMemoryEntry.conversation(
        id: m.id ??  '',
        type: m.type ?? MPMemoryType.summary,
        conversationKind: MPMemoryConversationKind.summary,
        variant: MPMemoryCardVariant.newUpdates,
        data: MPMemoryCardData(
          showActivity: false,
          title: m.title ?? '',
          timeLabel: _shortTimeLabel(m.createAt ?? 0),
          createAt: m.createAt ?? 0,
          preview: m.content ?? '',
          badgeCount: 0,
          statusLabel: null,
        ),
      );
    case MPMemoryType.memoryFeed:
      return MPMemoryEntry.conversation(
        id: m.id ?? '',
        type: m.type ?? MPMemoryType.memoryFeed,
        conversationKind: MPMemoryConversationKind.memoryFeed,
        variant: MPMemoryCardVariant.newUpdates,
        data: MPMemoryCardData(
          showActivity: true,
          title: m.title ?? '',
          timeLabel: _shortTimeLabel(m.createAt ?? 0),
          createAt: m.createAt ?? 0,
          preview: m.content ?? '',
          badgeCount: 0,
          statusLabel: null,
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

DateTime _memoryDateTimeFromServer(int createAt) {
  if (createAt > 10000000000) {
    return DateTime.fromMillisecondsSinceEpoch(createAt);
  }
  return DateTime.fromMillisecondsSinceEpoch(createAt * 1000);
}

String _shortTimeLabel(int createAt) {
  return DateFormat('MMM d, y, h:mm a').format(_memoryDateTimeFromServer(createAt));
}

String _formatDurationSeconds(int seconds) {
  if (seconds <= 0) {
    return '0s';
  }
  final int m = seconds ~/ 60;
  final int s = seconds % 60;
  if (m > 0) {
    return '${m}m${s}s';
  }
  return '${s}s';
}
