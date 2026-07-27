import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Markdown renderer shared by insight detail module content.
class MPInsightMarkdownBody extends StatelessWidget {
  const MPInsightMarkdownBody({
    super.key,
    required this.data,
    required this.style,
    this.bulletColor,
  });

  final String data;
  final TextStyle style;
  final Color? bulletColor;

  @override
  Widget build(BuildContext context) {
    final Color effectiveBulletColor = bulletColor ?? style.color ?? DefaultTextStyle.of(context).style.color!;
    return MarkdownBody(
      data: data,
      shrinkWrap: true,
      softLineBreak: true,
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
      styleSheet: MarkdownStyleSheet(
        blockSpacing: 8,
        listIndent: 22,
        p: style,
        pPadding: EdgeInsets.zero,
        strong: style.copyWith(fontWeight: FontWeight.w700),
        em: style.copyWith(fontStyle: FontStyle.italic),
        h1: style.copyWith(fontSize: (style.fontSize ?? 14) + 4, fontWeight: FontWeight.w700),
        h1Padding: EdgeInsets.zero,
        h2: style.copyWith(fontSize: (style.fontSize ?? 14) + 2, fontWeight: FontWeight.w700),
        h2Padding: EdgeInsets.zero,
        h3: style.copyWith(fontWeight: FontWeight.w700),
        h3Padding: EdgeInsets.zero,
        listBullet: style.copyWith(color: effectiveBulletColor),
        unorderedListAlign: WrapAlignment.start,
      ),
      bulletBuilder: (MarkdownBulletParameters parameters) {
        if (parameters.style == BulletStyle.unorderedList) {
          return Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: effectiveBulletColor, shape: BoxShape.circle),
            ),
          );
        }
        return Text('${parameters.index + 1}.', style: style);
      },
    );
  }
}
