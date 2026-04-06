import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';
import 'package:url_launcher/url_launcher.dart';

/// Memory 详情 **Overview** 分段内容（支持 Markdown；接口摘要可为 Markdown 字符串）。
class MPMemoryOverviewContent extends StatelessWidget {
  const MPMemoryOverviewContent({
    super.key,
    required this.content,
    this.height = 300,
    this.scrollWithParent = false,
    this.useMemoStyle = false,
  });

  final String content;
  final double height;
  final bool scrollWithParent;
  final bool useMemoStyle;

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
  Widget build(BuildContext context) {
    final MarkdownStyleSheet sheet = _styleSheet(useMemoStyle);
    final Widget body = MarkdownBody(
      data: content,
      selectable: true,
      shrinkWrap: true,
      styleSheet: sheet,
      onTapLink: (String text, String? href, String title) {
        unawaited(_onTapLink(text, href, title));
      },
    );

    final Widget contentView = Align(
      alignment: Alignment.topLeft,
      child: body,
    );
    if (scrollWithParent) {
      return contentView;
    }
    return SizedBox(
      height: height,
      child: ClipRect(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: contentView,
        ),
      ),
    );
  }
}
