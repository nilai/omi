import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/blu/mp_ble_file_util.dart';
import 'package:memo_pin/cache/mp_hive_util.dart';
import 'package:memo_pin/blu/mp_ble_transport.dart';
import 'package:memo_pin/blu/mp_ble_connection_helper.dart';
import 'package:memo_pin/common/mp_home_notification.dart';
import 'package:memo_pin/utils/mp_time_utils.dart';

import '../../../common/mp_date_utils.dart';
import '../../../http/api/mp_home.dart';
import '../../../http/api/mp_insight.dart';
import '../../../http/schema/mp_data_model.dart';
import '../../../http/schema/mp_home.dart';
import '../../../http/schema/mp_insight.dart';

/// Hive 中缓存 [MPGetHomeOverviewResponse.toJson] 的 key。
const String _kHomeOverviewHiveKey = 'mp_home_overview_v1';

/// 首页音频条状态类型（对齐 react `AudioStatusBar`）
enum MPHomeAudioStatusType { recording, syncing, importing }

/// 首页顶部音频 / 同步状态
class MPHomeAudioStatus {
  const MPHomeAudioStatus({required this.type, this.progress, this.currentFile, this.totalFiles});

  final MPHomeAudioStatusType type;

  /// 导入 / 同步流程中保留字段（例如与旧上报对齐）；首页状态条进度展示为动画条，不再绑定该百分比。
  final int? progress;

  /// 当前正在处理的文件序号（从 1 开始），与 [totalFiles] 组成状态条右侧 **x/y** 展示。
  final int? currentFile;

  /// 本批次文件总数，与 [currentFile] 组成 **x/y**。
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
    this.memoryId,
    this.insightId,
    this.deadlineUnixSec,
    this.description,
  });

  final String id;
  final String title;
  final String? time;
  final String? reason;
  final bool completed;
  final int? memoryId;
  final String? insightId;
  final String? description;

  /// 与 [MPTodoStruct.deadline] 一致（Unix 秒）；无截止为 `null`。
  final int? deadlineUnixSec;
}

/// Recent Memory 一行
class MPHomeMemoryItem {
  const MPHomeMemoryItem({
    required this.id,
    required this.titleOrDate,
    required this.timeLabel,
    required this.createAt,
    required this.type,
  });

  final String id;
  final String titleOrDate;
  final String timeLabel;
  final int createAt;
  final MPMemoryType type;
}

class MPHomeState {
  const MPHomeState({
    required this.upNextTodos,
    required this.recentMemories,
    required this.insightOverview,
    required this.isBleConnected,
    this.audioStatus,
  });

  final List<MPHomeTodoItem> upNextTodos;
  final List<MPHomeMemoryItem> recentMemories;

  /// Insights 卡片角标（动态演示）
  final MPHomeInsightOverviewStruct insightOverview;

  /// 是否已连接 BLE 设备。
  final bool isBleConnected;

  ///
  final MPHomeAudioStatus? audioStatus;

  MPHomeState copyWith({
    List<MPHomeTodoItem>? upNextTodos,
    List<MPHomeMemoryItem>? recentMemories,
    MPHomeInsightOverviewStruct? insightOverview,
    bool? isBleConnected,
    MPHomeAudioStatus? audioStatus,
    bool clearAudioStatus = false,
  }) {
    return MPHomeState(
      upNextTodos: upNextTodos ?? this.upNextTodos,
      recentMemories: recentMemories ?? this.recentMemories,
      insightOverview: insightOverview ?? this.insightOverview,
      isBleConnected: isBleConnected ?? this.isBleConnected,
      audioStatus: clearAudioStatus ? null : (audioStatus ?? this.audioStatus),
    );
  }
}

