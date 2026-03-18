// AI-generated START - 删除记忆确认对话框
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';

/// 删除记忆确认对话框
/// 显示删除记忆的确认弹窗，包含图标、标题、消息和操作按钮
class MPDeleteMemoryDialog extends StatelessWidget {
  const MPDeleteMemoryDialog({
    super.key,
    this.onCancel,
    this.onConfirm,
  });

  /// 取消回调
  final VoidCallback? onCancel;

  /// 确认删除回调
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 删除图标
            _buildDeleteIcon(),
            const SizedBox(height: 20.0),
            // 标题
            _buildTitle(),
            const SizedBox(height: 10.0),
            // 消息内容
            _buildMessage(),
            const SizedBox(height: 20.0),
            // 操作按钮
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// 构建删除图标
  Widget _buildDeleteIcon() {
    return Assets.images.mpMyVoiceDelete.image(width: 56.0, height: 56.0, fit: BoxFit.contain);
  }

  /// 构建标题
  Widget _buildTitle() {
    return const Text(
      '确认删除',
      style: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  /// 构建消息内容
  Widget _buildMessage() {
    return Text(
      '确定要删除这条记录吗？',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14.0,
        color: Colors.grey.shade700,
        height: 1.5,
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // 取消按钮
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel?.call();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              backgroundColor: Color(0xFFF3F4F6),
              foregroundColor: Colors.grey.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 0,
            ),
            child: const Text(
              '取消',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        // 删除按钮
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              backgroundColor: Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 0,
            ),
            child: const Text(
              '删除',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 显示删除确认对话框
  static Future<bool?> show({
    required BuildContext context,
    VoidCallback? onCancel,
    VoidCallback? onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MPDeleteMemoryDialog(
        onCancel: onCancel,
        onConfirm: onConfirm,
      ),
    );
  }
}
// AI-generated END - mp_delete_memory_dialog.dart
