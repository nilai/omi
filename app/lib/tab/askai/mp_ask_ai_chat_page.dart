import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/mp_voice_text_input.dart';
import '../../generated/assets.dart';
import '../../tab/askai/mp_ask_ai_chat_cubit.dart';
import '../../utils/omi_color_utils.dart';
import '../../utils/omi_font_utils.dart';
import '../../utils/omi_image_loader.dart';
import '../../utils/omi_textstyle.dart';

MarkdownStyleSheet? _mpAskAIChatMarkdownStyleCache;

MarkdownStyleSheet _mpAskAIChatMarkdownStyle() {
  return _mpAskAIChatMarkdownStyleCache ??= _buildMpAskAIChatMarkdownStyle();
}

MarkdownStyleSheet _buildMpAskAIChatMarkdownStyle() {
  TextStyle base({
    required double size,
    FontWeight? weight,
    Color? color,
    double height = 1.4,
    FontStyle? fontStyle,
    TextDecoration? decoration,
  }) {
    return OmiTextStyle.create(
      fontSize: size,
      fontWeight: weight ?? OmiFontWeight.regular,
      color: color ?? mainTextColor,
      height: height,
      fontStyle: fontStyle,
      decoration: decoration,
    );
  }

  return MarkdownStyleSheet(
    p: base(size: OmiFontSize.t8_17),
    pPadding: EdgeInsets.zero,
    h1: base(size: OmiFontSize.t11_20, weight: OmiFontWeight.bold, color: mainTextColor),
    h1Padding: const EdgeInsets.only(top: 4, bottom: 8),
    h2: base(size: OmiFontSize.t8_17, weight: OmiFontWeight.bold, color: mainTextColor),
    h2Padding: const EdgeInsets.only(top: 2, bottom: 6),
    h3: base(size: OmiFontSize.t6_15, weight: OmiFontWeight.medium, color: mainTextColor),
    h3Padding: const EdgeInsets.only(top: 2, bottom: 4),
    strong: base(size: OmiFontSize.t8_17, weight: OmiFontWeight.bold),
    em: base(size: OmiFontSize.t8_17, fontStyle: FontStyle.italic),
    a: base(size: OmiFontSize.t8_17, color: blueTextColor, decoration: TextDecoration.underline),
    code: base(
      size: OmiFontSize.t5_14,
      color: mainTextColor,
    ).copyWith(backgroundColor: pageColor, fontFamily: 'monospace'),
    blockquote: base(size: OmiFontSize.t8_17, color: secondTextColor),
    blockquotePadding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: secondTextColor.withValues(alpha: 0.6), width: 3)),
    ),
    blockSpacing: 8,
    listIndent: 22,
    listBullet: base(size: OmiFontSize.t8_17),
    listBulletPadding: const EdgeInsets.only(right: 6),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: lineColor, width: 1)),
    ),
    codeblockPadding: const EdgeInsets.all(10),
    codeblockDecoration: BoxDecoration(color: pageColor, borderRadius: BorderRadius.circular(8)),
  );
}

