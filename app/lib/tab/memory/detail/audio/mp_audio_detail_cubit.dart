import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:omi/audio/mp_local_records_util.dart';
import 'package:omi/utils/mp_toast_utils.dart';
import 'package:omi/http/api/mp_memory.dart';
import 'package:omi/http/schema/mp_data_model.dart';
import 'package:omi/http/schema/mp_memory.dart';

import '../memory/card/mp_memory_generate_summary_sheet.dart';

enum MPAudioDetailPhase { loading, error, loaded }

class MPAudioDetailData {
  const MPAudioDetailData({
    required this.title,
    required this.subtitle,
    required this.leftTime,
    required this.rightTime,
    required this.total,
    this.recordFile,
    this.recordUri,
  });

  final String title;
  final String subtitle;
  final String leftTime;
  final String rightTime;
  final Duration total;

  /// [MPOnlyRecordMemoryStruct.record_file]，供后续播放器使用。
  final String? recordFile;

  /// [MPOnlyRecordMemoryStruct.record_uri]
  final String? recordUri;
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

/// Audio 详情页 Cubit：拉取 [getMemoryDetail]，展示数据来自 [MPMemoryStruct.onlyRecordMemory]（JSON `only_record_content`）。
class MPAudioDetailCubit extends Cubit<MPAudioDetailState> {
  MPAudioDetailCubit({required this.memoryId})
    : super(const MPAudioDetailState(phase: MPAudioDetailPhase.loading)) {
    _playerStateSub = _audioPlayer.playerStateStream.listen((PlayerState ps) {
      if (ps.processingState == ProcessingState.completed) {
        _stopTimer();
        emit(state.copyWith(isPlaying: false, progress: 1));
      }
    });
  }

  final String memoryId;

  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;
  String? _playingLocalPath;

  Future<void> initData() => load();

