// AI-generated START - 声纹识别卡片组件，显示声纹识别管理入口
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';

/// 声纹识别卡片组件
/// 显示声纹识别入口，包含图标、标题、描述和导航箭头
class VoiceprintRecognitionCardWidget extends StatelessWidget {
  // AI-generated START - 卡片点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  // AI-generated START - 标题文本
  final String? title;
  // AI-generated END - title

  // AI-generated START - 描述文本
  final String? description;
  // AI-generated END - description

  const VoiceprintRecognitionCardWidget({
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // AI-generated START - 左侧：声纹图标
              ClipOval(
                child: Assets.images.settingVoiceprint.image(
                  fit: BoxFit.cover,
                  width: 56.0,
                  height: 56.0,
                ),
              ),
              // AI-generated END - 左侧：声纹图标

              const SizedBox(width: 16.0),

              // AI-generated START - 中间：标题和描述
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title ?? '声纹识别',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      description ?? '管理已保存的声音,提升识别准确度',
                      style: TextStyle(
                        color: Colors.grey.shade600,
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
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 24.0,
              ),
              // AI-generated END - 右侧：箭头图标
            ],
          ),
        ),
      ),
    );
  }
}
// AI-generated END - voiceprint_recognition_card_widget.dart
