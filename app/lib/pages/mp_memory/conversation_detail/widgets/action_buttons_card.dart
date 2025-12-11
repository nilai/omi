// AI-generated START - 操作按钮卡片组件，显示多个操作按钮
import 'package:flutter/material.dart';

/// 操作按钮数据模型
class ActionButton {
  // AI-generated START - 构造函数
  const ActionButton({
    required this.id,
    required this.label,
    required this.icon,
    this.onTap,
  });
  // AI-generated END - 构造函数

  /// 按钮ID
  final String id;

  /// 按钮标签
  final String label;

  /// 图标
  final IconData icon;

  /// 点击回调
  final VoidCallback? onTap;
}

/// 操作按钮卡片组件
/// 显示多个水平排列的操作按钮
class ActionButtonsCard extends StatelessWidget {
  // AI-generated START - 操作按钮列表
  final List<ActionButton> buttons;
  // AI-generated END - buttons

  const ActionButtonsCard({
    super.key,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: buttons.map((button) {
          return _buildActionButton(button);
        }).toList(),
      ),
    );
  }

  // AI-generated START - 构建操作按钮
  Widget _buildActionButton(ActionButton button) {
    return Expanded(
      child: GestureDetector(
        onTap: button.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI-generated START - 图标
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                button.icon,
                color: Colors.grey.shade700,
                size: 28.0,
              ),
            ),
            // AI-generated END - 图标

            const SizedBox(height: 8.0),

            // AI-generated START - 标签文本
            Text(
              button.label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13.0,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            // AI-generated END - 标签文本
          ],
        ),
      ),
    );
  }
  // AI-generated END - _buildActionButton
}
// AI-generated END - action_buttons_card.dart

