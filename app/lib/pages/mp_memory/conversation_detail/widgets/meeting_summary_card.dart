// AI-generated START - 会议总结卡片组件，显示会议总结内容
import 'package:flutter/material.dart';

/// 会议总结卡片组件
/// 显示会议总结的标题和正文内容
class MeetingSummaryCard extends StatelessWidget {
  // AI-generated START - 标题
  final String? title;
  // AI-generated END - title

  // AI-generated START - 总结内容
  final String content;
  // AI-generated END - content

  const MeetingSummaryCard({
    super.key,
    this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
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
            title ?? '会议总结',
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          // AI-generated END - 标题

          const SizedBox(height: 8.0),

          // AI-generated START - 正文内容
          Text(
            content,
            style: TextStyle(
              color: Color(0xFF374151),
              fontSize: 14.0,
              height: 1.4,
              fontWeight: FontWeight.normal,
            ),
          ),
          // AI-generated END - 正文内容
        ],
      ),
    );
  }
}
// AI-generated END - meeting_summary_card.dart