/// 首页：Today's Focus / Recent Memory / Insights / 顶部状态条（mock + 定时刷新）
class MPHomeCubit extends Cubit<MPHomeState> {
  MPHomeCubit() : super(_initialState()) {
    _recordCreatedSub = MPHomeNotification.listenRecordCreated(_onMemoryRecordCreated);
    _uploadProgressSub = MPHomeNotification.listenUploadProgress(_onUploadProgress);
    _homeListRefreshSub = MPHomeNotification.listenHomeListRefresh(_onHomeListRefresh);
    _todoDoneSub = MPHomeNotification.listenTodoDone(_onTodoDone);
    _todoDeletedSub = MPHomeNotification.listenTodoDeleted(_onTodoDeleted);
    _bleConnectedSub = MPHomeNotification.listenBleConnectedSuccess(_onBleConnectedSuccess);
    _bleMemopinRecordingSub = MPHomeNotification.listenBleMemopinRecordingState(_onBleMemopinRecordingStateChanged);
    initData();
  }

  Timer? _insightsTimer;
  StreamSubscription<MPHomeRecordCreatedPayload>? _recordCreatedSub;
  StreamSubscription<MPHomeUploadProgressPayload>? _uploadProgressSub;
  StreamSubscription<void>? _homeListRefreshSub;
  StreamSubscription<MPHomeTodoDonePayload>? _todoDoneSub;
  StreamSubscription<MPHomeTodoDeletedPayload>? _todoDeletedSub;
  StreamSubscription<void>? _bleConnectedSub;
  StreamSubscription<MPBleMemopinRecordingStateChangedPayload>? _bleMemopinRecordingSub;

  /// 外接 MemoPin 仍在录音时，将本应展示为 importing/syncing 的状态暂存，待停录后再 [emit]（见 [_onBleMemopinRecordingStateChanged]）。
  MPHomeAudioStatus? _pendingPostBleRecordingAudioStatus;

  /// 与 [_pendingPostBleRecordingAudioStatus] 配套：仅在 [_onMemoryRecordCreated] 因设备占录而推迟且为批次最后一条时设置，用于停录后启动 [_syncCompletedClearTimer]。
  MPHomeRecordCreatedPayload? _deferredRecordCreatedCompletion;

  Timer? _syncCompletedClearTimer;
  bool _bleDeviceImportRunning = false;

  static MPHomeState _initialState() {
    return MPHomeState(
      upNextTodos: const <MPHomeTodoItem>[],
      recentMemories: const <MPHomeMemoryItem>[],
      insightOverview: MPHomeInsightOverviewStruct(title: '', subTitle: '', newInsightCount: 0, content: ''),
      isBleConnected: false,
    );
  }

  void initData() {
    connectBluetoothToLastRecordedDevice();
    loadData();
  }

  /// 若本地存在上次连接的 BLE 记录，则短扫并建链后 [MPBleConnectionHelper.parkBackgroundBleTransport]；无记录则立即返回。
  Future<void> connectBluetoothToLastRecordedDevice() async {
    final bool connected = await MPBleConnectionHelper.tryConnectLastRecordedBleDevice();
    if (!isClosed && state.isBleConnected != connected) {
      emit(state.copyWith(isBleConnected: connected));
    }
  }

  /// 刷新 BLE 连接状态到 state。
  Future<void> refreshBleConnectionState() async {
    final bool connected = await MPBleConnectionHelper.hasConnectedBleDevice();
    if (!isClosed && state.isBleConnected != connected) {
      emit(state.copyWith(isBleConnected: connected));
    }
  }

  /// Today's Focus / Recent Memory 是否均为空（用于决定是否先读 Hive 占位）。
  bool _isHomeMainListsEmpty(MPHomeState s) {
    return s.upNextTodos.isEmpty && s.recentMemories.isEmpty;
  }

