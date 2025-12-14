// AI-generated START - Toast 提示工具类
import 'package:flutter/material.dart';
import 'package:omi/main.dart';

/// Toast 提示工具类
/// 用于显示提示消息，提示功能待完善
class MPToastUtils {
  /// 显示"功能待完善，敬请期待"的提示
  ///
  /// [context] - BuildContext，如果为 null 则使用全局 navigatorKey
  static void showFeatureComingSoon({BuildContext? context}) {
    final scaffoldMessenger = context != null
        ? ScaffoldMessenger.of(context)
        : ScaffoldMessenger.of(MyApp.navigatorKey.currentState!.context);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: const Text('功能待完善，敬请期待'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.all(16.0),
      ),
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
    final scaffoldMessenger = context != null
        ? ScaffoldMessenger.of(context)
        : ScaffoldMessenger.of(MyApp.navigatorKey.currentState!.context);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.all(16.0),
      ),
    );
  }
}
// AI-generated END - MPToastUtils
