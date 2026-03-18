/// 连接设备页面
///
/// 用于连接蓝牙设备的页面，显示设备连接状态动画和查找设备功能。
/// 用户可以通过此页面扫描、连接设备，连接成功后跳转到主页。
library;

import 'package:flutter/material.dart';
import 'package:omi/pages/home/page.dart';
import 'package:omi/pages/onboarding/find_device/page.dart';
import 'package:omi/pages/settings/device_settings.dart';
import 'package:omi/providers/onboarding_provider.dart';
import 'package:omi/utils/other/temp.dart';
import 'package:omi/widgets/device_widget.dart';
import 'package:provider/provider.dart';

/// 连接设备页面组件
///
/// 提供设备连接界面，包括：
/// - 设备连接状态动画显示
/// - 设备扫描和连接功能
/// - 设备设置入口
class ConnectDevicePage extends StatefulWidget {
  const ConnectDevicePage({super.key});

  @override
  State<ConnectDevicePage> createState() => _ConnectDevicePageState();
}

/// 连接设备页面状态类
class _ConnectDevicePageState extends State<ConnectDevicePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Connect'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            // 设置按钮，跳转到设备设置页面
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DeviceSettings(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
            )
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: ListView(
          children: [
            // 设备连接状态动画组件
            // 使用Consumer监听OnboardingProvider的状态变化
            Consumer<OnboardingProvider>(
              builder: (context, onboardingProvider, child) {
                return DeviceAnimationWidget(
                  isConnected: onboardingProvider.isConnected,
                  deviceName: onboardingProvider.deviceName,
                  deviceType: onboardingProvider.deviceType,
                  animatedBackground: onboardingProvider.isConnected,
                );
              },
            ),
            // 查找设备页面
            // 提供设备扫描和连接功能
            FindDevicesPage(
              isFromOnboarding: false,
              // 连接成功后的回调，跳转到主页
              goNext: () {
                debugPrint('onConnected from FindDevicesPage');
                routeToPage(context, const HomePageWrapper(), replace: true);
              },
              // 不显示跳过按钮
              includeSkip: false,
            )
          ],
        ));
  }
}
