import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/audio/record/mp_audio_local_records_util.dart';
import 'package:memo_pin/audio/record/mp_audio_upload_manger.dart';
import 'package:memo_pin/audio/record/mp_home_audio_task_queue.dart';
import 'package:memo_pin/blu/mp_ble_file_util.dart';
import 'package:memo_pin/cache/mp_hive_util.dart';
import 'package:memo_pin/blu/mp_ble_transport.dart';
import 'package:memo_pin/blu/mp_ble_connection_helper.dart';
import 'package:memo_pin/common/mp_home_notification.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';

import '../../../common/mp_date_utils.dart';
import '../../../http/api/mp_home.dart' as mp_home_api;
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
    required this.transcriptionBanner,
    required this.isBleConnected,
    this.audioStatus,
  });

  final List<MPHomeTodoItem> upNextTodos;
  final List<MPHomeMemoryItem> recentMemories;

  /// Insights 卡片角标（动态演示）
  final MPHomeInsightOverviewStruct insightOverview;

  /// 转录用量提示卡片（首页 `transcription_banner`）。
  final MPTranscriptionBannerStruct transcriptionBanner;

  /// 是否已连接 BLE 设备。
  final bool isBleConnected;

  ///
  final MPHomeAudioStatus? audioStatus;

  MPHomeState copyWith({
    List<MPHomeTodoItem>? upNextTodos,
    List<MPHomeMemoryItem>? recentMemories,
    MPHomeInsightOverviewStruct? insightOverview,
    MPTranscriptionBannerStruct? transcriptionBanner,
    bool? isBleConnected,
    MPHomeAudioStatus? audioStatus,
    bool clearAudioStatus = false,
  }) {
    return MPHomeState(
      upNextTodos: upNextTodos ?? this.upNextTodos,
      recentMemories: recentMemories ?? this.recentMemories,
      insightOverview: insightOverview ?? this.insightOverview,
      transcriptionBanner: transcriptionBanner ?? this.transcriptionBanner,
      isBleConnected: isBleConnected ?? this.isBleConnected,
      audioStatus: clearAudioStatus ? null : (audioStatus ?? this.audioStatus),
    );
  }
}

/// 首页：Today's Focus / Recent Memory / Insights / 顶部状态条（mock + 定时刷新）
class MPHomeCubit extends Cubit<MPHomeState> {
  MPHomeCubit() : super(_initialState()) {
    _audioTaskBarSub = MPHomeNotification.listenAudioTaskBar(_onAudioTaskBar);
    _uploadFailedSub = MPHomeNotification.listenUploadFailed(_onUploadFailed);
    _homeListRefreshSub = MPHomeNotification.listenHomeListRefresh(_onHomeListRefresh);
    _todoDoneSub = MPHomeNotification.listenTodoDone(_onTodoDone);
    _todoDeletedSub = MPHomeNotification.listenTodoDeleted(_onTodoDeleted);
    _bleConnectedSub = MPHomeNotification.listenBleConnectedSuccess(_onBleConnectedSuccess);
    _bleDisconnectedSub = MPHomeNotification.listenBleDisconnected(_onBleDisconnected);
    _bleMemopinRecordingSub = MPHomeNotification.listenBleMemopinRecordingState(_onBleMemopinRecordingStateChanged);
    initData();
  }

  Timer? _insightsTimer;
  StreamSubscription<MPHomeAudioTaskBarPayload>? _audioTaskBarSub;
  StreamSubscription<MPHomeUploadFailedPayload>? _uploadFailedSub;
  StreamSubscription<void>? _homeListRefreshSub;
  StreamSubscription<MPHomeTodoDonePayload>? _todoDoneSub;
  StreamSubscription<MPHomeTodoDeletedPayload>? _todoDeletedSub;
  StreamSubscription<void>? _bleConnectedSub;
  StreamSubscription<void>? _bleDisconnectedSub;
  StreamSubscription<MPBleMemopinRecordingStateChangedPayload>? _bleMemopinRecordingSub;

  /// 断连时若顶栏为「录音」，则忽略后续上传进度（避免误展示上传条）。
  bool _suppressBleUploadStatusAfterDisconnect = false;

  /// 外接 MemoPin 仍在录音时，将本应展示为 importing/syncing 的状态暂存，待停录后再 [emit]（见 [_onBleMemopinRecordingStateChanged]）。
  MPHomeAudioStatus? _pendingPostBleRecordingAudioStatus;

