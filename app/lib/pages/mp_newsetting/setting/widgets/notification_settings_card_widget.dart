// AI-generated START - 通知设置卡片组件，显示通知设置选项列表
import 'package:flutter/material.dart';

/// 通知设置项信息数据模型
class NotificationSettingItem {
  // AI-generated START - 设置项标题
  final String title;
  // AI-generated END - title

  // AI-generated START - 设置项描述
  final String? description;
  // AI-generated END - description

  // AI-generated START - 图标
  final IconData icon;
  // AI-generated END - icon

  // AI-generated START - 图标背景颜色
  final Color iconBackgroundColor;
  // AI-generated END - iconBackgroundColor

  // AI-generated START - 开关状态
  final bool value;
  // AI-generated END - value

  // AI-generated START - 开关状态改变回调
  final ValueChanged<bool>? onChanged;
  // AI-generated END - onChanged

  const NotificationSettingItem({
    required this.title,
    this.description,
    required this.icon,
    required this.iconBackgroundColor,
    required this.value,
    this.onChanged,
  });
}

/// 通知设置卡片组件
/// 显示通知设置选项列表，标题和设置项列表分开，便于扩展
class NotificationSettingsCardWidget extends StatelessWidget {
  // AI-generated START - 卡片标题
  final String? title;
  // AI-generated END - title

  // AI-generated START - 通知设置项列表
  final List<NotificationSettingItem> items;
  // AI-generated END - items

  const NotificationSettingsCardWidget({
    super.key,
    this.title,
    this.items = const [],
  });

  // AI-generated START - 获取默认通知设置项列表
  static List<NotificationSettingItem> getDefaultItems({BuildContext? context}) {
    return [
      NotificationSettingItem(
        title: '推送通知',
        description: '接收应用推送消息',
        icon: Icons.notifications_outlined,
        iconBackgroundColor: const Color(0xFF64B5F6), // 浅蓝色
        value: true,
        onChanged: (bool newValue) {
          // AI-generated START - 默认开关变化事件处理
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(newValue ? '已开启推送通知' : '已关闭推送通知'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
          // 这里可以添加实际的开关状态保存逻辑
          // 例如：保存到本地存储或发送到服务器
          // AI-generated END - 默认开关变化事件处理
        },
      ),
    ];
  }
  // AI-generated END - getDefaultItems

  @override
  Widget build(BuildContext context) {
    final itemsList = items.isEmpty ? NotificationSettingsCardWidget.getDefaultItems(context: context) : items;

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

            return Container(
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
                      color: item.iconBackgroundColor,
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
                      ],
                    ),
                  ),
                  // AI-generated END - 中间：标题和描述

                  const SizedBox(width: 12.0),

                  // AI-generated START - 右侧：开关
                  Switch(
                    value: item.value,
                    onChanged: item.onChanged,
                    activeThumbColor: Colors.blue,
                  ),
                  // AI-generated END - 右侧：开关
                ],
              ),
            );
          }),
          // AI-generated END - 设置项列表区域
        ],
      ),
    );
  }
}
// AI-generated END - notification_settings_card_widget.dart
