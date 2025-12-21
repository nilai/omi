import 'package:flutter/material.dart';

/// 任务提醒卡片，支持多处自定义以适配不同业务数据。
class MPHomeCard extends StatefulWidget {
  const MPHomeCard({
    super.key,
    required this.dateText,
    required this.headerText,
    required this.timeText,
    this.secondsText,
    this.tagText = '任务提醒',
    this.tagBackgroundColor = const Color(0xFFF4B95A),
    this.description,
    this.onShare,
    this.onDelete,
    this.onViewDetail,
  });

  /// 左上角日期文本（例：07-22）。
  final String dateText;

  /// 顶部标签文字（例：任务提醒），允许自定义背景色。
  final String tagText;

  /// 标签背景色，可根据不同业务类型传入不同颜色。
  final Color tagBackgroundColor;

  /// 第二行主标题文本。
  final String headerText;

  /// 第三行时间文本。
  final String timeText;

  /// 时间后的秒数文本（例：11s），可选。
  final String? secondsText;

  /// 中间正文，最多展示三行，缺省则隐藏。
  final String? description;

  /// 分享回调。
  final VoidCallback? onShare;

  /// 删除回调。
  final VoidCallback? onDelete;

  /// "查看详情"点击回调（文案不可修改）。
  final VoidCallback? onViewDetail;

  @override
  State<MPHomeCard> createState() => _MPHomeCardState();
}

class _MPHomeCardState extends State<MPHomeCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => widget.onViewDetail?.call(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(25, 0, 0, 0),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.dateText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6D6D6D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Visibility(
                  visible: widget.tagText.isNotEmpty,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.tagBackgroundColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.tagText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF5F5F5F),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(
                      color: Color(0xFFE5E5E5),
                      width: 1,
                    ),
                  ),
                  elevation: 4,
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'share',
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.share_outlined,
                            color: Color(0xFF111111),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '分享',
                            style: TextStyle(
                              color: Color(0xFF111111),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFFF0000),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '删除',
                            style: TextStyle(
                              color: Color(0xFFFF0000),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (String value) {
                    if (value == 'share') {
                      widget.onShare?.call();
                    } else if (value == 'delete') {
                      widget.onDelete?.call();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.headerText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF111111),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFFB2B2B2), size: 14),
                const SizedBox(width: 4),
                Text(
                  widget.timeText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF7D7D7D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.secondsText != null && widget.secondsText!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.play_circle_outline, color: Color(0xFF7D7D7D), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    widget.secondsText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7D7D7D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            if (widget.description != null && widget.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                widget.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF2C2C2C),
                  height: 1.25,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => widget.onViewDetail?.call(),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  '查看详情',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF2962FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
