import 'package:flutter/material.dart';
import 'package:memo_pin/common/mp_memory_todo_priority_kind.dart';
import 'package:memo_pin/common/mp_todo_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';

/// 服务端 Todo 优先级字符串与 [MPMemoryTodoPriorityKind] 的映射。
class MPTodoPriorityUtils {
  MPTodoPriorityUtils._();

  /// 将接口返回的 `priority` 字段转为本地枚举；无法识别时返回 [MPMemoryTodoPriorityKind.normal]。
  static MPMemoryTodoPriorityKind fromServerString(String priority) {
    final String p = priority.trim().toLowerCase();
    if (p.isEmpty) {
      return MPMemoryTodoPriorityKind.normal;
    }
    if (p == 'high' || p == 'urgent' || p == '1') {
      return MPMemoryTodoPriorityKind.high;
    }
    if (p == 'low') {
      return MPMemoryTodoPriorityKind.low;
    }
    if (p == 'normal' || p == 'medium' || p == '2' || p == 'mid') {
      return MPMemoryTodoPriorityKind.normal;
    }
    return MPMemoryTodoPriorityKind.normal;
  }

  /// 列表 / 弹窗展示的优先级英文文案。
  static String labelForKind(MPMemoryTodoPriorityKind kind) {
    switch (kind) {
      case MPMemoryTodoPriorityKind.high:
        return 'High priority';
      case MPMemoryTodoPriorityKind.normal:
        return 'Normal';
      case MPMemoryTodoPriorityKind.low:
        return 'Low priority';
    }
  }

  /// 优先级对应展示色。
  static Color colorForKind(MPMemoryTodoPriorityKind kind) {
    switch (kind) {
      case MPMemoryTodoPriorityKind.high:
        return todoPriorityHighColor;
      case MPMemoryTodoPriorityKind.normal:
        return todoPriorityNormalColor;
      case MPMemoryTodoPriorityKind.low:
        return todoPriorityLowColor;
    }
  }

  /// 接口 `priority` 字段 → 展示色。
  static Color colorForApi(String priority) {
    return colorForKind(fromServerString(priority));
  }

  /// 新建 / 编辑弹窗选项文案 → 展示色。
  static Color colorForPickerLabel(String label) {
    return colorForApi(MPTodoUtils.mapPriorityToApi(label));
  }
}
