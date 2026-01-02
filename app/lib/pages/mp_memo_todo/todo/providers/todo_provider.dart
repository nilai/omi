// AI-generated START - Todo 状态管理Provider
import 'package:flutter/material.dart';
import 'package:omi/backend/http/mp_api/mp_todo.dart' as mp_todo_api;
import 'package:omi/backend/http/mp_api/mp_todo.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/mp/mp_data_model.dart';
import 'package:omi/backend/schema/mp/mp_todo.dart';
import 'package:omi/pages/mp_custom_utils/mp_toast_utils.dart';

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
class TodoProvider with ChangeNotifier {
  // AI-generated START - Todo 任务列表
  List<TodoTaskItem> _todos = [];
  // AI-generated END - _todos

  // AI-generated START - 是否正在加载
  bool _isLoading = false;
  // AI-generated END - _isLoading

  // AI-generated START - 是否正在获取更多数据
  bool _isFetching = false;
  // AI-generated END - _isFetching

  // AI-generated START - 是否还有更多数据
  bool _hasMore = true;
  // AI-generated END - _hasMore

  // AI-generated START - 页码
  int _pageNo = 0;
  // AI-generated END - _pageNo

  // AI-generated START - 错误信息
  String? _error;
  // AI-generated END - _error

  // AI-generated START - 搜索关键词
  String _searchQuery = '';
  // AI-generated END - _searchQuery

  // AI-generated START - 总数量
  int _totalCount = 0;
  // AI-generated END - _totalCount

  // AI-generated START - 获取 Todo 任务列表
  List<TodoTaskItem> get todos => _todos;
  // AI-generated END - todos

  // AI-generated START - 获取总数量
  int get totalCount => _totalCount;
  // AI-generated END - totalCount

  // AI-generated START - 获取是否正在加载
  bool get isLoading => _isLoading;
  // AI-generated END - isLoading

  // AI-generated START - 获取是否正在获取更多数据
  bool get isFetching => _isFetching;
  // AI-generated END - isFetching

  // AI-generated START - 获取是否还有更多数据
  bool get hasMore => _hasMore;
  // AI-generated END - hasMore

  // AI-generated START - 获取错误信息
  String? get error => _error;
  // AI-generated END - error

  // AI-generated START - 获取搜索关键词
  String get searchQuery => _searchQuery;
  // AI-generated END - searchQuery

  // AI-generated START - 获取过滤后的 Todo 任务列表
  List<TodoTaskItem> get filteredTodos {
    // 搜索功能暂时不实现，直接返回所有数据
    return _todos;
  }
  // AI-generated END - filteredTodos

  // AI-generated START - 设置加载状态
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  // AI-generated END - setLoading

  // AI-generated START - 设置错误信息
  void setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
  // AI-generated END - setError

  // AI-generated START - 设置搜索关键词（暂时空实现）
  void setSearchQuery(String query) {
    _searchQuery = query;
    // 搜索功能暂时不实现
    notifyListeners();
  }
  // AI-generated END - setSearchQuery

  // AI-generated START - 加载 Todo 任务列表
  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners();
    _pageNo = 0; // 重置页码为第一页
    final request = MPGetTodoListRequest(
      pageSize: 20, // 每页数量
      pageno: _pageNo, // 页码，首次加载为第一页
    );

    final response = await getTodoList(request);

    if (response != null) {
      // 检查响应状态
      // 将 API 返回的数据转换为 TodoTaskItem
      final list = response.todos.map((todo) => _convertToTodoTaskItem(todo)).toList();
      _hasMore = response.hasMore;
      _pageNo ++;
      // 更新总数量
      if (response.totalCount != null) {
        _totalCount = response.totalCount!;
      }
      _todos.clear();
      _todos = list;
    }

    _isLoading = false;
    notifyListeners();
  }
  // AI-generated END - loadTodos

  // AI-generated START - 加载更多 Todo 任务
  Future<void> loadMoreTodos() async {
    if (_isFetching || !_hasMore) return;

    _isFetching = true;

    // 调用 API 加载更多 Todo 数据
    final request = MPGetTodoListRequest(
      pageSize: 20, // 每页数量
      pageno: _pageNo, // 使用下一页页码
    );

    final response = await getTodoList(request);

    if (response != null) {
      // 将 API 返回的数据转换为 TodoTaskItem 并追加到列表
      final moreTodos = response.todos.map((todo) => _convertToTodoTaskItem(todo)).toList();
      _todos.addAll(moreTodos);
      _hasMore = response.hasMore;
    }
    _isFetching = false;
    notifyListeners();
  }
  // AI-generated END - loadMoreTodos

