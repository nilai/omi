import 'package:flutter/cupertino.dart';
import 'package:omi/business/memory/presentation/pages/mp_memo_list_page.dart';
import 'package:omi/business/memory/presentation/pages/mp_memory_detail_page.dart';
import 'package:omi/business/memory/presentation/pages/mp_people_page.dart';
import 'package:omi/business/projects/presentation/pages/mp_projects_page.dart';
import 'package:omi/business/shared/state/mp_business_controller.dart';

class MPMemoryTabPage extends StatefulWidget {
  const MPMemoryTabPage({
    super.key,
    required this.controller,
  });

  final MPBusinessController controller;

  @override
  State<MPMemoryTabPage> createState() => _MPMemoryTabPageState();
}

class _MPMemoryTabPageState extends State<MPMemoryTabPage> {
  int _segment = 0;

  final Map<int, Widget> _segments = const <int, Widget>{
    0: Text('All'),
    1: Text('People'),
    2: Text('Projects'),
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final memories = widget.controller.memories;
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text('Memory'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => MPMemoListPage(controller: widget.controller),
                  ),
                );
              },
              child: const Text('Memos'),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _segment,
                    children: _segments,
                    onValueChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _segment = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _buildSegmentContent(memories),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegmentContent(List memories) {
    if (_segment == 1) {
      return Center(
        child: CupertinoButton(
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => const MPPeoplePage(),
              ),
            );
          },
          child: const Text('进入 People 页面'),
        ),
      );
    }
    if (_segment == 2) {
      return Center(
        child: CupertinoButton(
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => MPProjectsPage(controller: widget.controller),
              ),
            );
          },
          child: const Text('进入 Projects 页面'),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final memory = memories[index];
        return GestureDetector(
          onLongPress: () {
            final todos = widget.controller.todos;
            showCupertinoModalPopup<void>(
              context: context,
              builder: (_) {
                return CupertinoActionSheet(
                  title: const Text('把该 Memory 关联到 Todo'),
                  actions: todos
                      .map(
                        (todo) => CupertinoActionSheetAction(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.controller.linkTodoToMemory(
                              todoId: todo.id,
                              memoryId: memory.id,
                            );
                          },
                          child: Text(todo.title),
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CupertinoListTile(
              title: Text(memory.title),
              subtitle: Text(memory.summary),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => MPMemoryDetailPage(memory: memory),
                  ),
                );
              },
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(memory.dateLabel),
                  Text(memory.hasAudio ? 'Audio' : 'Text'),
                ],
              ),
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemCount: memories.length,
    );
  }
}
