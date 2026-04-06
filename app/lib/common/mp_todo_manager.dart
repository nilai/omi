import 'package:flutter/material.dart';
import 'package:memo_pin/common/mp_todo_notification.dart';
import 'package:memo_pin/http/api/mp_todo.dart' as MPTodo;
import 'package:memo_pin/http/schema/mp_todo.dart';
import 'package:memo_pin/utils/mp_preferences.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';


/// Todo 任务数据模型
class TodoTaskItem {
  // AI-generated START - 构造函数
  const TodoTaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.priorityTag,
    this.status,
  });
  // AI-generated END - 构造函数

  /// 任务ID
  final String id;

  /// 任务标题
  final String title;

  /// 任务描述
  final String description;

  /// 任务日期（格式：YYYY-MM-DD 或 Dec 16）
  final String date;

  /// 优先级标签（如：High, Normal, Low）
  final String? priorityTag;

  /// 任务状态（1-进行中，0-已删除，2-已完成, 3-已超期）
  final int? status;
}

/// Todo 状态管理Provider
/// 管理 Todo 任务列表数据
class MPTodoManager {

// AI-generated START - 创建 Todo 任务
  /// 通过 API 创建 Todo 任务
  /// [title] 任务标题
  /// [priority] 优先级（high, normal, low）
  /// [deadline] 截止日期（ISO 8601 格式字符串，如 "2025-01-15"）
  /// 返回 true 表示创建成功，false 表示创建失败
  Future<bool> createTodo({
    required String title,
    String priority = 'normal',
    /// `null` 表示使用当天日期（`YYYY-MM-DD`）；非 `null` 时原样提交（可为 `''` 或 Unix 秒字符串等，与接口约定一致）。
    String? deadline,
  }) async {
    try {
      final String deadlineStr =
          deadline ?? DateTime.now().toIso8601String().split('T')[0];

      // 创建请求
      final request = MPCreateTodoRequest(
        title: title,
        priority: priority,
        deadline: deadlineStr,
      );

      // 调用 API
      final response = await MPTodo.createTodo(request);

      if (response != null) {
        // 检查响应状态
        if (response.baseResp.code == 0) {
          debugPrint('Todo 创建成功');
          MPTodoNotification.notifyTodoCreated();
          return true;
        } else {
          debugPrint('创建 Todo 失败: ${response.baseResp.message}');
          return false;
        }
      } else {
        debugPrint('创建 Todo 失败: 响应为空');
        return false;
      }
    } catch (e) {
      debugPrint('创建 Todo 异常: $e');
      return false;
    }
  }
  // AI-generated END - createTodo

  // AI-generated START - 添加 Todo 任务
  /// 通过 API 创建 Todo 任务并添加到本地列表
  /// [todo] Todo 任务项
  /// 返回 true 表示创建成功，false 表示创建失败
  Future<bool> addTodo(TodoTaskItem todo) async {
    try {
      // 转换 priorityTag 为 API 需要的格式（小写）
      String priority = 'normal';
      if (todo.priorityTag != null) {
        priority = todo.priorityTag!.toLowerCase();
      }

      // 转换 date 为 API 需要的格式（ISO 8601）
      // date 格式可能是 "Dec 16" 或 "YYYY-MM-DD"
      String deadlineStr;
      try {
        // 尝试解析日期
        if (todo.date.contains('-')) {
          // 格式是 "YYYY-MM-DD"
          deadlineStr = todo.date;
        } else {
          // 格式是 "Dec 16"，需要转换为当前年份的日期
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          final parts = todo.date.split(' ');
          if (parts.length == 2) {
            final monthIndex = months.indexOf(parts[0]);
            final day = int.tryParse(parts[1]) ?? DateTime.now().day;
            final now = DateTime.now();
            final deadline = DateTime(now.year, monthIndex + 1, day);
            deadlineStr = deadline.toIso8601String().split('T')[0];
          } else {
            // 解析失败，使用当前日期
            deadlineStr = DateTime.now().toIso8601String().split('T')[0];
          }
        }
      } catch (e) {
        // 解析失败，使用当前日期
        deadlineStr = DateTime.now().toIso8601String().split('T')[0];
      }

      // 调用 API 创建 Todo
      final success = await createTodo(
        title: todo.title,
        priority: priority,
        deadline: deadlineStr,
      );

      if (success) {
        // 创建成功后，刷新列表以获取最新的数据
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('添加 Todo 异常: $e');
      return false;
    }
  }
  // AI-generated END - addTodo



  // AI-generated START - 完成 Todo 任务
  /// 通过 API 完成 Todo 任务
  /// [id] Todo 的 ID
  /// 返回 true 表示完成成功，false 表示完成失败
  Future<bool> completeTodo(String id) async {
    try {
      // 创建完成请求
      final request = MPDoneTodoRequest(todoId: id);

      // 调用 API
      final response = await MPTodo.doneTodo(request);

      if (response != null) {
        // 检查响应状态
        if (response.baseResp.code == 0) {
          debugPrint('Todo 完成成功');
          return true;
        } else {
          MPToastUtils.showMessage(response.baseResp.message);
          return false;
        }
      } else {
        MPToastUtils.showMessage('完成 Todo 失败: 响应为空');
        return false;
      }
    } catch (e) {
      MPToastUtils.showMessage('完成 Todo 异常: $e');
      return false;
    }
  }
  // AI-generated END - completeTodo

  /// 更新 Todo（含标记完成）；[deadline] 允许 `''`，与创建接口侧约定一致。
  Future<bool> updateTodoWithRequest({
    required String todoId,
    required String title,
    required String priority,
    required String deadline,
    required bool isCompleted,
  }) async {
    try {
      if (todoId.isEmpty) {
        MPToastUtils.showMessage('任务ID不能为空');
        return false;
      }
      if (title.trim().isEmpty) {
        MPToastUtils.showMessage('任务标题不能为空');
        return false;
      }
      if (priority.isEmpty) {
        MPToastUtils.showMessage('优先级不能为空');
        return false;
      }

      final request = MPUpdateTodoRequest(
        todoId: todoId,
        title: title.trim(),
        priority: priority,
        deadline: deadline,
        isCompleted: isCompleted,
      );

      final response = await MPTodo.updateTodo(request);

      if (response != null) {
        if (response.baseResp.code == 0) {
          MPToastUtils.showMessage('Todo 更新成功');
          return true;
        } else {
          MPToastUtils.showMessage(response.baseResp.message);
          return false;
        }
      } else {
        MPToastUtils.showMessage('更新 Todo 失败: 响应为空');
        return false;
      }
    } catch (e) {
      MPToastUtils.showMessage('更新 Todo 异常: $e');
      return false;
    }
  }
  // AI-generated START - 删除 Todo 任务
  /// 通过 API 删除 Todo 任务
  /// [id] Todo 的 ID
  /// 返回 true 表示删除成功，false 表示删除失败
  Future<bool> deleteTodo(String id) async {
    try {
      // 创建删除请求
      final request = MPDeleteTodoRequest(todoId: id);

      // 调用 API
      final response = await MPTodo.deleteTodo(request);

      if (response != null) {
        // 检查响应状态
        if (response.baseResp.code == 0) {
          debugPrint('Todo 删除成功');
         return true;
        } else {
          MPToastUtils.showMessage(response.baseResp.message);
          return false;
        }
      } else {
        MPToastUtils.showMessage('删除 Todo 失败: 响应为空');
        return false;
      }
    } catch (e) {
      MPToastUtils.showMessage('删除 Todo 异常: $e');
      return false;
    }
  }
  // AI-generated END - deleteTodo
}
