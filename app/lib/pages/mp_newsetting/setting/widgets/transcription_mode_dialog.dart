// AI-generated START - 录音后转写选择弹窗组件
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';
import 'package:omi/pages/mp_newsetting/home/providers/settings_provider.dart';
import 'package:omi/pages/mp_newsetting/setting/widgets/transcription_warning_dialog.dart';
import 'package:provider/provider.dart';

/// 转写模式选项
enum TranscriptionMode {
  immediate, // 默认立即转写
  confirm, // 确认后转写
}

/// 录音后转写选择弹窗
class TranscriptionModeDialog {
  /// 显示录音后转写选择弹窗
  ///
  /// [context] - BuildContext
  /// [currentMode] - 当前选中的模式，默认为立即转写
  /// [onModeSelected] - 模式选择回调，参数为选中的模式
  static Future<void> show(
    BuildContext context, {
    TranscriptionMode? currentMode,
    Function(TranscriptionMode mode)? onModeSelected,
  }) async {
    // 从 Provider 获取当前模式
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final selectedMode = currentMode ??
        (settingsProvider.transcriptionConfirmMode ? TranscriptionMode.confirm : TranscriptionMode.immediate);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _TranscriptionModeDialogContent(
          selectedMode: selectedMode,
          onModeSelected: (mode) {
            Navigator.of(dialogContext).pop();
            if (onModeSelected != null) {
              onModeSelected(mode);
            }
          },
        );
      },
    );
  }
}

class _TranscriptionModeDialogContent extends StatefulWidget {
  final TranscriptionMode selectedMode;
  final Function(TranscriptionMode mode) onModeSelected;

  const _TranscriptionModeDialogContent({
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  State<_TranscriptionModeDialogContent> createState() => _TranscriptionModeDialogContentState();
}

class _TranscriptionModeDialogContentState extends State<_TranscriptionModeDialogContent> {
  late TranscriptionMode _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.selectedMode;
  }

  void _selectMode(TranscriptionMode mode) {
    setState(() {
      _selectedMode = mode;
    });
  }

  void _confirm() {
    // 在关闭弹窗之前，先获取 Provider 引用和回调，避免 context 失效
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final selectedMode = _selectedMode;
    final onModeSelected = widget.onModeSelected;

    // 如果选择的是"默认立即转写"，显示警告提示弹窗
    if (_selectedMode == TranscriptionMode.immediate) {
      Navigator.of(context).pop();
      // 使用 Future.microtask 确保第一个弹窗完全关闭后再显示第二个弹窗
      Future.microtask(() {
        if (mounted) {
          TranscriptionWarningDialog.show(
            context,
            selectedMode: selectedMode,
            settingsProvider: settingsProvider,
            onModeSelected: onModeSelected,
          );
        }
      });
    } else {
      // 选择"确认后转写"，直接保存到服务器
      Navigator.of(context).pop();
      final confirmMode = selectedMode == TranscriptionMode.confirm;
      settingsProvider.saveTranscriptionMode(confirmMode).then((success) {
        if (success) {
          // 使用 Future.microtask 延迟执行回调，确保弹窗完全关闭后再执行
          Future.microtask(() {
            onModeSelected(selectedMode);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI-generated START - 标题栏
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '录音后转写',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Image.asset(Assets.images.mpVoiceDialogClose.path,
                        width: 32.0, height: 32.0, fit: BoxFit.cover),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // AI-generated END - 标题栏

            Container(
              margin: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 0.0),
              height: 1.0,
              color: Colors.grey.shade200,
            ),

            const SizedBox(height: 16.0),
            // AI-generated START - 选项列表
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // 默认立即转写选项
                  _buildOption(
                    title: '默认立即转写',
                    description: '录音完成后自动开始转写',
                    mode: TranscriptionMode.immediate,
                  ),
                  const SizedBox(height: 12.0),
                  // 确认后转写选项
                  _buildOption(
                    title: '确认后转写',
                    description: '需要手动确认后才开始转写',
                    mode: TranscriptionMode.confirm,
                  ),
                ],
              ),
            ),
            // AI-generated END - 选项列表

            const SizedBox(height: 24.0),

            // AI-generated START - 确认按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    backgroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '确认',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            // AI-generated END - 确认按钮
          ],
        ),
      ),
    );
  }

  /// 构建选项
  Widget _buildOption({
    required String title,
    required String description,
    required TranscriptionMode mode,
  }) {
    final isSelected = _selectedMode == mode;

    return InkWell(
      onTap: () => _selectMode(mode),
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCCFBF1) : Colors.grey.shade100, // 选中时浅青色，未选中时浅灰色
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // 选中标记（右上角）
            if (isSelected)
              Image.asset(Assets.images.mpTranscriptionCheck.path, width: 24.0, height: 24.0, fit: BoxFit.cover),
          ],
        ),
      ),
    );
  }
}
// AI-generated END - transcription_mode_dialog.dart
