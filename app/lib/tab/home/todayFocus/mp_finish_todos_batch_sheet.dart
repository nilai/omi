import 'package:flutter/material.dart';
import 'package:memo_pin/common/mp_dismissible_modal_backdrop.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

/// Unscheduled / Overdue 批量 Finish 确认弹窗类型。
enum MPFinishTodosBatchKind {
  unscheduled,
  overdue,
}

class MPFinishTodosBatchSheetParams {
  const MPFinishTodosBatchSheetParams({required this.kind});

  final MPFinishTodosBatchKind kind;

  String get title {
    switch (kind) {
      case MPFinishTodosBatchKind.unscheduled:
        return 'Finish all unscheduled todos?';
      case MPFinishTodosBatchKind.overdue:
        return 'Finish all overdue todos?';
    }
  }
}

/// 返回 `true` 表示用户点击了 Finish。
Future<bool?> showMPFinishTodosBatchSheet(
  BuildContext context, {
  required MPFinishTodosBatchSheetParams params,
  VoidCallback? onFinish,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext sheetContext) {
      return _MPFinishTodosBatchSheet(
        params: params,
        onFinish: onFinish,
      );
    },
  );
}

class _MPFinishTodosBatchSheet extends StatefulWidget {
  const _MPFinishTodosBatchSheet({
    required this.params,
    this.onFinish,
  });

  final MPFinishTodosBatchSheetParams params;
  final VoidCallback? onFinish;

  @override
  State<_MPFinishTodosBatchSheet> createState() =>
      _MPFinishTodosBatchSheetState();
}

class _MPFinishTodosBatchSheetState extends State<_MPFinishTodosBatchSheet> {
  void _onTapFinish() {
    Navigator.of(context).pop(true);
    widget.onFinish?.call();
  }

  @override
  Widget build(BuildContext context) {
    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return MPDismissibleModalBackdrop(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, safeBottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: lineColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Text(
                widget.params.title,
                style: OmiTextStyle.create(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: omiMainBodyText,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'These todos will be moved to Completed. They will not be deleted.',
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t6_15,
                  fontWeight: OmiFontWeight.regular,
                  color: omiSecondaryBodyText,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF2F2F7),
                          foregroundColor: omiMainBodyText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          splashFactory: NoSplash.splashFactory,
                        ),
                        child: Text(
                          'Cancel',
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t8_17,
                            fontWeight: FontWeight.w600,
                            color: omiMainBodyText,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: TextButton(
                        onPressed: _onTapFinish,
                        style: TextButton.styleFrom(
                          backgroundColor: blueTextColor,
                          foregroundColor: omiWhiteText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          splashFactory: NoSplash.splashFactory,
                        ),
                        child: Text(
                          'Finish',
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t8_17,
                            fontWeight: FontWeight.w600,
                            color: omiWhiteText,
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
      ),
    );
  }
}
