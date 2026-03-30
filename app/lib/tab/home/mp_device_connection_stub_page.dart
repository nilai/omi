import 'package:flutter/material.dart';
import 'package:omi/common/mp_custom_nav_bar.dart';
import 'package:omi/utils/mp_toast_utils.dart';
import 'package:omi/utils/omi_color_utils.dart';

/// 设备连接（对齐 react `DeviceConnectionPage`，完整能力后续再接 BLE）
class MPDeviceConnectionStubPage extends StatelessWidget {
  const MPDeviceConnectionStubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: PreferredSize(
        preferredSize: MPCustomNavBar.preferredSizeOf(context),
        child: MPCustomNavBar(
          title: 'Device',
          backgroundColor: pageColor,
          onBack: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Connect MemoPin',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: mainTextColor),
            ),
            const SizedBox(height: 8),
            Text(
              '配对、电量与同步设置在完整版本中提供。',
              style: TextStyle(fontSize: 15, color: secondTextColor, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => MPToastUtils.showFeatureComingSoon(message: '设备扫描与连接'),
              child: const Text('Scan devices'),
            ),
          ],
        ),
      ),
    );
  }
}
