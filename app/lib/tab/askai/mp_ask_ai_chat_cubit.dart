import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cache/mp_hive_util.dart';
import '../../utils/mp_time_utils.dart';
import '../../http/api/mp_chat.dart';
import '../../http/mp_chat_stream_utils.dart';
import '../../http/schema/mp_chat.dart';
import 'mp_ask_ai_chat_page.dart';

typedef _MPAskAIChatPageResult = ({List<MPAskAIChatMessage> messages, bool hasMore});

enum MPAskAIChatPhase { loading, loaded, error }

enum MPAskAIMessageRole { user, ai }

class MPAskAIChatMessage {
  const MPAskAIChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.time,
  });

  final String id;
  final MPAskAIMessageRole role;
  final String content;

  /// 服务端消息时间，用于向上分页游标。
  final String? time;
}

class MPAskAIChatState {
  const MPAskAIChatState({
    required this.phase,
    required this.aboutText,
    this.conversationId,
    this.messages = const <MPAskAIChatMessage>[],
    this.suggestedQuestions = const <String>[],
    this.isSending = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.errorMessage,
  });

  final MPAskAIChatPhase phase;
  final String aboutText;
  final String? conversationId;
  final List<MPAskAIChatMessage> messages;
  final List<String> suggestedQuestions;
  final bool isSending;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  bool get hasMessages => messages.isNotEmpty;

