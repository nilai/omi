import 'package:flutter/material.dart';

import '../../../../backend/http/mp_api/mp_memory.dart';
import '../../../../backend/schema/mp/mp_memory.dart';
import '../../../../services/mp_home_refresh_event_service.dart';
import '../../mp_custom_utils/mp_toast_utils.dart';

/// 新增记忆标签
/// 用于新增记忆标签
class MPMemoryAddTagDialog extends StatefulWidget {
  final String memoryId;
  final int maxLength;

  final Function(String title)? onSuccess;

  const MPMemoryAddTagDialog({
    super.key,
    required this.memoryId,
    this.maxLength = 100,
    this.onSuccess,
  });

  /// 显示新增记忆标签对话框
  static void show({
    required BuildContext context,
    required String memoryId,
    int maxLength = 100,
    Function(String title)? onSuccess,
  }) {
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => MPMemoryAddTagDialog(
        memoryId: memoryId,
        maxLength: maxLength,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<MPMemoryAddTagDialog> createState() => _MPMemoryAddTagDialogState();
}

class _MPMemoryAddTagDialogState extends State<MPMemoryAddTagDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newTitle = _controller.text.trim();

    // 验证输入
    if (newTitle.isEmpty) {
      MPToastUtils.showMessage('新增标签不能为空');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final req = MPMemoryAddTagRequest(
        memoryId: widget.memoryId,
        label: newTitle,
      );
      final res = await memoryAddTag(req);
      if (res != null && res.baseResp.code == 0) {
        MPHomeRefreshEventService().emitRefresh();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
        widget.onSuccess?.call(newTitle);
      } else {
        MPToastUtils.showMessage(res?.baseResp.message ?? '保存失败');
      }
    } catch (e) {
      MPToastUtils.showMessage('保存失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleCancel() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final currentLength = _controller.text.length;
    final isMaxLengthReached = currentLength >= widget.maxLength;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '新增记忆标签',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFF6B7280),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _isLoading ? null : _handleCancel,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 输入框
            TextField(
              controller: _controller,
              enabled: !_isLoading,
              maxLength: widget.maxLength,
              autofocus: true,
              cursorColor: Colors.black,
              decoration: InputDecoration(
                hintText: '请输入自定义标签',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 16,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                counterText: '',
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            // 字符计数
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$currentLength/${widget.maxLength}',
                style: TextStyle(
                  fontSize: 12,
                  color: isMaxLengthReached ? const Color(0xFFDC2626) : const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 操作按钮
            Row(
              children: [
                // 取消按钮
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1F2937),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 保存按钮
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoading ? const Color(0xFF9CA3AF) : Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '保存',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
