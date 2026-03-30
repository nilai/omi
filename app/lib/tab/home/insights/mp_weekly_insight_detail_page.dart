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

/// Weekly Insight 详情页
class MPWeeklyInsightDetailPage extends StatelessWidget {
  const MPWeeklyInsightDetailPage({
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
                title: 'Weekly Insight',
                backgroundColor: pageColor,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            body: _MPWeeklyInsightBody(state: state),
          );
        },
      ),
    );
  }
}

class _MPWeeklyInsightBody extends StatelessWidget {
  const _MPWeeklyInsightBody({required this.state});

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
            title: 'Unable to load Weekly insight',
            description: state.errorMessage ?? '请稍后重试',
            buttonText: 'Retry',
            onButtonPressed: () =>
                context.read<MPInsightDetailCubit>().initData(),
          ),
        );
      case MPInsightDetailPhase.loaded:
        final MPInsightListItem item = state.data!.item;
        final int completed = item.completedCount ?? 0;
        final int pending = item.pendingCount ?? 0;
        final int rec = item.recommendationsCount ?? 0;

        final int total = completed + pending;
        final double progress = total == 0 ? 0 : completed / total;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _WeeklyProgressHeader(
                periodLabel: item.periodLabel,
                summary: item.summary,
                progress: progress,
                completed: completed,
                pending: pending,
              ),
              const SizedBox(height: 16),
              _SectionTitle('Recommendations ($rec)'),
              const SizedBox(height: 10),
              _RecommendationList(
                tips: state.data!.tips,
                onTipTap: () =>
                    MPToastUtils.showFeatureComingSoon(message: 'Apply recommendation'),
              ),
              const SizedBox(height: 18),
              _SectionTitle('Key takeaways'),
              const SizedBox(height: 10),
              ...state.data!.paragraphs.map((String p) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    p,
                    style: OmiTextStyle.create(
                      color: secondTextColor,
                      fontSize: OmiFontSize.t5_14,
                      fontWeight: OmiFontWeight.regular,
                      height: 1.65,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => MPToastUtils.showFeatureComingSoon(
                    message: 'Create weekly action todo'),
                child: const Text('Create weekly action todo'),
              ),
            ],
          ),
        );
    }
  }
}

class _WeeklyProgressHeader extends StatelessWidget {
  const _WeeklyProgressHeader({
    required this.periodLabel,
    required this.summary,
    required this.progress,
    required this.completed,
    required this.pending,
  });

  final String periodLabel;
  final String summary;
  final double progress;
  final int completed;
  final int pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: purpleTextColor.withValues(alpha: 30),
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
            summary,
            style: OmiTextStyle.create(
              color: mainTextColor,
              fontSize: OmiFontSize.t6_15,
              fontWeight: OmiFontWeight.regular,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: purpleTextColor.withValues(alpha: 30),
              valueColor: AlwaysStoppedAnimation<Color>(purpleTextColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _MiniStat(
                label: 'Completed',
                value: completed,
                color: greenTextColor,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                label: 'Pending',
                value: pending,
                color: orangeTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 25),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '$value',
              style: OmiTextStyle.create(
                color: color,
                fontSize: OmiFontSize.t11_20,
                fontWeight: OmiFontWeight.bold,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: OmiTextStyle.create(
                color: secondTextColor,
                fontSize: OmiFontSize.t4_13,
                fontWeight: OmiFontWeight.regular,
                height: 1.2,
              ),
            ),
          ],
        ),
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

class _RecommendationList extends StatelessWidget {
  const _RecommendationList({required this.tips, required this.onTipTap});

  final List<String> tips;
  final VoidCallback onTipTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(tips.length, (int index) {
        final Color c = index % 2 == 0 ? blueTextColor : orangeTextColor;
        return Padding(
          padding: EdgeInsets.only(bottom: index == tips.length - 1 ? 0 : 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTipTap,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.withValues(alpha: 60)),
                ),
                child: Text(
                  tips[index],
                  style: OmiTextStyle.create(
                    color: mainTextColor,
                    fontSize: OmiFontSize.t5_14,
                    fontWeight: OmiFontWeight.regular,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

