import 'package:flutter/material.dart';
import 'package:memo_pin/tab/home/home/mp_home_cubit.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';

/// 首页录音 / 同步 / 导入状态条（对齐 react `AudioStatusBar`）。
///
/// 同步态：进度条为**当前文件**上传进度（0–100）；多文件时每条独立完成后再从 0 走到 100。
/// 序号与进度由 [MPHomeCubit] 经上传进度 / 创建通知写入。
class MPHomeAudioStatusBar extends StatelessWidget {
  const MPHomeAudioStatusBar({super.key, required this.status});

  final MPHomeAudioStatus status;

  @override
  Widget build(BuildContext context) {
    final bool isRecording = status.type == MPHomeAudioStatusType.recording;
    final bool showProgress = !isRecording && status.progress != null;
    final String title = _title();

    return Material(
      color: const Color(0xFFF5F7FA),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE8ECEF)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.mic_none_outlined,
                size: 18,
                color: isRecording ? redColor : blueTextColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (showProgress) _ProgressRow(progress: status.progress!),
                  if (isRecording) const _RecordingPulseBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title() {
    switch (status.type) {
      case MPHomeAudioStatusType.recording:
        return 'MemoPin is recording';
      case MPHomeAudioStatusType.syncing:
        final int? t = status.totalFiles;
        final int? c = status.currentFile;
        if (t != null && t > 1 && c != null) {
          return 'Syncing recordings ($c of $t)';
        }
        return 'Syncing recordings from MemoPin';
      case MPHomeAudioStatusType.importing:
        return 'Importing audio file';
    }
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress / 100.0,
              minHeight: 6,
              backgroundColor: const Color(0xFFE8ECEF),
              valueColor: const AlwaysStoppedAnimation<Color>(blueTextColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '$progress%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF86868B),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordingPulseBar extends StatefulWidget {
  const _RecordingPulseBar();

  @override
  State<_RecordingPulseBar> createState() => _RecordingPulseBarState();
}

class _RecordingPulseBarState extends State<_RecordingPulseBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 6,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(color: const Color(0xFFE8ECEF)),
            AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final double t = _controller.value;
                final double opacity = 0.5 + t * 0.5;
                return Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.28 + t * 0.12,
                    child: Opacity(
                      opacity: opacity,
                      child: const ColoredBox(color: blueTextColor),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
