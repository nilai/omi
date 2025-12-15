// AI-generated START - 偏好设置卡片组件，显示偏好设置选项列表
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';
import 'package:omi/pages/mp_newsetting/home/providers/settings_provider.dart';
import 'package:omi/pages/mp_newsetting/setting/widgets/primary_language_dialog.dart';
import 'package:omi/pages/mp_newsetting/setting/widgets/transcription_mode_dialog.dart';
import 'package:omi/providers/home_provider.dart';
import 'package:provider/provider.dart';

/// 偏好设置项信息数据模型
class PreferenceSettingItem {
  // AI-generated START - 设置项标题
  final String title;
  // AI-generated END - title

  // AI-generated START - 设置项描述
  final String? description;
  // AI-generated END - description

  // AI-generated START - 当前选择的值（可选，用于显示当前选择）
  final String? currentValue;
  // AI-generated END - currentValue

  // AI-generated START - 图标
  final String? icon;
  // AI-generated END - icon

  // AI-generated START - 点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  const PreferenceSettingItem({
    required this.title,
    this.description,
    this.currentValue,
    required this.icon,
    this.onTap,
  });
}

/// 偏好设置卡片组件
/// 显示偏好设置选项列表，标题和设置项列表分开，便于扩展
class PreferenceSettingsCardWidget extends StatelessWidget {
  // AI-generated START - 卡片标题
  final String? title;
  // AI-generated END - title

  // AI-generated START - 偏好设置项列表
  final List<PreferenceSettingItem> items;
  // AI-generated END - items

  const PreferenceSettingsCardWidget({
    super.key,
    this.title,
    this.items = const [],
  });

  // AI-generated START - 获取默认偏好设置项列表
  static List<PreferenceSettingItem> getDefaultItems({BuildContext? context, SettingsProvider? settingsProvider}) {
    return [
      PreferenceSettingItem(
        title: 'AI偏好',
        description: '自定义AI助手的行为和风格',
        icon: Assets.images.settingAiperfect.path,
        onTap: () {
          // AI-generated START - 默认点击事件处理
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('打开AI偏好设置'),
                duration: Duration(seconds: 1),
              ),
            );
          }
          // AI-generated END - 默认点击事件处理
        },
      ),
      PreferenceSettingItem(
        title: '转写语言偏好',
        description: null,
        icon: Assets.images.settingLanguage.path,
        currentValue: context != null ? _getCurrentLanguageName(context) : 'Chinese (Mandarin, Simplified)',
        onTap: () {
          // AI-generated START - 打开主要语言选择弹窗
          if (context != null) {
            PrimaryLanguageDialog.show(context);
          }
          // AI-generated END - 打开主要语言选择弹窗
        },
      ),
      PreferenceSettingItem(
        title: '录音后转写',
        description: null,
        currentValue: settingsProvider != null
            ? (settingsProvider.transcriptionConfirmMode ? '确认后转写' : '默认立即转写')
            : (context != null ? _getTranscriptionModeText(context) : '默认立即转写'),
        icon: Assets.images.mpSettingVoice.path,
        onTap: () {
          // AI-generated START - 打开转写模式选择弹窗
          if (context != null) {
            TranscriptionModeDialog.show(context);
          }
          // AI-generated END - 打开转写模式选择弹窗
        },
      ),
    ];
  }
  // AI-generated END - getDefaultItems

  // AI-generated START - 获取当前语言名称
  static String _getCurrentLanguageName(BuildContext context) {
    try {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      if (homeProvider.userPrimaryLanguage.isNotEmpty) {
        return homeProvider.getLanguageName(homeProvider.userPrimaryLanguage);
      }
    } catch (e) {
      // 如果获取失败，返回默认值
    }
    return 'Chinese (Mandarin, Simplified)';
  }
  // AI-generated END - _getCurrentLanguageName

  // AI-generated START - 获取转写模式文本
  static String _getTranscriptionModeText(BuildContext context) {
    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      debugPrint('_getTranscriptionModeText - transcriptionConfirmMode: ${settingsProvider.transcriptionConfirmMode}');
      // 根据后台返回的转写模式显示不同的文本
      return settingsProvider.transcriptionConfirmMode ? '确认后转写' : '默认立即转写';
    } catch (e) {
      debugPrint('_getTranscriptionModeText - error: $e');
      // 如果获取失败，返回默认值
      return '默认立即转写';
    }
  }
  // AI-generated END - _getTranscriptionModeText

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 来监听 SettingsProvider 的变化，动态获取转写模式
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final itemsList = items.isEmpty
            ? PreferenceSettingsCardWidget.getDefaultItems(context: context, settingsProvider: settingsProvider)
            : items;

        return Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI-generated START - 标题区域（独立）
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
                  child: Text(
                    title!,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              // AI-generated END - 标题区域

              // AI-generated START - 设置项列表区域（独立，便于扩展）
              ...itemsList.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == itemsList.length - 1;

                return GestureDetector(
                  onTap: item.onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                        child: Row(
                          children: [
                            // AI-generated START - 左侧：图标
                            Image.asset(item.icon!, fit: BoxFit.cover, width: 32.0, height: 32.0),
                            // AI-generated END - 左侧：图标

                            const SizedBox(width: 8.0),

                            // AI-generated START - 中间：标题和描述
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (item.description != null) ...[
                                    const SizedBox(height: 2.0),
                                    Text(
                                      item.description!,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                  if (item.currentValue != null) ...[
                                    const SizedBox(height: 2.0),
                                    Text(
                                      item.currentValue!,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // AI-generated END - 中间：标题和描述

                            const SizedBox(width: 12.0),

                            // AI-generated START - 右侧：箭头图标
                            Assets.images.settingRightArrow1.image(
                              width: 19.0,
                              height: 18.0,
                              fit: BoxFit.contain,
                            ),
                            // AI-generated END - 右侧：箭头图标
                          ],
                        ),
                      ),

                      // AI-generated START - 底部边框（带左右边距）
                      if (!isLast)
                        Container(
                          margin: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 0.0),
                          height: 1.0,
                          color: Colors.grey.shade200,
                        ),
                      // AI-generated END - 底部边框
                    ],
                  ),
                );
              }),
              // AI-generated END - 设置项列表区域
              const SizedBox(height: 12.0),
            ],
          ),
        );
      },
    );
  }
  // AI-generated END - build
}
// AI-generated END - preference_settings_card_widget.dart
