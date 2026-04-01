import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:omi/http/api/mp_memory.dart';
import 'package:omi/http/schema/mp_data_model.dart';
import 'package:omi/http/schema/mp_memory.dart';

import 'card/mp_audio_recording_card.dart';
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
  OmiAllCubit() : super(const OmiAllState(phase: OmiAllPhase.loading));

  /// 下一页请求的游标；首屏为空字符串，首屏成功后为当前列表最后一条的 [MPMemoryEntry.id]
  String _cursor = '';

  /// 每页条数（对接真实接口时传入请求体，如 pageSize: 20）
  static const int pageSize = 20;

  /// 首次进入：等价于 [load]
  Future<void> initData() => load();

  /// 刷新第一页：重置 cursor、hasMore，再拉首屏（对齐 [MemoryProvider.loadMemories]）
  ///
  /// - **当前无列表数据**：先检测网络，离线则 [OmiAllPhase.noNetwork]；在线则全屏 loading 再请求
  /// - **当前已有列表**（下拉刷新）：不展示三态图，保持列表展示；请求失败则仍显示原数据
  Future<void> load() async {
    final List<MPMemoryEntry> before = List<MPMemoryEntry>.from(state.items);
    final bool hasData = before.isNotEmpty;

    if (!hasData) {
      final bool online = await _hasNetworkConnectivity();
      if (!online) {
        emit(const OmiAllState(phase: OmiAllPhase.noNetwork));
        return;
      }
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
    final List<MPMemoryEntry> items =
        resp.memorys.map(_mpMemoryStructToEntry).toList(growable: false);
    return (items: items, hasMore: resp.hasMore);
  }
}

/// 服务端 [MPMemoryStruct] → 列表 [MPMemoryEntry]（会话卡片 / 纯录音卡片）。
MPMemoryEntry _mpMemoryStructToEntry(MPMemoryStruct m) {
  switch (m.type) {
    case MPMemoryType.onlyRecord:
      final DateTime dt = _memoryDateTimeFromServer(m.createAt);
      return MPMemoryEntry.audioRecording(
        id: m.id,
        audioData: MPAudioRecordingCardData(
          primaryTimeLabel: DateFormat('MMM d, y, h:mm a').format(dt),
          secondaryTimeLabel: DateFormat("MMMM d, y 'at' h:mm a").format(dt),
          sourceLabel: m.onlyRecordContent?.source?.trim().isNotEmpty == true
              ? m.onlyRecordContent!.source!.trim()
              : 'Recording',
          durationLabel: _formatDurationSeconds(m.duration ?? 0),
        ),
      );
    case MPMemoryType.summary:
      final MPSummaryMemoryStruct? sc = m.summaryContent;
      final bool hasTodos = sc != null && sc.todos.isNotEmpty;
      final MPMemoryCardVariant variant = hasTodos
          ? MPMemoryCardVariant.newUpdates
          : MPMemoryCardVariant.standard;
      final String preview =
          (sc?.summary ?? m.content).trim().isNotEmpty ? (sc?.summary ?? m.content).trim() : ' ';
      return MPMemoryEntry.conversation(
        id: m.id,
        variant: variant,
        data: MPMemoryCardData(
          title: m.title.trim().isNotEmpty ? m.title : 'Memory',
          timeLabel:_shortTimeLabel(m.createAt),
          preview: preview,
          badgeCount: variant == MPMemoryCardVariant.newUpdates
              ? sc!.todos.length
              : null,
          statusLabel:
              variant == MPMemoryCardVariant.newUpdates ? 'New updates' : null,
        ),
      );
    case MPMemoryType.memoryFeed:
      final String preview = _previewMemoryFeed(m);
      return MPMemoryEntry.conversation(
        id: m.id,
        variant: MPMemoryCardVariant.standard,
        data: MPMemoryCardData(
          title: m.title.trim().isNotEmpty ? m.title : 'Insight',
          timeLabel: _timeLabelForMemory(m),
          preview: preview,
        ),
      );
    case MPMemoryType.memoList:
      final String preview = _previewMemoList(m);
      return MPMemoryEntry.conversation(
        id: m.id,
        variant: MPMemoryCardVariant.standard,
        data: MPMemoryCardData(
          title: m.title.trim().isNotEmpty ? m.title : 'Expert',
          timeLabel: _timeLabelForMemory(m),
          preview: preview,
        ),
      );
  }
}

String _timeLabelForMemory(MPMemoryStruct m) {
  final String? st = m.subTitle?.trim();
  if (st != null && st.isNotEmpty) {
    return st;
  }
  return _shortTimeLabel(m.createAt);
}

/// [MPMemoryFeedStruct] 无顶层 `content`：优先 `summary_memory.summary`，否则取首个 feed 的 `content`，再退回 [MPMemoryStruct.content]。
String _previewMemoryFeed(MPMemoryStruct m) {
  final MPMemoryFeedStruct? mf = m.memoryFeed;
  if (mf != null) {
    final MPSummaryMemoryStruct? smStruct = mf.summaryMemory;
    if (smStruct != null) {
      final String t = smStruct.summary.trim();
      if (t.isNotEmpty) {
        return t;
      }
    }
    for (final MPFeedCardStruct f in mf.feeds) {
      final String? c = f.content?.trim();
      if (c != null && c.isNotEmpty) {
        return c;
      }
    }
  }
  final String fallback = m.content.trim();
  return fallback.isNotEmpty ? fallback : ' ';
}

/// `MEMO_LIST` 时顶层 `content` 可能为空，从 [MPMemoryStruct.memoList] 拼预览。
String _previewMemoList(MPMemoryStruct m) {
  final List<MPMemoStruct>? memos = m.memoList;
  if (memos != null && memos.isNotEmpty) {
    final List<String> parts = <String>[];
    for (final MPMemoStruct e in memos) {
      final String t = e.title.trim();
      final String c = e.content.trim();
      final String one = t.isNotEmpty ? t : c;
      if (one.isNotEmpty) {
        parts.add(one);
      }
      if (parts.length >= 3) {
        break;
      }
    }
    if (parts.isNotEmpty) {
      return parts.join(' · ');
    }
  }
  final String fallback = m.content.trim();
  return fallback.isNotEmpty ? fallback : ' ';
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
