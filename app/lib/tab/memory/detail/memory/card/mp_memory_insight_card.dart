import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:memo_pin/common/omi_add_todo_popup.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';
import '../omi_memory_detail_cubit.dart';

/// Insight 卡片配色主题（仅样式差异，与 [MPFeedCardType] 可对应或用于轮换）。
enum MPInsightCardTone {
  /// 粉色
  business,

  /// 橙色
  followUp,
  // /// 执行/蓝
  // execution,

  // /// 创意/紫
  // creative,

  // /// 健康/绿
  // wellness,

  // /// 战略/红
  // strategic,

  // /// 成长/深绿
  // growth,
}

/// 单条 Insight 卡片数据
class MPMemoryInsightItemData {
  const MPMemoryInsightItemData({
    this.feedCardId,
    required this.tone,
    required this.timeLabel,
    required this.bodyText,
    required this.title,
    this.categoryTitle,
    this.useMarkdown = true,
    this.insightContent,
    this.insightSuggestion,
    this.hasAddedTodo = false,
    required this.metaLine,
  });

  final MPInsightCardTone tone;

  /// 对应后端 feed card id（用于创建 follow-up todo 关联）。
  final String? feedCardId;

  final String title;

  final String metaLine;

  /// 右侧相对时间，如 `2 min later`
  final String timeLabel;

  /// 正文：Markdown（[useMarkdown]==true，如 followUp）或纯文本拼接（insight 时与 [insightContent]/[insightSuggestion] 一致）
  final String bodyText;

  /// 不传则根据 [tone] 使用默认英文大写标题
  final String? categoryTitle;

  /// 为 false 时按纯文本渲染（insight：[insightContent] + 「Suggestion:」+ [insightSuggestion]）
  final bool useMarkdown;

  /// insight 接口 [content] 字段
  final String? insightContent;

  /// insight 接口 [suggestion] 字段
  final String? insightSuggestion;

  /// 接口 [has_added_todo] 或本地创建成功后为 true，底部展示「Follow-up todo added」
  final bool hasAddedTodo;

  /// 展示用分类标题（全大写）
  String get resolvedCategoryTitle {
    if (categoryTitle != null && categoryTitle!.isNotEmpty) {
      return categoryTitle!;
    }
    return 'BUSINESS INSIGHT';
  }
}

class _MPInsightVisual {
  const _MPInsightVisual({
    required this.cardBg,
    required this.accent,
    required this.iconBg,
    required this.buttonBg,
    required this.buttonForeground,
    required this.icon,
  });

  final Color cardBg;
  final Color accent;
  final Color iconBg;
  final Color buttonBg;
  final Color buttonForeground;
  final String? icon;

  static _MPInsightVisual of(MPInsightCardTone tone) {
    switch (tone) {
      case MPInsightCardTone.business:
        return _MPInsightVisual(
          cardBg: pinkTextColor.withAlpha(30),
          accent: pinkTextColor,
          iconBg: pinkTextColor,
          buttonBg: pinkTextColor.withAlpha(60),
          buttonForeground: pinkTextColor,
          icon: Assets.omiDetailGift,
        );
      case MPInsightCardTone.followUp:
        return _MPInsightVisual(
          cardBg: orangeTextColor.withAlpha(30),
          accent: orangeTextColor,
          iconBg: orangeTextColor,
          buttonBg: orangeTextColor.withAlpha(60),
          buttonForeground: orangeTextColor,
          icon: Assets.omiDetailGift,
        );
    }
  }
}

