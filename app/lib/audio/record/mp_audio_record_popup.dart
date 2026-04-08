import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:memo_pin/audio/record/mp_audio_local_records_util.dart';
import 'package:memo_pin/audio/record/mp_audio_upload_manger.dart';
import 'package:memo_pin/http/schema/mp_memory.dart';
import 'package:memo_pin/permission/omi_microphone_manager.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 录音结束并保存后的结果（临时文件路径 + 时长）。
class MPAudioRecordResult {
  const MPAudioRecordResult({required this.filePath, required this.duration});

  final String filePath;
  final Duration duration;
}

/// 模态路由默认会插入全屏 [ModalBarrier]，即便透明也会拦截点击；覆盖为不参与命中，下层页面才可操作。
class MPPassThroughBarrierDialogRoute extends RawDialogRoute<MPAudioRecordResult?> {
  MPPassThroughBarrierDialogRoute({required super.pageBuilder, required String super.barrierLabel})
    : super(
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 200),
      );

  @override
  Widget buildModalBarrier() {
    return const IgnorePointer(ignoring: true, child: SizedBox.shrink());
  }
}

/// 展示「Record Audio」流程弹窗：引导 → 计时录音 →（取消时）确认；录音中可最小化为底部胶囊条继续录。
///
/// 返回 [MPAudioRecordResult] 表示用户点击 Save；取消或关闭为 `null`。
Future<MPAudioRecordResult?> showMPAudioRecordPopup(BuildContext context) {
  final NavigatorState rootNavigator = Navigator.of(context, rootNavigator: true);
  final String barrierLabel = MaterialLocalizations.of(context).modalBarrierDismissLabel;
  return rootNavigator.push<MPAudioRecordResult?>(
    MPPassThroughBarrierDialogRoute(
      barrierLabel: barrierLabel,
      pageBuilder: (BuildContext context, Animation<double> a1, Animation<double> a2) {
        return _MPAudioRecordDialog(rootNavigator: rootNavigator);
      },
    ),
  );
}

enum _MPAudioRecordStep {
  /// 蓝色麦克风，点击开始
  intro,

  /// 计时 + 暂停/继续 + Cancel / Save
  recording,
}

class _MPAudioRecordDialog extends StatefulWidget {
  const _MPAudioRecordDialog({required this.rootNavigator});

  final NavigatorState rootNavigator;

  @override
  State<_MPAudioRecordDialog> createState() => _MPAudioRecordDialogState();
}

class _MPAudioRecordDialogState extends State<_MPAudioRecordDialog> with SingleTickerProviderStateMixin {
  static const Color _kBlue = Color(0xFF007AFF);
  static const Color _kGreyCircleBg = Color(0xFFE8E8E8);
  static const Color _kCancelSheetBg = Color(0xFFF2F2F7);
  static const Color _kWaveGreen = Color(0xFF34C759);

  _MPAudioRecordStep _step = _MPAudioRecordStep.intro;

  /// 盖在「录音态」上的取消确认层
  bool _showCancelConfirm = false;

  /// `true` 时隐藏大卡与遮罩，仅保留底部胶囊条；录音不中断。
  bool _minimized = false;

  late final AnimationController _waveController;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderOpened = false;

  String? _recordPath;
  Duration _elapsed = Duration.zero;
  bool _isPaused = false;
  Timer? _tickTimer;

  bool _busy = false;

