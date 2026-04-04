import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import 'mp_today_focus_todo_item.dart';

/// 单行待办数据（分组内使用）
class MPTodayFocusTodoRowData {
  const MPTodayFocusTodoRowData({
    required this.title,
    required this.timeLabel,
    this.todoId = '',
    this.isChecked = false,
    this.highlighted = false,
  });

  final String title;
  final String timeLabel;
  final String todoId;
  final bool isChecked;

  /// 仅 Overdue：浅灰高亮底
  final bool highlighted;
}

/// 分组标识（回调里区分来源）
enum MPTodayFocusTodoSection {
  today,
  upcomingWithinSevenDays,
  futureBeyondSevenDays,
  overdue,
  completed,
}

/// Today / Upcoming / Future，以及 Overdue、Completed（可折叠；Overdue 带 Clear）。
class MPTodayFocusTodoGroupedList extends StatefulWidget {
  const MPTodayFocusTodoGroupedList({
    super.key,
    this.todayItems = const <MPTodayFocusTodoRowData>[],
    this.upcomingItems = const <MPTodayFocusTodoRowData>[],
    this.futureItems = const <MPTodayFocusTodoRowData>[],
    this.overdueItems = const <MPTodayFocusTodoRowData>[],
    this.completedItems = const <MPTodayFocusTodoRowData>[],
    this.initialFutureExpanded = false,
    this.initialOverdueExpanded = true,
    this.initialCompletedExpanded = true,
    this.onOverdueClear,
    this.clearLabel = 'Clear',
    this.onItemCheckChanged,
    this.onItemTap,
    this.sectionGap = 24,
    this.itemGap = 4,
  });

  final List<MPTodayFocusTodoRowData> todayItems;
  final List<MPTodayFocusTodoRowData> upcomingItems;
  final List<MPTodayFocusTodoRowData> futureItems;
  final List<MPTodayFocusTodoRowData> overdueItems;
  final List<MPTodayFocusTodoRowData> completedItems;

  final bool initialFutureExpanded;
  final bool initialOverdueExpanded;
  final bool initialCompletedExpanded;

  final VoidCallback? onOverdueClear;
  final String clearLabel;

  final void Function(
    MPTodayFocusTodoSection section,
    int index,
    bool isChecked,
  )? onItemCheckChanged;

  final void Function(MPTodayFocusTodoSection section, int index)? onItemTap;

  final double sectionGap;
  final double itemGap;

  @override
  State<MPTodayFocusTodoGroupedList> createState() =>
      _MPTodayFocusTodoGroupedListState();
}

class _MPTodayFocusTodoGroupedListState
    extends State<MPTodayFocusTodoGroupedList> {
  late bool _futureExpanded;
  late bool _overdueExpanded;
  late bool _completedExpanded;

  @override
  void initState() {
    super.initState();
    _futureExpanded = widget.initialFutureExpanded;
    _overdueExpanded = widget.initialOverdueExpanded;
    _completedExpanded = widget.initialCompletedExpanded;
  }

  @override
  void didUpdateWidget(MPTodayFocusTodoGroupedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.futureItems.isEmpty) {
      _futureExpanded = false;
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

  Widget _overdueHeader() {
    return _collapsibleMutedHeader(
      title: 'Overdue',
      expanded: _overdueExpanded,
      onToggle: () => setState(() => _overdueExpanded = !_overdueExpanded),
      trailing: TextButton(
        onPressed: widget.onOverdueClear,
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
      ),
    );
  }

  Widget _completedHeader() {
    return _collapsibleMutedHeader(
      title: 'Completed',
      expanded: _completedExpanded,
      onToggle: () => setState(() => _completedExpanded = !_completedExpanded),
      trailing: null,
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
      out.add(
        MPTodayFocusTodoItem(
          title: row.title,
          timeLabel: row.timeLabel,
          isChecked: row.isChecked,
          tone: tone,
          highlighted: row.highlighted,
          onChanged: widget.onItemCheckChanged == null
              ? null
              : (bool v) => widget.onItemCheckChanged!(section, i, v),
          onTap: widget.onItemTap == null
              ? null
              : () => widget.onItemTap!(section, i),
        ),
      );
    }
    return out;
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
