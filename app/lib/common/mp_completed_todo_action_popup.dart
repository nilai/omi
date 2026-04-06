import 'package:flutter/material.dart';
import 'package:memo_pin/common/omi_button.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

class MPCompletedTodoActionPopupParams {
  const MPCompletedTodoActionPopupParams({
    required this.title,
    this.statusLabel = 'Completed today',
  });

  final String title;
  final String statusLabel;
}

Future<void> showMPCompletedTodoActionPopup(
  BuildContext context, {
  required MPCompletedTodoActionPopupParams params,
  Future<bool> Function()? onRestore,
  Future<bool> Function()? onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext sheetContext) {
      return _MPCompletedTodoActionPopupSheet(
        params: params,
        onRestore: onRestore,
        onDelete: onDelete,
      );
    },
  );
}

class _MPCompletedTodoActionPopupSheet extends StatefulWidget {
  const _MPCompletedTodoActionPopupSheet({
    required this.params,
    this.onRestore,
    this.onDelete,
  });

  final MPCompletedTodoActionPopupParams params;
  final Future<bool> Function()? onRestore;
  final Future<bool> Function()? onDelete;

  @override
  State<_MPCompletedTodoActionPopupSheet> createState() =>
      _MPCompletedTodoActionPopupSheetState();
}

class _MPCompletedTodoActionPopupSheetState
    extends State<_MPCompletedTodoActionPopupSheet> {
  bool _restoring = false;
  bool _deleting = false;

  Future<void> _onTapRestore() async {
    if (_restoring || _deleting) {
      return;
    }
    if (widget.onRestore == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _restoring = true);
    final bool ok = await widget.onRestore!.call();
    if (!mounted) {
      return;
    }
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _restoring = false);
  }

  Future<void> _onTapDelete() async {
    if (_restoring || _deleting) {
      return;
    }
    if (widget.onDelete == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _deleting = true);
    final bool ok = await widget.onDelete!.call();
    if (!mounted) {
      return;
    }
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _deleting = false);
  }

  @override
  Widget build(BuildContext context) {
    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final bool disabled = _restoring || _deleting;
    return Container(
      color: Colors.white,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 0, safeBottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 56,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: <Widget>[
                    InkWell(
                      onTap: disabled ? null : () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: blueTextColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Todo',
                        textAlign: TextAlign.center,
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t6_15,
                          fontWeight: OmiFontWeight.medium,
                          color: mainTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 34),
                  ],
                ),
              ),
              Container(height: 1, color: lineColor.withValues(alpha: 0.8)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      widget.params.title,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t6_15,
                        fontWeight: OmiFontWeight.medium,
                        color: mainTextColor,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'STATUS',
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t3_12,
                        fontWeight: OmiFontWeight.medium,
                        color: secondTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: greenDeepColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.params.statusLabel,
                            style: OmiTextStyle.create(
                              fontSize: OmiFontSize.t5_14,
                              fontWeight: OmiFontWeight.medium,
                              color: greenDeepColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    OmiButton(
                      text: _restoring ? 'Restoring…' : 'Restore task',
                      textColor: Colors.white,
                      bgColor: blueTextColor,
                      width: double.infinity,
                      height: 50,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: disabled ? null : _onTapRestore,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: disabled ? null : _onTapDelete,
                      child: Text(
                        _deleting ? 'Deleting…' : 'Delete',
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t6_15,
                          fontWeight: OmiFontWeight.medium,
                          color: redColor,
                        ),
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
