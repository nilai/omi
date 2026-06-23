import 'package:memo_pin/http/schema/mp_memory.dart';
import 'package:memo_pin/tab/memory/detail/mp_transcription_limit_sheet.dart';

/// [summaryRecord] 接口离线测试数据。
class MPSummaryRecordFixtures {
  MPSummaryRecordFixtures._();

  /// Debug 下为 `true` 时，`summaryRecord` 直接返回 [transcriptionLimitResponse]。
  static const bool mockTranscriptionLimitEnabled = false;

  /// 弹窗用量区测试文案。
  static const String mockUsageText = '1,000 / 1,000 min used';

  /// 转录额度已用尽（`code == 10004`）响应。
  static MPSummaryRecordResponse transcriptionLimitResponse() {
    return MPSummaryRecordResponse.fromJson(<String, dynamic>{
      'base_resp': <String, dynamic>{
        'code': kMPSummaryRecordTranscriptionLimitCode,
        'message':
            'You\'ve used all of your test transcription minutes. This recording is saved, but AI transcription and summaries are paused.',
        'logid': 'mock-summary-record-10004',
      },
      'summary_id': '',
    });
  }
}
