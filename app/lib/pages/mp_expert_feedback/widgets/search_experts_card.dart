// AI-generated START - 搜索专家卡片组件
import 'package:flutter/material.dart';

/// 搜索专家卡片组件
/// 显示搜索输入框，用于搜索AI专家
class MPExpertSearchCard extends StatefulWidget {
  // AI-generated START - 搜索回调
  final Function(String query)? onSearchChanged;
  // AI-generated END - onSearchChanged

  // AI-generated START - 占位符文本
  final String? placeholder;
  // AI-generated END - placeholder

  const MPExpertSearchCard({
    super.key,
    this.onSearchChanged,
    this.placeholder,
  });

  @override
  State<MPExpertSearchCard> createState() => _MPExpertSearchCardState();
}

class _MPExpertSearchCardState extends State<MPExpertSearchCard> {
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
    return Column(children: [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        height: 46.0,
        child: TextField(
          controller: _searchController,
          cursorColor: Colors.black,
          onChanged: (value) {
            widget.onSearchChanged?.call(value);
          },
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14.0,
          ),
          decoration: InputDecoration(
            hintText: widget.placeholder ?? '搜索AI专家...',
            hintStyle: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14.0,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(
                'assets/images/mp_memo_search.png',
                width: 18.0,
                height: 18.0,
                fit: BoxFit.contain,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1.0,
              ),
            ),
          ),
        ),
      ),
      const Text(
        '添加成为小助理，让他们随时提供反馈',
        style: TextStyle(fontSize: 12.0, color: Color(0xFF6B7280)),
      ),
    ]);
  }
}
// AI-generated END - search_experts_card.dart
