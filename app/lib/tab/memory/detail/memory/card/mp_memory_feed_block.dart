import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_insight_card.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_my_memos_card.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_resummary_card.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_todos_created_models.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_you_asked_card.dart';

/// 详情页主卡片下方列表：顺序与 [MPMemoryFeedStruct.feeds] 一致，可混合多种类型。
sealed class MPMemoryFeedBlock {}

final class MPMemoryFeedInsightBlock extends MPMemoryFeedBlock {
  MPMemoryFeedInsightBlock(this.data);

  final MPMemoryInsightItemData data;
}

final class MPMemoryFeedTodosCreatedBlock extends MPMemoryFeedBlock {
  MPMemoryFeedTodosCreatedBlock(this.data);

  final MPMemoryTodosCreatedCardData data;
}

final class MPMemoryFeedMyMemoBlock extends MPMemoryFeedBlock {
  MPMemoryFeedMyMemoBlock(this.data);

  final MPMemoryMyMemosCardData data;
}

final class MPMemoryFeedYouAskedBlock extends MPMemoryFeedBlock {
  MPMemoryFeedYouAskedBlock(this.data);

  final MPMemoryYouAskedCardData data;
}

final class MPMemoryFeedResummaryBlock extends MPMemoryFeedBlock {
  MPMemoryFeedResummaryBlock(this.data);

  final MPMemoryResummaryCardData data;
}

/// 本地插入的「RESUMMARY 生成中」占位卡片（用于轮询期间展示）。
final class MPMemoryFeedResummaryLoadingBlock extends MPMemoryFeedBlock {
  MPMemoryFeedResummaryLoadingBlock(this.data);

  final MPMemoryResummaryLoadingCardData data;
}
