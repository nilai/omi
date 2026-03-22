import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';

/// Transcript 列表单行数据
class MPMemoryTranscriptItemData {
  /// [timestamp] 如 `00:00`
  const MPMemoryTranscriptItemData({
    required this.timestamp,
    required this.speakerName,
    required this.transcriptText,
    this.waveformHeights,
  });

  final String timestamp;

  final String speakerName;

  final String transcriptText;

  /// 波形高度 0~1，不传则内部生成占位
  final List<double>? waveformHeights;

  /// 复制并覆盖部分字段（用于编辑说话人等）
  MPMemoryTranscriptItemData copyWith({
    String? timestamp,
    String? speakerName,
    String? transcriptText,
    List<double>? waveformHeights,
  }) {
    return MPMemoryTranscriptItemData(
      timestamp: timestamp ?? this.timestamp,
      speakerName: speakerName ?? this.speakerName,
      transcriptText: transcriptText ?? this.transcriptText,
      waveformHeights: waveformHeights ?? this.waveformHeights,
    );
  }
}

/// Transcript 列表项：左侧时间戳 + 右侧说话人 / 编辑 / 播放 / 播放中波形 + 正文
class MPMemoryTranscriptItem extends StatelessWidget {
  /// {@template MPMemoryTranscriptItem}
  /// 与设计稿一致：深绿底、浅灰时间戳、说话人加粗、圆形浅灰操作钮；播放时下方显示细竖线波形动画。
  /// {@endtemplate}
  const MPMemoryTranscriptItem({
    super.key,
    required this.data,
    this.isPlaying = false,
    this.isSelected = false,
    this.onEditTap,
    this.onPlayTap,
  });

  final MPMemoryTranscriptItemData data;
  final bool isPlaying;
  final bool isSelected;

  final VoidCallback? onEditTap;

  final VoidCallback? onPlayTap;

  @override
  Widget build(BuildContext context) {
    final MPMemoryTranscriptItemData d = data;
    final Color textColor = Colors.white.withValues(alpha: 0.92);
    final Color subTextColor = isSelected
        ? mainTextColor
        : Colors.white.withValues(alpha: 0.72);
    final Color timeColor =  Colors.white.withValues(alpha: 0.8);
    return GestureDetector(
      onTap: onPlayTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top:2.0),
                child: SizedBox(
                  width: 52,
                  child: Text(
                    d.timestamp,
                    style: OmiTextStyle.create(
                      fontSize: OmiFontSize.t4_13,
                      fontWeight: OmiFontWeight.medium,
                      color: timeColor,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            d.speakerName,
                            style: OmiTextStyle.create(
                              fontSize: OmiFontSize.t5_14,
                              fontWeight: OmiFontWeight.medium,
                              color: textColor,
                              height: 1.35,
                            ),
                          ),
                        ),
                        SizedBox(width: 8,),
                        _MPTranscriptIconButton(
                          asset: Assets.omiDetailEdit,
                          onTap: onEditTap,
                          darkIcon: false,
                        ),
                        const SizedBox(width: 6),
                        _MPTranscriptIconButton(
                          asset: isPlaying ? Assets.omiPause : Assets.omiPlay,
                          onTap: onPlayTap,
                          darkIcon: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      d.transcriptText,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t4_13,
                        fontWeight: OmiFontWeight.regular,
                        color: subTextColor,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 圆形浅灰底图标按钮（编辑 / 播放）
class _MPTranscriptIconButton extends StatelessWidget {
  const _MPTranscriptIconButton({
    required this.asset,
    this.darkIcon = false,
    this.onTap,
  });

  final String asset;
  final bool darkIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: darkIcon
                ? const Color(0xFF1F3A31).withValues(alpha: 0.12)
                : Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: OmiImageLoader.localImg(
              asset,
              width: 10,
              height: 10,
              color: darkIcon
                  ? const Color(0xFF1F3A31)
                  : Color(0xFF1F3A31),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
