import 'package:flutter/material.dart';
import 'package:omi/http/api/mp_memo.dart';
import 'package:omi/http/schema/mp_memo.dart';
import 'package:omi/tab/memory/detail/memory/mp_analyze_suggested_tasks_sheet.dart';
import 'package:omi/utils/mp_toast_utils.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../../../../generated/assets.dart';
import '../../../../utils/omi_image_loader.dart';

const Color _kMPMemoHighlightAccent = Color(0xFFFFB340);

/// Memo 详情弹窗样式：Manual / Voice / Highlight（与设计稿一致）。
enum MPMemoDetailSheetVariant {
  /// 灰色铅笔 +「Manual Memo」，分段分隔线，可选「Linked memory (optional)」（正文加粗）。
  manual,

  /// 橙色麦克风 +「Voice Memo」，分隔线，大标题 + 正文。
  voice,

  /// 浅灰内容区：橙色 sparkles +「Highlight」+ 蓝色来源行 + 正文。
  highlight,
}

/// 打开 Memo 详情弹窗。
Future<void> showMPMemoDetailSheet(
  BuildContext context, {
  required MPMemoDetailSheetVariant variant,
  required Future<List<String>> Function(String memoText) onAnalyze,
  Future<bool> Function(String memoText)? onDelete,
  /// 有值时删除会先调 `deleteMemo` 接口，成功后再执行 [onDelete]（若有）并关闭弹窗。
  String? memoId,
  String manualMemoText = '',
  String linkedMemoryText = '',
  String voiceTitle = '',
  String voiceBody = '',
  String highlightSourceLine = '',
  String highlightMemoText = '',
}) {
  final String memoKey = switch (variant) {
    MPMemoDetailSheetVariant.manual => manualMemoText.trim(),
    MPMemoDetailSheetVariant.voice =>
      '${voiceTitle.trim()}\n\n${voiceBody.trim()}'.trim(),
    MPMemoDetailSheetVariant.highlight => highlightMemoText.trim(),
  };

  final String? trimmedMemoId = memoId?.trim();
  final bool hasServerMemoId =
      trimmedMemoId != null && trimmedMemoId.isNotEmpty;
  final bool canDelete = hasServerMemoId || onDelete != null;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      final double bottomInset = MediaQuery.viewPaddingOf(sheetContext).bottom;
      final double bottomPad = 20 + bottomInset;
      final bool isHighlight = variant == MPMemoDetailSheetVariant.highlight;

      Widget divider() => Container(
            height: 1,
            color: lineColor.withValues(alpha: 0.8),
          );

      Widget actionsBlock() => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
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
                      memoText: memoKey,
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
          );

      return SizedBox(
        width: double.infinity,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, isHighlight ? 0 : bottomPad),
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
                        onTap: !canDelete
                            ? null
                            : () async {
                                if (hasServerMemoId) {
                                  final MPDeleteMemoResponse? resp =
                                      await deleteMemo(
                                    MPDeleteMemoRequest(
                                      memoId: trimmedMemoId,
                                    ),
                                  );
                                  if (!sheetContext.mounted) return;
                                  if (resp == null ||
                                      resp.baseResp.code != 0) {
                                    MPToastUtils.showMessage(
                                      resp?.baseResp.message ??
                                          '删除 Memo 失败，请稍后重试',
                                    );
                                    return;
                                  }
                                }
                                if (onDelete != null) {
                                  final bool ok = await onDelete(memoKey);
                                  if (!sheetContext.mounted || !ok) return;
                                }
                                Navigator.of(sheetContext).pop();
                              },
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: OmiImageLoader.localImg(
                            Assets.omiDetailDelete,
                            width: 18,
                            height: 18,
                            color: canDelete ? redColor : secondTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                divider(),
                if (variant == MPMemoDetailSheetVariant.manual) ...<Widget>[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: secondTextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Manual Memo',
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t5_14,
                            fontWeight: OmiFontWeight.medium,
                            color: secondTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  divider(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      manualMemoText,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t6_15,
                        fontWeight: OmiFontWeight.regular,
                        color: mainTextColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (linkedMemoryText.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    divider(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Linked memory (optional)',
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t5_14,
                          fontWeight: OmiFontWeight.medium,
                          color: secondTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        linkedMemoryText,
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t6_15,
                          fontWeight: OmiFontWeight.bold,
                          color: mainTextColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  divider(),
                  actionsBlock(),
                ] else if (variant == MPMemoDetailSheetVariant.voice) ...<Widget>[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.mic_none_rounded,
                          size: 18,
                          color: orangeTextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Voice Memo',
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t5_14,
                            fontWeight: OmiFontWeight.medium,
                            color: orangeTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  divider(),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      voiceTitle,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t8_17,
                        fontWeight: OmiFontWeight.bold,
                        color: mainTextColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (voiceBody.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        voiceBody,
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t6_15,
                          fontWeight: OmiFontWeight.regular,
                          color: mainTextColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  divider(),
                  actionsBlock(),
                ] else
                  ColoredBox(
                    color: pageColor,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: bottomPad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: <Widget>[
                                OmiImageLoader.localImg(
                                  Assets.omiSparkles,
                                  width: 16,
                                  height: 16,
                                  color: _kMPMemoHighlightAccent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Highlight',
                                  style: OmiTextStyle.create(
                                    fontSize: OmiFontSize.t5_14,
                                    fontWeight: OmiFontWeight.medium,
                                    color: _kMPMemoHighlightAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (highlightSourceLine.trim().isNotEmpty) ...<Widget>[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                highlightSourceLine,
                                style: OmiTextStyle.create(
                                  fontSize: OmiFontSize.t5_14,
                                  fontWeight: OmiFontWeight.medium,
                                  color: blueTextColor,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          divider(),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              highlightMemoText,
                              style: OmiTextStyle.create(
                                fontSize: OmiFontSize.t6_15,
                                fontWeight: OmiFontWeight.regular,
                                color: mainTextColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          divider(),
                          actionsBlock(),
                        ],
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
