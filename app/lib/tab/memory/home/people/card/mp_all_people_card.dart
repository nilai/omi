import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

/// 「全部人物」单行：左姓名，右 `dateLabel · count`
class MPAllPeopleRowItem {
  const MPAllPeopleRowItem({
    required this.name,
    required this.dateLabel,
    required this.count,
  });

  final String name;

  /// 右侧日期文案，如 `Jan 21`、`Today`
  final String dateLabel;

  final int count;
}

/// 「ALL PEOPLE」数据（组件内按首字母 A–Z 分组，`#` 为非拉丁字符）
class MPAllPeopleCardData {
  const MPAllPeopleCardData({
    this.sectionTitle = 'ALL PEOPLE',
    required this.items,
  });

  final String sectionTitle;

  final List<MPAllPeopleRowItem> items;
}

/// 字母分组标题条背景（偏浅灰，接近白底）
const Color _kGroupHeaderBg = Color(0xFFF8F9FA);

/// 卡片描边（比 [borderColor] 更浅，弱对比）
const Color _kCardBorder = Color(0xFFF0F0EE);

/// People 页「全部人物」：区块标题 + 按字母分组的列表
class MPAllPeopleCard extends StatelessWidget {
  const MPAllPeopleCard({
    super.key,
    required this.data,
    this.onItemTap,
  });

  final MPAllPeopleCardData data;

  /// 点击某一行
  final void Function(MPAllPeopleRowItem item)? onItemTap;

  @override
  Widget build(BuildContext context) {
    if (data.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<({String letter, List<MPAllPeopleRowItem> rows})> groups =
        _groupByLetter(data.items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.sectionTitle.toUpperCase(),
          style: OmiTextStyle.create(
            fontSize: OmiFontSize.t3_12,
            fontWeight: OmiFontWeight.medium,
            color: secondTextColor,
            letterSpacing: 0.6,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: _kCardBorder, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildGroupChildren(groups),
            ),
          ),
        ),
      ],
    );
  }

  /// 按首字母分组并排序；组内按姓名忽略大小写排序
  static List<({String letter, List<MPAllPeopleRowItem> rows})> _groupByLetter(
    List<MPAllPeopleRowItem> items,
  ) {
    final Map<String, List<MPAllPeopleRowItem>> map =
        <String, List<MPAllPeopleRowItem>>{};
    for (final MPAllPeopleRowItem it in items) {
      final String key = _letterKey(it.name);
      map.putIfAbsent(key, () => <MPAllPeopleRowItem>[]).add(it);
    }
    for (final List<MPAllPeopleRowItem> list in map.values) {
      list.sort(
        (MPAllPeopleRowItem a, MPAllPeopleRowItem b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }
    final List<String> keys = map.keys.toList()..sort(_compareLetterKeys);
    return keys
        .map(
          (String k) =>
              (letter: k, rows: List<MPAllPeopleRowItem>.from(map[k]!)),
        )
        .toList();
  }

  static String _letterKey(String name) {
    final String t = name.trim();
    if (t.isEmpty) {
      return '#';
    }
    final String first = t.substring(0, 1).toUpperCase();
    if (RegExp(r'^[A-Z]$').hasMatch(first)) {
      return first;
    }
    return '#';
  }

  static int _compareLetterKeys(String a, String b) {
    if (a == b) {
      return 0;
    }
    if (a == '#') {
      return 1;
    }
    if (b == '#') {
      return -1;
    }
    return a.compareTo(b);
  }

  List<Widget> _buildGroupChildren(
    List<({String letter, List<MPAllPeopleRowItem> rows})> groups,
  ) {
    final List<Widget> out = <Widget>[];
    for (int g = 0; g < groups.length; g++) {
      final ({String letter, List<MPAllPeopleRowItem> rows}) group = groups[g];
      out.add(
        Container(
          width: double.infinity,
          color: _kGroupHeaderBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            group.letter,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t4_13,
              fontWeight: OmiFontWeight.medium,
              color: secondTextColor,
              height: 1.2,
            ),
          ),
        ),
      );
      out.add(
        Divider(
          height: 0.5,
          thickness: 1,
          color: lineColor,
        ),
      );
      for (int i = 0; i < group.rows.length; i++) {
        final MPAllPeopleRowItem row = group.rows[i];
        final bool isLastInGroup = i == group.rows.length - 1;
        out.add(
          Material(
            color: Colors.white,
            child: InkWell(
              onTap: onItemTap == null ? null : () => onItemTap!(row),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        row.name,
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t6_15,
                          fontWeight: OmiFontWeight.medium,
                          color: mainTextColor,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${row.dateLabel} · ${row.count}',
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t4_13,
                        fontWeight: OmiFontWeight.medium,
                        color: secondTextColor,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        if (!isLastInGroup) {
          out.add(
             Divider(
                height: 0.5,
                thickness: 1,
                color: lineColor,
              ),
          );
        }
      }
      if (g < groups.length - 1) {
        out.add(
          Divider(
            height: 0.5,
            thickness: 1,
            color: lineColor,
          ),
        );
      }
    }
    return out;
  }
}