Future<void> _mpAskAIChatTapMarkdownLink(String? href) async {
  if (href == null || href.isEmpty) return;
  final Uri? uri = Uri.tryParse(href);
  if (uri == null) return;
  if (!await canLaunchUrl(uri)) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

enum MPAskAIChatType { insight, memory, expert, template, speaker, normal }

class MPAskAIChatPage extends StatelessWidget {
  const MPAskAIChatPage({
    super.key,
    required this.aboutText,
    this.conversationId,
    this.suggestedQuestions = const <String>[],
    this.initialMessage,
    this.type = MPAskAIChatType.normal,
    this.chatTypeId,
  });

  final String aboutText;
  final String? conversationId;
  final List<String> suggestedQuestions;
  final String? initialMessage;
  final MPAskAIChatType type;
  final String? chatTypeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPAskAIChatCubit>(
      create: (_) => MPAskAIChatCubit(
        aboutText: aboutText,
        conversationId: conversationId,
        suggestedQuestions: suggestedQuestions,
        type: type,
        chatTypeId: chatTypeId,
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

  /// 用于检测流式回复：仅 [messages.length] / [isSending] 不变时正文仍在变长。
  int _lastMessagesContentLength = 0;

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
    final int contentLen = state.messages.fold<int>(0, (int sum, MPAskAIChatMessage m) => sum + m.content.length);
    final bool messageCountChanged = state.messages.length != _lastMessageCount;
    final bool sendingChanged = state.isSending != _lastIsSending;
    final bool contentGrowing = contentLen != _lastMessagesContentLength;

    final int prevCount = _lastMessageCount;
    _lastMessageCount = state.messages.length;
    _lastIsSending = state.isSending;
    _lastMessagesContentLength = contentLen;

    if (!messageCountChanged && !sendingChanged && !contentGrowing) {
      return;
    }

    /// 用户主动上滑阅读上方内容时，不因流式增量把视图拽回底部。
    final bool newUserBubble =
        messageCountChanged &&
        state.messages.length > prevCount &&
        state.messages.isNotEmpty &&
        state.messages.last.role == MPAskAIMessageRole.user;
    final bool streamJustEnded = sendingChanged && !state.isSending;
    if (!newUserBubble && !_isScrollNearBottom() && (contentGrowing || streamJustEnded)) {
      return;
    }

    /// 流式输出帧率高，用 [jumpTo] 避免动画积压；结束后再用动画收一次尾。
    _scrollToBottom(animated: !state.isSending);
  }

  /// [reverse: true] 列表底部为最新消息，首屏只构建可见区域。
  bool _isScrollNearBottom() {
    if (!_scrollController.hasClients) {
      return true;
    }
    final ScrollPosition pos = _scrollController.position;
    if (!pos.hasPixels) {
      return true;
    }
    const double threshold = 160;
    return pos.pixels <= threshold;
  }

  void _scrollToBottom({required bool animated}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      _scrollController.jumpTo(0);
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
                        child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    if (state.phase == MPAskAIChatPhase.error) {
                      return Center(
                        child: Text(
                          state.errorMessage ?? 'Couldn\'t load.',
                          style: OmiTextStyle.create(
                            color: secondTextColor,
                            fontSize: OmiFontSize.t5_14,
                            fontWeight: OmiFontWeight.regular,
                          ),
                        ),
                      );
                    }
                    return _ChatBody(state: state, scrollController: _scrollController);
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
                  hintText: 'Ask about your memories...',
                  onSubmitted: (MPVoiceTextInputResult result) => _onSubmit(context, result),
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
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: blueTextColor),
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
  const _ChatBody({required this.state, required this.scrollController});

  final MPAskAIChatState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          color: const Color(0xFFDFEAF5),
          child: Row(
            children: <Widget>[
              const Icon(Icons.auto_awesome_outlined, size: 14, color: blueTextColor),
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
        Expanded(
          child: state.hasMessages
              ? _MessageList(
                  messages: state.messages,
                  scrollController: scrollController,
                )
              : SingleChildScrollView(
                  controller: scrollController,
                  child: _SuggestedQuestions(questions: state.suggestedQuestions),
                ),
        ),
        if (state.isSending)
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Align(alignment: Alignment.centerLeft, child: _MPChatWaitingIndicator()),
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
        const SizedBox(height: 10),
      ],
    );
  }
}

class _MPChatWaitingIndicator extends StatefulWidget {
  const _MPChatWaitingIndicator();

  @override
  State<_MPChatWaitingIndicator> createState() => _MPChatWaitingIndicatorState();
}

class _MPChatWaitingIndicatorState extends State<_MPChatWaitingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
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
          const Icon(Icons.auto_awesome_outlined, size: 14, color: Color(0xFF87D5A2)),
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
        decoration: const BoxDecoration(color: Color(0xFF8F9098), shape: BoxShape.circle),
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
              const Icon(Icons.auto_awesome_outlined, size: 15, color: blueTextColor),
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
  const _MessageList({
    required this.messages,
    required this.scrollController,
  });

  final List<MPAskAIChatMessage> messages;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      cacheExtent: 360,
      addAutomaticKeepAlives: false,
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int index) {
        final MPAskAIChatMessage message = messages[messages.length - 1 - index];
        return RepaintBoundary(
          child: _ChatMessageBubble(
            key: ValueKey<String>(message.id),
            message: message,
            markdownDelay: Duration(milliseconds: index * 40),
          ),
        );
      },
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    super.key,
    required this.message,
    required this.markdownDelay,
  });

  final MPAskAIChatMessage message;
  final Duration markdownDelay;

  @override
  Widget build(BuildContext context) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
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
                  const Icon(Icons.auto_awesome_outlined, size: 14, color: greenTextColor),
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
              if (message.content.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                _MPAskAIChatMarkdownContent(
                  content: message.content,
                  renderDelay: markdownDelay,
                ),
              ],
            ],
          ),
        ),
        if (message.content.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          _MPAskAIChatCopyButton(text: message.content),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _MPAskAIChatCopyButton extends StatefulWidget {
  const _MPAskAIChatCopyButton({required this.text});

  final String text;

  @override
  State<_MPAskAIChatCopyButton> createState() => _MPAskAIChatCopyButtonState();
}

class _MPAskAIChatCopyButtonState extends State<_MPAskAIChatCopyButton> {
  static const Duration _copiedResetDelay = Duration(seconds: 3);

  bool _copied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _onTap() async {
    final String text = widget.text.trim();
    if (text.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    _resetTimer?.cancel();
    setState(() => _copied = true);
    _resetTimer = Timer(_copiedResetDelay, () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: OmiImageLoader.localImg(
          _copied ? Assets.mpChatCheck : Assets.mpChatCopy,
          width: 16,
          height: 16,
          color: secondTextColor,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _MPAskAIChatMarkdownContent extends StatefulWidget {
  const _MPAskAIChatMarkdownContent({
    required this.content,
    this.renderDelay = Duration.zero,
  });

  final String content;
  final Duration renderDelay;

  @override
  State<_MPAskAIChatMarkdownContent> createState() => _MPAskAIChatMarkdownContentState();
}

class _MPAskAIChatMarkdownContentState extends State<_MPAskAIChatMarkdownContent> {
  bool _showMarkdown = false;
  Timer? _renderTimer;

  @override
  void initState() {
    super.initState();
    _scheduleMarkdownRender();
  }

  @override
  void didUpdateWidget(_MPAskAIChatMarkdownContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_showMarkdown) {
      return;
    }
    if (oldWidget.renderDelay != widget.renderDelay) {
      _scheduleMarkdownRender();
    }
  }

  void _scheduleMarkdownRender() {
    _renderTimer?.cancel();
    if (widget.renderDelay == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _showMarkdown = true);
        }
      });
      return;
    }
    _renderTimer = Timer(widget.renderDelay, () {
      if (mounted) {
        setState(() => _showMarkdown = true);
      }
    });
  }

  @override
  void dispose() {
    _renderTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showMarkdown) {
      return Text(
        widget.content,
        style: OmiTextStyle.create(
          color: mainTextColor,
          fontSize: OmiFontSize.t8_17,
          fontWeight: OmiFontWeight.regular,
          height: 1.4,
        ),
      );
    }

    return MarkdownBody(
      data: widget.content,
      selectable: true,
      shrinkWrap: true,
      styleSheet: _mpAskAIChatMarkdownStyle(),
      onTapLink: (String text, String? href, String title) {
        unawaited(_mpAskAIChatTapMarkdownLink(href));
      },
    );
  }
}
