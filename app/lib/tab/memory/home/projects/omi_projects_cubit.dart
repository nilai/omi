import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'card/mp_project_card.dart';

/// Projects 页展示阶段（与 [MPTristatePage] 对应）
enum OmiProjectsPhase {
  /// 加载中
  loading,

  /// 无数据
  empty,

  /// 无网络
  noNetwork,

  /// 业务/服务器错误
  error,

  /// 有列表数据
  loaded,
}

/// 列表行：游标分页用 [id]，展示用 [data]
class OmiProjectEntry {
  const OmiProjectEntry({
    required this.id,
    required this.data,
  });

  final String id;
  final MPProjectCardData data;
}

/// Projects 页 Cubit 状态
class OmiProjectsState {
  final OmiProjectsPhase phase;

  final List<OmiProjectEntry> items;

  final String? errorMessage;

  final bool isLoadingMore;

  final bool hasMore;

  const OmiProjectsState({
    required this.phase,
    this.items = const [],
    this.errorMessage,
    this.isLoadingMore = false,
    this.hasMore = true,
  });
}

typedef _CursorFetchResult = ({List<OmiProjectEntry> items, bool hasMore});

/// Projects：首屏 [load]、下拉刷新 [load]、上拉更多 [loadMore]（游标）
class OmiProjectsCubit extends Cubit<OmiProjectsState> {
  OmiProjectsCubit()
      : super(const OmiProjectsState(phase: OmiProjectsPhase.loading));

  String _cursor = '';

  static const int pageSize = 20;

  Future<void> initData() => load();

  /// 刷新第一页
  Future<void> load() async {
    final List<OmiProjectEntry> before = List<OmiProjectEntry>.from(state.items);
    final bool hasData = before.isNotEmpty;

    if (!hasData) {
      final bool online = await _hasNetworkConnectivity();
      if (!online) {
        emit(const OmiProjectsState(phase: OmiProjectsPhase.noNetwork));
        return;
      }
      emit(const OmiProjectsState(phase: OmiProjectsPhase.loading));
    }

    try {
      _cursor = '';
      final _CursorFetchResult result =
          await _fetchProjectList(cursor: _cursor);
      final List<OmiProjectEntry> list = result.items;

      if (list.isEmpty) {
        emit(
          const OmiProjectsState(
            phase: OmiProjectsPhase.empty,
            hasMore: false,
          ),
        );
        return;
      }

      _cursor = list.last.id;
      emit(
        OmiProjectsState(
          phase: OmiProjectsPhase.loaded,
          items: list,
          hasMore: result.hasMore,
        ),
      );
    } on SocketException catch (_) {
      if (!hasData) {
        emit(const OmiProjectsState(phase: OmiProjectsPhase.noNetwork));
      } else {
        emit(
          OmiProjectsState(
            phase: OmiProjectsPhase.loaded,
            items: before,
            hasMore: state.hasMore,
          ),
        );
      }
    } on TimeoutException catch (_) {
      if (!hasData) {
        emit(const OmiProjectsState(phase: OmiProjectsPhase.noNetwork));
      } else {
        emit(
          OmiProjectsState(
            phase: OmiProjectsPhase.loaded,
            items: before,
            hasMore: state.hasMore,
          ),
        );
      }
    } catch (e) {
      if (!hasData) {
        emit(
          OmiProjectsState(
            phase: OmiProjectsPhase.error,
            errorMessage: e.toString(),
          ),
        );
      } else {
        emit(
          OmiProjectsState(
            phase: OmiProjectsPhase.loaded,
            items: before,
            hasMore: state.hasMore,
          ),
        );
      }
    }
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (state.phase != OmiProjectsPhase.loaded) return;
    if (state.isLoadingMore) return;
    if (!state.hasMore) return;

    final List<OmiProjectEntry> current =
        List<OmiProjectEntry>.from(state.items);
    emit(
      OmiProjectsState(
        phase: OmiProjectsPhase.loaded,
        items: current,
        isLoadingMore: true,
        hasMore: state.hasMore,
      ),
    );

    try {
      final _CursorFetchResult result =
          await _fetchProjectList(cursor: _cursor);
      final List<OmiProjectEntry> next = result.items;

      if (next.isEmpty) {
        emit(
          OmiProjectsState(
            phase: OmiProjectsPhase.loaded,
            items: current,
            isLoadingMore: false,
            hasMore: false,
          ),
        );
        return;
      }

      _cursor = next.last.id;
      emit(
        OmiProjectsState(
          phase: OmiProjectsPhase.loaded,
          items: <OmiProjectEntry>[...current, ...next],
          isLoadingMore: false,
          hasMore: result.hasMore,
        ),
      );
    } on SocketException catch (_) {
      emit(
        OmiProjectsState(
          phase: OmiProjectsPhase.loaded,
          items: current,
          isLoadingMore: false,
          hasMore: state.hasMore,
        ),
      );
    } on TimeoutException catch (_) {
      emit(
        OmiProjectsState(
          phase: OmiProjectsPhase.loaded,
          items: current,
          isLoadingMore: false,
          hasMore: state.hasMore,
        ),
      );
    } catch (_) {
      emit(
        OmiProjectsState(
          phase: OmiProjectsPhase.loaded,
          items: current,
          isLoadingMore: false,
          hasMore: state.hasMore,
        ),
      );
    }
  }

  Future<void> retry() => load();

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

  /// 模拟游标分页；接入真实接口时用 cursor + pageSize 请求
  Future<_CursorFetchResult> _fetchProjectList({
    required String cursor,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (cursor.isEmpty) {
      final List<OmiProjectEntry> items = <OmiProjectEntry>[
        const OmiProjectEntry(
          id: 'proj_001',
          data: MPProjectCardData(
            title: 'API Migration',
            updatedPhrase: 'today',
            memoryCount: 3,
            lastActivityDetail: 'Timeline discussion',
          ),
        ),
        const OmiProjectEntry(
          id: 'proj_002',
          data: MPProjectCardData(
            title: 'Q1 Planning',
            updatedPhrase: 'yesterday',
            memoryCount: 12,
            lastActivityDetail: 'Budget review notes',
          ),
        ),
      ];
      return (items: items, hasMore: true);
    }

    if (cursor == 'proj_002') {
      return (
        items: <OmiProjectEntry>[
          const OmiProjectEntry(
            id: 'proj_003',
            data: MPProjectCardData(
              title: '游标下一页 · 追加项目',
              updatedPhrase: 'today',
              memoryCount: 1,
              lastActivityDetail: '使用 cursor=proj_002 拉取',
            ),
          ),
        ],
        hasMore: false,
      );
    }

    return (items: <OmiProjectEntry>[], hasMore: false);
  }
}
