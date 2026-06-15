import 'package:flutter/material.dart';
import 'package:memo_pin/tab/home/todayFocus/mp_today_focus_swipe_reveal_bus.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import 'mp_today_focus_todo_item.dart';

/// 单行待办数据（分组内使用）
class MPTodayFocusTodoRowData {
  const MPTodayFocusTodoRowData({
    required this.title,
    required this.timeLabel,
    this.todoId = '',
    this.memoryId,
    this.insightId,
    this.status = 1,
    this.priorityApi = 'Normal',
    this.deadlineUnixSec,
    this.sourceSection,
    this.isChecked = false,
    this.highlighted = false,
    this.slot,
    this.description,
  });

  final String title;
  final String timeLabel;
  final String todoId;
  final int? slot;

  /// 关联 Memory id；无关联时为 `null`。
  final int? memoryId;
  final String? insightId;
  final int status;
  final String priorityApi;
  final int? deadlineUnixSec;
  final MPTodayFocusTodoSection? sourceSection;
  final bool isChecked;

  /// 仅 Overdue：浅灰高亮底
  final bool highlighted;

  final String? description;
}

/// 分组标识（回调里区分来源）
enum MPTodayFocusTodoSection {
  today,
  upcomingWithinSevenDays,
  futureBeyondSevenDays,
  unscheduled,
  overdue,
  completed,
}

/// Today / Upcoming / Future，以及 Overdue、Completed（可折叠；Overdue 带 Clear）。
class MPTodayFocusTodoGroupedList extends StatefulWidget {
  const MPTodayFocusTodoGroupedList({
    super.key,
    required this.swipeRevealBus,
    this.todayItems = const <MPTodayFocusTodoRowData>[],
    this.upcomingItems = const <MPTodayFocusTodoRowData>[],
    this.futureItems = const <MPTodayFocusTodoRowData>[],
    this.unscheduledItems = const <MPTodayFocusTodoRowData>[],
    this.overdueItems = const <MPTodayFocusTodoRowData>[],
    this.completedItems = const <MPTodayFocusTodoRowData>[],
    this.initialFutureExpanded = false,
    this.initialUnscheduledExpanded = true,
    this.initialOverdueExpanded = true,
    this.initialCompletedExpanded = true,
    this.onUnscheduledClear,
    this.onOverdueClear,
    this.onCompletedClear,
    this.clearLabel = 'Clear',
    this.onItemCheckChanged,
    this.onItemTap,
    this.onItemAddToFocus,
    this.sectionGap = 24,
    this.itemGap = 4,
  });

  final MPTodayFocusSwipeRevealBus swipeRevealBus;
  final List<MPTodayFocusTodoRowData> todayItems;
  final List<MPTodayFocusTodoRowData> upcomingItems;
  final List<MPTodayFocusTodoRowData> futureItems;
  final List<MPTodayFocusTodoRowData> unscheduledItems;
  final List<MPTodayFocusTodoRowData> overdueItems;
  final List<MPTodayFocusTodoRowData> completedItems;

  final bool initialFutureExpanded;
  final bool initialUnscheduledExpanded;
  final bool initialOverdueExpanded;
  final bool initialCompletedExpanded;

  final VoidCallback? onUnscheduledClear;
  final VoidCallback? onOverdueClear;
  final VoidCallback? onCompletedClear;
  final String clearLabel;

  final void Function(
    MPTodayFocusTodoSection section,
    int index,
    bool isChecked,
  )? onItemCheckChanged;

  final void Function(MPTodayFocusTodoSection section, int index)? onItemTap;

  /// 右滑露出「Add to Today's Focus」按钮；目前仅 Today 分组启用。
  final void Function(MPTodayFocusTodoSection section, int index)? onItemAddToFocus;

  final double sectionGap;
  final double itemGap;

  @override
  State<MPTodayFocusTodoGroupedList> createState() =>
      _MPTodayFocusTodoGroupedListState();
}