  Timer? _syncCompletedClearTimer;
  bool _bleDeviceImportRunning = false;

  /// 因设备正在录音而推迟的批量导入；停录后自动补跑。
  bool _pendingDeviceImportAfterRecordingStop = false;

  /// 本地待传音频批量上传任务是否仍在执行（含冷/热启动触发的队列上传）。
  bool _pendingLocalAudioUploadRunning = false;

  /// 是否正在拉取首页聚合数据，避免并发重复请求。
  bool _isLoadingData = false;

  static MPHomeState _initialState() {
    return MPHomeState(
      upNextTodos: const <MPHomeTodoItem>[],
      recentMemories: const <MPHomeMemoryItem>[],
      insightOverview: MPHomeInsightOverviewStruct(title: '', subTitle: '', newInsightCount: 0, content: ''),
      transcriptionBanner: MPTranscriptionBannerStruct(
        bannerId: 0,
        threshold: 0,
        currentMinutes: 0,
        showBanner: false,
        bannerContent: '',
      ),
      isBleConnected: false,
    );
  }

  void initData() {
    connectBluetoothToLastRecordedDevice();
    loadData();
    unawaited(_uploadPendingLocalAudioFilesIfNeeded(isHotStart: false));
  }

  /// 应用回到前台（热启动）：刷新首页数据，并检测本地待传音频。
  void onAppResumed({required bool shouldRefreshHomeData}) {
    if (shouldRefreshHomeData) {
      loadData();
    }
    unawaited(_uploadPendingLocalAudioFilesIfNeeded(isHotStart: true));
  }

  /// 是否正在同步设备文件或上传本地音频（热启动时用于跳过重复检测上传）。
  bool _isSyncOrUploadInProgress() {
    if (_bleDeviceImportRunning || _pendingLocalAudioUploadRunning) {
      return true;
    }
    if (MPHomeAudioTaskQueue.instance.hasImportTasks || MPHomeAudioTaskQueue.instance.hasUploadSession) {
      return true;
    }
    if (MPAudioUploadManager.instance.hasActiveUploads) {
      return true;
    }
    final MPHomeAudioStatusType? type = state.audioStatus?.type;
    return type == MPHomeAudioStatusType.syncing || type == MPHomeAudioStatusType.importing;
  }

