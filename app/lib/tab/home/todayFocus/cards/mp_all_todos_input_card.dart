import 'package:flutter/material.dart';
import 'package:memo_pin/common/mp_todo_voice_input.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

/// 「ALL TO DOS」标题 + 白底圆角输入条（占位文案 + 右侧语音，逻辑复用 [MPTodoVoiceInput]）。
class MPAllTodosInputCard extends StatelessWidget {
  const MPAllTodosInputCard({
    super.key,
    this.headerTitle = 'ALL TO DOS',
    this.hintText = 'Add something you need to do',
    this.initialText = '',
    this.onSubmitted,
    this.onChanged,
    this.transcribeDelay = const Duration(milliseconds: 1400),
  });

  final String headerTitle;
  final String hintText;
  final String initialText;
  final ValueChanged<MPTodoVoiceInputResult>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Duration transcribeDelay;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          headerTitle,
          style: OmiTextStyle.create(
            fontSize: OmiFontSize.t5_14,
            fontWeight: OmiFontWeight.bold,
            color: mainTextColor,
            letterSpacing: 0.6,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: MPTodoVoiceInput(
              hintText: hintText,
              initialText: initialText,
              onSubmitted: onSubmitted,
              onChanged: onChanged,
              transcribeDelay: transcribeDelay,
              showOutline: false,
            ),
          ),
        ),
      ],
    );
  }
}
