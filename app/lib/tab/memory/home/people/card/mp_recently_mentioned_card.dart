import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

/// 单条「最近提及」人物行数据
class MPRecentlyMentionedPersonItem {
  /// [name] 展示名；[lastTalkedPhrase] 如 `today` / `yesterday`；[memoryCount] 关联记忆条数
  const MPRecentlyMentionedPersonItem({
    required this.name,
    required this.lastTalkedPhrase,
    required this.memoryCount,
  });

  final String name;

  /// 时间片段文案，拼入 `Last talked …`（如 `today`、`yesterday`）
  final String lastTalkedPhrase;

  final int memoryCount;

  /// `Last talked today · 3 memories`（1 条时用 `memory`）
  String get subtitleLine {
    final String unit = memoryCount == 1 ? 'memory' : 'memories';
    return 'Last talked $lastTalkedPhrase · $memoryCount $unit';
  }
}

/// 「RECENTLY MENTIONED」区块数据
class MPRecentlyMentionedCardData {
  const MPRecentlyMentionedCardData({
    this.sectionTitle = 'RECENTLY MENTIONED',
    required this.items,
  });

  /// 区块标题（大写展示）
  final String sectionTitle;

  final List<MPRecentlyMentionedPersonItem> items;
}

const Color _kSectionTitle = Color(0xFF9E9E9E);
const Color _kCardBorder = Color(0xFFE8E8E6);

/// People 页「最近提及」卡片：区块标题 + 白底圆角列表
class MPRecentlyMentionedCard extends StatelessWidget {
  const MPRecentlyMentionedCard({
    super.key,
    required this.data,
    this.onItemTap,
  });

  final MPRecentlyMentionedCardData data;

  /// 点击某一行，`index` 为 [MPRecentlyMentionedCardData.items] 下标
  final void Function(int index, MPRecentlyMentionedPersonItem item)? onItemTap;

  @override
  Widget build(BuildContext context) {
    if (data.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.sectionTitle.toUpperCase(),
          style: OmiTextStyle.create(
            fontSize: OmiFontSize.t3_12,
            fontWeight: OmiFontWeight.medium,
            color: _kSectionTitle,
            letterSpacing: 0.6,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kCardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List<Widget>.generate(data.items.length, (int i) {
              final MPRecentlyMentionedPersonItem item = data.items[i];
              final bool isLast = i == data.items.length - 1;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onItemTap == null
                      ? null
                      : () => onItemTap!(i, item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: OmiTextStyle.create(
                                fontSize: OmiFontSize.t6_15,
                                fontWeight: OmiFontWeight.medium,
                                color: mainTextColor,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitleLine,
                              style: OmiTextStyle.create(
                                fontSize: OmiFontSize.t3_12,
                                fontWeight: OmiFontWeight.medium,
                                color: secondTextColor,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: lineColor.withValues(alpha: 0.85),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
