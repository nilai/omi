import 'package:flutter/material.dart';
import 'package:memo_pin/common/mp_dismissible_modal_backdrop.dart';
import 'package:memo_pin/common/omi_button.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../../../../../http/schema/mp_data_model.dart';
import '../../../../../utils/omi_image_loader.dart';

/// 自底部弹出「Choose summary style」：顶部为最近使用的 [recentTemplate]，下方列表为 [recommendTemplates]。
///
/// [onTemplateConfirmed] 用户点击「Use this style」时回调当前选中模板。
/// [onBrowseAllStyles] 点击「Browse all styles」
Future<void> showMPChooseSummaryStyleSheet(
  BuildContext context, {
  MPTemplateStruct? recentTemplate,
  List<MPTemplateStruct> recommendTemplates = const [],
  MPTemplateStruct? initialSelected,
  void Function(MPTemplateStruct tpl)? onTemplateConfirmed,
  VoidCallback? onBrowseAllStyles,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    useRootNavigator: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (BuildContext ctx) {
      return MPDismissibleModalBackdrop(
        child: _MPChooseSummaryStyleSheet(
          recentTemplate: recentTemplate,
          recommendTemplates: recommendTemplates,
          initialSelected: initialSelected,
          onTemplateConfirmed: onTemplateConfirmed,
          onBrowseAllStyles: onBrowseAllStyles,
        ),
      );
    },
  );
}

class _MPChooseSummaryStyleSheet extends StatefulWidget {
  const _MPChooseSummaryStyleSheet({
    required this.recommendTemplates,
    this.recentTemplate,
    this.initialSelected,
    this.onTemplateConfirmed,
    this.onBrowseAllStyles,
  });

  final MPTemplateStruct? recentTemplate;
  final List<MPTemplateStruct> recommendTemplates;
  final MPTemplateStruct? initialSelected;
  final void Function(MPTemplateStruct tpl)? onTemplateConfirmed;
  final VoidCallback? onBrowseAllStyles;

  static const Color _kCardBg = Color(0xFFF2F2F7);
  static const Color _kRecommendedBadgeBg = Color(0xFFE8F4FF);

  @override
  State<_MPChooseSummaryStyleSheet> createState() =>
      _MPChooseSummaryStyleSheetState();
}

