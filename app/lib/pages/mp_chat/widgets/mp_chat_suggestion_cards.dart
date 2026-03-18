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
    const spacing = 12.0;
    const horizontalPadding = 16.0;
    const verticalSpacing = 12.0;

    // 如果没有问题列表，使用旧的逻辑（向后兼容）
    if (questions.isEmpty) {
      return const SizedBox.shrink();
    }

    // 图标列表
    final icons = [
      FontAwesomeIcons.magnifyingGlass,
      FontAwesomeIcons.lightbulb,
      FontAwesomeIcons.star,
      FontAwesomeIcons.list,
    ];

    // 限制最多显示4个（2行x2列）
    final displayQuestions = questions.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 第一行
          Row(
            children: [
              Expanded(
                child: _buildCard(
                  context: context,
                  icon: icons[0 % icons.length],
                  text: displayQuestions.isNotEmpty ? displayQuestions[0] : '',
                  onTap: displayQuestions.isNotEmpty
                      ? () {
                          if (onQuestionTap != null) {
                            onQuestionTap!(displayQuestions[0]);
                          }
                        }
                      : null,
                ),
              ),
              if (displayQuestions.length > 1) ...[
                const SizedBox(width: spacing),
                Expanded(
                  child: _buildCard(
                    context: context,
                    icon: icons[1 % icons.length],
                    text: displayQuestions[1],
                    onTap: () {
                      if (onQuestionTap != null) {
                        onQuestionTap!(displayQuestions[1]);
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
          // 第二行（如果存在）
          if (displayQuestions.length > 2) ...[
            const SizedBox(height: verticalSpacing),
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    context: context,
                    icon: icons[2 % icons.length],
                    text: displayQuestions[2],
                    onTap: () {
                      if (onQuestionTap != null) {
                        onQuestionTap!(displayQuestions[2]);
                      }
                    },
                  ),
                ),
                if (displayQuestions.length > 3) ...[
                  const SizedBox(width: spacing),
                  Expanded(
                    child: _buildCard(
                      context: context,
                      icon: icons[3 % icons.length],
                      text: displayQuestions[3],
                      onTap: () {
                        if (onQuestionTap != null) {
                          onQuestionTap!(displayQuestions[3]);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 构建单个卡片
  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    // 统一的背景色（浅灰色）
    const backgroundColor = Color(0xFFF5F5F5);
    // 统一的文字颜色
    const textColor = Color(0xFF333333);
    // 统一的图标颜色
    const iconColor = Color(0xFF666666);
    // 统一的字号
    const fontSize = 14.0;
    // 统一的卡片高度
    const cardHeight = 60.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          children: [
            FaIcon(
              icon,
              color: iconColor,
              size: 16.0,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
