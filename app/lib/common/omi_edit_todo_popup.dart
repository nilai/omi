import 'package:flutter/material.dart';
import 'package:omi/common/omi_button.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_image_loader.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../generated/assets.dart';

class OmiEditTodoPopupParams {
  const OmiEditTodoPopupParams({
    required this.title,
    this.contextMemoryLabel = 'From memory:',
    this.contextMemoryTitle = 'Team standup discussion on API migration',
    this.contextMetaLine = 'Today, 10:30 AM · 12m34s · Summary',
    this.notes = '',
    this.priorityLabel = 'Normal',
    this.whenLabel = 'No deadline',
    this.timeLabel = '09:00',
  });

  final String title;
  final String contextMemoryLabel;
  final String contextMemoryTitle;
  final String contextMetaLine;
  final String notes;
  final String priorityLabel;
  final String whenLabel;
  final String timeLabel;
}

Future<void> showOmiEditTodoPopup(
  BuildContext context, {
  required OmiEditTodoPopupParams params,
  VoidCallback? onMarkAsDone,
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
      return _OmiEditTodoPopupSheet(params: params, onMarkAsDone: onMarkAsDone);
    },
  );
}

class _OmiEditTodoPopupSheet extends StatefulWidget {
  const _OmiEditTodoPopupSheet({required this.params, this.onMarkAsDone});

  final OmiEditTodoPopupParams params;
  final VoidCallback? onMarkAsDone;

  @override
  State<_OmiEditTodoPopupSheet> createState() => _OmiEditTodoPopupSheetState();
}

class _OmiEditTodoPopupSheetState extends State<_OmiEditTodoPopupSheet> {
  static const List<String> _priorities = <String>[
    'Low',
    'Normal',
    'High priority',
  ];
  static const List<String> _whenOptions = <String>[
    'No deadline',
    'Today',
    'Tomorrow',
    'This week',
  ];
  late String _priority;
  late String _when;
  late String _time;

  @override
  void initState() {
    super.initState();
    _priority = widget.params.priorityLabel;
    _when = widget.params.whenLabel;
    _time = widget.params.timeLabel;
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
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      color: Colors.white,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset + 16),
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
                      onTap: () {},
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                    const _SectionTitle(text: 'CONTEXT'),
                    const SizedBox(height: 8),
                    _ContextCard(params: widget.params),
                    const SizedBox(height: 14),
                    const _SectionTitle(text: 'NOTES'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.params.notes,
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t6_15,
                          fontWeight: OmiFontWeight.regular,
                          color: mainTextColor,
                          height: 1.35,
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
                                options: _priorities,
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
                            onTap: () async {
                              final String? v = await _showOptionSheet(
                                options: _whenOptions,
                                selected: _when,
                              );
                              if (v == null || !mounted) return;
                              setState(() {
                                _when = v;
                                if (v == 'No deadline') {
                                  _time = '';
                                } else if (_time.isEmpty) {
                                  _time = '09:00';
                                }
                              });
                            },
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
                                setState(() => _time = v);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    OmiButton(
                      text: 'Mark as done',
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
                      onPressed: () {
                        widget.onMarkAsDone?.call();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
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
