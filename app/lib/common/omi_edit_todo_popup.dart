import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memo_pin/common/mp_todo_popup_guard.dart';
import 'package:memo_pin/common/mp_todo_manager.dart';
import 'package:memo_pin/common/mp_todo_utils.dart';
import 'package:memo_pin/common/omi_button.dart';
import 'package:memo_pin/common/omi_todo_more_sheet.dart';
import 'package:memo_pin/common/mp_confirm_delete_dialog.dart';
import 'package:memo_pin/utils/mp_time_utils.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../generated/assets.dart';
import '../http/schema/mp_data_model.dart';
import '../tab/home/insights/mp_daily_insight_detail_page.dart';
import '../tab/home/insights/mp_monthly_insight_detail_page.dart';
import '../tab/home/insights/mp_pattern_insight_detail_page.dart';
import '../tab/home/insights/mp_weekly_insight_detail_page.dart';
import '../tab/home/insights/mp_insights_list_cubit.dart';
import '../tab/memory/detail/mp_memory_detail_helper.dart';
import 'mp_home_notification.dart';


class OmiEditTodoPopupParams {
  const OmiEditTodoPopupParams({
    required this.title,
    this.contextMemoryLabel = '',
    this.contextMemoryTitle = '',
    this.contextMetaLine = '',
    this.notes = '',
    this.priorityLabel = 'Normal',
    this.whenLabel = 'No deadline',
    this.timeLabel = '09:00',
    this.todoId = '',
    this.deadlineUnixSec,
    this.memoryId,
    this.memoryType,
    this.insightId,
    this.insightType,
  });

  final String title;
  final String contextMemoryLabel;
  final String contextMemoryTitle;
  final String contextMetaLine;
  final int? memoryId;

  /// 关联 Memory 类型（如 [MPMemorySimpleInfoStruct.type]）；为空时跳转详情回退为 [MPMemoryType.memoryFeed]。
  final MPMemoryType? memoryType;

  /// [contextMemoryLabel]、[contextMemoryTitle]、[contextMetaLine] 去首尾空白后均为空时不展示 CONTEXT 区块。
  bool get shouldShowContextSection =>
      contextMemoryLabel.trim().isNotEmpty ||
      contextMemoryTitle.trim().isNotEmpty ||
      contextMetaLine.trim().isNotEmpty;

  final String notes;
  final String priorityLabel;
  final String whenLabel;
  final String timeLabel;
  final String todoId;
  final String? insightId;
  final MPInsightCardType? insightType;

  /// 截止时间 Unix（秒或毫秒，与 [MPMemoryCreatedTodoLineData.deadlineLabel] 一致）；无截止为 `null`。
  final int? deadlineUnixSec;
}

/// 关闭编辑弹层后：为 `true` 表示已发生「需同步待办列表」的操作（如 Mark as done 成功）。
Future<bool> showOmiEditTodoPopup(
  BuildContext context, {
  required OmiEditTodoPopupParams params,
  VoidCallback? onMarkAsDone,
  Future<bool> Function()? onDelete,
}) async {
  if (!MPTodoPopupGuard.tryAcquire()) {
    return false;
  }
  try {
    final bool? value = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheetContext) {
        return _OmiEditTodoPopupSheet(
          params: params,
          onMarkAsDone: onMarkAsDone,
          rootContext: context,
          onDelete: onDelete,
        );
      },
    );
    return value == true;
  } finally {
    MPTodoPopupGuard.release();
  }
}

class _OmiEditTodoPopupSheet extends StatefulWidget {
  const _OmiEditTodoPopupSheet({
    required this.params,
    required this.rootContext,
    this.onMarkAsDone,
    this.onDelete,
  });

  final OmiEditTodoPopupParams params;
  final VoidCallback? onMarkAsDone;
  final BuildContext rootContext;
  final Future<bool> Function()? onDelete;

  @override
  State<_OmiEditTodoPopupSheet> createState() => _OmiEditTodoPopupSheetState();
}

