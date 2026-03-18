// AI-generated START - 记忆导出对话框
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 导出类型枚举
enum MPMemoryExportType {
  /// 导出音频
  audio,

  /// 导出 PDF
  pdf,

  /// 导出 DOCX
  docx,
}

/// 记忆导出对话框
/// 提供音频、PDF、DOCX 三种导出选项
class MPMemoryExportDialog {
  /// 显示导出对话框
  ///
  /// [context] 上下文
  /// [onExportSelected] 导出类型选择回调
  static Future<void> show({
    required BuildContext context,
    required void Function(MPMemoryExportType) onExportSelected,
  }) async {
    HapticFeedback.mediumImpact();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _MPMemoryExportDialogContent(
          onExportSelected: onExportSelected,
        );
      },
    );
  }
}

/// 导出对话框内容组件
class _MPMemoryExportDialogContent extends StatelessWidget {
  final void Function(MPMemoryExportType) onExportSelected;

  const _MPMemoryExportDialogContent({
    required this.onExportSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Text(
                    '导出为',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // 导出选项
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 导出音频
                  _ExportOptionCard(
                    title: '导出音频',
                    icon: Icons.audiotrack,
                    iconBackgroundColor: const Color(0xFF9333EA), // 紫色
                    onTap: () {
                      Navigator.of(context).pop();
                      onExportSelected(MPMemoryExportType.audio);
                    },
                  ),

                  const SizedBox(height: 12),

                  // 导出 PDF
                  _ExportOptionCard(
                    title: '导出 PDF',
                    icon: Icons.picture_as_pdf,
                    iconBackgroundColor: const Color(0xFFEA580C), // 橙色
                    onTap: () {
                      Navigator.of(context).pop();
                      onExportSelected(MPMemoryExportType.pdf);
                    },
                  ),

                  const SizedBox(height: 12),

                  // 导出 DOCX
                  _ExportOptionCard(
                    title: '导出 DOCX',
                    icon: Icons.description,
                    iconBackgroundColor: const Color(0xFF2563EB), // 蓝色
                    onTap: () {
                      Navigator.of(context).pop();
                      onExportSelected(MPMemoryExportType.docx);
                    },
                  ),
                ],
              ),
            ),

            // 取消按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    '取消',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212121),
                    ),
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

/// 导出选项卡片组件
class _ExportOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconBackgroundColor;
  final VoidCallback onTap;

  const _ExportOptionCard({
    required this.title,
    required this.icon,
    required this.iconBackgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 图标容器
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // 标题
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF212121),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // 箭头图标
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
// AI-generated END - mp_memory_export_dialog.dart
