import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memo_pin/common/omi_add_todo_popup.dart';
import 'package:memo_pin/common/omi_button.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_generate_summary_sheet.dart';
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
  });

  final String title;

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
  }) {
    return MPMemoryDetailCardData(
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
    );
  }
}

const Color _kCardBg = greenDeepColor;
const Color _kSegmentTrack = Color(0xFF1A3D2E);
const Color _kSegmentSelected = Color(0xFF4A6B5A);

/// Memory 详情：标题 + 元信息 + 音频波形 + 说话人 + **底部分段切换**
class MPMemoryDetailContentCard extends StatefulWidget {
  const MPMemoryDetailContentCard({
    super.key,
    required this.data,
    this.onSegmentChanged,
    this.onPlayTap,
    this.showBackground = true,
    this.segmentBodyScrollWithParent = false,
    this.cardType = MPMemoryDetailCardType.memory,
  });

  final MPMemoryDetailCardData data;

  /// 分段切换回调
  final ValueChanged<MPMemoryDetailSegment>? onSegmentChanged;

  final VoidCallback? onPlayTap;
  final bool showBackground;
  final bool segmentBodyScrollWithParent;
  final MPMemoryDetailCardType cardType;

  @override
  State<MPMemoryDetailContentCard> createState() =>
      _MPMemoryDetailContentCardState();
}

class _MPMemoryDetailContentCardState extends State<MPMemoryDetailContentCard> {
  late MPMemoryDetailSegment _segment;

