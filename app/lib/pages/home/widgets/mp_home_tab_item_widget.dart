import 'package:flutter/material.dart';

/// 主页底部 Tab 项，显示本地图片与文本标题。
class MPHomeTabItemWidget extends StatelessWidget {
  const MPHomeTabItemWidget({
    super.key,
    required this.assetPath,
    required this.label,
    this.isActive = false,
    this.onTap,
    this.iconSize = 26,
    this.spacing = 6,
    this.activeColor = const Color(0xFF306CFF),
    this.inactiveColor = const Color(0xFF999999),
    this.useTint = true,
  });

  /// 本地图片资源路径。
  final String assetPath;

  /// 底部标题文案。
  final String label;

  /// 是否为选中态，用于控制样式。
  final bool isActive;

  /// 点击回调。
  final VoidCallback? onTap;

  /// 图标尺寸，默认为 26。
  final double iconSize;

  /// 图标与文本之间的间距。
  final double spacing;

  /// 选中态颜色。
  final Color activeColor;

  /// 非选中态颜色。
  final Color inactiveColor;

  /// 是否为图标启用颜色覆盖。
  final bool useTint;

  @override
  Widget build(BuildContext context) {
    final textColor = isActive ? activeColor : inactiveColor;
    final iconColor = useTint ? textColor : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                color: iconColor,
                colorBlendMode: useTint ? BlendMode.srcIn : null,
              ),
            ),
            SizedBox(height: spacing),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
