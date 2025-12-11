// AI-generated START - Memo 任务卡片组件
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Memo 任务卡片组件
/// 显示任务信息，包含标题、描述、日期、标签和操作按钮
/// 支持左滑显示删除按钮
class MemoTaskCard extends StatelessWidget {
  // AI-generated START - 任务ID（用于 Dismissible 的 key）
  final String id;
  // AI-generated END - id

  // AI-generated START - 任务标题
  final String title;
  // AI-generated END - title

  // AI-generated START - 任务描述
  final String description;
  // AI-generated END - description

  // AI-generated START - 任务日期（格式：YYYY-MM-DD）
  final String date;
  // AI-generated END - date

  // AI-generated START - 标签列表
  final List<String> tags;
  // AI-generated END - tags

  // AI-generated START - 点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  // AI-generated START - 删除回调
  final VoidCallback? onDelete;
  // AI-generated END - onDelete

  const MemoTaskCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.tags = const [],
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart, // 只允许左滑
      // AI-generated START - 左滑时显示的删除背景
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12.0),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Text(
          '删除',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // AI-generated END - secondaryBackground

      // AI-generated START - 确认删除
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // 左滑删除
          HapticFeedback.mediumImpact();
          onDelete?.call();
          return false; // 不自动删除，由回调处理
        }
        return false;
      },
      // AI-generated END - confirmDismiss

      // AI-generated START - 卡片内容
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI-generated START - 左侧内容区域
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI-generated START - 标题
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // AI-generated END - 标题

                      const SizedBox(height: 8.0),

                      // AI-generated START - 描述
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14.0,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // AI-generated END - 描述

                      const SizedBox(height: 12.0),

                      // AI-generated START - 日期和标签
                      Row(
                        children: [
                          // 日期
                          Text(
                            date,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12.0,
                            ),
                          ),
                          if (tags.isNotEmpty) ...[
                            const SizedBox(width: 12.0),
                            // 标签
                            ...tags.map((tag) => Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                      vertical: 4.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF64B5F6),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )),
                          ],
                        ],
                      ),
                      // AI-generated END - 日期和标签
                    ],
                  ),
                ),
                // AI-generated END - 左侧内容区域

                const SizedBox(width: 12.0),

                // AI-generated START - 右侧操作按钮
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap?.call();
                  },
                  child: Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: const BoxDecoration(
                      color: Color(0xFF007AFF),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/images/mp_memo_edit.png',
                        width: 20.0,
                        height: 20.0,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // AI-generated END - 右侧操作按钮
              ],
            ),
          ),
        ),
      ),
      // AI-generated END - 卡片内容
    );
  }
}
// AI-generated END - memo_task_card.dart
