import 'package:flutter/material.dart';
import 'package:omi/common/omi_button.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';

/// 可选的摘要风格（与 UI 列表一一对应）
enum MPSummaryStyleId {
  /// Autopilot（推荐）
  autopilot,

  /// Meeting secretary
  meetingSecretary,

  /// Sales follow-up
  salesFollowUp,

  /// Learning notes
  learningNotes,

  /// ADHD-friendly
  adhdFriendly,
}

/// 各风格在上一层「Generate resummary」弹窗模式卡片中的主副文案（与列表条目一致）
extension MPSummaryStyleIdCopy on MPSummaryStyleId {
  /// 模式卡片主标题
  String get modeCardTitle {
    switch (this) {
      case MPSummaryStyleId.autopilot:
        return 'Autopilot';
      case MPSummaryStyleId.meetingSecretary:
        return 'Meeting secretary';
      case MPSummaryStyleId.salesFollowUp:
        return 'Sales follow-up';
      case MPSummaryStyleId.learningNotes:
        return 'Learning notes';
      case MPSummaryStyleId.adhdFriendly:
        return 'ADHD-friendly';
    }
  }

  /// 模式卡片副标题（说明）
  String get modeCardSubtitle {
    switch (this) {
      case MPSummaryStyleId.autopilot:
        return "Let AI decide what's worth generating based on the content";
      case MPSummaryStyleId.meetingSecretary:
        return 'Clear, structured meeting notes';
      case MPSummaryStyleId.salesFollowUp:
        return 'Client needs, objections, next steps';
      case MPSummaryStyleId.learningNotes:
        return 'Concepts, examples, personal takeaways';
      case MPSummaryStyleId.adhdFriendly:
        return 'Extra structure, clarity, no overload';
    }
  }
}

/// 自底部弹出「Choose summary style」：选择摘要风格（叠在上一层 sheet 之上）
///
/// [onStyleConfirmed] 用户点击「Use this style」时回调当前选中项
/// [onBrowseAllStyles] 点击「Browse all styles」
Future<void> showMPChooseSummaryStyleSheet(
  BuildContext context, {
  MPSummaryStyleId initialStyle = MPSummaryStyleId.autopilot,
  void Function(MPSummaryStyleId style)? onStyleConfirmed,
  VoidCallback? onBrowseAllStyles,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (BuildContext ctx) {
      return _MPChooseSummaryStyleSheet(
        initialStyle: initialStyle,
        onStyleConfirmed: onStyleConfirmed,
        onBrowseAllStyles: onBrowseAllStyles,
      );
    },
  );
}

class _MPChooseSummaryStyleSheet extends StatefulWidget {
  const _MPChooseSummaryStyleSheet({
    required this.initialStyle,
    this.onStyleConfirmed,
    this.onBrowseAllStyles,
  });

  final MPSummaryStyleId initialStyle;
  final void Function(MPSummaryStyleId style)? onStyleConfirmed;
  final VoidCallback? onBrowseAllStyles;

  static const Color _kCardBg = Color(0xFFF2F2F7);
  static const Color _kRecommendedBadgeBg = Color(0xFFE8F4FF);

  @override
  State<_MPChooseSummaryStyleSheet> createState() =>
      _MPChooseSummaryStyleSheetState();
}

class _MPChooseSummaryStyleSheetState extends State<_MPChooseSummaryStyleSheet> {
  late MPSummaryStyleId _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialStyle;
  }

  void _pop() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // 最大高度为屏幕的 80%
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
                        SizedBox(height: 4,),
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
                        _buildAutopilotCard(),
                        const SizedBox(height: 16),
                        _buildYourStylesDivider(),
                        const SizedBox(height: 6),
                        _buildStyleListTile(
                          id: MPSummaryStyleId.meetingSecretary,
                          icon: OmiImageLoader.localImg(
                            Assets.omiUsers,
                            width: 12,
                            height: 12,
                            color: blueTextColor,
                            fit: BoxFit.contain,
                          ),
                          title: 'Meeting secretary',
                          subtitle: 'Clear, structured meeting notes',
                        ),
                        const SizedBox(height: 10),
                        _buildStyleListTile(
                          id: MPSummaryStyleId.salesFollowUp,
                          icon: OmiImageLoader.localImg(Assets.omiDetailPhone, color: blueTextColor, width: 12, height: 12, fit: BoxFit.contain),
                          title: 'Sales follow-up',
                          subtitle:
                              'Client needs, objections, next steps',
                        ),
                        const SizedBox(height: 10),
                        _buildStyleListTile(
                          id: MPSummaryStyleId.learningNotes,
                          icon: OmiImageLoader.localImg(
                            Assets.omiBookText,
                            width: 12,
                            height: 12,
                            color: blueTextColor,
                            fit: BoxFit.contain,
                          ),
                          title: 'Learning notes',
                          subtitle:
                              'Concepts, examples, personal takeaways',
                        ),
                        const SizedBox(height: 10),
                        _buildStyleListTile(
                          id: MPSummaryStyleId.adhdFriendly,
                          icon: OmiImageLoader.localImg(
                            Assets.omiBrain,
                            width: 12,
                            height: 12,
                            color: blueTextColor,
                            fit: BoxFit.contain,
                          ),
                          title: 'ADHD-friendly',
                          subtitle:
                              'Extra structure, clarity, no overload',
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
                                  OmiImageLoader.localImg(Assets.omiBlueRighrArrow, width: 12, height: 12, fit: BoxFit.contain)

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
                    onPressed: () {
                      widget.onStyleConfirmed?.call(_selected);
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

  /// 顶部：返回 / 标题 / 关闭
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
                    OmiImageLoader.localImg(Assets.omiLeftBack, width: 20, height: 20, color: blueTextColor),
                    SizedBox(width: 4,),
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

  /// Autopilot 推荐卡片（可选中）
  Widget _buildAutopilotCard() {
    final bool sel = _selected == MPSummaryStyleId.autopilot;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selected = MPSummaryStyleId.autopilot),
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
                        Text(
                          'Autopilot',
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t5_14,
                            fontWeight: OmiFontWeight.medium,
                            color: mainTextColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _MPChooseSummaryStyleSheet._kRecommendedBadgeBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Recommended',
                            style: OmiTextStyle.create(
                              fontSize: OmiFontSize.t2_11,
                              fontWeight: OmiFontWeight.medium,
                              color: blueTextColor,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Let AI decide what's worth generating based on the content",
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
          ),
        ),
      ),
    );
  }

  /// 「Your styles」分隔标题
  Widget _buildYourStylesDivider() {
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

  /// 列表风格卡片
  Widget _buildStyleListTile({
    required MPSummaryStyleId id,
    required Widget icon,
    required String title,
    required String subtitle,
  }) {
    final bool sel = _selected == id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selected = id),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                  width: 30, height: 30,
                  child: Center(child: icon)
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.medium,
                        color: mainTextColor,
                        height: 1.25,
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
          ),
        ),
      ),
    );
  }
}
