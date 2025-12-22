// AI-generated START - 记忆对话卡片组件，显示对话记录信息
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';

/// 记忆对话卡片组件
/// 显示对话记录，包含头像、姓名、时间、描述和对话次数
class MemoryConversationCard extends StatelessWidget {
  // AI-generated START - 头像URL
  final String? avatarUrl;
  // AI-generated END - avatarUrl

  // AI-generated START - 头像背景颜色
  final Color? avatarBackgroundColor;
  // AI-generated END - avatarBackgroundColor

  // AI-generated START - 头像上的小图标（可选）
  final Widget? avatarBadge;
  // AI-generated END - avatarBadge

  // AI-generated START - 姓名
  final String name;
  // AI-generated END - name

  // AI-generated START - 时间戳文本
  final String timestamp;
  // AI-generated END - timestamp

  // AI-generated START - 活动描述
  final String description;
  // AI-generated END - description

  // AI-generated START - 对话次数
  final int conversationCount;
  // AI-generated END - conversationCount

  // AI-generated START - 点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  const MemoryConversationCard({
    super.key,
    this.avatarUrl,
    this.avatarBackgroundColor,
    this.avatarBadge,
    required this.name,
    required this.timestamp,
    required this.description,
    required this.conversationCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI-generated START - 左侧：头像
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28.0,
                  backgroundColor: avatarBackgroundColor ?? Colors.amber,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28.0,
                        )
                      : null,
                ),
                // AI-generated START - 头像上的小图标
                if (avatarBadge != null)
                  Positioned(
                    right: -4.0,
                    bottom: -4.0,
                    child: Container(
                      width: 20.0,
                      height: 20.0,
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2.0,
                        ),
                      ),
                      child: avatarBadge,
                    ),
                  ),
                // AI-generated END - 头像上的小图标
              ],
            ),
            // AI-generated END - 左侧：头像

            const SizedBox(width: 12.0),

            // AI-generated START - 中间：内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI-generated START - 姓名和时间戳
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        timestamp,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                  // AI-generated END - 姓名和时间戳

                  const SizedBox(height: 3.0),

                  // AI-generated START - 活动描述
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 14.0,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // AI-generated END - 活动描述

                  const SizedBox(height: 2.0),

                  // AI-generated START - 对话次数
                  Row(
                    children: [
                      Assets.images.mpMemoryImessage.image(
                        width: 12.0,
                        height: 12.0,
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          '$conversationCount次对话',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF9CA3AF),
                        size: 20.0,
                      ),
                    ],
                  ),
                  // AI-generated END - 对话次数
                ],
              ),
            ),
            // AI-generated END - 中间：内容区域

            const SizedBox(width: 8.0),

            // AI-generated START - 右侧：箭头

            // AI-generated END - 右侧：箭头
          ],
        ),
      ),
    );
  }
}
// AI-generated END - memory_conversation_card.dart
