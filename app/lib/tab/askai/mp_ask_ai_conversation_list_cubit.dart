import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

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
  int _nextPage = 1;

  Future<void> initData() => refresh();

  Future<void> refresh() async {
    emit(
      const MPAskAIConversationListState(
        phase: MPAskAIConversationListPhase.loading,
      ),
    );
    try {
      final _MPAskAIConversationPageResult result = await _fetchPageFromServer(
        page: 1,
        pageSize: _pageSize,
      );
      _nextPage = 2;
      emit(
        MPAskAIConversationListState(
          phase: MPAskAIConversationListPhase.loaded,
          items: result.items,
          hasMore: result.hasMore,
        ),
      );
    } catch (e) {
      emit(
        MPAskAIConversationListState(
          phase: MPAskAIConversationListPhase.error,
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
        page: _nextPage,
        pageSize: _pageSize,
      );
      _nextPage += 1;
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
    required int page,
    required int pageSize,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    const List<String> seed = <String>[
      'API migration discussion',
      'Product positioning rethink',
      'Hiring and team bandwidth',
      'Q4 revenue forecasting',
      'Brand identity refresh',
      'Sprint planning issues',
      'Customer feedback analysis',
      'Work-life balance strategies',
      'Release timeline alignment',
      'Weekly retro highlights',
    ];

    final int start = (page - 1) * pageSize;
    final List<MPAskAIConversationItem> items = List<MPAskAIConversationItem>.generate(
      pageSize,
      (int i) {
        final int index = start + i;
        return MPAskAIConversationItem(
          id: 'conv_$index',
          title: seed[index % seed.length],
        );
      },
      growable: false,
    );
    return _MPAskAIConversationPageResult(items: items, hasMore: true);
  }
}

class _MPAskAIConversationPageResult {
  const _MPAskAIConversationPageResult({
    required this.items,
    required this.hasMore,
  });

  final List<MPAskAIConversationItem> items;
  final bool hasMore;
}
