import 'package:flutter/material.dart';
import 'package:omi/pages/mp_custom_utils/mp_toast_utils.dart';
import 'package:omi/pages/mp_popup/mp_center_popup.dart';
import 'package:provider/provider.dart';

import 'providers/mp_audio_record_provider.dart';

/// 音频录制页面
class MPAudioRecordPage extends StatefulWidget {
  final Function(String) onSave;

  const MPAudioRecordPage({super.key, required this.onSave});

  @override
  State<MPAudioRecordPage> createState() => _MPAudioRecordPageState();
}

class _MPAudioRecordPageState extends State<MPAudioRecordPage> {
  late final MPAudioRecordProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = MPAudioRecordProvider();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<MPAudioRecordProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  // 顶部标题区域
                  _buildTitleSection(context, provider),
                  const SizedBox(height: 40),
                  // 中间麦克风图标区域
                  _buildMicrophoneSection(context, provider),
                  const SizedBox(height: 24),
                  // 时长显示
                  _buildDurationSection(context, provider),
                  const SizedBox(height: 8),
                  // 状态文本
                  _buildStatusSection(context, provider),
                  const Spacer(),
                  // 底部按钮区域
                  _buildBottomButtons(context, provider),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 构建标题区域
  Widget _buildTitleSection(BuildContext context, MPAudioRecordProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            provider.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showEditTitleDialog(context, provider),
            child: const Icon(
              Icons.edit,
              size: 20,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建麦克风图标区域
  Widget _buildMicrophoneSection(BuildContext context, MPAudioRecordProvider provider) {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        color: Color(0xFFE53935), // 红色背景
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.mic,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  /// 构建时长显示区域
  Widget _buildDurationSection(BuildContext context, MPAudioRecordProvider provider) {
    return Text(
      provider.formattedDuration,
      style: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111111),
        letterSpacing: 2,
      ),
    );
  }

  /// 构建状态文本区域
  Widget _buildStatusSection(BuildContext context, MPAudioRecordProvider provider) {
    if (provider.statusText.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      provider.statusText,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF666666),
      ),
    );
  }

  /// 构建底部按钮区域
  Widget _buildBottomButtons(BuildContext context, MPAudioRecordProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 关闭按钮
          _buildCloseButton(context, provider),
          // 录制/暂停按钮
          _buildRecordButton(context, provider),
          // 保存按钮
          _buildSaveButton(context, provider),
        ],
      ),
    );
  }

  /// 构建关闭按钮
  Widget _buildCloseButton(BuildContext context, MPAudioRecordProvider provider) {
    return GestureDetector(
      onTap: () => _showCancelDialog(context, provider),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close,
          color: Color(0xFF111111),
          size: 24,
        ),
      ),
    );
  }

  /// 构建录制/暂停按钮
  Widget _buildRecordButton(BuildContext context, MPAudioRecordProvider provider) {
    final isRecording = provider.state == MPAudioRecordState.recording;
    final isPaused = provider.state == MPAudioRecordState.paused;

    return GestureDetector(
      onTap: () async {
        try {
          if (isRecording) {
            // 正在录制，点击暂停
            await provider.pauseRecording();
          } else if (isPaused) {
            // 已暂停，点击继续录制
            await provider.startRecording();
          } else {
            // 未开始，点击开始录制
            await provider.startRecording();
          }
        } catch (e) {
          MPToastUtils.showMessage('操作失败: $e');
        }
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF2196F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isRecording ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  /// 构建保存按钮
  Widget _buildSaveButton(BuildContext context, MPAudioRecordProvider provider) {
    final canSave = provider.duration > 0 &&
        (provider.state == MPAudioRecordState.paused || provider.state == MPAudioRecordState.recording);

    return GestureDetector(
      onTap: canSave ? () => _handleSave(context, provider) : null,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: canSave ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  /// 显示编辑标题弹窗
  void _showEditTitleDialog(BuildContext context, MPAudioRecordProvider provider) {
    final controller = TextEditingController(text: provider.title);

    MPCenterPopup.show(
      context: context,
      contentWidget: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '修改录音名称',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              cursorColor: const Color(0xFF111111),
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: '请输入录音名称',
                hintStyle: const TextStyle(
                  color: Color(0xFF999999),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF306CFF)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '取消',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    final newTitle = controller.text.trim();
                    if (newTitle.isNotEmpty) {
                      provider.updateTitle(newTitle);
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    '确认',
                    style: TextStyle(
                      color: Color(0xFF306CFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  /// 显示取消确认弹窗
  void _showCancelDialog(BuildContext context, MPAudioRecordProvider provider) {
    MPCenterPopup.show(
      context: context,
      contentWidget: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '取消录音',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '确定要取消当前录音吗?录音内容将不会被保存。',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '返回录音',
                    style: TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await provider.cancelRecording();
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text(
                    '确认取消',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  /// 处理保存
  Future<void> _handleSave(BuildContext context, MPAudioRecordProvider provider) async {
    // 如果正在录制，先暂停
    if (provider.state == MPAudioRecordState.recording) {
      await provider.pauseRecording();
    }

    try {
      // 显示保存中提示
      MPToastUtils.showMessage('正在保存...');

      // 保存为MP3
      final mp3Path = await provider.saveAsMp3();

      if (mp3Path != null && mounted) {
        MPToastUtils.showMessage('保存成功');
        widget.onSave(mp3Path);
        Navigator.of(context).pop();
      }
    } catch (e) {
      MPToastUtils.showMessage('保存失败: $e');
    }
  }
}
