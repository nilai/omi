import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

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
  final List<String> items;

  /// 错误说明（[MPMemoryPhase.error] 时展示）
  final String? errorMessage;

  const MPMemoryState({
    required this.phase,
    this.items = const [],
    this.errorMessage,
  });
}

/// Memory 页逻辑：加载列表、重试、区分空/网络错误/其它错误
class MPMemoryCubit extends Cubit<MPMemoryState> {
  MPMemoryCubit() : super(const MPMemoryState(phase: MPMemoryPhase.loading));

  /// 首次进入或下拉刷新时调用；后续替换为真实接口
  Future<void> load() async {
    emit(const MPMemoryState(phase: MPMemoryPhase.loading));
    try {
      final List<String> list = await _fetchMemoryList();
      if (list.isEmpty) {
        emit(const MPMemoryState(phase: MPMemoryPhase.empty));
        return;
      }
      emit(MPMemoryState(phase: MPMemoryPhase.loaded, items: list));
    } on SocketException catch (_) {
      emit(const MPMemoryState(phase: MPMemoryPhase.noNetwork));
    } on TimeoutException catch (_) {
      emit(const MPMemoryState(phase: MPMemoryPhase.noNetwork));
    } catch (e) {
      emit(
        MPMemoryState(
          phase: MPMemoryPhase.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// 用户点击三态页「重试 / 刷新」
  Future<void> retry() => load();

  /// 模拟网络请求：替换为真实 Dio/Http
  ///
  /// 当前逻辑：演示用数据；若要看空页，可改为 `return <String>[]`；
  /// 若要试无网，可暂时 `throw const SocketException('no network')`。
  Future<List<String>> _fetchMemoryList() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return <String>[
 
    ];
  }
}
