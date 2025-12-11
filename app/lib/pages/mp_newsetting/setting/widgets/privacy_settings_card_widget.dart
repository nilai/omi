// AI-generated START - 隐私设置卡片组件，显示隐私设置选项列表
import 'package:flutter/material.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/pages/mp_newsetting/setting/widgets/audio_retention_dialog.dart';

/// 隐私设置项信息数据模型
class PrivacySettingItem {
  // AI-generated START - 设置项标题
  final String title;
  // AI-generated END - title

  // AI-generated START - 当前选择的值（可选，用于显示当前选择）
  final String? currentValue;
  // AI-generated END - currentValue

  // AI-generated START - 是否显示下拉箭头（用于可选择的设置项）
  final bool showDropdown;
  // AI-generated END - showDropdown

  // AI-generated START - 图标
  final IconData icon;
  // AI-generated END - icon

  // AI-generated START - 图标背景颜色
  final Color iconBackgroundColor;
  // AI-generated END - iconBackgroundColor

  // AI-generated START - 点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  const PrivacySettingItem({
    required this.title,
    this.currentValue,
    this.showDropdown = false,
    required this.icon,
    required this.iconBackgroundColor,
    this.onTap,
  });
}

/// 隐私设置卡片组件
/// 显示隐私设置选项列表，标题和设置项列表分开，便于扩展
class PrivacySettingsCardWidget extends StatefulWidget {
  // AI-generated START - 卡片标题
  final String? title;
  // AI-generated END - title

  // AI-generated START - 隐私设置项列表
  final List<PrivacySettingItem> items;
  // AI-generated END - items

  const PrivacySettingsCardWidget({
    super.key,
    this.title,
    this.items = const [],
  });

  @override
  State<PrivacySettingsCardWidget> createState() => _PrivacySettingsCardWidgetState();
}

class _PrivacySettingsCardWidgetState extends State<PrivacySettingsCardWidget> {
  // AI-generated START - 音频保留时间当前值
  String _audioRetentionValue = '1 month';
  // AI-generated END - _audioRetentionValue

  @override
  void initState() {
    super.initState();
    // AI-generated START - 从 SharedPreferences 读取音频保留时间设置
    _audioRetentionValue = SharedPreferencesUtil().audioRetentionPeriod;
    // AI-generated END - 从 SharedPreferences 读取音频保留时间设置
  }

  // AI-generated START - 获取默认隐私设置项列表
  List<PrivacySettingItem> _getDefaultItems() {
    return [
      PrivacySettingItem(
        title: '隐私政策',
        icon: Icons.visibility_off_outlined,
        iconBackgroundColor: const Color(0xFF8B5CF6), // 紫色
        onTap: () {
          // AI-generated START - 默认点击事件处理
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('打开隐私政策'),
              duration: Duration(seconds: 1),
            ),
          );
          // AI-generated END - 默认点击事件处理
        },
      ),
      PrivacySettingItem(
        title: '服务条款',
        icon: Icons.description_outlined,
        iconBackgroundColor: const Color(0xFF64B5F6), // 浅蓝色
        onTap: () {
          // AI-generated START - 默认点击事件处理
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('打开服务条款'),
              duration: Duration(seconds: 1),
            ),
          );
          // AI-generated END - 默认点击事件处理
        },
      ),
      PrivacySettingItem(
        title: '音频保留时间',
        currentValue: _audioRetentionValue,
        showDropdown: true,
        icon: Icons.access_time_outlined,
        iconBackgroundColor: const Color(0xFF4CAF50), // 绿色
        onTap: () {
          // AI-generated START - 打开音频保留时间选择弹窗
          AudioRetentionDialog.show(
            context,
            currentValue: _audioRetentionValue,
            onRetentionSelected: (value) {
              // AI-generated START - 更新音频保留时间设置
              setState(() {
                _audioRetentionValue = value;
              });
              // 保存选中的音频保留时间设置到 SharedPreferences
              SharedPreferencesUtil().audioRetentionPeriod = value;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('音频保留时间已设置为: $value'),
                  duration: const Duration(seconds: 1),
                ),
              );
              // AI-generated END - 更新音频保留时间设置
            },
          );
          // AI-generated END - 打开音频保留时间选择弹窗
        },
      ),
    ];
  }
  // AI-generated END - getDefaultItems

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
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 16.0),
              child: Text(
                widget.title!,
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

                    // AI-generated START - 中间：标题
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // AI-generated END - 中间：标题

                    // AI-generated START - 右侧：当前值或箭头
                    if (item.currentValue != null) ...[
                      Text(
                        item.currentValue!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Icon(
                        item.showDropdown ? Icons.keyboard_arrow_down : Icons.chevron_right,
                        color: Colors.grey.shade400,
                        size: 20.0,
                      ),
                    ] else
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                        size: 20.0,
                      ),
                    // AI-generated END - 右侧：当前值或箭头
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
// AI-generated END - privacy_settings_card_widget.dart
