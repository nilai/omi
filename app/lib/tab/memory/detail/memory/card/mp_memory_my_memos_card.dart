import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';

/// 「MY MEMOS」整卡数据
class MPMemoryMyMemosCardData {
  const MPMemoryMyMemosCardData({
    this.headerTimeLabel = 'Just now',
    required this.lines,
  });

  /// 头部右侧时间，如 `Just now`
  final String headerTimeLabel;

  /// 每条 Memo 正文（展示时会加引号样式）
  final List<String> lines;
}

/// 左侧蓝色竖条 + 白底圆角，展示多条 Memo 摘录
class MPMemoryMyMemosCard extends StatelessWidget {
  const MPMemoryMyMemosCard({
    super.key,
    required this.data,
  });

  final MPMemoryMyMemosCardData data;

  static const Color _kLeftStripe = blueTextColor;
  static const Color _kIconCircleBg = Color(0xFFE8F4FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: blueTextColor, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: blueTextColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: OmiImageLoader.localImg(
                        Assets.omiDetailEdit,
                        width: 12,
                        height: 12,
                        color: blueTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'MY MEMOS',
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t3_12,
                        fontWeight: OmiFontWeight.bold,
                        color: secondTextColor,
                        height: 1.2,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                Text(
                  data.headerTimeLabel,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t2_11,
                    fontWeight: OmiFontWeight.regular,
                    color: secondTextColor.withValues(alpha: 0.85),
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (int i = 0; i < data.lines.length; i++) ...<Widget>[
              if (i > 0) ...<Widget>[
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: lineColor.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                '“${data.lines[i]}”',
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t4_13,
                  fontWeight: OmiFontWeight.medium,
                  color: mainTextColor,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
