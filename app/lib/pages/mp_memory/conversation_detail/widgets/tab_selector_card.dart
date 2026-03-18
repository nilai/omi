// AI-generated START - 标签选择器卡片组件，显示多个标签选项
import 'package:flutter/material.dart';

/// 标签选项数据模型
class TabOption {
  // AI-generated START - 构造函数
  const TabOption({
    required this.id,
    required this.label,
    required this.icon,
  });
  // AI-generated END - 构造函数

  /// 选项ID
  final String id;

  /// 标签文本
  final String label;

  /// 图标
  final IconData icon;
}

/// 标签选择器卡片组件
/// 显示多个标签选项，支持选择切换
class TabSelectorCard extends StatelessWidget {
  // AI-generated START - 标签选项列表
  final List<TabOption> options;
  // AI-generated END - options

  // AI-generated START - 当前选中的选项ID
  final String? selectedId;
  // AI-generated END - selectedId

  // AI-generated START - 选择回调
  final ValueChanged<String>? onTabSelected;
  // AI-generated END - onTabSelected

  const TabSelectorCard({
    super.key,
    required this.options,
    this.selectedId,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
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
        children: options.map((option) {
          final isSelected = selectedId == option.id;
          return _buildTabOption(option, isSelected);
        }).toList(),
      ),
    );
  }

  // AI-generated START - 构建标签选项
  Widget _buildTabOption(TabOption option, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          onTabSelected?.call(option.id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFEFF6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI-generated START - 图标
              Icon(
                option.icon,
                color: isSelected ? Color(0xFF2563EB) : Color(0xFF4B5563),
                size: 24.0,
              ),
              // AI-generated END - 图标

              const SizedBox(height: 4.0),

              // AI-generated START - 标签文本
              Text(
                option.label,
                style: TextStyle(
                  color: isSelected ? Color(0xFF2563EB) : Color(0xFF4B5563),
                  fontSize: 12.0,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              // AI-generated END - 标签文本
            ],
          ),
        ),
      ),
    );
  }
  // AI-generated END - _buildTabOption
}
// AI-generated END - tab_selector_card.dart
