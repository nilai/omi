import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/common/omi_add_todo_popup.dart';
import 'package:memo_pin/http/schema/mp_data_model.dart';
import 'package:memo_pin/http/schema/mp_memory.dart';

import '../omi_memory_detail_cubit.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_feed_block.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/omi_memory_action_content.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/omi_memory_overview_content.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_edit_speaker_sheet.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/omi_memory_transcript_content.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/omi_memory_transcript_item.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';

/// 底部分段：Overview / Transcript / Actions
enum MPMemoryDetailSegment { overview, transcript, actions }

/// 详情卡片类型：
/// - [memory]：展示完整区块（含 Generate Resummary 按钮）
/// - [memo]：隐藏 Generate Resummary 按钮
enum MPMemoryDetailCardType { memory, memo }

/// Memory 详情主卡片数据
class MPMemoryDetailCardData {
  const MPMemoryDetailCardData({
    required this.memoryId,
    required this.title,
    required this.metaLine,
    required this.audioTimeStart,
    required this.audioTimeEnd,
    this.recordFile,
    this.recordUri,
    this.waveformHeights,
    required this.speakerLabels,
    required this.overviewText,
    required this.transcriptItems,
    required this.actionItems,
    this.initialSegment = MPMemoryDetailSegment.transcript,
    this.feedBlocks = const <MPMemoryFeedBlock>[],
    this.memoryType,
  });

  /// 与详情接口 [MPMemoryStruct.id] 一致，用于 resummary 等接口。
  final String memoryId;

  final String title;

  /// 与详情接口 [MPMemoryStruct.type] 一致；用于 Todo 弹窗 [MPAddTodoPopupParams.memoryType] 等。
  final MPMemoryType? memoryType;

  /// 一行元信息（含时间与来源等），如 `Yesterday, 4:30 PM • 45m52s • MemoPin`
  final String metaLine;

  final String audioTimeStart;
  final String audioTimeEnd;
  final String? recordFile;
  final String? recordUri;

  /// 波形条高度 0~1，不传则内部生成占位波形
  final List<double>? waveformHeights;

  final List<String> speakerLabels;
  final String overviewText;
  final List<MPMemoryTranscriptItemData> transcriptItems;
  final List<MPMemoryActionItemData> actionItems;

  final MPMemoryDetailSegment initialSegment;

  /// 主卡片下方活动区：顺序与接口 [MPMemoryFeedStruct.feeds] 一致（含 RESUMMARY / Insight / Todos 等，可混合）。
  final List<MPMemoryFeedBlock> feedBlocks;

  MPMemoryDetailCardData copyWith({
    String? memoryId,
    String? title,
    String? metaLine,
    String? audioTimeStart,
    String? audioTimeEnd,
    String? recordFile,
    String? recordUri,
    List<double>? waveformHeights,
    List<String>? speakerLabels,
    String? overviewText,
    List<MPMemoryTranscriptItemData>? transcriptItems,
    List<MPMemoryActionItemData>? actionItems,
    MPMemoryDetailSegment? initialSegment,
    List<MPMemoryFeedBlock>? feedBlocks,
    MPMemoryType? memoryType,
  }) {
    return MPMemoryDetailCardData(
      memoryId: memoryId ?? this.memoryId,
      title: title ?? this.title,
      metaLine: metaLine ?? this.metaLine,
      audioTimeStart: audioTimeStart ?? this.audioTimeStart,
      audioTimeEnd: audioTimeEnd ?? this.audioTimeEnd,
      recordFile: recordFile ?? this.recordFile,
      recordUri: recordUri ?? this.recordUri,
      waveformHeights: waveformHeights ?? this.waveformHeights,
      speakerLabels: speakerLabels ?? this.speakerLabels,
      overviewText: overviewText ?? this.overviewText,
      transcriptItems: transcriptItems ?? this.transcriptItems,
      actionItems: actionItems ?? this.actionItems,
      initialSegment: initialSegment ?? this.initialSegment,
      feedBlocks: feedBlocks ?? this.feedBlocks,
      memoryType: memoryType ?? this.memoryType,
    );
  }
}

