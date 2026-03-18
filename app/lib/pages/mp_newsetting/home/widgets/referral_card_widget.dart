// AI-generated START - 邀请好友推荐卡片组件，显示推荐信息和奖励提示
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';

/// 邀请好友推荐卡片组件
/// 显示推荐 MemoAI 给朋友的邀请卡片，包含礼物图标、推荐文本和通知标识
class ReferralCardWidget extends StatelessWidget {
  // AI-generated START - 卡片点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  // AI-generated START - 是否显示通知红点
  final bool showNotification;
  // AI-generated END - showNotification

  // AI-generated START - 推荐标题文本
  final String? title;
  // AI-generated END - title

  // AI-generated START - 推荐描述文本
  final String? description;
  // AI-generated END - description

  const ReferralCardWidget({
    super.key,
    this.onTap,
    this.showNotification = false,
    this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: Colors.lightBlue.shade100,
            width: 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          child: Row(
            children: [
              // AI-generated START - 左侧：礼物图标
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Assets.images.settingReferral.image(
                  fit: BoxFit.cover,
                  width: 32.0,
                  height: 32.0,
                ),
              ),
              // AI-generated END - 左侧：礼物图标

              const SizedBox(width: 16.0),

              // AI-generated START - 中间：推荐文本
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? '推荐 MemoAI 给朋友',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      description ?? '邀请好友,双方都能获得奖励',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // AI-generated END - 中间：推荐文本

              // AI-generated START - 右侧：通知点和箭头
              Stack(
                children: [
                  Assets.images.settingRightArrow1.image(
                    width: 19.0,
                    height: 18.0,
                    fit: BoxFit.contain,
                  ),
                  if (showNotification)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 6.0,
                        height: 6.0,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              // AI-generated END - 右侧：通知点和箭头
            ],
          ),
        ),
      ),
    );
  }
}
// AI-generated END - referral_card_widget.dart
