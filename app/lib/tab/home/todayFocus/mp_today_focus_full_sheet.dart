import 'package:flutter/material.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import 'cards/mp_today_focus_card.dart';

Future<void> showMPTodayFocusFullSheet(
  BuildContext context, {
  required List<MPTodayFocusCardItem> items,
  void Function(int replaceSlot, MPTodayFocusCardItem item)? onSelect,
}) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (BuildContext ctx) =>
        _MPTodayFocusFullDialog(items: items, onSelect: onSelect),
  );
}

class _MPTodayFocusFullDialog extends StatelessWidget {
  const _MPTodayFocusFullDialog({required this.items, this.onSelect});

  final List<MPTodayFocusCardItem> items;
  final void Function(int index, MPTodayFocusCardItem item)? onSelect;

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.sizeOf(context).width;
    final double maxW = w > 420 ? 420 : w;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "Today's Focus is full.",
                              style: OmiTextStyle.create(
                                fontSize: OmiFontSize.t7_16,
                                fontWeight: OmiFontWeight.medium,
                                color: mainTextColor,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Replace one priority?',
                              style: OmiTextStyle.create(
                                fontSize: OmiFontSize.t4_13,
                                fontWeight: OmiFontWeight.regular,
                                color: secondTextColor,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: secondTextColor.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List<Widget>.generate(
                    items.length.clamp(0, 3),
                    (int i) {
                      final MPTodayFocusCardItem it = items[i];
                      return Padding(
                        padding: EdgeInsets.only(bottom: i == 2 ? 0 : 12),
                        child: _FocusFullRow(
                          title: it.title,
                          onTap: onSelect == null
                              ? null
                              : () {
                                  Navigator.of(context).maybePop();
                                  onSelect?.call(it.slot ?? 0, it);
                                },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusFullRow extends StatelessWidget {
  const _FocusFullRow({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.star_border_rounded, size: 18, color: orangeTextColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title.trim().isEmpty ? '—' : title.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t5_14,
                    fontWeight: OmiFontWeight.medium,
                    color: mainTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