  /// 将接口响应映射为首页 state 并 [emit]。
  void _emitFromOverviewResponse(MPGetHomeOverviewResponse response) {
    final List<MPHomeTodoItem> upNextTodos = <MPHomeTodoItem>[];
    for (final MPTodoStruct e in response.focusItems) {
      upNextTodos.add(
        MPHomeTodoItem(
          id: e.id ?? '',
          title: e.title ?? '',
          time: MPTimeUtils.formatTodoDeadlineLabel(e.deadline),
          reason: e.reason ?? '',
          memoryId: e.memoryId,
          insightId: e.insightId,
          deadlineUnixSec: e.deadline,
          completed: e.status == 2,
          description: e.description,
        ),
      );
    }
    final List<MPHomeMemoryItem> recentMemories = <MPHomeMemoryItem>[];
    for (final MPMemoryStruct e in response.recentMemories) {
      String titleOrDate = e.title ?? '';
      if (titleOrDate.isEmpty) {
        titleOrDate = e.content ?? '';
      }
      if (titleOrDate.isEmpty) {
        final String date = MPDateUtils.formatDeadlineLineText(e.createAt);
        titleOrDate = '$date file';
      }
      recentMemories.add(
        MPHomeMemoryItem(
          id: e.id ?? '',
          titleOrDate: titleOrDate,
          timeLabel: MPDateUtils.formatRelativeTimeAgo(e.createAt),
          createAt: e.createAt,
          type: e.type ?? MPMemoryType.onlyRecord,
        ),
      );
    }
    final MPHomeInsightOverviewStruct insightOverview = response.insightOverview;
    if (!isClosed) {
      emit(state.copyWith(upNextTodos: upNextTodos, recentMemories: recentMemories, insightOverview: insightOverview));
    }
  }

  /// 成功拉取后台数据后写入 Hive。
  Future<void> _persistHomeOverviewCache(MPGetHomeOverviewResponse response) async {
    try {
      final Map<String, dynamic> json = response.toJson();
      await MPHiveUtil.instance.putMap(key: _kHomeOverviewHiveKey, value: json);
    } catch (e, stackTrace) {
      debugPrint('MPHomeCubit: persist home overview Hive failed — $e\n$stackTrace');
    }
  }

  /// 列表为空时尝试用 Hive 缓存先刷新界面。
  Future<void> _tryEmitCachedOverviewWhenEmpty() async {
    if (!_isHomeMainListsEmpty(state)) {
      return;
    }
    try {
      final Map<String, dynamic>? cached = await MPHiveUtil.instance.getMap(_kHomeOverviewHiveKey);
      if (cached == null || cached.isEmpty) {
        return;
      }
      final MPGetHomeOverviewResponse parsed = MPGetHomeOverviewResponse.fromJson(cached);
      if (parsed.baseResp.code != 0) {
        return;
      }
      _emitFromOverviewResponse(parsed);
    } catch (e, stackTrace) {
      debugPrint('MPHomeCubit: try emit cached overview when empty failed — $e\n$stackTrace');
    }
  }

  /// 拉取首页聚合数据：空列表时先展示 Hive 再请求后台；非空则直接请求后台；成功后更新 Hive。
  Future<void> loadData() async {
    if (_isHomeMainListsEmpty(state)) {
      await _tryEmitCachedOverviewWhenEmpty();
    }
    final MPGetHomeOverviewResponse? response = await getHomeOverview(MPGetHomeOverviewRequest());
    if (response != null && response.baseResp.code == 0) {
      _emitFromOverviewResponse(response);
      await _persistHomeOverviewCache(response);
    }
  }

  void start() {
    _insightsTimer?.cancel();
    _insightsTimer = Timer.periodic(Duration(seconds: 60), (_) => _tickInsights());
  }

