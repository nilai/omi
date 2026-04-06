import 'package:flutter/material.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

/// 通用确认删除弹窗参数。
class MPConfirmDeleteDialogParams {
  const MPConfirmDeleteDialogParams({
    this.title = 'Delete Todo',
    this.messageLine1 = 'Are you sure you want to delete this todo?',
    this.messageLine2 = 'This action cannot be undone.',
    this.cancelText = 'No, Keep Todo',
    this.confirmText = 'Yes, Delete',
  });

  final String title;
  final String messageLine1;
  final String messageLine2;
  final String cancelText;
  final String confirmText;
}

/// 打开确认删除弹窗；确认返回 `true`，否则返回 `false`。
Future<bool> showMPConfirmDeleteDialog(
  BuildContext context, {
  MPConfirmDeleteDialogParams params = const MPConfirmDeleteDialogParams(),
}) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return _MPConfirmDeleteDialog(params: params);
    },
  );
  return ok ?? false;
}

class _MPConfirmDeleteDialog extends StatelessWidget {
  const _MPConfirmDeleteDialog({required this.params});

  final MPConfirmDeleteDialogParams params;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: 28,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Text(
                    params.title,
                    style: OmiTextStyle.create(
                      fontSize: OmiFontSize.t8_17,
                      fontWeight: OmiFontWeight.bold,
                      color: mainTextColor,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(false),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: secondTextColor.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              params.messageLine1,
              textAlign: TextAlign.start,
              style: OmiTextStyle.create(
                fontSize: OmiFontSize.t5_14,
                fontWeight: OmiFontWeight.regular,
                color: secondTextColor,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              params.messageLine2,
              textAlign: TextAlign.center,
              style: OmiTextStyle.create(
                fontSize: OmiFontSize.t5_14,
                fontWeight: OmiFontWeight.regular,
                color: secondTextColor,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF2F2F7),
                        foregroundColor: mainTextColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        params.cancelText,
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
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        backgroundColor: redColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        params.confirmText,
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
