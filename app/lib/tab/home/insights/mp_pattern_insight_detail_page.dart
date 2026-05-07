import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/common/mp_custom_nav_bar.dart';
import 'package:memo_pin/common/mp_tristate_page.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../common/omi_add_todo_popup.dart';
import 'mp_insight_detail_cubit.dart';
import 'mp_insights_list_cubit.dart';

/// Pattern Insight 详情页（强调“主题 + 相关记忆”）
class MPPatternInsightDetailPage extends StatelessWidget {
  const MPPatternInsightDetailPage({super.key, required this.item});

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
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: blueTextColor),
                    tooltip: 'Share',
                    onPressed: () => context.read<MPInsightDetailCubit>().showShareExportSheet(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: blueTextColor),
                    onPressed: () => context.read<MPInsightDetailCubit>().showMoreDialog(context),
                  ),
                ],
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
            description: state.errorMessage ?? 'Please try again later.',
            buttonText: 'Retry',
            onButtonPressed: () => context.read<MPInsightDetailCubit>().initData(),
          ),
        );
      case MPInsightDetailPhase.loaded:
        final MPInsightListItem item = state.data!.item;
        final int appearedCount = item.patternMemoryTitles.length;
        final String topDescription = state.data!.paragraphs.isNotEmpty ? state.data!.paragraphs[0] : '';
        final String whyText = state.data!.paragraphs.length > 1 ? state.data!.paragraphs[1] : '';
        final String nextStepText = state.data!.tips.isNotEmpty ? state.data!.tips.first : '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _EmergingPatternHeader(label: 'Emerging pattern detected', isFloating: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(0),
                child: Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _PatternDetectedTitle(icon: Icons.handyman),
                        const SizedBox(height: 12),
                        Text(
                          topDescription,
                          style: OmiTextStyle.create(
                            color: mainTextColor,
                            fontSize: OmiFontSize.t6_15,
                            fontWeight: OmiFontWeight.regular,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _AppearedSection(
                          appearedItems: item.patternMemoryTitles,
                          onItemTap: (String title) {
                            MPToastUtils.showFeatureComingSoon(message: 'Open memory: $title');
                          },
                          appearedCount: appearedCount,
                        ),
                        const SizedBox(height: 16),
                        _WhyThisMattersSection(whyText: whyText),
                        const SizedBox(height: 16),
                        _SuggestedNextStepSection(nextStepText: nextStepText),
                        const SizedBox(height: 18),
                        _AskAiButton(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _EmergingPatternHeader extends StatelessWidget {
  const _EmergingPatternHeader({required this.label, this.isFloating = false});

  final String label;
  final bool isFloating;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFFFF3D9), Color(0xFFFFFBF0)],
        ),
        borderRadius: isFloating ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: OmiTextStyle.create(
              color: orangeTextColor,
              fontSize: OmiFontSize.t7_16,
              fontWeight: OmiFontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternDetectedTitle extends StatelessWidget {
  const _PatternDetectedTitle({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 24,
          height: 24,
          // decoration: BoxDecoration(
          //   color: purpleTextColor.withValues(alpha: 16),
          //   shape: BoxShape.circle,
          // ),
          // child: Icon(icon, color: purpleTextColor, size: 16),
          child: Center(child: Text('🧠', style: TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 10),
        Text(
          'Pattern Detected',
          style: OmiTextStyle.create(
            color: mainTextColor,
            fontSize: OmiFontSize.t8_17,
            fontWeight: OmiFontWeight.bold,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _AppearedSection extends StatelessWidget {
  const _AppearedSection({required this.appearedItems, required this.onItemTap, required this.appearedCount});

  final List<String> appearedItems;
  final ValueChanged<String> onItemTap;
  final int appearedCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            // Icon(Icons.place_outlined, color: orangeTextColor, size: 18),
            Text('📍', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Text(
              'Where This Appeared',
              style: OmiTextStyle.create(
                color: mainTextColor,
                fontSize: OmiFontSize.t6_15,
                fontWeight: OmiFontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(color: const Color(0xFFEDEDED), height: 1),
        const SizedBox(height: 12),
        Text(
          'Appeared in recent memories:',
          style: OmiTextStyle.create(
            color: secondTextColor,
            fontSize: OmiFontSize.t5_14,
            fontWeight: OmiFontWeight.regular,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: appearedItems.map((String raw) {
            final (_MemoryTileParts parts) = _parseMemoryTile(raw);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onItemTap(parts.title),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: orangeTextColor, borderRadius: BorderRadius.circular(999)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${parts.title} — ${parts.date}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: OmiTextStyle.create(
                              color: mainTextColor,
                              fontSize: OmiFontSize.t6_15,
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
          }).toList(),
        ),
        Text(
          'Appeared in $appearedCount conversations.',
          style: OmiTextStyle.create(
            color: secondTextColor,
            fontSize: OmiFontSize.t5_14,
            fontWeight: OmiFontWeight.regular,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _MemoryTileParts {
  const _MemoryTileParts({required this.title, required this.date});

  final String title;
  final String date;
}

_MemoryTileParts _parseMemoryTile(String raw) {
  // Example raw: "Team standup — Jan 18"
  const String sep = '—';
  final List<String> parts = raw.split(sep);
  if (parts.length >= 2) {
    return _MemoryTileParts(title: parts[0].trim(), date: parts[1].trim());
  }
  return _MemoryTileParts(title: raw.trim(), date: '');
}

class _WhyThisMattersSection extends StatelessWidget {
  const _WhyThisMattersSection({required this.whyText});

  final String whyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            // Icon(Icons.warning_amber_rounded, color: const Color(0xFFFF9500), size: 18),
            Text('⚠️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Text(
              'Why This Matters',
              style: OmiTextStyle.create(
                color: mainTextColor,
                fontSize: OmiFontSize.t6_15,
                fontWeight: OmiFontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(color: const Color(0xFFEDEDED), height: 1),
        const SizedBox(height: 14),
        Text(
          whyText,
          style: OmiTextStyle.create(
            color: secondTextColor,
            fontSize: OmiFontSize.t6_15,
            fontWeight: OmiFontWeight.regular,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _SuggestedNextStepSection extends StatefulWidget {
  const _SuggestedNextStepSection({required this.nextStepText});

  final String nextStepText;

  @override
  State<_SuggestedNextStepSection> createState() => _SuggestedNextStepSectionState();
}

class _SuggestedNextStepSectionState extends State<_SuggestedNextStepSection> {
  bool _added = false;

  @override
  Widget build(BuildContext context) {
    final String text = widget.nextStepText;
    final bool canAdd = text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('🎯', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Text(
              'Suggested Next Step',
              style: OmiTextStyle.create(
                color: mainTextColor,
                fontSize: OmiFontSize.t6_15,
                fontWeight: OmiFontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(color: const Color(0xFFEDEDED), height: 1),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                text,
                style: OmiTextStyle.create(
                  color: secondTextColor,
                  fontSize: OmiFontSize.t6_15,
                  fontWeight: OmiFontWeight.regular,
                  height: 1.6,
                ),
              ),
            ),
            if (canAdd) ...<Widget>[
              const SizedBox(width: 12),
              _added
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
                          params: MPAddTodoPopupParams(initialTitle: text.trim()),
                        );
                        if (!mounted) {
                          return;
                        }
                        if (result != null) {
                          setState(() => _added = true);
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
                        'Add As Todo',
                        style: OmiTextStyle.create(
                          color: const Color(0xFF0A84FF),
                          fontSize: OmiFontSize.t4_13,
                          fontWeight: OmiFontWeight.medium,
                          height: 1.1,
                        ),
                      ),
                    ),
            ],
          ],
        ),
      ],
    );
  }
}

class _AskAiButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: purpleTextColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: () => context.read<MPInsightDetailCubit>().onAskAiButtonPressed(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.auto_awesome, size: 18),
          const SizedBox(width: 10),
          const Text('Ask AI About This Pattern', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
