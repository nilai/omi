// AI-generated START - 通知设置卡片组件，显示通知设置选项列表
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';
import 'package:omi/pages/mp_custom_utils/mp_toast_utils.dart';
import 'package:omi/pages/mp_custom_widgets/mp_custom_switch.dart';

/// 通知设置项信息数据模型
class NotificationSettingItem {
  // AI-generated START - 设置项标题
  final String title;
  // AI-generated END - title

  // AI-generated START - 设置项描述
  final String? description;
  // AI-generated END - description

  // AI-generated START - 图标
  final AssetGenImage icon;
  // AI-generated END - icon

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
    required this.value,
    this.onChanged,
  });
}

/// 通知设置卡片组件
/// 显示通知设置选项列表，标题和设置项列表分开，便于扩展
class NotificationSettingsCardWidget extends StatefulWidget {
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

  @override
  State<NotificationSettingsCardWidget> createState() => _NotificationSettingsCardWidgetState();
}

class _NotificationSettingsCardWidgetState extends State<NotificationSettingsCardWidget> {
  // AI-generated START - 默认推送通知状态
  bool _defaultNotificationValue = true;
  // AI-generated END - _defaultNotificationValue

  // AI-generated START - 获取默认通知设置项列表
  List<NotificationSettingItem> _getDefaultItems() {
    return [
      NotificationSettingItem(
        title: '推送通知',
        description: '接收应用推送消息',
        icon: Assets.images.mpSettingNotification,
        value: _defaultNotificationValue,
        onChanged: (bool newValue) {
          // AI-generated START - 默认开关变化事件处理
          setState(() {
            _defaultNotificationValue = newValue;
          });
          MPToastUtils.showMessage(
            newValue ? '已开启推送通知' : '已关闭推送通知',
            context: context,
            duration: const Duration(seconds: 1),
          );
          // 这里可以添加实际的开关状态保存逻辑
          // 例如：保存到本地存储或发送到服务器
          // AI-generated END - 默认开关变化事件处理
        },
      ),
    ];
  }
  // AI-generated END - _getDefaultItems

  @override
  Widget build(BuildContext context) {
    final itemsList = widget.items.isEmpty ? _getDefaultItems() : widget.items;

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
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
              child: Text(
                widget.title!,
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

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
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
                  item.icon.image(
                    fit: BoxFit.cover,
                    width: 32.0,
                    height: 32.0,
                  ),

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
                      ],
                    ),
                  ),
                  // AI-generated END - 中间：标题和描述

                  const SizedBox(width: 12.0),

                  // AI-generated START - 右侧：开关
                  MPCustomSwitch(
                    value: item.value,
                    onChanged: item.onChanged,
                    showDashedBorder: false, // 可以根据需要设置为 true 显示虚线边框
                  ),
                  // AI-generated END - 右侧：开关
                ],
              ),
            );
          }),
          const SizedBox(height: 12.0),
          // AI-generated END - 设置项列表区域
        ],
      ),
    );
  }
}
// AI-generated END - notification_settings_card_widget.dart
