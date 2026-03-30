import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'mp_insights_list_cubit.dart';

/// Insights 详情页状态
enum MPInsightDetailPhase { loading, loaded, error }

/// 详情页状态
class MPInsightDetailState {
  const MPInsightDetailState({
    required this.phase,
    this.data,
    this.errorMessage,
  });

  final MPInsightDetailPhase phase;
  final MPInsightDetailData? data;
  final String? errorMessage;

  factory MPInsightDetailState.loading() => const MPInsightDetailState(
        phase: MPInsightDetailPhase.loading,
      );

  factory MPInsightDetailState.loaded(MPInsightDetailData data) =>
      MPInsightDetailState(
        phase: MPInsightDetailPhase.loaded,
        data: data,
      );

  factory MPInsightDetailState.error(String message) => MPInsightDetailState(
        phase: MPInsightDetailPhase.error,
        errorMessage: message,
      );
}

/// 详情页数据（不同类型会在 `paragraphs` / `tips` 等字段中体现差异）
class MPInsightDetailData {
  const MPInsightDetailData({
    required this.item,
    required this.paragraphs,
    required this.tips,
  });

  final MPInsightListItem item;
  final List<String> paragraphs;
  final List<String> tips;
}

/// 详情页 Cubit：根据列表项类型模拟后台拉取详情
class MPInsightDetailCubit extends Cubit<MPInsightDetailState> {
  MPInsightDetailCubit({
    required MPInsightListItem item,
  })  : _item = item,
        super(MPInsightDetailState.loading());

  final MPInsightListItem _item;

  /// 页面初始化：拉取详情
  Future<void> initData() async {
    emit(MPInsightDetailState.loading());
    try {
      await Future<void>.delayed(const Duration(milliseconds: 520));
      final MPInsightDetailData loaded = _buildDetailData(_item);
      emit(MPInsightDetailState.loaded(loaded));
    } catch (e) {
      emit(MPInsightDetailState.error(e.toString()));
    }
  }

  MPInsightDetailData _buildDetailData(MPInsightListItem item) {
    final int seed = item.id.hashCode & 0x7fffffff;
    final Random r = Random(seed);

    switch (item.type) {
      case MPInsightCardType.daily:
        return MPInsightDetailData(
          item: item,
          paragraphs: <String>[
            item.summary,
            'Today’s focus worked best when you reduced context switching and kept your next steps visible.',
            'If you get stuck, try capturing the “why” behind the task—clarity usually restores momentum.',
          ],
          tips: <String>[
            '把下一步写成一句可执行句',
            '将后续提醒合并到同一个时间窗口',
            if (r.nextBool()) '为高消耗任务留出缓冲 15 分钟',
          ],
        );

      case MPInsightCardType.weekly:
        return MPInsightDetailData(
          item: item,
          paragraphs: <String>[
            item.summary,
            'Over the week, your progress correlated with short capture sessions followed by one deep work block.',
            'Follow-ups were most effective when they were grouped and scheduled right after key work.',
          ],
          tips: <String>[
            '把 follow-up 放到“工作后立刻做”',
            '每周复盘一次，删掉低价值任务',
            if (r.nextBool()) '设置任务上限：一次只追求 1 个关键目标',
          ],
        );

      case MPInsightCardType.monthly:
        return MPInsightDetailData(
          item: item,
          paragraphs: <String>[
            item.summary,
            'Across the month, you improved reliability by maintaining a steady capture habit.',
            'Your best outcomes came from aligning tasks with your natural attention cycles.',
          ],
          tips: <String>[
            '每月选 3 个“最重要的持续改进”',
            '将长期目标拆成每周可执行的子任务',
            if (r.nextBool()) '减少重复确认，增加一次性记录',
          ],
        );

      case MPInsightCardType.pattern:
        return MPInsightDetailData(
          item: item,
          paragraphs: <String>[
            'API migration blockers have resurfaced across multiple conversations over the past two weeks. Ownership and delivery sequencing remain unclear, causing repeated execution friction.',
            'Continued ambiguity may delay rollout and increase cross-team coordination costs, affecting delivery confidence.',
          ],
          tips: <String>[
            'Clarify API ownership and rollout sequence in next infrastructure sync.',
            if (r.nextBool()) 'Capture the outcome of each meeting and connect it back to this pattern.',
          ],
        );
    }
  }
}

