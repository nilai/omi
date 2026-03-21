import 'package:flutter/cupertino.dart';
import 'package:omi/business/home/presentation/pages/mp_todo_detail_page.dart';
import 'package:omi/business/shared/models/mp_business_models.dart';
import 'package:omi/business/shared/state/mp_business_controller.dart';

/// 与 React 列表一致：按 Today / Up Next / Completed 分节展示
class MPTodoListPage extends StatelessWidget {
  const MPTodoListPage({
    super.key,
    required this.controller,
  });

  final MPBusinessController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final todos = controller.todos;
        final today = todos.where((t) => t.category == 'Today' && !t.completed).toList();
        final upNext = todos.where((t) => t.category == 'Up Next' && !t.completed).toList();
        final done = todos.where((t) => t.completed).toList();

        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Todo List'),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _MPTodoSection(
                  title: 'Today',
                  todos: today,
                  controller: controller,
                ),
                _MPTodoSection(
                  title: 'Up Next',
                  todos: upNext,
                  controller: controller,
                ),
                _MPTodoSection(
                  title: 'Completed',
                  todos: done,
                  controller: controller,
                ),
                if (today.isEmpty && upNext.isEmpty && done.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(
                      child: Text(
                        '暂无 Todo',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MPTodoSection extends StatelessWidget {
  const _MPTodoSection({
    required this.title,
    required this.todos,
    required this.controller,
  });

  final String title;
  final List<MPTodo> todos;
  final MPBusinessController controller;

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 8),
          ...todos.map(
            (todo) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CupertinoListTile(
                title: Text(todo.title),
                subtitle: Text('${todo.category} · ${todo.dueLabel ?? '无截止时间'}'),
                trailing: Text(todo.completed ? 'Done' : 'Todo'),
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => MPTodoDetailPage(
                        controller: controller,
                        todoId: todo.id,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
