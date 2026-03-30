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

/// Monthly Insight 详情页
class MPMonthlyInsightDetailPage extends StatelessWidget {
  const MPMonthlyInsightDetailPage({
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
                title: 'Monthly Insight',
                backgroundColor: pageColor,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            body: _MPMonthlyInsightBody(state: state),
          );
        },
      ),
    );
  }
}

class _MPMonthlyInsightBody extends StatelessWidget {
  const _MPMonthlyInsightBody({required this.state});

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
            title: 'Unable to load Monthly insight',
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

        final List<String> highlights = <String>[
          '你保持了稳定的记录习惯',
          '高价值任务更容易被完成',
          '你在关键时段减少了打断',
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _MonthlyHero(
                periodLabel: item.periodLabel,
                progress: progress,
                completed: completed,
                pending: pending,
                summary: item.summary,
              ),
              const SizedBox(height: 16),
              _SectionTitle('Highlights'),
              const SizedBox(height: 10),
              ...highlights.map((String h) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BulletRow(
                    text: h,
                    color: orangeTextColor,
                  ),
                );
              }),
              const SizedBox(height: 4),
              _SectionTitle('Recommended improvements ($rec)'),
              const SizedBox(height: 10),
              ...state.data!.tips.map((String t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BulletRow(
                    text: t,
                    color: blueTextColor,
                  ),
                );
              }),
              const SizedBox(height: 18),
              _SectionTitle('Notes'),
              const SizedBox(height: 10),
              ...state.data!.paragraphs.map((String p) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
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
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => MPToastUtils.showFeatureComingSoon(
                  message: 'Create monthly review todo',
                ),
                child: const Text('Create monthly review todo'),
              ),
            ],
          ),
        );
    }
  }
}

class _MonthlyHero extends StatelessWidget {
  const _MonthlyHero({
    required this.periodLabel,
    required this.progress,
    required this.completed,
    required this.pending,
    required this.summary,
  });

  final String periodLabel;
  final double progress;
  final int completed;
  final int pending;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: greenDeepColor.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greenDeepColor.withValues(alpha: 70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            periodLabel,
            style: OmiTextStyle.create(
              color: greenDeepColor,
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
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: greenDeepColor.withValues(alpha: 30),
              valueColor: AlwaysStoppedAnimation<Color>(greenTextColor),
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
                color: purpleTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 22),
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
                height: 1.25,
              ),
            )
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

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 9),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: OmiTextStyle.create(
              color: mainTextColor,
              fontSize: OmiFontSize.t5_14,
              fontWeight: OmiFontWeight.regular,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