  /// 检测本地待传音频队列，有则上传；热启动时若已在同步/上传则跳过。
  Future<void> _uploadPendingLocalAudioFilesIfNeeded({required bool isHotStart}) async {
    if (isHotStart && _isSyncOrUploadInProgress()) {
      debugPrint('MPHomeCubit: skip pending local audio upload on hot start — sync/upload in progress');
      return;
    }
    try {
      _pendingLocalAudioUploadRunning = true;
      await MPHomeAudioTaskQueue.instance.seedPendingUploadsFromLocal();
    } catch (e, st) {
      debugPrint(
        'MPHomeCubit: upload pending local audio failed (hotStart=$isHotStart): $e\n$st',
      );
    } finally {
      _pendingLocalAudioUploadRunning = false;
    }
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
          time: MPDateUtils.formatHomeItemTimeFromShowTime(e.showTime),
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
        final int? ts = MPDateUtils.resolveTimestampFromShowTime(
          e.showTime,
          fallbackUnix: e.createAt,
        );
        final String date = MPDateUtils.formatDeadlineLineText(ts);
        titleOrDate = '$date file';
      }
      recentMemories.add(
        MPHomeMemoryItem(
          id: e.id ?? '',
          titleOrDate: titleOrDate,
          timeLabel: MPDateUtils.formatHomeItemTimeFromShowTime(e.showTime),
          createAt: e.createAt,
          type: e.type ?? MPMemoryType.onlyRecord,
        ),
      );
    }
    final MPHomeInsightOverviewStruct insightOverview = response.insightOverview;
    final MPTranscriptionBannerStruct transcriptionBanner = response.transcriptionBanner;
    if (!isClosed) {
      emit(
        state.copyWith(
          upNextTodos: upNextTodos,
          recentMemories: recentMemories,
          insightOverview: insightOverview,
          transcriptionBanner: transcriptionBanner,
        ),
      );
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

  /// 关闭转录用量提示卡片；接口成功后隐藏卡片并同步 Hive 缓存。
  Future<void> closeTranscriptionBanner() async {
    final MPTranscriptionBannerStruct banner = state.transcriptionBanner;
    if (!banner.showBanner || banner.bannerId == 0) {
      return;
    }
    final MPCloseTranscriptionBannerResponse? response = await mp_home_api.closeTranscriptionBanner(
      MPCloseTranscriptionBannerRequest(bannerId: banner.bannerId),
    );
    if (response == null || response.baseResp.code != 0 || isClosed) {
      return;
    }
    emit(
      state.copyWith(
        transcriptionBanner: MPTranscriptionBannerStruct(
          bannerId: banner.bannerId,
          threshold: banner.threshold,
          currentMinutes: banner.currentMinutes,
          showBanner: false,
          bannerContent: banner.bannerContent,
        ),
      ),
    );
    await _persistTranscriptionBannerDismissed();
  }

  /// 将 Hive 中缓存的转录提示标记为已关闭。
  Future<void> _persistTranscriptionBannerDismissed() async {
    try {
      final Map<String, dynamic>? cached = await MPHiveUtil.instance.getMap(_kHomeOverviewHiveKey);
      if (cached == null || cached.isEmpty) {
        return;
      }
      final Map<String, dynamic> next = Map<String, dynamic>.from(cached);
      final Map<String, dynamic> banner = Map<String, dynamic>.from(
        next['transcription_banner'] as Map<String, dynamic>? ?? <String, dynamic>{},
      );
      banner['show_banner'] = false;
      next['transcription_banner'] = banner;
      await MPHiveUtil.instance.putMap(key: _kHomeOverviewHiveKey, value: next);
    } catch (e, stackTrace) {
      debugPrint('MPHomeCubit: persist transcription banner dismissed failed — $e\n$stackTrace');
    }
  }

  /// 拉取首页聚合数据：空列表时先展示 Hive 再请求后台；非空则直接请求后台；成功后更新 Hive。
  Future<void> loadData() async {
    if (_isLoadingData) {
      return;
    }
    _isLoadingData = true;
    try {
      if (_isHomeMainListsEmpty(state)) {
        await _tryEmitCachedOverviewWhenEmpty();
      }
      final MPGetHomeOverviewResponse? response =
          await mp_home_api.getHomeOverview(MPGetHomeOverviewRequest());
      if (response != null && response.baseResp.code == 0) {
        _emitFromOverviewResponse(response);
        await _persistHomeOverviewCache(response);
      }
    } finally {
      _isLoadingData = false;
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

  static const MPHomeAudioStatus _kImportingPlaceholderStatus = MPHomeAudioStatus(
    type: MPHomeAudioStatusType.importing,
    progress: 0,
    currentFile: 1,
    totalFiles: 1,
  );

  /// 任意状态 → recording 时立即展示（优先于 importing / syncing）。
  void _emitRecordingAudioStatusPrioritized() {
    _syncCompletedClearTimer?.cancel();
    if (!isClosed) {
      emit(state.copyWith(audioStatus: _kRecordingAudioStatus));
    }
  }

  /// 开录时暂停批量导入，并在 cancel 的 clear 之后再次钉住 recording 顶栏。
  Future<void> _pauseImportForDeviceRecording() async {
    await MPBleFileUtil.cancelActiveDeviceSync();
    if (!isClosed && MPBleConnectionHelper.isMemoPinDeviceRecording) {
      _emitRecordingAudioStatusPrioritized();
    }
  }

  /// [MPHomeNotification.listenBleMemopinRecordingState]
  void _onBleMemopinRecordingStateChanged(MPBleMemopinRecordingStateChangedPayload payload) {
    if (payload.isRecording) {
      _emitRecordingAudioStatusPrioritized();
      if (_bleDeviceImportRunning) {
        _pendingDeviceImportAfterRecordingStop = true;
        debugPrint('MPHomeCubit: device recording started, pause batch import');
        unawaited(_pauseImportForDeviceRecording());
      }
      return;
    }

    if (payload.changeReason == MPBleMemopinRecordingChangeReason.bleDisconnected) {
      unawaited(_onRecordingBusBleDisconnected());
      return;
    }

    if (payload.changeReason == MPBleMemopinRecordingChangeReason.watcherDetached) {
      // re-attach 可能触发；仅在设备已非录音时收起 recording 条。
      if (!MPBleConnectionHelper.isMemoPinDeviceRecording &&
          state.audioStatus?.type == MPHomeAudioStatusType.recording &&
          !isClosed) {
        _pendingPostBleRecordingAudioStatus = null;
        _syncCompletedClearTimer?.cancel();
        emit(state.copyWith(clearAudioStatus: true));
      }
      return;
    }

    // 设备停录：立刻切到 importing，再拉文件列表。
    final MPHomeAudioStatus? pending = _pendingPostBleRecordingAudioStatus;
    _pendingPostBleRecordingAudioStatus = null;
    _syncCompletedClearTimer?.cancel();

    if (payload.changeReason == MPBleMemopinRecordingChangeReason.deviceRecordingStopped) {
      _pendingDeviceImportAfterRecordingStop = true;
      if (!isClosed) {
        emit(
          state.copyWith(
            audioStatus: pending?.type == MPHomeAudioStatusType.importing
                ? pending
                : _kImportingPlaceholderStatus,
          ),
        );
      }
      unawaited(_runDeviceFileImport(reason: 'after device recording stopped'));
      return;
    }

    if (pending != null) {
      if (!isClosed) {
        emit(state.copyWith(audioStatus: pending));
      }
      return;
    }
    if (state.audioStatus?.type == MPHomeAudioStatusType.recording && !isClosed) {
      emit(state.copyWith(clearAudioStatus: true));
    }
  }

  /// 录音总线上报的 bleDisconnected：先确认链路真的断了，避免 GATT 繁忙误清 recording。
  Future<void> _onRecordingBusBleDisconnected() async {
    final BleTransport? transport = MPBleConnectionHelper.backgroundBleTransport;
    if (transport != null) {
      try {
        if (await transport.isConnected()) {
          debugPrint('MPHomeCubit: ignore recording-bus disconnect — BLE still connected');
          if (MPBleConnectionHelper.isMemoPinDeviceRecording) {
            _emitRecordingAudioStatusPrioritized();
          }
          return;
        }
      } catch (_) {
        // treat as disconnected
      }
    }
    if (state.audioStatus?.type == MPHomeAudioStatusType.recording) {
      _clearBleTopBarForRecordingDisconnect();
    }
  }

  /// 演示：设备录音中（对齐 react `setRecording`）；日常由 [_onBleMemopinRecordingStateChanged] 驱动。
  void showRecordingStatus() {
    _pendingPostBleRecordingAudioStatus = null;
    _emitRecordingAudioStatusPrioritized();
  }

  /// [MPHomeAudioTaskQueue] 驱动首页 importing / syncing 顶栏。
  void _onAudioTaskBar(MPHomeAudioTaskBarPayload payload) {
    if (_suppressBleUploadStatusAfterDisconnect && payload.kind == MPHomeAudioTaskBarKind.syncing) {
      return;
    }

    if (payload.kind == MPHomeAudioTaskBarKind.clear) {
      _syncCompletedClearTimer?.cancel();
      // 设备录音中 / 顶栏 recording：忽略 cancel 导入带来的 clear。
      if (MPBleConnectionHelper.isMemoPinDeviceRecording ||
          state.audioStatus?.type == MPHomeAudioStatusType.recording) {
        debugPrint('MPHomeCubit: ignore task-bar clear while recording');
        return;
      }
      // 导入进行中或队列仍有任务：忽略迟到 clear。
      if (_bleDeviceImportRunning ||
          MPHomeAudioTaskQueue.instance.hasImportTasks ||
          MPHomeAudioTaskQueue.instance.hasUploadSession) {
        debugPrint('MPHomeCubit: ignore stale task-bar clear while import/upload active');
        return;
      }
      if (!isClosed && state.audioStatus != null) {
        emit(state.copyWith(clearAudioStatus: true));
        loadData();
      }
      return;
    }

    final MPHomeAudioStatusType type = payload.kind == MPHomeAudioTaskBarKind.importing
        ? MPHomeAudioStatusType.importing
        : MPHomeAudioStatusType.syncing;
    final MPHomeAudioStatus next = MPHomeAudioStatus(
      type: type,
      progress: payload.progress.clamp(0, 100),
      currentFile: payload.currentFile,
      totalFiles: payload.totalFiles,
    );

    if (MPBleConnectionHelper.isMemoPinDeviceRecording) {
      _pendingPostBleRecordingAudioStatus = next;
      _emitRecordingAudioStatusPrioritized();
      return;
    }

    _syncCompletedClearTimer?.cancel();
    if (!isClosed) {
      emit(state.copyWith(audioStatus: next));
    }

    if (payload.scheduleClearAfterDisplay) {
      _scheduleSyncingStatusBarClear();
    }
  }

  /// 批量上传失败：Toast 展示具体错误（含网络类）。
  void _onUploadFailed(MPHomeUploadFailedPayload payload) {
    final int batchTotal = payload.batchTotal < 1 ? 1 : payload.batchTotal;
    final int batchIndex = payload.batchIndex.clamp(1, batchTotal);
    final String detail = payload.message?.trim().isNotEmpty == true
        ? payload.message!.trim()
        : 'Upload failed.';
    final String toast = batchTotal > 1 ? 'File $batchIndex/$batchTotal: $detail' : detail;
    MPToastUtils.showMessage(toast);
  }

  /// 上传完成态展示约 1.6s 后清除顶栏并刷新列表。
  void _scheduleSyncingStatusBarClear() {
    _syncCompletedClearTimer?.cancel();
    _syncCompletedClearTimer = Timer(const Duration(milliseconds: 1600), () {
      if (isClosed) {
        return;
      }
      if (state.audioStatus?.type == MPHomeAudioStatusType.recording ||
          MPBleConnectionHelper.isMemoPinDeviceRecording) {
        return;
      }
      if (_bleDeviceImportRunning ||
          MPHomeAudioTaskQueue.instance.hasImportTasks ||
          MPHomeAudioTaskQueue.instance.hasUploadSession) {
        return;
      }
      emit(state.copyWith(clearAudioStatus: true));
      loadData();
    });
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

  /// 录音中断连：顶栏消失，且不再响应上传进度。
  void _clearBleTopBarForRecordingDisconnect() {
    _suppressBleUploadStatusAfterDisconnect = true;
    _pendingPostBleRecordingAudioStatus = null;
    _syncCompletedClearTimer?.cancel();
    if (!isClosed) {
      emit(
        state.copyWith(
          isBleConnected: false,
          clearAudioStatus: true,
        ),
      );
    }
  }

  /// [MPHomeNotification.notifyBleDisconnected]：按当前顶栏状态处理断连。
  void _onBleDisconnected() {
    unawaited(_handleBleDisconnected());
  }

  Future<void> _handleBleDisconnected() async {
    final BleTransport? transport = MPBleConnectionHelper.backgroundBleTransport;
    if (transport != null) {
      try {
        if (await transport.isConnected()) {
          debugPrint('MPHomeCubit: ignore bleDisconnected notify — BLE still connected');
          if (MPBleConnectionHelper.isMemoPinDeviceRecording) {
            _emitRecordingAudioStatusPrioritized();
          }
          return;
        }
      } catch (_) {
        // treat as disconnected
      }
    }

    final MPHomeAudioStatusType? statusType = state.audioStatus?.type;

    if (statusType == MPHomeAudioStatusType.syncing) {
      _pendingPostBleRecordingAudioStatus = null;
      if (!isClosed) {
        emit(state.copyWith(isBleConnected: false));
      }
      return;
    }

    if (statusType == MPHomeAudioStatusType.importing) {
      MPHomeAudioTaskQueue.instance.cancelAllImportTasks();
      _pendingPostBleRecordingAudioStatus = null;
      _syncCompletedClearTimer?.cancel();
      final List<MPAudioLocalRecord> toUpload = MPBleFileUtil.takePendingUploadAfterAbort();
      if (!isClosed) {
        emit(state.copyWith(isBleConnected: false, clearAudioStatus: true));
      }
      if (toUpload.isNotEmpty) {
        await MPHomeAudioTaskQueue.instance.enqueueImportedRecordsForUpload(toUpload);
      }
      return;
    }

    _clearBleTopBarForRecordingDisconnect();
  }

  /// 将 [MPBleRecordingWatcher] 当前录音快照同步到首页顶栏（连接成功时兜底）。
  void _syncBleRecordingTopBarFromSnapshot() {
    if (MPBleConnectionHelper.isMemoPinDeviceRecording) {
      _pendingPostBleRecordingAudioStatus = null;
      _emitRecordingAudioStatusPrioritized();
    }
  }

  /// [MPHomeNotification.notifyBleConnectedSuccess]：录音探测结束后，若未在录音则按
  /// [MPBleFileUtil.syncDeviceOpusTxtToSandboxRegisterAndUpload] 拉设备 Opus/同名 Txt → 转 MP3 → 上传
  ///（设备端文件删除已暂停）。
  Future<void> _onBleConnectedSuccess() async {
    final BleTransport? transport = MPBleConnectionHelper.backgroundBleTransport;
    if (transport == null) {
      debugPrint('MPHomeCubit: Bluetooth session unavailable.');
      return;
    }
    _suppressBleUploadStatusAfterDisconnect = false;
    if (!isClosed) {
      emit(state.copyWith(isBleConnected: true));
    }
    await MPBleConnectionHelper.waitForRecordingConnectProbe();
    _syncBleRecordingTopBarFromSnapshot();
    if (MPBleConnectionHelper.isMemoPinDeviceRecording) {
      _pendingDeviceImportAfterRecordingStop = true;
      debugPrint('MPHomeCubit: device is recording, skip batch import until stop');
      return;
    }
    await _runDeviceFileImport(reason: 'ble connected');
  }

  /// 批量导入设备 Opus/Txt；录音中则推迟到停录后再跑。
  Future<void> _runDeviceFileImport({required String reason}) async {
    if (isClosed) {
      return;
    }
    if (MPBleConnectionHelper.isMemoPinDeviceRecording) {
      _pendingDeviceImportAfterRecordingStop = true;
      debugPrint('MPHomeCubit: defer device import ($reason) — still recording');
      return;
    }
    // 上一轮导入尚未退出时只挂起，待 finally 再跑，避免直接吞掉停录后的导入。
    if (_bleDeviceImportRunning) {
      _pendingDeviceImportAfterRecordingStop = true;
      debugPrint('MPHomeCubit: defer device import ($reason) — prior import still running');
      return;
    }
    final BleTransport? transport = MPBleConnectionHelper.backgroundBleTransport;
    if (transport == null) {
      debugPrint('MPHomeCubit: device import skipped ($reason) — no transport');
      return;
    }
    try {
      if (!await transport.isConnected()) {
        debugPrint('MPHomeCubit: device import skipped ($reason) — not connected');
        return;
      }
    } catch (_) {
      debugPrint('MPHomeCubit: device import skipped ($reason) — isConnected check failed');
      return;
    }

    _bleDeviceImportRunning = true;
    _pendingDeviceImportAfterRecordingStop = false;
    _syncCompletedClearTimer?.cancel();
    // 拉列表前先占住 importing 顶栏，避免中间被 clear 成空白。
    if (!isClosed && state.audioStatus?.type != MPHomeAudioStatusType.importing) {
      emit(state.copyWith(audioStatus: _kImportingPlaceholderStatus));
    }
    try {
      debugPrint('MPHomeCubit: Starting device import ($reason)...');
      await MPBleFileUtil.syncDeviceOpusTxtToSandboxRegisterAndUpload(
        transport: transport,
        onSyncProgress: ({required int fileIndex, required int fileTotal, required int progressPercent}) {},
      );
    } catch (e) {
      debugPrint('MPHomeCubit: device import error ($reason): $e');
    } finally {
      _bleDeviceImportRunning = false;
      // 设备无文件可导入时，收起占位 importing，避免顶栏一直挂着。
      if (!isClosed &&
          state.audioStatus?.type == MPHomeAudioStatusType.importing &&
          !MPHomeAudioTaskQueue.instance.hasImportTasks &&
          !MPHomeAudioTaskQueue.instance.hasUploadSession) {
        emit(state.copyWith(clearAudioStatus: true));
      }
      if (!isClosed) {
        await refreshBleConnectionState();
      }
      if (_pendingDeviceImportAfterRecordingStop &&
          !isClosed &&
          !MPBleConnectionHelper.isMemoPinDeviceRecording) {
        unawaited(_runDeviceFileImport(reason: 'pending after prior import'));
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
    _audioTaskBarSub?.cancel();
    _uploadFailedSub?.cancel();
    _homeListRefreshSub?.cancel();
    _todoDoneSub?.cancel();
    _todoDeletedSub?.cancel();
    _bleConnectedSub?.cancel();
    _bleDisconnectedSub?.cancel();
    _bleMemopinRecordingSub?.cancel();
    return super.close();
  }
}
