import 'package:flutter/material.dart';

/// 简单的上传进度卡片。
/// - 左下角展示已上传/总数，可自定义。
/// - 右下角展示百分比，驱动进度条。
class MPHomeUploadWidget extends StatelessWidget {
  const MPHomeUploadWidget({
    super.key,
    required this.title,
    required this.transferredCount,
    required this.totalCount,
    required this.percent,
    this.speedText,
    this.progressColor = const Color(0xFF2F80ED),
  });

  /// 主标题，例：正在从 MemoPin 传输录音至 APP...
  final String title;

  /// 已完成的文件数量。
  final int transferredCount;

  /// 总文件数量。
  final int totalCount;

  /// 右下角百分比（0-100），驱动进度条。
  final double percent;

  /// 速率文案（例：0.00KB/S），可选。
  final String? speedText;

  /// 进度条颜色。
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = percent.clamp(0, 100);
    final progress = clamped / 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(16, 22, 22, 22),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF2FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.autorenew,
                    color: Color(0xFF2F80ED),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF121212),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (speedText != null && speedText!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  speedText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8D8D8D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFEAEAEA),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$transferredCount/$totalCount',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF7A7A7A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${clamped.toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF2F80ED),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}