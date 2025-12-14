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
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9333EA), // 紫色
            Color(0xFF7E22CE), // 中间深紫色
            Color(0xFF000000), // 黑色
          ],
          stops: [0.0, 0.6, 1.0], // 控制每个颜色的位置，黑色占最后50%
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
        padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 12.0, bottom: 0.0),
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
                        width: 28.0,
                        height: 28.0,
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
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          planName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10.0,
                            fontWeight: FontWeight.normal,
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
                    Text(
                      '剩余',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10.0,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Text(
                      '$remainingMinutes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '分钟',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10.0,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                // AI-generated END - 右侧：剩余时间显示
              ],
            ),
            // AI-generated END - 顶部区域

            const SizedBox(height: 4.0),

            // AI-generated START - 中间区域：总时间和进度条
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$totalMinutes 分钟',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (showUnlimited) ...[
                      const SizedBox(width: 12.0),
                      Text(
                        '∞',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12.0,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        'Unlimited',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10.0,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.purple.shade300.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFA500), // 橙色/黄色
                    ),
                    minHeight: 4.0,
                  ),
                ),
              ],
            ),
            // AI-generated END - 中间区域

            const SizedBox(height: 4.0),

            // AI-generated START - 底部：试用按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTrialTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6D28D9),
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '7天无限免费试用',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // AI-generated END - 底部：试用按钮
            const SizedBox(
              height: 6.0,
            )
          ],
        ),
      ),
    );
  }
}
// AI-generated END - subscription_plan_card_widget.dart