  Future<void> _tickInsights() async {
    if (!isClosed) {
      final MPGetHomeInsightOverviewResponse? response = await getHomeInsightOverview(
        MPGetHomeInsightOverviewRequest(),
      );
      if (response != null && response.baseResp.code == 0) {
        final MPHomeInsightOverviewStruct insightOverview = response.insightOverview;
        bool shouldUpdate = false;
        if (state.insightOverview.newInsightCount != insightOverview.newInsightCount) {
          shouldUpdate = true;
        }
        if (state.insightOverview.content != insightOverview.content) {
          shouldUpdate = true;
        }
        if (state.insightOverview.title != insightOverview.title) {
          shouldUpdate = true;
        }
        if (state.insightOverview.subTitle != insightOverview.subTitle) {
          shouldUpdate = true;
        }
        if (!isClosed && shouldUpdate) {
          emit(state.copyWith(insightOverview: insightOverview));
        }
      }
    }
  }

  static const MPHomeAudioStatus _kRecordingAudioStatus = MPHomeAudioStatus(type: MPHomeAudioStatusType.recording);

  /// 任意状态 → recording 时立即展示（优先于 importing / syncing）。
  void _emitRecordingAudioStatusPrioritized() {
    _syncCompletedClearTimer?.cancel();
    emit(state.copyWith(audioStatus: _kRecordingAudioStatus));
  }

  /// [MPHomeNotification.listenBleMemopinRecordingState]：设备开始录音 → 顶栏 recording；停录 → 若有推迟的 import/sync 则应用，否则仅当当前为 recording 时隐藏条。
  void _onBleMemopinRecordingStateChanged(MPBleMemopinRecordingStateChangedPayload payload) {
    if (payload.isRecording) {
      _pendingPostBleRecordingAudioStatus = null;
      _deferredRecordCreatedCompletion = null;
      _emitRecordingAudioStatusPrioritized();
      return;
    }
    _flushPendingAfterBleRecordingStopped(payload);
  }

  /// 蓝牙已停录：应用推迟的 importing/syncing，或更新顶栏（仅 [deviceRecordingStopped] 切 syncing）。
  void _flushPendingAfterBleRecordingStopped(MPBleMemopinRecordingStateChangedPayload payload) {
    if (_pendingPostBleRecordingAudioStatus != null) {
      final MPHomeAudioStatus pending = _pendingPostBleRecordingAudioStatus!;
      _pendingPostBleRecordingAudioStatus = null;
      _syncCompletedClearTimer?.cancel();
      emit(state.copyWith(audioStatus: pending));
      if (_deferredRecordCreatedCompletion != null) {
        final MPHomeRecordCreatedPayload p = _deferredRecordCreatedCompletion!;
        _deferredRecordCreatedCompletion = null;
        final int total = p.batchTotal < 1 ? 1 : p.batchTotal;
        final int index = p.batchIndex.clamp(1, total);
        if (index >= total) {
          _syncCompletedClearTimer = Timer(const Duration(milliseconds: 1600), () {
            if (!isClosed) {
              emit(state.copyWith(clearAudioStatus: true));
              loadData();
            }
          });
        }
      }
      return;
    }
    _deferredRecordCreatedCompletion = null;
    if (state.audioStatus?.type != MPHomeAudioStatusType.recording) {
      return;
    }
    if (payload.changeReason == MPBleMemopinRecordingChangeReason.deviceRecordingStopped) {
      // 仅设备 303 停录成功：切 syncing，由后续 uploadRecords 更新进度。
      _syncCompletedClearTimer?.cancel();
      emit(
        state.copyWith(
          audioStatus: const MPHomeAudioStatus(
            type: MPHomeAudioStatusType.syncing,
            progress: 0,
            currentFile: 1,
            totalFiles: 1,
          ),
        ),
      );
      return;
    }
    emit(state.copyWith(clearAudioStatus: true));
  }

  /// 若外接 MemoPin 正在录音，则暂存 [next]；顶栏 **立即** 切为 recording（覆盖 importing / syncing），直至停录再应用暂存态。
  ///
  /// @returns {bool} `true` 表示已推迟，调用方不应再写入 [next]。
  bool _deferAudioStatusIfMemoPinRecording(MPHomeAudioStatus next) {
    if (!MPBleConnectionHelper.isMemoPinDeviceRecording) {
      return false;
    }
    _pendingPostBleRecordingAudioStatus = next;
    if (state.audioStatus?.type != MPHomeAudioStatusType.recording) {
      _emitRecordingAudioStatusPrioritized();
    }
    return true;
  }

