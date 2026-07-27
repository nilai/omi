import 'package:flutter/material.dart';
import 'package:memo_pin/common/mp_dismissible_modal_backdrop.dart';
import 'package:memo_pin/common/mp_memory_notification.dart';
import 'package:memo_pin/http/api/mp_memo.dart';
import 'package:memo_pin/http/schema/mp_memo.dart';
import 'package:memo_pin/tab/memory/detail/memory/mp_analyze_suggested_tasks_sheet.dart';
import 'package:memo_pin/utils/mp_time_utils.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../../generated/assets.dart';
import '../../../../utils/omi_image_loader.dart';

const Color _kMPMemoHighlightAccent = Color(0xFFFFB340);

/// Memo 正文展示，与 Execution Insight 一致使用 [SelectableText.rich]。
Widget _mpMemoSelectableBody(String text, TextStyle style) {
  return SelectableText.rich(TextSpan(text: text, style: style));
}

/// Memo 详情弹窗样式：Manual / Voice / Highlight（与设计稿一致）。
enum MPMemoDetailSheetVariant {
  /// 灰色铅笔 +「Manual Memo」，分段分隔线，可选「Linked memory (optional)」（正文加粗）。
  manual,

  /// 橙色麦克风 +「Voice Memo」，分隔线，大标题 + 正文。
  voice,

  /// 浅灰内容区：橙色 sparkles +「Highlight」+ 蓝色来源行 + 正文。
  highlight;

  static MPMemoDetailSheetVariant fromWireValue(String? value) {
    switch (value) {
      case 'record':  
        return MPMemoDetailSheetVariant.voice;
      case 'text':
        return MPMemoDetailSheetVariant.manual;
      default:
        return MPMemoDetailSheetVariant.highlight;
    }
  }
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
    isDismissible: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
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
                    final String content = memoKey.trim();
                    if (content.isEmpty) {
                      MPToastUtils.showMessage('Content is empty.');
                      return;
                    }
                    showMPAnalyzeSuggestedTasksSheet(
                      sheetContext,
                      memoText: content,
                      dismissContextOnCreateSuccess: sheetContext,
                      onAnalyzeStructured: (String memoText) async {
                        try {
                          final MPAnalyzeMemoTextResponse? resp =
                              await analyzeMemoText(
                            MPAnalyzeMemoTextRequest(
                              content: memoText.trim(),
                              createAt:
                                  MPTimeUtils.nowUnixSeconds(),
                            ),
                          );
                          if (resp == null) {
                            MPToastUtils.showMessage('Analysis failed.');
                            return <MPAnalyzeMemoSuggestionStruct>[];
                          }
                          if (resp.baseResp.code != 0) {
                            MPToastUtils.showMessage(resp.baseResp.message);
                            return <MPAnalyzeMemoSuggestionStruct>[];
                          }
                          return resp.structuredSuggestions
                              .map(
                                (s) => MPAnalyzeMemoSuggestionStruct(
                                  type: s.type,
                                  content: s.content.trim(),
                                  deadline: s.deadline,
                                  description: s.description,
                                ),
                              )
                              .where((s) => s.content.isNotEmpty)
                              .toList();
                        } catch (_) {
                          MPToastUtils.showMessage('Analysis failed.');
                          return <MPAnalyzeMemoSuggestionStruct>[];
                        }
                      },
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

      return MPDismissibleModalBackdrop(
        child: SizedBox(
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
                                          'Couldn\'t delete memo. Please try again later.',
                                    );
                                    return;
                                  }
                                }
                                if (onDelete != null) {
                                  final bool ok = await onDelete(memoKey);
                                  if (!sheetContext.mounted || !ok) return;
                                }
                                MPMemoryNotification.notifyMemoryListRefresh();
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
                    child: _mpMemoSelectableBody(
                      manualMemoText,
                      OmiTextStyle.create(
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
                      child: _mpMemoSelectableBody(
                        linkedMemoryText,
                        OmiTextStyle.create(
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
                    child: _mpMemoSelectableBody(
                      voiceTitle,
                      OmiTextStyle.create(
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
                      child: _mpMemoSelectableBody(
                        voiceBody,
                        OmiTextStyle.create(
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
                            child: _mpMemoSelectableBody(
                              highlightMemoText,
                              OmiTextStyle.create(
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
        ),
      );
    },
  );
}
