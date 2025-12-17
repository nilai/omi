// AI-generated START - 录制声纹页面
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';
import 'package:omi/pages/mp_add_voive_recognition/providers/mp_add_voice_recognition_provider.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/mp_common_app_bar.dart';
import 'package:provider/provider.dart';

/// 录制声纹页面
/// 用于录制新的声纹识别
class MPAddVoiceRecognitionPage extends StatefulWidget {
  const MPAddVoiceRecognitionPage({
    super.key,
    this.title = '录制声纹',
    this.isMyselfVoice = false,
  });

  /// 页面标题
  final String title;

  /// 是否是自己的声音
  final bool isMyselfVoice;

  @override
  State<MPAddVoiceRecognitionPage> createState() => _MPAddVoiceRecognitionPageState();
}

class _MPAddVoiceRecognitionPageState extends State<MPAddVoiceRecognitionPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MPAddVoiceRecognitionProvider(
        isMyselfVoice: widget.isMyselfVoice,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: MPCommonAppBar(
          title: widget.title,
        ),
        body: Consumer<MPAddVoiceRecognitionProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24.0),
                    // 设备图片区域
                    _buildDeviceImageArea(),
                    const SizedBox(height: 24.0),
                    // 说明文字
                    _buildInstructionText(),
                    const SizedBox(height: 24.0),
                    // 朗读文本
                    _buildReadText(),
                    const SizedBox(height: 32.0),
                    // 录音按钮区域
                    _buildRecordingButtons(provider),
                    const SizedBox(height: 16.0),
                    _buildHintText(),
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

  /// 构建设备图片区域
  Widget _buildDeviceImageArea() {
    return Column(
      children: [
        // 设备图片
        Image.asset(
          Assets.images.mpVoiceAddMark.path,
          width: 256.0,
          height: 256.0,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  /// 构建说明文字
  Widget _buildInstructionText() {
    return Text(
      '请您连续平静的朗读下面这段话，可重复朗读，我们将用于识别您的声音，录音时间需在${MPAddVoiceRecognitionProvider.maxRecordingDuration}秒以上',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16.0,
        color: Colors.grey.shade800,
        height: 1.5,
      ),
    );
  }

  /// 构建朗读文本
  Widget _buildReadText() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.0,
        ),
      ),
      child: const Text(
        '清晨的阳光透过树梢洒在窗台，微风带着草木的清香轻轻掠过。我们走过喧闹的街巷，也看过安静的湖畔，那些日常里的细碎时光，都藏着温暖的印记。试着放慢脚步，感受每一次呼吸的节奏，让声音自然舒展，清晰传递出属于自己的独特韵律，留存下最真实的语音模样。',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14.0,
          color: Color(0xFF1F2937),
          height: 1.5,
        ),
      ),
    );
  }

  /// 构建录音按钮区域
  Widget _buildRecordingButtons(MPAddVoiceRecognitionProvider provider) {
    return Column(
      children: [
        // 录音状态按钮（录音中时显示红色，未录音时显示紫色）
        SizedBox(
          height: 56.0,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: provider.isRecording
                ? null
                : () {
                    provider.startRecording();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  provider.isRecording ? const Color(0xFFEF4444) : const Color(0xFF9333EA), // 录音中：红色，未录音：紫色
              disabledBackgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: provider.isRecording
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 录音指示点
                      Container(
                        width: 8.0,
                        height: 8.0,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // 录音时长
                      Text(
                        '录音中 ${provider.recordingDuration}s / ${MPAddVoiceRecognitionProvider.maxRecordingDuration}s',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    '开始录音',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        // 停止录音按钮（仅在录音中时显示）
        if (provider.isRecording) ...[
          const SizedBox(height: 12.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                provider.stopRecording(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                '停止录音',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 构建底部提示文字
  Widget _buildHintText() {
    return Text(
      '您也可以到具体的记忆卡片里面去标记某个人的声音',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14.0,
        color: Colors.grey.shade600,
        height: 1.5,
      ),
    );
  }
}
// AI-generated END - mp_add_voice_recognition_page.dart
