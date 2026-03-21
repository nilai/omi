import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

/// 底部分段：Overview / Transcript / Actions
enum MPMemoryDetailSegment {
  overview,
  transcript,
  actions,
}

/// Memory 详情主卡片数据
class MPMemoryDetailCardData {
  const MPMemoryDetailCardData({
    required this.title,
    required this.metaLine,
    required this.audioTimeStart,
    required this.audioTimeEnd,
    this.waveformHeights,
    required this.speakerLabels,
    this.initialSegment = MPMemoryDetailSegment.transcript,
  });

  final String title;

  /// 一行元信息（含时间与来源等），如 `Yesterday, 4:30 PM • 45m52s • MemoPin`
  final String metaLine;

  final String audioTimeStart;
  final String audioTimeEnd;

  /// 波形条高度 0~1，不传则内部生成占位波形
  final List<double>? waveformHeights;

  final List<String> speakerLabels;

  final MPMemoryDetailSegment initialSegment;
}

const Color _kCardBg = greenDeepColor;
const Color _kWaveformTrack = Color(0xFF1E3D32);
const Color _kSegmentTrack = Color(0xFF1A3D2E);
const Color _kSegmentSelected = Color(0xFF4A6B5A);
const Color _kSpeakerLabelBlue = Color(0xFF90CAF9);

/// Memory 详情：标题 + 元信息 + 音频波形 + 说话人 + **底部分段切换**
class MPMemoryDetailContentCard extends StatefulWidget {
  const MPMemoryDetailContentCard({
    super.key,
    required this.data,
    this.onSegmentChanged,
    this.onPlayTap,
  });

  final MPMemoryDetailCardData data;

  /// 分段切换回调
  final ValueChanged<MPMemoryDetailSegment>? onSegmentChanged;

  final VoidCallback? onPlayTap;

  @override
  State<MPMemoryDetailContentCard> createState() =>
      _MPMemoryDetailContentCardState();
}

class _MPMemoryDetailContentCardState extends State<MPMemoryDetailContentCard> {
  late MPMemoryDetailSegment _segment;

  @override
  void initState() {
    super.initState();
    _segment = widget.data.initialSegment;
  }

  @override
  void didUpdateWidget(covariant MPMemoryDetailContentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.initialSegment != widget.data.initialSegment) {
      _segment = widget.data.initialSegment;
    }
  }

  List<double> get _heights {
    if (widget.data.waveformHeights != null &&
        widget.data.waveformHeights!.isNotEmpty) {
      return widget.data.waveformHeights!;
    }
    final math.Random r = math.Random(42);
    return List<double>.generate(
      48,
      (_) => 0.15 + r.nextDouble() * 0.85,
    );
  }

  @override
  Widget build(BuildContext context) {
    final MPMemoryDetailCardData d = widget.data;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            d.title,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t9_18,
              fontWeight: OmiFontWeight.medium,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            d.metaLine,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t4_13,
              fontWeight: OmiFontWeight.regular,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                d.audioTimeStart,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t4_13,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _WaveformBar(heights: _heights)),
              const SizedBox(width: 8),
              Text(
                d.audioTimeEnd,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t4_13,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: 10),
              _PlayButton(onTap: widget.onPlayTap),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'SPEAKERS',
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t3_12,
              fontWeight: OmiFontWeight.medium,
              color: _kSpeakerLabelBlue,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: d.speakerLabels
                .map(
                  (String s) => _SpeakerChip(label: s),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          _SegmentSwitcher(
            selected: _segment,
            onChanged: (MPMemoryDetailSegment v) {
              setState(() => _segment = v);
              widget.onSegmentChanged?.call(v);
            },
          ),
        ],
      ),
    );
  }
}

class _WaveformBar extends StatelessWidget {
  const _WaveformBar({required this.heights});

  final List<double> heights;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _kWaveformTrack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final double w = c.maxWidth;
          final int n = heights.length;
          final double gap = 2;
          final double barW = math.max(1.0, (w - (n - 1) * gap) / n);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(n, (int i) {
              final double h = 6 + heights[i] * (c.maxHeight - 8);
              return Container(
                width: barW,
                height: h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({this.onTap});

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
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          // 基础 play 图标 + 居中，避免圆角图标在部分机型不显示
          child: Center(
            child: Icon(
              Icons.play_arrow,
              size: 32,
              color: greenDeepColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeakerChip extends StatelessWidget {
  const _SpeakerChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Text(
        label,
        style: OmiTextStyle.create(
          fontSize: OmiFontSize.t4_13,
          fontWeight: OmiFontWeight.medium,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SegmentSwitcher extends StatelessWidget {
  const _SegmentSwitcher({
    required this.selected,
    required this.onChanged,
  });

  final MPMemoryDetailSegment selected;
  final ValueChanged<MPMemoryDetailSegment> onChanged;

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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kSegmentTrack,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: _tabs.map((MPMemoryDetailSegment s) {
          final bool isSel = selected == s;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(s),
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? _kSegmentSelected : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _label(s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OmiTextStyle.create(
                      fontSize: OmiFontSize.t4_13,
                      fontWeight: OmiFontWeight.medium,
                      color: Colors.white,
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
