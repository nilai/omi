import 'package:flutter_bloc/flutter_bloc.dart';

enum MPAudioDetailPhase { loading, error, loaded }

class MPAudioDetailData {
  const MPAudioDetailData({
    required this.title,
    required this.subtitle,
    required this.leftTime,
    required this.rightTime,
  });

  final String title;
  final String subtitle;
  final String leftTime;
  final String rightTime;
}

class MPAudioDetailState {
  const MPAudioDetailState({required this.phase, this.data, this.errorMessage});

  final MPAudioDetailPhase phase;
  final MPAudioDetailData? data;
  final String? errorMessage;

  MPAudioDetailState copyWith({
    MPAudioDetailPhase? phase,
    MPAudioDetailData? data,
    String? errorMessage,
  }) {
    return MPAudioDetailState(
      phase: phase ?? this.phase,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Audio 详情页 Cubit：负责数据加载与交互入口（播放/分享/更多/AI 总结）。
class MPAudioDetailCubit extends Cubit<MPAudioDetailState> {
  MPAudioDetailCubit()
    : super(const MPAudioDetailState(phase: MPAudioDetailPhase.loading));

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
    // TODO: 播放/暂停
  }

  Future<void> onSummarizeTap() async {
    // TODO: AI Summarize
  }
}
