import 'package:flutter/foundation.dart';

/// Ask AI 对话列表侧滑互斥：同一时间只允许一条 conversation 处于展开状态。
class MPAskAIConversationSwipeRevealBus {
  /// 当前展开的 conversation id；`null` 表示都收起。
  final ValueNotifier<String?> openRowId = ValueNotifier<String?>(null);

  void open(String rowId) {
    openRowId.value = rowId;
  }

  void closeAll() {
    openRowId.value = null;
  }

  void dispose() {
    openRowId.dispose();
  }
}
