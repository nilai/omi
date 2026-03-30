import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/common/mp_tristate_page.dart';
import 'package:omi/utils/mp_toast_utils.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_image_loader.dart';
import 'package:omi/utils/omi_textstyle.dart';

import 'mp_insight_detail_cubit.dart';
import 'mp_insights_list_cubit.dart';

import '../../../generated/assets.dart';

/// Monthly Insight 详情页（按 design 再排版）
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
              preferredSize: _MPMonthlyAppBar.preferredSizeOf(context),
              child: _MPMonthlyAppBar(
                monthSubtitle: item.periodLabel,
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

class _MPMonthlyAppBar extends StatelessWidget {
  const _MPMonthlyAppBar({
    required this.monthSubtitle,
    required this.onBack,
  });

  final String monthSubtitle;
  final VoidCallback onBack;

  static Size preferredSizeOf(BuildContext context) {
    final double top = MediaQuery.paddingOf(context).top;
    // 双行标题：比 MPCustomNavBar 多一点高度
    return Size.fromHeight(top + 66);
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;
    return Container(
      color: pageColor,
      padding: EdgeInsets.only(top: topInset, right: 16, left: 0),
      child: SizedBox(
        height: 66,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: OmiImageLoader.localImg(
                  Assets.omiLeftBack,
                  color: blueTextColor,
                  width: 20,
                  height: 20,
                ),
                onPressed: onBack,
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Monthly Insight',
                    style: OmiTextStyle.create(
                      color: mainTextColor,
                      fontSize: OmiFontSize.t8_17,
                      fontWeight: OmiFontWeight.medium,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    monthSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OmiTextStyle.create(
                      color: secondTextColor,
                      fontSize: OmiFontSize.t5_14,
                      fontWeight: OmiFontWeight.regular,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => MPToastUtils.showFeatureComingSoon(
                      message: 'Share monthly insight',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => MPToastUtils.showFeatureComingSoon(
                      message: 'Monthly options',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        final MPInsightDetailData d = state.data!;
        final MPMonthlyInsightDetailData? monthly = d.monthly;
        if (monthly == null) {
          return const MPTristatePage(type: MPTristateType.empty);
        }

        // 卡片不支持点击：仅用 Container/Column 渲染，不包 InkWell/GestureDetector
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _MPMonthlyMonthOverviewCard(
                summary: monthly.monthOverviewSummary,
              ),
              const SizedBox(height: 12),
              if (monthly.attentionDistribution.isNotEmpty)
                _MPMonthlyAttentionDistributionCard(
                  items: monthly.attentionDistribution,
                  summary: monthly.attentionDistributionSummary,
                ),
              if (monthly.keyPeopleThisMonth.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPMonthlyKeyPeopleCard(
                  items: monthly.keyPeopleThisMonth,
                  summary: monthly.keyPeopleThisMonthSummary,
                ),
              ],
              if (monthly.topicsSurfacing.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPMonthlyTopicsSurfacingCard(
                  items: monthly.topicsSurfacing,
                  summary: monthly.topicsSurfacingSummary,
                ),
              ],
              if (monthly.longRunningOpenThreads.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPMonthlyCard(
                  title: 'Long-running Open Threads',
                  icon: Icons.timer_outlined,
                  accent: greenTextColor,
                  child: _MPMonthlyBulletList(items: monthly.longRunningOpenThreads),
                ),
              ],
              if (monthly.monthToMonthTrend.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPMonthlyCard(
                  title: 'Month-to-Month Trend',
                  icon: Icons.trending_up_outlined,
                  accent: orangeTextColor,
                  child: _MPMonthlyParagraphList(paragraphs: monthly.monthToMonthTrend),
                ),
              ],
              if (monthly.decisionsThatCannotSlipAgain.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPMonthlyCard(
                  title: 'Decisions That Cannot Slip Again',
                  icon: Icons.warning_amber_rounded,
                  accent: orangeTextColor,
                  child: _MPMonthlyDecisionList(
                    items: monthly.decisionsThatCannotSlipAgain,
                  ),
                ),
              ],
              if (monthly.suggestedFocusNextMonth.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPMonthlyCard(
                  title: 'Suggested Focus Next Month',
                  icon: Icons.lightbulb_outline,
                  accent: purpleTextColor,
                  child: _MPMonthlySuggestedFocusList(
                    items: monthly.suggestedFocusNextMonth,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => MPToastUtils.showFeatureComingSoon(
                  message: monthly.askAiButtonText,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: purpleTextColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Ask AI about this month'),
              ),
            ],
          ),
        );
    }
  }
}

class _MPMonthlyMonthOverviewCard extends StatelessWidget {
  const _MPMonthlyMonthOverviewCard({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAEAEA),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.check_circle_outline,
                color: orangeTextColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Month Overview',
                style: OmiTextStyle.create(
                  color: mainTextColor,
                  fontSize: OmiFontSize.t7_16,
                  fontWeight: OmiFontWeight.medium,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: const Color(0xFFE6E6E6),
            height: 1,
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: OmiTextStyle.create(
              color: secondTextColor,
              fontSize: OmiFontSize.t5_14,
              fontWeight: OmiFontWeight.regular,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _MPMonthlyAttentionDistributionCard extends StatelessWidget {
  const _MPMonthlyAttentionDistributionCard({
    required this.items,
    required this.summary,
  });

  final List<MPMonthlyBarItem> items;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAEAEA),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.bar_chart_outlined,
                color: blueTextColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Attention Distribution',
                style: OmiTextStyle.create(
                  color: mainTextColor,
                  fontSize: OmiFontSize.t7_16,
                  fontWeight: OmiFontWeight.medium,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: const Color(0xFFE6E6E6),
            height: 1,
          ),
          const SizedBox(height: 12),
          Column(
            children: items.map((MPMonthlyBarItem i) {
              final double v = (i.value / 100.0).clamp(0, 1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 112,
                      child: Text(
                        i.label,
                        style: OmiTextStyle.create(
                          color: secondTextColor,
                          fontSize: OmiFontSize.t5_14,
                          fontWeight: OmiFontWeight.regular,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: v,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFF2F2F7),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(blueTextColor),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            style: OmiTextStyle.create(
              color: secondTextColor,
              fontSize: OmiFontSize.t5_14,
              fontWeight: OmiFontWeight.regular,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _MPMonthlyKeyPeopleCard extends StatelessWidget {
  const _MPMonthlyKeyPeopleCard({
    required this.items,
    required this.summary,
  });

  final List<MPMonthlyKeyPersonItem> items;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAEAEA),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.people_alt_outlined,
                color: blueTextColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Key People This Month',
                style: OmiTextStyle.create(
                  color: mainTextColor,
                  fontSize: OmiFontSize.t7_16,
                  fontWeight: OmiFontWeight.medium,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: const Color(0xFFE6E6E6),
            height: 1,
          ),
          const SizedBox(height: 12),
          Column(
            children: items.map((MPMonthlyKeyPersonItem p) {
              final double v = (p.value / 100.0).clamp(0, 1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Text(
                        p.name,
                        style: OmiTextStyle.create(
                          color: mainTextColor,
                          fontSize: OmiFontSize.t5_14,
                          fontWeight: OmiFontWeight.regular,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: v,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFF2F2F7),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(blueTextColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${p.count} memories',
                      style: OmiTextStyle.create(
                        color: secondTextColor,
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.regular,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          Text(
            summary,
            style: OmiTextStyle.create(
              color: secondTextColor,
              fontSize: OmiFontSize.t5_14,
              fontWeight: OmiFontWeight.regular,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _MPMonthlyTopicsSurfacingCard extends StatelessWidget {
  const _MPMonthlyTopicsSurfacingCard({
    required this.items,
    required this.summary,
  });

  final List<MPMonthlyTopicItem> items;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAEAEA),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.auto_awesome_outlined,
                color: purpleTextColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Topics Resurfacing',
                style: OmiTextStyle.create(
                  color: mainTextColor,
                  fontSize: OmiFontSize.t7_16,
                  fontWeight: OmiFontWeight.medium,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: const Color(0xFFE6E6E6),
            height: 1,
          ),
          const SizedBox(height: 12),
          Column(
            children: items.map((MPMonthlyTopicItem t) {
              final double v = (t.value / 100.0).clamp(0, 1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 112,
                      child: Text(
                        t.label,
                        style: OmiTextStyle.create(
                          color: secondTextColor,
                          fontSize: OmiFontSize.t5_14,
                          fontWeight: OmiFontWeight.regular,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: v,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFF2F2F7),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            purpleTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          Text(
            summary,
            style: OmiTextStyle.create(
              color: secondTextColor,
              fontSize: OmiFontSize.t5_14,
              fontWeight: OmiFontWeight.regular,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _MPMonthlyCard extends StatelessWidget {
  const _MPMonthlyCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAEAEA),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: OmiTextStyle.create(
                    color: mainTextColor,
                    fontSize: OmiFontSize.t7_16,
                    fontWeight: OmiFontWeight.medium,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MPMonthlyBulletList extends StatelessWidget {
  const _MPMonthlyBulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((String t) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.circle, size: 8, color: mainTextColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t,
                  style: OmiTextStyle.create(
                    color: secondTextColor,
                    fontSize: OmiFontSize.t5_14,
                    fontWeight: OmiFontWeight.regular,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MPMonthlyParagraphList extends StatelessWidget {
  const _MPMonthlyParagraphList({required this.paragraphs});

  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: paragraphs.map((String p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            p,
            style: OmiTextStyle.create(
              color: secondTextColor,
              fontSize: OmiFontSize.t5_14,
              fontWeight: OmiFontWeight.regular,
              height: 1.45,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MPMonthlyDecisionList extends StatelessWidget {
  const _MPMonthlyDecisionList({required this.items});

  final List<MPMonthlyDecisionItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((MPMonthlyDecisionItem d) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${d.rank}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  d.text,
                  style: OmiTextStyle.create(
                    color: secondTextColor,
                    fontSize: OmiFontSize.t5_14,
                    fontWeight: OmiFontWeight.regular,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MPMonthlySuggestedFocusList extends StatelessWidget {
  const _MPMonthlySuggestedFocusList({required this.items});

  final List<MPMonthlySuggestedFocusItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((MPMonthlySuggestedFocusItem f) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: blueTextColor.withValues(alpha: 100),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${f.rank}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  f.text,
                  style: OmiTextStyle.create(
                    color: secondTextColor,
                    fontSize: OmiFontSize.t5_14,
                    fontWeight: OmiFontWeight.regular,
                    height: 1.4,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: blueTextColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: blueTextColor.withValues(alpha: 60)),
                  ),
                  minimumSize: const Size(0, 0),
                ),
                onPressed: () => MPToastUtils.showFeatureComingSoon(
                  message: 'Add to Todo: ${f.text}',
                ),
                child: const Text(
                  'Add to Todo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

