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
        MPGetShareOptionsRequest(memoryId: memoryId),
      );
      if (resp == null || resp.baseResp.code != 0) {
        return params;
      }

      String? requiredId;
      final List<MPShareSummaryOption> requiredOptions = <MPShareSummaryOption>[];
      final List<MPShareSummaryOption> optionalOptions = <MPShareSummaryOption>[];
      for (final MPShareOptionItem item in resp.options) {
        if (item.required && requiredId == null) {
          requiredId = item.optionId.toString();
        }
        final String key = item.optionKey.trim();
        final String keyLower = key.toLowerCase();
        if (keyLower == 'transcript') {
          // 产品要求：不展示 transcript 标签
        }
        final String badge = (item.required ? 'Required' : '');
        final MPShareSummaryOption opt = MPShareSummaryOption(
          id: item.optionId.toString(),
          title: item.optionName,
          badge: badge,
          timeLabel: '',
        );
        if (item.required) {
          requiredOptions.add(opt);
        } else {
          optionalOptions.add(opt);
        }
      }
      if (requiredOptions.isEmpty && optionalOptions.isEmpty) {
        return params;
      }
      return MPShareSheetParams(
        requiredSummaryOptions: requiredOptions,
        optionalSummaryOptions: optionalOptions,
        initialSummaryOptionId: requiredId,
      );
    } catch (_) {
      return params;
    }
  }
}

