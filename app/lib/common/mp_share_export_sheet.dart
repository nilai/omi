import 'package:flutter/material.dart';
import 'package:memo_pin/common/mp_dismissible_modal_backdrop.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

/// 分享导出弹窗的导出方式。
enum MPShareExportKind { link, image, pdf, word, markdown, systemShare }

/// 分享导出弹窗参数。
class MPShareExportSheetParams {
  const MPShareExportSheetParams({
    this.title = 'Share this Memory',
    this.subtitle = 'Export or send it in the format you prefer.',
    this.cancelText = 'Cancel',
  });

  final String title;
  final String subtitle;
  final String cancelText;
}

/// 打开「Share this Memory」导出方式弹窗。
Future<MPShareExportKind?> showMPShareExportSheet(
  BuildContext context, {
  MPShareExportSheetParams params = const MPShareExportSheetParams(),
}) {
  return showModalBottomSheet<MPShareExportKind>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (BuildContext sheetContext) {
      return _MPShareExportSheet(params: params);
    },
  );
}

class _MPShareExportSheet extends StatelessWidget {
  const _MPShareExportSheet({required this.params});

  final MPShareExportSheetParams params;

  static const Color _kSheetBg = Color(0xFFF2F2F7);

  @override
  Widget build(BuildContext context) {
    final double bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final List<_MPExportTileData> tiles = <_MPExportTileData>[
      _MPExportTileData(
        kind: MPShareExportKind.link,
        label: 'Link',
        icon: Icons.language_rounded,
        iconColor: blueTextColor,
      ),
      _MPExportTileData(
        kind: MPShareExportKind.image,
        label: 'Image',
        icon: Icons.image_outlined,
        iconColor: blueTextColor,
      ),
      _MPExportTileData(
        kind: MPShareExportKind.pdf,
        label: 'PDF',
        icon: Icons.picture_as_pdf_outlined,
        iconColor: blueTextColor,
      ),
      _MPExportTileData(
        kind: MPShareExportKind.word,
        label: 'Word',
        icon: Icons.description_outlined,
        iconColor: blueTextColor,
      ),
      _MPExportTileData(
        kind: MPShareExportKind.markdown,
        label: 'Markdown',
        icon: Icons.article_outlined,
        iconColor: const Color(0xFF34C759),
      ),
      _MPExportTileData(
        kind: MPShareExportKind.systemShare,
        label: 'Share',
        icon: Icons.share_outlined,
        iconColor: blueTextColor,
      ),
    ];

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: MPDismissibleModalBackdrop(
        child: Container(
          decoration: const BoxDecoration(
            color: _kSheetBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomSafe),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D1D6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      params.title,
                      textAlign: TextAlign.center,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t6_15,
                        fontWeight: OmiFontWeight.medium,
                        color: mainTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      params.subtitle,
                      textAlign: TextAlign.center,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t4_13,
                        fontWeight: OmiFontWeight.regular,
                        color: secondTextColor,
                      ),
                    ),
                    const SizedBox(height: 18),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      childAspectRatio: 0.74,
                      children: tiles.map((_MPExportTileData tile) {
                        return _MPExportTile(data: tile);
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: blueTextColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          params.cancelText,
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t7_16,
                            fontWeight: OmiFontWeight.medium,
                            color: blueTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

class _MPExportTileData {
  const _MPExportTileData({
    required this.kind,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  final MPShareExportKind kind;
  final String label;
  final IconData icon;
  final Color iconColor;
}

class _MPExportTile extends StatelessWidget {
  const _MPExportTile({required this.data});

  final _MPExportTileData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.of(context).pop(data.kind),
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(data.icon, size: 26, color: data.iconColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.label,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t3_12,
              fontWeight: OmiFontWeight.regular,
              color: mainTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
