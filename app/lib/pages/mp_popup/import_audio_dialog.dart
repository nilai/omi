import 'package:flutter/material.dart';

/// 音频导入选项弹窗
/// 提供三种导入方式：从文件导入、从相册导入、从其他App导入
class ImportAudioDialog extends StatelessWidget {
  final VoidCallback? onImportFromFile;
  final VoidCallback? onImportFromAlbum;
  final VoidCallback? onImportFromOtherApp;
  final VoidCallback? onClose;

  const ImportAudioDialog({
    super.key,
    this.onImportFromFile,
    this.onImportFromAlbum,
    this.onImportFromOtherApp,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            _buildHeader(context),
            
            // 导入选项
            _buildImportOptions(),
            
            // 取消按钮
            _buildCancelButton(context),
          ],
        ),
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '导入音频',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: onClose ?? () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建导入选项
  Widget _buildImportOptions() {
    return Column(
      children: [
        // 从文件导入
        _buildImportOption(
          icon: Icons.insert_drive_file_outlined,
          title: '从文件导入',
          subtitle: '从本地存储选择音频文件',
          onTap: onImportFromFile,
        ),
        
        // 分割线
        Container(
          height: 1,
          color: const Color(0xFF2C2C2E),
          margin: const EdgeInsets.symmetric(horizontal: 20),
        ),
        
        // 从相册导入
        _buildImportOption(
          icon: Icons.photo_library_outlined,
          title: '从相册导入',
          subtitle: '从照片库选择音频文件',
          onTap: onImportFromAlbum,
        ),
        
        // 分割线
        Container(
          height: 1,
          color: const Color(0xFF2C2C2E),
          margin: const EdgeInsets.symmetric(horizontal: 20),
        ),
        
        // 从其他App导入
        _buildImportOption(
          icon: Icons.apps_outlined,
          title: '从其他App导入',
          subtitle: '通过系统分享导入音频',
          onTap: onImportFromOtherApp,
        ),
      ],
    );
  }

  /// 构建单个导入选项
  Widget _buildImportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          children: [
            // 图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF8E8E93),
                size: 20,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // 文字内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
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
    );
  }

  /// 构建取消按钮
  Widget _buildCancelButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: GestureDetector(
        onTap: onClose ?? () => Navigator.of(context).pop(),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              '取消',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
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
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return ImportAudioDialog(
          onImportFromFile: onImportFromFile,
          onImportFromAlbum: onImportFromAlbum,
          onImportFromOtherApp: onImportFromOtherApp,
          onClose: onClose ?? () => Navigator.of(context).pop(),
        );
      },
    );
  }
}