  /// 演示：设备录音中（对齐 react `setRecording`）；日常由 [_onBleMemopinRecordingStateChanged] 驱动。
  void showRecordingStatus() {
    _pendingPostBleRecordingAudioStatus = null;
    _deferredRecordCreatedCompletion = null;
    _emitRecordingAudioStatusPrioritized();
  }

  /// 文件同步：`progress` 为**当前条**上传进度 0–100；多文件时换条后从 0 重新计。
  void showSyncingStatus({required int currentFile, required int totalFiles, required int progress}) {
    final MPHomeAudioStatus next = MPHomeAudioStatus(
      type: MPHomeAudioStatusType.syncing,
      progress: progress.clamp(0, 100),
      currentFile: currentFile,
      totalFiles: totalFiles,
    );
    // 顶栏仍为 recording 或设备侧仍在录：勿提前展示 syncing（避免停录收尾/后台上传误触）。
    if (state.audioStatus?.type == MPHomeAudioStatusType.recording ||
        MPBleConnectionHelper.isMemoPinDeviceRecording) {
      _pendingPostBleRecordingAudioStatus = next;
      return;
    }
    if (_deferAudioStatusIfMemoPinRecording(next)) {
      _deferredRecordCreatedCompletion = null;
      return;
    }
    _syncCompletedClearTimer?.cancel();
    _deferredRecordCreatedCompletion = null;
    emit(state.copyWith(audioStatus: next));
  }

  /// 与 [MPHomeUploadProgressPayload.progress] 一致：单文件 0–100，下一条开始时由上传侧先发 0。
  void _onUploadProgress(MPHomeUploadProgressPayload payload) {
    final int batchTotal = payload.batchTotal < 1 ? 1 : payload.batchTotal;
    final int batchIndex = payload.batchIndex.clamp(1, batchTotal);
    showSyncingStatus(currentFile: batchIndex, totalFiles: batchTotal, progress: payload.progress.clamp(0, 100));
  }

  /// [MPHomeNotification]：本地录音上传并创建 record 成功后收口（最后一条完成后延时清除条）。
  void _onMemoryRecordCreated(MPHomeRecordCreatedPayload payload) {
    _syncCompletedClearTimer?.cancel();
    final int total = payload.batchTotal < 1 ? 1 : payload.batchTotal;
    final int index = payload.batchIndex.clamp(1, total);
    const int progress = 100;
    final MPHomeAudioStatus next = MPHomeAudioStatus(
      type: MPHomeAudioStatusType.syncing,
      progress: progress.clamp(0, 100),
      currentFile: index,
      totalFiles: total,
    );
    if (_deferAudioStatusIfMemoPinRecording(next)) {
      _deferredRecordCreatedCompletion = index >= total ? payload : null;
      return;
    }
    _deferredRecordCreatedCompletion = null;
    emit(state.copyWith(audioStatus: next));
    if (index >= total) {
      _syncCompletedClearTimer = Timer(const Duration(milliseconds: 1600), () {
        if (!isClosed) {
          emit(state.copyWith(clearAudioStatus: true));
          loadData();
        }
      });
    }
  }

  /// 导入音频（复制到沙盒阶段）；多选时 [currentFile] / [totalFiles] 为当前第几个文件与总个数。
  void showImportingStatus(int progress, {int? currentFile, int? totalFiles}) {
    final MPHomeAudioStatus next = MPHomeAudioStatus(
      type: MPHomeAudioStatusType.importing,
      progress: progress.clamp(0, 100),
      currentFile: currentFile,
      totalFiles: totalFiles,
    );
    if (_deferAudioStatusIfMemoPinRecording(next)) {
      _deferredRecordCreatedCompletion = null;
      return;
    }
    _deferredRecordCreatedCompletion = null;
    emit(state.copyWith(audioStatus: next));
  }