/// Memory 详情：标题 + 元信息 + 音频波形 + 说话人 + **底部分段切换**
class MPMemoryDetailContentCard extends StatefulWidget {
  const MPMemoryDetailContentCard({
    super.key,
    required this.data,
    this.onSegmentChanged,
    this.onPlayTap,
    this.onSeekPlay,
    this.onSeekWaveFraction,
    this.isAudioPlaying = false,
    this.showBackground = true,
    this.segmentBodyScrollWithParent = false,
    this.cardType = MPMemoryDetailCardType.memory,
    this.useExternalPlaybackProgress = false,
  });

  final MPMemoryDetailCardData data;

  /// 分段切换回调
  final ValueChanged<MPMemoryDetailSegment>? onSegmentChanged;

  /// 与 [OmiMemoryDetailCubit.onPlayTap] 对齐：成功为 `true`，失败（如未下载到本地）为 `false`。
  final Future<bool> Function()? onPlayTap;

  /// 点击 Transcript 的某一条，跳转到对应时间并播放（若正在播放则仅 seek，不做 pause）。
  final Future<bool> Function(Duration position)? onSeekPlay;

  /// 点击波形：按宽度比例 seek（0..1）。用于接口总时长未解析时仍能对准解码器时长。
  final Future<bool> Function(double fraction)? onSeekWaveFraction;

  /// 外部播放器是否正在播放（用于同步按钮与波形动画）。
  final bool isAudioPlaying;

  final bool showBackground;
  final bool segmentBodyScrollWithParent;
  final MPMemoryDetailCardType cardType;

  /// 为 true 时不使用本地 1s 定时器推进进度；由 [OmiMemoryDetailCubit] 更新 [MPMemoryDetailCardData.audioTimeStart]（播放中可为纯毫秒数字串）与 [audioTimeEnd]。
  final bool useExternalPlaybackProgress;

  @override
  State<MPMemoryDetailContentCard> createState() =>
      _MPMemoryDetailContentCardState();
}

class _MPMemoryDetailContentCardState extends State<MPMemoryDetailContentCard> {
  late MPMemoryDetailSegment _segment;

  /// 是否正在播放（未播放 [Assets.omiPlay]，播放中 [Assets.omiStop]）
  bool _playing = false;

  /// 点击播放后等待 [onPlayTap]（下载 / 解码）完成
  bool _playPreparing = false;
  int? _playingTranscriptIndex;
  Timer? _progressTimer;
  Duration _elapsed = Duration.zero;
  Duration _total = Duration.zero;

  /// 可编辑的 transcript 列表（保存说话人名后更新；与 [MPMemoryDetailCardData.transcriptItems] 同步自父级）
  late List<MPMemoryTranscriptItemData> _transcriptItems;

  /// 可变的 Actions 列表（创建 Todo 成功后对应项变为 [MPMemoryActionItemStatus.created]）
  late List<MPMemoryActionItemData> _actionItems;

  bool get _isMemoCard => widget.cardType == MPMemoryDetailCardType.memo;

  @override
  void initState() {
    super.initState();
    _segment = widget.data.initialSegment;
    _playing = widget.isAudioPlaying;
    _syncDurationFromData(widget.data);
    _transcriptItems = List<MPMemoryTranscriptItemData>.from(
      widget.data.transcriptItems,
    );
    _actionItems = List<MPMemoryActionItemData>.from(widget.data.actionItems);
  }

