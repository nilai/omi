import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

enum MPAskAIChatPhase { loading, loaded, error }

enum MPAskAIMessageRole { user, ai }

class MPAskAIChatMessage {
  const MPAskAIChatMessage({
    required this.id,
    required this.role,
    required this.content,
  });

  final String id;
  final MPAskAIMessageRole role;
  final String content;
}

class MPAskAIChatState {
  const MPAskAIChatState({
    required this.phase,
    required this.aboutText,
    this.messages = const <MPAskAIChatMessage>[],
    this.suggestedQuestions = const <String>[],
    this.errorMessage,
  });

  final MPAskAIChatPhase phase;
  final String aboutText;
  final List<MPAskAIChatMessage> messages;
  final List<String> suggestedQuestions;
  final String? errorMessage;

  bool get hasMessages => messages.isNotEmpty;

  MPAskAIChatState copyWith({
    MPAskAIChatPhase? phase,
    String? aboutText,
    List<MPAskAIChatMessage>? messages,
    List<String>? suggestedQuestions,
    String? errorMessage,
  }) {
    return MPAskAIChatState(
      phase: phase ?? this.phase,
      aboutText: aboutText ?? this.aboutText,
      messages: messages ?? this.messages,
      suggestedQuestions: suggestedQuestions ?? this.suggestedQuestions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MPAskAIChatCubit extends Cubit<MPAskAIChatState> {
  MPAskAIChatCubit({
    required this.aboutText,
    required this.conversationId,
    required this.suggestedQuestions,
  }) : super(
         MPAskAIChatState(
           phase: MPAskAIChatPhase.loading,
           aboutText: aboutText,
           suggestedQuestions: suggestedQuestions,
         ),
       );

  final String aboutText;
  final String? conversationId;
  final List<String> suggestedQuestions;

  Future<void> initData() async {
    emit(
      state.copyWith(
        phase: MPAskAIChatPhase.loading,
        aboutText: aboutText,
        suggestedQuestions: suggestedQuestions,
      ),
    );
    try {
      final List<MPAskAIChatMessage> messages = await _fetchMessagesFromServer(
        conversationId: conversationId,
      );
      emit(
        state.copyWith(
          phase: MPAskAIChatPhase.loaded,
          messages: messages,
          aboutText: aboutText,
          suggestedQuestions: suggestedQuestions,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          phase: MPAskAIChatPhase.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> sendMessage(String text) async {
    final String message = text.trim();
    if (message.isEmpty) return;
    if (state.phase != MPAskAIChatPhase.loaded) return;

    final List<MPAskAIChatMessage> current = state.messages;
    final List<MPAskAIChatMessage> next = <MPAskAIChatMessage>[
      ...current,
      MPAskAIChatMessage(
        id: 'u_${DateTime.now().microsecondsSinceEpoch}',
        role: MPAskAIMessageRole.user,
        content: message,
      ),
    ];
    emit(state.copyWith(messages: next));

    final MPAskAIChatMessage aiReply = await _fetchAIReplyFromServer(message);
    emit(state.copyWith(messages: <MPAskAIChatMessage>[...next, aiReply]));
  }

  Future<List<MPAskAIChatMessage>> _fetchMessagesFromServer({
    required String? conversationId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (conversationId == null || conversationId.isEmpty) {
      return const <MPAskAIChatMessage>[];
    }
    return const <MPAskAIChatMessage>[
      MPAskAIChatMessage(
        id: 'u_1',
        role: MPAskAIMessageRole.user,
        content: 'What have I been working on recently?',
      ),
      MPAskAIChatMessage(
        id: 'a_1',
        role: MPAskAIMessageRole.ai,
        content:
            'Based on your recent memories, you focused on API migration planning, roadmap alignment, and delivery coordination.',
      ),
    ];
  }

  Future<MPAskAIChatMessage> _fetchAIReplyFromServer(String text) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    return MPAskAIChatMessage(
      id: 'a_${DateTime.now().microsecondsSinceEpoch}',
      role: MPAskAIMessageRole.ai,
      content: '收到你的问题：$text\n我会结合近期记忆给你一个结构化总结。',
    );
  }
}
