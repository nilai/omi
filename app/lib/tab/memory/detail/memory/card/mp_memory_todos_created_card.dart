import 'package:flutter/material.dart';
import 'package:omi/common/omi_edit_todo_popup.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_image_loader.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';

/// 已创建 Todo 条目的优先级（决定文案与颜色）
enum MPMemoryTodoPriorityKind {
  /// 红色：High priority
  high,

  /// 灰色：Medium
  medium,

  /// 橙色：Normal
  normal,
}

/// 单条已创建 Todo（用于「TODOS CREATED」列表）
class MPMemoryCreatedTodoLineData {
  const MPMemoryCreatedTodoLineData({
    required this.title,
    required this.priority,
    required this.deadlineLabel,
  });

  final String title;
  final MPMemoryTodoPriorityKind priority;

  /// 如 `Tomorrow`、`No deadline`
  final String deadlineLabel;
}

/// 「TODOS CREATED」整卡数据
class MPMemoryTodosCreatedCardData {
  const MPMemoryTodosCreatedCardData({
    this.headerTimeLabel = 'Just now',
    required this.items,
  });

  /// 头部右侧时间，如 `Just now`
  final String headerTimeLabel;

  final List<MPMemoryCreatedTodoLineData> items;
}

/// 左侧深绿竖条 + 白底圆角，展示已生成的 Todo 列表
class MPMemoryTodosCreatedCard extends StatelessWidget {
  const MPMemoryTodosCreatedCard({super.key, required this.data});

  final MPMemoryTodosCreatedCardData data;

  static const Color _kLeftStripe = greenDeepColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: _kLeftStripe, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: OmiImageLoader.localImg(
                      Assets.omiDetailCheck,
                      width: 12,
                      height: 12,
                      color: greenDeepColor,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'TODOS CREATED',
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t3_12,
                        fontWeight: OmiFontWeight.bold,
                        color: secondTextColor,
                        height: 1.2,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                Text(
                  data.headerTimeLabel,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t2_11,
                    fontWeight: OmiFontWeight.regular,
                    color: secondTextColor.withValues(alpha: 0.85),
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (int i = 0; i < data.items.length; i++) ...<Widget>[
              if (i > 0) ...<Widget>[
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: lineColor.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 12),
              ],
              _MPCreatedTodoRow(
                item: data.items[i],
                onTap: () {
                  showOmiEditTodoPopup(
                    context,
                    params: OmiEditTodoPopupParams(
                      title: data.items[i].title,
                      notes:
                          'Need to confirm their availability for next sprint, focus on timeline alignment.',
                      priorityLabel: _priorityLabelByKind(
                        data.items[i].priority,
                      ),
                      whenLabel: data.items[i].deadlineLabel,
                      timeLabel: '01:02',
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _priorityLabelByKind(MPMemoryTodoPriorityKind kind) {
    switch (kind) {
      case MPMemoryTodoPriorityKind.high:
        return 'High priority';
      case MPMemoryTodoPriorityKind.medium:
        return 'Medium';
      case MPMemoryTodoPriorityKind.normal:
        return 'Normal';
    }
  }
}

class _MPCreatedTodoRow extends StatelessWidget {
  const _MPCreatedTodoRow({required this.item, this.onTap});

  final MPMemoryCreatedTodoLineData item;
  final VoidCallback? onTap;

  Color _priorityColor() {
    switch (item.priority) {
      case MPMemoryTodoPriorityKind.high:
        return redColor;
      case MPMemoryTodoPriorityKind.medium:
        return secondTextColor;
      case MPMemoryTodoPriorityKind.normal:
        return orangeTextColor;
    }
  }

  String _priorityLabel() {
    switch (item.priority) {
      case MPMemoryTodoPriorityKind.high:
        return 'High priority';
      case MPMemoryTodoPriorityKind.medium:
        return 'Medium';
      case MPMemoryTodoPriorityKind.normal:
        return 'Normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              item.title,
              style: OmiTextStyle.create(
                fontSize: OmiFontSize.t4_13,
                fontWeight: OmiFontWeight.bold,
                color: mainTextColor,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 0,
              runSpacing: 4,
              children: <Widget>[
                Text(
                  _priorityLabel(),
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t3_12,
                    fontWeight: OmiFontWeight.regular,
                    color: _priorityColor(),
                    height: 1.3,
                  ),
                ),
                Text(
                  ' • ',
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t3_12,
                    fontWeight: OmiFontWeight.regular,
                    color: secondTextColor,
                    height: 1.3,
                  ),
                ),
                Text(
                  item.deadlineLabel,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t3_12,
                    fontWeight: OmiFontWeight.regular,
                    color: secondTextColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
