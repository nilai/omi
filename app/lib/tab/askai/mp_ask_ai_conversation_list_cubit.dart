import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../http/api/mp_chat.dart';
import '../../http/schema/mp_chat.dart';
import 'mp_ask_ai_chat_const.dart';

enum MPAskAIConversationListPhase { loading, loaded, error }

class MPAskAIConversationItem {
  const MPAskAIConversationItem({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;
}

class MPAskAIConversationListState {
  const MPAskAIConversationListState({
    required this.phase,
    this.items = const <MPAskAIConversationItem>[],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
  });

  final MPAskAIConversationListPhase phase;
  final List<MPAskAIConversationItem> items;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  MPAskAIConversationListState copyWith({
    MPAskAIConversationListPhase? phase,
    List<MPAskAIConversationItem>? items,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
  }) {
    return MPAskAIConversationListState(
      phase: phase ?? this.phase,
      items: items ?? this.items,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MPAskAIConversationListCubit extends Cubit<MPAskAIConversationListState> {
  MPAskAIConversationListCubit()
    : super(
        const MPAskAIConversationListState(
          phase: MPAskAIConversationListPhase.loading,
        ),
      );

  static const int _pageSize = 20;
  String? _cursor;

  Future<void> initData() => refresh();

  Future<void> refresh() async {
    emit(
      const MPAskAIConversationListState(
        phase: MPAskAIConversationListPhase.loading,
      ),
    );
    try {
      final _MPAskAIConversationPageResult result = await _fetchPageFromServer(
        pageSize: _pageSize,
        cursor: null,
      );
      _cursor = result.nextCursor;
      emit(
        MPAskAIConversationListState(
          phase: MPAskAIConversationListPhase.loaded,
          items: result.items,
          hasMore: result.hasMore,
        ),
      );
    } catch (e) {
      _cursor = null;
      // 首屏加载失败时降级为空列表，确保页面显示空态而不是空白/错误占位。
      emit(
        MPAskAIConversationListState(
          phase: MPAskAIConversationListPhase.loaded,
          items: const <MPAskAIConversationItem>[],
          hasMore: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final MPAskAIConversationListState cur = state;
    if (cur.phase != MPAskAIConversationListPhase.loaded) return;
    if (cur.isLoadingMore || !cur.hasMore) return;

    emit(cur.copyWith(isLoadingMore: true));
    try {
      final _MPAskAIConversationPageResult result = await _fetchPageFromServer(
        pageSize: _pageSize,
        cursor: _cursor,
      );
      _cursor = result.nextCursor;
      emit(
        cur.copyWith(
          items: <MPAskAIConversationItem>[...cur.items, ...result.items],
          isLoadingMore: false,
          hasMore: result.hasMore,
        ),
      );
    } catch (e) {
      emit(
        cur.copyWith(
          isLoadingMore: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<_MPAskAIConversationPageResult> _fetchPageFromServer({
    required int pageSize,
    required String? cursor,
  }) async {
    final MPGetConversationListResponse? response =
        await getConversationList(
      MPGetConversationListRequest(pageSize: pageSize, cursor: cursor),
    );
    if (response == null) {
      throw Exception('Failed to load conversations');
    }
    if (response.baseResp.code != 0) {
      throw Exception(response.baseResp.message);
    }
    final List<MPAskAIConversationItem> items = response.conversations
        .map(
          (MPConversationHeaderStruct e) {
            final String title = e.title.trim().isEmpty
                ? MPAskAIChatConst.unknownConversationTitle
                : e.title.trim();
            return MPAskAIConversationItem(
              id: e.id,
              title: title,
            );
          },
        )
        .toList(growable: false);
    final String? nextCursor = items.isEmpty ? null : items.last.id;
    return _MPAskAIConversationPageResult(
      items: items,
      hasMore: response.hasMore,
      nextCursor: nextCursor,
    );
  }
}

class _MPAskAIConversationPageResult {
  const _MPAskAIConversationPageResult({
    required this.items,
    required this.hasMore,
    required this.nextCursor,
  });

  final List<MPAskAIConversationItem> items;
  final bool hasMore;
  final String? nextCursor;
}
