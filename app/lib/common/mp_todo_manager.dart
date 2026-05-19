import 'package:flutter/material.dart';
import 'package:memo_pin/common/mp_todo_notification.dart';
import 'package:memo_pin/common/mp_todo_utils.dart';
import 'package:memo_pin/http/api/mp_todo.dart' as MPTodo;
import 'package:memo_pin/http/schema/mp_todo.dart';
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
  /// [priority] 优先级（High, Normal, Low）
  /// [deadline] Unix **秒**时间戳；`null` 时使用**当前时刻**的时间戳。
  /// 返回 true 表示创建成功，false 表示创建失败
  Future<bool> createTodo({
    required String title,
    String priority = 'Normal',
    int? deadline,
    String? memoryId,
    String? feedCardId,
  }) async {
    try {
      final int deadlineUnix = deadline ?? 0;

      // 创建请求
      final request = MPCreateTodoRequest(
        title: title,
        memoryId: memoryId,
        priority: priority,
        deadline: deadlineUnix,
        feedCardId: feedCardId,
      );

      // 调用 API
      final response = await MPTodo.createTodo(request);

      if (response != null) {
        // 检查响应状态
        if (response.baseResp.code == 0) {
          debugPrint('Todo created successfully');
          MPTodoNotification.notifyTodoCreated();
          return true;
        } else {
          debugPrint('Create todo failed: ${response.baseResp.message}');
          return false;
        }
      } else {
        debugPrint('Create todo failed: empty response');
        return false;
      }
    } catch (e) {
      debugPrint('Create todo error: $e');
      return false;
    }
  }
  // AI-generated END - createTodo

  /// Memory 等场景：已有 [todoId] 时走 update，否则走 create。
  ///
  /// 返回 `true` 表示成功，`false` 表示失败。
  Future<bool> createOrUpdateTodo({
    required String title,
    String? todoId,
    String? memoryId,
    String priority = 'Normal',
    int? deadline,
    String? feedCardId,
    int? preCreateStatus,
    String? source,
    String? insightId,
  }) async {
    try {
      final int deadlineUnix = deadline ?? 0;
      final String trimmedId = todoId?.trim() ?? '';

      if (trimmedId.isNotEmpty) {
        return updateTodoWithRequest(
          todoId: trimmedId,
          title: title,
          priority: priority,
          deadlineUnixSec: deadlineUnix,
          isCompleted: false,
          preCreateStatus: preCreateStatus,
          source: source,
        );
      }

      final MPCreateTodoRequest request = MPCreateTodoRequest(
        title: title,
        memoryId: memoryId,
        priority: priority,
        deadline: deadlineUnix,
        feedCardId: feedCardId,
        insightId: insightId,
      );
      final MPCreateTodoResponse? response = await MPTodo.createTodo(request);
      if (response == null) {
        debugPrint('Create todo failed: empty response');
        return false;
      }
      if (response.baseResp.code != 0) {
        debugPrint('Create todo failed: ${response.baseResp.message}');
        return false;
      }
      debugPrint('Todo created successfully');
      MPTodoNotification.notifyTodoCreated();
      return true;
    } catch (e) {
      debugPrint('createOrUpdateTodo error: $e');
      return false;
    }
  }

  // AI-generated START - 添加 Todo 任务
  /// 通过 API 创建 Todo 任务并添加到本地列表
  /// [todo] Todo 任务项
  /// 返回 true 表示创建成功，false 表示创建失败
  Future<bool> addTodo(TodoTaskItem todo) async {
    try {
      String priority = 'Normal';
      if (todo.priorityTag != null) {
        priority = MPTodoUtils.mapPriorityToApi(
          MPTodoUtils.normalizePriorityPickerLabel(todo.priorityTag!),
        );
      }

      // 转换 date 为 Unix 秒（date 可能是 "YYYY-MM-DD" 或 "Dec 16"）
      int deadlineUnix;
      try {
        if (todo.date.contains('-')) {
          final List<String> p = todo.date.split('-');
          if (p.length == 3) {
            final int? y = int.tryParse(p[0]);
            final int? m = int.tryParse(p[1]);
            final int? d = int.tryParse(p[2]);
            if (y != null && m != null && d != null) {
              deadlineUnix = DateTime(y, m, d).millisecondsSinceEpoch ~/ 1000;
            } else {
              deadlineUnix = 0;
            }
          } else {
            deadlineUnix = 0;
          }
        } else {
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          final parts = todo.date.split(' ');
          if (parts.length == 2) {
            final monthIndex = months.indexOf(parts[0]);
            final day = int.tryParse(parts[1]) ?? DateTime.now().day;
            final now = DateTime.now();
            final dt = DateTime(now.year, monthIndex + 1, day);
            deadlineUnix = dt.millisecondsSinceEpoch ~/ 1000;
          } else {
            deadlineUnix = 0;
          }
        }
      } catch (e) {
        deadlineUnix = 0;
      }

      // 调用 API 创建 Todo
      final success = await createTodo(title: todo.title, priority: priority, deadline: deadlineUnix);

      if (success) {
        // 创建成功后，刷新列表以获取最新的数据
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Add todo error: $e');
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
          debugPrint('Todo completed successfully');
          return true;
        } else {
          MPToastUtils.showMessage(response.baseResp.message);
          return false;
        }
      } else {
        MPToastUtils.showMessage('Couldn\'t complete to-do: empty response.');
        return false;
      }
    } catch (e) {
      MPToastUtils.showMessage('Error completing to-do: $e');
      return false;
    }
  }
  // AI-generated END - completeTodo

  /// 更新 Todo（含标记完成）；[deadlineUnixSec] 为 Unix 秒，空值按当前时间戳传。
  Future<bool> updateTodoWithRequest({
    required String todoId,
    required String title,
    required String priority,
    required int? deadlineUnixSec,
    required bool isCompleted,
    int? preCreateStatus,
    String? source,
  }) async {
    try {
      if (todoId.isEmpty) {
        MPToastUtils.showMessage('Task ID cannot be empty.');
        return false;
      }
      if (title.trim().isEmpty) {
        MPToastUtils.showMessage('Task title cannot be empty.');
        return false;
      }
      if (priority.isEmpty) {
        MPToastUtils.showMessage('Priority cannot be empty.');
        return false;
      }

      final int resolvedDeadline = deadlineUnixSec ?? 0;

      final request = MPUpdateTodoRequest(
        todoId: todoId,
        title: title.trim(),
        priority: priority,
        deadline: resolvedDeadline,
        isCompleted: isCompleted,
        preCreateStatus: preCreateStatus,
        source: source,
      );

      final response = await MPTodo.updateTodo(request);

      if (response != null) {
        if (response.baseResp.code == 0) {
          MPToastUtils.showMessage('To-do updated.');
          return true;
        } else {
          MPToastUtils.showMessage(response.baseResp.message);
          return false;
        }
      } else {
        MPToastUtils.showMessage('Couldn\'t update to-do: empty response.');
        return false;
      }
    } catch (e) {
      MPToastUtils.showMessage('Error updating to-do: $e');
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
          debugPrint('Todo deleted successfully');
          return true;
        } else {
          MPToastUtils.showMessage(response.baseResp.message);
          return false;
        }
      } else {
        MPToastUtils.showMessage('Couldn\'t delete to-do: empty response.');
        return false;
      }
    } catch (e) {
      MPToastUtils.showMessage('Error deleting to-do: $e');
      return false;
    }
  }

  // AI-generated END - deleteTodo
}
