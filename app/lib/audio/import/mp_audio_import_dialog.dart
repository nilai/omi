import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';

/// 导入音频底部弹窗：从文件 / 相册（iOS）/ 其他 App（占位）。
class MPAudioImportDialog extends StatelessWidget {
  const MPAudioImportDialog({
    super.key,
    this.onImportFromFile,
    this.onImportFromAlbum,
    this.onImportFromOtherApp,
    this.onClose,
    this.autoClose = true,
  });

  final VoidCallback? onImportFromFile;

  final VoidCallback? onImportFromAlbum;

  final VoidCallback? onImportFromOtherApp;

  final VoidCallback? onClose;

  final bool autoClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: pageColor,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F7),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildHeader(context),
                  _buildImportOptions(context),
                  _buildDescription(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            '导入音频',
            style: TextStyle(
              fontSize: OmiFontSize.t9_18,
              fontWeight: OmiFontWeight.medium,
              color: mainTextColor,
            ),
          ),
          GestureDetector(
            onTap: onClose ?? () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.close, color: mainTextColor, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportOptions(BuildContext context) {
    final List<Widget> options = <Widget>[
      _buildImportOption(
        context: context,
        icon: Icons.insert_drive_file_outlined,
        title: '从文件导入',
        onTap: () {
          if (autoClose) {
            (onClose ?? () => Navigator.of(context).pop()).call();
          }
          onImportFromFile?.call();
        },
        iconBackgroundColor: blueTextColor,
        iconColor: Colors.white,
      ),
    ];

    if (Platform.isIOS) {
      options.add(
        _buildImportOption(
          context: context,
          icon: Icons.photo_library_outlined,
          title: '从相册导入',
          onTap: () {
            if (autoClose) {
              (onClose ?? () => Navigator.of(context).pop()).call();
            }
            onImportFromAlbum?.call();
          },
          iconBackgroundColor: const Color(0xFFAF52DE),
          iconColor: Colors.white,
        ),
      );
      options.add(
        _buildImportOption(
          context: context,
          icon: Icons.apps_outlined,
          title: '从其他App导入',
          onTap: () {
            if (autoClose) {
              (onClose ?? () => Navigator.of(context).pop()).call();
            }
            onImportFromOtherApp?.call();
          },
          iconBackgroundColor: greenTextColor,
          iconColor: Colors.white,
        ),
      );
    }

    return Column(children: options);
  }

  Widget _buildImportOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color iconBackgroundColor,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            spreadRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: OmiFontSize.t7_16,
                      fontWeight: OmiFontWeight.medium,
                      color: mainTextColor,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: secondTextColor, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Text(
        '支持导入单文件时长不超过5小时的音频',
        style: TextStyle(
          fontSize: OmiFontSize.t6_15,
          color: secondTextColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 显示底部弹窗。
  static Future<T?> show<T>({
    required BuildContext context,
    VoidCallback? onImportFromFile,
    VoidCallback? onImportFromAlbum,
    VoidCallback? onImportFromOtherApp,
    VoidCallback? onClose,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return MPAudioImportDialog(
          onImportFromFile: onImportFromFile,
          onImportFromAlbum: onImportFromAlbum,
          onImportFromOtherApp: onImportFromOtherApp,
          onClose: onClose ?? () => Navigator.of(sheetContext).pop(),
        );
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
    );
  }
}
