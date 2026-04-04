/// Todo 新建 / 编辑弹窗共用的选项列表与展示规范化。
class MPTodoUtils {
  MPTodoUtils._();

  static const List<String> kTodoPriorities = <String>[
    'Low',
    'Normal',
    'High',
  ];

  static const List<String> kTodoWhenOptions = <String>[
    'No deadline',
    'Today',
    'Tomorrow',
    'Pick a date',
  ];

  /// 将列表或接口侧的优先级文案规范为 [kTodoPriorities] 中的项。
  static String normalizePriorityPickerLabel(String raw) {
    switch (raw.trim()) {
      case 'High priority':
      case 'High':
        return 'High';
      case 'Medium':
        return 'Normal';
      case 'Low':
        return 'Low';
      case 'Normal':
      default:
        return 'Normal';
    }
  }

  /// UI 优先级文案 → 接口 `priority` 字段（`low` / `normal` / `high`）。
  static String mapPriorityToApi(String ui) {
    switch (ui.trim()) {
      case 'Low':
        return 'low';
      case 'High':
      case 'High priority':
        return 'high';
      case 'Medium':
        return 'normal';
      case 'Normal':
      default:
        return 'normal';
    }
  }
}
