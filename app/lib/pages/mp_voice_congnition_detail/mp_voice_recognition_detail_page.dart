// AI-generated START - 声纹详情页面
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';
import 'package:omi/pages/mp_add_voive_recognition/widgets/mp_delete_voice_dialog.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/mp_common_app_bar.dart';
import 'package:omi/pages/mp_voice_congnition_detail/providers/mp_voice_recognition_detail_provider.dart';
import 'package:omi/services/voice_recognition_event_service.dart';
import 'package:provider/provider.dart';

/// 声纹详情页面
/// 用于查看和编辑声纹信息
class MPVoiceRecognitionDetailPage extends StatefulWidget {
  const MPVoiceRecognitionDetailPage(
      {super.key,
      this.voiceId,
      this.initialName,
      this.audioDuration,
      this.isEditMode = false,
      this.audioPath,
      this.isMyselfVoice = false,
      this.imageUrl});

  /// 是否是编辑模式
  final bool isEditMode;

  /// 声纹ID
  final String? voiceId;

  /// 初始名称
  final String? initialName;

  /// 音频时长（秒）
  final String? audioDuration;

  /// 音频数据
  final String? audioPath;

  /// 是否是自己的声音
  final bool isMyselfVoice;

  /// 头像图片URL
  final String? imageUrl;

  @override
  State<MPVoiceRecognitionDetailPage> createState() => _MPVoiceRecognitionDetailPageState();
}

