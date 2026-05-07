import 'package:flutter/material.dart';
import 'package:memo_pin/common/mp_date_utils.dart';
import 'package:memo_pin/common/mp_todo_priority_utils.dart';
import 'package:memo_pin/common/omi_edit_todo_popup.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../omi_memory_detail_cubit.dart';
import 'mp_memory_todos_created_models.dart';

export 'mp_memory_todos_created_models.dart';

/// 左侧深绿竖条 + 白底圆角，展示已生成的 Todo 列表
class MPMemoryTodosCreatedCard extends StatelessWidget {
  const MPMemoryTodosCreatedCard({
    super.key,
    required this.data,
    this.feedBlockIndex = 0,
  });

  final MPMemoryTodosCreatedCardData data;

  /// 对应 [MPMemoryDetailCardData.feedBlocks] 下标，用于删除回调。
  final int feedBlockIndex;

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
                      title: data.items[i].title ?? '',
                      notes:
                          'Need to confirm their availability for next sprint, focus on timeline alignment.',
                      priorityLabel: MPTodoPriorityUtils.labelForKind(
                        data.items[i].priority ?? MPMemoryTodoPriorityKind.normal,
                      ),
                      whenLabel: MPDateUtils.formatWhenLabelFromDeadline(
                        data.items[i].deadlineLabel,
                      ),
                      timeLabel: MPDateUtils.formatTimeLabelFromDeadline(
                        data.items[i].deadlineLabel,
                      ),
                      todoId: data.items[i].id ?? '',
                      deadlineUnixSec: data.items[i].deadlineLabel,
                    ),
                    onDelete: () {
                      final String todoId = (data.items[i].id ?? '').trim();
                      if (todoId.isEmpty) {
                        return Future<bool>.value(false);
                      }
                      return context.read<OmiMemoryDetailCubit>().deleteCreatedTodoById(
                            feedBlockIndex,
                            todoId: todoId,
                            skipApi: true,
                          );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MPCreatedTodoRow extends StatelessWidget {
  const _MPCreatedTodoRow({required this.item, this.onTap});

  final MPMemoryCreatedTodoLineData item;
  final VoidCallback? onTap;

  Color _priorityColor() {
    switch (item.priority ?? MPMemoryTodoPriorityKind.normal) {
      case MPMemoryTodoPriorityKind.high:
        return redColor;
      case MPMemoryTodoPriorityKind.medium:
        return secondTextColor;
      case MPMemoryTodoPriorityKind.normal:
        return orangeTextColor;
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
              item.title ?? '',
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
                  MPTodoPriorityUtils.labelForKind(item.priority ?? MPMemoryTodoPriorityKind.normal),
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
                  MPDateUtils.deadlineLineText(item.deadlineLabel),
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
