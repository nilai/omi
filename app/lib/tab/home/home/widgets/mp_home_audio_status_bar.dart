import 'package:flutter/material.dart';
import 'package:memo_pin/tab/home/home/mp_home_cubit.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';

/// 首页录音 / 同步 / 导入状态条（对齐 react `AudioStatusBar`）。
///
/// 导入 / 同步态：进度为自中心向两侧往复扩散的动画条；右侧 **始终** 展示 **x/y**
///（[MPHomeAudioStatus.currentFile] / [MPHomeAudioStatus.totalFiles]，缺省按 `1/1`）。
class MPHomeAudioStatusBar extends StatelessWidget {
  const MPHomeAudioStatusBar({super.key, required this.status});

  final MPHomeAudioStatus status;

  @override
  Widget build(BuildContext context) {
    final bool isRecording = status.type == MPHomeAudioStatusType.recording;
    final bool showImportSyncRow =
        !isRecording &&
        (status.type == MPHomeAudioStatusType.importing || status.type == MPHomeAudioStatusType.syncing);
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
                    style: TextStyle(
                      fontSize: OmiFontSize.t5_14,
                      height: 1.35,
                      color: const Color(0xFF1D1D1F),
                      fontWeight: OmiFontWeight.medium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (showImportSyncRow)
                    _ImportSyncProgressRow(
                      currentFile: status.currentFile,
                      totalFiles: status.totalFiles,
                    ),
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
        final int? t = status.totalFiles;
        final int? c = status.currentFile;
        if (t != null && t > 1 && c != null) {
          return 'Importing audio files ($c of $t)';
        }
        return 'Importing audio file';
    }
  }
}

/// 自轨道中心向左右扩散、往复播放的指示条；右侧 **始终** 展示 **x/y** 文件序号。
class _ImportSyncProgressRow extends StatefulWidget {
  const _ImportSyncProgressRow({required this.currentFile, required this.totalFiles});

  /// 当前正在处理的文件序号（从 1 开始）；与 [totalFiles] 一并由 Cubit / 业务更新。
  final int? currentFile;

  /// 本次导入或上传的文件总数；为 `null` 或小于 1 时按 **1** 参与 **x/y** 展示。
  final int? totalFiles;

  @override
  State<_ImportSyncProgressRow> createState() => _ImportSyncProgressRowState();
}

class _ImportSyncProgressRowState extends State<_ImportSyncProgressRow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const Duration _kSpreadDuration = Duration(milliseconds: 1400);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _kSpreadDuration)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 规范化后的 **x/y**（缺省时为 `1/1`，且保证 `x` 落在 `1…y`）。
  String _fileIndexLabel() {
    final int y = widget.totalFiles == null || widget.totalFiles! < 1 ? 1 : widget.totalFiles!;
    final int x = (widget.currentFile ?? 1).clamp(1, y);
    return '$x/$y';
  }

  @override
  Widget build(BuildContext context) {
    final Curve curve = Curves.easeInOutCubic;
    return Row(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: <Widget>[
                  const Positioned.fill(child: ColoredBox(color: Color(0xFFE8ECEF))),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (BuildContext context, Widget? child) {
                      final double t = curve.transform(_controller.value);
                      // 自轨道中心向左右对称扩散：宽度由窄到宽往复（repeat reverse）。
                      final double widthFactor = 0.06 + t * 0.94;
                      return LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          final double maxW = constraints.maxWidth;
                          final double maxH = constraints.maxHeight;
                          final double w = (maxW * widthFactor).clamp(2.0, maxW);
                          return Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: w,
                              height: maxH,
                              child: const ColoredBox(color: blueTextColor),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _fileIndexLabel(),
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: OmiFontSize.t3_12,
            fontWeight: OmiFontWeight.medium,
            color: const Color(0xFF86868B),
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
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
            const ColoredBox(color: Color(0xFFE8ECEF)),
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
