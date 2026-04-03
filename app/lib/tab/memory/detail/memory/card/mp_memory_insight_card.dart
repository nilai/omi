import 'package:flutter/material.dart';
import 'package:omi/common/omi_add_todo_popup.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';

/// Insight 卡片配色主题（仅样式差异，与 [MPFeedCardType] 可对应或用于轮换）。
enum MPInsightCardTone {
  /// 暖橙
  business,

  /// 冷蓝
  execution,

  /// 紫色
  creative,

  /// 绿色
  wellness,

  /// 红色 / 强调
  strategic,

  /// 深绿
  growth,
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
      case MPInsightCardTone.creative:
        return 'CREATIVE INSIGHT';
      case MPInsightCardTone.wellness:
        return 'WELLNESS INSIGHT';
      case MPInsightCardTone.strategic:
        return 'STRATEGIC INSIGHT';
      case MPInsightCardTone.growth:
        return 'GROWTH INSIGHT';
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
      case MPInsightCardTone.creative:
        return _MPInsightVisual(
          cardBg: purpleTextColor.withAlpha(28),
          accent: purpleTextColor,
          iconBg: purpleTextColor,
          buttonBg: purpleTextColor.withAlpha(80),
          buttonForeground: purpleTextColor,
          icon: Assets.omiDetailMessage,
        );
      case MPInsightCardTone.wellness:
        return _MPInsightVisual(
          cardBg: greenTextColor.withAlpha(30),
          accent: greenTextColor,
          iconBg: greenTextColor,
          buttonBg: greenTextColor.withAlpha(80),
          buttonForeground: greenTextColor,
          icon: Assets.omiDetailPhone,
        );
      case MPInsightCardTone.strategic:
        return _MPInsightVisual(
          cardBg: redColor.withAlpha(26),
          accent: redColor,
          iconBg: redColor,
          buttonBg: redColor.withAlpha(80),
          buttonForeground: redColor,
          icon: Assets.omiDetailEdit,
        );
      case MPInsightCardTone.growth:
        return _MPInsightVisual(
          cardBg: greenDeepColor.withAlpha(28),
          accent: greenDeepColor,
          iconBg: greenDeepColor,
          buttonBg: greenDeepColor.withAlpha(80),
          buttonForeground: greenDeepColor,
          icon: Assets.omiDetailCheck,
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

  /// 从正文提取 Todo 预填标题，避免过长内容直接进入输入框。
  String _buildInitialTodoTitle() {
    final String text = data.bodyText.trim();
    if (text.isEmpty) {
      return 'Follow up on insight';
    }
    final int maxLen = 64;
    if (text.length <= maxLen) {
      return text;
    }
    return '${text.substring(0, maxLen).trimRight()}...';
  }

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
                onTap: () async {
                  final MPAddTodoPopupResult? result = await showMPAddTodoPopup(
                    context,
                    params: MPAddTodoPopupParams(
                      initialTitle: _buildInitialTodoTitle(),
                    ),
                  );
                  if (result != null) {
                    onAddFollowUpTodo?.call();
                  }
                },
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
