import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cache/mp_hive_util.dart';
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
    this.errorMessage,
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  final MPAskAIConversationListPhase phase;
  final List<MPAskAIConversationItem> items;
  final String? errorMessage;
  final bool isLoadingMore;
  final bool hasMore;

  MPAskAIConversationListState copyWith({
    MPAskAIConversationListPhase? phase,
    List<MPAskAIConversationItem>? items,
    String? errorMessage,
    bool? isLoadingMore,
    bool? hasMore,
    bool clearErrorMessage = false,
  }) {
    return MPAskAIConversationListState(
      phase: phase ?? this.phase,
      items: items ?? this.items,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

typedef _ConversationPageResult = ({
  List<MPAskAIConversationItem> items,
  bool hasMore,
});

/// 对话列表：首屏 [refresh]、下拉刷新 [refresh]、上拉更多 [loadMore]（游标）
class MPAskAIConversationListCubit extends Cubit<MPAskAIConversationListState> {
  MPAskAIConversationListCubit()
    : super(
        const MPAskAIConversationListState(
          phase: MPAskAIConversationListPhase.loading,
        ),
      );

  static const int _pageSize = 20;
  static const String _kConversationListCacheKey = 'ask_ai_conversation_list';

  String? _cursor;

  Future<void> initData() => refresh();

  /// [fromPullToRefresh] 为 `true` 时保持当前列表，后台拉取后更新。
  Future<void> refresh({bool fromPullToRefresh = false}) async {
    final bool keepVisibleList = fromPullToRefresh &&
        state.phase == MPAskAIConversationListPhase.loaded;

    bool bootstrappedFromCache = false;
    if (!keepVisibleList) {
      final List<MPAskAIConversationItem> cached = await _loadItemsFromCache();
      if (cached.isNotEmpty) {
        bootstrappedFromCache = true;
        _cursor = cached.last.id;
        if (!isClosed) {
          emit(
            MPAskAIConversationListState(
              phase: MPAskAIConversationListPhase.loaded,
              items: cached,
              hasMore: true,
            ),
          );
        }
      } else {
        if (!isClosed) {
          emit(
            const MPAskAIConversationListState(
              phase: MPAskAIConversationListPhase.loading,
            ),
          );
        }
      }
    } else if (!isClosed) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          clearErrorMessage: true,
        ),
      );
    }

    try {
      _cursor = null;
      final _ConversationPageResult result =
          await _fetchPageFromServer(cursor: null);
      final List<MPAskAIConversationItem> items = result.items;
      if (items.isNotEmpty) {
        _cursor = items.last.id;
      }
      await _persistItemsToCache(items);
      if (!isClosed) {
        emit(
          MPAskAIConversationListState(
            phase: MPAskAIConversationListPhase.loaded,
            items: items,
            hasMore: result.hasMore,
          ),
        );
      }
    } catch (e) {
      if (bootstrappedFromCache || keepVisibleList) {
        return;
      }
      final List<MPAskAIConversationItem> cached = await _loadItemsFromCache();
      if (cached.isNotEmpty) {
        _cursor = cached.last.id;
        if (!isClosed) {
          emit(
            MPAskAIConversationListState(
              phase: MPAskAIConversationListPhase.loaded,
              items: cached,
              hasMore: true,
              errorMessage: e.toString(),
            ),
          );
        }
        return;
      }
      if (!isClosed) {
        emit(
          MPAskAIConversationListState(
            phase: MPAskAIConversationListPhase.error,
            errorMessage: e.toString(),
            hasMore: false,
          ),
        );
      }
    }
  }

  /// 上拉加载更多
  Future<void> loadMore() async {
    if (state.phase != MPAskAIConversationListPhase.loaded) return;
    if (state.isLoadingMore) return;
    if (!state.hasMore) return;
    if (_cursor == null || _cursor!.trim().isEmpty) return;

    final List<MPAskAIConversationItem> current =
        List<MPAskAIConversationItem>.from(state.items);
    emit(state.copyWith(isLoadingMore: true));

    try {
      final _ConversationPageResult result =
          await _fetchPageFromServer(cursor: _cursor);
      final List<MPAskAIConversationItem> next = result.items;

      if (next.isEmpty) {
        emit(
          state.copyWith(
            isLoadingMore: false,
            hasMore: false,
          ),
        );
        return;
      }

      _cursor = next.last.id;
      emit(
        state.copyWith(
          isLoadingMore: false,
          hasMore: result.hasMore,
          items: <MPAskAIConversationItem>[...current, ...next],
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<List<MPAskAIConversationItem>> _loadItemsFromCache() async {
    final List<dynamic>? cached = await MPHiveUtil.instance
        .getPrimitive<List<dynamic>>(_kConversationListCacheKey);
    if (cached == null) {
      return const <MPAskAIConversationItem>[];
    }
    return cached
        .whereType<Map>()
        .map((Map raw) {
          final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
          final String id = (map['id'] ?? '').toString();
          final String title = (map['title'] ?? '').toString();
          if (id.trim().isEmpty || title.trim().isEmpty) {
            return null;
          }
          return MPAskAIConversationItem(id: id, title: title);
        })
        .whereType<MPAskAIConversationItem>()
        .toList(growable: false);
  }

  Future<void> _persistItemsToCache(
    List<MPAskAIConversationItem> items,
  ) async {
    await MPHiveUtil.instance.putPrimitive(
      key: _kConversationListCacheKey,
      value: items
          .map(
            (MPAskAIConversationItem item) => <String, dynamic>{
              'id': item.id,
              'title': item.title,
            },
          )
          .toList(growable: false),
    );
  }

  /// 删除指定 conversation：先调接口，成功后再从列表与本地缓存中移除。
  Future<bool> deleteConversation(String conversationId) async {
    if (state.phase != MPAskAIConversationListPhase.loaded) return false;
    if (conversationId.trim().isEmpty) return false;

    final bool exists = state.items.any(
      (MPAskAIConversationItem e) => e.id == conversationId,
    );
    if (!exists) return false;

    final MPDeleteChatResponse? response = await deleteChat(
      MPDeleteChatRequest(conversationId: conversationId),
    );
    if (response == null || response.baseResp.code != 0 || !response.success) {
      return false;
    }

    final List<MPAskAIConversationItem> next = state.items
        .where((MPAskAIConversationItem e) => e.id != conversationId)
        .toList(growable: false);

    if (!isClosed) {
      emit(state.copyWith(items: next));
    }
    await _persistItemsToCache(next);
    return true;
  }

  Future<_ConversationPageResult> _fetchPageFromServer({
    required String? cursor,
  }) async {
    final MPGetConversationListResponse? response =
        await getConversationList(
      MPGetConversationListRequest(pageSize: _pageSize, cursor: cursor),
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
    return (items: items, hasMore: response.hasMore);
  }
}