  Future<void> load() async {
    emit(const MPAudioDetailState(phase: MPAudioDetailPhase.loading));
    try {
      final MPGetMemoryV2DetailResponse? resp = await getMemoryDetail(
        MPGetMemoryV2DetailRequest(memoryId: memoryId),
      );
      if (resp == null) {
        throw StateError('getMemoryDetail failed');
      }
      final MPMemoryStruct m = resp.memoryDetail;
      final MPOnlyRecordMemoryStruct? only = m.onlyRecordContent;
      if (only == null) {
        throw StateError('only_record_content is empty');
      }
      final MPAudioDetailData data = _mapOnlyRecordToAudioData(m, only);
      emit(MPAudioDetailState(phase: MPAudioDetailPhase.loaded, data: data));
    } catch (e) {
      emit(
        MPAudioDetailState(
          phase: MPAudioDetailPhase.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> retry() => load();

  Future<void> onPlayTap() async {
    if (state.phase != MPAudioDetailPhase.loaded) return;
    final bool next = !state.isPlaying;
    if (!next) {
      await _audioPlayer.pause();
      _stopTimer();
      emit(state.copyWith(isPlaying: false));
      return;
    }

    final String? localPath = await _ensurePlayableLocalPath();
    if (localPath == null || localPath.isEmpty) {
      MPToastUtils.showMessage('音频下载失败，请稍后重试');
      return;
    }
    try {
      if (_playingLocalPath != localPath) {
        await _audioPlayer.setFilePath(localPath);
        _playingLocalPath = localPath;
      }
      await _audioPlayer.play();
    } catch (_) {
      MPToastUtils.showMessage('音频播放失败');
      return;
    }

    double p = state.progress;
    if (p >= 1) {
      p = 0;
    }
    emit(state.copyWith(isPlaying: true, progress: p));
    _startTimer();
  }

  Future<String?> _ensurePlayableLocalPath() async {
    final MPAudioDetailData? data = state.data;
    if (data == null) {
      return null;
    }
    final String recordFile = (data.recordFile ?? '').trim();
    if (recordFile.isEmpty) {
      return null;
    }

    final String? localPath = await MPLocalRecordsUtil.instance.getLocalRecordPath(
      recordFile,
    );
    if (localPath != null && localPath.isNotEmpty) {
      return localPath;
    }

    final String? downloadUrl = _resolveRecordDownloadUrl(
      recordFile: recordFile,
      recordUri: (data.recordUri ?? '').trim(),
    );
    if (downloadUrl == null) {
      return null;
    }

    return _downloadRecordToLocal(
      downloadUrl: downloadUrl,
      recordFile: recordFile,
      total: data.total,
    );
  }

  String? _resolveRecordDownloadUrl({
    required String recordFile,
    required String recordUri,
  }) {
    final Uri? recordFileUri = Uri.tryParse(recordFile);
    if (recordFileUri != null &&
        recordFileUri.hasScheme &&
        recordFileUri.host.isNotEmpty) {
      return recordFile;
    }
    final Uri? recordUriParsed = Uri.tryParse(recordUri);
    if (recordUriParsed != null &&
        recordUriParsed.hasScheme &&
        recordUriParsed.host.isNotEmpty) {
      return recordFileUri == null
          ? recordUri
          : recordUriParsed.resolveUri(recordFileUri).toString();
    }
    return null;
  }

  Future<String?> _downloadRecordToLocal({
    required String downloadUrl,
    required String recordFile,
    required Duration total,
  }) async {
    try {
      final Uri uri = Uri.parse(downloadUrl);
      final http.Response response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final Directory docs = await getApplicationDocumentsDirectory();
      final Directory audioDir = Directory('${docs.path}/mp_audio_records');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      final String sourceForId =
          recordFile.isNotEmpty ? recordFile : downloadUrl;
      String fileId = MPLocalRecordsUtil.getFileIdFromUrl(sourceForId).trim();
      if (fileId.isEmpty) {
        fileId = DateTime.now().millisecondsSinceEpoch.toString();
      }
      String ext = '.m4a';
      final String path = uri.path;
      final int dot = path.lastIndexOf('.');
      if (dot > 0 && dot < path.length - 1) {
        ext = path.substring(dot);
      }
      final String filePath =
          '${audioDir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileId$ext';
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes, flush: true);

      await MPLocalRecordsUtil.instance.loadLocalRecords();
      await MPLocalRecordsUtil.instance.addLocalRecord(
        filePath,
        duration: total.inSeconds > 0 ? total.inSeconds : null,
        source: 'mp',
        createAt: DateTime.now().millisecondsSinceEpoch,
        fileId: fileId,
      );
      return filePath;
    } catch (_) {
      return null;
    }
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
    _playerStateSub?.cancel();
    _audioPlayer.dispose();
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

DateTime _audioDetailDateTime(int raw) {
  if (raw > 10000000000) {
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }
  return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
}

String _formatDurationLabel(int? seconds) {
  if (seconds == null || seconds <= 0) {
    return '0s';
  }
  final int m = seconds ~/ 60;
  final int s = seconds % 60;
  if (m > 60) {
    final int h = m ~/ 60;
    final int mm = m % 60;
    return '${h}h${mm}m${s}s';
  }
  if (m > 0) {
    return '${m}m${s}s';
  }
  return '${s}s';
}

MPAudioDetailData _mapOnlyRecordToAudioData(
  MPMemoryStruct m,
  MPOnlyRecordMemoryStruct only,
) {
  final DateTime dt = _audioDetailDateTime(m.createAt);
  final String title = DateFormat('MMM d, y, h:mm a').format(dt);
  final String longDate =
      '${DateFormat('MMMM d, y').format(dt)} at ${DateFormat('h:mm a').format(dt)}';
  final String source = (only.source ?? m.source ?? '').trim();
  final String subtitle =
      source.isNotEmpty ? '$longDate  ·  $source' : longDate;

  final int? sec = m.duration;
  final Duration total = Duration(
    seconds: sec != null && sec > 0 ? sec : 0,
  );
  final String rightTime = _formatDurationLabel(sec);

  return MPAudioDetailData(
    title: title,
    subtitle: subtitle,
    leftTime: '0:00',
    rightTime: rightTime,
    total: total,
    recordFile: only.recordFile,
    recordUri: only.recordUri,
  );
}
