import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/common/mp_custom_nav_bar.dart';
import 'package:memo_pin/common/mp_tristate_page.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../common/omi_add_todo_popup.dart';
import '../../../generated/assets.dart';
import '../../../utils/omi_image_loader.dart';
import 'mp_insight_detail_cubit.dart';
import 'mp_insights_list_cubit.dart';

const Color _kDailyPageBgColor = Color(0xFFF2F2F7);

/// Daily Insight 详情页
class MPDailyInsightDetailPage extends StatelessWidget {
  const MPDailyInsightDetailPage({super.key, required this.item});

  final MPInsightListItem item;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPInsightDetailCubit>(
      create: (_) => MPInsightDetailCubit(item: item)..initData(),
      child: BlocBuilder<MPInsightDetailCubit, MPInsightDetailState>(
        builder: (BuildContext context, MPInsightDetailState state) {
          return Scaffold(
            backgroundColor: _kDailyPageBgColor,
            appBar: PreferredSize(
              preferredSize: MPCustomNavBar.preferredSizeOf(context),
              child: MPCustomNavBar(
                title: 'Daily Insight',
                backgroundColor: Colors.white,
                onBack: () => Navigator.of(context).maybePop(),
                actions: <Widget>[
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
            description: state.errorMessage ?? 'Please try again later.',
            buttonText: 'Retry',
            onButtonPressed: () => context.read<MPInsightDetailCubit>().initData(),
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
                iconAsset: Assets.mpInsightCompass,
                iconColor: const Color(0xFF3C7BEE),
                iconBgColor: const Color(0xFFEAF0FE),
                contentBgColor: const Color(0xFFF2F6FF),
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
                  iconAsset: Assets.mpInsightSquareCheck,
                  iconColor: const Color(0xFF3FB26E),
                  iconBgColor: const Color(0xFFE8F7EE),
                  contentBgColor: const Color(0xFFF2FAF4),
                  child: _MPDotTextList(items: daily.decisionsMade, dotColor: const Color(0xFF8FA76D)),
                ),
              ],
              if (daily.openQuestions.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPDailyCard(
                  title: 'Open questions',
                  icon: Icons.error_outline,
                  iconAsset: Assets.mpInsightCircleAlert,
                  iconColor: const Color(0xFFDA8A3F),
                  iconBgColor: const Color(0xFFFFF1E3),
                  contentBgColor: const Color(0xFFFFF7EE),
                  child: _MPDotTextList(items: daily.openQuestions, dotColor: const Color(0xFFDA8A3F)),
                ),
              ],
              if (daily.patternsEmerging.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPDailyCard(
                  title: 'Patterns emerging',
                  icon: Icons.auto_awesome_outlined,
                  iconAsset: Assets.mpInsightRotate,
                  iconColor: const Color(0xFF9C5CE4),
                  iconBgColor: const Color(0xFFF2EAFE),
                  contentBgColor: const Color(0xFFF7F1FF),
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
                  iconAsset: Assets.mpInsightLightbulb,
                  iconColor: const Color(0xFFD39F3E),
                  iconBgColor: const Color(0xFFFFF5E0),
                  contentBgColor: const Color(0xFFFFF9EB),
                  child: _MPDotTextList(items: daily.ideasCaptured, dotColor: const Color(0xFFD39F3E)),
                ),
              ],
              if (daily.tomorrowFocus.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _MPDailyTomorrowFocusCard(items: daily.tomorrowFocus),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.read<MPInsightDetailCubit>().onAskAiButtonPressed(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7436E7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(daily.askAiButtonText),
              ),
            ],
          ),
        );
    }
  }
}

class _MPDailyCard extends StatelessWidget {
  /// [iconAsset] 非空且非空字符串时左侧圆标优先使用该资源；否则使用 [icon]。
  const _MPDailyCard({
    required this.title,
    this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.contentBgColor,
    required this.child,
    this.iconAsset,
  });

  final String title;
  final IconData? icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color contentBgColor;
  final Widget child;
  final String? iconAsset;

  Widget _leadingGlyph() {
    final String? assetPath = iconAsset;
    if (assetPath != null && assetPath.isNotEmpty) {
      return OmiImageLoader.localImg(assetPath, width: 14, height: 14, color: iconColor, fit: BoxFit.contain);
    }
    if (icon != null) {
      return Icon(icon, color: iconColor, size: 14);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        // borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(999)),
                alignment: Alignment.center,
                child: _leadingGlyph(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OmiTextStyle.create(
                    color: mainTextColor,
                    fontSize: OmiFontSize.t6_15,
                    fontWeight: OmiFontWeight.medium,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE7E7E7)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: contentBgColor, borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _MPDotTextList extends StatelessWidget {
  const _MPDotTextList({required this.items, required this.dotColor});

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

class _MPDailyTomorrowFocusCard extends StatefulWidget {
  const _MPDailyTomorrowFocusCard({required this.items});

  final List<MPDailyFocusItem> items;

  @override
  State<_MPDailyTomorrowFocusCard> createState() => _MPDailyTomorrowFocusCardState();
}

class _MPDailyTomorrowFocusCardState extends State<_MPDailyTomorrowFocusCard> {
  final Set<int> _addedIndexes = <int>{};

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        // borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
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
          Container(
            decoration: BoxDecoration(color: const Color(0xFFF2F6FF), borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
            child: Column(
              children: widget.items.asMap().entries.map((MapEntry<int, MPDailyFocusItem> entry) {
                final MPDailyFocusItem focus = entry.value;
                final bool isAdded = _addedIndexes.contains(entry.key);
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    border: entry.key == widget.items.length - 1
                        ? null
                        : const Border(bottom: BorderSide(color: Color(0xFFEAEAEA), width: 1)),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: OmiTextStyle.create(
                            color: secondTextColor,
                            fontSize: OmiFontSize.t5_14,
                            fontWeight: OmiFontWeight.regular,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                          : TextButton(
                              onPressed: () async {
                                final MPAddTodoPopupResult? result = await showMPAddTodoPopup(
                                  context,
                                  params: MPAddTodoPopupParams(initialTitle: focus.text, contextMemoryLabel: 'From Daily Insight:'),
                                );
                                if (!mounted) {
                                  return;
                                }
                                if (result != null) {
                                  setState(() {
                                    _addedIndexes.add(entry.key);
                                  });
                                  MPToastUtils.showMessage('To-do created.');
                                } else {
                                  MPToastUtils.showMessage('Couldn\'t create to-do.');
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF0A84FF),
                                backgroundColor: const Color(0xFFEAF2FF),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                'Add to Todo',
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
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
