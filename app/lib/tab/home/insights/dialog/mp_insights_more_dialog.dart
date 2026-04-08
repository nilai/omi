import 'package:flutter/material.dart';

import '../../../../main.dart';
import '../../../../utils/omi_color_utils.dart';
import '../../../../utils/omi_font_utils.dart';

/// Insights 详情页右上角更多弹窗。
class MPInsightsMoreDialog extends StatelessWidget {
  /// 构造函数。
  const MPInsightsMoreDialog({
    super.key,
    required this.onDeleteTap,
  });

  /// 点击删除回调。
  final VoidCallback onDeleteTap;

  /// 显示弹窗；当 [context] 为空时使用全局 context。
  static Future<void> show({
    BuildContext? context,
    required VoidCallback onDeleteTap,
  }) async {
    final BuildContext? targetContext =
        context ?? MyApp.navigatorKey.currentContext;
    if (targetContext == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: targetContext,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return MPInsightsMoreDialog(
          onDeleteTap: () {
            Navigator.of(sheetContext).pop();
            onDeleteTap();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF2F2F7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 12 + safeBottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D1D6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Memory Options',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: OmiFontSize.t9_18,
                    fontWeight: OmiFontWeight.bold,
                    color: mainTextColor,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage this memory',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: OmiFontSize.t6_15,
                    fontWeight: OmiFontWeight.medium,
                    color: secondTextColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 18),
                _DeleteActionTile(onTap: onDeleteTap),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: blueTextColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: OmiFontSize.t7_16,
                        fontWeight: OmiFontWeight.medium,
                        color: blueTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteActionTile extends StatelessWidget {
  const _DeleteActionTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: redColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: OmiFontSize.t6_15,
                        fontWeight: OmiFontWeight.medium,
                        color: redColor,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Remove this memory',
                      style: TextStyle(
                        fontSize: OmiFontSize.t4_13,
                        fontWeight: OmiFontWeight.medium,
                        color: secondTextColor,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
