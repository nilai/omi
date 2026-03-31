import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/common/mp_voice_text_input.dart';
import 'package:omi/tab/askai/mp_ask_ai_cubit.dart';
import 'package:omi/utils/mp_toast_utils.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

class OmiAskAIPage extends StatelessWidget {
  const OmiAskAIPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPAskAICubit>(
      create: (_) => MPAskAICubit(),
      child: const _OmiAskAIView(),
    );
  }
}

class _OmiAskAIView extends StatelessWidget {
  const _OmiAskAIView();

  void _onTapTopRightAction(BuildContext context) {
    MPToastUtils.showFeatureComingSoon(context: context);
  }

  void _onTapModule(BuildContext context, MPAskAIModule module) {
    context.read<MPAskAICubit>().selectModule(module);
  }

  void _onSubmitInput(BuildContext context, MPVoiceTextInputResult result) {
    MPToastUtils.showFeatureComingSoon(context: context);
  }

  void _onTapQuestion(BuildContext context, String question) {
    MPToastUtils.showFeatureComingSoon(context: context);
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
          onTap: () => _onTapTopRightAction(context),
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
            fontSize: OmiFontSize.t8_17,
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
          module.subtitle,
          style: OmiTextStyle.create(
            color: mainTextColor,
            fontSize: OmiFontSize.t11_20,
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
                onTap: () => _onTapQuestion(context, question),
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
                          fontSize: OmiFontSize.t11_20,
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
        return Scaffold(
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
                    onSubmitted: (MPVoiceTextInputResult result) =>
                        _onSubmitInput(context, result),
                  ),
                ),
              ],
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
                        fontSize: OmiFontSize.t8_17,
                        fontWeight: OmiFontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      module.subtitle,
                      style: OmiTextStyle.create(
                        color: module.iconColor.withValues(alpha: 0.75),
                        fontSize: OmiFontSize.t7_16,
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
