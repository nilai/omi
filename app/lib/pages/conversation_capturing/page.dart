/// 对话捕获页面
///
/// 用于实时捕获和记录对话内容，包括：
/// - 实时转录对话内容（文本和语音）
/// - 捕获照片
/// - 显示对话片段和摘要
/// - 支持说话人识别和标注
/// - 停止录制并处理对话
///
/// 兼容 iOS 和 Android 平台
library;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/message_event.dart';
import 'package:omi/pages/capture/widgets/widgets.dart';
import 'package:omi/pages/conversation_detail/page.dart';
import 'package:omi/pages/conversation_detail/widgets/name_speaker_sheet.dart';
import 'package:omi/providers/capture_provider.dart';
import 'package:omi/providers/connectivity_provider.dart';
import 'package:omi/providers/device_provider.dart';
import 'package:omi/utils/enums.dart';
import 'package:omi/widgets/confirmation_dialog.dart';
import 'package:provider/provider.dart';

/// 对话捕获页面组件
///
/// 提供实时对话捕获界面，包含两个标签页：
/// - 转录和照片标签页：显示实时转录的对话片段和捕获的照片
/// - 摘要标签页：显示对话摘要和超时设置信息
class ConversationCapturingPage extends StatefulWidget {
  /// 顶部对话 ID（可选）
  ///
  /// 如果提供，将关联到指定的对话
  final String? topConversationId;

  const ConversationCapturingPage({
    super.key,
    this.topConversationId,
  });

  @override
  State<ConversationCapturingPage> createState() => _ConversationCapturingPageState();
}

/// 对话捕获页面状态管理类
///
/// 管理对话捕获页面的状态和交互逻辑
class _ConversationCapturingPageState extends State<ConversationCapturingPage> with TickerProviderStateMixin {
  /// Scaffold 的全局键
  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// 标签页控制器，用于切换转录和摘要两个标签页
  TabController? _controller;

  /// 是否显示总结确认对话框
  late bool showSummarizeConfirmation;

  /// 动画控制器（当前未使用，但已初始化）
  late AnimationController _animationController;

  @override
  void initState() {
    _controller = TabController(length: 2, vsync: this, initialIndex: 0);
    _controller!.addListener(() => setState(() {}));
    showSummarizeConfirmation = SharedPreferencesUtil().showSummarizeConfirmation;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// 将日期时间转换为秒数
  ///
  /// [dateTime] 要转换的日期时间
  ///
  /// 返回从指定日期时间到现在的秒数差
  int convertDateTimeToSeconds(DateTime dateTime) {
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    return difference.inSeconds;
  }

  /// 将秒数转换为 HH:MM:SS 格式的字符串
  ///
  /// [seconds] 要转换的秒数
  ///
  /// 返回格式化的时间字符串，例如 "01:23:45"
  String convertToHHMMSS(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(remainingSeconds)}';
  }

