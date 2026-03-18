// AI-generated START - 人物信息卡片组件，显示人物基本信息和对话次数
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';

/// 人物信息卡片组件
/// 显示人物头像、姓名和对话次数
class CharacterInfoCard extends StatelessWidget {
  // AI-generated START - 头像URL
  final String? avatarUrl;
  // AI-generated END - avatarUrl

  // AI-generated START - 头像背景颜色
  final Color? avatarBackgroundColor;
  // AI-generated END - avatarBackgroundColor

  // AI-generated START - 人物姓名
  final String name;
  // AI-generated END - name

  // AI-generated START - 对话次数
  final int conversationCount;
  // AI-generated END - conversationCount

  // AI-generated START - 点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  const CharacterInfoCard({
    super.key,
    this.avatarUrl,
    this.avatarBackgroundColor,
    required this.name,
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
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // AI-generated START - 左侧：头像
            CircleAvatar(
              radius: 32.0,
              backgroundColor: avatarBackgroundColor ?? Colors.amber,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 32.0,
                    )
                  : null,
            ),
            // AI-generated END - 左侧：头像

            const SizedBox(width: 16.0),

            // AI-generated START - 中间：信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI-generated START - 姓名
                  Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // AI-generated END - 姓名

                  const SizedBox(height: 8.0),

                  // AI-generated START - 对话次数
                  Row(
                    children: [
                      Text(
                        '共 $conversationCount 次对话',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                  // AI-generated END - 对话次数
                ],
              ),
            ),
            // AI-generated END - 中间：信息

            // AI-generated START - 右侧：箭头（可选）
            if (onTap != null)
              Assets.images.settingRightArrow1.image(
                width: 24.0,
                height: 24.0,
              ),
            // AI-generated END - 右侧：箭头
          ],
        ),
      ),
    );
  }
}
// AI-generated END - character_info_card.dart
