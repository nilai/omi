import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/http/schema/mp_chat.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';

import 'mp_ask_ai_question_util.dart';

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
  MPAskAICubit() : super(const MPAskAIState(modules: <MPAskAIModule>[]));

  Future<void> initData() async {
    final List<MPChatSuggestionCard> cards =
        await MPAskAIQuestionUtil.fetchQuestionsAndCache();
    final List<MPAskAIModule> modules = _buildModulesFromCards(cards);
    emit(state.copyWith(modules: modules, clearSelectedModule: true));
  }

  static List<MPAskAIModule> _buildModulesFromCards(
    List<MPChatSuggestionCard> cards,
  ) {
    final List<MPAskAIModule> modules = <MPAskAIModule>[];
    for (int i = 0; i < cards.length; i++) {
      if (modules.length >= 3) {
        break;
      }
      final MPChatSuggestionCard card = cards[i];
      final String title = card.title.trim();
      final List<String> questions = card.suggestions
          .map((String e) => e.trim())
          .where((String e) => e.isNotEmpty)
          .toList(growable: false);
      if (title.isEmpty || questions.isEmpty) {
        continue;
      }
      final _MPAskAIModuleStyle style = _styleFor(modules.length);
      final String subtitle = card.subtitle.trim().isNotEmpty
          ? card.subtitle.trim()
          : card.content.trim();
      modules.add(
        MPAskAIModule(
          id: 'module_${modules.length}',
          title: title,
          subtitle: subtitle,
          icon: style.icon,
          iconColor: style.iconColor,
          borderColor: style.borderColor,
          backgroundColor: style.backgroundColor,
          questions: questions,
        ),
      );
    }
    return modules;
  }

  static _MPAskAIModuleStyle _styleFor(int index) {
    switch (index % 3) {
      case 0:
        return const _MPAskAIModuleStyle(
          icon: Icons.history_rounded,
          iconColor: blueTextColor,
          borderColor: Color(0xFFDCE7FF),
          backgroundColor: Color(0xFFF8FBFF),
        );
      case 1:
        return const _MPAskAIModuleStyle(
          icon: Icons.link_rounded,
          iconColor: Color(0xFF8B5CF6),
          borderColor: Color(0xFFE9E0FF),
          backgroundColor: Color(0xFFFBF9FF),
        );
      default:
        return const _MPAskAIModuleStyle(
          icon: Icons.explore_outlined,
          iconColor: orangeTextColor,
          borderColor: Color(0xFFF7E7CE),
          backgroundColor: Color(0xFFFFFCF6),
        );
    }
  }

  void selectModule(MPAskAIModule module) {
    emit(state.copyWith(selectedModule: module));
  }

  void backToOverview() {
    if (state.isOverview) return;
    emit(state.copyWith(clearSelectedModule: true));
  }
}

class _MPAskAIModuleStyle {
  const _MPAskAIModuleStyle({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final Color backgroundColor;
}
