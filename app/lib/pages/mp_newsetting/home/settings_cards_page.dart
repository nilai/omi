// AI-generated START - 设置卡片展示页面，从上到下显示所有设置相关的卡片组件
import 'package:flutter/material.dart';
import 'package:omi/pages/mp_memory/home/memory_page.dart';
import 'package:omi/pages/mp_newsetting/home/providers/settings_provider.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/app_integration_card_widget.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/expert_feedback_card_widget.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/memory_warehouse_card_widget.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/other_settings_card_widget.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/referral_card_widget.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/settings_top_bar.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/subscription_plan_card_widget.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/template_selection_card_widget.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/voiceprint_recognition_card_widget.dart';
import 'package:omi/pages/mp_newsetting/personal/personal_page.dart';
import 'package:omi/pages/mp_newsetting/setting/setting_page.dart';
import 'package:provider/provider.dart';

/// 设置卡片展示页面
/// 从上到下显示所有设置相关的卡片组件
class SettingsCardsPage extends StatefulWidget {
  const SettingsCardsPage({super.key});

  @override
  State<SettingsCardsPage> createState() => _SettingsCardsPageState();
}

class _SettingsCardsPageState extends State<SettingsCardsPage> {
  @override
  void initState() {
    super.initState();
    // AI-generated START - 初始化时加载用户资料
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<SettingsProvider>(context, listen: false);
    });
    // AI-generated END - 初始化时加载用户资料
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: SettingsTopBar(
            onLeftIconTap: () {
              // 处理左侧图标点击
              Navigator.of(context).pop();
            },
            onSettingsTap: () {
              // AI-generated START - 打开设置页面
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingPage(),
                ),
              );
              // AI-generated END - 打开设置页面
            },
            onUserTap: () {
              // AI-generated START - 打开个人主页
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PersonalPage(),
                ),
              );
              // AI-generated END - 打开个人主页
            },
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8.0),
                // AI-generated START - 订阅计划卡片
                SubscriptionPlanCardWidget(
                  planName: 'Starter',
                  remainingMinutes: 165,
                  totalMinutes: 300,
                  onTrialTap: () {
                    // 处理试用按钮点击
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('开始7天无限免费试用')),
                    );
                  },
                ),
                // AI-generated END - 订阅计划卡片

                // AI-generated START - 推荐卡片
                ReferralCardWidget(
                  onTap: () {
                    // 处理推荐卡片点击
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('打开推荐页面')),
                    );
                  },
                  showNotification: true,
                ),
                // AI-generated END - 推荐卡片

                // AI-generated START - 模板选择卡片
                TemplateSelectionCardWidget(
                  onTap: () {
                    // 处理模板选择卡片点击
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('打开模板选择页面')),
                    );
                  },
                ),
                // AI-generated END - 模板选择卡片

                // AI-generated START - 专家反馈卡片
                ExpertFeedbackCardWidget(
                  onTap: () {
                    // 处理专家反馈卡片点击
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('打开专家反馈页面')),
                    );
                  },
                  onExpertTap: (expert) {
                    // 处理专家头像点击
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('选择专家: ${expert.role}')),
                    );
                  },
                ),
                // AI-generated END - 专家反馈卡片

                // AI-generated START - 记忆仓库卡片
                MemoryWarehouseCardWidget(
                  onTap: () {
                    // AI-generated START - 打开记忆仓库页面
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MemoryPage(),
                      ),
                    );
                    // AI-generated END - 打开记忆仓库页面
                  },
                  friendAvatars: const [
                    'https://via.placeholder.com/48',
                    'https://via.placeholder.com/48',
                    'https://via.placeholder.com/48',
                    'https://via.placeholder.com/48',
                    'https://via.placeholder.com/48',
                    'https://via.placeholder.com/48',
                  ],
                ),
                // AI-generated END - 记忆仓库卡片

                // AI-generated START - 声纹识别卡片
                VoiceprintRecognitionCardWidget(
                  onTap: () {
                    // 处理声纹识别卡片点击
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('打开声纹识别页面')),
                    );
                  },
                ),
                // AI-generated END - 声纹识别卡片

                // AI-generated START - App集成卡片
                AppIntegrationCardWidget(
                  onTap: () {
                    // 处理App集成卡片点击
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('打开App集成页面')),
                    );
                  },
                ),
                // AI-generated END - App集成卡片

                // AI-generated START - 其他设置卡片
                OtherSettingsCardWidget(
                  title: '其他设置',
                  settings: OtherSettingsCardWidget.getDefaultSettings().map((setting) {
                    return SettingItemInfo(
                      title: setting.title,
                      icon: setting.icon,
                      iconBackgroundColor: setting.iconBackgroundColor,
                      iconImage: setting.iconImage,
                      onTap: () {
                        // 处理设置项点击
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('打开${setting.title}')),
                        );
                      },
                    );
                  }).toList(),
                ),
                // AI-generated END - 其他设置卡片

                const SizedBox(height: 24.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
// AI-generated END - settings_cards_page.dart
