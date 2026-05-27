import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/common/mp_memory_options_sheet.dart';
import 'package:memo_pin/common/mp_tristate_page.dart';
import 'package:memo_pin/common/mp_share_export_sheet.dart';
import 'package:memo_pin/common/mp_memory_notification.dart';
import 'package:memo_pin/http/api/mp_memory.dart';
import 'package:memo_pin/http/schema/mp_memory.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../../common/mp_custom_nav_bar.dart';
import '../../../../common/mp_memory_share_dialog.dart';
import '../../../../generated/assets.dart';
import '../../../../utils/omi_image_loader.dart';
import '../memory/card/mp_memory_summary_generating_panel.dart';
import '../mp_detail_visibility_refresh.dart';
import 'mp_audio_detail_cubit.dart';

/// Audio Memory 详情页（UI 对齐设计稿）。
class OmiAudioDetailPage extends StatelessWidget {
  const OmiAudioDetailPage({super.key, required this.memoryId});

  /// 列表项 id，对应详情接口 `memory_id`。
  final String memoryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPAudioDetailCubit>(
      create: (_) => MPAudioDetailCubit(memoryId: memoryId)..initData(),
      child: _OmiAudioDetailView(memoryId: memoryId),
    );
  }
}

class _OmiAudioDetailView extends StatefulWidget {
  const _OmiAudioDetailView({required this.memoryId});

  final String memoryId;

  @override
  State<_OmiAudioDetailView> createState() => _OmiAudioDetailViewState();
}

