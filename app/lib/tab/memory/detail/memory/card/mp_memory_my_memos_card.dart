import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';

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
    return <String>[memoText.trim().replaceFirst(RegExp(r'[.?!]\s*$'), '')];
  }

  /// 显示「Suggested tasks」分析弹窗。
  void _showAnalyzeTasksSheet(
    BuildContext context, {
    required String memoText,
  }) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return _MPAnalyzeActionsSheet(
          memoText: memoText,
          onAnalyze: _analyzeMemoActions,
        );
      },
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
                          onTap: () => _onDeleteTap(
                            context,
                            memoText: memoText,
                          ),
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

class _MPAnalyzeActionsSheet extends StatefulWidget {
  const _MPAnalyzeActionsSheet({
    required this.memoText,
    required this.onAnalyze,
  });

  final String memoText;
  final Future<List<String>> Function(String memoText) onAnalyze;

  @override
  State<_MPAnalyzeActionsSheet> createState() => _MPAnalyzeActionsSheetState();
}

class _MPAnalyzeActionsSheetState extends State<_MPAnalyzeActionsSheet> {
  bool _loading = true;
  List<String> _suggestions = <String>[];
  int? _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<String> result = await widget.onAnalyze(widget.memoText);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _suggestions = result;
      _selectedIndex = result.isEmpty ? null : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 12, 6),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Suggested tasks',
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t9_18,
                          fontWeight: OmiFontWeight.bold,
                          color: mainTextColor,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: OmiImageLoader.localImg(
                          Assets.omiClose,
                          width: 24,
                          height: 24,
                          color: secondTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: lineColor.withValues(alpha: 0.8)),
              if (_loading) ...<Widget>[
                SizedBox(
                  height: 220,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const _MPAnalyzeLoadingDots(),
                      const SizedBox(height: 24),
                      Text(
                        'Analyzing your memo...',
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t7_16,
                          fontWeight: OmiFontWeight.medium,
                          color: secondTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...<Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Text(
                    'FROM YOUR MEMO',
                    style: OmiTextStyle.create(
                      fontSize: OmiFontSize.t3_12,
                      fontWeight: OmiFontWeight.medium,
                      color: secondTextColor.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEAEAEE)),
                    ),
                    child: Text(
                      widget.memoText,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.regular,
                        color: mainTextColor,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Text(
                    'SUGGESTIONS',
                    style: OmiTextStyle.create(
                      fontSize: OmiFontSize.t3_12,
                      fontWeight: OmiFontWeight.medium,
                      color: secondTextColor.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD8E7FF)),
                    ),
                    child: Column(
                      children: List<Widget>.generate(_suggestions.length, (
                        int i,
                      ) {
                        final bool isSelected = i == _selectedIndex;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: i == _suggestions.length - 1 ? 0 : 8,
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedIndex = isSelected ? null : i;
                              });
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFCFE0FF)
                                      : const Color(0xFFEAEAEE),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF1A73E8)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFF1A73E8),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _suggestions[i],
                                      style: OmiTextStyle.create(
                                        fontSize: OmiFontSize.t5_14,
                                        fontWeight: OmiFontWeight.medium,
                                        color: mainTextColor,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFF0F0F4),
                              foregroundColor: mainTextColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: OmiTextStyle.create(
                                fontSize: OmiFontSize.t8_17,
                                fontWeight: OmiFontWeight.medium,
                                color: mainTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: TextButton(
                            onPressed: _selectedIndex == null
                                ? null
                                : () {
                              // TODO: 调用创建 tasks 接口（使用 _suggestions[_selectedIndex]）
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: blueTextColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Create tasks',
                              style: OmiTextStyle.create(
                                fontSize: OmiFontSize.t8_17,
                                fontWeight: OmiFontWeight.medium,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MPAnalyzeDot extends StatelessWidget {
  const _MPAnalyzeDot({required this.opacity, required this.scale});

  final double opacity;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: blueTextColor.withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MPAnalyzeLoadingDots extends StatefulWidget {
  const _MPAnalyzeLoadingDots();

  @override
  State<_MPAnalyzeLoadingDots> createState() => _MPAnalyzeLoadingDotsState();
}

class _MPAnalyzeLoadingDotsState extends State<_MPAnalyzeLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotWave(int index) {
    final double t = _controller.value * 2 * math.pi;
    final double phase = index * (2 * math.pi / 3);
    return 0.5 + 0.5 * math.sin(t - phase);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(3, (int index) {
            final double wave = _dotWave(index);
            final double opacity = 0.35 + wave * 0.65;
            final double scale = 0.78 + wave * 0.32;
            return Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
              child: _MPAnalyzeDot(opacity: opacity, scale: scale),
            );
          }),
        );
      },
    );
  }
}
