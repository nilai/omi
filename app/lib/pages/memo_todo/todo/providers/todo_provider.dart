// AI-generated START - Todo 状态管理Provider
import 'package:flutter/material.dart';

/// Todo 任务数据模型
class TodoTaskItem {
  // AI-generated START - 构造函数
  const TodoTaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.priorityTag,
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

  // AI-generated START - 错误信息
  String? _error;
  // AI-generated END - _error

  // AI-generated START - 搜索关键词
  String _searchQuery = '';
  // AI-generated END - _searchQuery

  // AI-generated START - 获取 Todo 任务列表
  List<TodoTaskItem> get todos => _todos;
  // AI-generated END - todos

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

  // AI-generated START - 设置获取状态
  void setFetching(bool fetching) {
    _isFetching = fetching;
    notifyListeners();
  }
  // AI-generated END - setFetching

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
    setLoading(true);
    setError(null);
    _hasMore = true; // 重置 hasMore 状态
    try {
      // TODO: 从API或本地存储加载 Todo 数据
      await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络请求
      // AI-generated START - 默认测试数据
      final now = DateTime.now();
      _todos = [
        TodoTaskItem(
          id: '1',
          title: '确认设备不同模式下灯效需求',
          description: '评估设备充电状态不影响工作状态的实现',
          date: _formatDate(now.subtract(const Duration(days: 1))),
          priorityTag: 'Normal',
        ),
        TodoTaskItem(
          id: '2',
          title: '评估设备充电状态不影响工作状态的实现',
          description: '确保设备在充电时仍能正常工作，不影响用户体验',
          date: _formatDate(now.subtract(const Duration(days: 1))),
          priorityTag: 'High',
        ),
        TodoTaskItem(
          id: '3',
          title: '督促方案方明早给出两个时间预估',
          description: '联系方案方，要求提供项目时间预估',
          date: _formatDate(now.subtract(const Duration(days: 1))),
          priorityTag: 'Low',
        ),
        TodoTaskItem(
          id: '4',
          title: '完成用户界面优化方案',
          description: '设计新的交互流程，提升用户满意度',
          date: _formatDate(now.subtract(const Duration(days: 2))),
          priorityTag: 'High',
        ),
        TodoTaskItem(
          id: '5',
          title: '准备下周会议材料',
          description: '整理会议议程和相关文档',
          date: _formatDate(now.subtract(const Duration(days: 3))),
          priorityTag: 'Normal',
        ),
        TodoTaskItem(
          id: '6',
          title: '更新项目进度报告',
          description: '汇总本周项目进展，更新进度文档',
          date: _formatDate(now.subtract(const Duration(days: 4))),
          priorityTag: 'Low',
        ),
      ];
      // AI-generated END - 默认测试数据
      // 模拟：如果数据少于某个数量，则认为没有更多数据
      _hasMore = _todos.length >= 6; // 这里可以根据实际API响应调整
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
  // AI-generated END - loadTodos

  // AI-generated START - 加载更多 Todo 任务
  Future<void> loadMoreTodos() async {
    if (_isFetching || !_hasMore) return;

    setFetching(true);

    try {
      // TODO: 从API加载更多 Todo 数据
      await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络请求

      // AI-generated START - 模拟加载更多数据
      final now = DateTime.now();
      final moreTodos = [
        TodoTaskItem(
          id: '${_todos.length + 1}',
          title: '新增Todo任务${_todos.length + 1}',
          description: '新增的Todo数据，用于测试上拉加载功能',
          date: _formatDate(now.subtract(Duration(days: _todos.length + 7))),
          priorityTag: 'Normal',
        ),
      ];
      _todos.addAll(moreTodos);
      // 模拟：如果已加载超过10条，则认为没有更多数据
      _hasMore = _todos.length < 10;
      // AI-generated END - 模拟加载更多数据

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading more todos: $e');
    } finally {
      setFetching(false);
    }
  }
  // AI-generated END - loadMoreTodos

  // AI-generated START - 添加 Todo 任务
  void addTodo(TodoTaskItem todo) {
    _todos.insert(0, todo);
    notifyListeners();
  }
  // AI-generated END - addTodo

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
  void completeTodo(String id) {
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }
  // AI-generated END - completeTodo

  // AI-generated START - 删除 Todo 任务
  void deleteTodo(String id) {
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
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
}
// AI-generated END - todo_provider.dart
