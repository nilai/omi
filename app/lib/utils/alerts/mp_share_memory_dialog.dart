// AI-generated START - 分享记忆对话框
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// 分享记忆对话框
/// 直接弹出系统分享 bottom sheet，无需中间确认对话框
class MPShareMemoryDialog {
  /// 显示分享对话框
  /// 直接执行分享逻辑，弹出系统分享 bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String shareUrl,
    String? title,
    GlobalKey? shareButtonKey,
    Future<bool> Function()? setVisibilityFunction,
    VoidCallback? onShareSuccess,
    void Function(String)? onShareError,
  }) async {
    HapticFeedback.mediumImpact();

    try {
      // 如果提供了设置可见性的函数，先调用它
      if (setVisibilityFunction != null) {
        bool shared = await setVisibilityFunction();
        if (!shared) {
          final errorMessage = '分享链接无法生成，请稍后重试。';
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.grey.shade800,
              ),
            );
          }
          onShareError?.call(errorMessage);
          return;
        }
      }

      // 获取分享位置（用于 iOS）
      Rect? sharePositionOrigin;
      if (shareButtonKey != null) {
        final RenderBox? box = shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          final Offset position = box.localToGlobal(Offset.zero);
          final Size size = box.size;
          sharePositionOrigin = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
        }
      }

      // 执行分享，直接弹出系统分享 bottom sheet
      if (sharePositionOrigin != null) {
        await Share.share(
          shareUrl,
          subject: title,
          sharePositionOrigin: sharePositionOrigin,
        );
      } else {
        await Share.share(
          shareUrl,
          subject: title,
        );
      }

      // 延迟一下让分享面板显示
      await Future.delayed(const Duration(milliseconds: 150));

      onShareSuccess?.call();
    } catch (e) {
      final errorMessage = '分享失败，请稍后重试。';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.grey.shade800,
          ),
        );
      }
      onShareError?.call(errorMessage);
    }
  }
}
// AI-generated END - mp_share_memory_dialog.dart
