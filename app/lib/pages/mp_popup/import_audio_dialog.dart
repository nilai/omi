import 'dart:io';

import 'package:flutter/material.dart';

/// 音频导入选项弹窗
/// 提供三种导入方式：从文件导入、从相册导入、从其他App导入
class ImportAudioDialog extends StatelessWidget {
  final VoidCallback? onImportFromFile;
  final VoidCallback? onImportFromAlbum;
  final VoidCallback? onImportFromOtherApp;
  final VoidCallback? onClose;
  final bool autoClose;

  const ImportAudioDialog({
    super.key,
    this.onImportFromFile,
    this.onImportFromAlbum,
    this.onImportFromOtherApp,
    this.onClose,
    this.autoClose = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F2F7),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                children: [
                  // 标题栏
                  _buildHeader(context),

                  // 导入选项
                  _buildImportOptions(),

                  // 底部描述
                  _buildDescription(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '导入音频',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
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
              child: const Icon(
                Icons.close,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建导入选项
  /// Android: 只显示"从文件导入"
  /// iOS: 显示三个选项（从文件导入、从相册导入、从其他App导入）
  Widget _buildImportOptions() {
    final List<Widget> options = [];

    // 从文件导入（所有平台都显示）
    options.add(
      _buildImportOption(
        icon: Icons.insert_drive_file_outlined,
        title: '从文件导入',
        onTap: () {
          if (autoClose) {
            onClose?.call();
          }
          onImportFromFile?.call();
        },
        iconBackgroundColor: const Color(0xFF007AFF),
        iconColor: Colors.white,
      ),
    );

    // iOS 平台显示额外选项
    if (Platform.isIOS) {
      // 从相册导入
      options.add(
        _buildImportOption(
          icon: Icons.photo_library_outlined,
          title: '从相册导入',
          onTap: () {
            if (autoClose) {
              onClose?.call();
            }
            onImportFromAlbum?.call();
          },
          iconBackgroundColor: const Color(0xFFAF52DE),
          iconColor: Colors.white,
        ),
      );

      // 从其他App导入
      options.add(
        _buildImportOption(
          icon: Icons.apps_outlined,
          title: '从其他App导入',
          onTap: () {
            if (autoClose) {
              onClose?.call();
            }
            onImportFromOtherApp?.call();
          },
          iconBackgroundColor: const Color(0xFF34C759),
          iconColor: Colors.white,
        ),
      );
    }

    return Column(
      children: options,
    );
  }

  /// 构建单个导入选项
  Widget _buildImportOption({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    required Color iconBackgroundColor,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            spreadRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              // 图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 16),

              // 文字内容
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),

              // 箭头图标
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF8E8E93),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建底部描述
  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: const Text(
        '支持导入单文件时长不超过5小时的音频',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF8E8E93),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 显示弹窗的静态方法
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
      builder: (context) {
        return ImportAudioDialog(
          onImportFromFile: onImportFromFile,
          onImportFromAlbum: onImportFromAlbum,
          onImportFromOtherApp: onImportFromOtherApp,
          onClose: onClose ?? () => Navigator.of(context).pop(),
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
