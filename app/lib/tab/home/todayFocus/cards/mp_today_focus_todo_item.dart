import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

/// 列表行视觉：Today / Upcoming / Overdue / Completed 通过文案色与勾选样式区分，勾选态由 [isChecked] 决定。
enum MPTodayFocusTodoItemTone {
  today,
  upcoming,
  overdue,
  completed,
}

/// 圆角方框勾选 + 标题 + 右侧时间（浅灰底列表行）
class MPTodayFocusTodoItem extends StatelessWidget {
  const MPTodayFocusTodoItem({
    super.key,
    required this.title,
    required this.timeLabel,
    this.isChecked = false,
    this.onChanged,
    this.onTap,
    this.tone = MPTodayFocusTodoItemTone.today,
    this.highlighted = false,
  });

  final String title;
  final String timeLabel;
  final bool isChecked;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;
  final MPTodayFocusTodoItemTone tone;

  /// Overdue 下可选：浅灰高亮条（选中 / 按压态）
  final bool highlighted;

  static const Color _kTodayAccent = Color(0xFF1B4332);
  static const Color _kUpcomingCheckBorder = Color(0xFF9CA3AF);
  static const Color _kUpcomingCheckFill = Color(0xFF6B7280);
  static const Color _kRowBg = Color(0xFFF0F0F0);
  static const Color _kOverdueHighlightBg = Color(0xFFFFFFFF);
  static const Color _kTimeColor = Color(0xFF999999);

  Color get _contentBg {
    if (tone == MPTodayFocusTodoItemTone.overdue && highlighted) {
      return _kOverdueHighlightBg;
    }
    return _kRowBg;
  }

  TextStyle _titleStyle() {
    switch (tone) {
      case MPTodayFocusTodoItemTone.today:
        return OmiTextStyle.create(
          fontSize: OmiFontSize.t5_14,
          fontWeight: OmiFontWeight.regular,
          color: mainTextColor,
          height: 1.35,
        );
      case MPTodayFocusTodoItemTone.upcoming:
        return OmiTextStyle.create(
          fontSize: OmiFontSize.t3_12,
          fontWeight: OmiFontWeight.regular,
          color: mainTextColor,
          height: 1.35,
        );
      case MPTodayFocusTodoItemTone.overdue:
        return OmiTextStyle.create(
          fontSize: OmiFontSize.t3_12,
          fontWeight: OmiFontWeight.regular,
          color: secondTextColor,
          height: 1.35,
        );
      case MPTodayFocusTodoItemTone.completed:
        return OmiTextStyle.create(
          fontSize: OmiFontSize.t3_12,
          fontWeight: OmiFontWeight.regular,
          color: secondTextColor.withValues(alpha: 0.62),
          height: 1.35,
        );
    }
  }

  TextStyle? _timeStyle() {
    switch (tone) {
      case MPTodayFocusTodoItemTone.today:
        return OmiTextStyle.create(
          fontSize: OmiFontSize.t5_14,
          fontWeight: OmiFontWeight.regular,
          color: _kTimeColor,
        );
      case MPTodayFocusTodoItemTone.overdue:
      case MPTodayFocusTodoItemTone.upcoming:
        return OmiTextStyle.create(
          fontSize: OmiFontSize.t3_12,
          fontWeight: OmiFontWeight.regular,
          color: secondTextColor.withValues(alpha: 0.72),
        );
      case MPTodayFocusTodoItemTone.completed:
        return OmiTextStyle.create(
          fontSize: OmiFontSize.t3_12,
          fontWeight: OmiFontWeight.regular,
          color: secondTextColor.withValues(alpha: 0.4),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showTime = timeLabel.trim().isNotEmpty;

    final Widget body = Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: onChanged == null
                ? null
                : () {
                    onChanged!.call(!isChecked);
                  },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _MPTodoCheckSquare(
                checked: isChecked,
                enabled: onChanged != null,
                tone: tone,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: _titleStyle(),
            ),
          ),
          if (showTime) ...<Widget>[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                timeLabel,
                style: _timeStyle(),
              ),
            ),
          ],
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: onTap != null
          ? Material(
              color: _contentBg,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: body,
                ),
              ),
            )
          : ColoredBox(
              color: _contentBg,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: body,
              ),
            ),
    );
  }
}

class _MPTodoCheckSquare extends StatelessWidget {
  const _MPTodoCheckSquare({
    required this.checked,
    required this.enabled,
    required this.tone,
  });

  final bool checked;
  final bool enabled;
  final MPTodayFocusTodoItemTone tone;

  @override
  Widget build(BuildContext context) {
    final bool isToday = tone == MPTodayFocusTodoItemTone.today;
    final Color accent = MPTodayFocusTodoItem._kTodayAccent;
    final Color upcomingBorder = MPTodayFocusTodoItem._kUpcomingCheckBorder;
    final Color upcomingFill = MPTodayFocusTodoItem._kUpcomingCheckFill;

    final Color borderColor = checked
        ? (isToday ? accent : upcomingFill)
        : (isToday
            ? accent.withValues(alpha: enabled ? 1.0 : 0.35)
            : upcomingBorder.withValues(alpha: enabled ? 1.0 : 0.4));

    final Color? fillColor =
         null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fillColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      child: checked
          ? Icon(
              Icons.check_rounded,
              size: 12,
              color: upcomingFill,
            )
          : null,
    );
  }
}
