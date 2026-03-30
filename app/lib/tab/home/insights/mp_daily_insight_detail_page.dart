import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/common/mp_custom_nav_bar.dart';
import 'package:omi/common/mp_tristate_page.dart';
import 'package:omi/utils/mp_toast_utils.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';
import 'package:omi/utils/omi_space_utils.dart';

import 'mp_insight_detail_cubit.dart';
import 'mp_insights_list_cubit.dart';

/// Daily Insight 详情页（不同类型详情页在样式与内容上保持差异）
class MPDailyInsightDetailPage extends StatelessWidget {
  const MPDailyInsightDetailPage({
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
                title: 'Daily Insight',
                backgroundColor: pageColor,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            body: _MPDailyInsightBody(state: state),
          );
        },
      ),
    );
  }
}

class _MPDailyInsightBody extends StatelessWidget {
  const _MPDailyInsightBody({required this.state});

  final MPInsightDetailState state;

  @override
  Widget build(BuildContext context) {
    switch (state.phase) {
      case MPInsightDetailPhase.loading:
        return const Center(child: MPTristatePage(type: MPTristateType.loading));
      case MPInsightDetailPhase.error:
        return MPTristatePage(
          type: MPTristateType.error,
          data: MPTristatePageData(
            title: 'Unable to load Daily insight',
            description: state.errorMessage ?? '请稍后重试',
            buttonText: 'Retry',
            onButtonPressed: () => context.read<MPInsightDetailCubit>().initData(),
          ),
        );
      case MPInsightDetailPhase.loaded:
        final MPInsightListItem item = state.data!.item;
        final int decisions = item.decisionsCount ?? 0;
        final int followUps = item.followUpsCount ?? 0;
        final int risks = item.risksCount ?? 0;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _HeaderBlock(
                periodLabel: item.periodLabel,
                title: item.title,
                subtitle: item.subtitle,
              ),
              const SizedBox(height: 16),
              Text(
                item.summary,
                style: OmiTextStyle.create(
                  color: mainTextColor,
                  fontSize: OmiFontSize.t6_15,
                  fontWeight: OmiFontWeight.regular,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              _CountGrid(
                blocks: <_CountBlock>[
                  _CountBlock(
                    label: 'Decisions',
                    value: decisions,
                    color: greenTextColor,
                  ),
                  _CountBlock(
                    label: 'Follow-ups',
                    value: followUps,
                    color: blueTextColor,
                  ),
                  _CountBlock(
                    label: 'Risks',
                    value: risks,
                    color: purpleTextColor,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionTitle('What stood out'),
              const SizedBox(height: 10),
              ...List<Widget>.generate(state.data!.paragraphs.length, (int i) {
                return Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : textSmallPadding),
                  child: Text(
                    state.data!.paragraphs[i],
                    style: OmiTextStyle.create(
                      color: secondTextColor,
                      fontSize: OmiFontSize.t5_14,
                      fontWeight: OmiFontWeight.regular,
                      height: 1.6,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 18),
              _SectionTitle('Suggested next steps'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: state.data!.tips.map((String t) {
                  return _TipChip(
                    text: t,
                    onTap: () => MPToastUtils.showFeatureComingSoon(message: 'Apply tip'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => MPToastUtils.showFeatureComingSoon(message: 'Create follow-up todo'),
                child: const Text('Create follow-up todo'),
              ),
            ],
          ),
        );
    }
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({
    required this.periodLabel,
    required this.title,
    required this.subtitle,
  });

  final String periodLabel;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: greenTextColor.withValues(alpha: 25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greenTextColor.withValues(alpha: 60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 6),
          Text(
            title,
            style: OmiTextStyle.create(
              color: mainTextColor,
              fontSize: OmiFontSize.t8_17,
              fontWeight: OmiFontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: OmiTextStyle.create(
              color: secondTextColor,
              fontSize: OmiFontSize.t5_14,
              fontWeight: OmiFontWeight.regular,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBlock {
  const _CountBlock({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _CountGrid extends StatelessWidget {
  const _CountGrid({required this.blocks});

  final List<_CountBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: blocks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.7,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _CountBlock b = blocks[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: b.color.withValues(alpha: 25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: b.color.withValues(alpha: 60)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '${b.value}',
                style: OmiTextStyle.create(
                  color: b.color,
                  fontSize: OmiFontSize.t11_20,
                  fontWeight: OmiFontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                b.label,
                style: OmiTextStyle.create(
                  color: secondTextColor,
                  fontSize: OmiFontSize.t4_13,
                  fontWeight: OmiFontWeight.regular,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
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
        letterSpacing: 0.5,
        height: 1.3,
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