class _MPVoiceRecognitionDetailPageState extends State<MPVoiceRecognitionDetailPage> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');

    // // 在页面初始化后，如果 audioDuration 为 0，尝试从 audioPath 获取时长
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final provider = Provider.of<MPVoiceRecognitionDetailProvider>(context, listen: false);
    //   if (provider.totalDuration == 0 && widget.audioPath != null && widget.audioPath!.isNotEmpty) {
    //     provider.initializeDurationFromPath();
    //   }
    // });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 解析音频时长字符串为秒数
  /// 支持格式：'0秒'、'95'、'1分30秒' 等
  int _parseAudioDuration(String? durationStr) {
    if (durationStr == null || durationStr.isEmpty) {
      return 0;
    }

    try {
      // 如果直接是数字字符串，直接解析
      return int.parse(durationStr);
    } catch (e) {
      // 如果不是纯数字，尝试提取数字部分
      // 移除所有非数字字符，只保留数字
      final digitsOnly = durationStr.replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.isNotEmpty) {
        return int.parse(digitsOnly);
      }
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MPVoiceRecognitionDetailProvider(
        voiceId: widget.voiceId,
        audioDuration: _parseAudioDuration(widget.audioDuration),
        isEditMode: widget.isEditMode,
        audioPath: widget.audioPath,
        isMyselfVoice: widget.isMyselfVoice,
        avatarUrl: widget.imageUrl,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const MPCommonAppBar(
          title: '声纹详情',
        ),
        body: Consumer<MPVoiceRecognitionDetailProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2.0),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: const Color(0xFFF3F4F6),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // 头像
                          _buildAvatar(),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: // 名字输入框
                                _buildNameInput(),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    // 音频文件部分
                    _buildAudioFileSection(provider),
                    const SizedBox(height: 16.0),
                    // 提示信息
                    _buildInfoCard(),
                    const SizedBox(height: 40.0),
                    // 保存按钮（仅在编辑模式下显示）
                    if (provider.isEditMode) ...[
                      _buildSaveButton(provider),
                      const SizedBox(height: 12.0),
                    ],
                    // 删除按钮
                    _buildDeleteButton(provider),
                    const SizedBox(height: 32.0),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar() {
    return Consumer<MPVoiceRecognitionDetailProvider>(
      builder: (context, provider, child) {
        final avatarImage = provider.avatarImage;
        final avatarUrl = provider.avatarUrl;
        final canEdit = provider.isEditMode && !widget.isMyselfVoice;

        return GestureDetector(
          onTap: canEdit
              ? () async {
                  await provider.pickAvatarImage();
                }
              : null,
          child: Container(
            width: 48.0,
            height: 48.0,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: avatarImage != null
                  ? Image.file(
                      avatarImage,
                      width: 48.0,
                      height: 48.0,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 24.0,
                          color: Color(0xFF6B7280),
                        );
                      },
                    )
                  : avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          width: 48.0,
                          height: 48.0,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: 24.0,
                              color: Color(0xFF6B7280),
                            );
                          },
                        )
                      : const Icon(
                          Icons.person,
                          size: 24.0,
                          color: Color(0xFF6B7280),
                        ),
            ),
          ),
        );
      },
    );
  }

  /// 构建名字输入框
  Widget _buildNameInput() {
    return Consumer<MPVoiceRecognitionDetailProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '名字',
              style: TextStyle(
                fontSize: 12.0,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 4.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: TextField(
                controller: _nameController,
                readOnly: !provider.isEditMode || widget.isMyselfVoice, // 如果是我的声音，只能查看
                enabled: provider.isEditMode && !widget.isMyselfVoice, // 如果是我的声音，禁用输入
                cursorColor: const Color(0xFF1F2937),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: '请输入名字',
                  hintStyle: TextStyle(
                    fontSize: 16.0,
                    color: Color(0xFF1F2937),
                  ),
                ),
                style: TextStyle(
                  fontSize: 16.0,
                  color: (provider.isEditMode && !widget.isMyselfVoice)
                      ? const Color(0xFF1F2937)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建音频文件部分
  Widget _buildAudioFileSection(MPVoiceRecognitionDetailProvider provider) {
    final totalDuration = provider.totalDuration;
    final currentTime = provider.currentTime;
    final durationText = _formatDuration(totalDuration);
    final currentTimeText = _formatDuration(currentTime);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFFF3F4F6),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和时长
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '音频文件',
                style: TextStyle(
                  fontSize: 12.0,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Assets.images.mpMemoryDetailTime.image(
                    width: 16.0,
                    height: 16.0,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    durationText,
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // const SizedBox(height: 8.0),
          // 波形图
          // _buildWaveform(provider),
          // 播放控制
          _buildPlaybackControls(provider, currentTimeText, durationText),
        ],
      ),
    );
  }

  /// 构建波形图
  // Widget _buildWaveform(MPVoiceRecognitionDetailProvider provider) {
  //   return Container(
  //     height: 80.0,
  //     decoration: BoxDecoration(
  //       color: Colors.grey.shade100,
  //       borderRadius: BorderRadius.circular(8.0),
  //     ),
  //     child: CustomPaint(
  //       painter: _SimpleWaveformPainter(
  //         progress: provider.progress,
  //         isPlaying: provider.isPlaying,
  //       ),
  //       size: Size.infinite,
  //     ),
  //   );
  // }

  /// 构建播放控制
  Widget _buildPlaybackControls(
    MPVoiceRecognitionDetailProvider provider,
    String currentTimeText,
    String durationText,
  ) {
    return Row(children: [
      // 播放按钮
      GestureDetector(
        onTap: provider.isDownloading
            ? null
            : () async {
                if (provider.isPlaying) {
                  await provider.pause();
                } else {
                  await provider.play();
                }
              },
        child: Container(
          margin: const EdgeInsets.only(top: 12.0),
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: provider.isDownloading ? Colors.grey.shade400 : Colors.blue.shade600,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: provider.isDownloading
                ? const SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    provider.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28.0,
                  ),
          ),
        ),
      ),
      Expanded(
        child: Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
              ),
              child: Slider(
                value: provider.progress,
                onChanged: (value) {
                  provider.seekTo(value);
                },
                activeColor: Colors.blue.shade600,
                inactiveColor: const Color(0xFFE5E7EB),
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentTimeText,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      durationText,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ))
          ],
        ),
      ),
    ]);
  }

  /// 构建提示信息卡片
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(Assets.images.mpVoiceHelp.path, width: 28.0, height: 28.0),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              '这段录音将用于识别对话中的声音。建议录音时长至少30秒,环境安静,声音清晰。',
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建保存按钮
  Widget _buildSaveButton(MPVoiceRecognitionDetailProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          provider.saveVoice(_nameController.text, () {
            // 发送声音保存成功事件
            final voiceName = _nameController.text.isNotEmpty ? _nameController.text : '声纹';
            VoiceRecognitionEventService().emitVoiceSaved(
              data: {
                'voiceName': voiceName,
              },
            );
            Navigator.of(context).pop(true);
          });
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          backgroundColor: const Color(0xFF4F46E5), // 紫色
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: const Text(
          '保存',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// 构建删除按钮
  Widget _buildDeleteButton(MPVoiceRecognitionDetailProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _showDeleteConfirmDialog(provider);
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          backgroundColor: const Color(0xFFFEF2F2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: const Text(
          '删除',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFFDC2626),
          ),
        ),
      ),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(MPVoiceRecognitionDetailProvider provider) {
    MPDeleteVoiceDialog.show(
      context: context,
      voiceName: _nameController.text.isNotEmpty ? _nameController.text : '声纹',
      onCancel: () {
        // 取消操作
        Navigator.of(context).pop();
      },
      onConfirm: () {
        Navigator.of(context).pop(); // 先关闭对话框
        provider.deleteVoice(
          successCallback: () {
            // 发送声音删除成功事件
            VoiceRecognitionEventService().emitVoiceDeleted(
              data: {
                'voiceId': widget.voiceId,
                'voiceName': _nameController.text.isNotEmpty ? _nameController.text : '声纹',
              },
            );
            Navigator.of(context).pop(true); // 返回上一页
          },
        );
      },
    );
  }

  /// 格式化时长
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// 简单的波形图绘制器
class _SimpleWaveformPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;

  _SimpleWaveformPainter({
    required this.progress,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = Colors.blue.shade600
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const barWidth = 2.0;
    const spacing = 2.0;
    final barCount = ((size.width - 20) / (barWidth + spacing)).floor();
    final centerY = size.height / 2;

    // 生成随机波形数据（实际应用中应该使用真实的音频数据）
    for (int i = 0; i < barCount; i++) {
      final x = 10.0 + i * (barWidth + spacing);
      final height = (20.0 + (i % 10) * 3.0);
      final halfHeight = height / 2;

      final progressIndex = (barCount * progress).floor();
      final useActivePaint = isPlaying && i <= progressIndex;

      canvas.drawLine(
        Offset(x, centerY - halfHeight),
        Offset(x, centerY + halfHeight),
        useActivePaint ? activePaint : paint,
      );
    }

    // 绘制进度指示点
    if (isPlaying && progress > 0) {
      final progressX = 10.0 + (size.width - 20) * progress;
      final dotPaint = Paint()
        ..color = Colors.blue.shade600
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(progressX, centerY),
        4.0,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isPlaying != isPlaying;
  }
}
// AI-generated END - mp_voice_recognition_detail_page.dart
