import 'package:flutter/material.dart';
import 'package:omi/common/mp_voice_text_input.dart';
import 'package:omi/utils/mp_toast_utils.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

class OmiAskAIPage extends StatefulWidget {
  const OmiAskAIPage({super.key});

  @override
  State<OmiAskAIPage> createState() => _OmiAskAIPageState();
}

class _OmiAskAIPageState extends State<OmiAskAIPage> {
  static const List<_AskModule> _modules = <_AskModule>[
    _AskModule(
      id: 'recent',
      title: 'Recall recent context',
      subtitle: 'Remember what you\'ve been discussing',
      icon: Icons.history_rounded,
      iconColor: blueTextColor,
      borderColor: Color(0xFFDCE7FF),
      backgroundColor: Color(0xFFF8FBFF),
      questions: <String>[
        'What have I been working on recently?',
        'What decisions did I make this week?',
        'Who have I been talking with most?',
        'What unresolved threads should I revisit?',
      ],
    ),
    _AskModule(
      id: 'patterns',
      title: 'Connect patterns & signals',
      subtitle: 'See connections across conversations',
      icon: Icons.link_rounded,
      iconColor: Color(0xFF8B5CF6),
      borderColor: Color(0xFFE9E0FF),
      backgroundColor: Color(0xFFFBF9FF),
      questions: <String>[
        'What recurring concerns keep showing up?',
        'Which topics tend to appear together?',
        'Are there any strong positive patterns lately?',
        'What signals suggest burnout risk?',
        'What habits correlate with productive days?',
      ],
    ),
    _AskModule(
      id: 'next',
      title: 'Decide what matters next',
      subtitle: 'Figure out what deserves attention now',
      icon: Icons.explore_outlined,
      iconColor: orangeTextColor,
      borderColor: Color(0xFFF7E7CE),
      backgroundColor: Color(0xFFFFFCF6),
      questions: <String>[
        'What is the highest-leverage thing to do today?',
        'What should I delay or drop for now?',
        'Which conversations need follow-up first?',
        'What can I finish in under 30 minutes?',
      ],
    ),
  ];

  _AskModule? _selectedModule;

  bool get _isOverview => _selectedModule == null;

  void _onTapTopLeftArea() {
    if (_isOverview) {
      MPToastUtils.showFeatureComingSoon(context: context);
      return;
    }
    setState(() {
      _selectedModule = null;
    });
  }

  void _onTapTopRightAction() {
    MPToastUtils.showFeatureComingSoon(context: context);
  }

  void _onTapModule(_AskModule module) {
    setState(() {
      _selectedModule = module;
    });
  }

  void _onSubmitInput(MPVoiceTextInputResult result) {
    MPToastUtils.showFeatureComingSoon(context: context);
  }

  Widget _buildTopBar() {
    final bool enableLeftAction = !_isOverview;
    return Row(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enableLeftAction ? _onTapTopLeftArea : null,
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
          onTap: _onTapTopRightAction,
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

  Widget _buildOverviewState() {
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
        ..._modules
            .take(3)
            .map(
              (_AskModule module) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AskModuleCard(
                  module: module,
                  onTap: () => _onTapModule(module),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildQuestionState(_AskModule module) {
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final _AskModule? selected = _selectedModule;
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
                    _buildTopBar(),
                    if (selected == null) _buildOverviewState() else _buildQuestionState(selected),
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
                onSubmitted: _onSubmitInput,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AskModule {
  const _AskModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.backgroundColor,
    required this.questions,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final Color backgroundColor;
  final List<String> questions;
}

class _AskModuleCard extends StatelessWidget {
  const _AskModuleCard({
    required this.module,
    required this.onTap,
  });

  final _AskModule module;
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
