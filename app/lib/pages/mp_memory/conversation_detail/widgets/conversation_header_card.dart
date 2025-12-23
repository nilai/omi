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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // AI-generated START - 标题
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          // AI-generated END - 标题

          const SizedBox(height: 4.0),

          // AI-generated START - 总结时间
          Text(
            '总结时间 : $summaryTime',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14.0,
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