  @override
  void didUpdateWidget(covariant MPMemoryDetailContentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAudioPlaying != widget.isAudioPlaying) {
      _playing = widget.isAudioPlaying;
      _syncTimerByPlayingState();
      _syncPlayingTranscriptIndexByElapsed();
    }
    if (oldWidget.data.initialSegment != widget.data.initialSegment) {
      _segment = widget.data.initialSegment;
    }
    if (oldWidget.data.audioTimeStart != widget.data.audioTimeStart ||
        oldWidget.data.audioTimeEnd != widget.data.audioTimeEnd ||
        oldWidget.useExternalPlaybackProgress !=
            widget.useExternalPlaybackProgress) {
      _syncDurationFromData(widget.data);
      _scheduleStopPlayingIfExternalPlaybackEnded();
      _syncPlayingTranscriptIndexByElapsed();
    }
    if (oldWidget.data.transcriptItems != widget.data.transcriptItems) {
      _transcriptItems = List<MPMemoryTranscriptItemData>.from(
        widget.data.transcriptItems,
      );
    }
    if (oldWidget.data.actionItems != widget.data.actionItems) {
      _actionItems = List<MPMemoryActionItemData>.from(widget.data.actionItems);
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  List<double> get _heights {
    if (widget.data.waveformHeights != null &&
        widget.data.waveformHeights!.isNotEmpty) {
      return widget.data.waveformHeights!;
    }
    final math.Random r = math.Random(42);
    return List<double>.generate(80, (_) => 0.15 + r.nextDouble() * 0.85);
  }

  bool _isRawElapsedMsString(String s) => RegExp(r'^\d{1,9}$').hasMatch(s);

  /// 外部进度由 [OmiMemoryDetailCubit] 驱动时，自然播完不会走本地暂停分支，需根据进度把 [_playing] 置否以停波形动画。
  void _scheduleStopPlayingIfExternalPlaybackEnded() {
    if (!widget.useExternalPlaybackProgress || !_playing) {
      return;
    }
    if (_total <= Duration.zero) {
      return;
    }
    const int kEndSlackMs = 120;
    if (_elapsed.inMilliseconds < _total.inMilliseconds - kEndSlackMs) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (!widget.useExternalPlaybackProgress || !_playing) {
        return;
      }
      if (_total <= Duration.zero) {
        return;
      }
      if (_elapsed.inMilliseconds < _total.inMilliseconds - kEndSlackMs) {
        return;
      }
      setState(() {
        _playing = false;
      });
    });
  }

  void _syncDurationFromData(MPMemoryDetailCardData data) {
    final String startRaw = data.audioTimeStart.trim();
    if (widget.useExternalPlaybackProgress && _isRawElapsedMsString(startRaw)) {
      _elapsed = Duration(milliseconds: int.tryParse(startRaw) ?? 0);
    } else {
      _elapsed = Duration(seconds: _parseToSeconds(data.audioTimeStart));
    }
    _total = Duration(seconds: _parseToSeconds(data.audioTimeEnd));
    if (_total <= Duration.zero || _elapsed > _total) {
      if (!widget.useExternalPlaybackProgress || _total > Duration.zero) {
        _total = _elapsed;
      }
    }
  }

  Future<void> _togglePlayFromHeader() async {
    if (_playPreparing) {
      return;
    }
    if (_elapsed >= _total && _total > Duration.zero) {
      _elapsed = Duration.zero;
    }

    if (_playing) {
      setState(() {
        _playing = false;
      });
      _syncTimerByPlayingState();
      await widget.onPlayTap?.call();
      return;
    }

    final Future<bool>? fut = widget.onPlayTap?.call();
    if (fut == null) {
      setState(() {
        _playing = true;
        _playingTranscriptIndex ??= _transcriptItems.isNotEmpty ? 0 : null;
      });
      _syncTimerByPlayingState();
      return;
    }

    setState(() {
      _playPreparing = true;
    });
    try {
      final bool ok = await fut;
      if (!mounted) {
        return;
      }
      if (ok) {
        setState(() {
          _playing = true;
          _playingTranscriptIndex ??= _transcriptItems.isNotEmpty ? 0 : null;
        });
        _syncTimerByPlayingState();
      }
    } finally {
      if (mounted) {
        setState(() {
          _playPreparing = false;
        });
      }
    }
  }

  Future<void> _onTranscriptPlayTap(int index) async {
    if (_playPreparing) {
      return;
    }
    final bool isSameIndex = _playingTranscriptIndex == index;
    if (isSameIndex && _playing) {
      setState(() {
        _playing = false;
      });
      _syncTimerByPlayingState();
      await widget.onPlayTap?.call();
      return;
    }

    setState(() {
      final Duration fromTranscript =
          Duration(seconds: _transcriptItems[index].timeSeconds);
      if (fromTranscript <= _total) {
        _elapsed = fromTranscript;
      }
      if (_elapsed >= _total && _total > Duration.zero) {
        _elapsed = Duration.zero;
      }
      _playingTranscriptIndex = index;
      _playing = false;
    });
    _syncTimerByPlayingState();

    // 优先走 seek+play：避免 cubit 的 onPlayTap 在「正在播放」时把播放器 pause 掉。
    final Future<bool>? fut = widget.onSeekPlay != null
        ? widget.onSeekPlay!.call(
            Duration(seconds: _transcriptItems[index].timeSeconds),
          )
        : widget.onPlayTap?.call();
    if (fut == null) {
      setState(() {
        _playing = true;
      });
      _syncTimerByPlayingState();
      return;
    }

    setState(() {
      _playPreparing = true;
    });
    try {
      final bool ok = await fut;
      if (!mounted) {
        return;
      }
      if (ok) {
        setState(() {
          _playing = true;
        });
        _syncTimerByPlayingState();
      }
    } finally {
      if (mounted) {
        setState(() {
          _playPreparing = false;
        });
      }
    }
  }

  void _syncTimerByPlayingState() {
    _progressTimer?.cancel();
    if (widget.useExternalPlaybackProgress) {
      return;
    }
    if (!_playing || _total <= Duration.zero) return;
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) return;
      setState(() {
        if (_elapsed >= _total && _total > Duration.zero) {
          _playing = false;
          timer.cancel();
          return;
        }
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  int _parseToSeconds(String raw) {
    final String t = raw.trim();
    final RegExp hms = RegExp(r'^(\d+):(\d{2}):(\d{2})$');
    final Match? hmsMatch = hms.firstMatch(t);
    if (hmsMatch != null) {
      final int h = int.tryParse(hmsMatch.group(1) ?? '') ?? 0;
      final int m = int.tryParse(hmsMatch.group(2) ?? '') ?? 0;
      final int s = int.tryParse(hmsMatch.group(3) ?? '') ?? 0;
      return h * 3600 + m * 60 + s;
    }
    final RegExp mmss = RegExp(r'^(\d+):(\d{2})$');
    final Match? mmssMatch = mmss.firstMatch(t);
    if (mmssMatch != null) {
      final int m = int.tryParse(mmssMatch.group(1) ?? '') ?? 0;
      final int s = int.tryParse(mmssMatch.group(2) ?? '') ?? 0;
      return m * 60 + s;
    }
    final RegExp ms = RegExp(r'(?:(\d+)m)?\s*(?:(\d+)s)?');
    final Match? msMatch = ms.firstMatch(t);
    if (msMatch != null) {
      final int m = int.tryParse(msMatch.group(1) ?? '') ?? 0;
      final int s = int.tryParse(msMatch.group(2) ?? '') ?? 0;
      if (m > 0 || s > 0) {
        return m * 60 + s;
      }
    }
    return 0;
  }

  String _formatMmSs(Duration value) {
    final int totalSec = value.inSeconds.clamp(0, 359999);
    final int m = totalSec ~/ 60;
    final int s = totalSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  int? _selectedTranscriptIndex() {
    final List<MPMemoryTranscriptItemData> items = _transcriptItems;
    if (items.isEmpty) return null;
    final int nowSec = _elapsed.inSeconds;
    int selected = 0;
    for (int i = 0; i < items.length; i++) {
      final int ts = items[i].timeSeconds;
      if (nowSec >= ts) {
        selected = i;
      } else {
        break;
      }
    }
    return selected;
  }

  /// 播放中：根据当前 [_elapsed] 自动同步正在播放的 transcript index。
  /// 这样播放自然推进到下一段时，列表中的播放/暂停图标会跟随更新。
  void _syncPlayingTranscriptIndexByElapsed() {
    if (!_playing) {
      return;
    }
    if (_playPreparing) {
      return;
    }
    final int? selected = _selectedTranscriptIndex();
    if (selected == null) {
      return;
    }
    if (_playingTranscriptIndex == selected) {
      return;
    }
    setState(() {
      _playingTranscriptIndex = selected;
    });
  }

  Future<void> _onWaveformTapDown(TapDownDetails d, double width) async {
    if (_playPreparing) {
      return;
    }
    if (width <= 0) {
      return;
    }
    final double x = d.localPosition.dx.clamp(0.0, width);
    final double frac = (x / width).clamp(0.0, 1.0);

    if (widget.onSeekWaveFraction != null) {
      setState(() {
        if (_total > Duration.zero) {
          _elapsed = Duration(
            milliseconds: (_total.inMilliseconds * frac).round(),
          );
        } else {
          _elapsed = Duration.zero;
        }
        if (_elapsed >= _total && _total > Duration.zero) {
          _elapsed = Duration.zero;
        }
        _playing = true;
        _syncPlayingTranscriptIndexByElapsed();
      });
      _syncTimerByPlayingState();

      final Future<bool> fut = widget.onSeekWaveFraction!.call(frac);
      setState(() {
        _playPreparing = true;
      });
      try {
        final bool ok = await fut;
        if (!mounted) {
          return;
        }
        if (!ok) {
          setState(() {
            _playing = false;
          });
          _syncTimerByPlayingState();
        }
      } finally {
        if (mounted) {
          setState(() {
            _playPreparing = false;
          });
        }
      }
      return;
    }

    if (_total <= Duration.zero) {
      return;
    }
    final int targetMs = (_total.inMilliseconds * frac).round();
    final Duration target = Duration(milliseconds: targetMs);

    setState(() {
      _elapsed = target;
      if (_elapsed >= _total && _total > Duration.zero) {
        _elapsed = Duration.zero;
      }
      // 点击波形即视为从该位置开始播放
      _playing = true;
      _syncPlayingTranscriptIndexByElapsed();
    });
    _syncTimerByPlayingState();

    final Future<bool>? fut = widget.onSeekPlay?.call(target);
    if (fut == null) {
      return;
    }
    setState(() {
      _playPreparing = true;
    });
    try {
      final bool ok = await fut;
      if (!mounted) {
        return;
      }
      if (!ok) {
        setState(() {
          _playing = false;
        });
        _syncTimerByPlayingState();
      }
    } finally {
      if (mounted) {
        setState(() {
          _playPreparing = false;
        });
      }
    }
  }

  /// 点击某条 transcript 的编辑图标：弹出「Edit Speaker Name」底部弹窗
  Future<void> _onTranscriptEditTap(int index) async {
    final MPMemoryTranscriptItemData item = _transcriptItems[index];
    final MPMemoryEditSpeakerResult? result =
        await showMPMemoryEditSpeakerSheet(
          context: context,
          currentSpeakerName: item.speakerName,
        );
    if (!mounted || result == null) return;
    final String speakerId = (item.speakerId ?? '').trim();
    if (speakerId.isEmpty) {
      return;
    }
    await context.read<OmiMemoryDetailCubit>().updateSpeakerName(
      speakerId: speakerId,
      oldName: item.speakerName,
      newName: result.newName,
      applyToAll: result.applyToAll,
      transcriptItemId: item.id,
    );
  }

  /// Actions 里「Save Todo」后：先调接口，成功则更新本地列表为已创建
  Future<void> _onCreateTodoFromAction(
    int index,
    MPAddTodoPopupResult r,
  ) async {
    // Todo 创建已在 [showMPAddTodoPopup] 内完成；这里只负责更新本地 UI 状态。
    if (!mounted) return;
    if (index < 0 || index >= _actionItems.length) {
      return;
    }
    setState(() {
      final List<MPMemoryActionItemData> next =
          List<MPMemoryActionItemData>.from(_actionItems);
      final MPMemoryActionItemData cur = next[index];
      final String? resolvedId = () {
        final String fromResult = (r.todoId ?? '').trim();
        if (fromResult.isNotEmpty) {
          return fromResult;
        }
        final String existing = (cur.id ?? '').trim();
        return existing.isEmpty ? null : existing;
      }();
      next[index] = cur.copyWith(
        title: r.title.isNotEmpty ? r.title : cur.title,
        status: MPMemoryActionItemStatus.created,
        id: resolvedId,
      );
      _actionItems = next;
    });

    if (!mounted) return;
    context.read<OmiMemoryDetailCubit>().applyActionTodoCreatedToDetailCache(
          actionIndex: index,
          result: r,
        );
    // follow-up todo 创建成功后刷新详情，保证 feed 与状态与服务端对齐。
    unawaited(context.read<OmiMemoryDetailCubit>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    final MPMemoryDetailCardData d = widget.data;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: widget.showBackground ? greenDeepColor : Colors.transparent,
        borderRadius: widget.showBackground ? BorderRadius.circular(16) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            d.title,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t9_18,
              fontWeight: OmiFontWeight.medium,
              color: _isMemoCard ? const Color(0xFF1C1C1E) : Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            d.metaLine,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t4_13,
              fontWeight: OmiFontWeight.regular,
              color: _isMemoCard
                  ? const Color(0xFF8E8E93)
                  : Colors.white.withValues(alpha: 0.75),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  _formatMmSs(_elapsed),
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t4_13,
                    color: _isMemoCard ? const Color(0xFF1C1C1E) : Colors.white,
                    fontWeight: OmiFontWeight.medium,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatMmSs(_total),
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t4_13,
                  color: _isMemoCard ? const Color(0xFF8E8E93) : Colors.white,
                  fontWeight: OmiFontWeight.medium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints c) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (TapDownDetails d) =>
                          _onWaveformTapDown(d, c.maxWidth),
                      child: _WaveformBar(
                        heights: _heights,
                        isPlaying: _playing,
                        useMemoStyle: _isMemoCard,
                        progress: _total.inMilliseconds <= 0
                            ? 0
                            : _elapsed.inMilliseconds / _total.inMilliseconds,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              _PlayButton(
                isPlaying: _playing,
                isLoading: _playPreparing,
                useMemoStyle: _isMemoCard,
                onTap: _togglePlayFromHeader,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'SPEAKERS',
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t3_12,
              fontWeight: OmiFontWeight.medium,
              color: _isMemoCard ? const Color(0xFF8E8E93) : Colors.white,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: d.speakerLabels
                .map(
                  (String s) =>
                      _SpeakerChip(label: s, useMemoStyle: _isMemoCard),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          _SegmentSwitcher(
            selected: _segment,
            useMemoStyle: _isMemoCard,
            onChanged: (MPMemoryDetailSegment v) {
              setState(() => _segment = v);
              widget.onSegmentChanged?.call(v);
            },
          ),
          const SizedBox(height: 12),
          if (widget.segmentBodyScrollWithParent || _segment == MPMemoryDetailSegment.overview)
            _buildSegmentBody()
          else
            SizedBox(height: 330, child: _buildSegmentBody()),
        ],
      ),
    );
  }

  /// 根据 [MPMemoryDetailSegment] 切换：Overview / Transcript / Actions
  Widget _buildSegmentBody() {
    final MPMemoryDetailCardData d = widget.data;
    switch (_segment) {
      case MPMemoryDetailSegment.overview:
        return MPMemoryOverviewContent(
          content: d.overviewText,
          scrollWithParent: widget.segmentBodyScrollWithParent,
          useMemoStyle: _isMemoCard,
        );
      case MPMemoryDetailSegment.transcript:
        final int? selectedIndex = _selectedTranscriptIndex();
        return MPMemoryTranscriptContent(
          items: _transcriptItems,
          isPlaying: _playing,
          playingIndex: _playingTranscriptIndex,
          selectedIndex: selectedIndex,
          onItemEditTap: _onTranscriptEditTap,
          onItemPlayTap: _onTranscriptPlayTap,
          scrollWithParent: widget.segmentBodyScrollWithParent,
          useMemoStyle: _isMemoCard,
        );
      case MPMemoryDetailSegment.actions:
        return MPMemoryActionContent(
          items: _actionItems,
          memoryId: widget.data.memoryId,
          memoryDetail: MPMemoryDetailForTodoPopup(
            title: widget.data.title,
            metaLine: widget.data.metaLine,
          ),
          onCreateTodo: _onCreateTodoFromAction,
          scrollWithParent: widget.segmentBodyScrollWithParent,
          useMemoStyle: _isMemoCard,
        );
    }
  }
}

class _WaveformBar extends StatefulWidget {
  const _WaveformBar({
    required this.heights,
    required this.isPlaying,
    required this.progress,
    required this.useMemoStyle,
  });

  final List<double> heights;
  final bool isPlaying;
  final double progress;
  final bool useMemoStyle;

  @override
  State<_WaveformBar> createState() => _WaveformBarState();
}

class _WaveformBarState extends State<_WaveformBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 480),
        )..addListener(() {
          if (mounted) {
            setState(() {});
          }
        });
    if (widget.isPlaying) {
      _pulse.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _WaveformBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _pulse.repeat();
      } else {
        _pulse.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// [playing] 时按时间与索引做相位偏移，竖条高度起伏模拟电平
  double _barHeight(int index, double maxInnerH) {
    final double base = widget.heights[index].clamp(0.0, 1.0);
    if (!widget.isPlaying) {
      return 4 + base * maxInnerH;
    }
    final double t = _pulse.value * 2 * math.pi;
    final double phase = index * 0.45;
    final double env = 0.28 + 0.72 * (0.5 + 0.5 * math.sin(t + phase));
    return 4 + base * env * maxInnerH;
  }

  @override
  Widget build(BuildContext context) {
    /// Memo 与右侧播放钮同高 44，避免 Row 垂直居中时在条带下方露出透明缝（像底部无背景）。
    final double trackH = widget.useMemoStyle ? 44 : 40;
    return Container(
      height: trackH,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: widget.useMemoStyle
            ? Colors.transparent
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final int n = widget.heights.length;
          if (n == 0) {
            return const SizedBox.shrink();
          }

          /// 波形竖线宽度（逻辑像素）
          const double barW = 0.5;
          final double gap = n > 1
              ? math.max(0.0, (c.maxWidth - n * barW) / (n - 1))
              : 0.0;
          final double maxInnerH = (c.maxHeight - 8).clamp(4.0, 48.0);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (int i = 0; i < n; i++) ...<Widget>[
                if (i > 0) SizedBox(width: gap),
                Builder(
                  builder: (BuildContext context) {
                    final double clamped = widget.progress.clamp(0.0, 1.0);
                    final bool isPlayed = (i + 1) / n <= clamped;
                    return Container(
                      width: barW,
                      height: _barHeight(i, maxInnerH),
                      color: isPlayed
                          ? Colors.black
                          : (widget.useMemoStyle
                                ? const Color(0xFFD0D1D8)
                                : Colors.white),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.useMemoStyle,
    this.onTap,
  });

  final bool isPlaying;
  final bool isLoading;
  final bool useMemoStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor =
        useMemoStyle ? const Color(0xFF1C1C1E) : Colors.white;
    final Widget content = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: useMemoStyle
            ? Colors.white
            : Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        boxShadow: useMemoStyle
            ? const <BoxShadow>[
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: useMemoStyle ? mainTextColor : Colors.white,
                ),
              )
            : OmiImageLoader.localImg(
                isPlaying ? Assets.omiPause : Assets.omiPlay,
                width: 20,
                height: 20,
                color: iconColor,
                fit: BoxFit.contain,
              ),
      ),
    );

    /// Memo 样式不用 [InkWell]，避免水波纹在圆钮底部呈灰底。
    if (useMemoStyle) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isLoading ? null : onTap,
        child: content,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : OmiImageLoader.localImg(
                    isPlaying ? Assets.omiPause : Assets.omiPlay,
                    width: 20,
                    height: 20,
                    color: iconColor,
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ),
    );
  }
}

