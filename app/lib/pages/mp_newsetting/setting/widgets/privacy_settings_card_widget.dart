// AI-generated START - 隐私设置卡片组件，显示隐私设置选项列表
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';
import 'package:omi/pages/mp_custom_utils/mp_toast_utils.dart';
import 'package:omi/pages/mp_newsetting/home/providers/settings_provider.dart';
import 'package:omi/pages/mp_newsetting/setting/widgets/audio_retention_dialog.dart';
import 'package:provider/provider.dart';

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
  final String? icon;
  // AI-generated END - icon

  // AI-generated START - 点击回调
  final VoidCallback? onTap;
  // AI-generated END - onTap

  const PrivacySettingItem({
    required this.title,
    this.currentValue,
    this.showDropdown = false,
    required this.icon,
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
  @override
  void initState() {
    super.initState();
    // AI-generated START - 初始化音频保留时间（从 SettingsProvider 加载）
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    settingsProvider.initAudioRetentionPeriod();
    // AI-generated END - 初始化音频保留时间
  }

  // AI-generated START - 获取默认隐私设置项列表
  List<PrivacySettingItem> _getDefaultItems() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    return [
      PrivacySettingItem(
        title: '隐私政策',
        icon: Assets.images.mpSettingPrivicy.path,
        onTap: () {
          //打开隐私政策
          MPToastUtils.showFeatureComingSoon();
        },
      ),
      PrivacySettingItem(
        title: '服务条款',
        icon: Assets.images.mpSettingService.path,
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
        currentValue: settingsProvider.audioRetentionPeriod,
        showDropdown: true,
        icon: Assets.images.mpSettingVoiceTime.path,
        onTap: () {
          // AI-generated START - 打开音频保留时间选择弹窗
          AudioRetentionDialog.show(
            context,
            currentValue: settingsProvider.audioRetentionPeriod,
            onRetentionSelected: (value) {
              // AI-generated START - 更新音频保留时间设置
              settingsProvider.setAudioRetentionPeriod(value);
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
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
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

                return GestureDetector(
                  onTap: item.onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
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
                        Image.asset(item.icon!, fit: BoxFit.cover, width: 32.0, height: 32.0),

                        // AI-generated END - 左侧：图标
                        const SizedBox(width: 8.0),
                        // AI-generated START - 中间：标题
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14.0,
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
                          Assets.images.settingRightArrow1.image(
                            width: 19.0,
                            height: 18.0,
                            fit: BoxFit.contain,
                          ),
                        // AI-generated END - 右侧：当前值或箭头
                      ],
                    ),
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
}
// AI-generated END - privacy_settings_card_widget.dart
