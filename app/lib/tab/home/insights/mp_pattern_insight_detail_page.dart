import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/common/mp_custom_nav_bar.dart';
import 'package:omi/common/mp_tristate_page.dart';
import 'package:omi/utils/mp_toast_utils.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import 'mp_insight_detail_cubit.dart';
import 'mp_insights_list_cubit.dart';

/// Pattern Insight 详情页（强调“主题 + 相关记忆”）
class MPPatternInsightDetailPage extends StatelessWidget {
  const MPPatternInsightDetailPage({
    super.key,
    required this.item,
  });

  final MPInsightListItem item;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPInsightDetailCubit>(
      create: (_) => MPInsightDetailCubit(item: item)..initData(),
      child: BlocBuilder<MPInsightDetailCubit, MPInsightDetailState>(
        builder: (BuildContext context, MPInsightDetailState state) {
          return Scaffold(
            backgroundColor: pageColor,
            appBar: PreferredSize(
              preferredSize: MPCustomNavBar.preferredSizeOf(context),
              child: MPCustomNavBar(
                title: 'Pattern Insight',
                backgroundColor: pageColor,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            body: _MPPatternInsightBody(state: state),
          );
        },
      ),
    );
  }
}

class _MPPatternInsightBody extends StatelessWidget {
  const _MPPatternInsightBody({required this.state});

  final MPInsightDetailState state;

  @override
  Widget build(BuildContext context) {
    switch (state.phase) {
      case MPInsightDetailPhase.loading:
        return const MPTristatePage(type: MPTristateType.loading);
      case MPInsightDetailPhase.error:
        return MPTristatePage(
          type: MPTristateType.error,
          data: MPTristatePageData(
            title: 'Unable to load Pattern insight',
            description: state.errorMessage ?? '请稍后重试',
            buttonText: 'Retry',
            onButtonPressed: () =>
                context.read<MPInsightDetailCubit>().initData(),
          ),
        );
      case MPInsightDetailPhase.loaded:
        final MPInsightListItem item = state.data!.item;
        final List<String> themes = item.recurringThemes;
        final List<String> memos = item.patternMemoryTitles;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _PatternHero(
                periodLabel: item.periodLabel,
                title: item.title,
                subtitle: item.subtitle,
                summary: item.summary,
              ),
              const SizedBox(height: 16),
              _SectionTitle('Recurring themes'),
              const SizedBox(height: 10),
              ...themes.map((String t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ThemeCard(
                    text: t,
                    onTap: () => MPToastUtils.showFeatureComingSoon(
                        message: 'Open theme details'),
                  ),
                );
              }),
              const SizedBox(height: 6),
              _SectionTitle('Related memories'),
              const SizedBox(height: 10),
              ...memos.map((String m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => MPToastUtils.showFeatureComingSoon(
                          message: 'Open memory'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: blueTextColor.withValues(alpha: 18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: blueTextColor.withValues(alpha: 50),
                          ),
                        ),
                        child: Text(
                          m,
                          style: OmiTextStyle.create(
                            color: mainTextColor,
                            fontSize: OmiFontSize.t5_14,
                            fontWeight: OmiFontWeight.regular,
                            height: 1.55,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              _SectionTitle('Suggested actions'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: state.data!.tips.map((String tip) {
                  return _TipChip(
                    text: tip,
                    onTap: () => MPToastUtils.showFeatureComingSoon(
                      message: 'Apply action',
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => MPToastUtils.showFeatureComingSoon(
                    message: 'Create pattern todo'),
                child: const Text('Create pattern todo'),
              ),
            ],
          ),
        );
    }
  }
}

class _PatternHero extends StatelessWidget {
  const _PatternHero({
    required this.periodLabel,
    required this.title,
    required this.subtitle,
    required this.summary,
  });

  final String periodLabel;
  final String title;
  final String subtitle;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: purpleTextColor.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: purpleTextColor.withValues(alpha: 70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            periodLabel,
            style: OmiTextStyle.create(
              color: purpleTextColor,
              fontSize: OmiFontSize.t5_14,
              fontWeight: OmiFontWeight.medium,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: OmiTextStyle.create(
              color: mainTextColor,
              fontSize: OmiFontSize.t8_17,
              fontWeight: OmiFontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: OmiTextStyle.create(
              color: secondTextColor,
              fontSize: OmiFontSize.t5_14,
              fontWeight: OmiFontWeight.regular,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            summary,
            style: OmiTextStyle.create(
              color: secondTextColor,
              fontSize: OmiFontSize.t6_15,
              fontWeight: OmiFontWeight.regular,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: OmiTextStyle.create(
        color: secondTextColor,
        fontSize: OmiFontSize.t4_13,
        fontWeight: OmiFontWeight.medium,
        height: 1.3,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: orangeTextColor.withValues(alpha: 18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: orangeTextColor.withValues(alpha: 50),
            ),
          ),
          child: Text(
            text,
            style: OmiTextStyle.create(
              color: mainTextColor,
              fontSize: OmiFontSize.t6_15,
              fontWeight: OmiFontWeight.regular,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: blueTextColor.withValues(alpha: 25),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: blueTextColor.withValues(alpha: 60)),
        ),
        child: Text(
          text,
          style: OmiTextStyle.create(
            color: blueTextColor,
            fontSize: OmiFontSize.t5_14,
            fontWeight: OmiFontWeight.medium,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

