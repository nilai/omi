// AI-generated START - 偏好设置卡片组件，显示偏好设置选项列表
import 'package:flutter/material.dart';
import 'package:omi/pages/mp_newsetting/setting/widgets/primary_language_dialog.dart';
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
  final IconData icon;
  // AI-generated END - icon

  // AI-generated START - 图标背景颜色（用于渐变）
  final List<Color> iconGradientColors;
  // AI-generated END - iconGradientColors

  // AI-generated START - 点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  const PreferenceSettingItem({
    required this.title,
    this.description,
    this.currentValue,
    required this.icon,
    required this.iconGradientColors,
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
  static List<PreferenceSettingItem> getDefaultItems({BuildContext? context}) {
    return [
      PreferenceSettingItem(
        title: 'AI偏好',
        description: '自定义AI助手的行为和风格',
        icon: Icons.psychology_outlined,
        iconGradientColors: const [
          Color(0xFF8B5CF6), // 紫色
          Color(0xFF6D28D9), // 深紫色
        ],
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
        currentValue: context != null ? _getCurrentLanguageName(context) : 'Chinese (Mandarin, Simplified)',
        icon: Icons.language_outlined,
        iconGradientColors: const [
          Color(0xFF64B5F6), // 浅蓝色
          Color(0xFF8B5CF6), // 紫色
        ],
        onTap: () {
          // AI-generated START - 打开主要语言选择弹窗
          if (context != null) {
            PrimaryLanguageDialog.show(context);
          }
          // AI-generated END - 打开主要语言选择弹窗
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

  @override
  Widget build(BuildContext context) {
    final itemsList = items.isEmpty ? PreferenceSettingsCardWidget.getDefaultItems(context: context) : items;

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
          // AI-generated END - 标题区域

          // AI-generated START - 设置项列表区域（独立，便于扩展）
          ...itemsList.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == itemsList.length - 1;

            return GestureDetector(
              onTap: item.onTap,
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
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: item.iconGradientColors,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ),
                    // AI-generated END - 左侧：图标

                    const SizedBox(width: 16.0),

                    // AI-generated START - 中间：标题、描述和当前值
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (item.description != null) ...[
                            const SizedBox(height: 4.0),
                            Text(
                              item.description!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                          if (item.currentValue != null && item.description == null) ...[
                            const SizedBox(height: 4.0),
                            Text(
                              item.currentValue!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // AI-generated END - 中间：标题、描述和当前值

                    const SizedBox(width: 12.0),

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
          // AI-generated END - 设置项列表区域
        ],
      ),
    );
  }
}
// AI-generated END - preference_settings_card_widget.dart
