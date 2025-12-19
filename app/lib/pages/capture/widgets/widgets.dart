/// 捕获页面组件库
///
/// 包含捕获页面使用的各种卡片和组件：
/// - 语音配置文件卡片
/// - 固件更新卡片
/// - 照片预览组件
/// - 转录显示组件
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/bt_device/bt_device.dart';
import 'package:omi/backend/schema/conversation.dart';
import 'package:omi/backend/schema/message_event.dart';
import 'package:omi/backend/schema/transcript_segment.dart';
import 'package:omi/pages/home/firmware_update.dart';
import 'package:omi/pages/speech_profile/page.dart';
import 'package:omi/providers/capture_provider.dart';
import 'package:omi/providers/device_provider.dart';
import 'package:omi/providers/home_provider.dart';
import 'package:omi/utils/analytics/mixpanel.dart';
import 'package:omi/utils/other/temp.dart';
import 'package:omi/widgets/photos_grid.dart';
import 'package:omi/widgets/transcript.dart';
import 'package:provider/provider.dart';

/// 语音配置文件卡片组件
///
/// 显示一个提示卡片，引导用户创建语音配置文件。
/// 仅在以下条件满足时显示：
/// - 用户尚未创建语音配置文件
/// - 设备已配对且已连接
/// - 设备固件版本不是1.0.2
///
/// 点击卡片会跳转到语音配置文件创建页面。
class SpeechProfileCardWidget extends StatelessWidget {
  const SpeechProfileCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        // 如果正在加载，不显示任何内容
        if (provider.isLoading) return const SizedBox();
        // 如果已有语音配置文件，不显示卡片
        return provider.hasSpeakerProfile
            ? const SizedBox()
            : Consumer<DeviceProvider>(builder: (context, device, child) {
                // 检查设备状态：必须已配对、已连接，且固件版本不是1.0.2
                if (device.pairedDevice == null ||
                    !device.isConnected ||
                    device.pairedDevice?.firmwareRevision == '1.0.2') {
                  return const SizedBox();
                }
                return Stack(
                  children: [
                    // 可点击的卡片容器
                    GestureDetector(
                      onTap: () async {
                        // 记录分析事件
                        MixpanelManager().pageOpened('Speech Profile Memories');
                        // 记录进入页面前的语音配置文件状态
                        bool hasSpeakerProfile = SharedPreferencesUtil().hasSpeakerProfile;
                        // 跳转到语音配置文件页面
                        await routeToPage(context, const SpeechProfilePage());
                        // 如果语音配置文件状态发生变化，通知CaptureProvider更新
                        if (hasSpeakerProfile != SharedPreferencesUtil().hasSpeakerProfile) {
                          if (context.mounted) {
                            context.read<CaptureProvider>().onRecordProfileSettingChanged();
                          }
                        }
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF1F1F25),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        margin: const EdgeInsets.fromLTRB(16, 15, 16, 0),
                        padding: const EdgeInsets.all(16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.multitrack_audio),
                                  SizedBox(width: 16),
                                  Text(
                                    'Teach Omi your voice',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                    // 红色录音指示图标
                    const Positioned(
                      top: 6,
                      right: 24,
                      child: Icon(Icons.fiber_manual_record, color: Colors.red, size: 16.0),
                    ),
                  ],
                );
              });
      },
    );
  }
}

/// 固件更新卡片组件
///
/// 当检测到有新固件可用时显示更新提示卡片。
/// 点击卡片会跳转到固件更新页面。
class UpdateFirmwareCardWidget extends StatelessWidget {
  const UpdateFirmwareCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, child) {
        // 如果没有新固件，不显示卡片
        return (!provider.havingNewFirmware)
            ? const SizedBox()
            : Stack(
                children: [
                  // 可点击的卡片容器
                  GestureDetector(
                    onTap: () {
                      // 记录分析事件
                      MixpanelManager().pageOpened('Update Firmware Memories');
                      // 跳转到固件更新页面
                      routeToPage(context, FirmwareUpdate(device: provider.pairedDevice));
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF1F1F25),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: const EdgeInsets.all(16),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.upload),
                                SizedBox(width: 16),
                                Text(
                                  'Update omi firmware',
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              );
      },
    );
  }
}

