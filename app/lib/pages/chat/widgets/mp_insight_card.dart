import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../mp_insight_model.dart';

/// Insights 卡片 Widget
class MPInsightCard extends StatelessWidget {
  final MPInsightModel insight;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetailTap;
  final VoidCallback? onMenuTap;

  const MPInsightCard({
    super.key,
    required this.insight,
    this.onTap,
    this.onViewDetailTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部：标题和菜单按钮
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题 - 单行显示
                      Text(
                        insight.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // 时间 - 单行显示
                      Text(
                        insight.period.isNotEmpty ? insight.period : insight.timeText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 菜单按钮
                GestureDetector(
                  onTap: onMenuTap,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const FaIcon(
                      FontAwesomeIcons.ellipsisVertical,
                      size: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 内容 - 最大三行
            Text(
              insight.description,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF374151),
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // 底部：状态指示器和查看详情按钮
            Row(
              children: [
                // 状态指示器（绿色对勾）
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
                const Spacer(),
                // 查看详情按钮
                GestureDetector(
                  onTap: onViewDetailTap,
                  child: const Text(
                    '查看详情',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF306CFF),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

