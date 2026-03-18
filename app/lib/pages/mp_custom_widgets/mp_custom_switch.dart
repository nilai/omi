// AI-generated START - 自定义 Switch 组件
import 'package:flutter/material.dart';

/// 自定义 Switch 组件
/// 蓝色背景，白色圆形滑块，支持虚线边框（选中状态）
class MPCustomSwitch extends StatelessWidget {
  // AI-generated START - 开关状态
  final bool value;
  // AI-generated END - value

  // AI-generated START - 状态改变回调
  final ValueChanged<bool>? onChanged;
  // AI-generated END - onChanged

  // AI-generated START - 是否显示虚线边框（选中状态）
  final bool showDashedBorder;
  // AI-generated END - showDashedBorder

  // AI-generated START - 开关宽度
  final double width;
  // AI-generated END - width

  // AI-generated START - 开关高度
  final double height;
  // AI-generated END - height

  // AI-generated START - 滑块大小
  final double thumbSize;
  // AI-generated END - thumbSize

  // AI-generated START - 激活颜色
  final Color activeColor;
  // AI-generated END - activeColor

  // AI-generated START - 未激活颜色
  final Color inactiveColor;
  // AI-generated END - inactiveColor

  // AI-generated START - 滑块颜色
  final Color thumbColor;
  // AI-generated END - thumbColor

  // AI-generated START - 虚线边框颜色
  final Color borderColor;
  // AI-generated END - borderColor

  const MPCustomSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.showDashedBorder = false,
    this.width = 48.0,
    this.height = 28.0,
    this.thumbSize = 20.0,
    this.activeColor = const Color(0xFF007AFF), // 蓝色
    this.inactiveColor = const Color(0xFFE0E0E0), // 灰色
    this.thumbColor = Colors.white,
    this.borderColor = const Color(0xFF007AFF), // 浅蓝色虚线边框
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: value ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(height / 2),
          border: showDashedBorder
              ? Border.all(
                  color: borderColor,
                  width: 1.0,
                  style: BorderStyle.solid, // Flutter 不支持虚线，使用实线
                )
              : null,
        ),
        child: Stack(
          children: [
            // AI-generated START - 滑块
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: value ? width - thumbSize - 4 : 4,
              top: (height - thumbSize) / 2,
              child: Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  color: thumbColor,
                  shape: BoxShape.circle,
                  border: showDashedBorder
                      ? Border.all(
                          color: borderColor,
                          width: 1.0,
                          style: BorderStyle.solid,
                        )
                      : null,
                ),
              ),
            ),
            // AI-generated END - 滑块
          ],
        ),
      ),
    );
  }
}
// AI-generated END - mp_custom_switch.dart
