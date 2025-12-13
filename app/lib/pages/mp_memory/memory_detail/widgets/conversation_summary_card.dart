// AI-generated START - 对话摘要卡片组件，显示对话的标题、摘要和详细信息
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';

/// 对话摘要卡片组件
/// 显示对话标题、摘要内容、日期、时长和参与人数等信息
class ConversationSummaryCard extends StatelessWidget {
  // AI-generated START - 对话标题
  final String title;
  // AI-generated END - title

  // AI-generated START - 对话摘要
  final String summary;
  // AI-generated END - summary

  // AI-generated START - 对话日期
  final String date;
  // AI-generated END - date

  // AI-generated START - 对话时长（秒）
  final int durationSeconds;
  // AI-generated END - durationSeconds

  // AI-generated START - 参与人数
  final int participantCount;
  // AI-generated END - participantCount

  // AI-generated START - 点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  const ConversationSummaryCard({
    super.key,
    required this.title,
    required this.summary,
    required this.date,
    required this.durationSeconds,
    required this.participantCount,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI-generated START - 标题区域
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8.0),
                // AI-generated START - 音频图标
                Assets.images.mpMemoryDetailRadio.image(
                  width: 32.0,
                  height: 32.0,
                ),
                // AI-generated END - 音频图标
              ],
            ),
            // AI-generated END - 标题区域

            const SizedBox(height: 12.0),

            // AI-generated START - 摘要内容
            Text(
              summary,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14.0,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // AI-generated END - 摘要内容

            const SizedBox(height: 16.0),

            // AI-generated START - 底部信息
            Row(
              children: [
                // AI-generated START - 日期
                Row(
                  children: [
                    Assets.images.mpMemoryDetailTime.image(
                      width: 16.0,
                      height: 16.0,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
                // AI-generated END - 日期

                const SizedBox(width: 16.0),

                // AI-generated START - 时长
                Row(
                  children: [
                    Assets.images.mpMemoryDetailHistory.image(
                      width: 16.0,
                      height: 16.0,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      _formatDuration(durationSeconds),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
                // AI-generated END - 时长

                const SizedBox(width: 16.0),

                // AI-generated START - 参与人数
                Row(
                  children: [
                    Assets.images.mpMemoryDetailPeople.image(
                      width: 16.0,
                      height: 16.0,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      '$participantCount人',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
                // AI-generated END - 参与人数

                const Spacer(),

                // AI-generated START - 右箭头
                Assets.images.settingRightArrow1.image(
                  width: 20.0,
                  height: 20.0,
                ),
                // AI-generated END - 右箭头
              ],
            ),
            // AI-generated END - 底部信息
          ],
        ),
      ),
    );
  }

  // AI-generated START - 格式化时长
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0 && remainingSeconds > 0) {
      return '$minutes分$remainingSeconds秒';
    } else if (minutes > 0) {
      return '$minutes分钟';
    } else {
      return '$remainingSeconds秒';
    }
  }
  // AI-generated END - _formatDuration
}
// AI-generated END - conversation_summary_card.dart
