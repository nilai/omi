// AI-generated START - 新增人物记忆卡片组件，显示添加人物记忆的入口
import 'package:flutter/material.dart';

/// 新增人物记忆卡片组件
/// 显示添加人物记忆的按钮和描述信息
class AddCharacterMemoryCard extends StatelessWidget {
  // AI-generated START - 按钮点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  // AI-generated START - 按钮文本
  final String? buttonText;
  // AI-generated END - buttonText

  // AI-generated START - 描述文本
  final String? description;
  // AI-generated END - description

  const AddCharacterMemoryCard({
    super.key,
    this.onTap,
    this.buttonText,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI-generated START - 渐变按钮
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF3B82F6), // 蓝色
                    Color(0xFF8B5CF6), // 紫色
                  ],
                ),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // AI-generated START - 左侧：图标
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: Colors.white,
                      size: 24.0,
                    ),
                  ),
                  // AI-generated END - 左侧：图标

                  const SizedBox(width: 12.0),

                  // AI-generated START - 中间：按钮文本
                  Expanded(
                    child: Text(
                      buttonText ?? '新增人物记忆',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // AI-generated END - 中间：按钮文本
                ],
              ),
            ),
          ),
          // AI-generated END - 渐变按钮

          // AI-generated START - 描述文本
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0, left: 4.0, right: 4.0),
              child: Text(
                description!,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13.0,
                  height: 1.5,
                ),
              ),
            ),
          // AI-generated END - 描述文本
        ],
      ),
    );
  }
}
// AI-generated END - add_character_memory_card.dart