  /// 上传阶段进度（`null` 表示未在上传）；由 [MPAudioUploadManager.uploadLocalRecord] 的 [onPerFileProgress] 更新。
  int? _uploadProgressPct;
  int _uploadBatchIndex = 1;
  int _uploadBatchTotal = 1;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat();
  }

  @override
  void dispose() {
    _waveController.stop();
    _waveController.dispose();
    _tickTimer?.cancel();
    unawaited(_releaseRecorder(deleteFile: true));
    super.dispose();
  }

  Future<void> _releaseRecorder({required bool deleteFile}) async {
    _tickTimer?.cancel();
    _tickTimer = null;
    if (!_recorderOpened) {
      return;
    }
    try {
      if (_recorder.isRecording || _recorder.isPaused) {
        await _recorder.stopRecorder();
      }
    } catch (_) {}
    try {
      await _recorder.closeRecorder();
    } catch (_) {}
    _recorderOpened = false;
    if (deleteFile && _recordPath != null) {
      try {
        final File f = File(_recordPath!);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }
    _recordPath = null;
  }

  void _startElapsedTicker() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isPaused) {
        return;
      }
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  String _formatMmSs(Duration d) {
    final int m = d.inMinutes.remainder(60);
    final int s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 底部条用 `0:05` 样式
  String _formatMinSec(Duration d) {
    final int m = d.inMinutes;
    final int s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _minimizeToPillBar() {
    if (_busy) {
      return;
    }
    setState(() {
      _showCancelConfirm = false;
      _minimized = true;
    });
  }

  void _expandFromPillBar() {
    if (_busy) {
      return;
    }
    setState(() => _minimized = false);
  }

  Future<void> _onTapStartRecording() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      if (!mounted) {
        return;
      }
      final bool ok = await OmiMicrophoneManager.ensureMicrophonePermission();
      if (!ok) {
        if (mounted) {
          setState(() => _busy = false);
        }
        return;
      }
      final Directory dir = await getTemporaryDirectory();
      final String path = p.join(dir.path, 'omi_focus_${DateTime.now().millisecondsSinceEpoch}.aac');
      await _recorder.openRecorder();
      _recorderOpened = true;
      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
        bitRate: 8000,
        numChannels: 1,
        sampleRate: 8000,
      );
      if (!mounted) {
        await _releaseRecorder(deleteFile: true);
        return;
      }
      setState(() {
        _recordPath = path;
        _step = _MPAudioRecordStep.recording;
        _elapsed = Duration.zero;
        _isPaused = false;
        _busy = false;
      });
      _startElapsedTicker();
    } catch (e) {
      if (mounted) {
        MPToastUtils.showMessage('无法开始录音: $e');
      }
      await _releaseRecorder(deleteFile: true);
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _togglePauseResume() async {
    if (_busy || _recordPath == null || !_recorderOpened) {
      return;
    }
    setState(() => _busy = true);
    try {
      if (_isPaused) {
        await _recorder.resumeRecorder();
        if (mounted) {
          setState(() {
            _isPaused = false;
            _busy = false;
          });
        }
      } else {
        await _recorder.pauseRecorder();
        if (mounted) {
          setState(() {
            _isPaused = true;
            _busy = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        MPToastUtils.showMessage('操作失败: $e');
        setState(() => _busy = false);
      }
    }
  }

  void _openCancelConfirm() {
    setState(() => _showCancelConfirm = true);
  }

  void _closeCancelConfirm() {
    setState(() => _showCancelConfirm = false);
  }

  Future<void> _onConfirmDiscard() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    _showCancelConfirm = false;
    await _releaseRecorder(deleteFile: true);
    if (mounted) {
      widget.rootNavigator.pop();
    }
  }

  Future<void> _onSave() async {
    if (_busy || _recordPath == null) {
      return;
    }
    setState(() => _busy = true);
    _tickTimer?.cancel();
    _tickTimer = null;
    final Duration total = _elapsed;
    String outPath = _recordPath!;
    try {
      if (_recorderOpened) {
        final String? stopped = await _recorder.stopRecorder();
        outPath = stopped ?? outPath;
        await _recorder.closeRecorder();
        _recorderOpened = false;
      }
    } catch (e) {
      if (mounted) {
        MPToastUtils.showMessage('保存失败: $e');
        setState(() => _busy = false);
      }
      await _releaseRecorder(deleteFile: false);
      return;
    }
    if (!mounted || outPath.isEmpty) {
      if (mounted) {
        setState(() => _busy = false);
      }
      return;
    }

    final File tempFile = File(outPath);
    if (!await tempFile.exists()) {
      if (mounted) {
        MPToastUtils.showMessage('录音文件不存在');
        setState(() => _busy = false);
      }
      return;
    }

    final String? savedPath = await MPAudioLocalRecordsUtil.copyTempFileToLocalStorage(tempFile);
    if (savedPath == null || savedPath.isEmpty) {
      if (mounted) {
        MPToastUtils.showMessage('保存到本地失败，请重试');
        setState(() => _busy = false);
      }
      return;
    }

    if (!mounted) {
      return;
    }

    final File localFile = File(savedPath);
    final int durationSec = total.inSeconds <= 0 ? 1 : total.inSeconds;
    final int createAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    setState(() {
      _uploadProgressPct = 0;
      _uploadBatchIndex = 1;
      _uploadBatchTotal = 1;
    });
    
    widget.rootNavigator.pop(MPAudioRecordResult(filePath: savedPath, duration: total));

    final MPCreateRecordResponse? created = await MPAudioUploadManager.instance.uploadLocalRecord(
      localFile: localFile,
      durationSec: durationSec,
      createAt: createAt,
      rightNowTranscribe: true,
      source: 'mp',
    );

    if (!mounted) {
      return;
    }

    if (created == null) {
      setState(() {
        _busy = false;
        _uploadProgressPct = null;
      });
      return;
    }

    setState(() => _uploadProgressPct = null);
    _recordPath = null;
  }

  void _onCloseIntro() {
    widget.rootNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final bool showDimAndCard = !_minimized || _step == _MPAudioRecordStep.intro;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (_step == _MPAudioRecordStep.recording && _minimized)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: Colors.transparent, child: SizedBox.expand()),
              ),
            ),
          if (showDimAndCard)
            Positioned.fill(
              child: IgnorePointer(child: ColoredBox(color: Colors.black.withValues(alpha: 0.45))),
            ),
          if (!_minimized)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: <Widget>[_buildMainSheet()],
                ),
              ),
            ),
          if (_showCancelConfirm && !_minimized) Positioned.fill(child: _buildCancelConfirmLayer()),
          if (_step == _MPAudioRecordStep.recording && _minimized)
            Positioned(
              left: 16,
              right: 16,
              bottom: mq.padding.bottom + kBottomNavigationBarHeight + 8,
              child: _buildMinimizedRecordingBar(),
            ),
        ],
      ),
    );
  }

  Widget _buildMinimizedRecordingBar() {
    return Material(
      color: Colors.transparent,
      elevation: 10,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFB8D4FF), Color(0xFFD8E4FF), Color(0xFFE8DDF8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _expandFromPillBar,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        height: 28,
                        child: _MPMinimizedWaveform(animation: _waveController, active: !_isPaused, color: _kWaveGreen),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatMinSec(_elapsed),
              style: OmiTextStyle.create(
                color: mainTextColor,
                fontSize: OmiFontSize.t7_16,
                fontWeight: OmiFontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),

            GestureDetector(
              onTap: _busy ? null : _togglePauseResume,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: redColor, shape: BoxShape.circle),
                child: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white, size: 22),
              ),
            ),
            if (!_isPaused) ...<Widget>[
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: redColor, shape: BoxShape.circle),
              ),
            ] else
              const SizedBox(width: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSheet() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: _step == _MPAudioRecordStep.intro ? _buildIntroBody() : _buildRecordingBody(),
        ),
      ),
    );
  }

  Widget _buildIntroBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(width: 36),
            Expanded(
              child: Text(
                'Record Audio',
                textAlign: TextAlign.center,
                style: OmiTextStyle.create(
                  color: mainTextColor,
                  fontSize: OmiFontSize.t8_17,
                  fontWeight: OmiFontWeight.bold,
                ),
              ),
            ),
            _circleIconButton(icon: Icons.close, onTap: _busy ? () {} : _onCloseIntro),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _busy ? null : _onTapStartRecording,
          child: Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle),
            child: const Icon(Icons.mic, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to start recording',
          style: OmiTextStyle.create(
            color: secondTextColor,
            fontSize: OmiFontSize.t5_14,
            fontWeight: OmiFontWeight.regular,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            _circleIconButton(icon: Icons.fullscreen_exit, onTap: _busy ? () {} : _minimizeToPillBar),
            Expanded(
              child: Text(
                'Record Audio',
                textAlign: TextAlign.center,
                style: OmiTextStyle.create(
                  color: mainTextColor,
                  fontSize: OmiFontSize.t8_17,
                  fontWeight: OmiFontWeight.bold,
                ),
              ),
            ),
            _circleIconButton(icon: Icons.close, onTap: _busy ? () {} : _openCancelConfirm),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _formatMmSs(_elapsed),
          style: OmiTextStyle.create(
            color: mainTextColor,
            fontSize: OmiFontSize.t33_42,
            fontWeight: OmiFontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _busy ? null : _togglePauseResume,
          child: Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(color: redColor, shape: BoxShape.circle),
            child: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isPaused ? 'Paused' : 'Recording...',
          style: OmiTextStyle.create(
            color: secondTextColor,
            fontSize: OmiFontSize.t5_14,
            fontWeight: OmiFontWeight.regular,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: _sheetButton(
                label: 'Cancel',
                foreground: mainTextColor,
                background: _kCancelSheetBg,
                onTap: _busy ? () {} : _openCancelConfirm,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _sheetButton(
                label: 'Save',
                foreground: Colors.white,
                background: _kBlue,
                onTap: _busy ? () {} : _onSave,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCancelConfirmLayer() {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned.fill(
          child: IgnorePointer(child: ColoredBox(color: Colors.black.withValues(alpha: 0.35))),
        ),
        Center(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const SizedBox(width: 36),
                        Expanded(
                          child: Text(
                            'Cancel Recording',
                            textAlign: TextAlign.center,
                            style: OmiTextStyle.create(
                              color: mainTextColor,
                              fontSize: OmiFontSize.t8_17,
                              fontWeight: OmiFontWeight.bold,
                            ),
                          ),
                        ),
                        _circleIconButton(icon: Icons.close, onTap: _busy ? () {} : _closeCancelConfirm),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Are you sure you want to cancel this recording? All progress will be lost.',
                      textAlign: TextAlign.center,
                      style: OmiTextStyle.create(
                        color: secondTextColor,
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.regular,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: _sheetButton(
                            label: 'No, Keep\nRecording',
                            foreground: mainTextColor,
                            background: _kCancelSheetBg,
                            height: 52,
                            onTap: _busy ? () {} : _closeCancelConfirm,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _sheetButton(
                            label: 'Yes, Cancel',
                            foreground: Colors.white,
                            background: redColor,
                            height: 52,
                            onTap: _busy ? () {} : _onConfirmDiscard,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: _kGreyCircleBg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 20, color: secondTextColor)),
      ),
    );
  }

  Widget _sheetButton({
    required String label,
    required Color foreground,
    required Color background,
    required VoidCallback onTap,
    double height = 48,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: height,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: OmiTextStyle.create(
                color: foreground,
                fontSize: OmiFontSize.t5_14,
                fontWeight: OmiFontWeight.medium,
                height: 1.15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 底部胶囊条内的简易波形（非真实电平，仅示意）。
class _MPMinimizedWaveform extends StatelessWidget {
  const _MPMinimizedWaveform({required this.animation, required this.active, required this.color});

  final Animation<double> animation;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double phase = active ? animation.value * 2 * math.pi : 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List<Widget>.generate(7, (int i) {
            final double h = active ? 4 + (math.sin(phase + i * 0.82) + 1) * 7 : 5.0 + (i % 3) * 1.5;
            return Padding(
              padding: EdgeInsets.only(right: i == 6 ? 0 : 3),
              child: Container(
                width: 3,
                height: h.clamp(4.0, 18.0),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1.5)),
              ),
            );
          }),
        );
      },
    );
  }
}
