import 'package:memo_pin/common/mp_memory_todo_priority_kind.dart';

/// 服务端 Todo 优先级字符串与 [MPMemoryTodoPriorityKind] 的映射。
class MPTodoPriorityUtils {
  MPTodoPriorityUtils._();

  /// 将接口返回的 `priority` 字段转为本地枚举；无法识别时返回 [MPMemoryTodoPriorityKind.medium]。
  static MPMemoryTodoPriorityKind fromServerString(String priority) {
    final String p = priority.trim().toLowerCase();
    if (p.isEmpty) {
      return MPMemoryTodoPriorityKind.medium;
    }
    if (p == 'high' || p == 'urgent' || p == '1') {
      return MPMemoryTodoPriorityKind.high;
    }
    if (p == 'normal' || p == 'low') {
      return MPMemoryTodoPriorityKind.normal;
    }
    if (p == 'medium' || p == '2' || p == 'mid') {
      return MPMemoryTodoPriorityKind.medium;
    }
    return MPMemoryTodoPriorityKind.medium;
  }

  /// 列表 / 弹窗展示的优先级英文文案。
  static String labelForKind(MPMemoryTodoPriorityKind kind) {
    switch (kind) {
      case MPMemoryTodoPriorityKind.high:
        return 'High priority';
      case MPMemoryTodoPriorityKind.medium:
        return 'Medium';
      case MPMemoryTodoPriorityKind.normal:
        return 'Normal';
    }
  }
}
