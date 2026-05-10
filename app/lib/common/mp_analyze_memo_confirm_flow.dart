import 'package:flutter/material.dart';

import '../http/api/mp_todo.dart';
import '../http/schema/mp_memo.dart';
import '../http/schema/mp_todo.dart';
import '../tab/home/home/dialog/mp_qucik_capture_confirm_dialog.dart';
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
  }) async {
    final String fallbackText = originalText.trim();
    final List<MPQuickCaptureConfirmItem> items = <MPQuickCaptureConfirmItem>[];
    for (final MPAnalyzeMemoSuggestionStruct e in structuredSuggestions) {
      final String content = e.content.trim();
      if (content.isEmpty) {
        continue;
      }
      if (e.type == MPAnalyzeMemoSuggestionType.todo) {
        items.add(MPQuickCaptureConfirmItem.todo(content));
      } else {
        items.add(MPQuickCaptureConfirmItem.memo(content));
      }
    }
    final MPQuickCaptureConfirmResult? result = await MPQucikCaptureConfirmDialog.show(
      context,
      originalText: fallbackText,
      items: items,
    );
    if (result == null || !result.confirmed) {
      return false;
    }
    if (result.todos.isEmpty && result.memos.isEmpty) {
      MPToastUtils.showMessage('No suggestions selected.');
      return false;
    }
    final MPBatchCreateResponse? response = await batchCreate(
      MPBatchCreateRequest(todos: result.todos, memos: result.memos),
    );
    if (response == null) {
      return false;
    }
    if (response.baseResp.code != 0) {
      MPToastUtils.showMessage(response.baseResp.message);
      return false;
    }
    MPToastUtils.showMessage('todos and memos created.');
    return true;
  }
}
