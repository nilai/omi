import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

/// 「Today's Focus」单条数据
class MPTodayFocusCardItem {
  const MPTodayFocusCardItem({
    required this.title,
    required this.subtext,
    required this.timeLabel,
  });

  final String title;
  final String subtext;
  final String timeLabel;
}

/// 「Today's Focus」整卡数据
class MPTodayFocusCardData {
  const MPTodayFocusCardData({
    this.headerTitle = "Today's Focus",
    required this.items,
  });

  final String headerTitle;
  final List<MPTodayFocusCardItem> items;

  MPTodayFocusCardData copyWith({
    String? headerTitle,
    List<MPTodayFocusCardItem>? items,
  }) {
    return MPTodayFocusCardData(
      headerTitle: headerTitle ?? this.headerTitle,
      items: items ?? this.items,
    );
  }
}

/// 浅绿底圆角卡片：标题 + 星标列表（标题 / → 副文案 / 右侧时间）
class MPTodayFocusCard extends StatelessWidget {
  const MPTodayFocusCard({
    super.key,
    required this.data,
    this.onItemTap,
  });

  final MPTodayFocusCardData data;
  final void Function(int index, MPTodayFocusCardItem item)? onItemTap;

  static const Color _kCardBg = Color(0xFFF4F9F7);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            data.headerTitle,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t8_17,
              fontWeight: OmiFontWeight.bold,
              color: mainTextColor,
            ),
          ),
          if (data.items.isNotEmpty) const SizedBox(height: 16),
          ...List<Widget>.generate(data.items.length, (int index) {
            final MPTodayFocusCardItem item = data.items[index];
            final Widget row = _MPTodayFocusItemRow(item: item);
            final Widget content = onItemTap == null
                ? row
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onItemTap!(index, item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: row,
                      ),
                    ),
                  );
            if (index == 0) {
              return content;
            }
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: content,
            );
          }),
        ],
      ),
    );
  }
}

class _MPTodayFocusItemRow extends StatelessWidget {
  const _MPTodayFocusItemRow({required this.item});

  final MPTodayFocusCardItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.star_border_rounded,
            size: 22,
            color: orangeTextColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.title,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t6_15,
                  fontWeight: OmiFontWeight.bold,
                  color: mainTextColor,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '→ ${item.subtext}',
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t5_14,
                  fontWeight: OmiFontWeight.regular,
                  color: secondTextColor,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          item.timeLabel,
          style: OmiTextStyle.create(
            fontSize: OmiFontSize.t5_14,
            fontWeight: OmiFontWeight.regular,
            color: secondTextColor,
          ),
        ),
      ],
    );
  }
}
