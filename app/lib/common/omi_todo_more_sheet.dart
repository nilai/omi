import 'package:flutter/material.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

/// Todo 编辑页「更多」弹窗的操作类型。
enum OmiTodoMoreAction { exportToCalendar, shareTask, delete }

/// 从「更多」按钮旁边弹出菜单（popover），返回所选操作；点空白关闭返回 `null`。
Future<OmiTodoMoreAction?> showOmiTodoMoreMenu(
  BuildContext context, {
  required TapDownDetails details,
}) {
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;
  final Offset p = details.globalPosition + const Offset(0, 30);
  final RelativeRect position = RelativeRect.fromRect(
    Rect.fromPoints(p, p),
    Offset.zero & overlay.size,
  );

  return showMenu<OmiTodoMoreAction>(
    context: context,
    position: position,
    color: Colors.white,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    items: <PopupMenuEntry<OmiTodoMoreAction>>[
      PopupMenuItem<OmiTodoMoreAction>(
        value: OmiTodoMoreAction.exportToCalendar,
        child: _MenuRow(
          icon: Icons.calendar_today_rounded,
          iconColor: secondTextColor,
          title: 'Export to calendar',
        ),
      ),
      const PopupMenuDivider(height: 1),
      PopupMenuItem<OmiTodoMoreAction>(
        value: OmiTodoMoreAction.shareTask,
        child: _MenuRow(
          icon: Icons.share_outlined,
          iconColor: secondTextColor,
          title: 'Share task',
        ),
      ),
      const PopupMenuDivider(height: 1),
      PopupMenuItem<OmiTodoMoreAction>(
        value: OmiTodoMoreAction.delete,
        child: _MenuRow(
          icon: Icons.delete_outline_rounded,
          iconColor: redColor,
          title: 'Delete',
          titleColor: redColor,
        ),
      ),
    ],
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Text(
          title,
          style: OmiTextStyle.create(
            fontSize: OmiFontSize.t6_15,
            fontWeight: OmiFontWeight.medium,
            color: titleColor ?? mainTextColor,
          ),
        ),
      ],
    );
  }
}
