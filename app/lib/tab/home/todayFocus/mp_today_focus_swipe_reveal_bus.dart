import 'package:flutter/foundation.dart';

/// Today Focus 页侧滑互斥：「Add to Today's Focus」与「Remove from focus」不能同时展开。
class MPTodayFocusSwipeRevealBus {
  /// 当前展开的 Today 行 id；`null` 表示都收起。
  final ValueNotifier<String?> openAddRowId = ValueNotifier<String?>(null);

  /// 当前展开的 Focus 行 id；`null` 表示都收起。
  final ValueNotifier<String?> openRemoveRowId = ValueNotifier<String?>(null);

  void openAdd(String rowId) {
    openRemoveRowId.value = null;
    openAddRowId.value = rowId;
  }

  void openRemove(String rowId) {
    openAddRowId.value = null;
    openRemoveRowId.value = rowId;
  }

  void dispose() {
    openAddRowId.dispose();
    openRemoveRowId.dispose();
  }
}
