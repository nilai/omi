// AI-generated START - 设备设置卡片组件，显示设备设置选项列表
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';

/// 设备设置项信息数据模型
class DeviceSettingItem {
  // AI-generated START - 设置项标题
  final String title;
  // AI-generated END - title

  // AI-generated START - 设置项描述
  final String? description;
  // AI-generated END - description

  // AI-generated START - 图标图片
  final AssetGenImage? iconImage;
  // AI-generated END - iconImage

  // AI-generated START - 图标背景颜色（用于渐变）
  final List<Color>? iconGradientColors;
  // AI-generated END - iconGradientColors

  // AI-generated START - 点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  const DeviceSettingItem({
    required this.title,
    this.description,
    this.iconImage,
    this.iconGradientColors,
    this.onTap,
  });
}

/// 设备设置卡片组件
/// 显示设备设置选项列表，标题和设置项列表分开，便于扩展
class DeviceSettingsCardWidget extends StatelessWidget {
  // AI-generated START - 卡片标题
  final String? title;
  // AI-generated END - title

  // AI-generated START - 设备设置项列表
  final List<DeviceSettingItem> items;
  // AI-generated END - items

  const DeviceSettingsCardWidget({
    super.key,
    this.title,
    this.items = const [],
  });

  // AI-generated START - 获取默认设备设置项列表
  static List<DeviceSettingItem> getDefaultItems({BuildContext? context}) {
    // AI-generated START - 尝试使用资源图片，如果不存在则使用字符串路径
    AssetGenImage? memopinImage;
    try {
      // 如果资源文件已生成，使用 Assets.images.settingMemopin
      // 否则使用字符串路径作为备用
      memopinImage = const AssetGenImage('assets/images/setting_memopin.png');
    } catch (e) {
      memopinImage = const AssetGenImage('assets/images/setting_memopin.png');
    }
    // AI-generated END - memopinImage

    return [
      DeviceSettingItem(
        title: 'MemoPin设置',
        description: '设置连接的AI硬件',
        iconImage: memopinImage,
        iconGradientColors: const [
          Color(0xFF8B5CF6), // 紫色
          Color(0xFF6D28D9), // 深紫色
        ],
        onTap: () {
          // AI-generated START - 默认点击事件处理
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('打开MemoPin设置'),
                duration: Duration(seconds: 1),
              ),
            );
          }
          // AI-generated END - 默认点击事件处理
        },
      ),
    ];
  }
  // AI-generated END - getDefaultItems

  @override
  Widget build(BuildContext context) {
    final itemsList = items.isEmpty ? DeviceSettingsCardWidget.getDefaultItems(context: context) : items;

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
              child: Container(
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
                    item.iconImage != null
                        ? ClipOval(
                            child: item.iconImage!.image(
                              fit: BoxFit.cover,
                              width: 32.0,
                              height: 32.0,
                            ),
                          )
                        : const SizedBox.shrink(),
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

                    // AI-generated START - 右侧：箭头
                    Image.asset(Assets.images.settingRightArrow1.path, width: 19.0, height: 18.0, fit: BoxFit.cover),
                    // AI-generated END - 右侧：箭头
                  ],
                ),
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
// AI-generated END - device_settings_card_widget.dart
