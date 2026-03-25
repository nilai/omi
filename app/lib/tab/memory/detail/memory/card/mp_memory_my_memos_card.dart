import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';
import '../mp_analyze_suggested_tasks_sheet.dart';

/// 「MY MEMOS」整卡数据
class MPMemoryMyMemosCardData {
  const MPMemoryMyMemosCardData({
    this.headerTimeLabel = 'Just now',
    this.sourceLine = '',
    required this.lines,
  });

  /// 头部右侧时间，如 `Just now`
  final String headerTimeLabel;

  /// 每条 Memo 正文（展示时会加引号样式）
  final List<String> lines;

  /// 弹窗里的来源文案，如 `From: Team standup discussion on API migration · 02:14`
  final String sourceLine;
}

/// 左侧蓝色竖条 + 白底圆角，展示多条 Memo 摘录
class MPMemoryMyMemosCard extends StatefulWidget {
  const MPMemoryMyMemosCard({super.key, required this.data});

  final MPMemoryMyMemosCardData data;

  @override
  State<MPMemoryMyMemosCard> createState() => _MPMemoryMyMemosCardState();
}

class _MPMemoryMyMemosCardState extends State<MPMemoryMyMemosCard> {
  static const Color _kLeftStripe = blueTextColor;
  static const Color _kIconCircleBg = Color(0xFFE8F4FF);
  bool _isDeleted = false;

  Future<bool> _deleteMemo(String memoText) async {
    // TODO: 替换为真实删除接口
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<void> _onDeleteTap(
    BuildContext sheetContext, {
    required String memoText,
  }) async {
    final bool ok = await _deleteMemo(memoText);
    if (!mounted || !ok) return;
    Navigator.of(sheetContext).pop();
    setState(() {
      _isDeleted = true;
    });
  }

  /// 请求 AI 分析结果（占位实现，后续替换真实接口）。
  Future<List<String>> _analyzeMemoActions(String memoText) async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    final String t = memoText.trim();
    final String first = t.replaceFirst(RegExp(r'[.?!]\s*$'), '');
    return <String>[
      first,
      if (t.length > 8)
        'Follow up on: ${first.length > 48 ? '${first.substring(0, 48)}…' : first}',
      'Schedule a short sync to confirm next steps.',
    ];
  }

  /// 显示「Suggested tasks」分析弹窗。
  void _showAnalyzeTasksSheet(
    BuildContext context, {
    required String memoText,
  }) {
    showMPAnalyzeSuggestedTasksSheet(
      context,
      memoText: memoText,
      onAnalyze: _analyzeMemoActions,
    );
  }

  /// 显示 Memo 详情底部弹窗。
  void _showMemoSheet(BuildContext context, String memoText) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
        return Container(
          width: double.infinity,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: pageColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 20 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    height: 50,
                    color: Colors.white,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: OmiImageLoader.localImg(
                              Assets.omiLeftBack,
                              width: 24,
                              height: 24,
                              color: blueTextColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Memo',
                            textAlign: TextAlign.center,
                            style: OmiTextStyle.create(
                              fontSize: OmiFontSize.t8_17,
                              fontWeight: OmiFontWeight.medium,
                              color: mainTextColor,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              _onDeleteTap(context, memoText: memoText),
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: OmiImageLoader.localImg(
                              Assets.omiDetailDelete,
                              width: 18,
                              height: 18,
                              color: redColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: EdgeInsets.only(left: 16, right: 16),
                    child: Row(
                      children: <Widget>[
                        OmiImageLoader.localImg(
                          Assets.omiSparkles,
                          width: 16,
                          height: 16,
                          color: const Color(0xFFFFB340),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Highlight',
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t5_14,
                            fontWeight: OmiFontWeight.medium,
                            color: const Color(0xFFFFB340),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: EdgeInsets.only(left: 16, right: 16),
                    child: Text(
                      widget.data.sourceLine,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.medium,
                        color: blueTextColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: lineColor.withValues(alpha: 0.8)),
                  const SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.only(left: 16, right: 16),
                    child: Text(
                      memoText,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t6_15,
                        fontWeight: OmiFontWeight.regular,
                        color: mainTextColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(height: 1, color: lineColor.withValues(alpha: 0.8)),
                  const SizedBox(height: 14),
                  Padding(
                    padding: EdgeInsets.only(left: 16, right: 16),
                    child: Text(
                      'Actions',
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.medium,
                        color: secondTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.only(left: 16, right: 16),
                    child: InkWell(
                      onTap: () {
                        _showAnalyzeTasksSheet(context, memoText: memoText);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            OmiImageLoader.localImg(
                              Assets.omiSparkles,
                              width: 16,
                              height: 16,
                              color: blueTextColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Analyze actions',
                              style: OmiTextStyle.create(
                                fontSize: OmiFontSize.t6_15,
                                fontWeight: OmiFontWeight.medium,
                                color: blueTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleted) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (widget.data.lines.isEmpty) return;
          _showMemoSheet(context, widget.data.lines.first);
        },
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: const Border(
              left: BorderSide(color: _kLeftStripe, width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _kIconCircleBg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: OmiImageLoader.localImg(
                          Assets.omiDetailEdit,
                          width: 12,
                          height: 12,
                          color: _kLeftStripe,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'MY MEMOS',
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
                      widget.data.headerTimeLabel,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t2_11,
                        fontWeight: OmiFontWeight.regular,
                        color: secondTextColor.withValues(alpha: 0.85),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (int i = 0; i < widget.data.lines.length; i++) ...<Widget>[
                  if (i > 0) ...<Widget>[
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: lineColor.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 12),
                  ],
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showMemoSheet(context, widget.data.lines[i]),
                    child: Text(
                      '“${widget.data.lines[i]}”',
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t4_13,
                        fontWeight: OmiFontWeight.medium,
                        color: mainTextColor,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
