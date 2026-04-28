import 'package:flutter/material.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

/// 分享弹窗的 Summary 版本选项。
class MPShareSummaryOption {
  const MPShareSummaryOption({
    required this.id,
    required this.title,
    required this.badge,
    required this.timeLabel,
  });

  final String id;
  final String title;
  final String badge;
  final String timeLabel;
}

/// 分享弹窗可勾选的附加内容。
enum MPShareAdditionalContent { transcript, audioRecording }

/// 分享弹窗返回结果。
class MPShareSheetResult {
  const MPShareSheetResult({
    required this.summaryOptionId,
    required this.additionalContent,
    required this.optionalOptionIds,
  });

  final String summaryOptionId;
  final Set<MPShareAdditionalContent> additionalContent;

  /// required==false 的 options 勾选结果（可多选，可取消）。
  final Set<String> optionalOptionIds;
}

/// 分享弹窗参数（用于回显与配置）。
class MPShareSheetParams {
  const MPShareSheetParams({
    this.title = 'Choose content to share',
    this.subtitle = 'Select which summary and additional content to include',
    this.summarySectionTitle = 'SUMMARY VERSION',
    this.additionalSectionTitle = 'INCLUDE ADDITIONAL CONTENT',
    this.continueText = 'Continue',
    this.cancelText = 'Cancel',
    this.initialSummaryOptionId,
    this.initialAdditionalContent = const <MPShareAdditionalContent>{},
    this.initialOptionalOptionIds = const <String>{},
    this.requiredSummaryOptions = const <MPShareSummaryOption>[],
    this.optionalSummaryOptions = const <MPShareSummaryOption>[
      MPShareSummaryOption(
        id: 'original',
        title: 'Original Summary',
        badge: 'Original',
        timeLabel: 'Yesterday, 2:15 PM',
      ),
    ],
    this.showTranscript = true,
    this.showAudioRecording = true,
    this.audioSubtitle = 'Shared as link',
  });

  final String title;
  final String subtitle;
  final String summarySectionTitle;
  final String additionalSectionTitle;
  final String continueText;
  final String cancelText;

  final String? initialSummaryOptionId;
  final Set<MPShareAdditionalContent> initialAdditionalContent;
  final Set<String> initialOptionalOptionIds;

  /// required==true 的 options（展示在上面）。
  final List<MPShareSummaryOption> requiredSummaryOptions;

  /// required==false 的 options（展示在下面）。
  final List<MPShareSummaryOption> optionalSummaryOptions;

  final bool showTranscript;
  final bool showAudioRecording;
  final String audioSubtitle;
}

/// 打开分享弹窗，返回用户选择。
Future<MPShareSheetResult?> showMPShareSheet(
  BuildContext context, {
  MPShareSheetParams params = const MPShareSheetParams(),
  VoidCallback? onShare,
}) {
  return showModalBottomSheet<MPShareSheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (BuildContext sheetContext) {
      return _MPShareSheet(params: params, rootContext: context, onShare: onShare);
    },
  );
}

class _MPShareSheet extends StatefulWidget {
  const _MPShareSheet({required this.params, required this.rootContext, this.onShare});

  final MPShareSheetParams params;
  final BuildContext rootContext;
  final VoidCallback? onShare;

  @override
  State<_MPShareSheet> createState() => _MPShareSheetState();
}

class _MPShareSheetState extends State<_MPShareSheet> {
  late String _selectedSummaryId;
  late final Set<String> _optionalSelectedIds;

  static const Color _kSheetBg = Color(0xFFF2F2F7);

  @override
  void initState() {
    super.initState();
    final List<MPShareSummaryOption> options = <MPShareSummaryOption>[
      ...widget.params.requiredSummaryOptions,
      ...widget.params.optionalSummaryOptions,
    ];
    final String fallback = options.isNotEmpty ? options.first.id : 'original';
    _selectedSummaryId = widget.params.initialSummaryOptionId ?? fallback;
    _optionalSelectedIds = Set<String>.from(widget.params.initialOptionalOptionIds);
  }

