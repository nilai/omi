// AI-generated START - 人物记忆卡片组件，显示人物记忆信息
import 'package:flutter/material.dart';

/// 人物记忆卡片组件
/// 显示人物记忆记录，包含头像、姓名、时间、描述和音频图标
class MPChatPeopleMemoryCard extends StatelessWidget {
  /// 头像URL
  final String? avatarUrl;

  /// 头像背景颜色
  final Color? avatarBackgroundColor;

  /// 姓名
  final String name;

  /// 时间戳文本
  final String timestamp;

  /// 活动描述
  final String description;

  /// 点击回调
  final VoidCallback? onTap;

  const MPChatPeopleMemoryCard({
    super.key,
    this.avatarUrl,
    this.avatarBackgroundColor,
    required this.name,
    required this.timestamp,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左侧：头像
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
                // 头像上的音频图标
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
                    child: const Icon(
                      Icons.graphic_eq,
                      color: Colors.white,
                      size: 12.0,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12.0),

            // 中间：内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 姓名和时间戳
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        timestamp,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2.0),

                  // 活动描述
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 14.0,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8.0),

            // 右侧：箭头
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20.0,
            ),
          ],
        ),
      ),
    );
  }
}
// AI-generated END - mp_chat_people_memory_card.dart
