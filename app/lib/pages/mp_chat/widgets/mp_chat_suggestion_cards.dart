import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// 聊天建议卡片组件
/// 显示两个可点击的建议卡片：今天我应该怎么做？和我昨天做了什么？
class MPChatSuggestionCards extends StatelessWidget {
  /// 点击"今天我应该怎么做？"的回调
  final VoidCallback? onTodayTap;

  /// 点击"我昨天做了什么？"的回调
  final VoidCallback? onYesterdayTap;

  const MPChatSuggestionCards({
    super.key,
    this.onTodayTap,
    this.onYesterdayTap,
  });

  @override
  Widget build(BuildContext context) {
    const cardWidth = 160.0;
    const cardHeight = 80.0;
    const spacing = 12.0;
    const horizontalPadding = 16.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          _buildCard(
            context: context,
            icon: FontAwesomeIcons.lightbulb,
            text: '今天我应该怎么做？',
            color: const Color(0xFFFFE066), // 黄色
            iconColor: const Color(0xFFFFA500), // 橙黄色
            textColor: const Color(0xFFFFA500), // 橙黄色
            onTap: onTodayTap,
            width: cardWidth,
            height: cardHeight,
          ),
          const SizedBox(width: spacing),
          _buildCard(
            context: context,
            icon: FontAwesomeIcons.circleQuestion,
            text: '我昨天做了什么？',
            color: const Color(0xFF66B3FF), // 蓝色
            iconColor: const Color(0xFF0066CC), // 深蓝色
            textColor: const Color(0xFF0066CC), // 深蓝色
            onTap: onYesterdayTap,
            width: cardWidth,
            height: cardHeight,
          ),
        ],
      ),
    );
  }

  /// 构建单个卡片
  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Color color,
    required Color iconColor,
    required Color textColor,
    required VoidCallback? onTap,
    required double width,
    required double height,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          children: [
            FaIcon(
              icon,
              color: iconColor,
              size: 24.0,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
