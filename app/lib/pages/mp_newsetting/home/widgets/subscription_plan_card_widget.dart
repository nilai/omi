// AI-generated START - 订阅计划卡片组件，显示计划信息、剩余时间、进度条和试用按钮
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';

/// 订阅计划卡片组件
/// 显示计划名称、剩余时间、总时间、进度条和试用按钮
class SubscriptionPlanCardWidget extends StatelessWidget {
  // AI-generated START - 计划名称
  final String planName;
  // AI-generated END - planName

  // AI-generated START - 剩余时间（分钟）
  final int remainingMinutes;
  // AI-generated END - remainingMinutes

  // AI-generated START - 总时间（分钟）
  final int totalMinutes;
  // AI-generated END - totalMinutes

  // AI-generated START - 试用按钮点击回调
  final VoidCallback? onTrialTap;
  // AI-generated END - onTrialTap

  // AI-generated START - 是否显示无限选项
  final bool showUnlimited;
  // AI-generated END - showUnlimited

  const SubscriptionPlanCardWidget({
    super.key,
    required this.planName,
    required this.remainingMinutes,
    required this.totalMinutes,
    this.onTrialTap,
    this.showUnlimited = true,
  });

  @override
  Widget build(BuildContext context) {
    // AI-generated START - 计算进度百分比
    final double progress = totalMinutes > 0 ? remainingMinutes / totalMinutes : 0.0;
    // AI-generated END - progress

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6), // 浅紫色
            Color(0xFF6D28D9), // 深紫色
          ],
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI-generated START - 顶部区域：图标+名称 和 剩余时间
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI-generated START - 左侧：图标和计划名称
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Assets.images.settingSubscription.image(
                        fit: BoxFit.cover,
                        width: 48.0,
                        height: 48.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MemoAI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          planName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // AI-generated END - 左侧：图标和计划名称

                // AI-generated START - 右侧：剩余时间显示
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '剩余',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '$remainingMinutes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '分钟',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // AI-generated END - 右侧：剩余时间显示
              ],
            ),
            // AI-generated END - 顶部区域

            const SizedBox(height: 20.0),

            // AI-generated START - 中间区域：总时间和进度条
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalMinutes 分钟',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12.0),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.purple.shade300.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFFA500), // 橙色/黄色
                          ),
                          minHeight: 8.0,
                        ),
                      ),
                    ),
                    if (showUnlimited) ...[
                      const SizedBox(width: 12.0),
                      const Text(
                        '∞',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      const Text(
                        'Unlimited',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            // AI-generated END - 中间区域

            const SizedBox(height: 12.0),

            // AI-generated START - 底部：试用按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTrialTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6D28D9),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '7天无限免费试用',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // AI-generated END - 底部：试用按钮
          ],
        ),
      ),
    );
  }
}
// AI-generated END - subscription_plan_card_widget.dart
