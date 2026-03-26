import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

enum MPMemorySearchPhase { loading, error, loaded }

class MPMemorySearchState {
  const MPMemorySearchState({
    required this.phase,
    this.query = '',
    this.suggestions = const <String>[],
    this.filteredSuggestions = const <String>[],
    this.errorMessage,
  });

  final MPMemorySearchPhase phase;
  final String query;
  final List<String> suggestions;
  final List<String> filteredSuggestions;
  final String? errorMessage;

  MPMemorySearchState copyWith({
    MPMemorySearchPhase? phase,
    String? query,
    List<String>? suggestions,
    List<String>? filteredSuggestions,
    String? errorMessage,
  }) {
    return MPMemorySearchState(
      phase: phase ?? this.phase,
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      filteredSuggestions: filteredSuggestions ?? this.filteredSuggestions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Memory 搜索页 Cubit：负责加载/提供 suggestions，以及 query 的筛选逻辑。
class MPMemorySearchCubit extends Cubit<MPMemorySearchState> {
  MPMemorySearchCubit()
    : super(const MPMemorySearchState(phase: MPMemorySearchPhase.loading));

  Timer? _debounce;

  Future<void> initData() async {
    try {
      // TODO: 替换为真实接口（比如热门人物/主题/关键词）
      await Future<void>.delayed(const Duration(milliseconds: 120));
      const List<String> suggestions = <String>[
        'Alex',
        'API migration',
        'CES',
        'Investor meeting',
      ];
      emit(
        state.copyWith(
          phase: MPMemorySearchPhase.loaded,
          suggestions: suggestions,
          filteredSuggestions: suggestions,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          phase: MPMemorySearchPhase.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> retry() => initData();

  void setQuery(String value) {
    final String q = value.trimLeft();
    emit(state.copyWith(query: q));

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () {
      final List<String> filtered = _filter(state.suggestions, q);
      emit(state.copyWith(filteredSuggestions: filtered));
    });
  }

  List<String> _filter(List<String> items, String query) {
    final String q = query.trim();
    if (q.isEmpty) return items;
    final String lower = q.toLowerCase();
    return items
        .where((String s) => s.toLowerCase().contains(lower))
        .toList(growable: false);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _debounce = null;
    return super.close();
  }
}