class _OmiAudioDetailViewState extends State<_OmiAudioDetailView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (!mounted) {
        return;
      }
      unawaited(context.read<MPAudioDetailCubit>().pauseIfPlaying());
    }
  }

  @override
  Widget build(BuildContext context) {
    final String memoryId = widget.memoryId;
    return MPDetailVisibilityRefresh(
      onRefresh: () => context.read<MPAudioDetailCubit>().load(),
      child: Scaffold(
      backgroundColor: pageColor,
      appBar: PreferredSize(
        preferredSize: MPCustomNavBar.preferredSizeOf(context),
        child: MPCustomNavBar(
          title: 'Memo',
          actions: <Widget>[
            GestureDetector(
              onTap: () async {
                final MPShareExportKind? kind =
                    await showMPShareExportSheet(context);
                if (kind == null) return;
                if (!context.mounted) return;
                if (kind == MPShareExportKind.link) {
                  final MPShareMemoryResponse? resp = await shareMemory(MPShareMemoryRequest(memoryId: memoryId));
                  if (!context.mounted) return;
                  MPShareMemoryDialog.show(context: context, url: resp?.shareUrl ?? '');
                } else {
                  MPToastUtils.showFeatureComingSoon();
                }
              },
              child: OmiImageLoader.localImg(
                Assets.omiShare,
                width: 20,
                height: 20,
                color: blueTextColor,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () async {
                final MPMemoryOptionKind? kind = await showMPMemoryOptionsSheet(
                  context,
                  params: MPMemoryOptionsSheetParams(
                    showManageProjects: false,
                    showEditTitle: false,
                    showModifyDate: false,
                    showDelete: true,
                    memoryId: memoryId,
                  ),
                );
                if (kind == null) return;
                if (!context.mounted) return;

                if (kind == MPMemoryOptionKind.delete) {
                  // [MPMemoryOptionsSheetParams.memoryId] 非空时，确认与 deleteMemory 已在 Sheet 内完成。
                  MPMemoryNotification.notifyMemoryDeleted(memoryId);
                  Navigator.of(context).pop();
                }
              },
              child: OmiImageLoader.localImg(
                Assets.omiMemoryDetialMore,
                width: 20,
                height: 20,
                color: blueTextColor,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<MPAudioDetailCubit, MPAudioDetailState>(
        builder: (BuildContext context, MPAudioDetailState state) {
          switch (state.phase) {
            case MPAudioDetailPhase.loading:
              return const MPTristatePage(type: MPTristateType.loading);
            case MPAudioDetailPhase.error:
              return MPTristatePage(
                type: MPTristateType.error,
                data: MPTristatePageData(
                  title: 'Load failed',
                  description: 'Please try again',
                  onButtonPressed: () {
                    context.read<MPAudioDetailCubit>().load();
                  },
                ),
              );
            case MPAudioDetailPhase.loaded:
              final MPAudioDetailData d = state.data!;
              if (state.isSummaryGenerating) {
                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    child: MPSummaryGeneratingPanel(
                      headline: d.title.trim().isNotEmpty
                          ? d.title
                          : 'Audio Memory',
                      metaLine: d.subtitle,
                    ),
                  ),
                );
              }
              return SafeArea(
                top: false,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              d.title,
                              style: OmiTextStyle.create(
                                fontSize: OmiFontSize.t21_30,
                                fontWeight: OmiFontWeight.bold,
                                color: mainTextColor,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    d.subtitle,
                                    style: OmiTextStyle.create(
                                      fontSize: OmiFontSize.t6_15,
                                      fontWeight: OmiFontWeight.regular,
                                      color: secondTextColor,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: <Widget>[
                                Text(
                                  state.elapsedLabel,
                                  style: OmiTextStyle.create(
                                    fontSize: OmiFontSize.t6_15,
                                    fontWeight: OmiFontWeight.medium,
                                    color: secondTextColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  d.rightTime,
                                  style: OmiTextStyle.create(
                                    fontSize: OmiFontSize.t6_15,
                                    fontWeight: OmiFontWeight.medium,
                                    color: secondTextColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LayoutBuilder(
                              builder: (BuildContext context, BoxConstraints c) {
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (TapDownDetails d) {
                                    final double w = c.maxWidth;
                                    if (w <= 0) {
                                      return;
                                    }
                                    final double frac =
                                        (d.localPosition.dx / w).clamp(0.0, 1.0);
                                    context
                                        .read<MPAudioDetailCubit>()
                                        .onSeekByWaveFraction(frac);
                                  },
                                  child: _AudioWaveform(
                                    progress: state.progress,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 22),
                            Center(
                              child: _PlayButton(
                                isPlaying: state.isPlaying,
                                isLoading: state.playPreparing,
                                onTap: () {
                                  context
                                      .read<MPAudioDetailCubit>()
                                      .onPlayTap();
                                },
                              ),
                            ),
                            const SizedBox(height: 22),
                            Container(
                              height: 1,
                              color: lineColor.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 40),
                            Center(
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Color(0x1A007AFF).withAlpha(10),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Center(
                                  child: OmiImageLoader.localImg(
                                    Assets.tabAskAi,
                                    color: blueTextColor,
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Want a quick overview?',
                              textAlign: TextAlign.center,
                              style: OmiTextStyle.create(
                                fontSize: OmiFontSize.t9_18,
                                fontWeight: OmiFontWeight.bold,
                                color: mainTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Generate an AI summary of this conversation',
                              textAlign: TextAlign.center,
                              style: OmiTextStyle.create(
                                fontSize: OmiFontSize.t6_15,
                                fontWeight: OmiFontWeight.regular,
                                color: secondTextColor,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 110),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        0,
                        18,
                        MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      child: SizedBox(
                        height: 50,
                        width: 240,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                Color(0xFFE8F5FF),
                                Color(0xFFDBEAFE),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0x1A007AFF)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () async {
                                final MPAudioDetailCubit cubit =
                                    context.read<MPAudioDetailCubit>();
                                await cubit.pauseIfPlaying();
                                if (!context.mounted) return;
                                await cubit.onSummarizeTap(context);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  OmiImageLoader.localImg(
                                    Assets.tabAskAi,
                                    color: blueTextColor,
                                    width: 20,
                                    height: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'AI Summarize',
                                    style: OmiTextStyle.create(
                                      fontSize: OmiFontSize.t8_17,
                                      fontWeight: OmiFontWeight.bold,
                                      color: blueTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
          }
        },
      ),
    ),
    );
  }
}

class _AudioWaveform extends StatelessWidget {
  const _AudioWaveform({required this.progress});

  final double progress;

  /// 对应 Tailwind `h-24`（96px）。
  static const double _waveHeight = 96;

  static const double _barWidth = 1.5;
  static const double _barGap = 1;
  static const int _minBarCount = 48;
  static const int _maxBarCount = 200;
  static const Color _playedColor = Color(0xFF1C1C1E);
  static const Color _unplayedColor = Color(0xFFD1D1D6);

  /// 根据可用宽度计算竖条数量：`n * width + (n-1) * gap <= maxWidth`。
  static int _barCountForWidth(double maxWidth) {
    if (maxWidth <= 0) {
      return _minBarCount;
    }
    final int n = ((maxWidth + _barGap) / (_barWidth + _barGap)).floor();
    return n.clamp(_minBarCount, _maxBarCount);
  }

  /// 确定性伪随机 [0, 1)，避免 rebuild 抖动。
  static double _hash01(int i, int seed) {
    int x = i * 374761393 + seed * 668265263;
    x = (x ^ (x >> 13)) * 1274126177;
    x ^= x >> 16;
    return (x & 0x7fffffff) / 0x7fffffff;
  }

  /// 多层不规则波形 + 分段噪声；用归一化位置 [u] 打破前后半段相似。
  static double _barHeightPercent(int i, int barCount) {
    final int n = math.max(barCount, 2);
    final double u = i / (n - 1);
    final double t = i.toDouble();

    // 前后半段用不同相位/频率，避免 1、2 段镜像相似。
    final double halfBias = u < 0.5 ? 0.0 : 4.17;
    final double waveA = math.sin(t * 0.53 + u * 19.7 + halfBias) * 11;
    final double waveB = math.sin(u * 31.4 + t * 0.71 + 1.3) * 10;
    final double waveC = math.cos(t * 1.27 + u * 47.2 + halfBias * 0.6) * 8;
    final double waveD = math.sin((t + u * n) * 0.67 + 2.9) * 6;

    // 每 20% 宽度换一组噪声种子，降低段落重复感。
    final int segment = (u * 5).floor().clamp(0, 4);
    final double noise =
        (_hash01(i + n * 7 + segment * 131, 17) - 0.5) * 28 +
        (_hash01(i * 19 + segment * 59 + n, 53) - 0.5) * 20 +
        (_hash01((i * 1000 * (u + 0.11)).round(), 97) - 0.5) * 14;

    // 非对称包络：前段缓升、中段起伏、后段偏高。
    final double envelope = 0.65 +
        0.24 * math.sin(u * 5.9 + 0.4) +
        0.20 * math.sin(u * 13.1 + 2.1) +
        0.14 * u;
    final double raw = 44 + (waveA + waveB + waveC + waveD + noise) * envelope;
    return math.max(18, math.min(85, raw));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int barCount = _barCountForWidth(constraints.maxWidth);
        return SizedBox(
          width: constraints.maxWidth,
          height: _waveHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: _barGap,
            children: List<Widget>.generate(barCount, (int i) {
              final double barProgress = i / barCount;
              final bool isPlayed = barProgress <= progress;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                width: _barWidth,
                height: _waveHeight * _barHeightPercent(i, barCount) / 100,
                decoration: BoxDecoration(
                  color: isPlayed ? _playedColor : _unplayedColor,
                  borderRadius: BorderRadius.circular(_barWidth / 2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isLoading,
    this.onTap,
  });

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback? onTap;

  static const Color _iconColor = Color(0xFF1C1C1E);
  static const double _iconSize = 28;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E5EA)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: _iconSize,
                  height: _iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _iconColor,
                  ),
                )
              : isPlaying
                  ? Icon(
                      Icons.pause_rounded,
                      size: _iconSize,
                      color: _iconColor,
                    )
                  : Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: _iconSize,
                        color: _iconColor,
                      ),
                    ),
        ),
      ),
    );
  }
}
