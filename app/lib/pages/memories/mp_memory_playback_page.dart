import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

/// 记忆详情播放页
/// - 顶部与底部固定
/// - 页面内容根据屏幕尺寸自适应：内容不足不滚动，内容溢出可滚动
/// - 支持音频播放/暂停/进度条拖拽
class MPMemoryPlaybackPage extends StatefulWidget {
  final String audioUrl;
  final Duration initialDuration;
  final DateTime createdAt;
  final String? title;
  final String? tag;
  final VoidCallback? onShare;
  final VoidCallback? onMore;
  final VoidCallback? onSummarize;

  const MPMemoryPlaybackPage({
    super.key,
    required this.audioUrl,
    required this.initialDuration,
    required this.createdAt,
    this.title,
    this.tag,
    this.onShare,
    this.onMore,
    this.onSummarize,
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

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration;
    _setupPlayer();
  }

  Future<void> _setupPlayer() async {
    try {
      await _player.setUrl(widget.audioUrl);
      _duration = _player.duration ?? widget.initialDuration;
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
        _isBuffering = state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
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
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: widget.onShare,
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: widget.onMore,
          ),
        ],
        centerTitle: true,
        title: Text(widget.title ?? '记忆详情'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.onSummarize,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('AI总结'),
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
              physics:
                  _contentOverflow ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  key: _contentKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetaSection(),
                        const SizedBox(height: 16),
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
    final dateText = DateFormat('yyyy-MM-dd HH:mm:ss').format(widget.createdAt);
    final durationText =
        '${_duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(_duration.inSeconds.remainder(60)).toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16),
            const SizedBox(width: 8),
            Text(dateText),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.access_time, size: 16),
            const SizedBox(width: 8),
            Text(durationText),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.bookmark_outline, size: 16),
            const SizedBox(width: 8),
            Text(widget.tag ?? '记忆'),
          ],
        ),
      ],
    );
  }

  Widget _buildAudioCard(BuildContext context) {
    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.12),
            Theme.of(context).colorScheme.primary.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: _isBuffering ? null : _togglePlay,
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _isBuffering
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : Icon(
                          _player.playing ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatClock(_position)),
                        Text(_formatClock(_duration)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline, size: 32, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            '随时可生成',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            '生成后将在此处展示摘要',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
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
}