  void _onContinue() {
    final MPShareSheetResult result = MPShareSheetResult(
      summaryOptionId: _selectedSummaryId,
      additionalContent: const <MPShareAdditionalContent>{},
      optionalOptionIds: Set<String>.from(_optionalSelectedIds),
    );
    Navigator.of(context).pop(result);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // await showMPShareExportSheet(widget.rootContext);
      // TODO: 可根据导出方式 + result 执行真实分享/导出
      widget.onShare?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final MPShareSheetParams p = widget.params;
    final List<MPShareSummaryOption> requiredOptions = p.requiredSummaryOptions;
    final List<MPShareSummaryOption> optionalOptions = p.optionalSummaryOptions;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: _kSheetBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomSafe),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1D1D6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        fit: FlexFit.loose,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                p.title,
                                textAlign: TextAlign.center,
                                style: OmiTextStyle.create(
                                  fontSize: OmiFontSize.t9_18,
                                  fontWeight: OmiFontWeight.bold,
                                  color: mainTextColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p.subtitle,
                                textAlign: TextAlign.center,
                                style: OmiTextStyle.create(
                                  fontSize: OmiFontSize.t5_14,
                                  fontWeight: OmiFontWeight.regular,
                                  color: secondTextColor,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                p.summarySectionTitle,
                                style: OmiTextStyle.create(
                                  fontSize: OmiFontSize.t3_12,
                                  fontWeight: OmiFontWeight.medium,
                                  color:
                                      secondTextColor.withValues(alpha: 0.9),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _MPSummaryOptionCard(
                                options: requiredOptions.isNotEmpty
                                    ? requiredOptions
                                    : optionalOptions,
                                selectedId: _selectedSummaryId,
                                onChanged: (String id) {
                                  setState(() {
                                    _selectedSummaryId = id;
                                  });
                                },
                              ),
                              const SizedBox(height: 18),
                              Text(
                                p.additionalSectionTitle,
                                style: OmiTextStyle.create(
                                  fontSize: OmiFontSize.t3_12,
                                  fontWeight: OmiFontWeight.medium,
                                  color:
                                      secondTextColor.withValues(alpha: 0.9),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (optionalOptions.isNotEmpty)
                                _MPOptionalOptionsCard(
                                  options: optionalOptions,
                                  selectedIds: _optionalSelectedIds,
                                  onToggle: (String id) {
                                    setState(() {
                                      if (_optionalSelectedIds.contains(id)) {
                                        _optionalSelectedIds.remove(id);
                                      } else {
                                        _optionalSelectedIds.add(id);
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 50,
                        child: TextButton(
                          onPressed: _onContinue,
                          style: TextButton.styleFrom(
                            backgroundColor: blueTextColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                p.continueText,
                                style: OmiTextStyle.create(
                                  fontSize: OmiFontSize.t7_16,
                                  fontWeight: OmiFontWeight.medium,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right_rounded, size: 22),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 50,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: blueTextColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            p.cancelText,
                            style: OmiTextStyle.create(
                              fontSize: OmiFontSize.t7_16,
                              fontWeight: OmiFontWeight.medium,
                              color: blueTextColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MPCardContainer extends StatelessWidget {
  const _MPCardContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _MPSummaryOptionCard extends StatelessWidget {
  const _MPSummaryOptionCard({
    required this.options,
    required this.selectedId,
    required this.onChanged,
  });

  final List<MPShareSummaryOption> options;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _MPCardContainer(
      child: Column(
        children: List<Widget>.generate(options.length, (int i) {
          final MPShareSummaryOption opt = options[i];
          final bool selected = opt.id == selectedId;
          return Column(
            children: <Widget>[
              _MPSummaryTile(
                title: opt.title,
                badge: opt.badge,
                timeLabel: opt.timeLabel,
                selected: selected,
                onTap: () => onChanged(opt.id),
              ),
              if (i != options.length - 1) const Divider(height: 1, color: lineColor,),
            ],
          );
        }),
      ),
    );
  }
}

class _MPOptionalOptionsCard extends StatelessWidget {
  const _MPOptionalOptionsCard({
    required this.options,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<MPShareSummaryOption> options;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return _MPCardContainer(
      child: Column(
        children: List<Widget>.generate(options.length, (int i) {
          final MPShareSummaryOption opt = options[i];
          final bool selected = selectedIds.contains(opt.id);
          return Column(
            children: <Widget>[
              _MPOptionalTile(
                title: opt.title,
                badge: opt.badge,
                timeLabel: opt.timeLabel,
                selected: selected,
                onTap: () => onToggle(opt.id),
              ),
              if (i != options.length - 1)
                const Divider(height: 1, color: lineColor,),
            ],
          );
        }),
      ),
    );
  }
}

class _MPOptionalTile extends StatelessWidget {
  const _MPOptionalTile({
    required this.title,
    required this.badge,
    required this.timeLabel,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String badge;
  final String timeLabel;
  final bool selected;
  final VoidCallback onTap;

  static const Color _kBlue = Color(0xFF1A73E8);

  @override
  Widget build(BuildContext context) {
    final String b = badge.trim();
    final String t = timeLabel.trim();
    final bool hasBadge = b.isNotEmpty;
    final bool hasTime = t.isNotEmpty;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: selected ? _kBlue : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected ? _kBlue : const Color(0xFFC7C7CC),
                  width: 1.6,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:
                    hasTime ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        title,
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t5_14,
                          fontWeight: OmiFontWeight.regular,
                          color: mainTextColor,
                        ),
                      ),
                      if (hasBadge) ...<Widget>[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDEBFF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            b,
                            style: OmiTextStyle.create(
                              fontSize: OmiFontSize.t3_12,
                              fontWeight: OmiFontWeight.regular,
                              color: const Color(0xFF6B5CFF),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasTime) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      t,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t4_13,
                        fontWeight: OmiFontWeight.regular,
                        color: secondTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MPSummaryTile extends StatelessWidget {
  const _MPSummaryTile({
    required this.title,
    required this.badge,
    required this.timeLabel,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String badge;
  final String timeLabel;
  final bool selected;
  final VoidCallback onTap;

  static const Color _kRadioBlue = Color(0xFF1A73E8);

  @override
  Widget build(BuildContext context) {
    final String b = badge.trim();
    final String t = timeLabel.trim();
    final bool hasBadge = b.isNotEmpty;
    final bool hasTime = t.isNotEmpty;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? _kRadioBlue : const Color(0xFFC7C7CC),
                  width: 1.6,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _kRadioBlue,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:
                    hasTime ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        title,
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t5_14,
                          fontWeight: OmiFontWeight.regular,
                          color: mainTextColor,
                        ),
                      ),
                      if (hasBadge) ...<Widget>[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDEBFF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            b,
                            style: OmiTextStyle.create(
                              fontSize: OmiFontSize.t3_12,
                              fontWeight: OmiFontWeight.regular,
                              color: const Color(0xFF6B5CFF),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasTime) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      t,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t4_13,
                        fontWeight: OmiFontWeight.regular,
                        color: secondTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// _MPCheckbox 已不再使用（Include additional content 现展示更多 options 而非勾选项）。
