import 'package:flutter/material.dart';

import '../../../home/widgets/mp_battery_info_widget.dart';

/// 设置页面顶部导航栏
/// 包含左侧图标、中间空白区域和右侧设置/用户图标
class MPMemoAppBar extends StatelessWidget implements PreferredSizeWidget {
  // AI-generated START - 左侧图标点击回调
  final VoidCallback? onLeftIconTap;
  // AI-generated END - onLeftIconTap

  final String title;

  const MPMemoAppBar({
    super.key,
    this.onLeftIconTap,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: kToolbarHeight,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // AI-generated START - 左侧：相机图标
            const MPBatteryInfoWidget(),
            // AI-generated END - 左侧：相机图标
            const Spacer(),
            // AI-generated START - 中间：空白区域
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            // AI-generated END - 中间：空白区域
            const Spacer(),
            const SizedBox(
              width: 24,
              height: 24,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
// AI-generated END - settings_top_bar.dart
