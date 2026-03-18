import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../mp_chat_helper.dart';

/// 记忆卡片组件
/// 显示记忆附件信息，包含图标、标题和关闭按钮
class MPChatMemoryCard extends StatelessWidget {
  /// 点击卡片的回调
  final VoidCallback? onTap;

  /// 点击关闭按钮的回调
  final VoidCallback? onCloseTap;

  const MPChatMemoryCard({
    super.key,
    this.onTap,
    this.onCloseTap,
  });

  @override
  Widget build(BuildContext context) {
    final memory = MPChatHelper.instance.memory;
    if (memory == null) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左侧：图标容器
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE), // 浅蓝色背景
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.fileLines,
                  color: Color(0xFF1E40AF), // 深蓝色图标
                  size: 24.0,
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            // 中间：文字内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 第一行：附件 : 记忆
                  const Text(
                    '附件 : 记忆',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9CA3AF), // 浅灰色
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  // 第二行：标题（粗黑）
                  Text(
                    memory.title,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700, // 粗黑
                      color: Color(0xFF1F2937), // 深灰色/黑色
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            // 右侧：关闭按钮
            GestureDetector(
              onTap: onCloseTap,
              child: Container(
                width: 24.0,
                height: 24.0,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close,
                  size: 18.0,
                  color: Color(0xFF9CA3AF), // 浅灰色
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
