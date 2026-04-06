import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/common/mp_tristate_page.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../generated/assets.dart';
import 'mp_insight_detail_cubit.dart';
import 'mp_insights_list_cubit.dart';

const Color _kWeeklyPageBgColor = Color(0xFFF2F2F7);

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
            backgroundColor: _kWeeklyPageBgColor,
            appBar: PreferredSize(
              preferredSize: _MPWeeklyAppBar.preferredSizeOf(context),
              child: _MPWeeklyAppBar(
                subtitle: item.periodLabel,
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

class _MPWeeklyAppBar extends StatelessWidget {
  const _MPWeeklyAppBar({
    required this.subtitle,
    required this.onBack,
  });

  final String subtitle;
  final VoidCallback onBack;

  static Size preferredSizeOf(BuildContext context) {
    final double top = MediaQuery.paddingOf(context).top;
    return Size.fromHeight(top + 66);
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: topInset, right: 16),
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
                    'Weekly Insights',
                    style: OmiTextStyle.create(
                      color: mainTextColor,
                      fontSize: OmiFontSize.t8_17,
                      fontWeight: OmiFontWeight.medium,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: OmiTextStyle.create(
                      color: secondTextColor,
                      fontSize: OmiFontSize.t4_13,
                      fontWeight: OmiFontWeight.regular,
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
                      message: 'Share weekly insight',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => MPToastUtils.showFeatureComingSoon(
                      message: 'Weekly options',
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
        final MPWeeklyInsightDetailData? weekly = state.data?.weekly;
        if (weekly == null) {
          return const MPTristatePage(type: MPTristateType.empty);
        }
        final List<MPWeeklyPendingItem> visiblePendingItems = weekly
            .pendingItemCards
            .where((MPWeeklyPendingItem e) => e.visible)
            .toList();
        final List<MPWeeklyPriorityItem> visiblePriorities = weekly
            .nextWeekPriorities
            .where((MPWeeklyPriorityItem e) => e.visible)
            .toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 1. Week Header
              _MPWeeklyHeaderCard(
                title: weekly.titleLabel,
                subLabel: weekly.subLabel,
                summary: weekly.headerSummary,
              ),
              // 2. Week Summary
              if (weekly.weekSummaryText.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPWeeklySummaryCard(
                  summary: weekly.weekSummaryText,
                  metrics: weekly.metrics,
                ),
              ],
              // 3. Accomplishments
              if (weekly.accomplishmentItems.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPWeeklyAccomplishmentsCard(
                  items: weekly.accomplishmentItems,
                ),
              ],
              // 4. Challenges & Learnings
              if (weekly.challengeLearningItems.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPWeeklyChallengesLearningsCard(
                  items: weekly.challengeLearningItems,
                ),
              ],
              // 5. Pending items
              if (visiblePendingItems.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPWeeklyPendingItemsCard(
                  items: visiblePendingItems,
                ),
              ],
              // 6. Next Week Priorities
              if (visiblePriorities.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPWeeklyPrioritiesCard(items: visiblePriorities),
              ],
              // 7. Expert Weekly Feedback
              if (weekly.expertWeeklyFeedback.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPWeeklyExpertFeedbackCard(items: weekly.expertWeeklyFeedback),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => MPToastUtils.showFeatureComingSoon(
                  message: weekly.askAiButtonText,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7436E7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Ask AI about this week'),
              ),
            ],
          ),
        );
    }
  }
}

class _MPWeeklyCardShell extends StatelessWidget {
  const _MPWeeklyCardShell({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: child,
    );
  }
}

class _MPWeeklyHeaderCard extends StatelessWidget {
  const _MPWeeklyHeaderCard({
    required this.title,
    required this.subLabel,
    required this.summary,
  });

  final String title;
  final String subLabel;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE4EDF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD2E0EE),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Text(
                '📊',
                style: TextStyle(
                  fontSize: 18,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: OmiTextStyle.create(
                    color: mainTextColor,
                    fontSize: OmiFontSize.t9_18,
                    fontWeight: OmiFontWeight.bold,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              subLabel,
              style: OmiTextStyle.create(
                color: const Color(0xFF8B919A),
                fontSize: OmiFontSize.t5_14,
                fontWeight: OmiFontWeight.regular,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: OmiTextStyle.create(
              color: const Color(0xFF3E464F),
              fontSize: OmiFontSize.t6_15,
              fontWeight: OmiFontWeight.regular,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MPWeeklySummaryCard extends StatelessWidget {
  const _MPWeeklySummaryCard({
    required this.summary,
    required this.metrics,
  });

  final String summary;
  final List<MPWeeklyMetricItem> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Week Summary',
            style: OmiTextStyle.create(
              color: mainTextColor,
              fontSize: OmiFontSize.t6_15,
              fontWeight: OmiFontWeight.medium,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Focus Areas',
            style: OmiTextStyle.create(
              color: secondTextColor,
              fontSize: OmiFontSize.t5_14,
              fontWeight: OmiFontWeight.regular,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: OmiTextStyle.create(
              color: const Color(0xFF3F4750),
              fontSize: OmiFontSize.t6_15,
              fontWeight: OmiFontWeight.regular,
              height: 1.45,
            ),
          ),
          if (metrics.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'Key Metrics',
              style: OmiTextStyle.create(
                color: secondTextColor,
                fontSize: OmiFontSize.t5_14,
                fontWeight: OmiFontWeight.regular,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: metrics.asMap().entries.map((MapEntry<int, MPWeeklyMetricItem> e) {
                final MPWeeklyMetricItem m = e.value;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: e.key == metrics.length - 1 ? 0 : 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: <Widget>[
                        Text(
                          m.value,
                          style: OmiTextStyle.create(
                            color: const Color(0xFF3A8FBB),
                            fontSize: OmiFontSize.t13_22,
                            fontWeight: OmiFontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.label,
                          style: OmiTextStyle.create(
                            color: secondTextColor,
                            fontSize: OmiFontSize.t4_13,
                            fontWeight: OmiFontWeight.regular,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MPWeeklyAccomplishmentsCard extends StatelessWidget {
  const _MPWeeklyAccomplishmentsCard({required this.items});

  final List<MPWeeklyAccomplishmentItem> items;

  @override
  Widget build(BuildContext context) {
    return _MPWeeklyCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Accomplishments',
            style: OmiTextStyle.create(
              color: mainTextColor,
              fontSize: OmiFontSize.t11_20,
              fontWeight: OmiFontWeight.bold,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((MapEntry<int, MPWeeklyAccomplishmentItem> e) {
            final MPWeeklyAccomplishmentItem item = e.value;
            return Padding(
              padding: EdgeInsets.only(bottom: e.key == items.length - 1 ? 0 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDEFF5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.circle,
                      size: 7,
                      color: Color(0xFF339CC1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.title,
                          style: OmiTextStyle.create(
                            color: mainTextColor,
                            fontSize: OmiFontSize.t6_15,
                            fontWeight: OmiFontWeight.medium,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: OmiTextStyle.create(
                            color: secondTextColor,
                            fontSize: OmiFontSize.t5_14,
                            fontWeight: OmiFontWeight.regular,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MPWeeklyChallengesLearningsCard extends StatelessWidget {
  const _MPWeeklyChallengesLearningsCard({required this.items});

  final List<MPWeeklyChallengeLearningItem> items;

  @override
  Widget build(BuildContext context) {
    return _MPWeeklyCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Challenges & Learnings',
            style: OmiTextStyle.create(
              color: mainTextColor,
              fontSize: OmiFontSize.t6_15,
              fontWeight: OmiFontWeight.medium,
            ),
          ),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((MapEntry<int, MPWeeklyChallengeLearningItem> e) {
            final MPWeeklyChallengeLearningItem item = e.value;
            return Container(
              margin: EdgeInsets.only(bottom: e.key == items.length - 1 ? 0 : 10),
              decoration: BoxDecoration(
                color: Color(item.backgroundColorValue),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(item.borderColorValue),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: OmiTextStyle.create(
                      color: mainTextColor,
                      fontSize: OmiFontSize.t6_15,
                      fontWeight: OmiFontWeight.medium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: OmiTextStyle.create(
                      color: secondTextColor,
                      fontSize: OmiFontSize.t5_14,
                      fontWeight: OmiFontWeight.regular,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MPWeeklyPendingItemsCard extends StatelessWidget {
  const _MPWeeklyPendingItemsCard({required this.items});

  final List<MPWeeklyPendingItem> items;

  @override
  Widget build(BuildContext context) {
    return _MPWeeklyCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Pending Items',
            style: OmiTextStyle.create(
              color: mainTextColor,
              fontSize: OmiFontSize.t6_15,
              fontWeight: OmiFontWeight.medium,
            ),
          ),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((MapEntry<int, MPWeeklyPendingItem> e) {
            final MPWeeklyPendingItem item = e.value;
            return Padding(
              padding: EdgeInsets.only(bottom: e.key == items.length - 1 ? 0 : 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => MPToastUtils.showFeatureComingSoon(
                    message: item.text,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.star_outline_rounded,
                            size: 16,
                            color: Color(0xFFDA8A3F),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.text,
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
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MPWeeklyPrioritiesCard extends StatelessWidget {
  const _MPWeeklyPrioritiesCard({required this.items});

  final List<MPWeeklyPriorityItem> items;

  @override
  Widget build(BuildContext context) {
    return _MPWeeklyCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Next Week Priorities',
            style: OmiTextStyle.create(
              color: mainTextColor,
              fontSize: OmiFontSize.t6_15,
              fontWeight: OmiFontWeight.medium,
            ),
          ),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((MapEntry<int, MPWeeklyPriorityItem> e) {
            final MPWeeklyPriorityItem item = e.value;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: e.key == items.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFEAEAEA), width: 1),
                      ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF44B0C6).withValues(alpha: 50),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${e.key + 1}',
                      style: OmiTextStyle.create(
                        color: Colors.white,
                        fontSize: OmiFontSize.t3_12,
                        fontWeight: OmiFontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.text,
                          style: OmiTextStyle.create(
                            color: mainTextColor,
                            fontSize: OmiFontSize.t6_15,
                            fontWeight: OmiFontWeight.medium,
                            height: 1.35,
                          ),
                        ),
                        if (item.subtitle.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: OmiTextStyle.create(
                              color: secondTextColor,
                              fontSize: OmiFontSize.t5_14,
                              fontWeight: OmiFontWeight.regular,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => MPToastUtils.showFeatureComingSoon(
                      message: 'Add to Todo: ${item.text}',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4A82E8),
                      backgroundColor: const Color(0xFFEAF0FA),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Add to Todo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MPWeeklyExpertFeedbackCard extends StatelessWidget {
  const _MPWeeklyExpertFeedbackCard({required this.items});

  final List<MPWeeklyExpertFeedbackItem> items;

  @override
  Widget build(BuildContext context) {
    final List<MPWeeklyExpertFeedbackItem> visibleItems = items
        .where((MPWeeklyExpertFeedbackItem e) => e.visible)
        .toList();
    return _MPWeeklyCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Expert Weekly Feedback',
            style: OmiTextStyle.create(
              color: mainTextColor,
              fontSize: OmiFontSize.t6_15,
              fontWeight: OmiFontWeight.medium,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE7E7E7)),
          const SizedBox(height: 10),
          ...visibleItems.asMap().entries.map((MapEntry<int, MPWeeklyExpertFeedbackItem> e) {
            final MPWeeklyExpertFeedbackItem item = e.value;
            return Padding(
              padding: EdgeInsets.only(bottom: e.key == visibleItems.length - 1 ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        _iconDataOf(item.iconKey),
                        size: 15,
                        color: Color(item.iconColorValue),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.title,
                        style: OmiTextStyle.create(
                          color: mainTextColor,
                          fontSize: OmiFontSize.t5_14,
                          fontWeight: OmiFontWeight.medium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.content,
                    style: OmiTextStyle.create(
                      color: secondTextColor,
                      fontSize: OmiFontSize.t4_13,
                      fontWeight: OmiFontWeight.regular,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _iconDataOf(String iconKey) {
    switch (iconKey) {
      case 'business':
        return Icons.business_center_outlined;
      case 'creative':
        return Icons.palette_outlined;
      case 'execution':
        return Icons.build_outlined;
      case 'wellness':
        return Icons.favorite_border;
      default:
        return Icons.lightbulb_outline;
    }
  }
}

