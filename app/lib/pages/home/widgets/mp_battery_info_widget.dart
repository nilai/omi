import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';
import 'package:omi/providers/device_provider.dart';
import 'package:provider/provider.dart';

import '../../onboarding/find_device/mp_page.dart';

/// 电池状态图标 Widget
/// 根据设备连接状态和电量显示不同的图标
class MPBatteryInfoWidget extends StatelessWidget {
  const MPBatteryInfoWidget({super.key});

  /// 根据设备连接状态和电量获取对应的图标
  ///
  /// @param isConnected - 设备是否已连接
  /// @param batteryLevel - 电池电量（-1 表示未知）
  /// @returns 对应的 AssetGenImage
  AssetGenImage _getBatteryIcon(bool isConnected, int batteryLevel) {
    // 未连接状态·
    if (!isConnected) {
      return Assets.images.mpBatteryNoConnect;
    }

    // 已连接状态，根据电量选择图标
    // 电量 <0 或 >=20，使用连接完成图标
    if (batteryLevel < 0 || batteryLevel >= 20) {
      return Assets.images.mpBatteryConnect;
    }

    // 电量 >=10 且 <20，使用中等电量图标
    if (batteryLevel >= 10 && batteryLevel < 20) {
      return Assets.images.mpBatteryMidPower;
    }

    // 电量 >0 且 <10，使用低电量图标
    if (batteryLevel > 0 && batteryLevel < 10) {
      return Assets.images.mpBatteryLowPower;
    }

    // 默认返回连接完成图标（batteryLevel == 0 的情况）
    return Assets.images.mpBatteryConnect;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        final icon = _getBatteryIcon(
          deviceProvider.isConnected,
          deviceProvider.batteryLevel,
        );

        return icon.image(
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        );
      },
    );
  }

  static void pushToFindDevicesPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MPFindDevicesPage(
          isFromOnboarding: false,
          goNext: () {},
          onSkip: () {},
          includeSkip: false,
        ),
      ),
    );
  }
}
