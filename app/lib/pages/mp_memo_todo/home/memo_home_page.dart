// AI-generated START - Memo/Todo 主页面
import 'package:flutter/material.dart';
import 'package:omi/pages/mp_custom_utils/mp_const_utils.dart';
import 'package:omi/pages/mp_memo_todo/home/widgets/memo_todo_switch_card.dart';
import 'package:omi/pages/mp_memo_todo/memo/memo_page.dart';
import 'package:omi/pages/mp_memo_todo/todo/todo_page.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/mp_common_app_bar.dart';

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

  // AI-generated START - 构建方法
  @override
  Widget build(BuildContext context) {
    super.build(context); // Important! Call super.build
    return Scaffold(
      backgroundColor: MPConstUtils.backgroundColorGrey,
      appBar: MPCommonAppBar(
        title: widget.title,
        showBackButton: false,
      ),
      body: Column(
        children: [
          // AI-generated START - 固定的切换卡片
          MemoTodoSwitchCard(
            selectedType: _selectedType,
            onTypeChanged: (type) {
              setState(() {
                _selectedType = type;
              });
            },
          ),
          // AI-generated END - 固定的切换卡片

          // AI-generated START - 根据选择显示对应页面
          Expanded(
            child: IndexedStack(
              index: _selectedType == MemoTodoType.memo ? 0 : 1,
              children: [
                MemoPage(key: _memoPageKey),
                TodoPage(key: _todoPageKey),
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
