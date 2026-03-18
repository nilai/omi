// AI-generated START - 搜索任务卡片组件
import 'package:flutter/material.dart';

/// 搜索任务卡片组件
/// 显示搜索输入框，用于搜索任务
class SearchTasksCard extends StatefulWidget {
  // AI-generated START - 搜索回调
  final Function(String query)? onSearchChanged;
  // AI-generated END - onSearchChanged

  // AI-generated START - 占位符文本
  final String? placeholder;
  // AI-generated END - placeholder

  const SearchTasksCard({
    super.key,
    this.onSearchChanged,
    this.placeholder,
  });

  @override
  State<SearchTasksCard> createState() => _SearchTasksCardState();
}

class _SearchTasksCardState extends State<SearchTasksCard> {
  // AI-generated START - 搜索控制器
  final TextEditingController _searchController = TextEditingController();
  // AI-generated END - _searchController

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
      child: TextField(
        controller: _searchController,
        cursorColor: Colors.black,
        onChanged: (value) {
          widget.onSearchChanged?.call(value);
        },
        style: const TextStyle(
          color: Color(0xFF374151),
          fontSize: 14.0,
        ),
        decoration: InputDecoration(
          hintText: widget.placeholder ?? 'Search Tasks',
          hintStyle: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 14.0,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/mp_memo_search.png',
              width: 14.0,
              height: 14.0,
              fit: BoxFit.contain,
            ),
          ),
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 10.0,
          ),
        ),
      ),
    );
  }
}
// AI-generated END - search_tasks_card.dart
