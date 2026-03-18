// AI-generated START - 消息卡片组件，显示单条聊天消息
import 'package:flutter/material.dart';

/// 消息卡片数据模型
class MPMessageCardData {
  // AI-generated START - 构造函数
  const MPMessageCardData({
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.avatarText,
    this.avatarUrl,
    this.backgroundColor,
  });
  // AI-generated END - 构造函数

  /// 发送者姓名
  final String senderName;

  /// 消息内容
  final String content;

  /// 开始时间，单位s
  final String timestamp;

  /// 头像文字（如果提供，将显示在头像中）
  final String? avatarText;

  /// 头像URL（可选）
  final String? avatarUrl;

  /// 卡片背景颜色（可选，默认为白色）
  final Color? backgroundColor;
}

/// 消息卡片组件
/// 显示单条聊天消息，包含头像、发送者姓名、时间戳和消息内容
class MPMessageCard extends StatelessWidget {
  // AI-generated START - 消息数据
  final MPMessageCardData message;
  // AI-generated END - message

  // AI-generated START - 点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  const MPMessageCard({
    super.key,
    required this.message,
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
          color: message.backgroundColor ?? Colors.white,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI-generated START - 头像
            _buildAvatar(),
            // AI-generated END - 头像

            const SizedBox(width: 12.0),

            // AI-generated START - 消息内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI-generated START - 发送者姓名和时间戳
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        message.senderName,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        message.timestamp,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12.0,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  // AI-generated END - 发送者姓名和时间戳

                  const SizedBox(height: 8.0),

                  // AI-generated START - 消息内容
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15.0,
                      fontWeight: FontWeight.normal,
                      height: 1.5,
                    ),
                  ),
                  // AI-generated END - 消息内容
                ],
              ),
            ),
            // AI-generated END - 消息内容区域
          ],
        ),
      ),
    );
  }

  // AI-generated START - 构建头像
  Widget _buildAvatar() {
    // 如果有头像URL，优先使用网络图片
    if (message.avatarUrl != null && message.avatarUrl!.isNotEmpty) {
      return SizedBox(
        width: 32.0,
        height: 32.0,
        child: CircleAvatar(
          radius: 24.0,
          backgroundColor: const Color(0xFF3B82F6),
          backgroundImage: NetworkImage(message.avatarUrl!),
        ),
      );
    }

    // 否则使用文字头像
    final avatarChar = message.avatarText ?? (message.senderName.isNotEmpty ? message.senderName[0] : '?');

    return Container(
      width: 32.0,
      height: 32.0,
      decoration: const BoxDecoration(
        color: Color(0xFF3B82F6),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          avatarChar,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  // AI-generated END - _buildAvatar
}
// AI-generated END - mp_message_card.dart
