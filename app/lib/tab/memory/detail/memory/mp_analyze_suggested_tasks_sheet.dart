import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../../../../generated/assets.dart';
import '../../../../utils/omi_image_loader.dart';

/// 展示「Suggested tasks」分析结果底部弹窗（高度上限为屏高的 60%，中间区域可滚动）。
Future<void> showMPAnalyzeSuggestedTasksSheet(
  BuildContext context, {
  required String memoText,
  required Future<List<String>> Function(String memoText) onAnalyze,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) {
      return _MPAnalyzeSuggestedTasksSheet(
        memoText: memoText,
        onAnalyze: onAnalyze,
      );
    },
  );
}

class _MPAnalyzeSuggestedTasksSheet extends StatefulWidget {
  const _MPAnalyzeSuggestedTasksSheet({
    required this.memoText,
    required this.onAnalyze,
  });

  final String memoText;
  final Future<List<String>> Function(String memoText) onAnalyze;

  @override
  State<_MPAnalyzeSuggestedTasksSheet> createState() =>
      _MPAnalyzeSuggestedTasksSheetState();
}

class _MPAnalyzeSuggestedTasksSheetState
    extends State<_MPAnalyzeSuggestedTasksSheet> {
  bool _loading = true;
  List<String> _suggestions = <String>[];
  int? _selectedIndex = 0;

  /// 当前处于行内编辑的建议下标；非空时展示输入框与确认勾。
  int? _editingIndex;

  TextEditingController? _editController;
  final FocusNode _editFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _editController?.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final List<String> result = await widget.onAnalyze(widget.memoText);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _suggestions = List<String>.from(result);
      _selectedIndex = result.isEmpty ? null : 0;
      _editingIndex = null;
      _editController?.dispose();
      _editController = null;
    });
  }

  /// 进入行内编辑；若已在编辑其他行，先提交当前编辑内容。
  void _beginInlineEdit(int index) {
    if (index < 0 || index >= _suggestions.length) return;
    if (_editingIndex == index) {
      _editFocusNode.requestFocus();
      return;
    }
    if (_editingIndex != null) {
      final int prev = _editingIndex!;
      final String t = _editController!.text.trim();
      if (t.isNotEmpty) {
        _suggestions[prev] = t;
      }
      _editController!.dispose();
      _editController = null;
    }
    setState(() {
      _editingIndex = index;
      _editController = TextEditingController(text: _suggestions[index]);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _editFocusNode.requestFocus();
      }
    });
  }

  /// 点击右侧勾：写入列表并结束编辑。
  void _commitInlineEdit() {
    final int? i = _editingIndex;
    if (i == null || _editController == null) return;
    final String t = _editController!.text.trim();
    setState(() {
      if (t.isNotEmpty) {
        _suggestions[i] = t;
      }
      _editingIndex = null;
    });
    _editController!.dispose();
    _editController = null;
  }

  static const Color _kCheckboxBlue = Color(0xFF1A73E8);

  /// 单条 suggestion：只读行（点选 + 铅笔）或行内编辑（输入框 + 确认勾）。
  Widget _buildSuggestionTile(int i) {
    final bool isSelected = i == _selectedIndex;
    final bool isEditing = i == _editingIndex;

    Widget inner;
    if (isEditing && _editController != null) {
      inner = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCFE0FF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _selectedIndex = isSelected ? null : i;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? _kCheckboxBlue : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kCheckboxBlue, width: 1.5),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _editController,
                focusNode: _editFocusNode,
                minLines: 1,
                maxLines: 4,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t5_14,
                  fontWeight: OmiFontWeight.medium,
                  color: mainTextColor,
                  height: 1.3,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: _kCheckboxBlue,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: _kCheckboxBlue,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: _kCheckboxBlue,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _commitInlineEdit,
              child: Padding(
                padding: const EdgeInsets.only(left: 2, top: 8),
                child: Icon(Icons.check, size: 18, color: blueTextColor),
              ),
            ),
          ],
        ),
      );
    } else {
      inner = InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = isSelected ? null : i;
          });
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                  color: isSelected ? _kCheckboxBlue : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kCheckboxBlue, width: 1.5),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
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
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _beginInlineEdit(i),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, top: 1),
                  child: OmiImageLoader.localImg(
                    Assets.omiDetailEdit,
                    width: 14,
                    height: 14,
                    color: secondTextColor.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: i == _suggestions.length - 1 ? 0 : 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8E7FF)),
        ),
        child: Material(color: Colors.transparent, child: inner),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
    );
  }

  /// 「FROM YOUR MEMO」+「SUGGESTIONS」列表；配合外层 [ConstrainedBox] 与 `shrinkWrap` 在超高时滚动。
  Widget _buildScrollableBody() {
    return ListView(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      children: <Widget>[
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
          child: Column(
            children: List<Widget>.generate(
              _suggestions.length,
              _buildSuggestionTile,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final double screenH = MediaQuery.sizeOf(context).height;
    final double capH = screenH * 0.6;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxSheet = math.min(
          capH,
          constraints.maxHeight.isFinite ? constraints.maxHeight : capH,
        );
        // 预留：顶栏+分隔线、底部分割线与按钮区（约），剩余高度给中间卡片滚动。
        const double kHeaderBlock = 56;
        const double kDivider = 1;
        const double kFooterBlock = 79;
        final double scrollMax = math.max(
          120,
          maxSheet - kHeaderBlock - kDivider - kFooterBlock - bottomInset,
        );

        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxSheet),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _buildHeader(),
                        Container(
                          height: 1,
                          color: lineColor.withValues(alpha: 0.8),
                        ),
                        if (_loading)
                          SizedBox(
                            height: 220,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const _MPAnalyzeSuggestedTasksLoadingDots(),
                                  const SizedBox(height: 24),
                                  const _MPAnalyzeSuggestedTasksAnalyzingLabel(),
                                ],
                              ),
                            ),
                          )
                        else ...<Widget>[
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: scrollMax),
                            child: _buildScrollableBody(),
                          ),
                          Container(
                            height: 1,
                            color: lineColor.withValues(alpha: 0.8),
                          ),
                          _buildFooter(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 分析中提示文案（loading 态）。
class _MPAnalyzeSuggestedTasksAnalyzingLabel extends StatelessWidget {
  const _MPAnalyzeSuggestedTasksAnalyzingLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Analyzing your memo...',
      style: OmiTextStyle.create(
        fontSize: OmiFontSize.t7_16,
        fontWeight: OmiFontWeight.medium,
        color: secondTextColor,
      ),
    );
  }
}

class _MPAnalyzeSuggestedTasksDot extends StatelessWidget {
  const _MPAnalyzeSuggestedTasksDot({
    required this.opacity,
    required this.scale,
  });

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

class _MPAnalyzeSuggestedTasksLoadingDots extends StatefulWidget {
  const _MPAnalyzeSuggestedTasksLoadingDots();

  @override
  State<_MPAnalyzeSuggestedTasksLoadingDots> createState() =>
      _MPAnalyzeSuggestedTasksLoadingDotsState();
}

class _MPAnalyzeSuggestedTasksLoadingDotsState
    extends State<_MPAnalyzeSuggestedTasksLoadingDots>
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
              child: _MPAnalyzeSuggestedTasksDot(
                opacity: opacity,
                scale: scale,
              ),
            );
          }),
        );
      },
    );
  }
}
