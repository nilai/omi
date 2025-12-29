import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

import '../../backend/http/mp_api/mp_memory.dart';
import '../../backend/schema/mp/mp_data_model.dart';
import '../../backend/schema/mp/mp_memory.dart';
import '../../pages/mp_custom_utils/mp_const_utils.dart';
import '../../pages/mp_custom_utils/mp_timestamp_utils.dart';
import '../../pages/mp_newsetting/home/widgets/mp_common_app_bar.dart';
import '../../services/mp_home_refresh_event_service.dart';
import '../../utils/alerts/mp_share_memory_dialog.dart';
import '../../utils/mp_local_records_util.dart';
import '../mp_custom_utils/mp_toast_utils.dart';
import '../mp_popup/mp_record_detail_more_popup.dart';
import 'mp_memory_transition_page.dart';
import 'widgets/mp_memory_convert_dialog.dart';
import 'widgets/mp_memory_update_name_dialog.dart';

/// 记忆详情播放页
/// - 顶部与底部固定
/// - 页面内容根据屏幕尺寸自适应：内容不足不滚动，内容溢出可滚动
/// - 支持音频播放/暂停/进度条拖拽
class MPMemoryPlaybackPage extends StatefulWidget {
  final MPMemoryStruct memory;

  const MPMemoryPlaybackPage({
    super.key,
    required this.memory,
  });

  @override
  State<MPMemoryPlaybackPage> createState() => _MPMemoryPlaybackPageState();
}

class _MPMemoryPlaybackPageState extends State<MPMemoryPlaybackPage> {
  final GlobalKey _contentKey = GlobalKey();
  final AudioPlayer _player = AudioPlayer();

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isBuffering = true;
  bool _contentOverflow = false;

  /// 从 memory 中获取音频 URL
  Future<String>? get _audioUrl async {
    String recordFile = '';
    if (widget.memory.onlyRecordContent != null) {
      recordFile = widget.memory.onlyRecordContent!.recordFile;
    } else if (widget.memory.summaryContent != null) {
      recordFile = widget.memory.summaryContent!.recordUrl;
    }
    final localPath = await MPLocalRecordsUtil.instance.getLocalRecordPath(recordFile);
    return localPath;
  }

  @override
  void initState() {
    super.initState();
    // 从 memory.duration 初始化，单位是秒
    _duration = Duration(seconds: widget.memory.duration);
    _setupPlayer();
  }

