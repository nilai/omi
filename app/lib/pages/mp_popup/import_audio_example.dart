import 'package:flutter/material.dart';
import 'package:omi/pages/mp_popup/import_audio_dialog.dart';

/// 音频导入弹窗使用示例页面
class ImportAudioExamplePage extends StatelessWidget {
  const ImportAudioExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '导入音频示例',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _showImportDialog(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            '显示导入弹窗',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// 显示导入弹窗
  void _showImportDialog(BuildContext context) {
    ImportAudioDialog.show(
      context: context,
      onImportFromFile: () {
        Navigator.of(context).pop();
        // TODO: 实现从文件导入的逻辑
        _showResultToast(context, '从文件导入');
      },
      onImportFromAlbum: () {
        Navigator.of(context).pop();
        // TODO: 实现从相册导入的逻辑
        _showResultToast(context, '从相册导入');
      },
      onImportFromOtherApp: () {
        Navigator.of(context).pop();
        // TODO: 实现从其他App导入的逻辑
        _showResultToast(context, '从其他App导入');
      },
    );
  }

  /// 显示结果提示
  void _showResultToast(BuildContext context, String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('选择了: $method'),
        backgroundColor: const Color(0xFF007AFF),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}