import 'package:flutter/material.dart';

/** 顶部导入 SD 卡音频的进度卡片。 */
class MPHomeTopImportSdAudioWidget extends StatefulWidget {
  /** 标题文案，示例：正在从 MemoPin 传输录音至 APP... */
  final String title;

  /** 进度百分比（0-100）。 */
  final double percent;

  /** 速度文案（可选），示例：0.00KB/S。 */
  final String? speedText;

  /** 已完成数量（可选），用于左下角显示。 */
  final int? transferredCount;

  /** 总数量（可选），用于左下角显示。 */
  final int? totalCount;

  /** 进度条颜色。 */
  final Color progressColor;

  const MPHomeTopImportSdAudioWidget({
    super.key,
    required this.title,
    required this.percent,
    this.speedText,
    this.transferredCount,
    this.totalCount,
    this.progressColor = const Color(0xFF2F80ED),
  });

  @override
  State<MPHomeTopImportSdAudioWidget> createState() => _MPHomeTopImportSdAudioWidgetState();
}

class _MPHomeTopImportSdAudioWidgetState extends State<MPHomeTopImportSdAudioWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = widget.percent.clamp(0, 100);
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(20, 0, 0, 0),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: RotationTransition(
                  turns: _rotationController,
                  child: const Icon(
                    Icons.autorenew,
                    color: Color(0xFF2F80ED),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF121212),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.speedText != null && widget.speedText!.isNotEmpty)
                      Text(
                        widget.speedText!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8D8D8D),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
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
                valueColor: AlwaysStoppedAnimation<Color>(widget.progressColor),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.transferredCount != null && widget.totalCount != null
                      ? '${widget.transferredCount! + 1}/${widget.totalCount}'
                      : '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF7A7A7A),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${clamped.toStringAsFixed(0)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF2F80ED),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
