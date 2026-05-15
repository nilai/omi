import 'package:memo_pin/common/mp_memory_todo_priority_kind.dart';

export 'package:memo_pin/common/mp_memory_todo_priority_kind.dart';

/// 单条已创建 Todo（用于「TODOS CREATED」列表）
class MPMemoryCreatedTodoLineData {
  const MPMemoryCreatedTodoLineData({
    this.id,
    this.title,
    this.priority,
    this.deadlineLabel,
    this.description,
  });

  /// 与接口 [MPTodoStruct.id] 一致；本地新增尚未落库时可为空串。
  final String? id;

  final String? title;
  final MPMemoryTodoPriorityKind? priority;

  /// 截止时间 Unix 时间戳（秒或毫秒）；null 表示无截止时间。
  final int? deadlineLabel;
  final String? description;
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
