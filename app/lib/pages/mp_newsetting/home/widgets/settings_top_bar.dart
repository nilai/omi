// AI-generated START - 设置页面顶部导航栏组件
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';

/// 设置页面顶部导航栏
/// 包含左侧图标、中间空白区域和右侧设置/用户图标
class SettingsTopBar extends StatelessWidget implements PreferredSizeWidget {
  // AI-generated START - 左侧图标点击回调
  final VoidCallback? onLeftIconTap;
  // AI-generated END - onLeftIconTap

  // AI-generated START - 设置图标点击回调
  final VoidCallback? onSettingsTap;
  // AI-generated END - onSettingsTap

  // AI-generated START - 用户图标点击回调
  final VoidCallback? onUserTap;
  // AI-generated END - onUserTap

  const SettingsTopBar({
    super.key,
    this.onLeftIconTap,
    this.onSettingsTap,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: kToolbarHeight,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // AI-generated START - 左侧：相机图标
            GestureDetector(
              onTap: onLeftIconTap,
              child: Assets.images.settingCamera.image(
                width: 32.0,
                height: 32.0,
                fit: BoxFit.contain,
              ),
            ),
            // AI-generated END - 左侧：相机图标

            // AI-generated START - 中间：空白区域
            const Spacer(),
            // AI-generated END - 中间：空白区域

            // AI-generated START - 右侧：设置和用户图标
            Row(
              children: [
                // 设置图标
                GestureDetector(
                  onTap: onSettingsTap,
                  child: Assets.images.settingSet.image(
                    width: 32.0,
                    height: 32.0,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8.0),
                // 用户图标
                GestureDetector(
                  onTap: onUserTap,
                  child: Assets.images.settingUser.image(
                    width: 32.0,
                    height: 32.0,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            // AI-generated END - 右侧：设置和用户图标
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
// AI-generated END - settings_top_bar.dart
