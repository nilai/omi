import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../http/api/mp_chat.dart';
import '../../http/schema/mp_chat.dart';

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
    this.conversationId,
    this.messages = const <MPAskAIChatMessage>[],
    this.suggestedQuestions = const <String>[],
    this.isSending = false,
    this.errorMessage,
  });

  final MPAskAIChatPhase phase;
  final String aboutText;
  final String? conversationId;
  final List<MPAskAIChatMessage> messages;
  final List<String> suggestedQuestions;
  final bool isSending;
  final String? errorMessage;

  bool get hasMessages => messages.isNotEmpty;

  MPAskAIChatState copyWith({
    MPAskAIChatPhase? phase,
    String? aboutText,
    String? conversationId,
    List<MPAskAIChatMessage>? messages,
    List<String>? suggestedQuestions,
    bool? isSending,
    String? errorMessage,
  }) {
    return MPAskAIChatState(
      phase: phase ?? this.phase,
      aboutText: aboutText ?? this.aboutText,
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      suggestedQuestions: suggestedQuestions ?? this.suggestedQuestions,
      isSending: isSending ?? this.isSending,
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
           conversationId: conversationId,
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
        conversationId: conversationId,
        suggestedQuestions: suggestedQuestions,
      ),
    );
    try {
      final List<MPAskAIChatMessage> messages = await _fetchMessagesFromServer();
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
    if (state.phase != MPAskAIChatPhase.loaded || state.isSending) return;

    final List<MPAskAIChatMessage> current = state.messages;
    List<MPAskAIChatMessage> next = <MPAskAIChatMessage>[
      ...current,
      MPAskAIChatMessage(
        id: 'u_${DateTime.now().microsecondsSinceEpoch}',
        role: MPAskAIMessageRole.user,
        content: message,
      ),
    ];
    emit(state.copyWith(messages: next, isSending: true, errorMessage: ''));

    String? activeConversationId = state.conversationId;
    if (activeConversationId == null || activeConversationId.isEmpty) {
      final MPCreateConversationResponse? created =
          await createConversation(
        MPCreateConversationRequest(
          title: null,
          expertId: '',
          memoryId: '',
          templateId: '',
          speakerId: '',
        ),
      );
      if (created == null) {
        emit(
          state.copyWith(
            isSending: false,
            errorMessage: 'AI回复失败，请稍后重试',
          ),
        );
        return;
      }
      if (created.baseResp.code != 0) {
        emit(
          state.copyWith(
            isSending: false,
            errorMessage: created.baseResp.message,
          ),
        );
        return;
      }
      activeConversationId = created.conversationId;
      if (created.greet.trim().isNotEmpty) {
        next = <MPAskAIChatMessage>[
          ...next,
          MPAskAIChatMessage(
            id: 'a_${DateTime.now().microsecondsSinceEpoch}',
            role: MPAskAIMessageRole.ai,
            content: created.greet.trim(),
          ),
        ];
      }
      emit(
        state.copyWith(
          conversationId: activeConversationId,
          messages: next,
        ),
      );
    }

    String aiText = '';
    try {
      final Stream<String> stream = chat(
        MPChatRequest(
          message: message,
          conversationId: activeConversationId,
        ),
      );
      await for (final String chunk in stream) {
        aiText += chunk;
        final List<MPAskAIChatMessage> merged = <MPAskAIChatMessage>[
          ...next,
          MPAskAIChatMessage(
            id: 'a_${DateTime.now().microsecondsSinceEpoch}',
            role: MPAskAIMessageRole.ai,
            content: aiText,
          ),
        ];
        emit(state.copyWith(messages: merged, conversationId: activeConversationId));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'AI回复失败，请稍后重试'));
    } finally {
      emit(state.copyWith(isSending: false));
    }
  }

  Future<List<MPAskAIChatMessage>> _fetchMessagesFromServer() async {
    final String? targetConversationId = state.conversationId;
    if (targetConversationId == null || targetConversationId.isEmpty) {
      return const <MPAskAIChatMessage>[];
    }
    final MPGetConversationDetailResponse? response =
        await getConversationDetail(
      MPGetConversationDetailRequest(
        conversationId: targetConversationId,
        pageSize: 200,
      ),
    );
    if (response == null) {
      throw Exception('Failed to load conversation detail');
    }
    if (response.baseResp.code != 0) {
      throw Exception(response.baseResp.message);
    }
    return response.contents.map((MPConversationStruct item) {
      final bool isUser = item.speaker.myselfVoice == true;
      return MPAskAIChatMessage(
        id: 'history_${item.time}_${item.content.hashCode}',
        role: isUser ? MPAskAIMessageRole.user : MPAskAIMessageRole.ai,
        content: item.content,
      );
    }).toList(growable: false);
  }
}
