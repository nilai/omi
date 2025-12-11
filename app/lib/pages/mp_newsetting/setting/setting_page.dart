// AI-generated START - 设置页面，整合所有设置相关的卡片组件
import 'package:flutter/material.dart';
import 'package:omi/pages/mp_newsetting/setting/widgets/device_settings_card_widget.dart';
import 'package:omi/pages/mp_newsetting/setting/widgets/notification_settings_card_widget.dart';
import 'package:omi/pages/mp_newsetting/setting/widgets/preference_settings_card_widget.dart';
import 'package:omi/pages/mp_newsetting/setting/widgets/privacy_settings_card_widget.dart';

/// 设置页面
/// 显示所有设置相关的卡片组件
class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Setting',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 8.0),
            // AI-generated START - 通知设置卡片
            NotificationSettingsCardWidget(
              title: '通知设置',
            ),
            // AI-generated END - 通知设置卡片

            // AI-generated START - 设备设置卡片
            DeviceSettingsCardWidget(
              title: 'Device Setting',
            ),
            // AI-generated END - 设备设置卡片

            // AI-generated START - 偏好设置卡片
            PreferenceSettingsCardWidget(
              title: '偏好设置',
            ),
            // AI-generated END - 偏好设置卡片

            // AI-generated START - 隐私设置卡片
            PrivacySettingsCardWidget(
              title: '隐私设置',
            ),
            // AI-generated END - 隐私设置卡片

            SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }
}
// AI-generated END - setting_page.dart
