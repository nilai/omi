import 'package:flutter/material.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import 'mp_ask_ai_conversation_swipe_reveal_bus.dart';

/// 左滑露出右侧 Delete 按钮，点击后再触发 [onDelete]（非滑满即删）。
class MPAskAIConversationSwipeDeleteItem extends StatefulWidget {
  const MPAskAIConversationSwipeDeleteItem({
    super.key,
    required this.rowId,
    required this.swipeRevealBus,
    required this.child,
    required this.onDelete,
    this.onContentTap,
  });

  final String rowId;
  final MPAskAIConversationSwipeRevealBus swipeRevealBus;
  final Widget child;
  final VoidCallback onDelete;
  final VoidCallback? onContentTap;

  @override
  State<MPAskAIConversationSwipeDeleteItem> createState() =>
      _MPAskAIConversationSwipeDeleteItemState();
}

class _MPAskAIConversationSwipeDeleteItemState
    extends State<MPAskAIConversationSwipeDeleteItem> {
  static const double _kActionWidth = 72;

  /// 非正数，0 为闭合，`-_kActionWidth` 为完全露出删除区。
  double _offsetX = 0;

  void _onBusChanged() {
    if (!mounted) return;
    final String? openRowId = widget.swipeRevealBus.openRowId.value;
    if (_offsetX != 0 && openRowId != widget.rowId) {
      setState(() => _offsetX = 0);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.swipeRevealBus.openRowId.addListener(_onBusChanged);
  }

  @override
  void dispose() {
    widget.swipeRevealBus.openRowId.removeListener(_onBusChanged);
    super.dispose();
  }

  void _close() {
    if (!mounted) return;
    setState(() => _offsetX = 0);
    if (widget.swipeRevealBus.openRowId.value == widget.rowId) {
      widget.swipeRevealBus.openRowId.value = null;
    }
  }

  /// 点击行内容：已露出 Delete 时仅收回到 normal；否则触发 [onContentTap]。
  void _handleContentTap() {
    final VoidCallback? onContentTap = widget.onContentTap;
    if (onContentTap == null) {
      return;
    }
    if (_offsetX != 0) {
      _close();
      return;
    }
    onContentTap();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      clipBehavior: Clip.hardEdge,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: <Widget>[
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: _kActionWidth,
            child: Container(
              alignment: Alignment.center,
              color: redColor,
              child: SizedBox.expand(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _close();
                    widget.onDelete();
                  },
                  child: Center(
                    child: Text(
                      'Delete',
                      textAlign: TextAlign.center,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t6_15,
                        fontWeight: OmiFontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (DragUpdateDetails details) {
              setState(() {
                _offsetX =
                    (_offsetX + details.delta.dx).clamp(-_kActionWidth, 0.0);
              });
            },
            onHorizontalDragEnd: (DragEndDetails details) {
              final double? vx = details.primaryVelocity;
              setState(() {
                if (vx != null && vx < -400) {
                  _offsetX = -_kActionWidth;
                } else if (vx != null && vx > 400) {
                  _offsetX = 0;
                } else if (_offsetX.abs() > _kActionWidth / 2) {
                  _offsetX = -_kActionWidth;
                } else {
                  _offsetX = 0;
                }
              });
              if (_offsetX == -_kActionWidth) {
                widget.swipeRevealBus.open(widget.rowId);
              } else if (widget.swipeRevealBus.openRowId.value == widget.rowId) {
                widget.swipeRevealBus.openRowId.value = null;
              }
            },
            child: Transform.translate(
              offset: Offset(_offsetX, 0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onContentTap == null ? null : _handleContentTap,
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
