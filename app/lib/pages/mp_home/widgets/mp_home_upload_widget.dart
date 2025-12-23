import 'package:flutter/material.dart';

/// 简单的上传进度卡片(手机导入音频使用)。
/// - 主标题和百分比在同一行右侧对齐。
/// - 可选的副标题显示在主标题下方。
/// - 进度条显示在文本下方。
class MPHomeUploadWidget extends StatelessWidget {
  const MPHomeUploadWidget({
    super.key,
    required this.title,
    required this.percent,
    this.subtitle,
    this.transferredCount,
    this.totalCount,
    this.progressColor = const Color(0xFF2F80ED),
  });

  /// 主标题，例：音频导入中
  final String title;

  /// 副标题，例：正在处理音频文件...
  final String? subtitle;

  /// 百分比（0-100），驱动进度条。
  final double percent;

  /// 已完成的文件数量（可选，用于左下角显示）。
  final int? transferredCount;

  /// 总文件数量（可选，用于左下角显示）。
  final int? totalCount;

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
        border: Border.all(
          color: const Color(0xFFEAEAEA),
          width: 1,
        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.description,
                      color: Color(0xFF2F80ED),
                      size: 20,
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F80ED),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: const Color(0xFF121212),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          '${clamped.toStringAsFixed(0)}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF2F80ED),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8D8D8D),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
          if (transferredCount != null && totalCount != null) ...[
            const SizedBox(height: 10),
            Text(
              '$transferredCount/$totalCount',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF7A7A7A),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
