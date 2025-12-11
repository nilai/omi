// AI-generated START - Memo/Todo 主页面
import 'package:flutter/material.dart';
import 'package:omi/pages/mp_memo_todo/home/widgets/memo_todo_switch_card.dart';
import 'package:omi/pages/mp_memo_todo/memo/memo_page.dart';
import 'package:omi/pages/mp_memo_todo/todo/todo_page.dart';

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
  State<MemoHomePage> createState() => _MemoHomePageState();
  // AI-generated END - 创建状态
}

class _MemoHomePageState extends State<MemoHomePage> {
  // AI-generated START - 当前选中的类型
  MemoTodoType _selectedType = MemoTodoType.memo;
  // AI-generated END - _selectedType

  // AI-generated START - 构建方法
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // AI-generated START - 固定的切换卡片
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: MemoTodoSwitchCard(
              selectedType: _selectedType,
              onTypeChanged: (type) {
                setState(() {
                  _selectedType = type;
                });
              },
            ),
          ),
          // AI-generated END - 固定的切换卡片

          // AI-generated START - 根据选择显示对应页面
          Expanded(
            child: IndexedStack(
              index: _selectedType == MemoTodoType.memo ? 0 : 1,
              children: const [
                MemoPage(),
                TodoPage(),
              ],
            ),
          ),
          // AI-generated END - 根据选择显示对应页面
        ],
      ),
    );
  }
  // AI-generated END - 构建方法
}
// AI-generated END - memo_home_page.dart