  /// 是否正在播放（未播放 [Assets.omiPlay]，播放中 [Assets.omiStop]）
  bool _playing = false;
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
    _syncDurationFromData(widget.data);
    _transcriptItems = List<MPMemoryTranscriptItemData>.from(
      widget.data.transcriptItems,
    );
    _actionItems = List<MPMemoryActionItemData>.from(widget.data.actionItems);
  }

  @override
  void didUpdateWidget(covariant MPMemoryDetailContentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.initialSegment != widget.data.initialSegment) {
      _segment = widget.data.initialSegment;
    }
    if (oldWidget.data.audioTimeStart != widget.data.audioTimeStart ||
        oldWidget.data.audioTimeEnd != widget.data.audioTimeEnd) {
      _syncDurationFromData(widget.data);
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

  void _syncDurationFromData(MPMemoryDetailCardData data) {
    _elapsed = Duration(seconds: _parseToSeconds(data.audioTimeStart));
    _total = Duration(seconds: _parseToSeconds(data.audioTimeEnd));
    if (_total <= Duration.zero || _elapsed > _total) {
      _total = _elapsed;
    }
  }

  void _togglePlayFromHeader() {
    setState(() {
      if (_elapsed >= _total && _total > Duration.zero) {
        _elapsed = Duration.zero;
      }
      _playing = !_playing;
      _playingTranscriptIndex ??= _transcriptItems.isNotEmpty ? 0 : null;
    });
    _syncTimerByPlayingState();
    widget.onPlayTap?.call();
  }

  void _onTranscriptPlayTap(int index) {
    setState(() {
      final bool isSameIndex = _playingTranscriptIndex == index;
      if (isSameIndex && _playing) {
        _playing = false;
      } else {
        final Duration fromTranscript =
            Duration(seconds: _transcriptItems[index].timeSeconds);
        if (fromTranscript <= _total) {
          _elapsed = fromTranscript;
        }
        if (_elapsed >= _total && _total > Duration.zero) {
          _elapsed = Duration.zero;
        }
        _playing = true;
        _playingTranscriptIndex = index;
      }
    });
    _syncTimerByPlayingState();
    widget.onPlayTap?.call();
  }

  void _syncTimerByPlayingState() {
    _progressTimer?.cancel();
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
    final RegExp mmss = RegExp(r'^(\d+):(\d{2})$');
    final Match? mmssMatch = mmss.firstMatch(raw.trim());
    if (mmssMatch != null) {
      final int m = int.tryParse(mmssMatch.group(1) ?? '') ?? 0;
      final int s = int.tryParse(mmssMatch.group(2) ?? '') ?? 0;
      return m * 60 + s;
    }
    final RegExp ms = RegExp(r'(?:(\d+)m)?\s*(?:(\d+)s)?');
    final Match? msMatch = ms.firstMatch(raw.trim());
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

  /// 点击某条 transcript 的编辑图标：弹出「Edit Speaker Name」底部弹窗
  Future<void> _onTranscriptEditTap(int index) async {
    final MPMemoryTranscriptItemData item = _transcriptItems[index];
    final MPMemoryEditSpeakerResult? result =
        await showMPMemoryEditSpeakerSheet(
          context: context,
          currentSpeakerName: item.speakerName,
        );
    if (!mounted || result == null) return;
    setState(() {
      if (result.applyToAll) {
        final String oldName = item.speakerName;
        _transcriptItems = _transcriptItems
            .map(
              (MPMemoryTranscriptItemData e) => e.speakerName == oldName
                  ? e.copyWith(speakerName: result.newName)
                  : e,
            )
            .toList();
      } else {
        final List<MPMemoryTranscriptItemData> next =
            List<MPMemoryTranscriptItemData>.from(_transcriptItems);
        next[index] = item.copyWith(speakerName: result.newName);
        _transcriptItems = next;
      }
    });
  }

  /// 创建 Todo 接口（占位：延迟模拟网络；成功后由 [_onCreateTodoFromAction] 将条目置为 [MPMemoryActionItemStatus.created]）
  Future<bool> _submitActionTodoToBackend({
    required int index,
    required MPAddTodoPopupResult r,
  }) async {
    // TODO: 替换为真实请求，例如 POST /todos
    // 可提交：index、r.title、r.notes、r.priority、r.when、r.time、memoryId 等
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }

  /// Actions 里「Save Todo」后：先调接口，成功则更新本地列表为已创建
  Future<void> _onCreateTodoFromAction(
    int index,
    MPAddTodoPopupResult r,
  ) async {
    final bool ok = await _submitActionTodoToBackend(index: index, r: r);
    if (!mounted || !ok) {
      return;
    }
    if (index < 0 || index >= _actionItems.length) {
      return;
    }
    setState(() {
      final List<MPMemoryActionItemData> next =
          List<MPMemoryActionItemData>.from(_actionItems);
      final MPMemoryActionItemData cur = next[index];
      next[index] = cur.copyWith(
        title: r.title.isNotEmpty ? r.title : cur.title,
        status: MPMemoryActionItemStatus.created,
      );
      _actionItems = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final MPMemoryDetailCardData d = widget.data;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: widget.showBackground ? _kCardBg : Colors.transparent,
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
                child: _WaveformBar(
                  heights: _heights,
                  isPlaying: _playing,
                  useMemoStyle: _isMemoCard,
                  progress: _total.inMilliseconds <= 0
                      ? 0
                      : _elapsed.inMilliseconds / _total.inMilliseconds,
                ),
              ),
              const SizedBox(width: 10),
              _PlayButton(
                isPlaying: _playing,
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
          if (widget.segmentBodyScrollWithParent)
            _buildSegmentBody()
          else
            SizedBox(height: 330, child: _buildSegmentBody()),
          if (widget.cardType == MPMemoryDetailCardType.memory) ...<Widget>[
            const SizedBox(height: 16),

            /// 分段区与「Generate Resummary」之间的浅灰分隔线（约 0.5 逻辑像素）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                height: 0.5,
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ),
            const SizedBox(height: 16),
            OmiButton(
              textColor: Colors.white,
              bgColor: Colors.white.withValues(alpha: 0.15),
              icon: OmiImageLoader.localImg(
                Assets.omiRefreshGenerateSummary,
                width: 20,
                height: 20,
                color: Colors.white,
                fit: BoxFit.cover,
              ),
              text: 'Generate Resummary',
              width: double.infinity,
              height: 50,
              onPressed: () {
                showMPMemoryGenerateSummarySheet(
                  context,
                  onGenerateResummary: () {
                    // TODO: 调用生成 resummary 接口
                  },
                  onChangeMode: () {
                    // TODO: 切换 Autopilot / 其它模式
                  },
                );
              },
            ),
            const SizedBox(height: 12),
          ],
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
    return Container(
      height: 40,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: widget.useMemoStyle
            ? const Color(0xFFF0F0F5)
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
          final double maxInnerH = (c.maxHeight - 8).clamp(4.0, 40.0);
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
    required this.useMemoStyle,
    this.onTap,
  });

  final bool isPlaying;
  final bool useMemoStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
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
            child: OmiImageLoader.localImg(
              isPlaying ? Assets.omiPause : Assets.omiPlay,
              width: 20,
              height: 20,
              color: useMemoStyle ? const Color(0xFF1C1C1E) : Colors.white,
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
        color: useMemoStyle ? Colors.transparent : _kSegmentTrack,
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
                        ? (useMemoStyle ? Colors.white : _kSegmentSelected)
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
