import 'package:flutter/material.dart';
import 'package:memo_pin/common/omi_button.dart';
import 'package:memo_pin/generated/assets.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

/// AI 推荐任务卡片：白底圆角阴影、角标、关闭、标题、计划时间、`Add to Focus` 主按钮。
class MPTodayFocusAddCard extends StatelessWidget {
  const MPTodayFocusAddCard({
    super.key,
    required this.title,
    this.scheduledTimeLabel,
    this.headerLabel = 'SUGGESTED BY AI',
    this.addButtonText = 'Add to Focus',
    this.onAddToFocus,
    this.onDismiss,
  });

  final String title;

  /// 展示为 `→ Scheduled for {值}`；为 `null` 或空串时不显示该行。
  final String? scheduledTimeLabel;

  final String headerLabel;
  final String addButtonText;
  final VoidCallback? onAddToFocus;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final bool showSchedule = scheduledTimeLabel != null &&
        scheduledTimeLabel!.trim().isNotEmpty;

    return Column(
      children: [
        Container(
          color: lineColor,
          height: 1,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      headerLabel.toUpperCase(),
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t2_11,
                        fontWeight: OmiFontWeight.medium,
                        color: secondTextColor,
                        letterSpacing: 0.6,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (onDismiss != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onDismiss,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 4, 4),
                          child: OmiImageLoader.localImg(
                            Assets.omiClose,
                            width: 20,
                            height: 20,
                            color: secondTextColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t6_15,
                  fontWeight: OmiFontWeight.bold,
                  color: mainTextColor,
                  height: 1.35,
                ),
              ),
              if (showSchedule) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  '→ Scheduled for ${scheduledTimeLabel!.trim()}',
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t3_12,
                    fontWeight: OmiFontWeight.regular,
                    color: secondTextColor,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              OmiButton(
                text: addButtonText,
                width: double.infinity,
                height: 50,
                bgColor: blueTextColor,
                textColor: Colors.white,
                textFontSize: OmiFontSize.t5_14,
                textFontWeight: OmiFontWeight.medium,
                borderRadius: BorderRadius.circular(12),
                onPressed: onAddToFocus,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
