import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

/// 录音记忆卡片数据（与设计稿：主/副时间、来源、时长）
class MPAudioRecordingCardData {
  const MPAudioRecordingCardData({
    required this.primaryTimeLabel,
    required this.secondaryTimeLabel,
    required this.sourceLabel,
    required this.durationLabel,
  });

  /// 首行粗体时间，如 `Jan 18, 2026, 11:20 AM`
  final String primaryTimeLabel;

  /// 第二行说明时间，如 `January 18, 2026 at 11:20 AM`
  final String secondaryTimeLabel;

  /// 录音来源，如 `MobilePhone`（与左侧麦克风一起展示）
  final String sourceLabel;

  /// 时长文案，如 `3m47s`
  final String durationLabel;
}

const Color _kBorder = Color(0xFFE8E8E6);

/// 录音类 Memory 卡片：圆角白底、双时间 + 底栏「麦克风+来源 | 时长」
class MPAudioRecordingCard extends StatelessWidget {
  const MPAudioRecordingCard({
    super.key,
    required this.data,
    this.onTap,
  });

  final MPAudioRecordingCardData data;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.primaryTimeLabel,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t7_16,
                    fontWeight: OmiFontWeight.medium,
                    color: mainTextColor,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.secondaryTimeLabel,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t4_13,
                    fontWeight: OmiFontWeight.regular,
                    color: secondTextColor,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic_none_outlined,
                          size: 18,
                          color: secondTextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          data.sourceLabel,
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t4_13,
                            fontWeight: OmiFontWeight.regular,
                            color: secondTextColor,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      data.durationLabel,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t4_13,
                        fontWeight: OmiFontWeight.regular,
                        color: secondTextColor,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
