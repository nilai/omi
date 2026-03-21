import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'card/mp_memory_card.dart';

/// Memory 页展示阶段（与 [MPTristatePage] 对应）
enum MPMemoryPhase {
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
class MPMemoryState {
  /// 当前阶段
  final MPMemoryPhase phase;

  /// 列表数据（仅 [MPMemoryPhase.loaded] 有意义）
  final List<MPMemoryEntry> items;

  /// 错误说明（[MPMemoryPhase.error] 时展示）
  final String? errorMessage;

  /// [loadMore] 拉取更多时为 `true`，在列表底部展示加载中
  final bool isLoadingMore;

  /// 是否还有下一页（用于上拉是否继续请求）
  final bool hasMore;

  const MPMemoryState({
    required this.phase,
    this.items = const [],
    this.errorMessage,
    this.isLoadingMore = false,
    this.hasMore = true,
  });
}

/// Memory 页逻辑：第一页刷新 [load]、上拉更多 [loadMore]
class MPMemoryCubit extends Cubit<MPMemoryState> {
  MPMemoryCubit() : super(const MPMemoryState(phase: MPMemoryPhase.loading));

  /// 当前服务端页码（第一页为 1）
  int _page = 1;

  /// 首次进入：等价于 [load]
  Future<void> initData() => load();

  /// 刷新第一页数据（替换列表，不追加）
  ///
  /// - **当前无列表数据**：全屏 [MPTristateType.loading]
  /// - **当前已有列表**（下拉刷新等）：保持 [MPMemoryPhase.loaded]，不闪全屏 loading，仅替换 [items]
  Future<void> load() async {
    final List<MPMemoryEntry> before = List<MPMemoryEntry>.from(state.items);
    final bool hasData = before.isNotEmpty;

    if (!hasData) {
      emit(const MPMemoryState(phase: MPMemoryPhase.loading));
    }

    try {
      _page = 1;
      final List<MPMemoryEntry> list = await _fetchMemoryList(page: 1);
      if (list.isEmpty) {
        emit(
          const MPMemoryState(
            phase: MPMemoryPhase.empty,
            hasMore: false,
          ),
        );
        return;
      }
      emit(
        MPMemoryState(
          phase: MPMemoryPhase.loaded,
          items: list,
          hasMore: true,
        ),
      );
    } on SocketException catch (_) {
      if (!hasData) {
        emit(const MPMemoryState(phase: MPMemoryPhase.noNetwork));
      } else {
        emit(
          MPMemoryState(
            phase: MPMemoryPhase.loaded,
            items: before,
            hasMore: state.hasMore,
          ),
        );
      }
    } on TimeoutException catch (_) {
      if (!hasData) {
        emit(const MPMemoryState(phase: MPMemoryPhase.noNetwork));
      } else {
        emit(
          MPMemoryState(
            phase: MPMemoryPhase.loaded,
            items: before,
            hasMore: state.hasMore,
          ),
        );
      }
    } catch (e) {
      if (!hasData) {
        emit(
          MPMemoryState(
            phase: MPMemoryPhase.error,
            errorMessage: e.toString(),
          ),
        );
      } else {
        emit(
          MPMemoryState(
            phase: MPMemoryPhase.loaded,
            items: before,
            hasMore: state.hasMore,
          ),
        );
      }
    }
  }

  /// 上拉加载下一页，拼接到列表末尾
  Future<void> loadMore() async {
    if (state.phase != MPMemoryPhase.loaded) return;
    if (state.isLoadingMore) return;
    if (!state.hasMore) return;

    final List<MPMemoryEntry> current = List<MPMemoryEntry>.from(state.items);
    emit(
      MPMemoryState(
        phase: MPMemoryPhase.loaded,
        items: current,
        isLoadingMore: true,
        hasMore: state.hasMore,
      ),
    );

    try {
      final int nextPage = _page + 1;
      final List<MPMemoryEntry> next = await _fetchMemoryList(page: nextPage);
      if (next.isEmpty) {
        emit(
          MPMemoryState(
            phase: MPMemoryPhase.loaded,
            items: current,
            isLoadingMore: false,
            hasMore: false,
          ),
        );
        return;
      }
      _page = nextPage;
      emit(
        MPMemoryState(
          phase: MPMemoryPhase.loaded,
          items: <MPMemoryEntry>[...current, ...next],
          isLoadingMore: false,
          hasMore: true,
        ),
      );
    } on SocketException catch (_) {
      emit(
        MPMemoryState(
          phase: MPMemoryPhase.loaded,
          items: current,
          isLoadingMore: false,
          hasMore: state.hasMore,
        ),
      );
    } on TimeoutException catch (_) {
      emit(
        MPMemoryState(
          phase: MPMemoryPhase.loaded,
          items: current,
          isLoadingMore: false,
          hasMore: state.hasMore,
        ),
      );
    } catch (_) {
      emit(
        MPMemoryState(
          phase: MPMemoryPhase.loaded,
          items: current,
          isLoadingMore: false,
          hasMore: state.hasMore,
        ),
      );
    }
  }

  /// 三态页重试：拉第一页
  Future<void> retry() => load();

  /// 模拟分页请求：替换为真实接口时传入 page / pageSize
  Future<List<MPMemoryEntry>> _fetchMemoryList({required int page}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (page == 1) {
      return <MPMemoryEntry>[
        MPMemoryEntry(
          variant: MPMemoryCardVariant.newUpdates,
          data: const MPMemoryCardData(
            title: 'Team standup discussion on API migration',
            timeLabel: 'Today, 10:30 AM',
            preview:
                'Discussed timeline for migrating legacy API to new microservices architecture. Team agreed...',
            badgeCount: 1,
            statusLabel: 'New updates',
          ),
        ),
        MPMemoryEntry(
          variant: MPMemoryCardVariant.standard,
          data: const MPMemoryCardData(
            title: 'Investor meeting - Series A funding discussion',
            timeLabel: 'Yesterday, 4:30 PM',
            preview:
                'Presented growth metrics and Q1 achievements to potential lead investor. They...',
          ),
        ),
        MPMemoryEntry(
          variant: MPMemoryCardVariant.compact,
          data: const MPMemoryCardData(
            title: 'Coffee chat with Jordan about team dynamics',
            timeLabel: 'Yesterday, 2:15 PM',
            preview:
                'Explored ideas for differentiation in competitive market. Jordan suggested...',
          ),
        ),
         MPMemoryEntry(
          variant: MPMemoryCardVariant.standard,
          data: const MPMemoryCardData(
            title: 'Investor meeting - Series A funding discussion',
            timeLabel: 'Yesterday, 4:30 PM',
            preview:
                'Presented growth metrics and Q1 achievements to potential lead investor. They...',
          ),
        ),
        MPMemoryEntry(
          variant: MPMemoryCardVariant.compact,
          data: const MPMemoryCardData(
            title: 'Coffee chat with Jordan about team dynamics',
            timeLabel: 'Yesterday, 2:15 PM',
            preview:
                'Explored ideas for differentiation in competitive market. Jordan suggested...',
          ),
        ),
      ];
    }
    if (page == 2) {
      return <MPMemoryEntry>[
        const MPMemoryEntry(
          variant: MPMemoryCardVariant.standard,
          data: MPMemoryCardData(
            title: '第 2 页 · 追加条目',
            timeLabel: 'Just now',
            preview: '上拉加载更多时拼接在列表末尾的示例数据。',
          ),
        ),
      ];
    }
    return <MPMemoryEntry>[];
  }
}
