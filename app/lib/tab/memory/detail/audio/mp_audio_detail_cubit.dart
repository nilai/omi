import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../memory/card/mp_memory_generate_summary_sheet.dart';

enum MPAudioDetailPhase { loading, error, loaded }

class MPAudioDetailData {
  const MPAudioDetailData({
    required this.title,
    required this.subtitle,
    required this.leftTime,
    required this.rightTime,
    required this.total,
  });

  final String title;
  final String subtitle;
  final String leftTime;
  final String rightTime;
  final Duration total;
}

class MPAudioDetailState {
  const MPAudioDetailState({
    required this.phase,
    this.data,
    this.errorMessage,
    this.isPlaying = false,
    this.progress = 0,
  });

  final MPAudioDetailPhase phase;
  final MPAudioDetailData? data;
  final String? errorMessage;
  final bool isPlaying;

  /// 0..1
  final double progress;

  MPAudioDetailState copyWith({
    MPAudioDetailPhase? phase,
    MPAudioDetailData? data,
    String? errorMessage,
    bool? isPlaying,
    double? progress,
  }) {
    return MPAudioDetailState(
      phase: phase ?? this.phase,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      isPlaying: isPlaying ?? this.isPlaying,
      progress: progress ?? this.progress,
    );
  }
}

/// Audio 详情页 Cubit：负责数据加载与交互入口（播放/分享/更多/AI 总结）。
class MPAudioDetailCubit extends Cubit<MPAudioDetailState> {
  MPAudioDetailCubit()
    : super(const MPAudioDetailState(phase: MPAudioDetailPhase.loading));

  Timer? _timer;

  Future<void> initData() async {
    try {
      // TODO: 替换为真实接口
      await Future<void>.delayed(const Duration(milliseconds: 200));
      emit(
        MPAudioDetailState(
          phase: MPAudioDetailPhase.loaded,
          data: const MPAudioDetailData(
            title: 'Jan 21, 2026, 3:45 PM',
            subtitle: 'January 21, 2026 at 3:45 PM  ·  MemoPin',
            leftTime: '0:00',
            rightTime: '5m23s',
            total: Duration(minutes: 5, seconds: 23),
          ),
        ),
      );
    } catch (e) {
      emit(
        MPAudioDetailState(
          phase: MPAudioDetailPhase.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> retry() => initData();

  Future<void> onPlayTap() async {
    if (state.phase != MPAudioDetailPhase.loaded) return;
    final bool next = !state.isPlaying;
    if (!next) {
      _stopTimer();
      emit(state.copyWith(isPlaying: false));
      return;
    }

    double p = state.progress;
    if (p >= 1) {
      p = 0;
    }
    emit(state.copyWith(isPlaying: true, progress: p));
    _startTimer();
    // TODO: 播放/暂停（接真实音频时在这里同步播放器）
  }

  void _startTimer() {
    _stopTimer();
    final Duration total = state.data?.total ?? Duration.zero;
    if (total <= Duration.zero) return;

    const Duration tick = Duration(milliseconds: 120);
    final int totalMs = total.inMilliseconds;
    _timer = Timer.periodic(tick, (_) {
      final double next = (state.progress + tick.inMilliseconds / totalMs)
          .clamp(0.0, 1.0);
      if (next >= 1.0) {
        _stopTimer();
        emit(state.copyWith(isPlaying: false, progress: 1));
      } else {
        emit(state.copyWith(progress: next));
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }

  void onSummarizeTap(BuildContext context) {
    showMPMemoryGenerateSummarySheet(
      context,
      onGenerateResummary: () {
        // TODO: 调用生成 resummary 接口
      },
      onChangeMode: () {
        // TODO: 切换 Autopilot / 其它模式
      },
    );
  }
}
