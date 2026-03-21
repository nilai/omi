import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  /// 模拟游标分页。接入真实接口时改为：
  /// `getXxx(MPRequest(cursor: cursor, pageSize: pageSize))`，并用返回的 `hasMore` 与列表最后 id 更新 [_cursor]。
  Future<_CursorFetchResult> _fetchMemoryList({required String cursor}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (cursor.isEmpty) {
      final List<MPMemoryEntry> items = <MPMemoryEntry>[
        const MPMemoryEntry.conversation(
          id: 'mem_001',
          variant: MPMemoryCardVariant.newUpdates,
          data: MPMemoryCardData(
            title: 'Team standup discussion on API migration',
            timeLabel: 'Today, 10:30 AM',
            preview:
            'Discussed timeline for migrating legacy API to new microservices architecture. Team agreed...',
            badgeCount: 1,
            statusLabel: 'New updates',
          ),
        ),
        const MPMemoryEntry.memoGroup(
          id: 'mem_mo_single',
          memoVariant: MPMemoGroupCardVariant.listFull,
          memoData: MPMemoGroupCardData(
            categoryLabel: 'Memos',
            dateLabel: 'Mar 3',
            items: <String>[
              'Follow up with design on the onboarding flow wireframes.',
            ],
          ),
        ),
        const MPMemoryEntry.memoGroup(
          id: 'mem_mo_full',
          memoVariant: MPMemoGroupCardVariant.listFull,
          memoData: MPMemoGroupCardData(
            categoryLabel: 'Memos',
            dateLabel: 'Mar 2',
            items: <String>[
              'Book venue for Q2 offsite by Friday.',
              'Share draft OKRs with the leadership team.',
              'Review analytics dashboard with data team.',
            ],
          ),
        ),
        const MPMemoryEntry.memoGroup(
          id: 'mem_mo_collapse',
          memoVariant: MPMemoGroupCardVariant.listFull,
          memoData: MPMemoGroupCardData(
            categoryLabel: 'Memos',
            dateLabel: 'Mar 1',
            items: <String>[
              'Sync with legal on updated privacy policy.',
              'Prepare slide deck for customer advisory board.',
              'Schedule 1:1s with new hires next week.',
              'Draft blog post for product launch.',
              'Confirm budget allocation with finance.',
            ],
            itemMuted: <bool>[false, true, false, false, true],
          ),
        ),
        const MPMemoryEntry.conversation(
          id: 'mem_002',
          variant: MPMemoryCardVariant.standard,
          data: MPMemoryCardData(
            title: 'Investor meeting - Series A funding discussion',
            timeLabel: 'Yesterday, 4:30 PM',
            preview:
            'Presented growth metrics and Q1 achievements to potential lead investor. They...',
          ),
        ),
        const MPMemoryEntry.conversation(
          id: 'mem_003',
          variant: MPMemoryCardVariant.compact,
          data: MPMemoryCardData(
            title: 'Coffee chat with Jordan about team dynamics',
            timeLabel: 'Yesterday, 2:15 PM',
            preview:
            'Explored ideas for differentiation in competitive market. Jordan suggested...',
          ),
        ),
      ];
      return (items: items, hasMore: true);
    }

    if (cursor == 'mem_003') {
      return (
      items: <MPMemoryEntry>[
        const MPMemoryEntry.conversation(
          id: 'mem_004',
          variant: MPMemoryCardVariant.standard,
          data: MPMemoryCardData(
            title: '游标下一页 · 追加条目',
            timeLabel: 'Just now',
            preview: '使用 cursor=mem_003 拉取的下一批数据（模拟已无更多）。',
          ),
        ),
      ],
      hasMore: false,
      );
    }

    return (items: <MPMemoryEntry>[], hasMore: false);
  }
}
