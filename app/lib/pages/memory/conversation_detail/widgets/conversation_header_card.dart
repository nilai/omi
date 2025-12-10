// AI-generated START - 对话头部卡片组件，显示对话标题和总结时间
import 'package:flutter/material.dart';

/// 对话头部卡片组件
/// 显示对话标题和总结时间信息
class ConversationHeaderCard extends StatelessWidget {
  // AI-generated START - 对话标题
  final String title;
  // AI-generated END - title

  // AI-generated START - 总结时间
  final String summaryTime;
  // AI-generated END - summaryTime

  const ConversationHeaderCard({
    super.key,
    required this.title,
    required this.summaryTime,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          // AI-generated END - 标题

          const SizedBox(height: 12.0),

          // AI-generated START - 总结时间
          Text(
            '总结时间 : $summaryTime',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13.0,
              fontWeight: FontWeight.normal,
            ),
          ),
          // AI-generated END - 总结时间
        ],
      ),
    );
  }
}
// AI-generated END - conversation_header_card.dart

