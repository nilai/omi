import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';

/// 单条 RESUMMARY 活动卡片数据（列表可有多张）
class MPMemoryResummaryCardData {
  const MPMemoryResummaryCardData({
    this.headerTimeLabel = 'Just now',
    this.badgeLabel = 'Autopilot mode',
    required this.mainTitle,
    required this.sectionTitle,
    required this.bodyText,
    this.expandedSectionTitle,
    this.expandedSectionBody,
  });

  /// 头部右侧时间
  final String headerTimeLabel;

  /// 标题下胶囊标签，如 `Autopilot mode`
  final String badgeLabel;

  /// 主标题，如 `Strategic Investment Analysis`
  final String mainTitle;

  /// 小节标题，如 `Executive Summary`
  final String sectionTitle;

  /// 正文（折叠时为截断展示，展开后显示完整）
  final String bodyText;

  /// 展开后额外区块标题，如 `Bottom Line`；与 [expandedSectionBody] 搭配使用
  final String? expandedSectionTitle;

  /// 展开后额外正文（如 Bottom Line 段落）
  final String? expandedSectionBody;
}

/// RESUMMARY 卡片：文档图标 + 徽章 + 标题层级 + 可展开正文 + Read full analysis / Show less
class MPMemoryResummaryCard extends StatefulWidget {
  const MPMemoryResummaryCard({
    super.key,
    required this.data,
    this.onExpansionChanged,
  });

  final MPMemoryResummaryCardData data;

  /// 展开/收起状态变化（`true` 为已展开）
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<MPMemoryResummaryCard> createState() => _MPMemoryResummaryCardState();
}

class _MPMemoryResummaryCardState extends State<MPMemoryResummaryCard> {
  static const Color _kIconCircleBg = Color(0xFFE8F5E9);
  static const Color _kBadgeBg = Color(0xFFE8F5E9);

  /// 折叠时正文最大行数
  static const int _kCollapsedBodyLines = 4;

  bool _expanded = false;

  MPMemoryResummaryCardData get _d => widget.data;

  /// [bodyText] 在 [maxWidth] 下是否超过 [_kCollapsedBodyLines] 行（与 [Text] 测量一致）
  static bool _bodyExceedsCollapsedLines({
    required String text,
    required double maxWidth,
    required TextStyle style,
  }) {
    if (text.isEmpty || maxWidth <= 0) {
      return false;
    }
    final TextPainter tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: _kCollapsedBodyLines,
    )..layout(maxWidth: maxWidth);
    return tp.didExceedMaxLines;
  }

  /// 是否存在「更多内容」：有展开区块，或正文在折叠行数内显示不下
  bool _hasMoreContent(double bodyMaxWidth, TextStyle bodyStyle) {
    final bool hasExtra = _d.expandedSectionBody != null &&
        _d.expandedSectionBody!.trim().isNotEmpty;
    if (hasExtra) {
      return true;
    }
    return _bodyExceedsCollapsedLines(
      text: _d.bodyText,
      maxWidth: bodyMaxWidth,
      style: bodyStyle,
    );
  }

  @override
  void didUpdateWidget(covariant MPMemoryResummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _expanded = false;
    }
  }

  void _setExpanded(bool value) {
    if (_expanded == value) {
      return;
    }
    setState(() => _expanded = value);
    widget.onExpansionChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: _kIconCircleBg,
                    shape: BoxShape.circle,
                  ),
                  child:
                  Center(
                    child: OmiImageLoader.localImg(
                        Assets.omiBookText,
                        width: 12,
                        height: 12,
                        color: greenTextColor,
                        fit: BoxFit.contain
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'RESUMMARY',
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t3_12,
                        fontWeight: OmiFontWeight.bold,
                        color: secondTextColor,
                        height: 1.2,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                Text(
                  _d.headerTimeLabel,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t2_11,
                    fontWeight: OmiFontWeight.regular,
                    color: secondTextColor.withValues(alpha: 0.85),
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _kBadgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _d.badgeLabel,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t2_11,
                    fontWeight: OmiFontWeight.medium,
                    color: greenTextColor,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _d.mainTitle,
              style: OmiTextStyle.create(
                fontSize: OmiFontSize.t8_17,
                fontWeight: OmiFontWeight.bold,
                color: mainTextColor,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _d.sectionTitle,
              style: OmiTextStyle.create(
                fontSize: OmiFontSize.t5_14,
                fontWeight: OmiFontWeight.bold,
                color: mainTextColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final TextStyle bodyStyle = OmiTextStyle.create(
                  fontSize: OmiFontSize.t4_13,
                  fontWeight: OmiFontWeight.regular,
                  color: mainTextColor,
                  height: 1.45,
                );
                final double w = constraints.maxWidth.isFinite &&
                        constraints.maxWidth > 0
                    ? constraints.maxWidth
                    : MediaQuery.sizeOf(context).width - 64;
                final bool showToggle = _hasMoreContent(w, bodyStyle);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      _d.bodyText,
                      maxLines: _expanded ? null : _kCollapsedBodyLines,
                      overflow: _expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: bodyStyle,
                    ),
                    if (_expanded &&
                        _d.expandedSectionBody != null &&
                        _d.expandedSectionBody!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      Text(
                        _d.expandedSectionTitle?.trim().isNotEmpty == true
                            ? _d.expandedSectionTitle!
                            : 'Bottom Line',
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t5_14,
                          fontWeight: OmiFontWeight.bold,
                          color: mainTextColor,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _d.expandedSectionBody!,
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t4_13,
                          fontWeight: OmiFontWeight.regular,
                          color: mainTextColor,
                          height: 1.45,
                        ),
                      ),
                    ],
                    if (showToggle) ...<Widget>[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () => _setExpanded(!_expanded),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  _expanded ? 'Show less' : 'Read full analysis',
                                  style: OmiTextStyle.create(
                                    fontSize: OmiFontSize.t4_13,
                                    fontWeight: OmiFontWeight.medium,
                                    color: greenTextColor,
                                  ),
                                ),
                                const SizedBox(width: 2),

                                OmiImageLoader.localImg(
                                    _expanded ? Assets.omiArrowUp : Assets.omiArrowDown,
                                    width: 14,
                                    height: 14,
                                    color: greenTextColor
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