  /// 导航到新的对话详情页面
  ///
  /// [context] 构建上下文
  /// [conversation] 要显示的对话对象
  ///
  /// 使用 pushReplacement 替换当前页面，显示对话详情
  void _pushNewConversation(BuildContext context, conversation) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (c) => ConversationDetailPage(
          conversation: conversation,
        ),
      ));
    });
  }

  /// 停止对话录制
  ///
  /// [provider] 捕获提供者
  ///
  /// 停止当前正在进行的录制（手机麦克风或系统音频），并处理对话。
  /// 如果启用了确认对话框，会先显示确认对话框询问用户是否确定要停止。
  Future<void> _stopConversation(CaptureProvider provider) async {
    if (provider.segments.isNotEmpty || provider.photos.isNotEmpty) {
      /// 停止录制并处理对话的辅助函数
      Future<void> stopRecordingAndProcess() async {
        // Stop any active recording (phone mic or system audio)
        if (provider.recordingState == RecordingState.record) {
          await provider.stopStreamRecording();
        } else if (provider.recordingState == RecordingState.systemAudioRecord) {
          await provider.stopSystemAudioRecording();
        }
        // Then process the conversation
        provider.forceProcessingCurrentConversation();
      }

      if (!showSummarizeConfirmation) {
        await stopRecordingAndProcess();
        Navigator.of(context).pop();
        return;
      }
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              final timeoutDuration = SharedPreferencesUtil().conversationSilenceDuration;
              String timeoutText;
              if (timeoutDuration == -1) {
                timeoutText = "Conversation will only end manually.";
              } else {
                final minutes = timeoutDuration ~/ 60;
                timeoutText =
                    "Conversation is summarized after $minutes minute${minutes == 1 ? '' : 's'} of no speech.";
              }

              return ConfirmationDialog(
                title: "Finished Conversation?",
                description:
                    "Are you sure you want to stop recording and summarize the conversation now?\n\nHints: $timeoutText",
                checkboxValue: !showSummarizeConfirmation,
                checkboxText: "Don't ask me again",
                onCheckboxChanged: (value) {
                  setState(() {
                    showSummarizeConfirmation = !value;
                  });
                },
                onCancel: () {
                  Navigator.of(context).pop();
                },
                onConfirm: () async {
                  SharedPreferencesUtil().showSummarizeConfirmation = showSummarizeConfirmation;
                  await stopRecordingAndProcess();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              );
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CaptureProvider, DeviceProvider>(
      builder: (context, provider, deviceProvider, child) {
        return PopScope(
          canPop: true,
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: Theme.of(context).colorScheme.primary,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).colorScheme.primary,
              title: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      return;
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 24.0),
                  ),
                  const SizedBox(width: 4),
                  Text(provider.photos.isNotEmpty ? "📸" : "🎙️"),
                  const SizedBox(width: 4),
                  const Expanded(child: Text("Listening")),
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: TabBarView(
                      controller: _controller,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Transcripts, photos
                        provider.segments.isEmpty && provider.photos.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 50.0),
                                  child: Text("Waiting for transcript or photos..."),
                                ),
                              )
                            : getTranscriptWidget(
                                false,
                                provider.segments,
                                provider.photos,
                                deviceProvider.connectedDevice,
                                bottomMargin: 150,
                                suggestions: provider.suggestionsBySegmentId,
                                taggingSegmentIds: provider.taggingSegmentIds,
                                onAcceptSuggestion: (suggestion) {
                                  provider.assignSpeakerToConversation(suggestion.speakerId, suggestion.personId,
                                      suggestion.personName, [suggestion.segmentId]);
                                },
                                editSegment: (segmentId, speakerId) {
                                  final connectivityProvider =
                                      Provider.of<ConnectivityProvider>(context, listen: false);
                                  if (!connectivityProvider.isConnected) {
                                    ConnectivityProvider.showNoInternetDialog(context);
                                    return;
                                  }
                                  showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.black,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                      ),
                                      builder: (context) {
                                        final suggestion = provider.suggestionsBySegmentId.values.firstWhere(
                                            (s) => s.speakerId == speakerId,
                                            orElse: () => SpeakerLabelSuggestionEvent.empty());
                                        return NameSpeakerBottomSheet(
                                          speakerId: speakerId,
                                          segmentId: segmentId,
                                          segments: provider.segments,
                                          suggestion: suggestion,
                                          onSpeakerAssigned: (speakerId, personId, personName, segmentIds) async {
                                            await provider.assignSpeakerToConversation(
                                                speakerId, personId, personName, segmentIds);
                                          },
                                        );
                                      });
                                },
                              ),
                        // Summary Tab
                        Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32.0).copyWith(bottom: 50.0), // Adjust padding
                            child: Text(
                              provider.segments.isEmpty && provider.photos.isEmpty
                                  ? "No summary yet"
                                  : _getTimeoutDisplayText(),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: provider.segments.isEmpty ? 16 : 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: (provider.segments.isNotEmpty || provider.photos.isNotEmpty)
                ? Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => _stopConversation(provider),
                      icon: const FaIcon(
                        FontAwesomeIcons.stop,
                        color: Colors.white,
                        size: 20.0,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  /// 获取超时显示文本
  ///
  /// 根据用户设置的静音超时时间返回相应的提示文本。
  /// 如果超时时间为 -1，表示只能手动结束对话。
  /// 否则显示在多少分钟无语音后会自动总结对话。
  String _getTimeoutDisplayText() {
    final timeoutDuration = SharedPreferencesUtil().conversationSilenceDuration;
    if (timeoutDuration == -1) {
      return "Conversation will only end manually 🤫";
    } else {
      final minutes = timeoutDuration ~/ 60;
      return "Conversation is summarized after $minutes minute${minutes == 1 ? '' : 's'} of no speech 🤫";
    }
  }
}

/// 从时间戳字符串中提取经过的时间
///
/// [timepstamp] 时间戳字符串，格式应包含 " - " 分隔符
///
/// 返回时间戳字符串中 " - " 后面的部分（经过的时间）
String transcriptElapsedTime(String timepstamp) {
  timepstamp = timepstamp.split(' - ')[1];
  return timepstamp;
}
