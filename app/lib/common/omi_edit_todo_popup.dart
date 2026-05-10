import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memo_pin/common/mp_todo_manager.dart';
import 'package:memo_pin/common/mp_todo_utils.dart';
import 'package:memo_pin/common/omi_button.dart';
import 'package:memo_pin/common/omi_todo_more_sheet.dart';
import 'package:memo_pin/common/mp_confirm_delete_dialog.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../generated/assets.dart';
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
  });

  final String title;
  final String contextMemoryLabel;
  final String contextMemoryTitle;
  final String contextMetaLine;

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

  /// 截止时间 Unix（秒或毫秒，与 [MPMemoryCreatedTodoLineData.deadlineLabel] 一致）；无截止为 `null`。
  final int? deadlineUnixSec;
}

Future<void> showOmiEditTodoPopup(
  BuildContext context, {
  required OmiEditTodoPopupParams params,
  VoidCallback? onMarkAsDone,
  Future<bool> Function()? onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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

  static int? _normalizeDeadlineSec(int? raw) {
    if (raw == null) {
      return null;
    }
    return raw > 10000000000 ? raw ~/ 1000 : raw;
  }

  static DateTime _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  TimeOfDay _parseTimeOfDayFromEdit(
    String raw, {
    int? fallbackFromSec,
  }) {
    final String t = raw.trim();
    if (t.isEmpty || t.startsWith('--')) {
      if (fallbackFromSec != null) {
        final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
          fallbackFromSec * 1000,
        );
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
    final DateTime now = DateTime.now();
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
        day = DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {
        try {
          final DateTime parsed =
              DateFormat('yyyy年M月d日').parse(_when, false);
          day = DateTime(parsed.year, parsed.month, parsed.day);
        } catch (_) {
          return;
        }
      }
    }
    final DateTime combined = DateTime(
      day.year,
      day.month,
      day.day,
      tod.hour,
      tod.minute,
    );
    _deadlineUnixSec = combined.millisecondsSinceEpoch ~/ 1000;
  }

  void _syncInitialWhenFromParams() {
    final String w = _when;
    if (w == 'No deadline' || w == 'Today' || w == 'Tomorrow') {
      _pickedCalendarDate = null;
      return;
    }
    if (_deadlineUnixSec != null) {
      final DateTime dt =
          DateTime.fromMillisecondsSinceEpoch(_deadlineUnixSec! * 1000);
      final DateTime d = DateTime(dt.year, dt.month, dt.day);
      final DateTime today = _dateOnly(DateTime.now());
      if (d == today) {
        _when = 'Today';
        _pickedCalendarDate = null;
      } else if (d == today.add(const Duration(days: 1))) {
        _when = 'Tomorrow';
        _pickedCalendarDate = null;
      } else {
        _pickedCalendarDate = d;
        _when = DateFormat('MMM d, y').format(d);
      }
      return;
    }
    try {
      final DateTime parsed = DateFormat('yyyy年M月d日').parse(w, false);
      _pickedCalendarDate =
          DateTime(parsed.year, parsed.month, parsed.day);
      _when = DateFormat('MMM d, y').format(_pickedCalendarDate!);
    } catch (_) {
      _pickedCalendarDate = null;
    }
  }

  Future<void> _pickDateOnlyFlow() async {
    final DateTime now = DateTime.now();
    final DateTime today = _dateOnly(now);
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _pickedCalendarDate ?? today,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 5),
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
    _priority =
        MPTodoUtils.normalizePriorityPickerLabel(widget.params.priorityLabel);
    _when = widget.params.whenLabel;
    _time = widget.params.timeLabel;
    if (_time.startsWith('--')) {
      _time = '';
    }
    _deadlineUnixSec = _normalizeDeadlineSec(widget.params.deadlineUnixSec);
    _notesController = TextEditingController(text: widget.params.notes);
    _syncInitialWhenFromParams();
    _syncDeadlineFromWhenAndTime();
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
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
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
      child: Align(
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
                        onTap: () => Navigator.of(context).pop(),
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
                          if (action == null) return;
                          switch (action) {
                            case OmiTodoMoreAction.exportToCalendar:
                              // TODO: Export to calendar
                              break;
                            case OmiTodoMoreAction.shareTask:
                              // TODO: Share task
                              break;
                            case OmiTodoMoreAction.delete:
                              Navigator.of(context).pop();
                              WidgetsBinding.instance.addPostFrameCallback((
                                _,
                              ) async {
                                final bool ok = await showMPConfirmDeleteDialog(
                                  widget.rootContext,
                                );
                                if (!ok) return;
                                final String todoId =
                                    widget.params.todoId.trim();
                                if (todoId.isNotEmpty) {
                                  final bool deleted = await MPTodoManager()
                                      .deleteTodo(todoId);
                                  if (!deleted) return;
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
                      padding: EdgeInsets.fromLTRB(16, 16, 16, safeBottom + 16),
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
                          _ContextCard(params: widget.params),
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
                        const SizedBox(height: 18),
                        OmiButton(
                          text: _isMarkingDone ? 'Saving…' : 'Mark as done',
                          icon: OmiImageLoader.localImg(
                            Assets.omiDetailCheck,
                            width: 16,
                            height: 16,
                            color: Colors.white,
                          ),
                          textColor: Colors.white,
                          bgColor: greenDeepColor,
                          width: double.infinity,
                          height: 50,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: _isMarkingDone
                              ? null
                              : () async {
                                  final String tid = widget.params.todoId.trim();
                                  if (tid.isEmpty) {
                                    MPToastUtils.showMessage('Task ID cannot be empty.');
                                    return;
                                  }
                                  _syncDeadlineFromWhenAndTime();
                                  setState(() => _isMarkingDone = true);
                                  final bool ok =
                                      await MPTodoManager().updateTodoWithRequest(
                                    todoId: tid,
                                    title: widget.params.title,
                                    priority: MPTodoUtils.mapPriorityToApi(_priority),
                                    deadlineUnixSec: _deadlineUnixSec,
                                    isCompleted: true,
                                  );
                                  MPHomeNotification.notifyHomeListRefresh();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (ok) {
                                    widget.onMarkAsDone?.call();
                                    Navigator.of(context).pop();
                                  } else {
                                    setState(() => _isMarkingDone = false);
                                  }
                                },
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
  const _ContextCard({required this.params});

  final OmiEditTodoPopupParams params;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            params.contextMemoryLabel,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t4_13,
              fontWeight: OmiFontWeight.regular,
              color: secondTextColor,
            ),
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
                ),
              ),
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
          ),
        ],
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
