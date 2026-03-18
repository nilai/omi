// AI-generated START - 模板类别选择弹窗组件
import 'package:flutter/material.dart';

/// 模板类别选择弹窗组件
/// 显示模板类别列表，支持选择
class MPTemplateCategorySelectionPopup extends StatefulWidget {
  // AI-generated START - 构造函数
  const MPTemplateCategorySelectionPopup({
    super.key,
    this.selectedCategory,
    this.onCategorySelected,
  });
  // AI-generated END - 构造函数

  /// 当前选中的类别
  final String? selectedCategory;

  /// 类别选择回调，参数为选中的类别名称
  final ValueChanged<String>? onCategorySelected;

  // AI-generated START - 创建状态
  @override
  State<MPTemplateCategorySelectionPopup> createState() => _MPTemplateCategorySelectionPopupState();
  // AI-generated END - 创建状态

  // AI-generated START - 显示弹窗静态方法
  /// 显示模板类别选择弹窗
  static Future<String?> show({
    required BuildContext context,
    String? selectedCategory,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return MPTemplateCategorySelectionPopup(
          selectedCategory: selectedCategory,
          onCategorySelected: (category) {
            Navigator.of(context).pop(category);
          },
        );
      },
    );
  }
  // AI-generated END - 显示弹窗静态方法

  // AI-generated START - 类别列表
  /// 获取所有可用的模板类别
  static const List<String> categories = [
    '通用',
    '会议',
    '销售',
    '采访',
    '教育',
    '投融资',
  ];
  // AI-generated END - 类别列表
}

class _MPTemplateCategorySelectionPopupState extends State<MPTemplateCategorySelectionPopup> {
  // AI-generated START - 构建方法
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI-generated START - 顶部标题栏
            _buildHeader(),
            // AI-generated END - 顶部标题栏

            // AI-generated START - 类别列表
            Flexible(
              child: _buildCategoryList(),
            ),
            // AI-generated END - 类别列表
          ],
        ),
      ),
    );
  }
  // AI-generated END - 构建方法

  // AI-generated START - 构建顶部标题栏
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        children: [
          // AI-generated START - 左侧标题
          const Text(
            '选择类别',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          // AI-generated END - 左侧标题

          const Spacer(),

          // AI-generated START - 右侧关闭按钮
          IconButton(
            icon: const Icon(
              Icons.close,
              color: Color(0xFF9CA3AF),
              size: 20.0,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          // AI-generated END - 右侧关闭按钮
        ],
      ),
    );
  }
  // AI-generated END - 构建顶部标题栏

  // AI-generated START - 构建类别列表
  Widget _buildCategoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: MPTemplateCategorySelectionPopup.categories.length,
      itemBuilder: (context, index) {
        final category = MPTemplateCategorySelectionPopup.categories[index];
        final isSelected = widget.selectedCategory == category;
        return _buildCategoryItem(category, isSelected);
      },
    );
  }
  // AI-generated END - 构建类别列表

  // AI-generated START - 构建单个类别项
  Widget _buildCategoryItem(String category, bool isSelected) {
    return InkWell(
      onTap: () {
        widget.onCategorySelected?.call(category);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: isSelected ? const Color(0xFFFDF2F8) : Colors.white,
        ),
        child: Row(
          children: [
            // AI-generated START - 类别名称
            Expanded(
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  color: isSelected ? const Color(0xFFDB2777) : const Color(0xFF1F2937),
                ),
              ),
            ),
            // AI-generated END - 类别名称

            // AI-generated START - 选中标记
            if (isSelected)
              const Icon(
                Icons.check,
                color: Color(0xFFEC4899),
                size: 20.0,
              ),
            // AI-generated END - 选中标记
          ],
        ),
      ),
    );
  }
  // AI-generated END - 构建单个类别项
}
// AI-generated END - template_category_selection_popup.dart
