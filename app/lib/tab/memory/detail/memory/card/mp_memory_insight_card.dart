import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';

/// Insight 卡片配色主题（商务洞察 / 执行洞察）
enum MPInsightCardTone {
  /// 暖橙：Business insight
  business,

  /// 冷蓝：Execution insight
  execution,
}

/// 单条 Insight 卡片数据
class MPMemoryInsightItemData {
  const MPMemoryInsightItemData({
    required this.tone,
    required this.timeLabel,
    required this.bodyText,
    this.categoryTitle,
  });

  final MPInsightCardTone tone;

  /// 右侧相对时间，如 `2 min later`
  final String timeLabel;

  /// 正文
  final String bodyText;

  /// 不传则根据 [tone] 使用默认英文大写标题
  final String? categoryTitle;

  /// 展示用分类标题（全大写）
  String get resolvedCategoryTitle {
    if (categoryTitle != null && categoryTitle!.isNotEmpty) {
      return categoryTitle!;
    }
    switch (tone) {
      case MPInsightCardTone.business:
        return 'BUSINESS INSIGHT';
      case MPInsightCardTone.execution:
        return 'EXECUTION INSIGHT';
    }
  }
}

class _MPInsightVisual {
  const _MPInsightVisual({
    required this.cardBg,
    required this.accent,
    required this.iconBg,
    required this.buttonBg,
    required this.buttonForeground,
    required this.icon,
  });

  final Color cardBg;
  final Color accent;
  final Color iconBg;
  final Color buttonBg;
  final Color buttonForeground;
  final String? icon;

  static _MPInsightVisual of(MPInsightCardTone tone) {
    switch (tone) {
      case MPInsightCardTone.business:
        return _MPInsightVisual(
          cardBg: orangeTextColor.withAlpha(30),
          accent: orangeTextColor,
          iconBg: orangeTextColor,
          buttonBg: orangeTextColor.withAlpha(80),
          buttonForeground: orangeTextColor,
          icon: Assets.omiDetailGift,
        );
      case MPInsightCardTone.execution:
        return _MPInsightVisual(
          cardBg: blueTextColor.withAlpha(30),
          accent: blueTextColor,
          iconBg: blueTextColor,
          buttonBg: blueTextColor.withAlpha(80),
          buttonForeground: blueTextColor,
          icon: Assets.omiExecutionInsight,
        );
    }
  }
}

/// Memory 详情列表中的 Insight 卡片（图标 + 分类 + 时间 + 正文 + Read more + Add follow-up todo）
class MPMemoryInsightCard extends StatelessWidget {
  const MPMemoryInsightCard({
    super.key,
    required this.data,
    this.onReadMore,
    this.onAddFollowUpTodo,
  });

  final MPMemoryInsightItemData data;

  /// 点击「Read more」
  final VoidCallback? onReadMore;

  /// 点击底部「+ Add follow-up todo」
  final VoidCallback? onAddFollowUpTodo;

  @override
  Widget build(BuildContext context) {
    final _MPInsightVisual v = _MPInsightVisual.of(data.tone);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: v.cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: v.iconBg.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: OmiImageLoader.localImg(
                      v.icon ?? '',
                      width: 16,
                      height: 16,
                      fit: BoxFit.contain,
                      color: v.iconBg
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data.resolvedCategoryTitle,
                    style: OmiTextStyle.create(
                      fontSize: OmiFontSize.t3_12,
                      fontWeight: OmiFontWeight.bold,
                      color: v.accent,
                      height: 1.25,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  data.timeLabel,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t2_11,
                    fontWeight: OmiFontWeight.regular,
                    color: secondTextColor,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.bodyText,
              style: OmiTextStyle.create(
                fontSize: OmiFontSize.t4_13,
                fontWeight: OmiFontWeight.regular,
                color: mainTextColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: onReadMore,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    'Read more',
                    style: OmiTextStyle.create(
                      fontSize: OmiFontSize.t4_13,
                      fontWeight: OmiFontWeight.medium,
                      color: v.accent,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: v.buttonBg,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: onAddFollowUpTodo,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      OmiImageLoader.localImg(
                        Assets.omiPlus,
                        width: 16,
                        height: 16,
                        color: v.buttonForeground,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Add follow-up todo',
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t4_13,
                          fontWeight: OmiFontWeight.medium,
                          color: v.buttonForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