  MPAskAIChatState copyWith({
    MPAskAIChatPhase? phase,
    String? aboutText,
    String? conversationId,
    List<MPAskAIChatMessage>? messages,
    List<String>? suggestedQuestions,
    bool? isSending,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
  }) {
    return MPAskAIChatState(
      phase: phase ?? this.phase,
      aboutText: aboutText ?? this.aboutText,
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      suggestedQuestions: suggestedQuestions ?? this.suggestedQuestions,
      isSending: isSending ?? this.isSending,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MPAskAIChatCubit extends Cubit<MPAskAIChatState> {
  MPAskAIChatCubit({
    required this.aboutText,
    required this.conversationId,
    required this.suggestedQuestions,
    required this.type,
    required this.chatTypeId,
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
  final MPAskAIChatType type;
  final String? chatTypeId;

  static const int _pageSize = 30;

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
      final ({List<MPAskAIChatMessage> messages, bool hasMore}) result = await _fetchMessagesFromServer();
      emit(
        state.copyWith(
          phase: MPAskAIChatPhase.loaded,
          messages: result.messages,
          hasMore: result.hasMore,
          aboutText: aboutText,
          suggestedQuestions: suggestedQuestions,
        ),
      );
    } catch (e) {
      emit(state.copyWith(phase: MPAskAIChatPhase.error, errorMessage: e.toString()));
    }
  }

  /// 上滑到顶部附近时加载更早的消息（游标为当前最早一条的 [MPAskAIChatMessage.time]）。
  Future<void> loadMore() async {
    if (state.phase != MPAskAIChatPhase.loaded) return;
    if (state.isLoadingMore) return;
    if (!state.hasMore) return;

    final String? cursor = state.messages.isEmpty ? null : state.messages.first.time;
    if (cursor == null || cursor.trim().isEmpty) return;

    final List<MPAskAIChatMessage> current = List<MPAskAIChatMessage>.from(state.messages);
    emit(state.copyWith(isLoadingMore: true));

    try {
      final _MPAskAIChatPageResult result = await _fetchPageFromServer(cursor: cursor);
      final List<MPAskAIChatMessage> older = result.messages;
      if (older.isEmpty) {
        emit(state.copyWith(isLoadingMore: false, hasMore: false));
        return;
      }

      final Set<String> existingIds = current.map((MPAskAIChatMessage m) => m.id).toSet();
      final List<MPAskAIChatMessage> uniqueOlder =
          older.where((MPAskAIChatMessage m) => !existingIds.contains(m.id)).toList(growable: false);

      emit(
        state.copyWith(
          isLoadingMore: false,
          hasMore: result.hasMore,
          messages: <MPAskAIChatMessage>[...uniqueOlder, ...current],
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> sendMessage(String text) async {
    final String message = text.trim();
    if (message.isEmpty) return;
    if (state.phase != MPAskAIChatPhase.loaded || state.isSending) return;

    final List<MPAskAIChatMessage> current = state.messages;
    List<MPAskAIChatMessage> next = <MPAskAIChatMessage>[
      ...current,
      MPAskAIChatMessage(id: 'u_${MPTimeUtils.nowUnixMicroseconds()}', role: MPAskAIMessageRole.user, content: message),
    ];
    emit(state.copyWith(messages: next, isSending: true, errorMessage: ''));

    String? activeConversationId = state.conversationId;
    if (activeConversationId == null || activeConversationId.isEmpty) {
      final MPCreateConversationResponse? created = await createConversation(
        MPCreateConversationRequest(
          title: null,
          expertId: type == MPAskAIChatType.expert ? chatTypeId ?? '' : '',
          memoryId: type == MPAskAIChatType.memory ? chatTypeId ?? '' : '',
          templateId: type == MPAskAIChatType.template ? chatTypeId ?? '' : '',
          speakerId: type == MPAskAIChatType.speaker ? chatTypeId ?? '' : '',
          insightId: type == MPAskAIChatType.insight ? chatTypeId ?? '' : '',
        ),
      );
      if (created == null) {
        emit(state.copyWith(isSending: false, errorMessage: 'AI reply failed. Please try again later.'));
        return;
      }
      if (created.baseResp.code != 0) {
        emit(state.copyWith(isSending: false, errorMessage: created.baseResp.message));
        return;
      }
      activeConversationId = created.conversationId;
      emit(state.copyWith(conversationId: activeConversationId, messages: next));
    }

    String rawBuffer = '';
    final String aiMessageId = 'a_${MPTimeUtils.nowUnixMicroseconds()}';
    try {
      final Stream<String> stream = chat(MPChatRequest(message: message, conversationId: activeConversationId));
      await for (final String chunk in stream) {
        rawBuffer = MPChatStreamUtils.appendToBuffer(rawBuffer, chunk);
        final List<MPAskAIChatMessage> merged = <MPAskAIChatMessage>[
          ...next,
          MPAskAIChatMessage(id: aiMessageId, role: MPAskAIMessageRole.ai, content: rawBuffer),
        ];
        emit(state.copyWith(messages: merged, conversationId: activeConversationId));
      }
      print('[MPAskAIChat] stream final result:\n$rawBuffer');
      if (rawBuffer.trim().isNotEmpty) {
        final List<MPAskAIChatMessage> merged = <MPAskAIChatMessage>[
          ...next,
          MPAskAIChatMessage(id: aiMessageId, role: MPAskAIMessageRole.ai, content: rawBuffer),
        ];
        emit(state.copyWith(messages: merged, conversationId: activeConversationId));
      }
    } catch (e) {
      if (rawBuffer.trim().isNotEmpty) {
        print('[MPAskAIChat] stream final result (error):\n$rawBuffer');
        final List<MPAskAIChatMessage> merged = <MPAskAIChatMessage>[
          ...next,
          MPAskAIChatMessage(id: aiMessageId, role: MPAskAIMessageRole.ai, content: rawBuffer),
        ];
        emit(
          state.copyWith(
            messages: merged,
            conversationId: activeConversationId,
            errorMessage: 'AI reply failed. Please try again later.',
          ),
        );
      } else {
        emit(state.copyWith(errorMessage: 'AI reply failed. Please try again later.'));
      }
    } finally {
      emit(state.copyWith(isSending: false));
    }
  }

  Future<_MPAskAIChatPageResult> _fetchMessagesFromServer() async {
    final String? targetConversationId = state.conversationId;
    if (targetConversationId == null || targetConversationId.isEmpty) {
      return (messages: <MPAskAIChatMessage>[], hasMore: false);
    }

    try {
      final _MPAskAIChatPageResult result = await _fetchPageFromServer(
        conversationId: targetConversationId,
        cursor: null,
      );
      unawaited(
        MPHiveUtil.instance.putPrimitive(
          key: targetConversationId,
          value: result.messages
              .map(
                (MPAskAIChatMessage item) => <String, dynamic>{
                  'id': item.id,
                  'role': item.role == MPAskAIMessageRole.user ? 'user' : 'ai',
                  'content': item.content,
                  if (item.time != null) 'time': item.time,
                },
              )
              .toList(growable: false),
        ),
      );
      return result;
    } catch (_) {
      final List<dynamic>? cached = await MPHiveUtil.instance.getPrimitive<List<dynamic>>(targetConversationId);
      if (cached != null && cached.isNotEmpty) {
        final List<MPAskAIChatMessage> messages = cached
            .whereType<Map>()
            .map((Map item) {
              final Map<String, dynamic> map = Map<String, dynamic>.from(item);
              final String role = (map['role'] ?? '').toString();
              return MPAskAIChatMessage(
                id: (map['id'] ?? '').toString(),
                role: role == 'user' ? MPAskAIMessageRole.user : MPAskAIMessageRole.ai,
                content: (map['content'] ?? '').toString(),
                time: (map['time'] ?? '').toString().trim().isEmpty ? null : (map['time'] ?? '').toString(),
              );
            })
            .where((MPAskAIChatMessage e) => e.content.trim().isNotEmpty)
            .toList(growable: false);
        return (messages: messages, hasMore: true);
      }
      throw Exception('Failed to load conversation detail');
    }
  }

  Future<_MPAskAIChatPageResult> _fetchPageFromServer({
    String? conversationId,
    String? cursor,
  }) async {
    final String? targetConversationId = conversationId ?? state.conversationId;
    if (targetConversationId == null || targetConversationId.isEmpty) {
      return (messages: <MPAskAIChatMessage>[], hasMore: false);
    }

    final MPGetConversationDetailResponse? response = await getConversationDetail(
      MPGetConversationDetailRequest(
        conversationId: targetConversationId,
        pageSize: _pageSize,
        cursor: cursor,
      ),
    );
    if (response == null) {
      throw Exception('Failed to load conversation detail');
    }
    if (response.baseResp.code != 0) {
      throw Exception(response.baseResp.message);
    }

    final List<MPAskAIChatMessage> messages = <MPAskAIChatMessage>[];
    for (final (int index, MPConversationStruct element) in response.contents.indexed) {
      final bool isUser = index % 2 == 1;
      messages.add(
        MPAskAIChatMessage(
          id: 'history_${element.time}_${element.content.hashCode}',
          role: isUser ? MPAskAIMessageRole.user : MPAskAIMessageRole.ai,
          content: element.content,
          time: element.time,
        ),
      );
    }
    return (
      messages: messages.reversed.toList(growable: false),
      hasMore: response.hasMore,
    );
  }
}
