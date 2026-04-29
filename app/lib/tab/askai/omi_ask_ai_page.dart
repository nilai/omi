import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/common/mp_system_ui_region.dart';
import 'package:memo_pin/common/mp_voice_text_input.dart';
import 'package:memo_pin/http/api/mp_chat.dart';
import 'package:memo_pin/http/schema/mp_chat.dart';
import 'package:memo_pin/tab/askai/mp_ask_ai_chat_page.dart';
import 'package:memo_pin/tab/askai/mp_ask_ai_cubit.dart';
import 'package:memo_pin/tab/askai/mp_ask_ai_conversation_list_page.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../main.dart';

class OmiAskAIPage extends StatelessWidget {
  const OmiAskAIPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPAskAICubit>(
      create: (_) => MPAskAICubit()..initData(),
      child: const _OmiAskAIView(),
    );
  }
}

class _OmiAskAIView extends StatefulWidget {
  const _OmiAskAIView();

  @override
  State<_OmiAskAIView> createState() => _OmiAskAIViewState();
}

class _OmiAskAIViewState extends State<_OmiAskAIView> {
  late final FocusNode _inputFocusNode;

  @override
  void initState() {
    super.initState();
    _inputFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    _inputFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _onTapTopRightAction(BuildContext context) async {
    context.read<MPAskAICubit>().backToOverview();
    _dismissKeyboard();
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, _, _) => const MPAskAIConversationListPage(),
        transitionsBuilder: (_, Animation<double> animation, _, Widget child) {
          final Animation<Offset> slide = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          return SlideTransition(position: slide, child: child);
        },
      ),
    );
    if (!mounted) return;
    _dismissKeyboard();
  }

  void _onTapModule(BuildContext context, MPAskAIModule module) {
    context.read<MPAskAICubit>().selectModule(module);
  }

  Future<void> _onSubmitInput(BuildContext context, MPVoiceTextInputResult result) async {
    final String text = result.text.trim();
    if (text.isEmpty) return;
    _dismissKeyboard();
    final MPGetLastConversationResponse? lastConversation = await getLastConversation(MPGetLastConversationRequest(conversationType: 0, paramId: ''));
    final String conversationId = lastConversation?.conversationId ?? '';
    final BuildContext? targetContext = context.mounted ? context : MyApp.navigatorKey.currentContext;
    // ignore: use_build_context_synchronously
    context.read<MPAskAICubit>().backToOverview();
    // ignore: use_build_context_synchronously
    await Navigator.of(targetContext!).push(
      MaterialPageRoute<void>(
        builder: (_) => MPAskAIChatPage(
          aboutText: 'Ask AI',
          suggestedQuestions: const <String>[],
          initialMessage: text,
          conversationId: conversationId,
          type: MPAskAIChatType.normal,
          chatTypeId: '',
        ),
      ),
    );
    if (!mounted) return;
    _dismissKeyboard();
  }

  Future<void> _onTapQuestion(
    BuildContext context,
    MPAskAIModule module,
    String question,
  ) async {
    
    _dismissKeyboard();
    final MPGetLastConversationResponse? lastConversation = await getLastConversation(MPGetLastConversationRequest(conversationType: 0, paramId: module.id));
    final String conversationId = lastConversation?.conversationId ?? '';
    final BuildContext? targetContext = context.mounted ? context : MyApp.navigatorKey.currentContext;
    // ignore: use_build_context_synchronously
    context.read<MPAskAICubit>().backToOverview();
    // ignore: use_build_context_synchronously
    await Navigator.of(targetContext!).push(
      MaterialPageRoute<void>(
        builder: (_) => MPAskAIChatPage(
          aboutText: 'Ask AI',
          suggestedQuestions: const <String>[],
          conversationId: conversationId,
          initialMessage: question,
          type: MPAskAIChatType.template,
          chatTypeId: module.id,
        ),
      ),
    );
    if (!mounted) return;
    _dismissKeyboard();
  }

  Widget _buildTopBar(BuildContext context, MPAskAIState state) {
    final bool enableLeftAction = !state.isOverview;
    return Row(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enableLeftAction
                ? () => context.read<MPAskAICubit>().backToOverview()
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1EFFA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_outlined,
                      size: 16,
                      color: Color(0xFF7F6FD6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Ask AI',
                    style: OmiTextStyle.create(
                      color: mainTextColor,
                      fontSize: OmiFontSize.t13_22,
                      fontWeight: OmiFontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _onTapTopRightAction(context);
          },
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.menu_rounded,
              color: secondTextColor,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewState(BuildContext context, MPAskAIState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10),
        Text(
          'Understand your memories and decide what matters',
          style: OmiTextStyle.create(
            color: secondTextColor,
            fontSize: OmiFontSize.t6_15,
            fontWeight: OmiFontWeight.regular,
          ),
        ),
        const SizedBox(height: 14),
        ...state.modules
            .take(3)
            .map(
              (MPAskAIModule module) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AskModuleCard(
                  module: module,
                  onTap: () => _onTapModule(context, module),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildQuestionState(BuildContext context, MPAskAIModule module) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10),
        Text(
          'Understand your memories and decide what matters',
          style: OmiTextStyle.create(
            color: secondTextColor,
            fontSize: OmiFontSize.t6_15,
            fontWeight: OmiFontWeight.regular,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          module.subtitle,
          style: OmiTextStyle.create(
            color: mainTextColor,
            fontSize: OmiFontSize.t8_17,
            fontWeight: OmiFontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, thickness: 1, color: lineColor),
        const SizedBox(height: 14),
        ...module.questions.map(
          (String question) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _onTapQuestion(context, module, question);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '•',
                        style: OmiTextStyle.create(
                          color: secondTextColor,
                          fontSize: OmiFontSize.t8_17,
                          fontWeight: OmiFontWeight.regular,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question,
                        style: OmiTextStyle.create(
                          color: secondTextColor,
                          fontSize: OmiFontSize.t8_17,
                          fontWeight: OmiFontWeight.regular,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MPAskAICubit, MPAskAIState>(
      builder: (BuildContext context, MPAskAIState state) {
        final MPAskAIModule? selected = state.selectedModule;
        return MPSystemUiRegion(
          topBarColor: pageColor,
          child: Scaffold(
            backgroundColor: pageColor,
            body: SafeArea(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildTopBar(context, state),
                          if (selected == null)
                            _buildOverviewState(context, state)
                          else
                            _buildQuestionState(context, selected),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    decoration: const BoxDecoration(
                      color: pageColor,
                      border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
                    ),
                    child: MPVoiceTextInput(
                      hintText: 'Ask about your memories...',
                      focusNode: _inputFocusNode,
                      autofocus: false,
                      onSubmitted: (MPVoiceTextInputResult result) =>
                          _onSubmitInput(context, result),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AskModuleCard extends StatelessWidget {
  const _AskModuleCard({
    required this.module,
    required this.onTap,
  });

  final MPAskAIModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: module.backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: module.borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(module.icon, size: 16, color: module.iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      module.title,
                      style: OmiTextStyle.create(
                        color: module.iconColor,
                        fontSize: OmiFontSize.t6_15,
                        fontWeight: OmiFontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      module.subtitle,
                      style: OmiTextStyle.create(
                        color: module.iconColor.withValues(alpha: 0.75),
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.regular,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
