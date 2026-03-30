import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

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

  final int id;
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

  final int id;
  final String titleOrDate;
  final String timeLabel;
}

class MPHomeState {
  const MPHomeState({
    required this.upNextTodos,
    required this.recentMemories,
    required this.insightsUnreadCount,
    required this.insightsSummaryLine,
    this.audioStatus,
  });

  final List<MPHomeTodoItem> upNextTodos;
  final List<MPHomeMemoryItem> recentMemories;

  /// Insights 卡片角标（动态演示）
  final int insightsUnreadCount;

  /// Insights 卡片正文一行摘要
  final String insightsSummaryLine;

  final MPHomeAudioStatus? audioStatus;

  MPHomeState copyWith({
    List<MPHomeTodoItem>? upNextTodos,
    List<MPHomeMemoryItem>? recentMemories,
    int? insightsUnreadCount,
    String? insightsSummaryLine,
    MPHomeAudioStatus? audioStatus,
    bool clearAudioStatus = false,
  }) {
    return MPHomeState(
      upNextTodos: upNextTodos ?? this.upNextTodos,
      recentMemories: recentMemories ?? this.recentMemories,
      insightsUnreadCount: insightsUnreadCount ?? this.insightsUnreadCount,
      insightsSummaryLine: insightsSummaryLine ?? this.insightsSummaryLine,
      audioStatus: clearAudioStatus ? null : (audioStatus ?? this.audioStatus),
    );
  }
}

/// 首页：Today's Focus / Recent Memory / Insights / 顶部状态条（mock + 定时刷新）
class MPHomeCubit extends Cubit<MPHomeState> {
  MPHomeCubit() : super(_initialState());

  Timer? _insightsTimer;
  final Random _random = Random();

  static MPHomeState _initialState() {
    const List<MPHomeTodoItem> upNext = <MPHomeTodoItem>[
      MPHomeTodoItem(
        id: 1,
        title: 'Review migration milestones with infrastructure team',
        time: '09:00',
        reason: 'Meeting scheduled today',
      ),
      MPHomeTodoItem(
        id: 3,
        title: 'Follow up with Sarah about design feedback',
        time: '14:00',
        reason: 'Design feedback pending',
      ),
      MPHomeTodoItem(
        id: 4,
        title: 'Finalize API migration timeline',
        time: '16:30',
        reason: 'Project deadline soon',
      ),
    ];

    const List<MPHomeMemoryItem> memories = <MPHomeMemoryItem>[
      MPHomeMemoryItem(
        id: 1,
        titleOrDate: 'Team standup discussion on API migration',
        timeLabel: '2h ago',
      ),
      MPHomeMemoryItem(
        id: 7,
        titleOrDate: 'Product launch planning with marketing team',
        timeLabel: '3h ago',
      ),
      MPHomeMemoryItem(
        id: 8,
        titleOrDate: 'Investor meeting - Series A funding discussion',
        timeLabel: 'Yesterday',
      ),
    ];

    return MPHomeState(
      upNextTodos: upNext,
      recentMemories: memories,
      insightsUnreadCount: 1,
      insightsSummaryLine:
          'You have three meetings tomorrow morning. Consider blocking 30 minutes before the first one to review notes.',
      audioStatus: null,
    );
  }

  void start() {
    _insightsTimer?.cancel();
    _insightsTimer = Timer.periodic(const Duration(seconds: 4), (_) => _tickInsights());
  }

  void _tickInsights() {
    final int nextBadge = _random.nextInt(4);
    final List<String> lines = <String>[
      'You have three meetings tomorrow morning. Consider blocking 30 minutes before the first one to review notes.',
      'Pattern detected: API migration blockers appeared in multiple discussions this week.',
      'Weekly reflection: balance deep work blocks with follow-ups on investor materials.',
      'Today\'s tip: link todos to memories so Recall stays accurate.',
    ];
    final String line = lines[_random.nextInt(lines.length)];
    emit(
      state.copyWith(
        insightsUnreadCount: nextBadge,
        insightsSummaryLine: line,
      ),
    );
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
