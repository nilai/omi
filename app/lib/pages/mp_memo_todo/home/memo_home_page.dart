// AI-generated START - Memo/Todo 主页面
import 'package:flutter/material.dart';
import 'package:omi/pages/home/widgets/mp_battery_info_widget.dart';
import 'package:omi/pages/mp_custom_utils/mp_const_utils.dart';
import 'package:omi/pages/mp_memo_todo/home/widgets/memo_todo_switch_card.dart';
import 'package:omi/pages/mp_memo_todo/memo/memo_page.dart';
import 'package:omi/pages/mp_memo_todo/memo/providers/memo_provider.dart';
import 'package:omi/pages/mp_memo_todo/todo/providers/todo_provider.dart';
import 'package:omi/pages/mp_memo_todo/todo/todo_page.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/mp_common_app_bar.dart';
import 'package:omi/pages/mp_popup/new_memo_popup.dart';
import 'package:omi/pages/mp_popup/new_task_popup.dart';
import 'package:provider/provider.dart';

import 'widgets/mp_memo_app_bar.dart';

/// Memo/Todo 主页面
/// 顶部显示切换卡片，根据选择显示 Memo 或 Todo 页面
class MemoHomePage extends StatefulWidget {
  // AI-generated START - 构造函数
  const MemoHomePage({
    super.key,
    this.title = 'Memo & Todo',
  });
  // AI-generated END - 构造函数

  /// 页面标题
  final String title;

  // AI-generated START - 创建状态
  @override
  State<MemoHomePage> createState() => MemoHomePageState();
  // AI-generated END - 创建状态
}

class MemoHomePageState extends State<MemoHomePage> with AutomaticKeepAliveClientMixin {
  // AI-generated START - 当前选中的类型
  MemoTodoType _selectedType = MemoTodoType.memo;
  // AI-generated END - _selectedType

  @override
  bool get wantKeepAlive => true;

  // AI-generated START - 子页面的 GlobalKey
  final GlobalKey _memoPageKey = GlobalKey();
  final GlobalKey _todoPageKey = GlobalKey();
  // AI-generated END - 子页面的 GlobalKey

  // AI-generated START - 滚动到顶部
  void scrollToTop() {
    if (_selectedType == MemoTodoType.memo) {
      final memoState = _memoPageKey.currentState;
      if (memoState != null) {
        (memoState as dynamic).scrollToTop();
      }
    } else {
      final todoState = _todoPageKey.currentState;
      if (todoState != null) {
        (todoState as dynamic).scrollToTop();
      }
    }
  }
  // AI-generated END - scrollToTop

  // AI-generated START - 下拉刷新方法
  Future<void> _onRefresh() async {
    if (_selectedType == MemoTodoType.memo) {
      final memoProvider = Provider.of<MemoProvider>(context, listen: false);
      await memoProvider.loadMemos();
    } else {
      final todoProvider = Provider.of<TodoProvider>(context, listen: false);
      await todoProvider.loadTodos();
    }
  }
  // AI-generated END - _onRefresh

  // AI-generated START - 处理浮动按钮点击
  void _onFloatingActionButtonPressed() {
    if (_selectedType == MemoTodoType.memo) {
      // 打开创建 Memo 的弹窗
      NewMemoPopup.show(
        context: context,
        onSave: (content) async {
          // 调用 API 创建 Memo
          final memoProvider = Provider.of<MemoProvider>(context, listen: false);
          await memoProvider.createMemoWithText(content: content);
        },
      );
    } else {
      // 打开创建 Todo 的弹窗
      NewTaskPopup.show(
        context: context,
        showMarkComplete: false, // 显示 Mark complete 复选框
        showDeleteTask: false, // 显示删除任务按钮
        onComplete: (isCompleted, title, dueDate, priority) async {
          // 创建新的 Todo
          final todoProvider = Provider.of<TodoProvider>(context, listen: false);
          final now = DateTime.now();
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          final dateStr =
              dueDate != null ? '${months[dueDate.month - 1]} ${dueDate.day}' : '${months[now.month - 1]} ${now.day}';

          final priorityTag = priority != null
              ? (priority == TaskPriority.high
                  ? 'high'
                  : priority == TaskPriority.normal
                      ? 'normal'
                      : 'low')
              : 'normal';

          final newTodo = TodoTaskItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            description: '', // Todo 可能没有描述，或者可以从其他地方获取
            date: dateStr,
            priorityTag: priorityTag,
          );
          await todoProvider.addTodo(newTodo);
        },
      );
    }
  }
  // AI-generated END - _onFloatingActionButtonPressed

  // AI-generated START - 构建方法
  @override
  Widget build(BuildContext context) {
    super.build(context); // Important! Call super.build
    return Scaffold(
      backgroundColor: MPConstUtils.backgroundColorGrey,
      // appBar: MPCommonAppBar(
      //   customLeading: GestureDetector(
      //     onTap: () {
      //       MPBatteryInfoWidget.pushToFindDevicesPage(context);
      //     },
      //     child: const MPBatteryInfoWidget(),
      //   ),
      //   title: widget.title,
      //   showBackButton: false,
      // ),
      appBar: MPMemoAppBar(
        title: widget.title,
      ),
      body: Column(
        children: [
          // AI-generated START - 固定的切换卡片
          MemoTodoSwitchCard(
            selectedType: _selectedType,
            onTypeChanged: (type) {
              // 切换类型时，重置两个页面的活动卡片，还原左滑状态
              final memoState = _memoPageKey.currentState;
              if (memoState != null) {
                (memoState as dynamic).resetActiveCard();
              }
              final todoState = _todoPageKey.currentState;
              if (todoState != null) {
                (todoState as dynamic).resetActiveCard();
              }
              setState(() {
                _selectedType = type;
              });
            },
          ),
          // AI-generated END - 固定的切换卡片

          // AI-generated START - 根据选择显示对应页面（带下拉刷新）
          Expanded(
            child: NotificationListener<ScrollNotification>(
              child: IndexedStack(
                index: _selectedType == MemoTodoType.memo ? 0 : 1,
                children: [
                  MemoPage(key: _memoPageKey),
                  TodoPage(key: _todoPageKey),
                ],
              ),
            ),
          ),
          // AI-generated END - 根据选择显示对应页面
        ],
      ),
      // AI-generated START - 浮动操作按钮
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60.0), // 避免与底部导航栏重叠
        child: FloatingActionButton(
          heroTag: 'memo_todo_fab',
          onPressed: _onFloatingActionButtonPressed,
          backgroundColor: Colors.blue,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 32.0, // 增大图标尺寸
          ),
        ),
      ),
      // AI-generated END - 浮动操作按钮
    );
  }
  // AI-generated END - 构建方法
}
// AI-generated END - memo_home_page.dart
