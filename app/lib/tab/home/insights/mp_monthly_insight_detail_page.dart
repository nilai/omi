import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/common/mp_tristate_page.dart';
import 'package:memo_pin/http/schema/mp_data_model.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../memory/detail/mp_detail_visibility_refresh.dart';
import 'mp_insight_detail_cubit.dart';
import 'mp_insights_list_cubit.dart';

import '../../../generated/assets.dart';

/// Monthly Insight 详情页（按 design 再排版）
class MPMonthlyInsightDetailPage extends StatelessWidget {
  const MPMonthlyInsightDetailPage({super.key, required this.item});

  final MPInsightListItem item;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPInsightDetailCubit>(
      create: (_) => MPInsightDetailCubit(item: item)..initData(),
      child: Builder(
        builder: (BuildContext context) {
          return MPDetailVisibilityRefresh(
            onRefresh: () => context.read<MPInsightDetailCubit>().refresh(),
            child: BlocBuilder<MPInsightDetailCubit, MPInsightDetailState>(
              builder: (BuildContext context, MPInsightDetailState state) {
                return Scaffold(
                  backgroundColor: pageColor,
                  appBar: PreferredSize(
                    preferredSize: _MPMonthlyAppBar.preferredSizeOf(context),
                    child: _MPMonthlyAppBar(monthSubtitle: item.periodLabel, onBack: () => Navigator.of(context).maybePop()),
                  ),
                  body: _MPMonthlyInsightBody(state: state),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MPMonthlyAppBar extends StatelessWidget {
  const _MPMonthlyAppBar({required this.monthSubtitle, required this.onBack});

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
                icon: OmiImageLoader.localImg(Assets.omiLeftBack, color: blueTextColor, width: 20, height: 20),
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
                    icon: const Icon(Icons.share_outlined, color: blueTextColor),
                    onPressed: () => context.read<MPInsightDetailCubit>().showShareExportSheet(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: blueTextColor),
                    onPressed: () => context.read<MPInsightDetailCubit>().showMoreDialog(context),
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
            description: state.errorMessage ?? 'Please try again later.',
            buttonText: 'Retry',
            onButtonPressed: () => context.read<MPInsightDetailCubit>().initData(),
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
              _MPMonthlyMonthOverviewCard(summary: monthly.monthOverviewSummary),
              const SizedBox(height: 12),
              if (monthly.attentionDistribution.isNotEmpty)
                _MPMonthlyAttentionDistributionCard(
                  items: monthly.attentionDistribution,
                  summary: monthly.attentionDistributionSummary,
                ),
              if (monthly.keyPeopleThisMonth.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPMonthlyKeyPeopleCard(items: monthly.keyPeopleThisMonth, summary: monthly.keyPeopleThisMonthSummary),
              ],
              if (monthly.topicsSurfacing.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPMonthlyTopicsSurfacingCard(items: monthly.topicsSurfacing, summary: monthly.topicsSurfacingSummary),
              ],
              if (monthly.longRunningOpenThreads.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPMonthlyOpenThreadsCard(
                  items: monthly.longRunningOpenThreads,
                  summary: monthly.longRunningOpenThreadsSummary,
                ),
              ],
              if (monthly.monthToMonthTrend.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPMonthlyTrendCard(paragraphs: monthly.monthToMonthTrend),
              ],
              if (monthly.decisionsThatCannotSlipAgain.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPMonthlyCannotSlipDecisionsCard(
                  items: monthly.decisionsThatCannotSlipAgain,
                  summary: monthly.decisionsThatCannotSlipAgainSummary,
                ),
              ],
              if (monthly.suggestedFocusNextMonth.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPMonthlySuggestedFocusCard(items: monthly.suggestedFocusNextMonth),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => context.read<MPInsightDetailCubit>().onAskAiButtonPressed(context),
                style: FilledButton.styleFrom(
                  backgroundColor: purpleTextColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
        border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              OmiImageLoader.localImg(
                Assets.mpInsightCompass,
                width: 20,
                height: 20,
                color: orangeTextColor,
                fit: BoxFit.contain,
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
          Divider(color: const Color(0xFFE6E6E6), height: 1),
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
  const _MPMonthlyAttentionDistributionCard({required this.items, required this.summary});

  final List<MPMonthlyBarItem> items;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.bar_chart_outlined, color: blueTextColor, size: 20),
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
          Divider(color: const Color(0xFFE6E6E6), height: 1),
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
                          valueColor: AlwaysStoppedAnimation<Color>(blueTextColor),
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
  const _MPMonthlyKeyPeopleCard({required this.items, required this.summary});

  final List<MPMonthlyKeyPersonItem> items;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              OmiImageLoader.localImg(
                Assets.mpMineUsers,
                width: 20,
                height: 20,
                color: blueTextColor,
                fit: BoxFit.contain,
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
          Divider(color: const Color(0xFFE6E6E6), height: 1),
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
                          valueColor: AlwaysStoppedAnimation<Color>(blueTextColor),
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
  const _MPMonthlyTopicsSurfacingCard({required this.items, required this.summary});

  final List<MPMonthlyTopicItem> items;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              OmiImageLoader.localImg(
                Assets.mpInsightBrain,
                width: 20,
                height: 20,
                color: purpleTextColor,
                fit: BoxFit.contain,
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
          Divider(color: const Color(0xFFE6E6E6), height: 1),
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
                          valueColor: AlwaysStoppedAnimation<Color>(purpleTextColor),
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

class _MPMonthlyOpenThreadsCard extends StatelessWidget {
  const _MPMonthlyOpenThreadsCard({required this.items, required this.summary});

  final List<String> items;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, color: orangeTextColor, size: 20),
              const SizedBox(width: 10),
              Text(
                'Long-running Open Threads',
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
          const Divider(color: Color(0xFFE6E6E6), height: 1),
          const SizedBox(height: 12),
          ...items.map((String t) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Icon(Icons.circle, size: 7, color: orangeTextColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: OmiTextStyle.create(
                        color: secondTextColor,
                        fontSize: OmiFontSize.t6_15,
                        fontWeight: OmiFontWeight.regular,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
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

class _MPMonthlyTrendCard extends StatelessWidget {
  const _MPMonthlyTrendCard({required this.paragraphs});

  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.trending_up, color: greenTextColor, size: 20),
              const SizedBox(width: 10),
              Text(
                'Month-to-Month Trend',
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
          const Divider(color: Color(0xFFE6E6E6), height: 1),
          const SizedBox(height: 12),
          ...paragraphs.map((String p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                p,
                style: OmiTextStyle.create(
                  color: secondTextColor,
                  fontSize: OmiFontSize.t6_15,
                  fontWeight: OmiFontWeight.regular,
                  height: 1.35,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MPMonthlyCannotSlipDecisionsCard extends StatelessWidget {
  const _MPMonthlyCannotSlipDecisionsCard({required this.items, required this.summary});

  final List<MPMonthlyDecisionItem> items;
  final String summary;

  static const Color _kDecisionRed = Color(0xFFFF3B30);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.error_outline_rounded, color: _kDecisionRed, size: 20),
              const SizedBox(width: 10),
              Text(
                'Decisions That Cannot Slip Again',
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
          const Divider(color: Color(0xFFE6E6E6), height: 1),
          const SizedBox(height: 12),
          Text(
            summary,
            style: OmiTextStyle.create(
              color: secondTextColor,
              fontSize: OmiFontSize.t5_14,
              fontWeight: OmiFontWeight.regular,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((MPMonthlyDecisionItem d) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(color: _kDecisionRed, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      '${d.rank}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      d.text,
                      style: OmiTextStyle.create(
                        color: mainTextColor,
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.regular,
                        height: 1.4,
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

class _MPMonthlySuggestedFocusCard extends StatefulWidget {
  const _MPMonthlySuggestedFocusCard({required this.items});

  final List<MPTodoStruct> items;

  @override
  State<_MPMonthlySuggestedFocusCard> createState() => _MPMonthlySuggestedFocusCardState();
}

class _MPMonthlySuggestedFocusCardState extends State<_MPMonthlySuggestedFocusCard> {
  final Set<int> _addedIndexes = <int>{};

  static const Color _kFocusBlue = Color(0xFF3C7BEE);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              OmiImageLoader.localImg(
                Assets.mpInsightTarget,
                width: 20,
                height: 20,
                color: _kFocusBlue,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Text(
                'Suggested Focus Next Month',
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
          const Divider(color: Color(0xFFE6E6E6), height: 1),
          const SizedBox(height: 6),
          ...widget.items.asMap().entries.map((MapEntry<int, MPTodoStruct> e) {
            final int idx = e.key;
            final MPTodoStruct f = e.value;
            final bool isAdded = _addedIndexes.contains(idx) || mpInsightTodoIsAdded(f);
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: idx == widget.items.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: Color(0xFFEDEDED), width: 1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(color: _kFocusBlue, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (f.title ?? '').trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: OmiTextStyle.create(
                        color: mainTextColor,
                        fontSize: OmiFontSize.t6_15,
                        fontWeight: OmiFontWeight.regular,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  isAdded
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F7EE),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(Icons.check, size: 13, color: Color(0xFF34C759)),
                              const SizedBox(width: 4),
                              Text(
                                'Added',
                                style: OmiTextStyle.create(
                                  color: const Color(0xFF1BAA52),
                                  fontSize: OmiFontSize.t4_13,
                                  fontWeight: OmiFontWeight.medium,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        )
                      : FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFEAF2FF),
                            foregroundColor: const Color(0xFF0A84FF),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            minimumSize: const Size(0, 0),
                          ),
                          onPressed: () async {
                            final cubit = context.read<MPInsightDetailCubit>();
                            final MPMonthlyInsightDetailData? monthly = cubit.state.data?.monthly;
                            final title = monthly?.monthSubtitle ?? '';
                            final subtitle = '';
                            final String label = title.isNotEmpty || subtitle.isNotEmpty ? 'From Monthly Insight:' : '';
                            final result = await cubit.showAddTodoPopup(
                              f,
                              context,
                              MPInsightTodoContentStruct(label: label, title: title, metaLine: subtitle),
                            );
                            if (!mounted) {
                              return;
                            }

                            if (result != null) {
                              setState(() {
                                _addedIndexes.add(idx);
                              });
                            }
                          },
                          child: Text(
                            'Add to Todo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: OmiTextStyle.create(
                              color: const Color(0xFF0A84FF),
                              fontSize: OmiFontSize.t4_13,
                              fontWeight: OmiFontWeight.medium,
                              height: 1.1,
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