  void clearAudioStatus() {
    emit(state.copyWith(clearAudioStatus: true));
  }

  /// 外部页面触发首页刷新通知后，重新拉取首页聚合数据。
  ///
  /// @returns {void}
  void _onHomeListRefresh() {
    loadData();
  }

  /// [MPHomeNotification.notifyBleConnectedSuccess]：后台 BLE 就绪后按 [MPBleFileUtil.syncDeviceOpusTxtToSandboxRegisterAndUpload] 拉设备 Opus/同名 Txt → 转 MP3 → 上传并删设备端 Opus/同名 Txt。
  Future<void> _onBleConnectedSuccess() async {
    if (_bleDeviceImportRunning || isClosed) {
      return;
    }
    final BleTransport? transport = MPBleConnectionHelper.backgroundBleTransport;
    if (transport == null) {
      debugPrint('MPHomeCubit: Bluetooth session unavailable.');
      return;
    }
    _bleDeviceImportRunning = true;
    try {
      debugPrint('MPHomeCubit: Bluetooth connected. Starting device import...');
      if (!isClosed) {
        emit(state.copyWith(isBleConnected: true));
      }
      await MPBleFileUtil.syncDeviceOpusTxtToSandboxRegisterAndUpload(
        transport: transport,
        onSyncProgress: ({required int fileIndex, required int fileTotal, required int progressPercent}) {
          if (!isClosed) {
            showImportingStatus(progressPercent, currentFile: fileIndex, totalFiles: fileTotal);
          }
        },
      );
    } catch (e) {
      debugPrint('MPHomeCubit: device import error: $e');
    } finally {
      _bleDeviceImportRunning = false;
      if (!isClosed) {
        await refreshBleConnectionState();
        if (state.audioStatus?.type == MPHomeAudioStatusType.importing) {
          emit(state.copyWith(clearAudioStatus: true));
        }
      }
    }
  }

  /// 收到 todo 完成通知后，首页 Up Next 直接移除对应项。
  ///
  /// @param {MPHomeTodoDonePayload} payload
  /// @returns {void}
  void _onTodoDone(MPHomeTodoDonePayload payload) {
    final String todoId = payload.todoId.trim();
    if (todoId.isEmpty) {
      return;
    }
    final List<MPHomeTodoItem> next = state.upNextTodos
        .where((MPHomeTodoItem e) => e.id.trim() != todoId)
        .toList(growable: false);
    if (next.length == state.upNextTodos.length) {
      return;
    }
    emit(state.copyWith(upNextTodos: next));
  }

  /// 收到 todo 删除通知后，首页 Up Next 直接移除对应项。
  ///
  /// @param {MPHomeTodoDeletedPayload} payload
  /// @returns {void}
  void _onTodoDeleted(MPHomeTodoDeletedPayload payload) {
    final String todoId = payload.todoId.trim();
    if (todoId.isEmpty) {
      return;
    }
    final List<MPHomeTodoItem> next = state.upNextTodos
        .where((MPHomeTodoItem e) => e.id.trim() != todoId)
        .toList(growable: false);
    if (next.length == state.upNextTodos.length) {
      return;
    }
    emit(state.copyWith(upNextTodos: next));
  }

  @override
  Future<void> close() {
    _insightsTimer?.cancel();
    _insightsTimer = null;
    _syncCompletedClearTimer?.cancel();
    _syncCompletedClearTimer = null;
    _recordCreatedSub?.cancel();
    _uploadProgressSub?.cancel();
    _homeListRefreshSub?.cancel();
    _todoDoneSub?.cancel();
    _todoDeletedSub?.cancel();
    _bleConnectedSub?.cancel();
    _bleMemopinRecordingSub?.cancel();
    return super.close();
  }
}
