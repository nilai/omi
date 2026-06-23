import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memo_pin/cache/mp_hive_util.dart';
import 'package:memo_pin/common/mp_dismissible_modal_backdrop.dart';
import 'package:memo_pin/common/omi_button.dart';
import 'package:memo_pin/http/schema/mp_data_model.dart';
import 'package:memo_pin/http/schema/mp_home.dart';
import 'package:memo_pin/main.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../generated/assets.dart';
import 'mp_summary_record_fixtures.dart';

/// [summaryRecord] 转录额度已用尽的业务错误码。
const int kMPSummaryRecordTranscriptionLimitCode = 10004;

const String _kHomeOverviewHiveKey = 'mp_home_overview_v1';

/// 从首页 Hive 缓存解析转录用量文案，例如 `1,000 / 1,000 min used`。
Future<String> mpResolveTranscriptionUsageText() async {
  try {
    final Map<String, dynamic>? cached = await MPHiveUtil.instance.getMap(_kHomeOverviewHiveKey);
    if (cached == null || cached.isEmpty) {
      return '';
    }
    final Map<String, dynamic>? bannerMap =
        cached['transcription_banner'] as Map<String, dynamic>?;
    if (bannerMap == null || bannerMap.isEmpty) {
      return '';
    }
    final MPTranscriptionBannerStruct banner = MPTranscriptionBannerStruct.fromJson(bannerMap);
    return mpFormatTranscriptionUsageText(
      usedMinutes: banner.quotaMinutesUsed,
      totalMinutes: banner.currentMinutes,
    );
  } catch (_) {
    return '';
  }
}

/// 将已用/总额分钟格式化为弹窗用量文案。
String mpFormatTranscriptionUsageText({
  required int usedMinutes,
  required int totalMinutes,
}) {
  final NumberFormat formatter = NumberFormat('#,###');
  final String used = formatter.format(usedMinutes);
  final String total = formatter.format(totalMinutes);
  return '$used / $total min used';
}

/// 展示转录额度已用尽底部弹窗。
Future<void> showMPTranscriptionLimitSheet(
  BuildContext context, {
  required String message,
  required String usageText,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    useRootNavigator: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (BuildContext ctx) {
      return MPDismissibleModalBackdrop(
        child: _MPTranscriptionLimitSheet(
          message: message,
          usageText: usageText,
        ),
      );
    },
  );
}

/// [summaryRecord] 返回 [kMPSummaryRecordTranscriptionLimitCode] 时展示额度弹窗。
Future<void> mpHandleSummaryRecordTranscriptionLimit(
  MPBaseResp baseResp, {
  String? usageText,
}) async {
  final String trimmedMessage = baseResp.message.trim();
  String resolvedUsage = (usageText ?? '').trim();
  if (resolvedUsage.isEmpty) {
    resolvedUsage = (await mpResolveTranscriptionUsageText()).trim();
  }
  if (resolvedUsage.isEmpty && kDebugMode && MPSummaryRecordFixtures.mockTranscriptionLimitEnabled) {
    resolvedUsage = MPSummaryRecordFixtures.mockUsageText;
  }
  final BuildContext? context = MyApp.navigatorKey.currentContext;
  if (context == null || !context.mounted) {
    return;
  }
  await showMPTranscriptionLimitSheet(
    context,
    message: trimmedMessage.isNotEmpty
        ? trimmedMessage
        : 'You\'ve used all of your test transcription minutes. This recording is saved, but AI transcription and summaries are paused.',
    usageText: resolvedUsage,
  );
}

class _MPTranscriptionLimitSheet extends StatelessWidget {
  const _MPTranscriptionLimitSheet({
    required this.message,
    required this.usageText,
  });

  final String message;
  final String usageText;

  static const Color _kWarningIconBg = Color(0xFFFFF1E3);
  static const Color _kWarningIconColor = Color(0xFFDA8A3F);
  static const Color _kUsageBoxBg = Color(0xFFF2F2F7);

  Widget _buildWarningIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: _kWarningIconBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: OmiImageLoader.localImg(
        Assets.mpInsightCircleAlert,
        width: 22,
        height: 22,
        scale: 3.0,
        fit: BoxFit.contain,
        color: _kWarningIconColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Material(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: _buildWarningIcon(),
              ),
              const SizedBox(height: 12),
              Text(
                'Test transcription limit reached',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t9_18,
                  fontWeight: OmiFontWeight.bold,
                  color: mainTextColor,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t5_14,
                  fontWeight: OmiFontWeight.regular,
                  color: secondTextColor,
                  height: 1.4,
                ),
              ),
              if (usageText.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _kUsageBoxBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      OmiImageLoader.localImg(
                        Assets.mpClock,
                        width: 16,
                        height: 16,
                        scale: 3.0,
                        fit: BoxFit.cover,
                        color: secondTextColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          usageText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t5_14,
                            fontWeight: OmiFontWeight.medium,
                            color: mainTextColor,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              OmiButton(
                text: 'OK',
                width: double.infinity,
                height: 50,
                bgColor: mainTextColor,
                textColor: Colors.white,
                textFontSize: OmiFontSize.t8_17,
                textFontWeight: OmiFontWeight.bold,
                borderRadius: BorderRadius.circular(14),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
