// AI-generated START - 记忆仓库卡片组件，显示沟通记录入口和朋友头像列表
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';

/// 记忆仓库卡片组件
/// 显示记忆仓库入口，包含标题、描述和重叠的朋友头像列表
class MemoryWarehouseCardWidget extends StatelessWidget {
  // AI-generated START - 卡片点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  // AI-generated START - 标题文本
  final String? title;
  // AI-generated END - title

  // AI-generated START - 副标题文本
  final String? subtitle;
  // AI-generated END - subtitle

  // AI-generated START - 朋友头像URL列表
  final List<String> friendAvatars;
  // AI-generated END - friendAvatars

  // AI-generated START - 显示的头像数量（默认4个）
  final int maxVisibleAvatars;
  // AI-generated END - maxVisibleAvatars

  const MemoryWarehouseCardWidget({
    super.key,
    this.onTap,
    this.title,
    this.subtitle,
    this.friendAvatars = const [],
    this.maxVisibleAvatars = 4,
  });

  @override
  Widget build(BuildContext context) {
    final visibleAvatars = friendAvatars.take(maxVisibleAvatars).toList();
    final remainingCount = friendAvatars.length > maxVisibleAvatars ? friendAvatars.length - maxVisibleAvatars : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF7ED), // 浅粉色
              Color(0xFFFAF5FF),
            ],
          ),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: Colors.pink.shade100.withValues(alpha: 0.5),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withValues(alpha: 0.1),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI-generated START - 顶部：标题和导航箭头
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title ?? '记忆仓库',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          subtitle ?? '查看与朋友的沟通记录',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Assets.images.settingRightArrow2.image(
                    width: 21.0,
                    height: 20.0,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              // AI-generated END - 顶部：标题和导航箭头

              const SizedBox(height: 12.0),

              // AI-generated START - 底部：重叠的头像列表
              SizedBox(
                height: 40.0,
                child: Stack(
                  children: [
                    ...visibleAvatars.asMap().entries.map((entry) {
                      final index = entry.key;
                      final avatarUrl = entry.value;
                      // AI-generated START - 计算头像位置，每个头像重叠12像素
                      final double left = index * 36.0; // 48 - 12 = 36
                      // AI-generated END - left
                      return Positioned(
                        left: left,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2.0,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24.0,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    color: Colors.grey.shade400,
                                    size: 24.0,
                                  )
                                : null,
                          ),
                        ),
                      );
                    }),
                    if (remainingCount > 0)
                      Positioned(
                        left: visibleAvatars.length * 36.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2.0,
                            ),
                          ),
                          child: Container(
                            width: 40.0,
                            height: 40.0,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFF6B9D), // 粉色
                                  Color(0xFFFF8C42), // 橙色
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '+$remainingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // AI-generated END - 底部：重叠的头像列表
            ],
          ),
        ),
      ),
    );
  }
}
// AI-generated END - memory_warehouse_card_widget.dart
