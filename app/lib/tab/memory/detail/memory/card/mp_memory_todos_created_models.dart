import 'package:omi/common/mp_memory_todo_priority_kind.dart';

export 'package:omi/common/mp_memory_todo_priority_kind.dart';

/// 单条已创建 Todo（用于「TODOS CREATED」列表）
class MPMemoryCreatedTodoLineData {
  const MPMemoryCreatedTodoLineData({
    required this.id,
    required this.title,
    required this.priority,
    required this.deadlineLabel,
  });

  /// 与接口 [MPTodoStruct.id] 一致；本地新增尚未落库时可为空串。
  final String id;

  final String title;
  final MPMemoryTodoPriorityKind priority;

  /// 如 `Tomorrow`、`No deadline`
  final String deadlineLabel;
}

/// 「TODOS CREATED」整卡数据
class MPMemoryTodosCreatedCardData {
  const MPMemoryTodosCreatedCardData({
    this.headerTimeLabel = 'Just now',
    required this.items,
  });

  /// 头部右侧时间，如 `Just now`
  final String headerTimeLabel;

  final List<MPMemoryCreatedTodoLineData> items;
}
