import 'package:flutter/material.dart';

import '../../../utils/omi_color_utils.dart';
import '../../../utils/omi_font_utils.dart';
import '../../../utils/omi_textstyle.dart';

/// 蓝牙权限被拒绝时的引导弹窗。
///
/// - 取消：返回 `false`（调用方应退出连接页）
/// - 确定：返回 `true`（调用方应打开系统设置）
Future<bool?> showMPBlePermissionDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (BuildContext dialogContext) {
      return const _MPBlePermissionDialog();
    },
  );
}

class _MPBlePermissionDialog extends StatelessWidget {
  const _MPBlePermissionDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Bluetooth Permission Required',
              textAlign: TextAlign.center,
              style: OmiTextStyle.create(
                fontSize: OmiFontSize.t8_17,
                fontWeight: OmiFontWeight.bold,
                color: mainTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bluetooth access was denied. Please enable Bluetooth permission in Settings to scan and connect devices.',
              textAlign: TextAlign.center,
              style: OmiTextStyle.create(
                fontSize: OmiFontSize.t5_14,
                fontWeight: OmiFontWeight.regular,
                color: secondTextColor,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF2F2F7),
                        foregroundColor: mainTextColor,
                        splashFactory: NoSplash.splashFactory,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t5_14,
                          fontWeight: OmiFontWeight.medium,
                          color: mainTextColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        backgroundColor: blueTextColor,
                        foregroundColor: Colors.white,
                        splashFactory: NoSplash.splashFactory,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Sure',
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t5_14,
                          fontWeight: OmiFontWeight.medium,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
