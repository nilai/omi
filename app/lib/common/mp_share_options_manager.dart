import '../http/api/mp_memory.dart';
import '../http/schema/mp_memory.dart';
import 'mp_share_sheet.dart';

class MPShareOptionsManager {
  MPShareOptionsManager._();

  static final MPShareOptionsManager instance = MPShareOptionsManager._();

  Future<MPShareSheetParams> getShareSheetParams({
    required String memoryId,
  }) async {
    MPShareSheetParams params = const MPShareSheetParams();
    try {
      final MPGetShareOptionsResponse? resp = await getShareOptionsV2(
        MPShareMemoryWithOptionsRequest(
          memoryId: memoryId,
          optionIds: const <int>[],
        ),
      );
      if (resp == null || resp.baseResp.code != 0) {
        return params;
      }

      String? requiredId;
      final List<MPShareSummaryOption> options =
          resp.options.map((MPShareOptionItem item) {
        if (item.required && requiredId == null) {
          requiredId = item.optionId.toString();
        }
        return MPShareSummaryOption(
          id: item.optionId.toString(),
          title: item.optionName,
          badge: item.optionKey.trim(),
          timeLabel: '',
        );
      }).toList();
      if (options.isEmpty) {
        return params;
      }
      return MPShareSheetParams(
        summaryOptions: options,
        initialSummaryOptionId: requiredId,
      );
    } catch (_) {
      return params;
    }
  }
}

