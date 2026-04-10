import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:memo_pin/audio/record/mp_audio_upload_service.dart';
import 'package:memo_pin/permission/omi_microphone_manager.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum MPTodoVoiceInputMode { text, recording, transcribing }

class MPTodoVoiceInputResult {
  const MPTodoVoiceInputResult({
    required this.text,
    required this.fromVoice,
    this.recordUrl,
  });

  final String text;

  /// `false`：键盘输入；`true`：语音录制并上传后得到 [recordUrl]，由上层走 [analyzeMemoRecord]。
  final bool fromVoice;

  /// 语音路径下、上传成功后的录音 URL；纯文本时为空。
  final String? recordUrl;
}

class MPTodoVoiceInput extends StatefulWidget {
  const MPTodoVoiceInput({
    super.key,
    this.hintText = 'Add something you need to do',
    this.initialText = '',
    this.onSubmitted,
    this.onChanged,
    this.transcribeDelay = const Duration(milliseconds: 1400),
    this.showOutline = true,
  });

  final String hintText;
  final String initialText;
  final ValueChanged<MPTodoVoiceInputResult>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Duration transcribeDelay;

  /// 为 `false` 时无外描边，适合外包一层带投影的圆角卡片（如首页 ALL TO DOS）。
  final bool showOutline;

  @override
  State<MPTodoVoiceInput> createState() => _MPTodoVoiceInputState();
}

