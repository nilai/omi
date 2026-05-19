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
  });

  final MPAskAIConversationListPhase phase;
  final List<MPAskAIConversationItem> items;
  final String? errorMessage;

  MPAskAIConversationListState copyWith({
    MPAskAIConversationListPhase? phase,
    List<MPAskAIConversationItem>? items,
    String? errorMessage,
  }) {
    return MPAskAIConversationListState(
      phase: phase ?? this.phase,
      items: items ?? this.items,
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
  static const String _kConversationListCacheKey = 'ask_ai_conversation_list';

  Future<void> initData() => refresh();

  /// [fromPullToRefresh] 为 `true` 时保持当前列表展示，仅后台拉取第一页。
  Future<void> refresh({bool fromPullToRefresh = false}) async {
    final bool keepVisibleList = fromPullToRefresh &&
        state.phase == MPAskAIConversationListPhase.loaded;
    if (!keepVisibleList) {
      emit(
        const MPAskAIConversationListState(
          phase: MPAskAIConversationListPhase.loading,
        ),
      );
    }
    try {
      final List<MPAskAIConversationItem> items = await _fetchFirstPageFromServer();
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
      emit(
        MPAskAIConversationListState(
          phase: MPAskAIConversationListPhase.loaded,
          items: items,
        ),
      );
    } catch (e) {
      final List<dynamic>? cached = await MPHiveUtil.instance
          .getPrimitive<List<dynamic>>(_kConversationListCacheKey);
      final List<MPAskAIConversationItem> cachedItems = cached == null
          ? const <MPAskAIConversationItem>[]
          : cached
                .whereType<Map>()
                .map((Map raw) {
                  final Map<String, dynamic> map =
                      Map<String, dynamic>.from(raw);
                  final String id = (map['id'] ?? '').toString();
                  final String title = (map['title'] ?? '').toString();
                  if (id.trim().isEmpty || title.trim().isEmpty) {
                    return null;
                  }
                  return MPAskAIConversationItem(id: id, title: title);
                })
                .whereType<MPAskAIConversationItem>()
                .toList(growable: false);

      if (cachedItems.isNotEmpty) {
        emit(
          MPAskAIConversationListState(
            phase: MPAskAIConversationListPhase.loaded,
            items: cachedItems,
            errorMessage: e.toString(),
          ),
        );
        return;
      }

      emit(
        MPAskAIConversationListState(
          phase: MPAskAIConversationListPhase.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<List<MPAskAIConversationItem>> _fetchFirstPageFromServer() async {
    final MPGetConversationListResponse? response =
        await getConversationList(
      MPGetConversationListRequest(pageSize: _pageSize, cursor: null),
    );
    if (response == null) {
      throw Exception('Failed to load conversations');
    }
    if (response.baseResp.code != 0) {
      throw Exception(response.baseResp.message);
    }
    return response.conversations
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
  }
}
