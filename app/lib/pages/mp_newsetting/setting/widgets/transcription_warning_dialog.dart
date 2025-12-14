// AI-generated START - 转写模式警告提示弹窗
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';
import 'package:omi/pages/mp_newsetting/home/providers/settings_provider.dart';
import 'package:omi/pages/mp_newsetting/setting/widgets/transcription_mode_dialog.dart';

/// 转写模式警告提示弹窗
/// 当用户选择"默认立即转写"时显示，提示会消耗订阅计划中的转写时长
class TranscriptionWarningDialog {
  /// 显示转写模式警告提示弹窗
  ///
  /// [context] - BuildContext
  /// [selectedMode] - 选中的转写模式
  /// [settingsProvider] - SettingsProvider 实例
  /// [onModeSelected] - 模式选择回调
  /// [onCancel] - 取消回调
  static Future<void> show(
    BuildContext context, {
    required TranscriptionMode selectedMode,
    required SettingsProvider settingsProvider,
    required Function(TranscriptionMode mode) onModeSelected,
    VoidCallback? onCancel,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _TranscriptionWarningDialogContent(
          selectedMode: selectedMode,
          settingsProvider: settingsProvider,
          onModeSelected: onModeSelected,
          onCancel: () {
            Navigator.of(dialogContext).pop();
            onCancel?.call();
          },
          onConfirm: () async {
            // 确认操作，先保存设置到服务器
            final confirmMode = selectedMode == TranscriptionMode.confirm;
            final success = await settingsProvider.saveTranscriptionMode(confirmMode);
            // 关闭弹窗
            Navigator.of(dialogContext).pop();
            // 使用 Future.microtask 延迟执行回调，确保弹窗完全关闭后再执行
            Future.microtask(() {
              if (success) {
                onModeSelected(selectedMode);
              }
            });
          },
        );
      },
    );
  }
}

class _TranscriptionWarningDialogContent extends StatelessWidget {
  final TranscriptionMode selectedMode;
  final SettingsProvider settingsProvider;
  final Function(TranscriptionMode mode) onModeSelected;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _TranscriptionWarningDialogContent({
    required this.selectedMode,
    required this.settingsProvider,
    required this.onModeSelected,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI-generated START - 图标
            const SizedBox(height: 32.0),
            Assets.images.mpVoiceTipIcon.image(
              width: 56.0,
              height: 56.0,
              fit: BoxFit.contain,
            ),
            // AI-generated END - 图标

            const SizedBox(height: 12.0),

            // AI-generated START - 标题
            const Text(
              '提示',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            // AI-generated END - 标题

            const SizedBox(height: 12.0),

            // AI-generated START - 消息内容
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                '默认立即转写会消耗您订阅计划中的转写时长,\n如果选择此选项建议您订阅Unlimited计划',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),
            // AI-generated END - 消息内容

            const SizedBox(height: 24.0),

            // AI-generated START - 操作按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
              child: Row(
                children: [
                  // 取消按钮
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onCancel,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        backgroundColor: const Color(0xFFF3F4F6),
                        foregroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  // 确认按钮
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '确认',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // AI-generated END - 操作按钮
          ],
        ),
      ),
    );
  }
}
// AI-generated END - transcription_warning_dialog.dart
