import 'package:flutter/material.dart';

import '../../../http/api/mp_memory.dart';
import '../../../http/schema/mp_data_model.dart';
import '../../../http/schema/mp_memory.dart';
import 'audio/omi_audio_detail_page.dart';
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
      final int status = summaryStatus?.status ?? 0;
      if (!context.mounted) {
        return;
      }
      if (status == 1) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MPMemoryTransitionBlocPage(
              memoryId: id,
              createAt: createAt,
              headline: title,
            ),
          ),
        );
        return;
      }
      if (type == MPMemoryType.onlyRecord) {
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => OmiAudioDetailPage(memoryId: id)));
        return;
      }
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => OmiMemoryDetailPage(memoryId: id)));
    } finally {
      isOpening = false;
    }
  }

  
}
