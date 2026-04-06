import 'package:flutter/material.dart';
import 'package:memo_pin/http/schema/mp_data_model.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';
import '../mp_memo_detail_sheet.dart';

/// 单条 MY MEMO 行：正文 + 与后端 [MPMemoType] 一致的类型（决定底部弹窗 Manual / Highlight）。
class MPMemoryMyMemoLine {
  const MPMemoryMyMemoLine({
    required this.text,
    this.type = MPMemoType.highlightMemo,
    this.memoId,
  });

  final String text;

  /// `highlightMemo` → Highlight 弹窗；`manualMemo` → Manual Memo 弹窗。
  final MPMemoType type;

  /// 服务端 Memo id；有值时删除会先请求接口。
  final String? memoId;
}

/// 「MY MEMOS」整卡数据
class MPMemoryMyMemosCardData {
  const MPMemoryMyMemosCardData({
    this.headerTimeLabel = 'Just now',
    this.sourceLine = '',
    required this.lines,
  });

  /// 头部右侧时间，如 `Just now`
  final String headerTimeLabel;

  /// 每条 Memo（展示正文时会加引号样式）
  final List<MPMemoryMyMemoLine> lines;

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

  /// 显示 Memo 详情底部弹窗（按 [MPMemoryMyMemoLine.type] 区分 Manual / Highlight）。
  void _showMemoSheet(BuildContext context, MPMemoryMyMemoLine line) {
    final MPMemoDetailSheetVariant variant =
        line.type == MPMemoType.manualMemo
            ? MPMemoDetailSheetVariant.manual
            : MPMemoDetailSheetVariant.highlight;
    final bool isManual = variant == MPMemoDetailSheetVariant.manual;
    showMPMemoDetailSheet(
      context,
      variant: variant,
      memoId: line.memoId,
      manualMemoText: isManual ? line.text : '',
      highlightSourceLine: isManual ? '' : widget.data.sourceLine,
      highlightMemoText: isManual ? '' : line.text,
      onAnalyze: _analyzeMemoActions,
      onDelete: (String t) async {
        if (!mounted) return false;
        setState(() {
          _isDeleted = true;
        });
        return true;
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
                    onTap: () =>
                        _showMemoSheet(context, widget.data.lines[i]),
                    child: Text(
                      '“${widget.data.lines[i].text}”',
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
