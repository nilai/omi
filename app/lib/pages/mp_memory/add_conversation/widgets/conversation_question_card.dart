import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConversationQuestionCard extends StatefulWidget {
  final Function(String)? onQuestionSubmitted;
  final VoidCallback? onVoiceInput;

  const ConversationQuestionCard({
    super.key,
    this.onQuestionSubmitted,
    this.onVoiceInput,
  });

  @override
  State<ConversationQuestionCard> createState() => _ConversationQuestionCardState();
}

class _ConversationQuestionCardState extends State<ConversationQuestionCard> {
  final TextEditingController _questionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _questionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final question = _questionController.text.trim();
    if (question.isNotEmpty) {
      HapticFeedback.mediumImpact();
      widget.onQuestionSubmitted?.call(question);
      _questionController.clear();
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            const Center(
              child: Text(
                '基于你和叶成功的对话记录提问',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(
              color: Colors.grey,
              height: 1,
              thickness: 1,
            ),
            const SizedBox(height: 12),
            // 输入框和按钮行
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _questionController,
              builder: (context, value, child) {
                final hasText = value.text.trim().isNotEmpty;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 输入框
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: TextField(
                          controller: _questionController,
                          focusNode: _focusNode,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            hintText: '输入你的问题...',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 麦克风按钮
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onVoiceInput?.call();
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 发送按钮
                    GestureDetector(
                      onTap: hasText ? _handleSend : null,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: hasText ? Colors.grey.shade400 : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: hasText ? Colors.white : Colors.grey.shade500,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

