// AI-generated START - 模板选择卡片组件，显示模板选择入口和描述信息
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';

/// 模板选择卡片组件
/// 显示模板选择入口，包含图标、标题、描述和导航箭头
class TemplateSelectionCardWidget extends StatelessWidget {
  // AI-generated START - 卡片点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  // AI-generated START - 标题文本
  final String? title;
  // AI-generated END - title

  // AI-generated START - 描述文本
  final String? description;
  // AI-generated END - description

  const TemplateSelectionCardWidget({
    super.key,
    this.onTap,
    this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // AI-generated START - 左侧：模板图标
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Assets.images.settingTemplate.image(
                  fit: BoxFit.cover,
                  width: 48.0,
                  height: 48.0,
                ),
              ),
              // AI-generated END - 左侧：模板图标

              const SizedBox(width: 12.0),

              // AI-generated START - 中间：标题和描述
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title ?? '模板社区',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      description ?? '选择AI总结模板，定制你的内容风格',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // AI-generated END - 中间：标题和描述

              const SizedBox(width: 12.0),

              // AI-generated START - 右侧：箭头图标
              Assets.images.mpRightArrowWhite.image(
                width: 21.0,
                height: 20.0,
                fit: BoxFit.contain,
              ),
              // AI-generated END - 右侧：箭头图标
            ],
          ),
        ),
      ),
    );
  }
}
// AI-generated END - template_selection_card_widget.dart
