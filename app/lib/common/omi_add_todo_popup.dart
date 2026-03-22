import 'package:flutter/material.dart';
import 'package:omi/common/omi_button.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_image_loader.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../generated/assets.dart';

/// [showMPAddTodoPopup] 保存时返回的数据
class MPAddTodoPopupResult {
  const MPAddTodoPopupResult({
    required this.title,
    required this.notes,
    required this.priority,
    required this.when,
    required this.time,
  });

  final String title;

  final String notes;

  final String priority;

  final String when;

  /// `HH:mm`，仅当 [when] 非 `No deadline` 时有意义；否则为空字符串
  final String time;
}

/// 打开弹窗时的可配置项（用于 **数据回显**：标题、备注、优先级、截止时间、Context 文案等）
class MPAddTodoPopupParams {
  const MPAddTodoPopupParams({
    this.initialTitle = 'Schedule authentication service testing session',
    this.contextMemoryLabel = 'From memory:',
    this.contextMemoryTitle = 'Team standup discussion on API migration',
    this.contextMetaLine = 'Today, 10:30 AM · 12m34s · Summary',
    this.initialNotes = '',
    this.initialPriority = 'Normal',
    this.initialWhen = 'No deadline',
    this.initialTime = '09:00',
  });

  final String initialTitle;

  final String contextMemoryLabel;

  final String contextMemoryTitle;

  final String contextMetaLine;

  final String initialNotes;

  final String initialPriority;

  final String initialWhen;

  /// 与 [initialWhen] 同时回显；`No deadline` 时忽略
  final String initialTime;
}

/// 自底部弹出「New Todo」：**左右全宽**，**最高高度为屏高 0.8**；[MPAddTodoPopupParams] 做数据回显；点击空白或滑动可收起键盘。
Future<MPAddTodoPopupResult?> showMPAddTodoPopup(
  BuildContext context, {
  MPAddTodoPopupParams params = const MPAddTodoPopupParams(),
  VoidCallback? onContextTap,
}) {
  return showModalBottomSheet<MPAddTodoPopupResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (BuildContext sheetContext) {
      return _MPAddTodoPopupSheet(
        params: params,
        onContextTap: onContextTap,
      );
    },
  );
}

class _MPAddTodoPopupSheet extends StatefulWidget {
  const _MPAddTodoPopupSheet({
    required this.params,
    this.onContextTap,
  });

  final MPAddTodoPopupParams params;

  final VoidCallback? onContextTap;

  @override
  State<_MPAddTodoPopupSheet> createState() => _MPAddTodoPopupSheetState();
}

