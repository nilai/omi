import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart';
import '../utils/platform/platform_service.dart';

/// 记忆分享工具：直接唤起系统分享面板。
class MPShareMemoryDialog {
  MPShareMemoryDialog._();

  /// 显示分享对话框。
  ///
  /// - 入参仅支持 [context] 与 [url]
  /// - 当 [context] 为空时，自动使用全局 context
  static Future<void> show({
    BuildContext? context,
    required String url,
  }) async {
    final BuildContext? targetContext = context ?? MyApp.navigatorKey.currentContext;
    if (targetContext == null || !targetContext.mounted) {
      return;
    }

    HapticFeedback.mediumImpact();

    try {
      final String shareUrl = url.trim();
      if (shareUrl.isEmpty) {
        _showErrorSnackBar(targetContext, '分享链接无法生成，请稍后重试。');
        return;
      }

      Rect? sharePositionOrigin;
      if (PlatformService.isIOS) {
        final MediaQueryData mediaQuery = MediaQuery.of(targetContext);
        const double defaultSize = 44;
        sharePositionOrigin = Rect.fromLTWH(
          (mediaQuery.size.width - defaultSize) / 2,
          (mediaQuery.size.height - defaultSize) / 2,
          defaultSize,
          defaultSize,
        );
      }

      if (PlatformService.isIOS) {
        await Share.share(
          shareUrl,
          subject: '分享链接',
          sharePositionOrigin: sharePositionOrigin!,
        );
      } else {
        await Share.share(shareUrl, subject: '分享链接');
      }
    } catch (_) {
      _showErrorSnackBar(targetContext, '分享失败，请稍后重试。');
    }
  }

  /// 显示分享错误提示。
  static void _showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.grey.shade800,
      ),
    );
  }
}
