import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';
import 'package:url_launcher/url_launcher.dart';

/// Memory 详情 **Overview** 分段内容（支持 Markdown；接口摘要可为 Markdown 字符串）。
///
/// 当 [scrollWithParent] 为 false 且正文高度超过 [height] 时，展示 Show more / Show less；
/// 展开后高度为正文真实高度（不再内嵌滚动）。
class MPMemoryOverviewContent extends StatefulWidget {
  const MPMemoryOverviewContent({
    super.key,
    required this.content,
    this.height = 300,
    this.scrollWithParent = false,
    this.useMemoStyle = false,
    this.onExpandedChanged,
  });

  final String content;
  final double height;
  final bool scrollWithParent;
  final bool useMemoStyle;

  /// 展开/收起时通知父级（用于去掉外层固定高度约束）。
  final ValueChanged<bool>? onExpandedChanged;

  static MarkdownStyleSheet _styleSheet(bool useMemoStyle) {
    final Color bodyColor = useMemoStyle
        ? const Color(0xFF2C2C2E)
        : Colors.white.withValues(alpha: 0.82);
    final Color headingColor = useMemoStyle
        ? mainTextColor
        : Colors.white.withValues(alpha: 0.96);
    final Color secondaryColor = useMemoStyle
        ? secondTextColor
        : Colors.white.withValues(alpha: 0.62);
    final Color linkColor =
        useMemoStyle ? blueTextColor : const Color(0xFFB8D9FF);
    final Color codeBg = useMemoStyle
        ? const Color(0xFFF2F2F7)
        : Colors.white.withValues(alpha: 0.14);
    final Color hrColor =
        useMemoStyle ? lineColor : Colors.white.withValues(alpha: 0.35);

    TextStyle base({
      required double size,
      FontWeight? weight,
      Color? color,
      double height = 1.4,
      FontStyle? fontStyle,
      TextDecoration? decoration,
    }) {
      return OmiTextStyle.create(
        fontSize: size,
        fontWeight: weight ?? OmiFontWeight.regular,
        color: color ?? bodyColor,
        height: height,
        fontStyle: fontStyle,
        decoration: decoration,
      );
    }

    return MarkdownStyleSheet(
      p: base(size: OmiFontSize.t4_13),
      pPadding: EdgeInsets.zero,
      h1: base(
        size: OmiFontSize.t9_18,
        weight: OmiFontWeight.bold,
        color: headingColor,
      ),
      h1Padding: const EdgeInsets.only(top: 4, bottom: 6),
      h2: base(
        size: OmiFontSize.t6_15,
        weight: OmiFontWeight.bold,
        color: headingColor,
      ),
      h2Padding: const EdgeInsets.only(top: 2, bottom: 6),
      h3: base(
        size: OmiFontSize.t5_14,
        weight: OmiFontWeight.medium,
        color: headingColor,
      ),
      h3Padding: const EdgeInsets.only(top: 2, bottom: 4),
      strong: base(size: OmiFontSize.t4_13, weight: OmiFontWeight.bold),
      em: base(size: OmiFontSize.t4_13, fontStyle: FontStyle.italic),
      a: base(
        size: OmiFontSize.t4_13,
        color: linkColor,
        decoration: TextDecoration.underline,
      ),
      code: base(
        size: OmiFontSize.t3_12,
        color: useMemoStyle ? mainTextColor : bodyColor,
      ).copyWith(
        backgroundColor: codeBg,
        fontFamily: 'monospace',
      ),
      blockquote: base(size: OmiFontSize.t4_13, color: secondaryColor),
      blockquotePadding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: secondaryColor, width: 3),
        ),
      ),
      blockSpacing: 8,
      listIndent: 22,
      listBullet: base(size: OmiFontSize.t4_13),
      listBulletPadding: const EdgeInsets.only(right: 6),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: hrColor, width: 1),
        ),
      ),
      codeblockPadding: const EdgeInsets.all(10),
      codeblockDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  static Future<void> _onTapLink(String text, String? href, String title) async {
    if (href == null || href.isEmpty) return;
    final Uri? uri = Uri.tryParse(href);
    if (uri == null) return;
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  State<MPMemoryOverviewContent> createState() => _MPMemoryOverviewContentState();
}

class _MPMemoryOverviewContentState extends State<MPMemoryOverviewContent> {
  final GlobalKey _measureKey = GlobalKey();
  bool _expanded = false;
  bool? _overflows;

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(MPMemoryOverviewContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content || oldWidget.height != widget.height) {
      _expanded = false;
      _overflows = null;
      widget.onExpandedChanged?.call(false);
      _scheduleMeasure();
    }
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureContentHeight());
  }

  void _measureContentHeight() {
    if (!mounted || widget.scrollWithParent) {
      return;
    }
    final BuildContext? ctx = _measureKey.currentContext;
    if (ctx == null) {
      _scheduleMeasure();
      return;
    }
    final RenderObject? ro = ctx.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) {
      _scheduleMeasure();
      return;
    }
    final double contentH = ro.size.height;
    final bool overflow = contentH > widget.height + 0.5;
    if (_overflows == overflow) {
      return;
    }
    setState(() => _overflows = overflow);
  }

  void _setExpanded(bool value) {
    if (_expanded == value) {
      return;
    }
    setState(() => _expanded = value);
    widget.onExpandedChanged?.call(value);
  }

  Color get _toggleColor =>
      widget.useMemoStyle ? blueTextColor : const Color(0xFFB8D9FF);

  @override
  Widget build(BuildContext context) {
    final MarkdownStyleSheet sheet = MPMemoryOverviewContent._styleSheet(widget.useMemoStyle);
    final Widget body = _buildMarkdownBody(sheet);

    final Widget contentView = Align(
      alignment: Alignment.topLeft,
      child: body,
    );

    if (widget.scrollWithParent) {
      return contentView;
    }

    final bool showToggle = _overflows == true;
    // 测量完成前按折叠高度展示，避免先全高再收起的闪烁。
    final bool collapsed = _overflows != false && !_expanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Offstage(
          offstage: true,
          child: KeyedSubtree(key: _measureKey, child: body),
        ),
        if (collapsed)
          SizedBox(
            height: widget.height,
            child: ClipRect(
              clipBehavior: Clip.hardEdge,
              child: Align(
                alignment: Alignment.topLeft,
                child: contentView,
              ),
            ),
          )
        else
          contentView,
        if (showToggle) ...<Widget>[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _setExpanded(!_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                _expanded ? 'Show less' : 'Show more',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t4_13,
                  fontWeight: OmiFontWeight.medium,
                  color: _toggleColor,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMarkdownBody(MarkdownStyleSheet sheet) {
    return MarkdownBody(
      data: widget.content,
      selectable: true,
      shrinkWrap: true,
      styleSheet: sheet,
      onTapLink: (String text, String? href, String title) {
        unawaited(MPMemoryOverviewContent._onTapLink(text, href, title));
      },
    );
  }
}
