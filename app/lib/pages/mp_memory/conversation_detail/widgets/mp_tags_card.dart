// AI-generated START - 标签卡片组件，显示对话的标签列表
import 'package:flutter/material.dart';

/// 标签卡片组件
/// 显示对话的标签列表，包括添加标签按钮和已有标签
class MPTagsCard extends StatelessWidget {
  /// 标签列表
  final List<String> tags;

  /// 标题
  final String? title;

  /// 添加标签回调
  final VoidCallback? onAddTag;

  const MPTagsCard({
    super.key,
    required this.tags,
    this.title,
    this.onAddTag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI-generated START - 标题
          Text(
            title ?? '# 标签',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          // AI-generated END - 标题

          const SizedBox(height: 16.0),

          // AI-generated START - 标签列表
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: [
              // 添加标签按钮
              if (onAddTag != null)
                _buildAddTagButton(context),
              // 已有标签
              ...tags.map((tag) => _buildTagChip(tag)),
            ],
          ),
          // AI-generated END - 标签列表
        ],
      ),
    );
  }

  /// 构建添加标签按钮
  Widget _buildAddTagButton(BuildContext context) {
    return GestureDetector(
      onTap: onAddTag,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 16.0,
              color: Colors.grey,
            ),
            SizedBox(width: 4.0),
            Text(
              '添加',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14.0,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建标签按钮
  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}
// AI-generated END - mp_tags_card.dart

