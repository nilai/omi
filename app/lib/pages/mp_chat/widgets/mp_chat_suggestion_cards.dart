import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// 聊天建议卡片组件
/// 根据提供的问题列表动态显示可点击的建议卡片
class MPChatSuggestionCards extends StatelessWidget {
  /// 问题列表
  final List<String> questions;

  /// 点击问题的回调，参数为问题文本
  final Function(String)? onQuestionTap;

  /// 点击"今天我应该怎么做？"的回调（已废弃，保留用于向后兼容）
  @Deprecated('使用 onQuestionTap 代替')
  final VoidCallback? onTodayTap;

  /// 点击"我昨天做了什么？"的回调（已废弃，保留用于向后兼容）
  @Deprecated('使用 onQuestionTap 代替')
  final VoidCallback? onYesterdayTap;

  const MPChatSuggestionCards({
    super.key,
    this.questions = const [],
    this.onQuestionTap,
    this.onTodayTap,
    this.onYesterdayTap,
  });

  @override
  Widget build(BuildContext context) {
    const cardWidth = 160.0;
    const cardHeight = 80.0;
    const spacing = 12.0;
    const horizontalPadding = 16.0;

    // 如果没有问题列表，使用旧的逻辑（向后兼容）
    if (questions.isEmpty) {
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

    // 根据问题列表动态生成卡片
    final cardColors = [
      const Color(0xFFFFE066), // 黄色
      const Color(0xFF66B3FF), // 蓝色
      const Color(0xFF66FF99), // 绿色
      const Color(0xFFFF99CC), // 粉色
    ];

    final iconColors = [
      const Color(0xFFFFA500), // 橙黄色
      const Color(0xFF0066CC), // 深蓝色
      const Color(0xFF00CC66), // 深绿色
      const Color(0xFFFF66CC), // 深粉色
    ];

    final icons = [
      FontAwesomeIcons.lightbulb,
      FontAwesomeIcons.circleQuestion,
      FontAwesomeIcons.star,
      FontAwesomeIcons.heart,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          return Row(
            children: [
              _buildCard(
                context: context,
                icon: icons[index % icons.length],
                text: question,
                color: cardColors[index % cardColors.length],
                iconColor: iconColors[index % iconColors.length],
                textColor: iconColors[index % iconColors.length],
                onTap: () {
                  if (onQuestionTap != null) {
                    onQuestionTap!(question);
                  }
                },
                width: cardWidth,
                height: cardHeight,
              ),
              if (index < questions.length - 1) const SizedBox(width: spacing),
            ],
          );
        }).toList(),
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