class _MPTodayFocusTodoGroupedListState
    extends State<MPTodayFocusTodoGroupedList> {
  late bool _futureExpanded;
  late bool _unscheduledExpanded;
  late bool _overdueExpanded;
  late bool _completedExpanded;

  @override
  void initState() {
    super.initState();
    _futureExpanded = widget.initialFutureExpanded;
    _unscheduledExpanded = widget.initialUnscheduledExpanded;
    _overdueExpanded = widget.initialOverdueExpanded;
    _completedExpanded = widget.initialCompletedExpanded;
  }

  @override
  void didUpdateWidget(MPTodayFocusTodoGroupedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.futureItems.isEmpty) {
      _futureExpanded = false;
    }
    if (widget.unscheduledItems.isEmpty) {
      _unscheduledExpanded = widget.initialUnscheduledExpanded;
    }
    if (widget.overdueItems.isEmpty) {
      _overdueExpanded = widget.initialOverdueExpanded;
    }
    if (widget.completedItems.isEmpty) {
      _completedExpanded = widget.initialCompletedExpanded;
    }
  }

  TextStyle _headerStyle({required bool isToday}) {
    return OmiTextStyle.create(
      fontSize: OmiFontSize.t5_14,
      fontWeight: OmiFontWeight.medium,
      color: isToday ? mainTextColor : secondTextColor,
      height: 1.25,
    );
  }

  TextStyle get _mutedHeaderStyle => OmiTextStyle.create(
        fontSize: OmiFontSize.t5_14,
        fontWeight: OmiFontWeight.medium,
        color: secondTextColor,
        height: 1.25,
      );

  Widget _sectionHeader(String title, {required bool isToday}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title, style: _headerStyle(isToday: isToday)),
    );
  }

  Widget _futureHeader() {
    final int n = widget.futureItems.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: GestureDetector(
        onTap: n == 0
            ? null
            : () => setState(() => _futureExpanded = !_futureExpanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  'Future (>7 days)',
                  style: _headerStyle(isToday: false),
                ),
              ),
              if (n > 0) ...<Widget>[
                Icon(
                  _futureExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: secondTextColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _collapsibleMutedHeader({
    required String title,
    required bool expanded,
    required VoidCallback? onToggle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: Row(
                  children: <Widget>[
                    Text(title, style: _mutedHeaderStyle),
                    const SizedBox(width: 4),
                    Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: secondTextColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _clearTrailingButton(VoidCallback? onClear) {
    if (onClear == null) {
      return const SizedBox.shrink();
    }
    return TextButton(
      onPressed: onClear,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: secondTextColor.withValues(alpha: 0.75),
      ),
      child: Text(
        widget.clearLabel,
        style: OmiTextStyle.create(
          fontSize: OmiFontSize.t3_12,
          fontWeight: OmiFontWeight.regular,
          color: secondTextColor.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  Widget _unscheduledHeader() {
    return _collapsibleMutedHeader(
      title: 'Unscheduled',
      expanded: _unscheduledExpanded,
      onToggle: () => setState(() => _unscheduledExpanded = !_unscheduledExpanded),
      trailing: _clearTrailingButton(widget.onUnscheduledClear),
    );
  }

  Widget _overdueHeader() {
    return _collapsibleMutedHeader(
      title: 'Overdue',
      expanded: _overdueExpanded,
      onToggle: () => setState(() => _overdueExpanded = !_overdueExpanded),
      trailing: _clearTrailingButton(widget.onOverdueClear),
    );
  }

  Widget _completedHeader() {
    return _collapsibleMutedHeader(
      title: 'Completed',
      expanded: _completedExpanded,
      onToggle: () => setState(() => _completedExpanded = !_completedExpanded),
      trailing: _clearTrailingButton(widget.onCompletedClear),
    );
  }

  List<Widget> _buildItems({
    required MPTodayFocusTodoSection section,
    required List<MPTodayFocusTodoRowData> items,
    required MPTodayFocusTodoItemTone tone,
  }) {
    final List<Widget> out = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      if (i > 0) {
        out.add(SizedBox(height: widget.itemGap));
      }
      final MPTodayFocusTodoRowData row = items[i];
      final VoidCallback? contentTap = widget.onItemTap == null
          ? null
          : () => widget.onItemTap!(section, i);

      if (section == MPTodayFocusTodoSection.today &&
          widget.onItemAddToFocus != null) {
        final String rowId =
            'today_add_focus_${row.todoId}_${i}_${row.title}_${row.timeLabel}';
        out.add(
          _MPTodayTodoRevealAddToFocusRow(
            key: ValueKey<String>('mp_${rowId}'),
            rowId: rowId,
            swipeRevealBus: widget.swipeRevealBus,
            onAdd: () => widget.onItemAddToFocus!(section, i),
            onContentTap: contentTap,
            builder: (VoidCallback? onTitleTap) => MPTodayFocusTodoItem(
              title: row.title,
              timeLabel: _timeLabelForRow(row),
              isChecked: row.isChecked,
              tone: tone,
              highlighted: row.highlighted,
              onChanged: widget.onItemCheckChanged == null
                  ? null
                  : (bool v) => widget.onItemCheckChanged!(section, i, v),
              onTap: onTitleTap,
            ),
          ),
        );
        continue;
      }

      out.add(
        MPTodayFocusTodoItem(
          title: row.title,
          timeLabel: _timeLabelForRow(row),
          isChecked: row.isChecked,
          tone: tone,
          highlighted: row.highlighted,
          onChanged: widget.onItemCheckChanged == null
              ? null
              : (bool v) => widget.onItemCheckChanged!(section, i, v),
          onTap: contentTap,
        ),
      );
    }
    return out;
  }

  /// 右侧时间：仅展示 [MPTodayFocusTodoRowData.timeLabel]（由 `show_time` 本地时区解析，无 `deadline` 兜底）。
  static String _timeLabelForRow(MPTodayFocusTodoRowData row) {
    final String label = row.timeLabel.trim();
    return label.isEmpty ? 'No deadline' : label;
  }

  void _addGapIfNeeded(List<Widget> children) {
    if (children.isNotEmpty) {
      children.add(SizedBox(height: widget.sectionGap));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];

    if (widget.todayItems.isNotEmpty) {
      children.add(_sectionHeader('Today', isToday: true));
      children.addAll(
        _buildItems(
          section: MPTodayFocusTodoSection.today,
          items: widget.todayItems,
          tone: MPTodayFocusTodoItemTone.today,
        ),
      );
    }

    if (widget.upcomingItems.isNotEmpty) {
      _addGapIfNeeded(children);
      children.add(_sectionHeader('Upcoming (7 days)', isToday: false));
      children.addAll(
        _buildItems(
          section: MPTodayFocusTodoSection.upcomingWithinSevenDays,
          items: widget.upcomingItems,
          tone: MPTodayFocusTodoItemTone.upcoming,
        ),
      );
    }

    if (widget.futureItems.isNotEmpty) {
      _addGapIfNeeded(children);
      children.add(_futureHeader());
      if (_futureExpanded) {
        children.addAll(
          _buildItems(
            section: MPTodayFocusTodoSection.futureBeyondSevenDays,
            items: widget.futureItems,
            tone: MPTodayFocusTodoItemTone.upcoming,
          ),
        );
      }
    }

    if (widget.unscheduledItems.isNotEmpty) {
      _addGapIfNeeded(children);
      children.add(_unscheduledHeader());
      if (_unscheduledExpanded) {
        children.addAll(
          _buildItems(
            section: MPTodayFocusTodoSection.unscheduled,
            items: widget.unscheduledItems,
            tone: MPTodayFocusTodoItemTone.overdue,
          ),
        );
      }
    }

    if (widget.overdueItems.isNotEmpty) {
      _addGapIfNeeded(children);
      children.add(_overdueHeader());
      if (_overdueExpanded) {
        children.addAll(
          _buildItems(
            section: MPTodayFocusTodoSection.overdue,
            items: widget.overdueItems,
            tone: MPTodayFocusTodoItemTone.overdue,
          ),
        );
      }
    }

    if (widget.completedItems.isNotEmpty) {
      _addGapIfNeeded(children);
      children.add(_completedHeader());
      if (_completedExpanded) {
        children.addAll(
          _buildItems(
            section: MPTodayFocusTodoSection.completed,
            items: widget.completedItems,
            tone: MPTodayFocusTodoItemTone.completed,
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// 右滑露出左侧「Add to Today's Focus」按钮（非滑满即触发）。
class _MPTodayTodoRevealAddToFocusRow extends StatefulWidget {
  const _MPTodayTodoRevealAddToFocusRow({
    super.key,
    required this.rowId,
    required this.swipeRevealBus,
    required this.builder,
    required this.onAdd,
    this.onContentTap,
  });

  final String rowId;
  final MPTodayFocusSwipeRevealBus swipeRevealBus;
  final Widget Function(VoidCallback? onTitleTap) builder;
  final VoidCallback onAdd;
  final VoidCallback? onContentTap;

  @override
  State<_MPTodayTodoRevealAddToFocusRow> createState() =>
      _MPTodayTodoRevealAddToFocusRowState();
}

class _MPTodayTodoRevealAddToFocusRowState
    extends State<_MPTodayTodoRevealAddToFocusRow> {
  static const double _kActionWidth = 108;

  /// 非负数，0 为闭合，`_kActionWidth` 为完全露出按钮区。
  double _offsetX = 0;

  void _onBusChanged() {
    if (!mounted) return;
    final String? openAddId = widget.swipeRevealBus.openAddRowId.value;
    final bool shouldClose =
        (openAddId != null && openAddId != widget.rowId) ||
        widget.swipeRevealBus.openRemoveRowId.value != null;
    if (shouldClose && _offsetX != 0) {
      setState(() => _offsetX = 0);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.swipeRevealBus.openAddRowId.addListener(_onBusChanged);
    widget.swipeRevealBus.openRemoveRowId.addListener(_onBusChanged);
  }

  @override
  void dispose() {
    widget.swipeRevealBus.openAddRowId.removeListener(_onBusChanged);
    widget.swipeRevealBus.openRemoveRowId.removeListener(_onBusChanged);
    super.dispose();
  }

  void _close() {
    if (!mounted) return;
    setState(() => _offsetX = 0);
    if (widget.swipeRevealBus.openAddRowId.value == widget.rowId) {
      widget.swipeRevealBus.openAddRowId.value = null;
    }
  }

  void _setOpen() {
    widget.swipeRevealBus.openAdd(widget.rowId);
  }

  /// 点击行标题：normal 显示弹窗；已露出 Add to Today's Focus 时仅收回到 normal。
  void _handleContentTap() {
    final VoidCallback? onContentTap = widget.onContentTap;
    if (onContentTap == null) {
      return;
    }
    if (_offsetX > 0) {
      _close();
      return;
    }
    onContentTap();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      clipBehavior: Clip.hardEdge,
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            bottom: 0,
            width: _kActionWidth,
            child: Container(
              alignment: Alignment.center,
              color: greenTextColor,
              child: SizedBox.expand(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _close();
                    widget.onAdd();
                  },
                  child: Center(
                    child: Text(
                      'Add to\nToday\'s Focus',
                      textAlign: TextAlign.center,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t3_12,
                        fontWeight: OmiFontWeight.medium,
                        color: Colors.white,
                        height: 1.1,
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
                _offsetX = (_offsetX + details.delta.dx).clamp(0.0, _kActionWidth);
              });
            },
            onHorizontalDragEnd: (DragEndDetails details) {
              final double? vx = details.primaryVelocity;
              setState(() {
                if (vx != null && vx > 400) {
                  _offsetX = _kActionWidth;
                } else if (vx != null && vx < -400) {
                  _offsetX = 0;
                } else if (_offsetX > _kActionWidth / 2) {
                  _offsetX = _kActionWidth;
                } else {
                  _offsetX = 0;
                }
              });
              if (_offsetX > 0) {
                _setOpen();
              } else if (widget.swipeRevealBus.openAddRowId.value == widget.rowId) {
                widget.swipeRevealBus.openAddRowId.value = null;
              }
            },
            child: Transform.translate(
              offset: Offset(_offsetX, 0),
              child: widget.builder(
                widget.onContentTap == null ? null : _handleContentTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
