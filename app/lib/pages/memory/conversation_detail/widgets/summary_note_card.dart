// AI-generated START - 摘要笔记卡片组件，显示对话摘要和关键信息
import 'package:flutter/material.dart';

/// 摘要笔记卡片组件
/// 显示时间、收藏状态、高亮引用、分析和相关标签
class SummaryNoteCard extends StatelessWidget {
  // AI-generated START - 时间
  final String time;
  // AI-generated END - time

  // AI-generated START - 是否收藏
  final bool isFavorite;
  // AI-generated END - isFavorite

  // AI-generated START - 收藏状态变化回调
  final ValueChanged<bool>? onFavoriteChanged;
  // AI-generated END - onFavoriteChanged

  // AI-generated START - 高亮引用文本
  final String highlightQuote;
  // AI-generated END - highlightQuote

  // AI-generated START - 分析文本
  final String? analysis;
  // AI-generated END - analysis

  // AI-generated START - 相关标签列表
  final List<String>? tags;
  // AI-generated END - tags

  // AI-generated START - 标签点击回调
  final ValueChanged<String>? onTagTap;
  // AI-generated END - onTagTap

  const SummaryNoteCard({
    super.key,
    required this.time,
    this.isFavorite = false,
    this.onFavoriteChanged,
    required this.highlightQuote,
    this.analysis,
    this.tags,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI-generated START - 顶部：时间和收藏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '时间: $time',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13.0,
                ),
              ),
              GestureDetector(
                onTap: () {
                  onFavoriteChanged?.call(!isFavorite);
                },
                child: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: Colors.amber.shade700,
                  size: 20.0,
                ),
              ),
            ],
          ),
          // AI-generated END - 顶部：时间和收藏

          const SizedBox(height: 12.0),

          // AI-generated START - 高亮引用区域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.yellow.shade200,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              '"$highlightQuote"',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 15.0,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // AI-generated END - 高亮引用区域

          // AI-generated START - 分析区域
          if (analysis != null) ...[
            const SizedBox(height: 12.0),
            Text(
              '分析:',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              analysis!,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14.0,
                height: 1.5,
              ),
            ),
          ],
          // AI-generated END - 分析区域

          // AI-generated START - 标签区域
          if (tags != null && tags!.isNotEmpty) ...[
            const SizedBox(height: 12.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: tags!.map((tag) {
                return GestureDetector(
                  onTap: () {
                    onTagTap?.call(tag);
                  },
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 13.0,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          // AI-generated END - 标签区域
        ],
      ),
    );
  }
}
// AI-generated END - summary_note_card.dart

