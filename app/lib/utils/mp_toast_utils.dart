// AI-generated START - Toast 提示工具类
import 'package:flutter/material.dart';
import 'package:memo_pin/main.dart';

/// Toast 提示工具类
/// 用于显示提示消息，提示功能待完善
class MPToastUtils {
  /// 显示"功能待完善，敬请期待"的提示
  ///
  /// [context] - BuildContext，如果为 null 则使用全局 navigatorKey
  static void showFeatureComingSoon({String? message, BuildContext? context}) {
    final String m = message ?? '';
    final String prefix = m.isNotEmpty ? '$m — ' : '';
    _showCenterToast(
      context: context,
      message: '${prefix}Coming soon.',
      duration: const Duration(seconds: 2),
    );
  }

  /// 显示自定义消息的提示
  ///
  /// [message] - 要显示的消息内容
  /// [context] - BuildContext，如果为 null 则使用全局 navigatorKey
  /// [duration] - 显示时长，默认为 2 秒
  static void showMessage(
    String message, {
    BuildContext? context,
    Duration? duration,
  }) {
    _showCenterToast(
      context: context,
      message: message,
      duration: duration ?? const Duration(seconds: 2),
    );
  }

  /// 在页面中间显示 Toast
  ///
  /// [context] - BuildContext，如果为 null 则使用全局 navigatorKey
  /// [message] - 要显示的消息内容
  /// [duration] - 显示时长
  static void _showCenterToast({
    BuildContext? context,
    required String message,
    required Duration duration,
  }) {
    final overlay = context != null ? Overlay.of(context) : MyApp.navigatorKey.currentState!.overlay;

    if (overlay == null) return;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // 自动移除
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}
// AI-generated END - MPToastUtils
