import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuickQuestionsCard extends StatelessWidget {
  final Function(String)? onQuestionSelected;
  final List<String> questions;

  static const List<String> _defaultQuestions = [
    '帮我总结一下近半年我们的沟通情况',
    '我们讨论的最重要三个话题',
    '前几次讨论我们还有没有没解决的问题',
  ];

  const QuickQuestionsCard({
    super.key,
    this.onQuestionSelected,
    List<String>? questions,
  }) : questions = questions ?? _defaultQuestions;

  void _handleQuestionTap(String question) {
    HapticFeedback.mediumImpact();
    onQuestionSelected?.call(question);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '快速提问',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // 问题卡片列表
        ...questions.map((question) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _QuestionItem(
                question: question,
                onTap: () => _handleQuestionTap(question),
              ),
            )),
      ],
    );
  }
}

class _QuestionItem extends StatelessWidget {
  final String question;
  final VoidCallback onTap;

  const _QuestionItem({
    required this.question,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          question,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
