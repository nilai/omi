import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';

/// 「YOU ASKED」问答卡数据：用户气泡 + AI 回复
class MPMemoryYouAskedCardData {
  const MPMemoryYouAskedCardData({
    this.headerTimeLabel = 'Just now',
    required this.userMessage,
    required this.aiReply,
  });

  /// 头部右侧时间，如 `Just now`
  final String headerTimeLabel;

  /// 用户提问（展示在浅灰蓝气泡内）
  final String userMessage;

  /// AI 回复（左侧绿色竖线强调）
  final String aiReply;
}

/// 白底圆角卡：YOU ASKED 标题 + 用户气泡 + AI 回复
class MPMemoryYouAskedCard extends StatelessWidget {
  const MPMemoryYouAskedCard({
    super.key,
    required this.data,
  });

  final MPMemoryYouAskedCardData data;


  /// 用户气泡背景（浅蓝灰）
  static const Color _kUserBubbleBg = Color(0xFFF1F4F9);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: lineColor.withValues(alpha: 0.65),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                    color: greenTextColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: OmiImageLoader.localImg(
                      Assets.omiDetailMessage,
                      width: 12,
                      height: 12,
                      color: greenTextColor,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'YOU ASKED',
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
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _kUserBubbleBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                data.userMessage,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t4_13,
                  fontWeight: OmiFontWeight.regular,
                  color: mainTextColor,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 12),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: greenTextColor, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: OmiImageLoader.localImg(
                          Assets.omiSparkles,
                          width: 12,
                          height: 12,
                          color: greenTextColor,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI',
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t2_11,
                          fontWeight: OmiFontWeight.medium,
                          color: secondTextColor,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.aiReply,
                    style: OmiTextStyle.create(
                      fontSize: OmiFontSize.t4_13,
                      fontWeight: OmiFontWeight.regular,
                      color: mainTextColor,
                      height: 1.45,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