class _MPChooseSummaryStyleSheetState extends State<_MPChooseSummaryStyleSheet> {
  MPTemplateStruct? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected ??
        widget.recentTemplate ??
        (widget.recommendTemplates.isNotEmpty
            ? widget.recommendTemplates.first
            : null);
  }

  void _pop() {
    Navigator.of(context).pop();
  }

  bool _isSameTemplate(MPTemplateStruct? a, MPTemplateStruct? b) {
    if (a == null || b == null) return false;
    final String? idA = a.id;
    final String? idB = b.id;
    if (idA != null &&
        idB != null &&
        idA.isNotEmpty &&
        idB.isNotEmpty) {
      return idA == idB;
    }
    return identical(a, b);
  }

  String _tplTitle(MPTemplateStruct t) {
    final String x = (t.title ?? '').trim();
    return x;
  }

  String _tplSubtitle(MPTemplateStruct t) {
    return (t.subTitle ?? '').trim();
  }

  /// 标题右侧小标签（与「Recent」同款：浅蓝底 + 蓝字）
  Widget _buildTitleTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _MPChooseSummaryStyleSheet._kRecommendedBadgeBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: OmiTextStyle.create(
          fontSize: OmiFontSize.t2_11,
          fontWeight: OmiFontWeight.medium,
          color: blueTextColor,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _iconForIndex(int idx) {
    final List<Widget> icons = <Widget>[
      OmiImageLoader.localImg(
        Assets.omiUsers,
        width: 12,
        height: 12,
        color: blueTextColor,
        fit: BoxFit.contain,
      ),
      OmiImageLoader.localImg(
        Assets.omiDetailPhone,
        width: 12,
        height: 12,
        color: blueTextColor,
        fit: BoxFit.contain,
      ),
      OmiImageLoader.localImg(
        Assets.omiBookText,
        width: 12,
        height: 12,
        color: blueTextColor,
        fit: BoxFit.contain,
      ),
      OmiImageLoader.localImg(
        Assets.omiBrain,
        width: 12,
        height: 12,
        color: blueTextColor,
        fit: BoxFit.contain,
      ),
    ];
    return icons[idx % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    final double maxH = MediaQuery.sizeOf(context).height * 0.8;
    final double kb = MediaQuery.viewInsetsOf(context).bottom;
    final double bottomPad = 12 + MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Material(
          color: Colors.white,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        OmiImageLoader.localImg(
                          Assets.omiSparkles,
                          width: 18,
                          height: 18,
                          color: orangeTextColor,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Choose how you'd like this summarized",
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t7_16,
                            fontWeight: OmiFontWeight.medium,
                            color: mainTextColor,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pick a style that fits this recording.',
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t4_13,
                            fontWeight: OmiFontWeight.regular,
                            color: secondTextColor,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (widget.recentTemplate != null) ...<Widget>[
                          _buildRecentTemplateCard(widget.recentTemplate!),
                          const SizedBox(height: 16),
                        ],
                        _buildRecommendedDivider(),
                        const SizedBox(height: 6),
                        if (widget.recommendTemplates.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'No recommended templates',
                              style: OmiTextStyle.create(
                                fontSize: OmiFontSize.t4_13,
                                fontWeight: OmiFontWeight.regular,
                                color: secondTextColor,
                              ),
                            ),
                          )
                        else
                          ...List<Widget>.generate(
                            widget.recommendTemplates.length,
                            (int i) {
                              final MPTemplateStruct t =
                                  widget.recommendTemplates[i];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: i == widget.recommendTemplates.length - 1
                                      ? 0
                                      : 10,
                                ),
                                child: _buildTemplateTile(
                                  tpl: t,
                                  icon: _iconForIndex(i),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 12),
                        Text(
                          'Looking for a specific role or style?',
                          textAlign: TextAlign.center,
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t4_13,
                            fontWeight: OmiFontWeight.regular,
                            color: secondTextColor,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            widget.onBrowseAllStyles?.call();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  'Browse all styles',
                                  style: OmiTextStyle.create(
                                    fontSize: OmiFontSize.t4_13,
                                    fontWeight: OmiFontWeight.medium,
                                    color: blueTextColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                OmiImageLoader.localImg(
                                  Assets.omiBlueRighrArrow,
                                  width: 12,
                                  height: 12,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPad),
                  child: OmiButton(
                    text: 'Use this style',
                    width: double.infinity,
                    height: 50,
                    bgColor: blueTextColor,
                    textColor: Colors.white,
                    textFontSize: OmiFontSize.t5_14,
                    textFontWeight: OmiFontWeight.bold,
                    borderRadius: BorderRadius.circular(12),
                    icon: OmiImageLoader.localImg(
                      Assets.omiSparkles,
                      width: 18,
                      height: 18,
                      color: Colors.white,
                      fit: BoxFit.contain,
                    ),
                    onPressed: _selected == null
                        ? null
                        : () {
                            widget.onTemplateConfirmed?.call(_selected!);
                            _pop();
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        8 + MediaQuery.paddingOf(context).top,
        8,
        8,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: _pop,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    OmiImageLoader.localImg(
                      Assets.omiLeftBack,
                      width: 20,
                      height: 20,
                      color: blueTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.medium,
                        color: blueTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Text(
            'Choose summary style',
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t7_16,
              fontWeight: OmiFontWeight.medium,
              color: mainTextColor,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: _pop,
              icon: OmiImageLoader.localImg(
                Assets.omiClose,
                width: 20,
                height: 20,
                color: secondTextColor,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部：最近使用的模板（recentTemplate）
  Widget _buildRecentTemplateCard(MPTemplateStruct recent) {
    final bool sel = _isSameTemplate(_selected, recent);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selected = recent),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? blueTextColor : borderColor,
              width: sel ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              OmiImageLoader.localImg(
                Assets.omiSparkles,
                width: 18,
                height: 18,
                color: blueTextColor,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            _tplTitle(recent),
                            style: OmiTextStyle.create(
                              fontSize: OmiFontSize.t5_14,
                              fontWeight: OmiFontWeight.medium,
                              color: mainTextColor,
                            ),
                            
                          ),
                        ),
                         const SizedBox(width: 8),
                        _buildTitleTag('Recommended'),
                      ],
                    ),
                    if (_tplSubtitle(recent).isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        _tplSubtitle(recent),
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t3_12,
                          fontWeight: OmiFontWeight.regular,
                          color: secondTextColor,
                          height: 1.4,
                        ),
                      ),
                    ],

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedDivider() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(height: 0.5, color: lineColor),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Your styles',
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t3_12,
              fontWeight: OmiFontWeight.regular,
              color: secondTextColor,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 0.5, color: lineColor),
        ),
      ],
    );
  }

  Widget _buildTemplateTile({
    required MPTemplateStruct tpl,
    required Widget icon,
  }) {
    final bool sel = _isSameTemplate(_selected, tpl);
    final String sub = _tplSubtitle(tpl);
    final bool hasSub = sub.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selected = tpl),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _MPChooseSummaryStyleSheet._kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? blueTextColor : Colors.transparent,
              width: sel ? 2 : 0,
            ),
          ),
          child: Row(
            crossAxisAlignment:
                hasSub ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                width: 30,
                height: 30,
                child: Center(child: icon),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _tplTitle(tpl),
                            style: OmiTextStyle.create(
                              fontSize: OmiFontSize.t5_14,
                              fontWeight: OmiFontWeight.medium,
                              color: mainTextColor,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasSub) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t3_12,
                          fontWeight: OmiFontWeight.regular,
                          color: secondTextColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
