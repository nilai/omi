import 'package:flutter/material.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';

/// 「YOU ASKED」问答卡数据：用户气泡 + AI 回复
class MPMemoryYouAskedCardData {
  const MPMemoryYouAskedCardData({
    this.headerTimeLabel = 'Just now',
    required this.userMessage,
    required this.aiReply,
    this.count,
  });

  /// 头部右侧时间，如 `Just now`
  final String headerTimeLabel;

  /// 用户提问（展示在浅灰蓝气泡内）
  final String userMessage;

  /// AI 回复（左侧绿色竖线强调）
  final String aiReply;

  final int? count;
}

/// 白底圆角卡：YOU ASKED 标题 + 用户气泡 + AI 回复
class MPMemoryYouAskedCard extends StatelessWidget {
  const MPMemoryYouAskedCard({
    super.key,
    required this.data,
    this.onTap,
  });

  final MPMemoryYouAskedCardData data;

  /// 与详情页底部「Ask AI」一致时传入，整卡可点进会话。
  final VoidCallback? onTap;


  /// 用户气泡背景（浅蓝灰）
  static const Color _kUserBubbleBg = Color(0xFFF1F4F9);

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(12);
    final Widget content = Padding(
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
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: OmiTextStyle.create(
                      fontSize: OmiFontSize.t4_13,
                      fontWeight: OmiFontWeight.regular,
                      color: mainTextColor,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            if ((data.count ?? 0) > 0) ...<Widget>[
              const SizedBox(height: 10),
              Divider(height: 1, color: lineColor),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '${data.count} ${data.count == 1 ? 'message' : 'messages'} · Tap to continue',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondTextColor,
                    fontSize: OmiFontSize.t4_13,
                    fontWeight: OmiFontWeight.medium,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      );

    final Widget shell = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(
          color: lineColor.withValues(alpha: 0.65),
          width: 1,
        ),
      ),
      child: content,
    );

    if (onTap == null) {
      return shell;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: shell,
      ),
    );
  }
}
