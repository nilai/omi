import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

/// Memory 页顶部分段：All / People / Projects
class MPMemoryTopTabs extends StatelessWidget {
  const MPMemoryTopTabs({
    super.key,
    required this.index,
    required this.onChanged,
  });

  /// 当前选中下标 0..2
  final int index;

  final ValueChanged<int> onChanged;

  static const List<_TabItem> _items = <_TabItem>[
    _TabItem(label: 'All', icon: Icons.list_rounded),
    _TabItem(label: 'People', icon: Icons.person_outline_rounded),
    _TabItem(label: 'Projects', icon: Icons.folder_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: List<Widget>.generate(_items.length, (int i) {
          final _TabItem item = _items[i];
          final bool selected = index == i;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: i < _items.length - 1 ? 10 : 0,
              ),
              child: _SegmentButton(
                label: item.label,
                icon: item.icon,
                selected: selected,
                onTap: () => onChanged(i),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? blueTextColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? blueTextColor : borderColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : mainTextColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t6_15,
                  fontWeight: OmiFontWeight.medium,
                  color: selected ? Colors.white : mainTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
