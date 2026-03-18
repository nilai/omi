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
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 20.0),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: buttons.asMap().entries.map((entry) {
          final index = entry.key;
          final button = entry.value;
          final isLast = index == buttons.length - 1;
          return _buildActionButton(button, isLast: isLast);
        }).toList(),
      ),
    );
  }

  // AI-generated START - 构建操作按钮
  Widget _buildActionButton(ActionButton button, {bool isLast = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: button.onTap,
        child: Container(
          margin: EdgeInsets.only(right: isLast ? 0.0 : 8.0),
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI-generated START - 图标
              Icon(
                button.icon,
                color: const Color(0xFF374151),
                size: 20.0,
              ),
              // AI-generated END - 图标

              const SizedBox(height: 4.0),

              // AI-generated START - 标签文本
              Text(
                button.label,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14.0,
                  fontWeight: FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              // AI-generated END - 标签文本
            ],
          ),
        ),
      ),
    );
  }
  // AI-generated END - _buildActionButton
}
// AI-generated END - action_buttons_card.dart
