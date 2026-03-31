import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/common/mp_voice_text_input.dart';
import 'package:omi/tab/askai/mp_ask_ai_chat_cubit.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

class MPAskAIChatPage extends StatelessWidget {
  const MPAskAIChatPage({
    super.key,
    required this.aboutText,
    this.conversationId,
    this.suggestedQuestions = const <String>[],
  });

  final String aboutText;
  final String? conversationId;
  final List<String> suggestedQuestions;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPAskAIChatCubit>(
      create: (_) => MPAskAIChatCubit(
        aboutText: aboutText,
        conversationId: conversationId,
        suggestedQuestions: suggestedQuestions,
      )..initData(),
      child: const _MPAskAIChatView(),
    );
  }
}

class _MPAskAIChatView extends StatelessWidget {
  const _MPAskAIChatView();

  void _onSubmit(BuildContext context, MPVoiceTextInputResult result) {
    context.read<MPAskAIChatCubit>().sendMessage(result.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _ChatTopBar(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: BlocBuilder<MPAskAIChatCubit, MPAskAIChatState>(
                builder: (BuildContext context, MPAskAIChatState state) {
                  if (state.phase == MPAskAIChatPhase.loading) {
                    return const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (state.phase == MPAskAIChatPhase.error) {
                    return Center(
                      child: Text(
                        state.errorMessage ?? '加载失败',
                        style: OmiTextStyle.create(
                          color: secondTextColor,
                          fontSize: OmiFontSize.t5_14,
                          fontWeight: OmiFontWeight.regular,
                        ),
                      ),
                    );
                  }
                  return _ChatBody(state: state);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F2),
                border: Border(top: BorderSide(color: Color(0xFFE8E8E8))),
              ),
              child: MPVoiceTextInput(
                hintText: 'Ask AI anything about this memory...',
                onSubmitted: (MPVoiceTextInputResult result) =>
                    _onSubmit(context, result),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTopBar extends StatelessWidget {
  const _ChatTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: blueTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Ask AI',
              textAlign: TextAlign.center,
              style: OmiTextStyle.create(
                color: mainTextColor,
                fontSize: OmiFontSize.t8_17,
                fontWeight: OmiFontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _ChatBody extends StatelessWidget {
  const _ChatBody({required this.state});

  final MPAskAIChatState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            color: const Color(0xFFDFEAF5),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.auto_awesome_outlined,
                  size: 14,
                  color: blueTextColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'About: ${state.aboutText}',
                    style: OmiTextStyle.create(
                      color: mainTextColor,
                      fontSize: OmiFontSize.t6_15,
                      fontWeight: OmiFontWeight.regular,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.hasMessages)
            _MessageList(messages: state.messages)
          else
            _SuggestedQuestions(questions: state.suggestedQuestions),
        ],
      ),
    );
  }
}

class _SuggestedQuestions extends StatelessWidget {
  const _SuggestedQuestions({required this.questions});

  final List<String> questions;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.auto_awesome_outlined,
                size: 15,
                color: blueTextColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Suggested Questions',
                style: OmiTextStyle.create(
                  color: mainTextColor,
                  fontSize: OmiFontSize.t11_20,
                  fontWeight: OmiFontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...questions.map(
            (String question) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: () => context.read<MPAskAIChatCubit>().sendMessage(question),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '•',
                      style: OmiTextStyle.create(
                        color: secondTextColor,
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.regular,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question,
                        style: OmiTextStyle.create(
                          color: blueTextColor,
                          fontSize: OmiFontSize.t8_17,
                          fontWeight: OmiFontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages});

  final List<MPAskAIChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: messages.map((MPAskAIChatMessage message) {
          if (message.role == MPAskAIMessageRole.user) {
            return Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: const BoxConstraints(maxWidth: 280),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E7BEA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message.content,
                  style: OmiTextStyle.create(
                    color: Colors.white,
                    fontSize: OmiFontSize.t8_17,
                    fontWeight: OmiFontWeight.medium,
                  ),
                ),
              ),
            );
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.auto_awesome_outlined,
                      size: 14,
                      color: greenTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI',
                      style: OmiTextStyle.create(
                        color: secondTextColor,
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.medium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message.content,
                  style: OmiTextStyle.create(
                    color: mainTextColor,
                    fontSize: OmiFontSize.t8_17,
                    fontWeight: OmiFontWeight.regular,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
