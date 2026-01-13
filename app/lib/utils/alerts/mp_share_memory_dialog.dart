// AI-generated START - 分享记忆对话框
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omi/utils/platform/platform_service.dart';
import 'package:share_plus/share_plus.dart';

import '../../backend/http/mp_api/mp_memory.dart';
import '../../backend/schema/mp/mp_memory.dart';

/// 分享记忆对话框
/// 直接弹出系统分享 bottom sheet，无需中间确认对话框
class MPShareMemoryDialog {
  /// 显示分享对话框
  /// 直接执行分享逻辑，弹出系统分享 bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String memoryId,
    String? title,
    GlobalKey? shareButtonKey,
    VoidCallback? onShareSuccess,
    void Function(String)? onShareError,
  }) async {
    HapticFeedback.mediumImpact();

    try {
      final req = MPShareMemoryRequest(memoryId: memoryId);
      final response = await shareMemory(req);
      if (response == null) {
        const errorMessage = '分享链接无法生成，请稍后重试。';
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(errorMessage),
              backgroundColor: Colors.grey.shade800,
            ),
          );
        }
        onShareError?.call(errorMessage);
        return;
      }
      final shareUrl = response.shareUrl;

      // // 如果提供了设置可见性的函数，先调用它
      // if (setVisibilityFunction != null) {
      //   bool shared = await setVisibilityFunction();
      //   if (!shared) {
      //     final errorMessage = '分享链接无法生成，请稍后重试。';
      //     if (context.mounted) {
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         SnackBar(
      //           content: Text(errorMessage),
      //           backgroundColor: Colors.grey.shade800,
      //         ),
      //       );
      //     }
      //     onShareError?.call(errorMessage);
      //     return;
      //   }
      // }

      // 获取分享位置（仅用于 iOS）
      // iOS 26+ 要求 sharePositionOrigin 必须设置且有效（非零尺寸）
      Rect? sharePositionOrigin;
      if (PlatformService.isIOS) {
        if (shareButtonKey != null) {
          final RenderBox? box = shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
          if (box != null) {
            final Offset position = box.localToGlobal(Offset.zero);
            final Size size = box.size;
            // 验证 Rect 是否有效（宽度和高度必须大于 0）
            if (size.width > 0 && size.height > 0) {
              sharePositionOrigin = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
            }
          }
        }

        // 如果无法获取有效的 sharePositionOrigin，使用屏幕中心作为默认位置
        if (sharePositionOrigin == null) {
          final MediaQueryData mediaQuery = MediaQuery.of(context);
          final double screenWidth = mediaQuery.size.width;
          final double screenHeight = mediaQuery.size.height;
          // 使用屏幕中心的一个小区域（44x44，iOS 标准触摸目标大小）
          const double defaultSize = 44.0;
          sharePositionOrigin = Rect.fromLTWH(
            (screenWidth - defaultSize) / 2,
            (screenHeight - defaultSize) / 2,
            defaultSize,
            defaultSize,
          );
        }
      }

      // 执行分享，直接弹出系统分享 bottom sheet
      // Android 上不使用 sharePositionOrigin 参数
      if (PlatformService.isIOS) {
        await Share.share(
          shareUrl,
          subject: '分享链接',
          sharePositionOrigin: sharePositionOrigin!,
        );
      } else {
        await Share.share(
          shareUrl,
          subject: '分享链接',
        );
      }

      // 延迟一下让分享面板显示
      await Future.delayed(const Duration(milliseconds: 150));

      onShareSuccess?.call();
    } catch (e) {
      debugPrint('分享失败: ${e.toString()}');
      const errorMessage = '分享失败，请稍后重试。';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(errorMessage),
            backgroundColor: Colors.grey.shade800,
          ),
        );
      }
      onShareError?.call(errorMessage);
    }
  }
}
// AI-generated END - mp_share_memory_dialog.dart
