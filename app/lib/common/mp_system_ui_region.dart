import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 页面级系统状态栏样式容器。
///
/// 传入顶部背景色后，自动计算状态栏图标明暗，保证状态栏与顶部区域视觉一致。
class MPSystemUiRegion extends StatelessWidget {
  const MPSystemUiRegion({
    super.key,
    required this.topBarColor,
    required this.child,
  });

  final Color topBarColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _resolveSystemUiOverlayStyle(topBarColor),
      child: child,
    );
  }

  /// 根据顶部背景色自动生成状态栏样式，兼容 iOS / Android。
  static SystemUiOverlayStyle _resolveSystemUiOverlayStyle(Color barColor) {
    final bool isDarkBackground =
        ThemeData.estimateBrightnessForColor(barColor) == Brightness.dark;
    return isDarkBackground
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          )
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          );
  }
}