class _OmiEditTodoPopupSheetState extends State<_OmiEditTodoPopupSheet> {
  late String _priority;
  late String _when;
  late String _time;
  late final TextEditingController _notesController;
  int? _deadlineUnixSec;
  DateTime? _pickedCalendarDate;
  bool _isMarkingDone = false;
  bool _isSavingChanges = false;

  bool get _isActionInProgress => _isMarkingDone || _isSavingChanges;

  static DateTime _dateOnly(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day);

  TimeOfDay _parseTimeOfDayFromEdit(
    String raw, {
    int? fallbackFromSec,
  }) {
    final String t = raw.trim();
    if (t.isEmpty || t.startsWith('--')) {
      if (fallbackFromSec != null) {
        final DateTime dt =
            MPTimeUtils.dateTimeFromUnixEpoch(fallbackFromSec)!;
        return TimeOfDay(hour: dt.hour, minute: dt.minute);
      }
      return const TimeOfDay(hour: 9, minute: 0);
    }
    final List<String> parts = t.split(':');
    final int h = int.tryParse(parts[0]) ?? 9;
    final int m = parts.length >= 2 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return TimeOfDay(
      hour: h.clamp(0, 23),
      minute: m.clamp(0, 59),
    );
  }

  void _syncDeadlineFromWhenAndTime() {
    if (_when == 'No deadline') {
      _deadlineUnixSec = null;
      return;
    }
    final int? secBefore = _deadlineUnixSec;
    final TimeOfDay tod = _parseTimeOfDayFromEdit(
      _time,
      fallbackFromSec: secBefore,
    );
    final DateTime now = MPTimeUtils.nowInTimeZone();
    late final DateTime day;
    if (_when == 'Today') {
      day = _dateOnly(now);
    } else if (_when == 'Tomorrow') {
      day = _dateOnly(now).add(const Duration(days: 1));
    } else if (_pickedCalendarDate != null) {
      day = _pickedCalendarDate!;
    } else {
      try {
        final DateTime parsed = DateFormat('MMM d, y').parse(_when, false);
        day = DateTime.utc(parsed.year, parsed.month, parsed.day);
      } catch (_) {
        try {
          final DateTime parsed =
              DateFormat('yyyy年M月d日').parse(_when, false);
          day = DateTime.utc(parsed.year, parsed.month, parsed.day);
        } catch (_) {
          return;
        }
      }
    }
    _deadlineUnixSec = MPTimeUtils.unixSecondsFromLocalParts(
      year: day.year,
      month: day.month,
      day: day.day,
      hour: tod.hour,
      minute: tod.minute,
    );
  }

  void _applyInitialDeadlineSeconds(int raw) {
    final int sec = raw > 10000000000 ? raw ~/ 1000 : raw;
    final DateTime local = MPTimeUtils.dateTimeFromUnixEpoch(sec)!;
    final DateTime day = DateTime.utc(local.year, local.month, local.day);
    final DateTime today = MPTimeUtils.startOfTodayInTimeZone();
    final DateTime tomorrow = today.add(const Duration(days: 1));

    _pickedCalendarDate = day;
    _time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (day == today) {
      _when = 'Today';
      _pickedCalendarDate = null;
    } else if (day == tomorrow) {
      _when = 'Tomorrow';
      _pickedCalendarDate = null;
    } else {
      _when = DateFormat('MMM d, y').format(day);
    }
    _deadlineUnixSec = sec;
  }

