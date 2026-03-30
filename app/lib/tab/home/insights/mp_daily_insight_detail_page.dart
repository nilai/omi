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

/// Daily Insight 详情页
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
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => MPToastUtils.showFeatureComingSoon(
                      message: 'Share daily insight',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => MPToastUtils.showFeatureComingSoon(
                      message: 'Daily options',
                    ),
                  ),
                ],
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
        return const MPTristatePage(type: MPTristateType.loading);
      case MPInsightDetailPhase.error:
        return MPTristatePage(
          type: MPTristateType.error,
          data: MPTristatePageData(
            title: 'Unable to load Daily insight',
            description: state.errorMessage ?? '请稍后重试',
            buttonText: 'Retry',
            onButtonPressed: () =>
                context.read<MPInsightDetailCubit>().initData(),
          ),
        );
      case MPInsightDetailPhase.loaded:
        final MPDailyInsightDetailData? daily = state.data?.daily;
        if (daily == null) {
          return const MPTristatePage(type: MPTristateType.empty);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                child: Text(
                  daily.dateLabel,
                  style: OmiTextStyle.create(
                    color: mainTextColor,
                    fontSize: OmiFontSize.t11_20,
                    fontWeight: OmiFontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              _MPDailyCard(
                title: daily.narrativeTitle,
                icon: Icons.radar_outlined,
                iconColor: const Color(0xFF3C7BEE),
                child: Text(
                  daily.narrativeBody,
                  style: OmiTextStyle.create(
                    color: secondTextColor,
                    fontSize: OmiFontSize.t5_14,
                    fontWeight: OmiFontWeight.regular,
                    height: 1.52,
                  ),
                ),
              ),
              if (daily.decisionsMade.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPDailyCard(
                  title: 'Decisions made',
                  icon: Icons.check_box_outlined,
                  iconColor: const Color(0xFF3FB26E),
                  child: _MPDotTextList(
                    items: daily.decisionsMade,
                    dotColor: const Color(0xFF8FA76D),
                  ),
                ),
              ],
              if (daily.openQuestions.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPDailyCard(
                  title: 'Open questions',
                  icon: Icons.error_outline,
                  iconColor: const Color(0xFFDA8A3F),
                  child: _MPDotTextList(
                    items: daily.openQuestions,
                    dotColor: const Color(0xFFDA8A3F),
                  ),
                ),
              ],
              if (daily.patternsEmerging.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPDailyCard(
                  title: 'Patterns emerging',
                  icon: Icons.auto_awesome_outlined,
                  iconColor: const Color(0xFF9C5CE4),
                  child: Text(
                    daily.patternsEmerging,
                    style: OmiTextStyle.create(
                      color: secondTextColor,
                      fontSize: OmiFontSize.t5_14,
                      fontWeight: OmiFontWeight.regular,
                      height: 1.52,
                    ),
                  ),
                ),
              ],
              if (daily.ideasCaptured.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPDailyCard(
                  title: 'Ideas captured',
                  icon: Icons.lightbulb_outline,
                  iconColor: const Color(0xFFD39F3E),
                  child: _MPDotTextList(
                    items: daily.ideasCaptured,
                    dotColor: const Color(0xFFD39F3E),
                  ),
                ),
              ],
              if (daily.tomorrowFocus.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPDailyTomorrowFocusCard(items: daily.tomorrowFocus),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => MPToastUtils.showFeatureComingSoon(
                  message: daily.askAiButtonText,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7436E7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Ask AI about today'),
              ),
            ],
          ),
        );
    }
  }
}

class _MPDailyCard extends StatelessWidget {
  const _MPDailyCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: OmiTextStyle.create(
                  color: mainTextColor,
                  fontSize: OmiFontSize.t6_15,
                  fontWeight: OmiFontWeight.medium,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE7E7E7)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MPDotTextList extends StatelessWidget {
  const _MPDotTextList({
    required this.items,
    required this.dotColor,
  });

  final List<String> items;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((String text) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Icon(Icons.circle, size: 5, color: dotColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: OmiTextStyle.create(
                    color: secondTextColor,
                    fontSize: OmiFontSize.t5_14,
                    fontWeight: OmiFontWeight.regular,
                    height: 1.45,
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

class _MPDailyTomorrowFocusCard extends StatelessWidget {
  const _MPDailyTomorrowFocusCard({required this.items});

  final List<MPDailyFocusItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Tomorrow\'s focus',
            style: OmiTextStyle.create(
              color: mainTextColor,
              fontSize: OmiFontSize.t6_15,
              fontWeight: OmiFontWeight.medium,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE7E7E7)),
          const SizedBox(height: 8),
          ...items.asMap().entries.map((MapEntry<int, MPDailyFocusItem> entry) {
            final MPDailyFocusItem focus = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                border: entry.key == items.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFEAEAEA), width: 1),
                      ),
              ),
              child: Row(
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.circle, size: 5, color: Color(0xFF8FA76D)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      focus.text,
                      style: OmiTextStyle.create(
                        color: secondTextColor,
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.regular,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => MPToastUtils.showFeatureComingSoon(
                      message: 'Add to Todo: ${focus.text}',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4A82E8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

