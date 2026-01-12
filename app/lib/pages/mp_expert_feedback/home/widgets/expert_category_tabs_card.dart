// AI-generated START - 专家分类标签栏卡片组件
import 'package:flutter/material.dart';

/// 专家分类标签数据模型
class ExpertCategoryTab {
  // AI-generated START - 构造函数
  const ExpertCategoryTab({
    required this.label,
    required this.icon,
    this.id,
  });
  // AI-generated END - 构造函数

  /// 标签ID（可选，用于标识）
  final String? id;

  /// 标签文字
  final String label;

  /// 标签图标
  final IconData icon;
}

/// 专家分类标签栏卡片组件
/// 显示标题和专家分类标签，支持切换选择
class ExpertCategoryTabsCard extends StatelessWidget {
  // AI-generated START - 构造函数
  const ExpertCategoryTabsCard({
    super.key,
    this.title,
    this.subtitle,
    required this.categories,
    this.selectedIndex = 0,
    this.onCategoryChanged,
  });
  // AI-generated END - 构造函数

  /// 标题文本
  final String? title;

  /// 副标题文本
  final String? subtitle;

  /// 分类列表
  final List<ExpertCategoryTab> categories;

  /// 当前选中的索引
  final int selectedIndex;

  /// 分类切换回调
  final ValueChanged<int>? onCategoryChanged;

  // AI-generated START - 获取默认分类列表
  static List<ExpertCategoryTab> getDefaultCategories() {
    return const [
      ExpertCategoryTab(
        label: '全部',
        icon: Icons.apps,
      ),
      ExpertCategoryTab(
        label: '商业',
        icon: Icons.business,
      ),
      ExpertCategoryTab(
        label: '技术',
        icon: Icons.code,
      ),
      ExpertCategoryTab(
        label: '创意',
        icon: Icons.palette,
      ),
      ExpertCategoryTab(
        label: '生活',
        icon: Icons.home,
      ),
    ];
  }
  // AI-generated END - getDefaultCategories

  // AI-generated START - 构建方法
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI-generated START - 标题和副标题
          if (title != null || subtitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (subtitle != null) ...[
                    if (title != null) const SizedBox(height: 4.0),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // AI-generated END - 标题和副标题

          // AI-generated START - 分类标签栏
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  final isSelected = index == selectedIndex;
                  return _buildCategoryButton(category, index, isSelected);
                }),
              ],
            ),
          ),
          // AI-generated END - 分类标签栏
        ],
      ),
    );
  }
  // AI-generated END - 构建方法

  // AI-generated START - 构建分类按钮
  Widget _buildCategoryButton(
    ExpertCategoryTab category,
    int index,
    bool isSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          onCategoryChanged?.call(index);
        },
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2563EB) // 蓝色背景（激活状态）
                : Colors.white, // 白色背景（未激活状态）
            borderRadius: BorderRadius.circular(20.0),
            border: isSelected
                ? null
                : Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1.0,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
                size: 14.0,
              ),
              const SizedBox(width: 4.0),
              Text(
                category.label,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.normal,
                  color: isSelected ? Colors.white : const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // AI-generated END - 构建分类按钮
}
// AI-generated END - expert_category_tabs_card.dart