MarkdownStyleSheet _mpInsightMarkdownStyle(Color linkColor) {
  TextStyle base({
    required double size,
    FontWeight? weight,
    Color? color,
    double height = 1.45,
    FontStyle? fontStyle,
    TextDecoration? decoration,
  }) {
    return OmiTextStyle.create(
      fontSize: size,
      fontWeight: weight ?? OmiFontWeight.regular,
      color: color ?? mainTextColor,
      height: height,
      fontStyle: fontStyle,
      decoration: decoration,
    );
  }

  return MarkdownStyleSheet(
    p: base(size: OmiFontSize.t4_13),
    pPadding: EdgeInsets.zero,
    h1: base(size: OmiFontSize.t8_17, weight: OmiFontWeight.bold, color: mainTextColor),
    h1Padding: const EdgeInsets.only(top: 4, bottom: 6),
    h2: base(size: OmiFontSize.t6_15, weight: OmiFontWeight.bold, color: mainTextColor),
    h2Padding: const EdgeInsets.only(top: 2, bottom: 6),
    h3: base(size: OmiFontSize.t5_14, weight: OmiFontWeight.medium, color: mainTextColor),
    h3Padding: const EdgeInsets.only(top: 2, bottom: 4),
    strong: base(size: OmiFontSize.t4_13, weight: OmiFontWeight.bold),
    em: base(size: OmiFontSize.t4_13, fontStyle: FontStyle.italic),
    a: base(size: OmiFontSize.t4_13, color: linkColor, decoration: TextDecoration.underline),
    code: base(
      size: OmiFontSize.t3_12,
      color: mainTextColor,
    ).copyWith(backgroundColor: pageColor, fontFamily: 'monospace'),
    blockquote: base(size: OmiFontSize.t4_13, color: secondTextColor),
    blockquotePadding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: secondTextColor.withValues(alpha: 0.6), width: 3)),
    ),
    blockSpacing: 8,
    listIndent: 22,
    listBullet: base(size: OmiFontSize.t4_13),
    listBulletPadding: const EdgeInsets.only(right: 6),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: lineColor, width: 1)),
    ),
    codeblockPadding: const EdgeInsets.all(10),
    codeblockDecoration: BoxDecoration(color: pageColor, borderRadius: BorderRadius.circular(8)),
  );
}

