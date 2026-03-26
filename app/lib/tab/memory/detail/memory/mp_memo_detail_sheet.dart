import 'package:flutter/material.dart';
import 'package:omi/tab/memory/detail/memory/mp_analyze_suggested_tasks_sheet.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../../../../generated/assets.dart';
import '../../../../utils/omi_image_loader.dart';

/// 打开 Memo 详情弹窗（复用「MY MEMOS」中的同款 UI）。
Future<void> showMPMemoDetailSheet(
  BuildContext context, {
  required String memoText,
  required String sourceLine,
  required Future<List<String>> Function(String memoText) onAnalyze,
  Future<bool> Function(String memoText)? onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      final double bottomInset = MediaQuery.viewPaddingOf(sheetContext).bottom;
      return Container(
        width: double.infinity,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: pageColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 20 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  height: 50,
                  color: Colors.white,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      InkWell(
                        onTap: () => Navigator.of(sheetContext).pop(),
                        borderRadius: BorderRadius.circular(999),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 20,
                              color: blueTextColor,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Memo',
                          textAlign: TextAlign.center,
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t8_17,
                            fontWeight: OmiFontWeight.medium,
                            color: mainTextColor,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: onDelete == null
                            ? null
                            : () async {
                                final bool ok = await onDelete(memoText);
                                if (!sheetContext.mounted || !ok) return;
                                Navigator.of(sheetContext).pop();
                              },
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: OmiImageLoader.localImg(
                            Assets.omiDetailDelete,
                            width: 18,
                            height: 18,
                            color: onDelete == null
                                ? secondTextColor
                                : redColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Row(
                    children: <Widget>[
                      OmiImageLoader.localImg(
                        Assets.omiSparkles,
                        width: 16,
                        height: 16,
                        color: const Color(0xFFFFB340),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Highlight',
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t5_14,
                          fontWeight: OmiFontWeight.medium,
                          color: const Color(0xFFFFB340),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (sourceLine.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Text(
                      sourceLine,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.medium,
                        color: blueTextColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                if (sourceLine.isNotEmpty) const SizedBox(height: 14),
                Container(height: 1, color: lineColor.withValues(alpha: 0.8)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Text(
                    memoText,
                    style: OmiTextStyle.create(
                      fontSize: OmiFontSize.t6_15,
                      fontWeight: OmiFontWeight.regular,
                      color: mainTextColor,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: lineColor.withValues(alpha: 0.8)),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Text(
                    'Actions',
                    style: OmiTextStyle.create(
                      fontSize: OmiFontSize.t5_14,
                      fontWeight: OmiFontWeight.medium,
                      color: secondTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: InkWell(
                    onTap: () {
                      showMPAnalyzeSuggestedTasksSheet(
                        sheetContext,
                        memoText: memoText,
                        onAnalyze: onAnalyze,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          OmiImageLoader.localImg(
                            Assets.omiSparkles,
                            width: 16,
                            height: 16,
                            color: blueTextColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Analyze actions',
                            style: OmiTextStyle.create(
                              fontSize: OmiFontSize.t6_15,
                              fontWeight: OmiFontWeight.medium,
                              color: blueTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
