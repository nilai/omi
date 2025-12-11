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
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12.0),
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
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
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
                  ? const Color(0xFF007AFF) // 蓝色
                  : Colors.grey.shade700, // 深灰色
              fontSize: 16.0,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
  // AI-generated END - _buildSwitchButton
}
// AI-generated END - memo_todo_switch_card.dart
