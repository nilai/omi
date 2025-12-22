// AI-generated START - Todo 页面
import 'package:flutter/material.dart';
import 'package:omi/pages/mp_memo_todo/home/widgets/search_tasks_card.dart';
import 'package:omi/pages/mp_memo_todo/todo/providers/todo_provider.dart';
import 'package:omi/pages/mp_memo_todo/todo/widgets/todo_task_card.dart';
import 'package:omi/pages/mp_popup/new_task_popup.dart';
import 'package:provider/provider.dart';

/// Todo 页面
/// 显示 Todo 任务列表，支持搜索、下拉刷新和上拉加载
class TodoPage extends StatefulWidget {
  // AI-generated START - 构造函数
  const TodoPage({
    super.key,
    this.title = 'Todo',
  });
  // AI-generated END - 构造函数

  /// 页面标题
  final String title;

  // AI-generated START - 创建状态
  @override
  State<TodoPage> createState() => _TodoPageState();
  // AI-generated END - 创建状态
}

class _TodoPageState extends State<TodoPage> {
  // AI-generated START - 滚动控制器
  final ScrollController _scrollController = ScrollController();
  // AI-generated END - _scrollController

  // AI-generated START - 初始化方法
  @override
  void initState() {
    super.initState();
    // AI-generated START - 添加滚动监听
    _scrollController.addListener(_onScroll);
    // AI-generated END - 添加滚动监听
    // AI-generated START - 初始化 Todo 数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 获取 TodoProvider 实例，用于后续数据加载
      final provider = Provider.of<TodoProvider>(context, listen: false);
      // 加载 Todo 数据
      provider.loadTodos();
    });
    // AI-generated END - 初始化 Todo 数据
  }
  // AI-generated END - 初始化方法

  // AI-generated START - 清理资源
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  // AI-generated END - 清理资源

  // AI-generated START - 滚动监听方法
  void _onScroll() {
    final provider = Provider.of<TodoProvider>(context, listen: false);
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!provider.isFetching && provider.hasMore) {
        provider.loadMoreTodos();
      }
    }
  }
  // AI-generated END - _onScroll

  // AI-generated START - 下拉刷新方法
  Future<void> _onRefresh() async {
    final provider = Provider.of<TodoProvider>(context, listen: false);
    await provider.loadTodos();
  }
  // AI-generated END - _onRefresh

  // AI-generated START - 滚动到顶部
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }
  // AI-generated END - scrollToTop

  // AI-generated START - 构建方法
  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        return Column(
          children: [
            // AI-generated START - 固定的搜索条
            SearchTasksCard(
              placeholder: 'Search ${todoProvider.todos.length} Todos',
              onSearchChanged: (query) {
                // 搜索功能暂时不实现
                todoProvider.setSearchQuery(query);
              },
            ),
            // AI-generated END - 固定的搜索条

            // AI-generated START - 可滚动的列表内容
            Expanded(
              child: _buildBody(todoProvider),
            ),
            // AI-generated END - 可滚动的列表内容
          ],
        );
      },
    );
  }
  // AI-generated END - 构建方法

  // AI-generated START - 构建页面主体
  Widget _buildBody(TodoProvider provider) {
    if (provider.isLoading && provider.todos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.error != null && provider.todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadTodos(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (provider.filteredTodos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              provider.searchQuery.isEmpty ? '暂无Todo' : '未找到相关Todo',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // AI-generated START - Todo 列表（带下拉刷新和上拉加载）
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: provider.filteredTodos.length + (provider.hasMore && provider.isFetching ? 1 : 0),
        itemBuilder: (context, index) {
          // 显示加载更多指示器
          if (index == provider.filteredTodos.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          final todo = provider.filteredTodos[index];
          return TodoTaskCard(
            id: todo.id,
            title: todo.title,
            description: todo.description,
            date: todo.date,
            priorityTag: todo.priorityTag,
            status: todo.status,
            onTap: () {
              // 解析日期字符串（可能是 "Dec 20" 或 "YYYY-MM-DD" 格式）
              DateTime? parsedDate;
              try {
                if (todo.date.contains('-')) {
                  // 格式是 "YYYY-MM-DD"
                  parsedDate = DateTime.parse(todo.date);
                } else {
                  // 格式是 "Dec 20"，需要转换为当前年份的日期
                  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  final parts = todo.date.split(' ');
                  if (parts.length == 2) {
                    final monthIndex = months.indexOf(parts[0]);
                    if (monthIndex != -1) {
                      final day = int.tryParse(parts[1]) ?? DateTime.now().day;
                      final now = DateTime.now();
                      parsedDate = DateTime(now.year, monthIndex + 1, day);
                    }
                  }
                }
              } catch (e) {
                debugPrint('解析日期失败: ${todo.date}, 错误: $e');
                parsedDate = null;
              }

              // 解析优先级（priorityTag 可能是 "High", "Normal", "Low"，需要转换为小写匹配枚举）
              TaskPriority? parsedPriority;
              if (todo.priorityTag != null) {
                try {
                  parsedPriority = TaskPriority.values.firstWhere(
                    (e) => e.name.toLowerCase() == todo.priorityTag!.toLowerCase(),
                    orElse: () => TaskPriority.normal, // 如果找不到匹配项，使用默认值
                  );
                } catch (e) {
                  debugPrint('解析优先级失败: ${todo.priorityTag}, 错误: $e');
                  parsedPriority = null;
                }
              }

              NewTaskPopup.show(
                context: context,
                initialTitle: todo.title,
                initialDueDate: parsedDate,
                initialPriority: parsedPriority,
                showMarkComplete: true, // 显示 Mark complete 复选框
                showDeleteTask: true, // 显示删除任务按钮
                isCompleted: todo.status == 2 ? true : false, // 初始完成状态
                onDelete: () async {
                  await provider.deleteTodo(todo.id);
                  // 处理删除操作
                },
                onComplete: (isCompleted, title, dueDate, priority) async {
                  final now = DateTime.now();
                  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  final dateStr = dueDate != null
                      ? '${months[dueDate.month - 1]} ${dueDate.day}'
                      : '${months[now.month - 1]} ${now.day}';

                  final priorityTag = priority != null
                      ? (priority == TaskPriority.high
                          ? 'High'
                          : priority == TaskPriority.normal
                              ? 'Normal'
                              : 'Low')
                      : 'Normal';
                  // 处理完成操作
                  await provider.updateTodoWithRequest(
                      todoId: todo.id, title: title, priority: priorityTag, deadline: dateStr);
                },
              );
            },
            onComplete: () async {
              await provider.completeTodo(todo.id);
            },
            onDelete: () async {
              await provider.deleteTodo(todo.id);
            },
          );
        },
      ),
    );
    // AI-generated END - Todo 列表
  }
  // AI-generated END - _buildBody
}
// AI-generated END - todo_page.dart
