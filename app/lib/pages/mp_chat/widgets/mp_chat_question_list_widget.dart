import 'package:flutter/material.dart';

/// 聊天问题列表组件
/// 显示一个可滚动的垂直问题列表，每个问题卡片支持点击
class MPChatQuestionListWidget extends StatelessWidget {
  /// 问题文本列表，由外部传入，不可修改
  final List<String> questions;

  /// 点击问题的回调，参数为被点击的问题文本
  final Function(String)? onQuestionTap;

  /// 卡片之间的垂直间距
  final double itemSpacing;

  /// 水平内边距
  final double horizontalPadding;

  const MPChatQuestionListWidget({
    super.key,
    required this.questions,
    this.onQuestionTap,
    this.itemSpacing = 12.0,
    this.horizontalPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemCount: questions.length,
      separatorBuilder: (context, index) => SizedBox(height: itemSpacing),
      itemBuilder: (context, index) {
        final question = questions[index];
        return _buildQuestionCard(
          context: context,
          text: question,
          onTap: () {
            if (onQuestionTap != null) {
              onQuestionTap!(question);
            }
          },
        );
      },
    );
  }

  /// 构建单个问题卡片
  /// 
  /// [context] 构建上下文
  /// [text] 问题文本，不可修改
  /// [onTap] 点击回调
  Widget _buildQuestionCard({
    required BuildContext context,
    required String text,
    required VoidCallback onTap,
  }) {
    // 统一的背景色（浅灰色）
    const backgroundColor = Color(0xFFF5F5F5);
    // 统一的文字颜色
    const textColor = Color(0xFF333333);
    // 统一的字号
    const fontSize = 14.0;
    // 卡片最小高度
    const minCardHeight = 48.0;
    // 卡片圆角
    const borderRadius = 12.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: minCardHeight),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Text(
          text,
          style: const TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

