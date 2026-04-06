import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/mp_date_utils.dart';
import '../../../http/api/mp_home.dart';
import '../../../http/schema/mp_data_model.dart';
import '../../../http/schema/mp_home.dart';
import '../../../utils/mp_toast_utils.dart';

/// 首页音频条状态类型（对齐 react `AudioStatusBar`）
enum MPHomeAudioStatusType {
  recording,
  syncing,
  importing,
}

/// 首页顶部音频 / 同步状态
class MPHomeAudioStatus {
  const MPHomeAudioStatus({
    required this.type,
    this.progress,
    this.currentFile,
    this.totalFiles,
  });

  final MPHomeAudioStatusType type;

  /// 0–100，同步 / 导入时使用
  final int? progress;

  /// 多文件同步时的当前序号（从 1 开始）
  final int? currentFile;

  final int? totalFiles;
}

/// Today's Focus 列表项（Up Next）
class MPHomeTodoItem {
  const MPHomeTodoItem({
    required this.id,
    required this.title,
    this.time,
    this.reason,
    this.completed = false,
  });

  final String id;
  final String title;
  final String? time;
  final String? reason;
  final bool completed;
}

/// Recent Memory 一行
class MPHomeMemoryItem {
  const MPHomeMemoryItem({
    required this.id,
    required this.titleOrDate,
    required this.timeLabel,
  });

  final String id;
  final String titleOrDate;
  final String timeLabel;
}

class MPHomeState {
  const MPHomeState({
    required this.upNextTodos,
    required this.recentMemories,
    required this.insightOverview,
    this.audioStatus,
  });

  final List<MPHomeTodoItem> upNextTodos;
  final List<MPHomeMemoryItem> recentMemories;

  /// Insights 卡片角标（动态演示）
  final MPHomeInsightOverviewStruct insightOverview;

  /// 
  final MPHomeAudioStatus? audioStatus;

  MPHomeState copyWith({
    List<MPHomeTodoItem>? upNextTodos,
    List<MPHomeMemoryItem>? recentMemories,
    MPHomeInsightOverviewStruct? insightOverview,
    MPHomeAudioStatus? audioStatus,
    bool clearAudioStatus = false,
  }) {
    return MPHomeState(
      upNextTodos: upNextTodos ?? this.upNextTodos,
      recentMemories: recentMemories ?? this.recentMemories,
      insightOverview: insightOverview ?? this.insightOverview,
      audioStatus: clearAudioStatus ? null : (audioStatus ?? this.audioStatus),
    );
  }
}

/// 首页：Today's Focus / Recent Memory / Insights / 顶部状态条（mock + 定时刷新）
class MPHomeCubit extends Cubit<MPHomeState> {
  MPHomeCubit() : super(_initialState()) {
    initData();
  }

  Timer? _insightsTimer;

  static MPHomeState _initialState() {
    return MPHomeState(
      upNextTodos: const <MPHomeTodoItem>[],
      recentMemories: const <MPHomeMemoryItem>[],
      insightOverview: MPHomeInsightOverviewStruct(
        title: '',
        subTitle: '',
        newInsightCount: 0,
        content: '',),
    );
  }

  void initData() async {
    final MPGetHomeOverviewResponse? response = await getHomeOverview(MPGetHomeOverviewRequest());
    if (response != null && response.baseResp.code == 0) {
        
      final List<MPHomeTodoItem> upNextTodos = <MPHomeTodoItem>[];
      for (final MPTodoStruct e in response.focusItems) {
        String formatDeadlineToTime(int? deadline) {
          if (deadline == null) return '';
          final DateTime? dt = MPDateUtils.dateTimeFromUnixEpoch(deadline);
          if (dt == null) return '';
          final String hh = dt.hour.toString().padLeft(2, '0');
          final String mm = dt.minute.toString().padLeft(2, '0');
          return '$hh:$mm';
        }
        upNextTodos.add(MPHomeTodoItem(id: e.id ?? '', title: e.title ?? '', time: formatDeadlineToTime(e.deadline), reason: e.priority ?? ''));
      }
      final List<MPHomeMemoryItem> recentMemories = <MPHomeMemoryItem>[];
      for (final MPMemoryStruct e in response.recentMemories) {
        recentMemories.add(
          MPHomeMemoryItem(
            id: e.id,
            titleOrDate: e.title,
            timeLabel: MPDateUtils.formatRelativeTimeAgo(e.createAt),
          ),
        );
      }
      final MPHomeInsightOverviewStruct insightOverview = response.insightOverview;

      emit(state.copyWith(
        upNextTodos: upNextTodos,
        recentMemories: recentMemories,
        insightOverview: insightOverview,
      ));
    }
  }

  void start() {
    _insightsTimer?.cancel();
    _insightsTimer = Timer.periodic(Duration(seconds: 1), (_) => _tickInsights());
  }

  void _tickInsights() {
    // TODO: 定时刷新 insights
  }

  /// 演示：设备录音中（对齐 react `setRecording`）
  void showRecordingStatus() {
    emit(
      state.copyWith(
        audioStatus: const MPHomeAudioStatus(
          type: MPHomeAudioStatusType.recording,
        ),
      ),
    );
  }

  /// 演示：文件同步（进度与 current/total 可变）
  void showSyncingStatus({required int currentFile, required int totalFiles, required int progress}) {
    emit(
      state.copyWith(
        audioStatus: MPHomeAudioStatus(
          type: MPHomeAudioStatusType.syncing,
          progress: progress.clamp(0, 100),
          currentFile: currentFile,
          totalFiles: totalFiles,
        ),
      ),
    );
  }

  /// 演示：导入音频
  void showImportingStatus(int progress) {
    emit(
      state.copyWith(
        audioStatus: MPHomeAudioStatus(
          type: MPHomeAudioStatusType.importing,
          progress: progress.clamp(0, 100),
        ),
      ),
    );
  }

  void clearAudioStatus() {
    emit(state.copyWith(clearAudioStatus: true));
  }

  @override
  Future<void> close() {
    _insightsTimer?.cancel();
    return super.close();
  }
}