/// 照片预览组件
///
/// 显示会话中的照片预览，最多显示最后3张照片（最新的在前）。
/// 照片以横向排列的方式显示，高度固定为80像素。
class PhotosPreviewWidget extends StatelessWidget {
  /// 要显示的照片列表
  final List<ConversationPhoto> photos;
  const PhotosPreviewWidget({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
    // 显示最后3张照片，最新的在前
    final displayPhotos = photos.length > 3 ? photos.sublist(photos.length - 3) : photos;
    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: displayPhotos.reversed.map((photo) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: AspectRatio(
              // 保持800:600的宽高比
              aspectRatio: 800 / 600,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.memory(
                  base64Decode(photo.base64),
                  fit: BoxFit.cover,
                  // 避免图片更新时的闪烁
                  gaplessPlayback: true,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 获取转录组件
///
/// 根据提供的参数构建并返回包含照片和转录内容的组件。
/// 如果正在创建会话，显示加载指示器。
/// 根据是否有照片和转录内容，返回不同的布局：
/// - 两者都有：照片在上，转录在下
/// - 只有照片：仅显示照片网格
/// - 只有转录：仅显示转录组件
/// - 都没有：返回空组件
///
/// [conversationCreating] 是否正在创建会话
/// [segments] 转录片段列表
/// [photos] 会话照片列表
/// [btDevice] 蓝牙设备（当前未使用）
/// [horizontalMargin] 是否显示水平边距
/// [topMargin] 是否显示顶部边距
/// [canDisplaySeconds] 是否可以显示秒数
/// [isConversationDetail] 是否为会话详情页面
/// [bottomMargin] 底部边距
/// [editSegment] 编辑片段的回调函数
/// [suggestions] 说话人标签建议事件映射
/// [taggingSegmentIds] 正在标记的片段ID列表
/// [onAcceptSuggestion] 接受建议的回调函数
/// [searchQuery] 搜索查询字符串
/// [currentResultIndex] 当前搜索结果索引
/// [onTapWhenSearchEmpty] 搜索为空时的点击回调
Widget getTranscriptWidget(
  bool conversationCreating,
  List<TranscriptSegment> segments,
  List<ConversationPhoto> photos,
  BtDevice? btDevice, {
  bool horizontalMargin = true,
  bool topMargin = true,
  bool canDisplaySeconds = true,
  bool isConversationDetail = false,
  double bottomMargin = 100.0,
  Function(String, int)? editSegment,
  Map<String, SpeakerLabelSuggestionEvent> suggestions = const {},
  List<String> taggingSegmentIds = const [],
  Function(SpeakerLabelSuggestionEvent)? onAcceptSuggestion,
  String searchQuery = '',
  int currentResultIndex = -1,
  VoidCallback? onTapWhenSearchEmpty,
}) {
  // 如果正在创建会话，显示加载指示器
  if (conversationCreating) {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  final bool showPhotos = photos.isNotEmpty;
  final bool showTranscript = segments.isNotEmpty;

  /// 构建照片网格组件
  Widget buildPhotos() {
    return PhotosGridComponent(
      photos: photos,
    );
  }

  /// 构建转录片段组件
  Widget buildTranscriptSegments() {
    return TranscriptWidget(
      segments: segments,
      horizontalMargin: horizontalMargin,
      topMargin: topMargin,
      canDisplaySeconds: canDisplaySeconds,
      isConversationDetail: isConversationDetail,
      bottomMargin: bottomMargin,
      editSegment: editSegment,
      suggestions: suggestions,
      taggingSegmentIds: taggingSegmentIds,
      onAcceptSuggestion: onAcceptSuggestion,
      searchQuery: searchQuery,
      currentResultIndex: currentResultIndex,
      onTapWhenSearchEmpty: onTapWhenSearchEmpty,
    );
  }

  // 如果同时有照片和转录，显示两者
  if (showPhotos && showTranscript) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 250,
          child: buildPhotos(),
        ),
        Expanded(
          child: buildTranscriptSegments(),
        ),
      ],
    );
  }

  // 如果只有照片，仅显示照片
  if (showPhotos) {
    return buildPhotos();
  }

  // 如果只有转录，仅显示转录
  if (showTranscript) {
    return buildTranscriptSegments();
  }
  // 都没有，返回空组件
  return const SizedBox.shrink();
}

/// 获取精简转录组件
///
/// 构建一个精简版本的转录显示组件，包含照片预览和精简转录内容。
/// 照片预览显示在顶部，转录内容显示在下方。
///
/// [segments] 转录片段列表
/// [photos] 会话照片列表
/// [btDevice] 蓝牙设备（当前未使用）
Widget getLiteTranscriptWidget(
  List<TranscriptSegment> segments,
  List<ConversationPhoto> photos,
  BtDevice? btDevice,
) {
  return Column(
    children: [
      // 如果有照片，显示照片预览
      if (photos.isNotEmpty) PhotosPreviewWidget(photos: photos),
      // 如果同时有照片和转录，添加间距
      if (photos.isNotEmpty && segments.isNotEmpty) const SizedBox(height: 8),
      // 如果有转录，显示精简转录组件
      if (segments.isNotEmpty)
        LiteTranscriptWidget(
          segments: segments,
        ),
    ],
  );
}
