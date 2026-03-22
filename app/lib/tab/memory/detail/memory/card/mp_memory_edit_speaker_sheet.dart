import 'package:flutter/material.dart';
import 'package:omi/common/omi_button.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

/// 编辑说话人弹窗的保存结果
class MPMemoryEditSpeakerResult {
  const MPMemoryEditSpeakerResult({
    required this.newName,
    required this.applyToAll,
  });

  final String newName;

  /// 为 `true` 时替换 transcript 中所有同名说话人
  final bool applyToAll;
}

/// 展示「Edit Speaker Name」底部弹窗，返回保存结果；取消时为 `null`
Future<MPMemoryEditSpeakerResult?> showMPMemoryEditSpeakerSheet({
  required BuildContext context,
  required String currentSpeakerName,
}) {
  return showModalBottomSheet<MPMemoryEditSpeakerResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext ctx) => _MPEditSpeakerSheetBody(
      currentSpeakerName: currentSpeakerName,
    ),
  );
}

class _MPEditSpeakerSheetBody extends StatefulWidget {
  const _MPEditSpeakerSheetBody({
    required this.currentSpeakerName,
  });

  final String currentSpeakerName;

  @override
  State<_MPEditSpeakerSheetBody> createState() =>
      _MPEditSpeakerSheetBodyState();
}

class _MPEditSpeakerSheetBodyState extends State<_MPEditSpeakerSheetBody> {
  late final TextEditingController _controller;
  bool _applyToAll = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentSpeakerName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final String oldName = widget.currentSpeakerName;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Edit Speaker Name',
                  textAlign: TextAlign.start,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t11_20,
                    fontWeight: OmiFontWeight.bold,
                    color: mainTextColor,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Change \"$oldName\" to a new name",
                  textAlign: TextAlign.start,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t4_13,
                    fontWeight: OmiFontWeight.regular,
                    color: secondTextColor,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'New Speaker Name',
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t3_12,
                    fontWeight: OmiFontWeight.regular,
                    color: secondTextColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t5_14,
                    fontWeight: OmiFontWeight.regular,
                    color: mainTextColor,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: blueTextColor, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: blueTextColor, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: blueTextColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _applyToAll,
                        activeColor: mainTextColor,
                        onChanged: (bool? v) {
                          setState(() => _applyToAll = v ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Apply to all \"$oldName\"",
                            style: OmiTextStyle.create(
                              fontSize: OmiFontSize.t5_14,
                              fontWeight: OmiFontWeight.regular,
                              color: mainTextColor,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Update all segments where this speaker appears in the transcript',
                            style: OmiTextStyle.create(
                              fontSize: OmiFontSize.t3_12,
                              fontWeight: OmiFontWeight.regular,
                              color: secondTextColor,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OmiButton(
                        text: 'Cancel',
                        height: 48,
                        bgColor: const Color(0xFFF2F2F7),
                        textColor: mainTextColor,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OmiButton(
                        text: 'Save',
                        height: 48,
                        bgColor: blueTextColor,
                        textColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () {
                          final String name = _controller.text.trim();
                          if (name.isEmpty) return;
                          Navigator.of(context).pop(
                            MPMemoryEditSpeakerResult(
                              newName: name,
                              applyToAll: _applyToAll,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
