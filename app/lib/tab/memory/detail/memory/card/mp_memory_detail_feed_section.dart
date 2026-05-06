import 'package:flutter/material.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_detail_content_card.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_feed_block.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_insight_card.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_my_memos_card.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_resummary_card.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_todos_created_card.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_you_asked_card.dart';

/// 主卡片下方：按 [MPMemoryDetailCardData.feedBlocks] 顺序渲染（与接口 feeds 一致，含 RESUMMARY）。
class MPMemoryDetailFeedSection extends StatelessWidget {
  const MPMemoryDetailFeedSection({
    super.key,
    required this.data,
    this.onYouAskedTap,
  });

  final MPMemoryDetailCardData data;

  /// 与详情页底部「Ask AI」相同的跳转（YOU ASKED 卡片整卡点击）。
  final VoidCallback? onYouAskedTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < data.feedBlocks.length; i++) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MPMemoryFeedBlockWidget(
              block: data.feedBlocks[i],
              feedBlockIndex: i,
              memoryId: data.memoryId,
              onYouAskedTap: onYouAskedTap,
            ),
          ),
        ],
      ],
    );
  }
}

class _MPMemoryFeedBlockWidget extends StatelessWidget {
  const _MPMemoryFeedBlockWidget({
    required this.block,
    required this.feedBlockIndex,
    required this.memoryId,
    this.onYouAskedTap,
  });

  final MPMemoryFeedBlock block;
  final int feedBlockIndex;
  final String memoryId;
  final VoidCallback? onYouAskedTap;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      MPMemoryFeedInsightBlock(:final data) => MPMemoryInsightCard(
        data: data,
        memoryId: memoryId,
      ),
      MPMemoryFeedTodosCreatedBlock(:final data) => MPMemoryTodosCreatedCard(
        data: data,
        feedBlockIndex: feedBlockIndex,
      ),
      MPMemoryFeedMyMemoBlock(:final data) => MPMemoryMyMemosCard(data: data),
      MPMemoryFeedYouAskedBlock(:final data) => MPMemoryYouAskedCard(
        data: data,
        onTap: onYouAskedTap,
      ),
      MPMemoryFeedResummaryBlock(:final data) => MPMemoryResummaryCard(
        data: data,
        onExpansionChanged: (bool expanded) {

        },
      ),
      MPMemoryFeedResummaryLoadingBlock(:final data) =>
        MPMemoryResummaryLoadingCard(data: data),
    };
  }
}
