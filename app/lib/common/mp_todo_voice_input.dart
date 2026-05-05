import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:memo_pin/audio/record/mp_audio_upload_service.dart';

import '../audio/record/mp_recording_background_support.dart';
import 'package:memo_pin/permission/omi_microphone_manager.dart';

import '../http/api/mp_chat.dart';
import '../http/schema/mp_chat.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum MPTodoVoiceInputMode { text, recording, transcribing }

/// 返回 `true` 表示提交成功，输入框将清空；`false` 表示失败或取消，保留原文。
typedef MPTodoVoiceInputOnSubmitted =
    Future<bool> Function(MPTodoVoiceInputResult result);

class MPTodoVoiceInputResult {
  const MPTodoVoiceInputResult({
    required this.text,
    required this.fromVoice,
    this.recordUrl,
  });

  final String text;

  /// `false`：键盘输入（含先录音转写再编辑后提交）；`true`：仍由上层按 [recordUrl] 走 [analyzeMemoRecord]（本组件确认录音后已改为先转写再文本提交）。
  final bool fromVoice;

  /// 语音路径下、上传成功后的录音 URL；纯文本或先转写再提交时为空。
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
  final MPTodoVoiceInputOnSubmitted? onSubmitted;
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
  bool _sending = false;
  bool _recorderOpened = false;
  String? _recordPath;

  /// 与 [_controller] 是否含非空 trim 同步，用于右侧「发送 / 麦克风」切换，避免仅依赖外层 rebuild。
  bool _hasTrimmedText = false;

  late final AnimationController _waveCtrl;
  late final AnimationController _dotsCtrl;

  void _onControllerChanged() {
    if (!mounted) return;
    final bool next = _controller.text.trim().isNotEmpty;
    if (next == _hasTrimmedText) return;
    setState(() => _hasTrimmedText = next);
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _hasTrimmedText = widget.initialText.trim().isNotEmpty;
    _controller.addListener(_onControllerChanged);
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
    _controller.removeListener(_onControllerChanged);
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
    await MPRecordingBackgroundSupport.deactivateAfterRecording();
  }

  double get _cornerRadius => widget.showOutline ? 12.0 : 16.0;

  Future<void> _submitTyped() async {
    if (_sending || _busy) return;
    final String t = _controller.text.trim();
    if (t.isEmpty) return;
    final MPTodoVoiceInputOnSubmitted? handler = widget.onSubmitted;
    if (handler == null) return;

    setState(() => _sending = true);
    _focusNode.unfocus();

    try {
      final bool ok = await handler(
        MPTodoVoiceInputResult(text: t, fromVoice: false),
      );
      if (!mounted) return;
      if (ok) {
        _controller.clear();
        widget.onChanged?.call('');
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _startRecording() async {
    if (_busy || _sending) return;
    _focusNode.unfocus();
    setState(() => _busy = true);
    try {
      final bool hasPermission =
          await OmiMicrophoneManager.ensureMicrophonePermission();
      if (!hasPermission) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      await MPRecordingBackgroundSupport.activateForRecording();
      final String dir = await _ensureRecordDirectory();
      final String path = p.join(
        dir,
        'omi_todo_voice_${DateTime.now().millisecondsSinceEpoch}.aac',
      );
      await _recorder.openRecorder(isBGService: true);
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
        MPToastUtils.showMessage('Failed to start recording: $e');
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
    if (_busy || _sending) return;
    if (_recordPath == null || _recordPath!.isEmpty) {
      MPToastUtils.showMessage('Invalid recording file.');
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
      await MPRecordingBackgroundSupport.deactivateAfterRecording();
    } catch (e) {
      _dotsCtrl.stop();
      if (mounted) {
        setState(() {
          _busy = false;
          _mode = MPTodoVoiceInputMode.text;
        });
        MPToastUtils.showMessage('Failed to stop recording: $e');
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
      MPToastUtils.showMessage('Recording file not found.');
      return;
    }

    final String? recordUri = await MPAudioUploadService().uploadMPAudio(file);

    if (!mounted) {
      _dotsCtrl.stop();
      await _stopRecorder(deleteFile: true);
      return;
    }

    if (recordUri == null || recordUri.isEmpty) {
      _dotsCtrl.stop();
      setState(() {
        _busy = false;
        _mode = MPTodoVoiceInputMode.text;
      });
      await _stopRecorder(deleteFile: true);
      MPToastUtils.showMessage('Failed to upload audio.');
      return;
    }

    final MPTranscriptResponse? transcriptResp = await transcript(
      MPTranscriptRequest(audioUrl: recordUri),
    );
    _dotsCtrl.stop();

    if (!mounted) {
      await _stopRecorder(deleteFile: true);
      return;
    }

    if (transcriptResp == null || transcriptResp.baseResp.code != 0) {
      final String msg = transcriptResp?.baseResp.message.isNotEmpty == true
          ? transcriptResp!.baseResp.message
          : 'Voice-to-text failed.';
      setState(() {
        _busy = false;
        _mode = MPTodoVoiceInputMode.text;
      });
      await _stopRecorder(deleteFile: true);
      MPToastUtils.showMessage(msg);
      return;
    }

    final String text = transcriptResp.content.trim();
    if (text.isEmpty) {
      setState(() {
        _busy = false;
        _mode = MPTodoVoiceInputMode.text;
      });
      await _stopRecorder(deleteFile: true);
      MPToastUtils.showMessage('No speech recognized.');
      return;
    }

    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    widget.onChanged?.call(text);

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
              readOnly: _sending,
              onChanged: widget.onChanged,
              onSubmitted: (_) => unawaited(_submitTyped()),
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
          if (_hasTrimmedText)
            _sending
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: blueTextColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  )
                : _circleButton(
                    bg: blueTextColor,
                    onTap: () => unawaited(_submitTyped()),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  )
          else
            _circleButton(
              bg: const Color(0xFFEAF7EF),
              onTap: _sending ? null : _startRecording,
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