Future<void> _mpInsightTapMarkdownLink(String? href) async {
  if (href == null || href.isEmpty) return;
  final Uri? uri = Uri.tryParse(href);
  if (uri == null) return;
  if (!await canLaunchUrl(uri)) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// 纯文本折行行数估算（insight 非 Markdown）
int _mpEstimatePlainBodyLines(String raw, double maxWidth) {
  final String t = raw.trim();
  if (t.isEmpty) {
    return 0;
  }
  final TextStyle style = OmiTextStyle.create(fontSize: OmiFontSize.t4_13, height: 1.45, color: mainTextColor);
  final TextPainter tp = TextPainter(
    text: TextSpan(text: t, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);
  return tp.computeLineMetrics().length;
}

/// 粗略估算正文在 [maxWidth] 下占几行（与真实 Markdown 高度不完全一致，用于是否展示 Show more；避免再叠一层 Markdown 测量导致 overflow）。
int _mpEstimateInsightBodyLines(String raw, double maxWidth) {
  final String t = raw
      .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1')
      .replaceAll(RegExp(r'`+'), '')
      .replaceAll(RegExp(r'\*{1,2}'), '')
      .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
      .trim();
  if (t.isEmpty) {
    return 0;
  }
  final TextStyle style = OmiTextStyle.create(fontSize: OmiFontSize.t4_13, height: 1.45, color: mainTextColor);
  final TextPainter tp = TextPainter(
    text: TextSpan(text: t, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);
  return tp.computeLineMetrics().length;
}

/// 与正文段落样式一致，在 [maxWidth] 下折行后「恰好 n 行」纯文本的排版高度（用于折叠区，避免用 fontSize×5 裁掉半行）。
double _mpHeightForParagraphLines(int lineCount, double maxWidth) {
  if (lineCount <= 0 || maxWidth <= 0) {
    return 0;
  }
  final TextStyle style = OmiTextStyle.create(fontSize: OmiFontSize.t4_13, height: 1.45, color: mainTextColor);
  final String text = List<String>.filled(lineCount, 'x').join('\n');
  final TextPainter tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);
  return tp.height;
}

/// Memory 详情列表中的 Insight 卡片（图标 + 分类 + 时间 + 正文 Markdown 或纯文本 + Show more + Add follow-up todo）
class MPMemoryInsightCard extends StatefulWidget {
  const MPMemoryInsightCard({super.key, required this.data, required this.memoryId});

  final MPMemoryInsightItemData data;

  /// 当前 Memory 详情 [MPMemoryStruct.id]，创建 Todo 时传 [memory_id]
  final String memoryId;

  @override
  State<MPMemoryInsightCard> createState() => _MPMemoryInsightCardState();
}

class _MPMemoryInsightCardState extends State<MPMemoryInsightCard> {
  /// 长文时在卡片内展开全文（非弹窗）
  bool _bodyExpanded = false;

  /// 底部是否已添加 follow-up（本地保存成功或与接口 [hasAddedTodo] 同步）
  late bool _followUpTodoAdded;

  @override
  void initState() {
    super.initState();
    _followUpTodoAdded = widget.data.hasAddedTodo;
  }

  @override
  void didUpdateWidget(covariant MPMemoryInsightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.hasAddedTodo != widget.data.hasAddedTodo) {
      _followUpTodoAdded = widget.data.hasAddedTodo;
    }
    if (oldWidget.data.bodyText != widget.data.bodyText ||
        oldWidget.data.insightContent != widget.data.insightContent ||
        oldWidget.data.insightSuggestion != widget.data.insightSuggestion ||
        oldWidget.data.useMarkdown != widget.data.useMarkdown) {
      _bodyExpanded = false;
    }
  }

  Widget _buildFollowUpFooter(_MPInsightVisual v) {
    if (_followUpTodoAdded) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: secondTextColor.withAlpha(22), borderRadius: BorderRadius.circular(22)),
        alignment: Alignment.center,
        child: Text(
          'Follow-up todo added',
          style: OmiTextStyle.create(
            fontSize: OmiFontSize.t4_13,
            fontWeight: OmiFontWeight.medium,
            color: secondTextColor,
            height: 1.2,
          ),
        ),
      );
    }
    return Material(
      color: v.buttonBg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () async {
          final MPAddTodoPopupResult? result = await showMPAddTodoPopup(
            context,
            params: _followUpTodoParams(),
            onContextTap: () {
              Navigator.of(context).pop();
            },
          );
          if (result != null) {
            setState(() {
              _followUpTodoAdded = true;
            });
            if (!mounted) return;
            // follow-up todo 创建成功后刷新详情，保证 feed 与状态与服务端对齐。
            unawaited(context.read<OmiMemoryDetailCubit>().refresh());
          }
        },
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              OmiImageLoader.localImg(
                Assets.omiPlus,
                width: 16,
                height: 16,
                color: v.buttonForeground,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 6),
              Text(
                'Add follow-up todo',
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t4_13,
                  fontWeight: OmiFontWeight.medium,
                  color: v.buttonForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _measurePlainBodyRaw() {
    final String c = (widget.data.insightContent ?? '').trim();
    final String s = (widget.data.insightSuggestion ?? '').trim();
    if (c.isEmpty && s.isEmpty) {
      return widget.data.bodyText;
    }
    if (s.isEmpty) {
      return c;
    }
    if (c.isEmpty) {
      return 'Suggestion:\n$s';
    }
    return '$c\n\nSuggestion:\n$s';
  }

  Widget _buildPlainStructuredBody(_MPInsightVisual v) {
    final String c = (widget.data.insightContent ?? '').trim();
    final String s = (widget.data.insightSuggestion ?? '').trim();
    final bool hasC = c.isNotEmpty;
    final bool hasS = s.isNotEmpty;

    final TextStyle baseStyle = OmiTextStyle.create(fontSize: OmiFontSize.t4_13, height: 1.45, color: mainTextColor);
    final TextStyle labelStyle = OmiTextStyle.create(
      fontSize: OmiFontSize.t4_13,
      height: 1.45,
      fontWeight: OmiFontWeight.bold,
      color: v.accent,
    );

    final List<InlineSpan> spans = <InlineSpan>[];
    if (hasC) {
      spans.add(TextSpan(text: c, style: baseStyle));
    }
    if (hasC && hasS) {
      spans.add(TextSpan(text: '\n\n', style: baseStyle));
    }
    if (hasS) {
      spans.add(TextSpan(text: 'Suggestion:\n', style: labelStyle));
      spans.add(TextSpan(text: s, style: baseStyle));
    }
    if (!hasC && !hasS) {
      spans.add(TextSpan(text: widget.data.bodyText, style: baseStyle));
    }

    return SelectableText.rich(TextSpan(children: spans));
  }

  String _plainSnippetForTodo(String md) {
    if (!widget.data.useMarkdown) {
      final String s = md.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (s.isEmpty) {
        return 'Follow up on insight';
      }
      const int maxLen = 64;
      if (s.length <= maxLen) {
        return s;
      }
      return '${s.substring(0, maxLen).trimRight()}...';
    }
    final String s = md
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1')
        .replaceAll(RegExp(r'[#*_`>\[\]]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (s.isEmpty) {
      return 'Follow up on insight';
    }
    const int maxLen = 64;
    if (s.length <= maxLen) {
      return s;
    }
    return '${s.substring(0, maxLen).trimRight()}...';
  }

  /// Insight 纯文本：notes←content，标题←suggestion，Context←接口 title（无则用分类默认标题）
  MPAddTodoPopupParams _followUpTodoParams() {
    final String mid = widget.memoryId.trim();
    final String fid = (widget.data.feedCardId ?? '').trim();
    if (!widget.data.useMarkdown) {
      return MPAddTodoPopupParams(
        initialTitle: (widget.data.insightSuggestion ?? '').trim(),
        initialNotes: (widget.data.insightContent ?? '').trim(),
        contextMemoryLabel: 'From memory:',
        contextMemoryTitle: widget.data.title,
        contextMetaLine: widget.data.metaLine,
        memoryId: mid,
        feedCardId: fid,
      );
    }
    return MPAddTodoPopupParams(
      initialTitle: _plainSnippetForTodo(widget.data.bodyText),
      initialNotes: '',
      contextMemoryLabel: 'From memory:',
      contextMemoryTitle: widget.data.title,
      contextMetaLine: widget.data.metaLine,
      memoryId: mid,
      feedCardId: fid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final _MPInsightVisual v = _MPInsightVisual.of(widget.data.tone);
    final MarkdownStyleSheet mdStyle = _mpInsightMarkdownStyle(v.accent);

    Widget buildMarkdownBody() {
      return MarkdownBody(
        data: widget.data.bodyText,
        selectable: true,
        shrinkWrap: true,
        styleSheet: mdStyle,
        onTapLink: (String text, String? href, String title) {
          unawaited(_mpInsightTapMarkdownLink(href));
        },
      );
    }

    Widget buildClippedMarkdown(double contentWidth) {
      // 按当前宽度计算 5 行段落真实排版高度 + 余量（列表/引用等略高），减少最后一行被拦腰截断
      final double fiveLineHeight = _mpHeightForParagraphLines(5, contentWidth) + 10;
      return SizedBox(
        height: fiveLineHeight,
        child: ClipRect(
          clipBehavior: Clip.hardEdge,
          child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: buildMarkdownBody()),
        ),
      );
    }

    Widget buildPlainBody() {
      return _buildPlainStructuredBody(v);
    }

    Widget buildClippedPlain(double contentWidth) {
      final double fiveLineHeight = _mpHeightForParagraphLines(5, contentWidth) + 10;
      return SizedBox(
        height: fiveLineHeight,
        child: ClipRect(
          clipBehavior: Clip.hardEdge,
          child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: buildPlainBody()),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double w = constraints.maxWidth;
          final String measureRaw = widget.data.useMarkdown ? widget.data.bodyText : _measurePlainBodyRaw();
          final int estLines = widget.data.useMarkdown
              ? _mpEstimateInsightBodyLines(widget.data.bodyText, w)
              : _mpEstimatePlainBodyLines(measureRaw, w);
          // 标题/列表等会高于纯文本估算，长字符兜底避免该显示时不显示
          final bool needsShowMore = estLines > 5 || measureRaw.length > 260;

          Widget buildVisibleBody() {
            if (needsShowMore && !_bodyExpanded) {
              return widget.data.useMarkdown ? buildClippedMarkdown(w) : buildClippedPlain(w);
            }
            return widget.data.useMarkdown ? buildMarkdownBody() : buildPlainBody();
          }

          return Container(
            decoration: BoxDecoration(color: v.cardBg, borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: v.iconBg.withAlpha(20), shape: BoxShape.circle),
                      child: Center(
                        child: OmiImageLoader.localImg(
                          v.icon ?? '',
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                          color: v.iconBg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.data.resolvedCategoryTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t3_12,
                          fontWeight: OmiFontWeight.bold,
                          color: v.accent,
                          height: 1.25,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.data.timeLabel,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t2_11,
                        fontWeight: OmiFontWeight.regular,
                        color: secondTextColor,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                buildVisibleBody(),
                if (needsShowMore && !_bodyExpanded) ...<Widget>[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _bodyExpanded = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Show more',
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t4_13,
                            fontWeight: OmiFontWeight.medium,
                            color: v.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (needsShowMore && _bodyExpanded) ...<Widget>[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _bodyExpanded = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Show less',
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t4_13,
                            fontWeight: OmiFontWeight.medium,
                            color: v.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                widget.data.tone == MPInsightCardTone.followUp ? const SizedBox.shrink() : _buildFollowUpFooter(v),
              ],
            ),
          );
        },
      ),
    );
  }
}
