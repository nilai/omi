import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/common/mp_memory_options_sheet.dart';
import 'package:memo_pin/common/mp_memory_update_name_dialog.dart';
import 'package:memo_pin/common/mp_share_export_sheet.dart';
import 'package:memo_pin/common/mp_share_sheet.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../../common/mp_custom_nav_bar.dart';
import '../../../../common/mp_memory_share_dialog.dart';
import '../../../../generated/assets.dart';
import '../../../../utils/omi_image_loader.dart';
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

class _OmiAudioDetailView extends StatelessWidget {
  const _OmiAudioDetailView({required this.memoryId});

  final String memoryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: PreferredSize(
        preferredSize: MPCustomNavBar.preferredSizeOf(context),
        child: MPCustomNavBar(
          title: 'Memo',
          actions: <Widget>[
            GestureDetector(
              onTap: () async {
                final MPShareSheetResult? result = await showMPShareSheet(
                  context,
                  onShare: () {
                    showMPShareExportSheet(context).then((MPShareExportKind? kind) {
                      if (kind == null) return;
                      if (!context.mounted) return;
                      if (kind == MPShareExportKind.link) {
                        MPShareMemoryDialog.show(context: context, memoryId: memoryId);
                      } else {
                        MPToastUtils.showFeatureComingSoon();
                      }
                    });
                  },
                );
                if (result == null) return;
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
                  params: MPMemoryOptionsSheetParams(memoryId: memoryId),
                );
                if (kind == null) return;
                if (!context.mounted) return;
                switch (kind) {
                  case MPMemoryOptionKind.manageProjects:
                    // TODO: Manage projects
                    break;
                  case MPMemoryOptionKind.editTitle:
                    final MPAudioDetailCubit cubit =
                        context.read<MPAudioDetailCubit>();
                    final MPAudioDetailState s = cubit.state;
                    if (s.phase != MPAudioDetailPhase.loaded ||
                        s.data == null) {
                      MPToastUtils.showMessage('请等待加载完成');
                      break;
                    }
                    MPMemoryUpdateNameDialog.show(
                      context: context,
                      memoryId: memoryId,
                      currentTitle: s.data!.title,
                      onSuccess: cubit.updateTitle,
                    );
                    break;
                  case MPMemoryOptionKind.modifyDate:
                    // TODO: Modify date
                    break;
                  case MPMemoryOptionKind.delete:
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                    break;
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
              return const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            case MPAudioDetailPhase.error:
              return Center(
                child: Text(
                  state.errorMessage ?? '加载失败',
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t7_16,
                    fontWeight: OmiFontWeight.medium,
                    color: secondTextColor,
                  ),
                ),
              );
            case MPAudioDetailPhase.loaded:
              final MPAudioDetailData d = state.data!;
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
                                  d.leftTime,
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
                            _AudioWaveform(
                              isPlaying: state.isPlaying,
                              progress: state.progress,
                            ),
                            const SizedBox(height: 22),
                            Center(
                              child: _PlayButton(
                                isPlaying: state.isPlaying,
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
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F0FF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Center(
                                  child: OmiImageLoader.localImg(
                                    Assets.tabAskAi,
                                    color: blueTextColor,
                                    width: 20,
                                    height: 20,
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
                        height: 56,
                        width: 240,
                        child: TextButton(
                          onPressed: () {
                            context.read<MPAudioDetailCubit>().onSummarizeTap(
                              context,
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFE8F0FF),
                            foregroundColor: blueTextColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(
                                color: Color(0xFFD8E7FF),
                                width: 1,
                              ),
                            ),
                          ),
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
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}

class _AudioWaveform extends StatefulWidget {
  const _AudioWaveform({required this.isPlaying, required this.progress});

  final bool isPlaying;
  final double progress;

  @override
  State<_AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<_AudioWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  static const int _n = 86;
  static const double _h = 74;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isPlaying) {
      _pulse.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _AudioWaveform oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _h,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (BuildContext context, Widget? child) {
          final double p = widget.isPlaying ? _pulse.value : 0.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List<Widget>.generate(_n, (int i) {
              final bool isPlayed = (i + 1) / _n <= widget.progress;
              final double t = i / (_n - 1);
              final double base =
                  0.28 +
                  0.52 *
                      (0.5 +
                          0.5 *
                              math.sin((t * 5.6 + 0.35) * 2 * math.pi) *
                              math.sin((t * 2.1 + 0.1) * 2 * math.pi));
              final double wobble = widget.isPlaying
                  ? (0.92 + 0.12 * math.sin((p * 2 * math.pi) + t * 10.0))
                  : 1.0;
              final double v = (base * wobble).clamp(0.0, 1.0);
              final double barH = 10 + v * (_h - 10);
              return Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 2,
                    height: barH,
                    decoration: BoxDecoration(
                      color: isPlayed ? Colors.black : const Color(0xFFD1D1D6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
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
  const _PlayButton({required this.isPlaying, this.onTap});

  final bool isPlaying;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: OmiImageLoader.localImg(
              isPlaying ? Assets.omiPause : Assets.omiPlay,
              width: 26,
              height: 26,
              color: mainTextColor,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
