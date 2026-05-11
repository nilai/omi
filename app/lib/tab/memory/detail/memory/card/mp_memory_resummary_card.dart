import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';

MarkdownStyleSheet _mpResummaryMarkdownStyle() {
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
    h1: base(
      size: OmiFontSize.t8_17,
      weight: OmiFontWeight.bold,
      color: mainTextColor,
    ),
    h1Padding: const EdgeInsets.only(top: 4, bottom: 6),
    h2: base(
      size: OmiFontSize.t6_15,
      weight: OmiFontWeight.bold,
      color: mainTextColor,
    ),
    h2Padding: const EdgeInsets.only(top: 2, bottom: 6),
    h3: base(
      size: OmiFontSize.t5_14,
      weight: OmiFontWeight.medium,
      color: mainTextColor,
    ),
    h3Padding: const EdgeInsets.only(top: 2, bottom: 4),
    strong: base(size: OmiFontSize.t4_13, weight: OmiFontWeight.bold),
    em: base(size: OmiFontSize.t4_13, fontStyle: FontStyle.italic),
    a: base(
      size: OmiFontSize.t4_13,
      color: greenTextColor,
      decoration: TextDecoration.underline,
    ),
    code: base(size: OmiFontSize.t3_12, color: mainTextColor).copyWith(
      backgroundColor: pageColor,
      fontFamily: 'monospace',
    ),
    blockquote: base(size: OmiFontSize.t4_13, color: secondTextColor),
    blockquotePadding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
    blockquoteDecoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: secondTextColor.withValues(alpha: 0.6), width: 3),
      ),
    ),
    blockSpacing: 8,
    listIndent: 22,
    listBullet: base(size: OmiFontSize.t4_13),
    listBulletPadding: const EdgeInsets.only(right: 6),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: lineColor, width: 1),
      ),
    ),
    codeblockPadding: const EdgeInsets.all(10),
    codeblockDecoration: BoxDecoration(
      color: pageColor,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

Future<void> _mpResummaryTapMarkdownLink(String? href) async {
  if (href == null || href.isEmpty) {
    return;
  }
  final Uri? uri = Uri.tryParse(href);
  if (uri == null) {
    return;
  }
  if (!await canLaunchUrl(uri)) {
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// 粗略估算 Markdown 在 [maxWidth] 下折行数（与 Insight 卡片一致，用于「Read full analysis」是否展示）。
int _mpEstimateResummaryMarkdownLines(String raw, double maxWidth) {
  final String t = raw
      .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1')
      .replaceAll(RegExp(r'`+'), '')
      .replaceAll(RegExp(r'\*{1,2}'), '')
      .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
      .trim();
  if (t.isEmpty) {
    return 0;
  }
  final TextStyle style = OmiTextStyle.create(
    fontSize: OmiFontSize.t4_13,
    height: 1.45,
    color: mainTextColor,
  );
  final TextPainter tp = TextPainter(
    text: TextSpan(text: t, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);
  return tp.computeLineMetrics().length;
}

/// 与正文段落样式一致，折叠区固定显示约 [lineCount] 行文本高度。
double _mpHeightForResummaryParagraphLines(int lineCount, double maxWidth) {
  if (lineCount <= 0 || maxWidth <= 0) {
    return 0;
  }
  final TextStyle style = OmiTextStyle.create(
    fontSize: OmiFontSize.t4_13,
    height: 1.45,
    color: mainTextColor,
  );
  final String text = List<String>.filled(lineCount, 'x').join('\n');
  final TextPainter tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);
  return tp.height;
}

/// 单条 RESUMMARY 活动卡片数据（列表可有多张）
class MPMemoryResummaryCardData {
  const MPMemoryResummaryCardData({
    this.headerTimeLabel = 'Just now',
    this.badgeLabel = 'Autopilot mode',
    this.summaryMemoryId,
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

  /// 与接口返回的 summary_memory_id 对齐，用于本地定位更新
  final String? summaryMemoryId;

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

/// RESUMMARY 生成中占位卡片数据
class MPMemoryResummaryLoadingCardData {
  const MPMemoryResummaryLoadingCardData({
    this.headerTimeLabel = 'Just now',
    required this.summaryMemoryId,
  });

  final String headerTimeLabel;

  /// 与 [summaryRecord] 返回的 summary_memory_id 一致，作为唯一标识
  final String summaryMemoryId;
}

/// RESUMMARY 生成中占位卡片（与设计一致：中间 sparkles + 文案 + 三点）
class MPMemoryResummaryLoadingCard extends StatelessWidget {
  const MPMemoryResummaryLoadingCard({super.key, required this.data});

  final MPMemoryResummaryLoadingCardData data;

  static const Color _kIconCircleBg = Color(0xFFE8F5E9);

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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                  child: Center(
                    child: OmiImageLoader.localImg(
                      Assets.omiBookText,
                      width: 12,
                      height: 12,
                      color: greenTextColor,
                      fit: BoxFit.contain,
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
                  data.headerTimeLabel,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t2_11,
                    fontWeight: OmiFontWeight.regular,
                    color: secondTextColor.withValues(alpha: 0.85),
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Column(
              children: <Widget>[
                OmiImageLoader.localImg(
                  Assets.omiSparkles,
                  width: 42,
                  height: 42,
                  color: greenTextColor,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 14),
                Text(
                  'AI is analyzing...',
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t7_16,
                    fontWeight: OmiFontWeight.bold,
                    color: mainTextColor,
                    height: 1.25,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Generating a fresh perspective based on\nyour recording',
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t4_13,
                    fontWeight: OmiFontWeight.regular,
                    color: secondTextColor,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                const _MPResummaryDots(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MPResummaryDots extends StatefulWidget {
  const _MPResummaryDots();

  @override
  State<_MPResummaryDots> createState() => _MPResummaryDotsState();
}

class _MPResummaryDotsState extends State<_MPResummaryDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final double t = _controller.value; // 0~1
        int active = (t * 3).floor().clamp(0, 2);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(3, (int i) {
            final bool on = i <= active;
            return Container(
              width: 8,
              height: 8,
              margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
              decoration: BoxDecoration(
                color: on
                    ? greenTextColor.withValues(alpha: 0.95)
                    : greenTextColor.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
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

  /// [bodyText] 作为 Markdown 在 [maxWidth] 下是否超过 [_kCollapsedBodyLines] 行（估算，与 Insight 卡片一致）
  bool _markdownBodyExceedsCollapsedLines(String text, double maxWidth) {
    if (text.trim().isEmpty || maxWidth <= 0) {
      return false;
    }
    return _mpEstimateResummaryMarkdownLines(text, maxWidth) >
        _kCollapsedBodyLines;
  }

  /// 是否存在「更多内容」：有展开区块，或正文在折叠行数内显示不下
  bool _hasMoreContent(double bodyMaxWidth) {
    final bool hasExtra = _d.expandedSectionBody != null &&
        _d.expandedSectionBody!.trim().isNotEmpty;
    if (hasExtra) {
      return true;
    }
    return _markdownBodyExceedsCollapsedLines(_d.bodyText, bodyMaxWidth);
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
            // const SizedBox(height: 8),
            // Text(
            //   _d.sectionTitle,
            //   style: OmiTextStyle.create(
            //     fontSize: OmiFontSize.t5_14,
            //     fontWeight: OmiFontWeight.bold,
            //     color: mainTextColor,
            //     height: 1.3,
            //   ),
            // ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final MarkdownStyleSheet mdSheet = _mpResummaryMarkdownStyle();
                final double w = constraints.maxWidth.isFinite &&
                        constraints.maxWidth > 0
                    ? constraints.maxWidth
                    : MediaQuery.sizeOf(context).width - 64;
                final bool showToggle = _hasMoreContent(w);
                final bool bodyOverflow =
                    _markdownBodyExceedsCollapsedLines(_d.bodyText, w);

                Widget buildMainBodyMarkdown() {
                  return MarkdownBody(
                    data: _d.bodyText,
                    selectable: true,
                    shrinkWrap: true,
                    styleSheet: mdSheet,
                    onTapLink: (String text, String? href, String title) {
                      unawaited(_mpResummaryTapMarkdownLink(href));
                    },
                  );
                }

                Widget buildCollapsedMainBody() {
                  if (!bodyOverflow) {
                    return buildMainBodyMarkdown();
                  }
                  final double clipH =
                      _mpHeightForResummaryParagraphLines(
                            _kCollapsedBodyLines,
                            w,
                          ) +
                          10;
                  return SizedBox(
                    height: clipH,
                    child: ClipRect(
                      clipBehavior: Clip.hardEdge,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: buildMainBodyMarkdown(),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _expanded ? buildMainBodyMarkdown() : buildCollapsedMainBody(),
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
                      MarkdownBody(
                        data: _d.expandedSectionBody!,
                        selectable: true,
                        shrinkWrap: true,
                        styleSheet: mdSheet,
                        onTapLink: (String text, String? href, String title) {
                          unawaited(_mpResummaryTapMarkdownLink(href));
                        },
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
