import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/common/mp_memory_options_sheet.dart';
import 'package:omi/common/mp_share_sheet.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../../../../generated/assets.dart';
import '../../../../utils/omi_image_loader.dart';
import 'mp_audio_detail_cubit.dart';

/// Audio Memory 详情页（UI 对齐设计稿）。
class OmiAudioDetailPage extends StatelessWidget {
  const OmiAudioDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPAudioDetailCubit>(
      create: (_) => MPAudioDetailCubit()..initData(),
      child: const _OmiAudioDetailView(),
    );
  }
}

class _OmiAudioDetailView extends StatelessWidget {
  const _OmiAudioDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _AudioDetailNavBar(
          title: 'Audio Memory',
          onShareTap: () async {
            final MPShareSheetResult? result = await showMPShareSheet(context);
            if (result == null) return;
            // TODO: 根据 result.summaryOptionId 与 result.additionalContent 执行分享
          },
          onMoreTap: () async {
            final MPMemoryOptionKind? kind = await showMPMemoryOptionsSheet(
              context,
              params: const MPMemoryOptionsSheetParams(),
            );
            if (kind == null) return;
            switch (kind) {
              case MPMemoryOptionKind.manageProjects:
                // TODO: Manage projects
                break;
              case MPMemoryOptionKind.editTitle:
                // TODO: Edit title
                break;
              case MPMemoryOptionKind.modifyDate:
                // TODO: Modify date
                break;
              case MPMemoryOptionKind.delete:
                // TODO: Delete
                break;
            }
          },
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
                      const _AudioWaveform(),
                      const SizedBox(height: 22),
                      Center(
                        child: _PlayButton(
                          onTap: () {
                            context.read<MPAudioDetailCubit>().onPlayTap();
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        height: 1,
                        color: lineColor.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 24,
                              color: blueTextColor,
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
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 56,
                        child: TextButton(
                          onPressed: () {
                            context.read<MPAudioDetailCubit>().onSummarizeTap();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFE8F0FF),
                            foregroundColor: blueTextColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: const Color(0xFFD8E7FF),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 20,
                                color: blueTextColor,
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
                    ],
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}

class _AudioDetailNavBar extends StatelessWidget {
  const _AudioDetailNavBar({
    required this.title,
    this.onShareTap,
    this.onMoreTap,
  });

  final String title;
  final VoidCallback? onShareTap;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    final double topSafe = MediaQuery.viewPaddingOf(context).top;
    return Container(
      height: 56 + topSafe,
      padding: EdgeInsets.only(top: topSafe),
      color: const Color(0xFFF2F2F7),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 10),
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: mainTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: OmiTextStyle.create(
                fontSize: OmiFontSize.t8_17,
                fontWeight: OmiFontWeight.bold,
                color: mainTextColor,
              ),
            ),
          ),
          InkWell(
            onTap: onShareTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: OmiImageLoader.localImg(
                Assets.omiShare,
                width: 20,
                height: 20,
                color: blueTextColor,
              ),
            ),
          ),
          InkWell(
            onTap: onMoreTap,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.more_horiz_rounded,
                size: 22,
                color: blueTextColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _AudioWaveform extends StatelessWidget {
  const _AudioWaveform();

  @override
  Widget build(BuildContext context) {
    // 仅用于视觉占位：固定的伪波形（不依赖随机，保证每次一致）。
    const int n = 86;
    const double h = 74;
    return SizedBox(
      height: h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List<Widget>.generate(n, (int i) {
          final double t = i / (n - 1);
          final double v =
              0.28 +
              0.52 *
                  (0.5 +
                      0.5 *
                          math.sin((t * 5.6 + 0.35) * 2 * math.pi) *
                          math.sin((t * 2.1 + 0.1) * 2 * math.pi));
          final double barH = 10 + v * (h - 10);
          return Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 2,
                height: barH,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          );
        }),
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
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 74,
          height: 74,
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
          child: const Center(
            child: Icon(
              Icons.play_arrow_rounded,
              size: 34,
              color: mainTextColor,
            ),
          ),
        ),
      ),
    );
  }
}