// AI-generated START - 创建 Todo 任务
  /// 通过 API 创建 Todo 任务
  /// [title] 任务标题
  /// [priority] 优先级（high, normal, low）
  /// [deadline] 截止日期（ISO 8601 格式字符串，如 "2025-01-15"）
  /// 返回 true 表示创建成功，false 表示创建失败
  Future<bool> createTodo({
    required String title,
    String priority = 'normal',
    String? deadline,
  }) async {
    try {
      // 获取用户ID
      final ownerId = SharedPreferencesUtil().uid;
      // 如果没有提供截止日期，使用当前日期
      final deadlineStr = deadline ?? DateTime.now().toIso8601String().split('T')[0];

      // 创建请求
      final request = MPCreateTodoRequest(
        title: title,
        ownerId: ownerId,
        priority: priority,
        deadline: deadlineStr,
      );

      // 调用 API
      final response = await mp_todo_api.createTodo(request);

      if (response != null) {
        // 检查响应状态
        if (response.baseResp.code == 0) {
          debugPrint('Todo 创建成功');
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
        await loadTodos();
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

  // AI-generated START - 通过 API 更新 Todo 任务
  /// 通过 API 更新 Todo 任务
  /// [todoId] Todo 的 ID
  /// [title] 任务标题
  /// [priority] 优先级（high, normal, low）
  /// [deadline] 截止日期（ISO 8601 格式字符串，如 "2025-01-15"）
  /// 返回 true 表示更新成功，false 表示更新失败
  Future<bool> updateTodoWithRequest({
    required String todoId,
    required String title,
    required String priority,
    required String deadline,
    required bool isCompleted,
  }) async {
    try {
      // 参数判空处理
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
      if (deadline.isEmpty) {
        MPToastUtils.showMessage('截止日期不能为空');
        return false;
      }

      // 创建请求
      final request = MPUpdateTodoRequest(
        todoId: todoId,
        title: title.trim(),
        priority: priority,
        deadline: deadline,
        isCompleted: isCompleted,
      );

      // 调用 API
      final response = await mp_todo_api.updateTodo(request);

      if (response != null) {
        // 检查响应状态
        if (response.baseResp.code == 0) {
          MPToastUtils.showMessage('Todo 更新成功');
          
          // 检查是否是更新为完成状态
          final index = _todos.indexWhere((t) => t.id == todoId);
          final wasCompleted = index != -1 && _todos[index].status == 2;
          final isNowCompleted = isCompleted;
          
          // 如果是从未完成变为完成，则刷新整个列表
          if (!wasCompleted && isNowCompleted) {
            await loadTodos();
            return true;
          }
          
          // 其他字段修改（title、priority、deadline）或取消完成，只更新本地卡片
          if (index != -1) {
            final existingTodo = _todos[index];
            // 解析 deadline 日期
            DateTime deadlineDate;
            try {
              if (deadline.contains('-')) {
                final parts = deadline.split('T')[0].split('-');
                if (parts.length == 3) {
                  final year = int.tryParse(parts[0]);
                  final month = int.tryParse(parts[1]);
                  final day = int.tryParse(parts[2]);
                  if (year != null && month != null && day != null) {
                    deadlineDate = DateTime(year, month, day).toLocal();
                  } else {
                    deadlineDate = DateTime.parse(deadline).toLocal();
                  }
                } else {
                  deadlineDate = DateTime.parse(deadline).toLocal();
                }
              } else {
                deadlineDate = DateTime.parse(deadline).toLocal();
              }
            } catch (e) {
              deadlineDate = DateTime.now();
            }
            
            // 格式化 priority
            String? priorityTag;
            if (priority.isNotEmpty) {
              if (priority.length == 1) {
                priorityTag = priority.toUpperCase();
              } else {
                priorityTag = priority.substring(0, 1).toUpperCase() + priority.substring(1).toLowerCase();
              }
            }
            
            // 更新本地 todo 项，保留原有的 description，更新其他字段
            _todos[index] = TodoTaskItem(
              id: existingTodo.id,
              title: title.trim(),
              description: existingTodo.description, // 保留原有描述
              date: _formatDate(deadlineDate),
              priorityTag: priorityTag,
              status: isCompleted ? 2 : existingTodo.status, // 如果完成则设为2，否则保留原状态
            );
            notifyListeners();
          }
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
  // AI-generated END - updateTodoWithRequest

  // AI-generated START - 更新 Todo 任务
  void updateTodo(String id, TodoTaskItem updatedTodo) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos[index] = updatedTodo;
      notifyListeners();
    }
  }
  // AI-generated END - updateTodo

  // AI-generated START - 完成 Todo 任务
  /// 通过 API 完成 Todo 任务
  /// [id] Todo 的 ID
  /// 返回 true 表示完成成功，false 表示完成失败
  Future<bool> completeTodo(String id) async {
    try {
      // 创建完成请求
      final request = MPDoneTodoRequest(todoId: id);

      // 调用 API
      final response = await mp_todo_api.doneTodo(request);

      if (response != null) {
        // 检查响应状态
        if (response.baseResp.code == 0) {
          debugPrint('Todo 完成成功');
          // 直接更新本地状态：将任务状态更新为已完成（2）
          final index = _todos.indexWhere((t) => t.id == id);
          if (index != -1) {
            final todo = _todos[index];
            // 更新任务状态为已完成（2）
            _todos[index] = TodoTaskItem(
              id: todo.id,
              title: todo.title,
              description: todo.description,
              date: todo.date,
              priorityTag: todo.priorityTag,
              status: 2, // 2-已完成
            );
            notifyListeners();
          }
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

  // AI-generated START - 删除 Todo 任务
  /// 通过 API 删除 Todo 任务
  /// [id] Todo 的 ID
  /// 返回 true 表示删除成功，false 表示删除失败
  Future<bool> deleteTodo(String id) async {
    try {
      // 创建删除请求
      final request = MPDeleteTodoRequest(todoId: id);

      // 调用 API
      final response = await mp_todo_api.deleteTodo(request);

      if (response != null) {
        // 检查响应状态
        if (response.baseResp.code == 0) {
          debugPrint('Todo 删除成功');
          // 从本地列表中删除
          _todos.removeWhere((t) => t.id == id);
          // 总数量减1
          if (_totalCount > 0) {
            _totalCount--;
          }
          notifyListeners();
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

  // AI-generated START - 清空 Todo 列表
  void clearTodos() {
    _todos.clear();
    notifyListeners();
  }
  // AI-generated END - clearTodos

  // AI-generated START - 格式化日期
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
  // AI-generated END - _formatDate

  // AI-generated START - 将 MPTodoStruct 转换为 TodoTaskItem
  TodoTaskItem _convertToTodoTaskItem(MPTodoStruct todo) {
    // 解析 deadline 日期字符串
    DateTime deadlineDate;
    try {
      if (todo.deadline.isEmpty) {
        // 如果 deadline 为空，使用当前日期
        deadlineDate = DateTime.now();
      } else if (todo.deadline.contains('-')) {
        // 格式是 "YYYY-MM-DD" 或 "YYYY-MM-DDTHH:mm:ss"
        final parts = todo.deadline.split('T')[0].split('-');
        if (parts.length == 3) {
          final year = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final day = int.tryParse(parts[2]);
          if (year != null && month != null && day != null) {
            deadlineDate = DateTime(year, month, day).toLocal();
          } else {
            throw FormatException('无法解析日期部分: ${todo.deadline}');
          }
        } else {
          // 尝试使用 DateTime.parse
          deadlineDate = DateTime.parse(todo.deadline).toLocal();
        }
      } else {
        // 格式可能是 "Dec 25"，需要转换为当前年份的日期
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final parts = todo.deadline.trim().split(' ');
        if (parts.length == 2) {
          final monthIndex = months.indexOf(parts[0]);
          if (monthIndex != -1) {
            final day = int.tryParse(parts[1]) ?? DateTime.now().day;
            final now = DateTime.now();
            deadlineDate = DateTime(now.year, monthIndex + 1, day).toLocal();
          } else {
            throw FormatException('无法解析月份: ${todo.deadline}');
          }
        } else {
          // 尝试使用 DateTime.parse
          deadlineDate = DateTime.parse(todo.deadline).toLocal();
        }
      }
    } catch (e) {
      // 如果解析失败，使用当前日期
      debugPrint('解析 deadline 失败: ${todo.deadline}, 错误: $e, 使用当前日期');
      deadlineDate = DateTime.now();
    }

    // 将 priority 转换为 priorityTag（可能需要根据实际 API 返回的格式调整）
    String? priorityTag;
    if (todo.priority.isNotEmpty) {
      // 假设 priority 可能是 "high", "normal", "low" 等，转换为首字母大写的格式
      if (todo.priority.length == 1) {
        priorityTag = todo.priority.toUpperCase();
      } else {
        priorityTag = todo.priority.substring(0, 1).toUpperCase() + todo.priority.substring(1).toLowerCase();
      }
    }

    return TodoTaskItem(
      id: todo.id,
      title: todo.title,
      description: todo.owner.name, // 使用 owner 的 name 作为 description，或者可以根据需要调整
      date: _formatDate(deadlineDate),
      priorityTag: priorityTag,
      status: todo.status,
    );
  }
  // AI-generated END - _convertToTodoTaskItem
}
// AI-generated END - todo_provider.dart