  Future<void> _pickDateOnlyFlow() async {
    final DateTime now = MPTimeUtils.nowInTimeZone();
    final DateTime today = _dateOnly(now);
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _pickedCalendarDate ?? today,
      firstDate: DateTime.utc(today.year - 1),
      lastDate: DateTime.utc(today.year + 5),
    );
    if (!mounted || date == null) {
      return;
    }
    setState(() {
      _pickedCalendarDate = _dateOnly(date);
      _when = DateFormat('MMM d, y').format(_pickedCalendarDate!);
      if (_time.isEmpty) {
        _time = '09:00';
      }
      _syncDeadlineFromWhenAndTime();
    });
  }

  Future<void> _pickWhenForEdit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final String? v = await _showOptionSheet(
      options: MPTodoUtils.kTodoWhenOptions,
      selected: _when,
    );
    if (v == null || !mounted) return;
    if (v == 'Pick a date') {
      await _pickDateOnlyFlow();
      return;
    }
    setState(() {
      _when = v;
      _pickedCalendarDate = null;
      if (v == 'No deadline') {
        _time = '';
      } else if (_time.isEmpty) {
        _time = '09:00';
      }
      _syncDeadlineFromWhenAndTime();
    });
  }

  @override
  void initState() {
    super.initState();
    final OmiEditTodoPopupParams p = widget.params;
    _priority = MPTodoUtils.normalizePriorityPickerLabel(p.priorityLabel);
    _notesController = TextEditingController(text: p.notes);
    final bool isInitialDeadlineValid =
        p.deadlineUnixSec != null && p.deadlineUnixSec! > 0;
    if (isInitialDeadlineValid) {
      _applyInitialDeadlineSeconds(p.deadlineUnixSec!);
    } else {
      _when = p.whenLabel;
      _time = p.whenLabel == 'No deadline'
          ? ''
          : (p.timeLabel.isNotEmpty ? p.timeLabel : '09:00');
      _pickedCalendarDate = null;
      _syncDeadlineFromWhenAndTime();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<String?> _showOptionSheet({
    required List<String> options,
    required String selected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      barrierColor: Colors.black54,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((String e) {
              final bool isSel = e == selected;
              return ListTile(
                title: Text(
                  e,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t6_15,
                    color: isSel ? blueTextColor : mainTextColor,
                    fontWeight: isSel
                        ? OmiFontWeight.medium
                        : OmiFontWeight.regular,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(e),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  int _safeInt(String raw, {required int min, required int max}) {
    final int? v = int.tryParse(raw);
    if (v == null) return min;
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }

  Future<String?> _showTimeWheelSheet({required String selected}) {
    final List<String> parts = selected.split(':');
    int hour = 0;
    int minute = 0;
    if (parts.length == 2) {
      hour = _safeInt(parts[0], min: 0, max: 23);
      minute = _safeInt(parts[1], min: 0, max: 59);
    }
    final FixedExtentScrollController hourController =
        FixedExtentScrollController(initialItem: hour);
    final FixedExtentScrollController minuteController =
        FixedExtentScrollController(initialItem: minute);
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'HOUR',
                          textAlign: TextAlign.center,
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t4_13,
                            fontWeight: OmiFontWeight.medium,
                            color: secondTextColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'MIN',
                          textAlign: TextAlign.center,
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t4_13,
                            fontWeight: OmiFontWeight.medium,
                            color: secondTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: ListWheelScrollView.useDelegate(
                              controller: hourController,
                              itemExtent: 48,
                              perspective: 0.003,
                              diameterRatio: 1.8,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (int value) =>
                                  hour = value,
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 24,
                                builder: (BuildContext context, int index) {
                                  if (index < 0 || index > 23) return null;
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: OmiTextStyle.create(
                                        fontSize: OmiFontSize.t9_18,
                                        fontWeight: OmiFontWeight.medium,
                                        color: mainTextColor,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 16,
                            child: Center(
                              child: Text(
                                ':',
                                style: OmiTextStyle.create(
                                  fontSize: OmiFontSize.t9_18,
                                  fontWeight: OmiFontWeight.bold,
                                  color: mainTextColor,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListWheelScrollView.useDelegate(
                              controller: minuteController,
                              itemExtent: 48,
                              perspective: 0.003,
                              diameterRatio: 1.8,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (int value) =>
                                  minute = value,
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 60,
                                builder: (BuildContext context, int index) {
                                  if (index < 0 || index > 59) return null;
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: OmiTextStyle.create(
                                        fontSize: OmiFontSize.t9_18,
                                        fontWeight: OmiFontWeight.medium,
                                        color: mainTextColor,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                OmiButton(
                  text: 'Done',
                  textColor: Colors.white,
                  bgColor: blueTextColor,
                  width: double.infinity,
                  height: 44,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(
                      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onMarkAsDoneTap() async {
    if (_isActionInProgress) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final String tid = widget.params.todoId.trim();
    if (tid.isEmpty) {
      MPToastUtils.showMessage('Task ID cannot be empty.');
      return;
    }
    _syncDeadlineFromWhenAndTime();
    setState(() => _isMarkingDone = true);
    final bool ok = await MPTodoManager().updateTodoWithRequest(
      todoId: tid,
      title: widget.params.title,
      priority: MPTodoUtils.mapPriorityToApi(_priority),
      deadlineUnixSec: _deadlineUnixSec,
      isCompleted: true,
      note: _notesController.text,
    );
    MPHomeNotification.notifyHomeListRefresh();
    if (!mounted) {
      return;
    }
    if (ok) {
      widget.onMarkAsDone?.call();
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isMarkingDone = false);
    }
  }

  Future<void> _onSaveChangesTap() async {
    if (_isActionInProgress) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final String tid = widget.params.todoId.trim();
    if (tid.isEmpty) {
      MPToastUtils.showMessage('Task ID cannot be empty.');
      return;
    }
    _syncDeadlineFromWhenAndTime();
    setState(() => _isSavingChanges = true);
    final bool ok = await MPTodoManager().updateTodoWithRequest(
      todoId: tid,
      title: widget.params.title,
      priority: MPTodoUtils.mapPriorityToApi(_priority),
      deadlineUnixSec: _deadlineUnixSec,
      isCompleted: false,
      note: _notesController.text,
    );
    if (!mounted) {
      return;
    }
    if (ok) {
      MPHomeNotification.notifyHomeListRefresh();
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSavingChanges = false);
    }
  }

  Widget _buildMarkAsDoneButton() {
    final bool disabled = _isActionInProgress;
    return GestureDetector(
      onTap: disabled ? null : _onMarkAsDoneTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: greenDeepColor, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              OmiImageLoader.localImg(
                Assets.omiDetailCheck,
                width: 16,
                height: 16,
                color: greenDeepColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _isMarkingDone ? 'Saving…' : 'Mark as done',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t6_15,
                    fontWeight: OmiFontWeight.medium,
                    color: greenDeepColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(double safeBottom) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, safeBottom + 16),
      child: Row(
        children: <Widget>[
          Expanded(child: _buildMarkAsDoneButton()),
          const SizedBox(width: 10),
          Expanded(
            child: OmiButton(
              text: _isSavingChanges ? 'Saving…' : 'Save changes',
              textColor: Colors.white,
              bgColor: greenDeepColor,
              width: double.infinity,
              height: 50,
              borderRadius: BorderRadius.circular(12),
              onPressed: _isActionInProgress ? null : _onSaveChangesTap,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double keyboardInset = mediaQuery.viewInsets.bottom;
    final double safeBottom = mediaQuery.viewPadding.bottom;
    final double maxSheetHeight = mediaQuery.size.height - mediaQuery.padding.top - 8;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(context).pop(false);
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  height: 56,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: <Widget>[
                      InkWell(
                        onTap: () => Navigator.of(context).pop(false),
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: OmiImageLoader.localImg(
                            Assets.omiLeftBack,
                            width: 22,
                            height: 22,
                            color: blueTextColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Todo',
                          textAlign: TextAlign.center,
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t6_15,
                            fontWeight: OmiFontWeight.medium,
                            color: mainTextColor,
                          ),
                        ),
                      ),
                      InkWell(
                        onTapDown: (TapDownDetails details) async {
                          final OmiTodoMoreAction? action =
                              await showOmiTodoMoreMenu(
                                context,
                                details: details,
                              );
                          if (action == null || !context.mounted) return;
                          switch (action) {
                            case OmiTodoMoreAction.exportToCalendar:
                              // TODO: Export to calendar
                              break;
                            case OmiTodoMoreAction.shareTask:
                              // TODO: Share task
                              break;
                            case OmiTodoMoreAction.delete:
                              Navigator.of(context).pop(false);
                              WidgetsBinding.instance.addPostFrameCallback((
                                _,
                              ) async {
                                final bool ok = await showMPConfirmDeleteDialog(
                                  widget.rootContext,
                                );
                                if (!ok || !widget.rootContext.mounted) {
                                  return;
                                }
                                final String todoId =
                                    widget.params.todoId.trim();
                                if (todoId.isNotEmpty) {
                                  final bool deleted = await MPTodoManager()
                                      .deleteTodo(todoId);
                                  if (!deleted || !widget.rootContext.mounted) {
                                    return;
                                  }
                                  if (widget.onDelete == null) {
                                    MPHomeNotification.notifyTodoDeleted(
                                      MPHomeTodoDeletedPayload(todoId: todoId),
                                    );
                                  }
                                }
                                if (widget.onDelete != null) {
                                  await widget.onDelete!.call();
                                }
                              });
                              break;
                          }
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: OmiImageLoader.localImg(
                            Assets.omiMemoryDetialMore,
                            width: 20,
                            height: 20,
                            color: secondTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: lineColor.withValues(alpha: 0.8)),
                Flexible(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          widget.params.title,
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t6_15,
                            fontWeight: OmiFontWeight.medium,
                            color: mainTextColor,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (widget.params.shouldShowContextSection) ...<Widget>[
                          const _SectionTitle(text: 'CONTEXT'),
                          const SizedBox(height: 8),
                          _ContextCard(params: widget.params, rootContext: widget.rootContext),
                          const SizedBox(height: 14),
                        ],
                        const _SectionTitle(text: 'NOTES'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _notesController,
                            minLines: 3,
                            maxLines: 6,
                            textInputAction: TextInputAction.newline,
                            style: OmiTextStyle.create(
                              fontSize: OmiFontSize.t6_15,
                              fontWeight: OmiFontWeight.regular,
                              color: mainTextColor,
                              height: 1.35,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Add notes',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: OmiTextStyle.create(
                                fontSize: OmiFontSize.t6_15,
                                fontWeight: OmiFontWeight.regular,
                                color: secondTextColor,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _InfoField(
                                title: 'PRIORITY',
                                value: _priority,
                                onTap: () async {
                                  final String? v = await _showOptionSheet(
                                    options: MPTodoUtils.kTodoPriorities,
                                    selected: _priority,
                                  );
                                  if (v == null || !mounted) return;
                                  setState(() => _priority = v);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _InfoField(
                                title: 'WHEN',
                                value: _when,
                                onTap: _pickWhenForEdit,
                              ),
                            ),
                            if (_when != 'No deadline') ...<Widget>[
                              const SizedBox(width: 8),
                              Expanded(
                                child: _InfoField(
                                  title: 'TIME',
                                  value: _time.isEmpty ? '--:--' : _time,
                                  onTap: () async {
                                    final String? v = await _showTimeWheelSheet(
                                      selected: _time.isEmpty ? '09:00' : _time,
                                    );
                                    if (v == null || !mounted) return;
                                    setState(() {
                                      _time = v;
                                      _syncDeadlineFromWhenAndTime();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildBottomActions(safeBottom),
              ],
            ),
          ),
        ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: OmiTextStyle.create(
        fontSize: OmiFontSize.t3_12,
        fontWeight: OmiFontWeight.medium,
        color: secondTextColor.withValues(alpha: 0.9),
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.params, required this.rootContext});

  final OmiEditTodoPopupParams params;
  final BuildContext rootContext;

  /// 关闭编辑 Todo 弹层后，从 [rootContext] 打开 CONTEXT 对应详情（Memory 或 Insight）。
  void _openContextDetail(BuildContext sheetContext) {
    final int? mid = params.memoryId;
    final bool memoryOk = mid != null && mid > 0;
    final String insightTrim = (params.insightId ?? '').trim();
    final bool insightOk = insightTrim.isNotEmpty;
    if (!memoryOk && !insightOk) {
      return;
    }

    Navigator.of(sheetContext).pop(false);

    if (memoryOk) {
      final String memoryIdStr = '$mid';
      final String trimmedTitle = params.contextMemoryTitle.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!rootContext.mounted) {
          return;
        }
        MPMemoryDetailPageHelper.navigateToDetailPage(
          rootContext,
          memoryIdStr,
          params.memoryType ?? MPMemoryType.memoryFeed,
          title: trimmedTitle.isEmpty ? null : trimmedTitle,
        );
      });
      return;
    }

    final MPInsightListItem item = MPInsightListItem(
      id: insightTrim,
      type: params.insightType ?? MPInsightCardType.daily,
      periodLabel: '',
      title: params.contextMemoryTitle.trim().isEmpty ? 'Insight' : params.contextMemoryTitle.trim(),
      subtitle: '',
      content: params.contextMetaLine.trim(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!rootContext.mounted) {
        return;
      }
      switch (item.type) {
        case MPInsightCardType.daily:
          Navigator.of(rootContext).push(
            MaterialPageRoute<void>(builder: (_) => MPDailyInsightDetailPage(item: item)),
          );
          break;
        case MPInsightCardType.weekly:
          Navigator.of(rootContext).push(
            MaterialPageRoute<void>(builder: (_) => MPWeeklyInsightDetailPage(item: item)),
          );
          break;
        case MPInsightCardType.monthly:
          Navigator.of(rootContext).push(
            MaterialPageRoute<void>(builder: (_) => MPMonthlyInsightDetailPage(item: item)),
          );
          break;
        case MPInsightCardType.pattern:
          Navigator.of(rootContext).push(
            MaterialPageRoute<void>(builder: (_) => MPPatternInsightDetailPage(item: item)),
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int? mid = params.memoryId;
    final bool memoryOk = mid != null && mid > 0;
    final bool insightOk = (params.insightId ?? '').trim().isNotEmpty;
    final bool tappable = memoryOk || insightOk;

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          params.contextMemoryLabel,
          style: OmiTextStyle.create(
            fontSize: OmiFontSize.t4_13,
            fontWeight: OmiFontWeight.regular,
            color: secondTextColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                params.contextMemoryTitle,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t5_14,
                  fontWeight: OmiFontWeight.medium,
                  color: mainTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (tappable)
              OmiImageLoader.localImg(
                Assets.omiRightArrow,
                width: 14,
                height: 14,
                color: blueTextColor,
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          params.contextMetaLine,
          style: OmiTextStyle.create(
            fontSize: OmiFontSize.t4_13,
            fontWeight: OmiFontWeight.regular,
            color: secondTextColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    if (!tappable) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEAEAEE)),
        ),
        child: content,
      );
    }

    return Material(
      color: const Color(0xFFF5F5F7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEAEAEE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openContextDetail(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: content,
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.title, required this.value, this.onTap});

  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: OmiTextStyle.create(
            fontSize: OmiFontSize.t3_12,
            fontWeight: OmiFontWeight.medium,
            color: secondTextColor.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OmiTextStyle.create(
                      fontSize: OmiFontSize.t3_12,
                      fontWeight: OmiFontWeight.medium,
                      color: mainTextColor,
                    ),
                  ),
                ),
                OmiImageLoader.localImg(
                  Assets.omiArrowDown,
                  width: 14,
                  height: 14,
                  color: secondTextColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
