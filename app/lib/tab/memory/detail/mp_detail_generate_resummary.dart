import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/http/schema/mp_memory.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_detail_content_card.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_generate_summary_sheet.dart';
import 'package:memo_pin/tab/memory/detail/memory/omi_memory_detail_cubit.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';

/// 打开 Generate Resummary 配置弹窗并触发重新摘要（Memory / Memo 详情共用）。
Future<void> openMPDetailGenerateResummary(BuildContext context) async {
  final OmiMemoryDetailCubit cubit = context.read<OmiMemoryDetailCubit>();
  final OmiMemoryDetailState s = cubit.state;
  if (s.phase != OmiMemoryDetailPhase.loaded || s.data == null) {
    MPToastUtils.showMessage('Please wait until loading finishes.');
    return;
  }
  final MPMemoryDetailCardData d = s.data!;
  final String recordUrl = (d.recordUri ?? '').trim().isNotEmpty
      ? (d.recordUri ?? '').trim()
      : (d.recordFile ?? '').trim();
  final MPSummaryRecordRequest? req = await showMPMemoryGenerateSummarySheet(
    context,
    memoryId: d.memoryId,
    recordUrl: recordUrl,
    isRegen: true,
    onChangeMode: () {
      // TODO: 切换 Autopilot / 其它模式
    },
  );
  if (!context.mounted) return;
  if (req != null) {
    await cubit.runSummaryRegeneration(req);
  }
}