class _MPAddTodoPopupSheetState extends State<_MPAddTodoPopupSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late String _priority;
  late String _when;
  late String _time;

  static const List<String> _priorities = <String>[
    'Low',
    'Normal',
    'High',
  ];

  static const List<String> _whenOptions = <String>[
    'No deadline',
    'Today',
    'Tomorrow',
    'This week',
  ];

  static const Color _kFieldBg = Color(0xFFF2F2F7);

  /// 全天每 30 分钟一档：`00:00` … `23:30`
  static final List<String> _timeSlots30m = _buildTimeSlots30m();

  static List<String> _buildTimeSlots30m() {
    final List<String> out = <String>[];
    for (int h = 0; h < 24; h++) {
      for (final int m in <int>[0, 30]) {
        out.add(
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
        );
      }
    }
    return out;
  }

  bool get _showTimeRow => _when != 'No deadline';

  @override
  void initState() {
    super.initState();
    final MPAddTodoPopupParams p = widget.params;
    _titleController = TextEditingController(text: p.initialTitle);
    _notesController = TextEditingController(text: p.initialNotes);
    _priority = p.initialPriority;
    _when = p.initialWhen;
    _time = p.initialWhen == 'No deadline'
        ? ''
        : (p.initialTime.isNotEmpty ? p.initialTime : '09:00');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _unfocusKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _pickFromList({
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) async {
    _unfocusKeyboard();
    final String? v = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  title,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t5_14,
                    fontWeight: OmiFontWeight.medium,
                    color: mainTextColor,
                  ),
                ),
              ),
              ...options.map(
                (String o) => ListTile(
                  title: Text(o),
                  onTap: () => Navigator.of(ctx).pop(o),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (v != null) {
      setState(() => onSelected(v));
    }
  }

  Future<void> _pickWhen() async {
    _unfocusKeyboard();
    final String? v = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'When',
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t5_14,
                    fontWeight: OmiFontWeight.medium,
                    color: mainTextColor,
                  ),
                ),
              ),
              ..._whenOptions.map(
                (String o) => ListTile(
                  title: Text(o),
                  onTap: () => Navigator.of(ctx).pop(o),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (v == null || !mounted) return;
    setState(() {
      _when = v;
      if (v == 'No deadline') {
        _time = '';
      } else {
        if (_time.isEmpty) {
          _time = widget.params.initialTime.isNotEmpty
              ? widget.params.initialTime
              : '09:00';
        }
      }
    });
  }

  Future<void> _pickTimeSlot() async {
    _unfocusKeyboard();
    final String? v = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        final double maxListH = MediaQuery.sizeOf(ctx).height * 0.55;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Time',
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t5_14,
                    fontWeight: OmiFontWeight.medium,
                    color: mainTextColor,
                  ),
                ),
              ),
              SizedBox(
                height: maxListH,
                child: ListView.builder(
                  itemCount: _timeSlots30m.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String slot = _timeSlots30m[index];
                    return ListTile(
                      title: Text(slot),
                      onTap: () => Navigator.of(ctx).pop(slot),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (v != null && mounted) {
      setState(() => _time = v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MPAddTodoPopupParams p = widget.params;
    final double screenH = MediaQuery.sizeOf(context).height;
    final double maxSheetH = screenH * 0.8;
    final double kb = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Material(
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            height: maxSheetH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _unfocusKeyboard,
                  onVerticalDragStart: (_) => _unfocusKeyboard(),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildHeader(context),
                Divider(
                  height: 1,
                  color: lineColor,
                ),
                SizedBox(height: 12,),
                Expanded(
                  child: GestureDetector(
                    onTap: _unfocusKeyboard,
                    behavior: HitTestBehavior.translucent,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification n) {
                        if (n is ScrollStartNotification ||
                            n is OverscrollNotification) {
                          _unfocusKeyboard();
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            TextField(
                              controller: _titleController,
                              maxLines: null,
                              style: OmiTextStyle.create(
                                fontSize: OmiFontSize.t8_17,
                                fontWeight: OmiFontWeight.medium,
                                color: mainTextColor,
                                height: 1.35,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _sectionLabel('CONTEXT'),
                            const SizedBox(height: 8),
                            _buildContextCard(p),
                            const SizedBox(height: 20),
                            _sectionLabel('NOTES'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _notesController,
                              minLines: 4,
                              maxLines: 8,
                              style: OmiTextStyle.create(
                                fontSize: OmiFontSize.t4_13,
                                fontWeight: OmiFontWeight.regular,
                                color: mainTextColor,
                                height: 1.4,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add notes...',
                                hintStyle: OmiTextStyle.create(
                                  fontSize: OmiFontSize.t4_13,
                                  color: secondTextColor.withValues(alpha: 0.7),
                                ),
                                filled: true,
                                fillColor: _kFieldBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _sectionLabel('PRIORITY'),
                            const SizedBox(height: 8),
                            _dropdownRow(
                              value: _priority,
                              onTap: () => _pickFromList(
                                title: 'Priority',
                                options: _priorities,
                                onSelected: (String v) => _priority = v,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _sectionLabel('WHEN'),
                            const SizedBox(height: 8),
                            _dropdownRow(
                              value: _when,
                              onTap: _pickWhen,
                            ),
                            if (_showTimeRow) ...<Widget>[
                              const SizedBox(height: 16),
                              _sectionLabel('TIME'),
                              const SizedBox(height: 8),
                              _dropdownRow(
                                value: _time.isNotEmpty ? _time : '09:00',
                                onTap: _pickTimeSlot,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.paddingOf(context).bottom),
                  child: OmiButton(
                    text: 'Save Todo',
                    width: double.infinity,
                    height: 50,
                    bgColor: blueTextColor,
                    textColor: Colors.white,
                    textFontSize: OmiFontSize.t5_14,
                    textFontWeight: OmiFontWeight.medium,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () {
                      Navigator.of(context).pop(
                        MPAddTodoPopupResult(
                          title: _titleController.text.trim(),
                          notes: _notesController.text.trim(),
                          priority: _priority,
                          when: _when,
                          time: _when == 'No deadline' ? '' : _time,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: <Widget>[
          Expanded(child:
          Row(
            children: [
              GestureDetector(
                  onTap: () {
                    _unfocusKeyboard();
                    Navigator.of(context).pop();
                  },
                  child: OmiImageLoader.localImg(Assets.omiLeftBack, width: 24,
                      height: 24,
                      color: blueTextColor)),
              Flexible(
                child: Text(
                  'New Todo',
                  textAlign: TextAlign.center,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t6_15,
                    fontWeight: OmiFontWeight.medium,
                    color: blueTextColor,
                  ),
                ),
              ),
            ],
          )),
          GestureDetector(
              onTap: () {
                _unfocusKeyboard();
                Navigator.of(context).pop();
              },
              child: Padding(padding: EdgeInsets.all(8),
                  child: OmiImageLoader.localImg(
                      Assets.omiClose, width: 20,
                      height: 20,
                      color: secondTextColor
                  )
              )
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: OmiTextStyle.create(
        fontSize: OmiFontSize.t2_11,
        fontWeight: OmiFontWeight.medium,
        color: secondTextColor,
        letterSpacing: 0.6,
        height: 1.2,
      ),
    );
  }

  Widget _buildContextCard(MPAddTodoPopupParams p) {
    return Material(
      color: _kFieldBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: widget.onContextTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      p.contextMemoryLabel,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t3_12,
                        fontWeight: OmiFontWeight.regular,
                        color: secondTextColor,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.contextMemoryTitle,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.medium,
                        color: mainTextColor,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.contextMetaLine,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t3_12,
                        fontWeight: OmiFontWeight.regular,
                        color: secondTextColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              OmiImageLoader.localImg(Assets.omiRightArrow, width: 18, height: 18, color: blueTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownRow({
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _kFieldBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  value,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t4_13,
                    fontWeight: OmiFontWeight.regular,
                    color: mainTextColor,
                  ),
                ),
              ),
              OmiImageLoader.localImg(Assets.omiArrowDown, width: 18, height: 18, color: secondTextColor),

            ],
          ),
        ),
      ),
    );
  }
}