class _SpeakerChip extends StatelessWidget {
  const _SpeakerChip({required this.label, required this.useMemoStyle});

  final String label;
  final bool useMemoStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: useMemoStyle
              ? const Color(0xFFE5E5EA)
              : Colors.white.withValues(alpha: 0.35),
        ),
        color: useMemoStyle
            ? const Color(0xFFF3F3F6)
            : Colors.white.withValues(alpha: 0.08),
      ),
      child: Text(
        label,
        style: OmiTextStyle.create(
          fontSize: OmiFontSize.t4_13,
          fontWeight: OmiFontWeight.medium,
          color: useMemoStyle ? const Color(0xFF1C1C1E) : Colors.white,
        ),
      ),
    );
  }
}

class _SegmentSwitcher extends StatelessWidget {
  const _SegmentSwitcher({
    required this.selected,
    required this.onChanged,
    required this.useMemoStyle,
  });

  final MPMemoryDetailSegment selected;
  final ValueChanged<MPMemoryDetailSegment> onChanged;
  final bool useMemoStyle;

  static const List<MPMemoryDetailSegment> _tabs = <MPMemoryDetailSegment>[
    MPMemoryDetailSegment.overview,
    MPMemoryDetailSegment.transcript,
    MPMemoryDetailSegment.actions,
  ];

  String _label(MPMemoryDetailSegment s) {
    switch (s) {
      case MPMemoryDetailSegment.overview:
        return 'Overview';
      case MPMemoryDetailSegment.transcript:
        return 'Transcript';
      case MPMemoryDetailSegment.actions:
        return 'Actions';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: useMemoStyle ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _tabs.map((MPMemoryDetailSegment s) {
          final bool isSel = selected == s;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(s),
                borderRadius: BorderRadius.circular(12),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                overlayColor: const WidgetStatePropertyAll<Color>(
                  Colors.transparent,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel
                        ? (useMemoStyle ? Colors.white : Colors.white.withValues(alpha: 0.1))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSel && useMemoStyle
                        ? const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _label(s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OmiTextStyle.create(
                      fontSize: OmiFontSize.t4_13,
                      fontWeight: OmiFontWeight.medium,
                      color: useMemoStyle
                          ? (isSel
                                ? const Color(0xFF1C1C1E)
                                : const Color(0xFF8E8E93))
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