  Future<void> _setupPlayer() async {
    final audioUrl = await _audioUrl;
    if (audioUrl == null) {
      if (mounted) {
        setState(() {
          _isBuffering = false;
        });
      }
      return;
    }

    try {
      await _player.setUrl(audioUrl);
      _duration = _player.duration ?? Duration(seconds: widget.memory.duration);
    } catch (_) {
      // 失败时仍允许界面显示，播放按钮会被禁用
    } finally {
      if (mounted) {
        setState(() {
          _isBuffering = false;
        });
      }
    }

    _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() {
        _position = pos;
      });
    });

    _player.durationStream.listen((dur) {
      if (!mounted || dur == null) return;
      setState(() {
        _duration = dur;
      });
    });

    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isBuffering =
            state.processingState == ProcessingState.loading || state.processingState == ProcessingState.buffering;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isBuffering) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _seek(double seconds) async {
    if (_duration == Duration.zero) return;
    final newPosition = Duration(seconds: seconds.round());
    await _player.seek(newPosition);
    if (!_player.playing) {
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MPConstUtils.backgroundColorGrey,
      appBar: MPCommonAppBar(
        title: widget.memory.title.isNotEmpty ? widget.memory.title : '记忆详情',
        showMoreButton: true,
        showShareButton: true,
        onMorePressed: () {
          _showMoreActionsDialog(context);
        },
        onSharePressed: () => MPShareMemoryDialog.show(context: context, memoryId: widget.memory.id),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => MPMemoryConvertDialog.show(context, memory: widget.memory, onGenerate: () {
                Future.delayed(const Duration(milliseconds: 500), () {
                  MPHomeRefreshEventService().emitRefresh();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => MPMemoryTransitionPage(
                        memory: widget.memory,
                      ),
                    ),
                  );
                });
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: Color(0xFF60A5FA), // 浅蓝色图标
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI总结',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final size = _contentKey.currentContext?.size;
              if (size == null) return;
              final overflow = size.height > constraints.maxHeight;
              if (overflow != _contentOverflow && mounted) {
                setState(() {
                  _contentOverflow = overflow;
                });
              }
            });

            return SingleChildScrollView(
              physics: _contentOverflow ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  key: _contentKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: _buildMetaSection(),
                        ),
                        const SizedBox(height: 32),
                        _buildAudioCard(context),
                        const SizedBox(height: 16),
                        _buildSummaryPlaceholder(context),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetaSection() {
    // 从 memory.createAt 获取时间（时间戳，单位可能是毫秒或秒）
    final createdAt = MPTimestampUtils.timestampMsToDateTime(widget.memory.createAt);
    final dateText = DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt);
    // 格式化时长为 "2m 6s" 格式
    final durationText = MPTimestampUtils.toMinutesAndSecondsString(widget.memory.duration);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Text(
              dateText,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Text(
              durationText,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.bookmark_outline,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Text(
              widget.memory.label.isNotEmpty ? widget.memory.label : '记忆',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAudioCard(BuildContext context) {
    final progress =
        _duration.inMilliseconds == 0 ? 0.0 : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 播放按钮
          InkWell(
            onTap: _isBuffering ? null : _togglePlay,
            borderRadius: BorderRadius.circular(32),
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB), // 蓝色播放按钮
                shape: BoxShape.circle,
              ),
              child: _isBuffering
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _player.playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(width: 12.0),
          // 进度条和时间
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 进度条
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 8.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                    activeTrackColor: const Color(0xFF2563EB),
                    inactiveTrackColor: const Color(0xFFE5E7EB),
                    thumbColor: const Color(0xFF2563EB),
                  ),
                  child: Slider(
                    value: progress.isNaN ? 0 : progress,
                    min: 0,
                    max: 1,
                    onChanged: (value) {
                      if (_duration == Duration.zero) return;
                      _seek(_duration.inSeconds * value);
                    },
                  ),
                ),
                const SizedBox(height: 8.0),
                // 时间显示
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatClock(_position),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12.0,
                      ),
                    ),
                    Text(
                      _formatClock(_duration),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPlaceholder(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: const Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              Icons.chat_bubble_outline,
              size: 24,
              color: Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 12),
          Text(
            '随时可生成',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 14.0,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '生成后将在此处显示转写',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }

  String _formatClock(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showMoreActionsDialog(BuildContext context) {
    final actions = [
      MPRecordDetailMoreAction.export,
      // MPRecordDetailMoreAction.addTag,
      MPRecordDetailMoreAction.deleteMemory,
    ];
    MPRecordDetailMorePopup.show(context: context, actions: actions).then((value) {
      if (value != null) {
        switch (value) {
          case MPRecordDetailMoreAction.export:
            MPToastUtils.showFeatureComingSoon();
            break;
          // case MPRecordDetailMoreAction.addTag:
          //   break;
          case MPRecordDetailMoreAction.deleteMemory:
            _deleteMemory();
            break;
          default:
            break;
        }
      }
    });
  }

  Future<void> _deleteMemory() async {
    final req = MPDeleteMemoryRequest(memoryId: widget.memory.id);
    final res = await deleteMemory(req);
    if (res != null && res.baseResp.code == 0) {
      MPHomeRefreshEventService().emitRefresh();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      MPToastUtils.showMessage(res?.baseResp.message ?? '删除失败');
    }
  }
}
