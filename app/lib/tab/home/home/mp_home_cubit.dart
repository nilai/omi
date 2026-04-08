import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/blu/mp_bluetooth_connection_helper.dart';
import 'package:memo_pin/common/mp_memory_notification.dart';

import '../../../common/mp_date_utils.dart';
import '../../../http/api/mp_home.dart';
import '../../../http/schema/mp_data_model.dart';
import '../../../http/schema/mp_home.dart';

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

  /// 同步：当前**正在上传的这一条文件**的进度 0–100（非整批累加）；第 N 条完成后，第 N+1 条从 0 再到 100。
  /// 导入：导入单文件的进度 0–100。
  final int? progress;

  /// 多文件同步时当前条序号（从 1 开始），与 [progress] 表示的「当前条」一致。
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
    _recordCreatedSub =
        MPMemoryNotification.listenMemoryRecordCreated(_onMemoryRecordCreated);
    _uploadProgressSub =
        MPMemoryNotification.listenUploadProgress(_onUploadProgress);
    initData();
  }

  Timer? _insightsTimer;
  StreamSubscription<MPMemoryRecordCreatedPayload>? _recordCreatedSub;
  StreamSubscription<MPMemoryRecordUploadProgressPayload>? _uploadProgressSub;
  Timer? _syncCompletedClearTimer;

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

  /// 若本地存在上次连接的 BLE 记录，则短扫并建链后 [MPBluetoothConnectionHelper.parkBackgroundBleTransport]；无记录则立即返回。
  Future<void> connectBluetoothToLastRecordedDevice() {
    return MPBluetoothConnectionHelper.tryConnectLastRecordedBleDevice();
  }

  Future<void> initData() async {
    unawaited(connectBluetoothToLastRecordedDevice());
    await loadData();
  }

  Future<void> loadData() async {
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
      // if (upNextTodos.length < 4) {
      //   const List<MPHomeTodoItem> mockTodoItems = <MPHomeTodoItem>[
      //     MPHomeTodoItem(
      //       id: 'mock_todo_1',
      //       title: 'Review weekly highlights',
      //       time: '09:30',
      //       reason: 'high',
      //     ),
      //     MPHomeTodoItem(
      //       id: 'mock_todo_2',
      //       title: 'Prepare standup notes',
      //       time: '11:00',
      //       reason: 'medium',
      //     ),
      //     MPHomeTodoItem(
      //       id: 'mock_todo_3',
      //       title: 'Sync family reminders',
      //       time: '14:20',
      //       reason: 'low',
      //     ),
      //     MPHomeTodoItem(
      //       id: 'mock_todo_4',
      //       title: 'Clean up old tags',
      //       time: '18:45',
      //       reason: 'low',
      //     ),
      //   ];
      //   for (final MPHomeTodoItem mockItem in mockTodoItems) {
      //     if (upNextTodos.length >= 4) {
      //       break;
      //     }
      //     final bool existed = upNextTodos.any((MPHomeTodoItem e) => e.id == mockItem.id);
      //     if (!existed) {
      //       upNextTodos.add(mockItem);
      //     }
      //   }
      // }
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
      // if (recentMemories.length < 4) {
      //   const List<MPHomeMemoryItem> mockMemoryItems = <MPHomeMemoryItem>[
      //     MPHomeMemoryItem(
      //       id: 'mock_memory_1',
      //       titleOrDate: 'Morning walking reflection',
      //       timeLabel: '2h ago',
      //     ),
      //     MPHomeMemoryItem(
      //       id: 'mock_memory_2',
      //       titleOrDate: 'Team retro key decisions',
      //       timeLabel: 'Yesterday',
      //     ),
      //     MPHomeMemoryItem(
      //       id: 'mock_memory_3',
      //       titleOrDate: 'Family trip checklist',
      //       timeLabel: '2d ago',
      //     ),
      //     MPHomeMemoryItem(
      //       id: 'mock_memory_4',
      //       titleOrDate: 'Book notes summary',
      //       timeLabel: '3d ago',
      //     ),
      //   ];
      //   for (final MPHomeMemoryItem mockItem in mockMemoryItems) {
      //     if (recentMemories.length >= 4) {
      //       break;
      //     }
      //     final bool existed = recentMemories.any((MPHomeMemoryItem e) => e.id == mockItem.id);
      //     if (!existed) {
      //       recentMemories.add(mockItem);
      //     }
      //   }
      // }
      final MPHomeInsightOverviewStruct insightOverview = response.insightOverview;
      if (!isClosed) {
        emit(state.copyWith(
          upNextTodos: upNextTodos,
          recentMemories: recentMemories,
          insightOverview: insightOverview,
        ));
      }
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

  /// 文件同步：`progress` 为**当前条**上传进度 0–100；多文件时换条后从 0 重新计。
  void showSyncingStatus({
    required int currentFile,
    required int totalFiles,
    required int progress,
  }) {
    _syncCompletedClearTimer?.cancel();
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

  /// 与 [MPMemoryRecordUploadProgressPayload.progress] 一致：单文件 0–100，下一条开始时由上传侧先发 0。
  void _onUploadProgress(MPMemoryRecordUploadProgressPayload payload) {
    if (state.audioStatus?.type == MPHomeAudioStatusType.recording) {
      return;
    }
    final int batchTotal = payload.batchTotal < 1 ? 1 : payload.batchTotal;
    final int batchIndex = payload.batchIndex.clamp(1, batchTotal);
    showSyncingStatus(
      currentFile: batchIndex,
      totalFiles: batchTotal,
      progress: payload.progress.clamp(0, 100),
    );
  }

  /// [MPMemoryNotification]：本地录音上传并创建 record 成功后收口（最后一条完成后延时清除条）。
  void _onMemoryRecordCreated(MPMemoryRecordCreatedPayload payload) {
    if (state.audioStatus?.type == MPHomeAudioStatusType.recording) {
      return;
    }
    _syncCompletedClearTimer?.cancel();
    final int total = payload.batchTotal < 1 ? 1 : payload.batchTotal;
    final int index = payload.batchIndex.clamp(1, total);
    // 本条已创建完成，与 [_onUploadProgress] 单文件进度语义一致（不再用批次折算，避免从 100% 回跳）。
    const int progress = 100;
    emit(
      state.copyWith(
        audioStatus: MPHomeAudioStatus(
          type: MPHomeAudioStatusType.syncing,
          progress: progress.clamp(0, 100),
          currentFile: index,
          totalFiles: total,
        ),
      ),
    );
    if (index >= total) {
      _syncCompletedClearTimer = Timer(const Duration(milliseconds: 1600), () {
        if (!isClosed) {
          emit(state.copyWith(clearAudioStatus: true));
        }
      });
    }
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
    _syncCompletedClearTimer?.cancel();
    _recordCreatedSub?.cancel();
    _uploadProgressSub?.cancel();
    return super.close();
  }
}
