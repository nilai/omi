// AI-generated START - 重点内容卡片组件，显示多个重点摘要笔记
import 'package:flutter/material.dart';
import 'package:omi/pages/memory/conversation_detail/widgets/summary_note_card.dart';

/// 重点内容项数据模型
class KeyContentItem {
  // AI-generated START - 构造函数
  const KeyContentItem({
    required this.id,
    required this.time,
    required this.highlightQuote,
    this.isFavorite = false,
    this.analysis,
    this.tags,
  });
  // AI-generated END - 构造函数

  /// 内容ID
  final String id;

  /// 时间
  final String time;

  /// 高亮引用文本
  final String highlightQuote;

  /// 是否收藏
  final bool isFavorite;

  /// 分析文本
  final String? analysis;

  /// 相关标签列表
  final List<String>? tags;
}

/// 重点内容卡片组件
/// 显示标题和多个重点摘要笔记
class KeyContentCard extends StatelessWidget {
  // AI-generated START - 标题
  final String? title;
  // AI-generated END - title

  // AI-generated START - 重点内容项列表
  final List<KeyContentItem> items;
  // AI-generated END - items

  // AI-generated START - 收藏状态变化回调（参数：内容ID）
  final ValueChanged<String>? onFavoriteChanged;
  // AI-generated END - onFavoriteChanged

  // AI-generated START - 标签点击回调
  final ValueChanged<String>? onTagTap;
  // AI-generated END - onTagTap

  const KeyContentCard({
    super.key,
    this.title,
    required this.items,
    this.onFavoriteChanged,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
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
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.orange.shade700,
                size: 20.0,
              ),
              const SizedBox(width: 8.0),
              Text(
                title ?? '重点内容',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // AI-generated END - 标题

          const SizedBox(height: 16.0),

          // AI-generated START - 重点内容项列表
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                SummaryNoteCard(
                  time: item.time,
                  isFavorite: item.isFavorite,
                  onFavoriteChanged: onFavoriteChanged != null
                      ? (isFavorite) {
                          onFavoriteChanged!(item.id);
                        }
                      : null,
                  highlightQuote: item.highlightQuote,
                  analysis: item.analysis,
                  tags: item.tags,
                  onTagTap: onTagTap,
                ),
                // AI-generated START - 添加间距（最后一个不添加）
                if (index < items.length - 1) const SizedBox(height: 8.0),
                // AI-generated END - 添加间距
              ],
            );
          }),
          // AI-generated END - 重点内容项列表
        ],
      ),
    );
  }
}
// AI-generated END - key_content_card.dart
