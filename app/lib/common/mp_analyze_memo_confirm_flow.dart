import 'package:flutter/material.dart';

import 'mp_home_notification.dart';
import '../http/api/mp_todo.dart';
import '../http/schema/mp_memo.dart';
import '../http/schema/mp_todo.dart';
import '../tab/home/home/dialog/mp_qucik_capture_confirm_dialog.dart';
import '../utils/mp_time_utils.dart';
import '../utils/mp_toast_utils.dart';

/// Quick Capture 同款：展示分析结果确认弹窗并在确认后 [batchCreate]。
class MPAnalyzeMemoConfirmFlow {
  MPAnalyzeMemoConfirmFlow._();

  /// 组装 [structuredSuggestions] 为确认列表并弹窗；用户确认后批量创建。
  ///
  /// 返回 `true`：用户点击确认且 [batchCreate] 成功（`base_resp.code == 0`）。
  /// 取消、未选条目、或接口失败返回 `false`。
  static Future<bool> showConfirmAndBatchCreate(
    BuildContext context, {
    required String originalText,
    required List<MPAnalyzeMemoSuggestionStruct> structuredSuggestions,
    required int memoType,
  }) async {
    final String fallbackText = originalText.trim();
    final List<MPQuickCaptureConfirmItem> items = <MPQuickCaptureConfirmItem>[];
    for (final MPAnalyzeMemoSuggestionStruct e in structuredSuggestions) {
      final String content = e.content.trim();
      if (content.isEmpty) {
        continue;
      }
      if (e.type == MPAnalyzeMemoSuggestionType.todo) {
        items.add(
          MPQuickCaptureConfirmItem.todo(content, e.deadline, e.description),
        );
      } else {
        items.add(
          MPQuickCaptureConfirmItem.memo(content, memoType, e.description),
        );
      }
    }
    final MPQuickCaptureConfirmResult? result =
        await MPQucikCaptureConfirmDialog.show(
          context,
          originalText: fallbackText,
          items: items,
          onConfirmSubmit: (MPQuickCaptureConfirmResult confirmResult) {
            return _batchCreateFromResult(confirmResult);
          },
        );
    return result != null && result.confirmed;
  }

  /// 根据确认弹窗结果调用 [batchCreate]；成功返回 `true`。
  static Future<bool> _batchCreateFromResult(
    MPQuickCaptureConfirmResult result,
  ) async {
    final String? chosenOriginal = result.originalText?.trim();
    final bool useOriginalText =
        chosenOriginal != null && chosenOriginal.isNotEmpty;
    final int memoCreateAt = MPTimeUtils.nowUnixSeconds();
    final MPBatchCreateRequest request;
    if (useOriginalText) {
      request = MPBatchCreateRequest(
        memos: <MPBatchCreateMemoItem>[
          MPBatchCreateMemoItem(
            content: chosenOriginal,
            createAt: memoCreateAt,
          ),
        ],
      );
    } else {
      request = MPBatchCreateRequest(todos: result.todos, memos: result.memos);
    }
    final MPBatchCreateResponse? response = await batchCreate(request);
    if (response == null) {
      return false;
    }
    if (response.baseResp.code != 0) {
      MPToastUtils.showMessage(response.baseResp.message);
      return false;
    }
    MPToastUtils.showMessage('todos and memos created.');
    MPHomeNotification.notifyHomeListRefresh();
    return true;
  }
}