class _MPTodoVoiceInputState extends State<MPTodoVoiceInput>
    with TickerProviderStateMixin {
  static const String _kRecordDirName = 'mp_todo_voice_input_records';

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late FlutterSoundRecorder _recorder;

  MPTodoVoiceInputMode _mode = MPTodoVoiceInputMode.text;
  bool _busy = false;
  bool _recorderOpened = false;
  String? _recordPath;

  late final AnimationController _waveCtrl;
  late final AnimationController _dotsCtrl;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    _recorder = FlutterSoundRecorder();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    unawaited(_stopRecorder(deleteFile: true));
    _waveCtrl.dispose();
    _dotsCtrl.dispose();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<String> _ensureRecordDirectory() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final String dir = p.join(docs.path, _kRecordDirName);
    await Directory(dir).create(recursive: true);
    return dir;
  }

  Future<void> _stopRecorder({required bool deleteFile}) async {
    try {
      if (_recorderOpened &&
          (_recorder.isRecording || _recorder.isPaused)) {
        await _recorder.stopRecorder();
      }
    } catch (_) {}
    try {
      if (_recorderOpened) {
        await _recorder.closeRecorder();
      }
    } catch (_) {}
    _recorderOpened = false;
    if (deleteFile && _recordPath != null) {
      final File file = File(_recordPath!);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    _recordPath = null;
  }

  bool get _hasText => _controller.text.trim().isNotEmpty;

  double get _cornerRadius => widget.showOutline ? 12.0 : 16.0;

  void _submitTyped() {
    final String t = _controller.text.trim();
    if (t.isEmpty) return;
    widget.onSubmitted?.call(
      MPTodoVoiceInputResult(text: t, fromVoice: false),
    );
  }

  Future<void> _startRecording() async {
    if (_busy) return;
    _focusNode.unfocus();
    setState(() => _busy = true);
    try {
      final bool hasPermission =
          await OmiMicrophoneManager.ensureMicrophonePermission();
      if (!hasPermission) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final String dir = await _ensureRecordDirectory();
      final String path = p.join(
        dir,
        'omi_todo_voice_${DateTime.now().millisecondsSinceEpoch}.aac',
      );
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
        await _stopRecorder(deleteFile: true);
        return;
      }
      _recordPath = path;
      setState(() {
        _busy = false;
        _mode = MPTodoVoiceInputMode.recording;
      });
      _waveCtrl.repeat();
    } catch (e) {
      await _stopRecorder(deleteFile: true);
      if (mounted) {
        setState(() => _busy = false);
        MPToastUtils.showMessage('开始录音失败: $e');
      }
    }
  }

  Future<void> _cancelRecording() async {
    _waveCtrl.stop();
    await _stopRecorder(deleteFile: true);
    if (!mounted) return;
    setState(() {
      _mode = MPTodoVoiceInputMode.text;
    });
  }

  Future<void> _confirmRecording() async {
    if (_busy) return;
    if (_recordPath == null || _recordPath!.isEmpty) {
      MPToastUtils.showMessage('录音文件无效');
      return;
    }
    _waveCtrl.stop();
    setState(() {
      _mode = MPTodoVoiceInputMode.transcribing;
      _busy = true;
    });
    _dotsCtrl.repeat();

    String? filePath = _recordPath;
    try {
      if (_recorderOpened) {
        filePath = await _recorder.stopRecorder() ?? filePath;
        await _recorder.closeRecorder();
        _recorderOpened = false;
      }
    } catch (e) {
      _dotsCtrl.stop();
      if (mounted) {
        setState(() {
          _busy = false;
          _mode = MPTodoVoiceInputMode.text;
        });
        MPToastUtils.showMessage('停止录音失败: $e');
      }
      await _stopRecorder(deleteFile: true);
      return;
    }

    if (filePath == null || filePath.isEmpty) {
      _dotsCtrl.stop();
      if (mounted) {
        setState(() {
          _busy = false;
          _mode = MPTodoVoiceInputMode.text;
        });
      }
      await _stopRecorder(deleteFile: true);
      return;
    }

    final File file = File(filePath);
    if (!await file.exists()) {
      _dotsCtrl.stop();
      if (mounted) {
        setState(() {
          _busy = false;
          _mode = MPTodoVoiceInputMode.text;
        });
      }
      await _stopRecorder(deleteFile: true);
      MPToastUtils.showMessage('录音文件不存在');
      return;
    }

    final String? recordUri = await MPAudioUploadService().uploadMPAudio(file);
    _dotsCtrl.stop();

    if (!mounted) {
      await _stopRecorder(deleteFile: true);
      return;
    }

    if (recordUri == null || recordUri.isEmpty) {
      setState(() {
        _busy = false;
        _mode = MPTodoVoiceInputMode.text;
      });
      await _stopRecorder(deleteFile: true);
      MPToastUtils.showMessage('音频上传失败');
      return;
    }

    widget.onSubmitted?.call(
      MPTodoVoiceInputResult(
        text: '',
        fromVoice: true,
        recordUrl: recordUri,
      ),
    );

    await _stopRecorder(deleteFile: true);
    if (!mounted) return;
    setState(() {
      _mode = MPTodoVoiceInputMode.text;
      _busy = false;
    });
    _focusNode.requestFocus();
  }

  Widget _circleButton({
    required Widget child,
    required Color bg,
    required VoidCallback? onTap,
    Color? borderColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor, width: 2),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _textMode() {
    return Container(
      height: 52,
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: widget.showOutline
            ? Border.all(color: const Color(0xFFEAEAEE))
            : null,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              onSubmitted: (_) => _submitTyped(),
              style: OmiTextStyle.create(
                fontSize: OmiFontSize.t6_15,
                fontWeight: OmiFontWeight.medium,
                color: mainTextColor,
                height: 1.25,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: OmiTextStyle.create(
                  fontSize: OmiFontSize.t6_15,
                  fontWeight: OmiFontWeight.regular,
                  color: secondTextColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (_hasText)
            _circleButton(
              bg: blueTextColor,
              onTap: _submitTyped,
              child: const Icon(
                Icons.arrow_upward_rounded,
                size: 20,
                color: Colors.white,
              ),
            )
          else
            _circleButton(
              bg: const Color(0xFFEAF7EF),
              onTap: _startRecording,
              child: const Icon(
                Icons.mic_none_rounded,
                size: 20,
                color: Color(0xFF2E5E49),
              ),
            ),
        ],
      ),
    );
  }

  Widget _recordingMode() {
    return Container(
      height: 52,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: Border.all(color: blueTextColor, width: 2),
      ),
      child: Row(
        children: <Widget>[
          _circleButton(
            bg: const Color(0xFFF2F2F7),
            onTap: _cancelRecording,
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: secondTextColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _MPTodoMiniWaveform(controller: _waveCtrl)),
          const SizedBox(width: 12),
          _circleButton(
            bg: blueTextColor,
            onTap: _confirmRecording,
            child: const Icon(
              Icons.check_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transcribingMode() {
    return Container(
      height: 52,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: Border.all(color: blueTextColor, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _MPTodoDots(controller: _dotsCtrl),
          const SizedBox(width: 10),
          Text(
            'Transcribing…',
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t6_15,
              fontWeight: OmiFontWeight.medium,
              color: secondTextColor.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
      case MPTodoVoiceInputMode.text:
        return _textMode();
      case MPTodoVoiceInputMode.recording:
        return _recordingMode();
      case MPTodoVoiceInputMode.transcribing:
        return _transcribingMode();
    }
  }
}

class _MPTodoMiniWaveform extends StatelessWidget {
  const _MPTodoMiniWaveform({required this.controller});

  final Animation<double> controller;

  static const int _bars = 16;

  double _barHeight(int i, double p) {
    final double t = (i / (_bars - 1)) * 2 * math.pi;
    final double wave = 0.5 + 0.5 * math.sin(t + p * 2 * math.pi);
    return 6 + wave * 16;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final double p = controller.value;
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double slotWidth = constraints.maxWidth / _bars;
            final double barWidth = math.min(3.0, math.max(1.0, slotWidth * 0.48));
            return Row(
              children: List<Widget>.generate(_bars, (int i) {
                final double h = _barHeight(i, p);
                final bool strong = i > _bars * 0.6;
                return Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: barWidth,
                      height: h,
                      decoration: BoxDecoration(
                        color: strong
                            ? blueTextColor
                            : blueTextColor.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }
}

class _MPTodoDots extends StatelessWidget {
  const _MPTodoDots({required this.controller});

  final Animation<double> controller;

  double _dotOpacity(int index, double p) {
    final double phase = index * 0.22;
    final double v = (p + phase) % 1.0;
    return 0.25 + 0.75 * (0.5 + 0.5 * math.sin(v * 2 * math.pi));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final double p = controller.value;
        return Row(
          children: List<Widget>.generate(3, (int i) {
            final double o = _dotOpacity(i, p);
            return Padding(
              padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: blueTextColor.withValues(alpha: o),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
