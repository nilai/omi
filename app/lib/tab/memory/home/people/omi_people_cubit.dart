import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'card/mp_all_people_card.dart';
import 'card/mp_recently_mentioned_card.dart';

/// People 页展示阶段（与 [MPTristatePage] 对应）
enum OmiPeoplePhase {
  /// 加载中
  loading,

  /// 无数据
  empty,

  /// 无网络
  noNetwork,

  /// 业务/服务器错误
  error,

  /// 有数据
  loaded,
}

/// People 页状态（无分页、无上拉加载）
class OmiPeopleState {
  final OmiPeoplePhase phase;

  /// 最近提及人物列表（仅 [OmiPeoplePhase.loaded] 有意义）
  final List<MPRecentlyMentionedPersonItem> items;

  /// 全部人物（字母表顺序由 [MPAllPeopleCard] 内部分组）
  final List<MPAllPeopleRowItem> allPeopleItems;

  final String? errorMessage;

  const OmiPeopleState({
    required this.phase,
    this.items = const [],
    this.allPeopleItems = const [],
    this.errorMessage,
  });
}

/// People：首屏 [load]、下拉刷新 [load]（无 [loadMore]）
class OmiPeopleCubit extends Cubit<OmiPeopleState> {
  OmiPeopleCubit() : super(const OmiPeopleState(phase: OmiPeoplePhase.loading));

  /// 首次进入：等价于 [load]
  Future<void> initData() => load();

  /// 拉取数据
  ///
  /// - **当前无列表数据**：先检测网络，离线则 [OmiPeoplePhase.noNetwork]；在线则全屏 loading 再请求
  /// - **当前已有列表**（下拉刷新）：不展示三态图，保持列表；请求失败则仍显示原数据
  Future<void> load() async {
    final List<MPRecentlyMentionedPersonItem> beforeRecent =
        List<MPRecentlyMentionedPersonItem>.from(state.items);
    final List<MPAllPeopleRowItem> beforeAll =
        List<MPAllPeopleRowItem>.from(state.allPeopleItems);
    final bool hasData =
        beforeRecent.isNotEmpty || beforeAll.isNotEmpty;

    if (!hasData) {
      final bool online = await _hasNetworkConnectivity();
      if (!online) {
        emit(const OmiPeopleState(phase: OmiPeoplePhase.noNetwork));
        return;
      }
      emit(const OmiPeopleState(phase: OmiPeoplePhase.loading));
    }

    try {
      final ({
        List<MPRecentlyMentionedPersonItem> recent,
        List<MPAllPeopleRowItem> all,
      }) bundle = await _fetchPeople();

      if (bundle.recent.isEmpty && bundle.all.isEmpty) {
        emit(const OmiPeopleState(phase: OmiPeoplePhase.empty));
        return;
      }

      emit(
        OmiPeopleState(
          phase: OmiPeoplePhase.loaded,
          items: bundle.recent,
          allPeopleItems: bundle.all,
        ),
      );
    } on SocketException catch (_) {
      if (!hasData) {
        emit(const OmiPeopleState(phase: OmiPeoplePhase.noNetwork));
      } else {
        emit(
          OmiPeopleState(
            phase: OmiPeoplePhase.loaded,
            items: beforeRecent,
            allPeopleItems: beforeAll,
          ),
        );
      }
    } on TimeoutException catch (_) {
      if (!hasData) {
        emit(const OmiPeopleState(phase: OmiPeoplePhase.noNetwork));
      } else {
        emit(
          OmiPeopleState(
            phase: OmiPeoplePhase.loaded,
            items: beforeRecent,
            allPeopleItems: beforeAll,
          ),
        );
      }
    } catch (e) {
      if (!hasData) {
        emit(
          OmiPeopleState(
            phase: OmiPeoplePhase.error,
            errorMessage: e.toString(),
          ),
        );
      } else {
        emit(
          OmiPeopleState(
            phase: OmiPeoplePhase.loaded,
            items: beforeRecent,
            allPeopleItems: beforeAll,
          ),
        );
      }
    }
  }

  /// 三态页重试
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

  /// 模拟接口；接入真实 API 时替换为请求
  Future<
      ({
        List<MPRecentlyMentionedPersonItem> recent,
        List<MPAllPeopleRowItem> all,
      })> _fetchPeople() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return (
      recent: const <MPRecentlyMentionedPersonItem>[
        // MPRecentlyMentionedPersonItem(
        //   name: 'Alex',
        //   lastTalkedPhrase: 'today',
        //   memoryCount: 3,
        // ),
        // MPRecentlyMentionedPersonItem(
        //   name: 'Sarah',
        //   lastTalkedPhrase: 'yesterday',
        //   memoryCount: 2,
        // ),
        // MPRecentlyMentionedPersonItem(
        //   name: 'Jordan',
        //   lastTalkedPhrase: 'today',
        //   memoryCount: 1,
        // ),
        // MPRecentlyMentionedPersonItem(
        //   name: 'Emily',
        //   lastTalkedPhrase: 'yesterday',
        //   memoryCount: 2,
        // ),
      ],
      all: const <MPAllPeopleRowItem>[
        // MPAllPeopleRowItem(name: 'Alex', dateLabel: 'Jan 21', count: 3),
        // MPAllPeopleRowItem(name: 'Amy', dateLabel: 'Jan 10', count: 1),
        // MPAllPeopleRowItem(name: 'David', dateLabel: 'Today', count: 4),
        // MPAllPeopleRowItem(name: 'Elena', dateLabel: 'Jan 5', count: 2),
        // MPAllPeopleRowItem(name: 'Jordan', dateLabel: 'Jan 18', count: 1),
        // MPAllPeopleRowItem(name: 'Julia', dateLabel: 'Dec 28', count: 5),
      ],
    );
  }
}
