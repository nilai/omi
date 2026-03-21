import 'package:flutter/cupertino.dart';
import 'package:omi/business/shared/state/mp_business_controller.dart';

/// Todo 详情页：与 Home 弹层同一套操作（Mark done / Not now / Delete / 关联 Memory）
class MPTodoDetailPage extends StatelessWidget {
  const MPTodoDetailPage({
    super.key,
    required this.controller,
    required this.todoId,
  });

  final MPBusinessController controller;
  final String todoId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final todo = controller.getTodoById(todoId);
        if (todo == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          });
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text('Todo Detail'),
            ),
            child: SafeArea(
              child: Center(child: CupertinoActivityIndicator()),
            ),
          );
        }

        final linked = todo.linkedMemoryId == null
            ? null
            : controller.getMemoryById(todo.linkedMemoryId!);

        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Todo Detail'),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  todo.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text('分类: ${todo.category}'),
                Text('状态: ${todo.completed ? '已完成' : '待处理'}'),
                Text('截止: ${todo.dueLabel ?? '未设置'}'),
                Text('关联记忆: ${linked?.title ?? '未关联'}'),
                const SizedBox(height: 20),
                CupertinoButton.filled(
                  onPressed: () {
                    controller.markTodoDone(todo.id);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Mark done'),
                ),
                CupertinoButton(
                  onPressed: () {
                    controller.moveTodoToToday(todo.id);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Not now（移到 Today）'),
                ),
                CupertinoButton(
                  onPressed: () {
                    showCupertinoDialog<void>(
                      context: context,
                      builder: (ctx) => CupertinoAlertDialog(
                        title: const Text('删除 Todo'),
                        content: const Text('确定删除？此操作不可撤销。'),
                        actions: [
                          CupertinoDialogAction(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('取消'),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            onPressed: () {
                              Navigator.pop(ctx);
                              controller.deleteTodo(todo.id);
                              Navigator.of(context).pop();
                            },
                            child: const Text('删除'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                ),
                CupertinoButton(
                  onPressed: () {
                    final memories = controller.memories;
                    showCupertinoModalPopup<void>(
                      context: context,
                      builder: (_) {
                        return CupertinoActionSheet(
                          title: const Text('选择关联 Memory'),
                          actions: memories
                              .map(
                                (memory) => CupertinoActionSheetAction(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    controller.linkTodoToMemory(
                                      todoId: todo.id,
                                      memoryId: memory.id,
                                    );
                                  },
                                  child: Text(memory.title),
                                ),
                              )
                              .toList(),
                          cancelButton: CupertinoActionSheetAction(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('取消'),
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('关联 Memory'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
