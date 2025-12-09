// AI-generated START - 其他设置卡片组件，显示设置选项列表
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';

/// 设置项信息数据模型
class SettingItemInfo {
  // AI-generated START - 设置项标题
  final String title;
  // AI-generated END - title

  // AI-generated START - 图标
  final IconData icon;
  // AI-generated END - icon

  // AI-generated START - 图标背景颜色
  final Color iconBackgroundColor;
  // AI-generated END - iconBackgroundColor

  // AI-generated START - 图标图片（可选，优先使用图片）
  final AssetGenImage? iconImage;
  // AI-generated END - iconImage

  // AI-generated START - 点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  const SettingItemInfo({
    required this.title,
    required this.icon,
    required this.iconBackgroundColor,
    this.iconImage,
    this.onTap,
  });
}

/// 其他设置卡片组件
/// 显示设置选项列表，包含标题和多个设置项
class OtherSettingsCardWidget extends StatelessWidget {
  // AI-generated START - 卡片标题
  final String? title;
  // AI-generated END - title

  // AI-generated START - 设置项列表
  final List<SettingItemInfo> settings;
  // AI-generated END - settings

  const OtherSettingsCardWidget({
    super.key,
    this.title,
    this.settings = const [],
  });

  // AI-generated START - 获取默认设置项列表
  static List<SettingItemInfo> getDefaultSettings() {
    return [
      SettingItemInfo(
        title: '数据导出',
        icon: Icons.download,
        iconBackgroundColor: const Color(0xFFFF9800), // 橙色
        iconImage: Assets.images.settingDownload,
      ),
      SettingItemInfo(
        title: '意见反馈',
        icon: Icons.feedback,
        iconBackgroundColor: const Color(0xFFFFC107), // 黄色
        iconImage: Assets.images.settingFeedback,
      ),
      SettingItemInfo(
        title: '帮助中心',
        icon: Icons.help_outline,
        iconBackgroundColor: const Color(0xFF00BCD4), // 青色
        iconImage: Assets.images.settingHelp,
      ),
      SettingItemInfo(
        title: '关于应用',
        icon: Icons.info_outline,
        iconBackgroundColor: Colors.grey.shade600, // 灰色
        iconImage: Assets.images.settingAbout,
      ),
    ];
  }
  // AI-generated END - getDefaultSettings

  @override
  Widget build(BuildContext context) {
    final settingsList = settings.isEmpty ? OtherSettingsCardWidget.getDefaultSettings() : settings;

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
          // AI-generated START - 标题
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 16.0),
              child: Text(
                title!,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          // AI-generated END - 标题

          // AI-generated START - 设置项列表
          ...settingsList.asMap().entries.map((entry) {
            final index = entry.key;
            final setting = entry.value;
            final isLast = index == settingsList.length - 1;

            return GestureDetector(
              onTap: setting.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1.0,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    // AI-generated START - 左侧：图标
                    Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: setting.iconBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: setting.iconImage != null
                          ? ClipOval(
                              child: setting.iconImage!.image(
                                fit: BoxFit.cover,
                                width: 40.0,
                                height: 40.0,
                              ),
                            )
                          : Icon(
                              setting.icon,
                              color: Colors.white,
                              size: 20.0,
                            ),
                    ),
                    // AI-generated END - 左侧：图标

                    const SizedBox(width: 16.0),

                    // AI-generated START - 中间：标题
                    Expanded(
                      child: Text(
                        setting.title,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    // AI-generated END - 中间：标题

                    // AI-generated START - 右侧：箭头
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 20.0,
                    ),
                    // AI-generated END - 右侧：箭头
                  ],
                ),
              ),
            );
          }),
          // AI-generated END - 设置项列表
        ],
      ),
    );
  }
}
// AI-generated END - other_settings_card_widget.dart
