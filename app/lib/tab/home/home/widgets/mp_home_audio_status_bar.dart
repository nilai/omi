import 'package:flutter/material.dart';
import 'package:memo_pin/tab/home/home/mp_home_cubit.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';

/// 首页录音 / 同步 / 导入状态条（对齐 react `AudioStatusBar`）。
///
/// 内容由 [MPHomeAudioStatus] 注入；蓝牙录音通知与「占录时推迟导入/同步」在 [MPHomeCubit] 中处理。
///
/// 录音 / 导入 / 同步态：进度均为自中心向两侧往复扩散的动画条；导入 / 同步右侧另展示 **x/y**。
class MPHomeAudioStatusBar extends StatelessWidget {
  const MPHomeAudioStatusBar({super.key, required this.status});

  final MPHomeAudioStatus status;

  @override
  Widget build(BuildContext context) {
    final bool isRecording = status.type == MPHomeAudioStatusType.recording;
    final bool showImportSyncRow =
        status.type == MPHomeAudioStatusType.importing || status.type == MPHomeAudioStatusType.syncing;
    final String title = _title();

    return Material(
      color: const Color(0xFFF5F7FA),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE8ECEF))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.mic_none_outlined, size: 18, color: isRecording ? redColor : blueTextColor),
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
                    _ImportSyncProgressRow(currentFile: status.currentFile, totalFiles: status.totalFiles),
                  if (isRecording) const _CenterSpreadAnimatedBar(indicatorColor: redColor),
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
        // final int? t = status.totalFiles;
        // final int? c = status.currentFile;
        // if (t != null && t > 1 && c != null) {
        //   return 'Syncing recordings ($c of $t)';
        // }
        return 'Syncing recordings to server';
      case MPHomeAudioStatusType.importing:
        // final int? t = status.totalFiles;
        // final int? c = status.currentFile;
        // if (t != null && t > 1 && c != null) {
        //   return 'Importing audio files ($c of $t)';
        // }
        return 'Importing audio file';
    }
  }
}

/// 自轨道中心向左右对称扩散、往复播放的指示条（录音 / 导入 / 同步共用）。
class _CenterSpreadAnimatedBar extends StatefulWidget {
  const _CenterSpreadAnimatedBar({this.indicatorColor = blueTextColor});

  final Color indicatorColor;

  @override
  State<_CenterSpreadAnimatedBar> createState() => _CenterSpreadAnimatedBarState();
}

class _CenterSpreadAnimatedBarState extends State<_CenterSpreadAnimatedBar> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final Curve curve = Curves.easeInOutCubic;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 6,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            const Positioned.fill(child: ColoredBox(color: Color(0xFFE8ECEF))),
            AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final double t = curve.transform(_controller.value);
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
                        child: ColoredBox(color: widget.indicatorColor),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 导入 / 同步：共用 [_CenterSpreadAnimatedBar] + 右侧 **x/y**。
class _ImportSyncProgressRow extends StatelessWidget {
  const _ImportSyncProgressRow({required this.currentFile, required this.totalFiles});

  final int? currentFile;
  final int? totalFiles;

  String _fileIndexLabel() {
    final int y = totalFiles == null || totalFiles! < 1 ? 1 : totalFiles!;
    final int x = (currentFile ?? 1).clamp(1, y);
    return '$x/$y';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: _CenterSpreadAnimatedBar()),
        const SizedBox(width: 24),
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
