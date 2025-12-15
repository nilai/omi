// AI-generated START - 专家卡片组件
import 'package:flutter/material.dart';

/// 专家卡片数据模型
class MPExpertCardData {
  // AI-generated START - 构造函数
  const MPExpertCardData({
    required this.id,
    required this.name,
    required this.description,
    this.avatarUrl,
    this.isHot = false,
    this.isAdded = false,
  });
  // AI-generated END - 构造函数

  /// 专家ID
  final String id;

  /// 专家名称/角色
  final String name;

  /// 专家描述
  final String description;

  /// 头像URL
  final String? avatarUrl;

  /// 是否热门
  final bool isHot;

  /// 是否已添加
  final bool isAdded;
}

/// 专家卡片组件
/// 显示单个专家的信息卡片，包含头像、名称、标签、描述和添加按钮
class MPExpertCard extends StatelessWidget {
  // AI-generated START - 构造函数
  const MPExpertCard({
    super.key,
    required this.expert,
    this.onAddTap,
    this.onCardTap,
  });
  // AI-generated END - 构造函数

  /// 专家数据
  final MPExpertCardData expert;

  /// 添加按钮点击回调
  final VoidCallback? onAddTap;

  /// 卡片点击回调
  final VoidCallback? onCardTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI-generated START - 左侧：头像（带热门标识）
            Stack(
              children: [
                Container(
                  width: 56.0,
                  height: 56.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: ClipOval(
                    child: expert.avatarUrl != null
                        ? Image.network(
                            expert.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar();
                            },
                          )
                        : _buildDefaultAvatar(),
                  ),
                ),
                // 热门标识
                if (expert.isHot)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 18.0,
                      height: 18.0,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEF4444), // 红色
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        size: 12.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            // AI-generated END - 左侧：头像

            const SizedBox(width: 12.0),

            // AI-generated START - 中间：标题、标签、描述
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和标签行
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          expert.name,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // 热门标签
                      if (expert.isHot)
                        Container(
                          margin: const EdgeInsets.only(left: 8.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444), // 红色
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: const Text(
                            '热门',
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      // 添加按钮
                      const SizedBox(width: 8.0),
                      _buildActionButton(),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // 描述文字
                  Text(
                    expert.description,
                    style: TextStyle(
                      fontSize: 13.0,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // AI-generated END - 中间：标题、标签、描述
          ],
        ),
      ),
    );
  }

  // AI-generated START - 构建默认头像
  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.person,
          color: Colors.grey,
          size: 28.0,
        ),
      ),
    );
  }
  // AI-generated END - _buildDefaultAvatar

  // AI-generated START - 构建操作按钮
  Widget _buildActionButton() {
    if (expert.isAdded) {
      // 已添加状态
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 6.0,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check,
              size: 14.0,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4.0),
            Text(
              '已添加',
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    } else {
      // 未添加状态
      return GestureDetector(
        onTap: onAddTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 6.0,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3), // 蓝色
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 14.0,
                color: Colors.white,
              ),
              SizedBox(width: 4.0),
              Text(
                '添加',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  // AI-generated END - _buildActionButton
}
// AI-generated END - mp_expert_card.dart
