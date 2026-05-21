import 'package:flutter/material.dart';
import 'package:memo_pin/tab/home/todayFocus/mp_today_focus_swipe_reveal_bus.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

/// 「Today's Focus」单条数据
class MPTodayFocusCardItem {
  const MPTodayFocusCardItem({
    required this.title,
    required this.subtext,
    required this.timeLabel,
    this.todoId = '',
    this.memoryId,
    this.insightId,
    this.slot,
    this.deadlineUnixSec,
    this.description,
  });

  final String title;
  final String subtext;
  final String timeLabel;

  /// 与服务端 todo id 一致；无 id 时为空。
  final String todoId;

  /// 关联 Memory id（与 [MPTodoStruct.memoryId] 一致）；无关联时为 `null`。
  final int? memoryId;

  /// 关联 Insight id（与 [MPInsightListItem.id] 一致）；无关联时为 `null`。
  final String? insightId;

  /// Today's Focus 槽位（与 [MPTodoStruct.slot]、[MPRemoveTodayFocusRequest.slot] 一致）；为空时由列表下标推断。
  final int? slot;

  /// 与 [MPTodoStruct.deadline] 一致（Unix 秒）；无截止为 `null`。
  final int? deadlineUnixSec;

  final String? description;
}

/// 「Today's Focus」整卡数据
class MPTodayFocusCardData {
  const MPTodayFocusCardData({
    this.headerTitle = "Today's Focus",
    required this.items,
  });

  final String headerTitle;
  final List<MPTodayFocusCardItem> items;

  MPTodayFocusCardData copyWith({
    String? headerTitle,
    List<MPTodayFocusCardItem>? items,
  }) {
    return MPTodayFocusCardData(
      headerTitle: headerTitle ?? this.headerTitle,
      items: items ?? this.items,
    );
  }
}

/// 浅绿底圆角卡片：标题 + 星标列表（标题 / → 副文案 / 右侧时间）
class MPTodayFocusCard extends StatelessWidget {
  const MPTodayFocusCard({
    super.key,
    required this.data,
    required this.swipeRevealBus,
    this.onItemTap,
    this.onItemDeleted,
  });

  final MPTodayFocusCardData data;
  final MPTodayFocusSwipeRevealBus swipeRevealBus;
  final void Function(int index, MPTodayFocusCardItem item)? onItemTap;

  /// 左滑露出删除按钮，点击删除后回调；为 `null` 时不启用。
  final void Function(int index)? onItemDeleted;

  static const Color _kCardBg = Color(0xFFF4F9F7);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            data.headerTitle,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t8_17,
              fontWeight: OmiFontWeight.bold,
              color: mainTextColor,
            ),
          ),
          if (data.items.isNotEmpty) const SizedBox(height: 16),
          ...List<Widget>.generate(data.items.length, (int index) {
            final MPTodayFocusCardItem item = data.items[index];
            final Widget row = _MPTodayFocusItemRow(item: item);
            Widget content = onItemTap == null
                ? row
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onItemTap!(index, item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: row,
                      ),
                    ),
                  );
            if (onItemDeleted != null) {
              final String rowId =
                  'focus_remove_${item.todoId}_${index}_${item.title}_${item.timeLabel}';
              content = _MPTodayFocusRevealDeleteRow(
                key: ValueKey<String>('mp_$rowId'),
                rowId: rowId,
                swipeRevealBus: swipeRevealBus,
                cardBgColor: _kCardBg,
                onDelete: () => onItemDeleted!(index),
                child: content,
              );
            }
            if (index == 0) {
              return content;
            }
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: content,
            );
          }),
        ],
      ),
    );
  }
}

/// 左滑露出右侧「删除」按钮，点击后再触发 [onDelete]（非滑满即删）。
class _MPTodayFocusRevealDeleteRow extends StatefulWidget {
  const _MPTodayFocusRevealDeleteRow({
    super.key,
    required this.rowId,
    required this.swipeRevealBus,
    required this.cardBgColor,
    required this.child,
    required this.onDelete,
  });

  final String rowId;
  final MPTodayFocusSwipeRevealBus swipeRevealBus;
  final Color cardBgColor;
  final Widget child;
  final VoidCallback onDelete;

  @override
  State<_MPTodayFocusRevealDeleteRow> createState() =>
      _MPTodayFocusRevealDeleteRowState();
}

class _MPTodayFocusRevealDeleteRowState
    extends State<_MPTodayFocusRevealDeleteRow> {
  static const double _kActionWidth = 66;

  /// 非正数，0 为闭合，`-_kActionWidth` 为完全露出删除区。
  double _offsetX = 0;

  void _onBusChanged() {
    if (!mounted) return;
    final String? openRemoveId = widget.swipeRevealBus.openRemoveRowId.value;
    final bool shouldClose =
        (openRemoveId != null && openRemoveId != widget.rowId) ||
        widget.swipeRevealBus.openAddRowId.value != null;
    if (shouldClose && _offsetX != 0) {
      setState(() => _offsetX = 0);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.swipeRevealBus.openRemoveRowId.addListener(_onBusChanged);
    widget.swipeRevealBus.openAddRowId.addListener(_onBusChanged);
  }

  @override
  void dispose() {
    widget.swipeRevealBus.openRemoveRowId.removeListener(_onBusChanged);
    widget.swipeRevealBus.openAddRowId.removeListener(_onBusChanged);
    super.dispose();
  }

  void _close() {
    if (!mounted) return;
    setState(() => _offsetX = 0);
    if (widget.swipeRevealBus.openRemoveRowId.value == widget.rowId) {
      widget.swipeRevealBus.openRemoveRowId.value = null;
    }
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
                      'Remove from\nfocus',
                      textAlign: TextAlign.center,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t3_12,
                        fontWeight: OmiFontWeight.regular,
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
                widget.swipeRevealBus.openRemove(widget.rowId);
              } else if (widget.swipeRevealBus.openRemoveRowId.value ==
                  widget.rowId) {
                widget.swipeRevealBus.openRemoveRowId.value = null;
              }
            },
            child: Transform.translate(
              offset: Offset(_offsetX, 0),
              child: Container(
                width: double.infinity,
                color: widget.cardBgColor,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MPTodayFocusItemRow extends StatelessWidget {
  const _MPTodayFocusItemRow({required this.item});

  final MPTodayFocusCardItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.star_border_rounded,
            size: 18,
            color: orangeTextColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t5_14,
                  fontWeight: OmiFontWeight.medium,
                  color: mainTextColor,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '→ ${item.subtext}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t4_13,
                  fontWeight: OmiFontWeight.regular,
                  color: secondTextColor,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          item.timeLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: OmiTextStyle.create(
            fontSize: OmiFontSize.t5_14,
            fontWeight: OmiFontWeight.regular,
            color: secondTextColor,
          ),
        ),
      ],
    );
  }
}
