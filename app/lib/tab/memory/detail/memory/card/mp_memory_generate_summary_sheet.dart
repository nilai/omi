import 'package:flutter/material.dart';
import 'package:omi/common/omi_button.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';
import 'mp_choose_summary_style_sheet.dart';

/// 自底部弹出「Generate resummary」说明与确认（白底圆角 sheet）
Future<void> showMPMemoryGenerateSummarySheet(
  BuildContext context, {
  VoidCallback? onGenerateResummary,
  VoidCallback? onChangeMode,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    /// 使用根 Navigator，避免嵌套路由（如 Tab）时底部 sheet 不显示或层级异常
    useRootNavigator: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (BuildContext ctx) {
      return _MPGenerateSummarySheet(
        onGenerate: onGenerateResummary,
        onChangeMode: onChangeMode,
      );
    },
  );
}

class _MPGenerateSummarySheet extends StatefulWidget {
  const _MPGenerateSummarySheet({
    this.onGenerate,
    this.onChangeMode,
  });

  final VoidCallback? onGenerate;

  final VoidCallback? onChangeMode;

  @override
  State<_MPGenerateSummarySheet> createState() =>
      _MPGenerateSummarySheetState();
}

class _MPGenerateSummarySheetState extends State<_MPGenerateSummarySheet> {
  /// 当前选中的摘要风格（与下层选择器同步）
  MPSummaryStyleId _selectedStyle = MPSummaryStyleId.autopilot;

  static const Color _kFeatureCardBg = Color(0xFFF2F2F7);
  static const Color _kAutopilotBg = Color(0xFFF7F2E8);
  static const Color _kAutopilotBorder = Color(0xFFE8DCC8);

  @override
  Widget build(BuildContext context) {
    // 最大高度为屏幕的 80%
    final double maxH = MediaQuery.sizeOf(context).height * 0.8;
    final double kb = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Material(
          color: Colors.white,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          "Here's what AI will do for you",
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t9_18,
                            fontWeight: OmiFontWeight.medium,
                            color: mainTextColor,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'AI will analyze this memory from a new perspective and create a resummary.',
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t4_13,
                            fontWeight: OmiFontWeight.regular,
                            color: secondTextColor,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _kFeatureCardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "What you'll get:",
                                style: OmiTextStyle.create(
                                  fontSize: OmiFontSize.t5_14,
                                  fontWeight: OmiFontWeight.medium,
                                  color: mainTextColor,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _MPFeatureRow(
                                icon: OmiImageLoader.localImg(
                                  Assets.omiSparkles,
                                  width: 18,
                                  height: 18,
                                  color: blueTextColor,
                                  fit: BoxFit.contain,
                                ),
                                title: 'Different perspective',
                                subtitle:
                                    'Analyze this memory through a new lens',
                              ),
                              const SizedBox(height: 14),
                              _MPFeatureRow(
                                icon: OmiImageLoader.localImg(
                                  Assets.omiBookText,
                                  width: 18,
                                  height: 18,
                                  color: blueTextColor,
                                  fit: BoxFit.contain,
                                ),
                                title: 'Fresh insights',
                                subtitle:
                                    'Discover details you might have missed',
                              ),
                              const SizedBox(height: 14),
                              _MPFeatureRow(
                                icon: OmiImageLoader.localImg(
                                  Assets.omiQuestion,
                                  width: 18,
                                  height: 18,
                                  color: blueTextColor,
                                  fit: BoxFit.contain,
                                ),
                                title: 'Structured analysis',
                                subtitle:
                                    'Organized sections based on style',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _kAutopilotBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kAutopilotBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              OmiImageLoader.localImg(
                                Assets.omiSparkles,
                                width: 18,
                                height: 18,
                                color: orangeTextColor,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      _selectedStyle.modeCardTitle,
                                      style: OmiTextStyle.create(
                                        fontSize: OmiFontSize.t5_14,
                                        fontWeight: OmiFontWeight.medium,
                                        color: mainTextColor,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedStyle.modeCardSubtitle,
                                      style: OmiTextStyle.create(
                                        fontSize: OmiFontSize.t3_12,
                                        fontWeight: OmiFontWeight.regular,
                                        color: secondTextColor,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  showMPChooseSummaryStyleSheet(
                                    context,
                                    initialStyle: _selectedStyle,
                                    onStyleConfirmed:
                                        (MPSummaryStyleId style) {
                                      setState(() {
                                        _selectedStyle = style;
                                      });
                                      widget.onChangeMode?.call();
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        'Change',
                                        style: OmiTextStyle.create(
                                          fontSize: OmiFontSize.t4_13,
                                          fontWeight: OmiFontWeight.medium,
                                          color: blueTextColor,
                                        ),
                                      ),
                                      OmiImageLoader.localImg(Assets.omiSolidRightArrow, width: 8, height: 8),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      12 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        OmiButton(
                          text: 'Generate resummary',
                          width: double.infinity,
                          height: 50,
                          bgColor: blueTextColor,
                          textColor: Colors.white,
                          textFontSize: OmiFontSize.t5_14,
                          textFontWeight: OmiFontWeight.bold,
                          borderRadius: BorderRadius.circular(12),
                          icon: OmiImageLoader.localImg(
                            Assets.omiSparkles,
                            width: 20,
                            height: 20,
                            color: Colors.white,
                            fit: BoxFit.contain,
                          ),
                          onPressed: () {
                            final NavigatorState nav = Navigator.of(context);
                            widget.onGenerate?.call();
                            nav.pop();
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'This will add a new activity card below',
                          textAlign: TextAlign.center,
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t2_11,
                            fontWeight: OmiFontWeight.regular,
                            color: secondTextColor.withValues(alpha: 0.85),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MPFeatureRow extends StatelessWidget {
  const _MPFeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Widget icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(width: 18, child: Center(child: icon)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t4_13,
                  fontWeight: OmiFontWeight.medium,
                  color: mainTextColor,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t3_12,
                  fontWeight: OmiFontWeight.regular,
                  color: secondTextColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
