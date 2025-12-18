// AI-generated START - Todo 页面
import 'package:flutter/material.dart';
import 'package:omi/pages/mp_memo_todo/home/widgets/search_tasks_card.dart';
import 'package:omi/pages/mp_memo_todo/todo/providers/todo_provider.dart';
import 'package:omi/pages/mp_memo_todo/todo/widgets/todo_task_card.dart';
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
              // TODO: 导航到 Todo 详情页面
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
