import 'package:flutter/material.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';

import '../../../http/api/mp_memory.dart';
import '../../../http/schema/mp_data_model.dart';
import '../../../http/schema/mp_memory.dart';
import 'audio/omi_audio_detail_page.dart';
import 'memo/omi_memo_detail_page.dart';
import 'memory/omi_memory_detail_page.dart';
import 'trans/mp_memory_transition_page.dart';

class MPMemoryDetailPageHelper {
  static bool isOpening = false;

  /// 打开详情页统一入口。
  ///
  /// @param {BuildContext} context
  /// @param {String} memoryId
  /// @param {MPMemoryType} type
  /// @returns `Future<void>`
  static Future<void> navigateToDetailPage(
    BuildContext context,
    String memoryId,
    MPMemoryType type, {
    int? createAt,
    String? title,
  }) async {
    if (isOpening) {
      return;
    }
    if (type == MPMemoryType.memoList) {
      return;
    }
    final String id = memoryId.trim();
    if (id.isEmpty) {
      return;
    }
    isOpening = true;
    try {
      if (!context.mounted) {
        return;
      }
      final MPGetSummaryStatusResponse? summaryStatus = await getSummaryStatus(MPGetSummaryStatusRequest(memoryId: id));
      if (!context.mounted) {
        return;
      }
      if (summaryStatus == null) {
        return;
      }
      final int status = summaryStatus.status;
      if (status == 0) {
        MPToastUtils.showMessage('This memory has been deleted.', context: context);
        return;
      }
      if (status == 1) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MPMemoryTransitionBlocPage(memoryId: id, createAt: createAt, headline: title),
          ),
        );
        return;
      }
      final MPMemoryType newType = MPMemoryType.fromWireValue(summaryStatus.type);
      switch (newType) {
        case MPMemoryType.onlyRecord:
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => OmiAudioDetailPage(memoryId: id)));
          break;
        case MPMemoryType.summary:
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (BuildContext context) => OmiMemoDetailPage(memoryId: id)));
          break;
        case MPMemoryType.memoryFeed:
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (BuildContext context) => OmiMemoryDetailPage(memoryId: id)));
          break;
        case MPMemoryType.memoList:
          break;
      }
    } finally {
      isOpening = false;
    }
  }
}
