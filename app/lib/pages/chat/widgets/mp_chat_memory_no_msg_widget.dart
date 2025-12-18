import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 聊天记忆无消息时的Widget
/// 显示快速提问和AI介绍消息
class MPChatMemoryNoMsgWidget extends StatelessWidget {
  /// 点击问题后的回调，返回问题文本
  final Function(String)? onQuestionTap;

  /// AI头像URL（可选）
  final String? avatarUrl;

  /// AI名称，默认为"叶成功 AI"
  final String aiName;

  /// AI介绍消息文本
  final String introMessage;

  /// 时间戳，默认为当前时间
  final DateTime? timestamp;

  const MPChatMemoryNoMsgWidget({
    super.key,
    this.onQuestionTap,
    this.avatarUrl,
    this.aiName = '叶成功 AI',
    this.introMessage = '你好!我是基于你和叶成功的对话记录训练的AI助手，可以帮助你回顾和分析你们的沟通内容。',
    this.timestamp,
  });

  /// 快速提问的问题列表
  static const List<String> quickQuestions = [
    '帮我总结一下近半年我们的沟通情况',
    '我们讨论的最重要三个话题',
    '前几次讨论我们还有没有没解决的问题',
  ];

  @override
  Widget build(BuildContext context) {
    final now = timestamp ?? DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 快速提问标题
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Text(
              '快速提问',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          // 快速提问按钮列表
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: quickQuestions.map((question) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildQuestionCard(
                    context: context,
                    question: question,
                    onTap: () {
                      onQuestionTap?.call(question);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // AI介绍消息
          _buildAIMessage(
            context: context,
            avatarUrl: avatarUrl,
            aiName: aiName,
            message: introMessage,
            timestamp: timeString,
          ),
        ],
      ),
    );
  }

  /// 构建问题卡片
  Widget _buildQuestionCard({
    required BuildContext context,
    required String question,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE), // 浅蓝色背景
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0369A1), // 深蓝色文字
            height: 1.4,
          ),
        ),
      ),
    );
  }

  /// 构建AI消息
  Widget _buildAIMessage({
    required BuildContext context,
    String? avatarUrl,
    required String aiName,
    required String message,
    required String timestamp,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI头像
          _buildAvatar(avatarUrl),
          const SizedBox(width: 12),
          // AI名称和消息内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI名称
                Text(
                  aiName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                // 消息气泡
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6), // 浅灰色背景
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4.0),
                      topRight: Radius.circular(16.0),
                      bottomRight: Radius.circular(16.0),
                      bottomLeft: Radius.circular(16.0),
                    ),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // 时间戳
                Text(
                  timestamp,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (context, url) => const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFE5E7EB),
            child: Icon(
              Icons.person,
              color: Color(0xFF9CA3AF),
              size: 24,
            ),
          ),
          errorWidget: (context, url, error) => const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFE5E7EB),
            child: Icon(
              Icons.person,
              color: Color(0xFF9CA3AF),
              size: 24,
            ),
          ),
        ),
      );
    } else {
      // 默认头像 - 蓝色衬衫男性头像
      return const CircleAvatar(
        radius: 20,
        backgroundColor: Color(0xFF3B82F6), // 蓝色背景
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: 24,
        ),
      );
    }
  }
}
