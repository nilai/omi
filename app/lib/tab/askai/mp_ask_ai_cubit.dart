import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';

class MPAskAIModule {
  const MPAskAIModule({
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

class MPAskAIState {
  const MPAskAIState({
    required this.modules,
    this.selectedModule,
  });

  final List<MPAskAIModule> modules;
  final MPAskAIModule? selectedModule;

  bool get isOverview => selectedModule == null;

  MPAskAIState copyWith({
    List<MPAskAIModule>? modules,
    MPAskAIModule? selectedModule,
    bool clearSelectedModule = false,
  }) {
    return MPAskAIState(
      modules: modules ?? this.modules,
      selectedModule: clearSelectedModule
          ? null
          : (selectedModule ?? this.selectedModule),
    );
  }
}

class MPAskAICubit extends Cubit<MPAskAIState> {
  MPAskAICubit() : super(MPAskAIState(modules: _defaultModules));

  static const List<MPAskAIModule> _defaultModules = <MPAskAIModule>[
    MPAskAIModule(
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
    MPAskAIModule(
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
    MPAskAIModule(
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

  void selectModule(MPAskAIModule module) {
    emit(state.copyWith(selectedModule: module));
  }

  void backToOverview() {
    if (state.isOverview) return;
    emit(state.copyWith(clearSelectedModule: true));
  }
}
