import 'package:flutter/material.dart';

import '../../../../pages/mp_home/provider/mp_page_provider.dart';

/// 合并记忆列表项组件
/// 显示记忆记录信息，支持选中状态
class MPMergeMemoryItem extends StatelessWidget {
  /// 记忆项数据
  final MPMemoryItem item;

  /// 是否选中
  final bool isSelected;

  /// 点击回调
  final VoidCallback onTap;

  /// 构造函数
  /// @param item 记忆项数据
  /// @param isSelected 是否选中
  /// @param onTap 点击回调
  const MPMergeMemoryItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF306CFF),
                  width: 2,
                )
              : null,
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(25, 0, 0, 0),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 复选框
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF306CFF) : const Color(0xFFE5E5E5),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF306CFF) : Colors.white,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // 内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日期和标签
                  Row(
                    children: [
                      Text(
                        item.dateText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6D6D6D),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (item.tagText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.tagColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.tagText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 标题
                  Text(
                    item.headerText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 时间和时长
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Color(0xFFB2B2B2),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.timeText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7D7D7D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (item.secondsText != null && item.secondsText!.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.play_circle_outline,
                          size: 14,
                          color: Color(0xFF7D7D7D),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.secondsText!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7D7D7D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // 描述
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      item.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C2C2C),
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

