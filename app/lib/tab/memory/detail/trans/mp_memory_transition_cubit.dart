import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../http/api/mp_memory.dart';
import '../../../../http/schema/mp_memory.dart';

enum MPMemoryTransitionPhase { polling, completed, error }

class MPMemoryTransitionState {
  const MPMemoryTransitionState({
    required this.phase,
    this.errorMessage,
  });

  final MPMemoryTransitionPhase phase;
  final String? errorMessage;

  MPMemoryTransitionState copyWith({
    MPMemoryTransitionPhase? phase,
    String? errorMessage,
  }) {
    return MPMemoryTransitionState(
      phase: phase ?? this.phase,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MPMemoryTransitionCubit extends Cubit<MPMemoryTransitionState> {
  MPMemoryTransitionCubit({required this.memoryId})
    : super(const MPMemoryTransitionState(phase: MPMemoryTransitionPhase.polling));

  final String memoryId;
  static const Duration _pollingInterval = Duration(seconds: 5);
  Timer? _pollingTimer;

  /// 开始轮询总结状态。
  ///
  /// @returns {Future<void>}
  Future<void> startPolling() async {
    _stopPolling();
    emit(const MPMemoryTransitionState(phase: MPMemoryTransitionPhase.polling));
    await _checkStatus();
    if (isClosed || state.phase != MPMemoryTransitionPhase.polling) {
      return;
    }
    _pollingTimer = Timer.periodic(_pollingInterval, (_) async {
      await _checkStatus();
    });
  }

  /// 停止轮询，外部可手动调用。
  ///
  /// @returns {void}
  void stopPolling() {
    _stopPolling();
  }

  /// 主动重试（重启轮询）。
  ///
  /// @returns {Future<void>}
  Future<void> retry() async {
    await startPolling();
  }

  Future<void> _checkStatus() async {
    try {
      final MPGetSummaryStatusResponse? res = await getSummaryStatus(
        MPGetSummaryStatusRequest(memoryId: memoryId),
      );
      if (res == null) {
        return;
      }
      if (res.baseResp.code != 0) {
        emit(
          MPMemoryTransitionState(
            phase: MPMemoryTransitionPhase.error,
            errorMessage: res.baseResp.message,
          ),
        );
        _stopPolling();
        return;
      }
      if (res.status == 2) {
        emit(const MPMemoryTransitionState(phase: MPMemoryTransitionPhase.completed));
        _stopPolling();
      }
    } catch (_) {
      // 保持轮询，不把瞬时网络错误视为失败。
    }
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
