// AI-generated START - Memo/Todo 切换卡片组件
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Memo/Todo 切换类型
enum MemoTodoType {
  memo,
  todo,
}

/// Memo/Todo 切换卡片组件
/// 显示两个切换按钮：Memo 和 Todo
class MemoTodoSwitchCard extends StatelessWidget {
  // AI-generated START - 当前选中的类型
  final MemoTodoType selectedType;
  // AI-generated END - selectedType

  // AI-generated START - 切换回调
  final Function(MemoTodoType type)? onTypeChanged;
  // AI-generated END - onTypeChanged

  const MemoTodoSwitchCard({
    super.key,
    required this.selectedType,
    this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Container(
        height: 44.0,
        padding: const EdgeInsets.only(left: 4.0, right: 4.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(22.0),
        ),
        child: Row(
          children: [
            // AI-generated START - Memo 按钮
            Expanded(
              child: _buildSwitchButton(
                label: 'Memo',
                isSelected: selectedType == MemoTodoType.memo,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTypeChanged?.call(MemoTodoType.memo);
                },
              ),
            ),
            // AI-generated END - Memo 按钮

            // AI-generated START - Todo 按钮
            Expanded(
              child: _buildSwitchButton(
                label: 'Todo',
                isSelected: selectedType == MemoTodoType.todo,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTypeChanged?.call(MemoTodoType.todo);
                },
              ),
            ),
            // AI-generated END - Todo 按钮
          ],
        ),
      ),
    );
  }

  // AI-generated START - 构建切换按钮
  Widget _buildSwitchButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36.0,
        padding: const EdgeInsets.only(left: 12.0, right: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF2563EB) // 蓝色
                  : const Color(0xFF4B5563), // 深灰色
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
  // AI-generated END - _buildSwitchButton
}
// AI-generated END - memo_todo_switch_card.dart
