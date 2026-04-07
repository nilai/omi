import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../common/mp_voice_text_input.dart';
import '../../tab/askai/mp_ask_ai_chat_cubit.dart';
import '../../utils/omi_color_utils.dart';
import '../../utils/omi_font_utils.dart';
import '../../utils/omi_textstyle.dart';

class MPAskAIChatPage extends StatelessWidget {
  const MPAskAIChatPage({
    super.key,
    required this.aboutText,
    this.conversationId,
    this.suggestedQuestions = const <String>[],
    this.initialMessage,
  });

  final String aboutText;
  final String? conversationId;
  final List<String> suggestedQuestions;
  final String? initialMessage;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPAskAIChatCubit>(
      create: (_) => MPAskAIChatCubit(
        aboutText: aboutText,
        conversationId: conversationId,
        suggestedQuestions: suggestedQuestions,
      )..initData(),
      child: _MPAskAIChatView(initialMessage: initialMessage),
    );
  }
}

class _MPAskAIChatView extends StatefulWidget {
  const _MPAskAIChatView({this.initialMessage});

  final String? initialMessage;

  @override
  State<_MPAskAIChatView> createState() => _MPAskAIChatViewState();
}

class _MPAskAIChatViewState extends State<_MPAskAIChatView> {
  bool _hasAutoSentInitialMessage = false;
  late final ScrollController _scrollController;
  int _lastMessageCount = 0;
  bool _lastIsSending = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onSubmit(BuildContext context, MPVoiceTextInputResult result) {
    context.read<MPAskAIChatCubit>().sendMessage(result.text);
  }

  void _tryAutoSendInitialMessage(MPAskAIChatState state) {
    if (_hasAutoSentInitialMessage) return;
    if (state.phase != MPAskAIChatPhase.loaded) return;
    final String text = widget.initialMessage?.trim() ?? '';
    if (text.isEmpty) return;
    _hasAutoSentInitialMessage = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MPAskAIChatCubit>().sendMessage(text);
    });
  }

  void _maybeAutoScroll(MPAskAIChatState state) {
    final bool shouldScroll =
        state.messages.length != _lastMessageCount ||
        state.isSending != _lastIsSending;
    _lastMessageCount = state.messages.length;
    _lastIsSending = state.isSending;
    if (!shouldScroll) return;
    _scrollToBottom(animated: true);
  }

  void _scrollToBottom({required bool animated}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final double max = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      _scrollController.jumpTo(max);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _ChatTopBar(onBack: () => Navigator.of(context).maybePop()),
              Expanded(
                child: BlocConsumer<MPAskAIChatCubit, MPAskAIChatState>(
                  listener: (BuildContext context, MPAskAIChatState state) {
                    _tryAutoSendInitialMessage(state);
                    _maybeAutoScroll(state);
                  },
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
                    return _ChatBody(
                      state: state,
                      scrollController: _scrollController,
                    );
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
  const _ChatBody({
    required this.state,
    required this.scrollController,
  });

  final MPAskAIChatState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
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
          if (state.isSending)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: _MPChatWaitingIndicator(),
              ),
            ),
          if (!state.isSending && (state.errorMessage?.trim().isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                state.errorMessage!,
                style: OmiTextStyle.create(
                  color: redColor,
                  fontSize: OmiFontSize.t5_14,
                  fontWeight: OmiFontWeight.regular,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MPChatWaitingIndicator extends StatefulWidget {
  const _MPChatWaitingIndicator();

  @override
  State<_MPChatWaitingIndicator> createState() => _MPChatWaitingIndicatorState();
}

class _MPChatWaitingIndicatorState extends State<_MPChatWaitingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _opacityForDot(int index) {
    final double value = (_controller.value + index * 0.2) % 1.0;
    final double distance = (value - 0.5).abs();
    return 0.35 + (1 - distance * 2) * 0.55;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.auto_awesome_outlined,
            size: 14,
            color: Color(0xFF87D5A2),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(3, (int index) {
                  return Padding(
                    padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
                    child: _MPWaitingDot(opacity: _opacityForDot(index)),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MPWaitingDot extends StatelessWidget {
  const _MPWaitingDot({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Color(0xFF8F9098),
          shape: BoxShape.circle,
        ),
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
