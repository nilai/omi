import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../audio/record/mp_audio_upload_service.dart';
import '../../../../http/api/mp_memo.dart';
import '../../../../http/schema/mp_memo.dart';
import '../../../../permission/omi_microphone_manager.dart';
import '../../../../utils/mp_toast_utils.dart';
import '../../../../utils/omi_color_utils.dart';
import '../../../../utils/omi_font_utils.dart';
import 'mp_qucik_capture_confirm_dialog.dart';

enum _MPQuickCaptureState {
  idle,
  textReady,
  recording,
  analyzingText,
  transcribingVoice,
}

/// Quick Capture 弹窗（图1~图5五种状态）。
class MPQuickCaptureDialog extends StatefulWidget {
  const MPQuickCaptureDialog({
    super.key,
    required this.hostContext,
  });

  final BuildContext hostContext;

  /// 显示 Quick Capture 底部弹窗。
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return MPQuickCaptureDialog(hostContext: context);
      },
    );
  }

  @override
  State<MPQuickCaptureDialog> createState() => _MPQuickCaptureDialogState();
}

class _MPQuickCaptureDialogState extends State<MPQuickCaptureDialog>
    with SingleTickerProviderStateMixin {
  static const String _kQuickCaptureDirName = 'mp_quick_capture_records';
  static const Color _kPrimaryBlue = Color(0xFF2F7BFF);

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late FlutterSoundRecorder _recorder;

  AnimationController? _waveController;

  _MPQuickCaptureState _state = _MPQuickCaptureState.idle;
  bool _recorderOpened = false;
  String? _recordPath;
  bool _busy = false;
  bool _isClosing = false;
  late NavigatorState _sheetNavigator;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _textController.addListener(_handleTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sheetNavigator = Navigator.of(context);
  }

  @override
  void dispose() {
    _textController.removeListener(_handleTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    _waveController?.stop();
    _waveController?.dispose();
    _waveController = null;
    unawaited(_stopRecorder(deleteFile: true));
    super.dispose();
  }

  void _handleTextChanged() {
    if (!mounted) {
      return;
    }
    final bool hasText = _textController.text.trim().isNotEmpty;
    if (hasText && _state == _MPQuickCaptureState.idle) {
      setState(() => _state = _MPQuickCaptureState.textReady);
      return;
    }
    if (!hasText && _state == _MPQuickCaptureState.textReady) {
      setState(() => _state = _MPQuickCaptureState.idle);
    }
  }

  /// 组装分析结果并展示确认弹窗。
  Future<void> _showAnalyzeConfirmDialog({
    required String originalText,
    required List<MPAnalyzeMemoSuggestionStruct> structuredSuggestions,
  }) async {
    final String fallbackText = originalText.trim();
    final List<String> issues = structuredSuggestions
        .map((MPAnalyzeMemoSuggestionStruct e) {
          final String content = e.content.trim();
          if (content.isEmpty) {
            return '';
          }
          final String prefix = e.type == MPAnalyzeMemoSuggestionType.todo
              ? 'Todo: '
              : 'Memo: ';
          return '$prefix$content';
        })
        .where((String e) => e.isNotEmpty)
        .toList(growable: false);
    await MPQucikCaptureConfirmDialog.show(
      widget.hostContext,
      originalText: fallbackText,
      issues: issues,
    );
  }

  Future<String> _ensureQuickCaptureDirectory() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final String dir = p.join(docs.path, _kQuickCaptureDirName);
    await Directory(dir).create(recursive: true);
    return dir;
  }

  Future<void> _stopRecorder({required bool deleteFile}) async {
    try {
      if (_recorderOpened && (_recorder.isRecording || _recorder.isPaused)) {
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

  Future<void> _closeDialog() async {
    if (_isClosing) {
      return;
    }
    _isClosing = true;
    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    await _stopRecorder(deleteFile: true);
    if (_sheetNavigator.mounted && _sheetNavigator.canPop()) {
      _sheetNavigator.pop();
    }
  }

  Future<void> _startRecording() async {
    if (_busy) {
      return;
    }
    _focusNode.unfocus();
    setState(() => _busy = true);
    try {
      final bool hasPermission =
          await OmiMicrophoneManager.ensureMicrophonePermission();
      if (!hasPermission) {
        if (mounted) {
          setState(() => _busy = false);
        }
        return;
      }
      final String dir = await _ensureQuickCaptureDirectory();
      final String path = p.join(
        dir,
        'omi_quick_capture_${DateTime.now().millisecondsSinceEpoch}.aac',
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
      setState(() {
        _recordPath = path;
        _busy = false;
        _state = _MPQuickCaptureState.recording;
      });
    } catch (e) {
      await _stopRecorder(deleteFile: true);
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      MPToastUtils.showMessage('Failed to start recording: $e');
    }
  }

  Future<void> _cancelRecordingAndBackToIdle() async {
    await _stopRecorder(deleteFile: true);
    if (!mounted) {
      return;
    }
    setState(() {
      _state = _MPQuickCaptureState.idle;
    });
  }

  Future<void> _submitText() async {
    if (_busy) {
      return;
    }
    final String content = _textController.text.trim();
    if (content.isEmpty) {
      return;
    }
    setState(() {
      _busy = true;
      _state = _MPQuickCaptureState.analyzingText;
    });
    final MPAnalyzeMemoTextResponse? response = await analyzeMemoText(
      MPAnalyzeMemoTextRequest(
        content: content,
        createAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    );
    if (!mounted || _isClosing) {
      return;
    }
    if (response == null || response.baseResp.code != 0) {
      setState(() {
        _busy = false;
        _state = _MPQuickCaptureState.textReady;
      });
      MPToastUtils.showMessage(
        response?.baseResp.message ??
            'Analysis failed. Please try again later.',
      );
      return;
    }
    final String memoText = response.originalText.trim().isNotEmpty
        ? response.originalText
        : content;
    _isClosing = true;
    if (_sheetNavigator.mounted && _sheetNavigator.canPop()) {
      _sheetNavigator.pop();
    }
    if (!widget.hostContext.mounted) {
      return;
    }
    await _showAnalyzeConfirmDialog(
      originalText: memoText,
      structuredSuggestions: response.structuredSuggestions,
    );
  }

  Future<void> _finishRecordingAndTranscribe() async {
    if (_busy || _recordPath == null) {
      return;
    }
    setState(() {
      _busy = true;
      _state = _MPQuickCaptureState.transcribingVoice;
    });
    String? filePath = _recordPath;
    try {
      if (_recorderOpened) {
        filePath = await _recorder.stopRecorder() ?? filePath;
        await _recorder.closeRecorder();
        _recorderOpened = false;
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      MPToastUtils.showMessage('Failed to stop recording: $e');
      setState(() {
        _busy = false;
        _state = _MPQuickCaptureState.recording;
      });
      return;
    }
    if (filePath == null || filePath.isEmpty) {
      if (!mounted) {
        return;
      }
      MPToastUtils.showMessage('Invalid recording file.');
      setState(() {
        _busy = false;
        _state = _MPQuickCaptureState.idle;
      });
      return;
    }
    final File file = File(filePath);
    if (!await file.exists()) {
      if (!mounted) {
        return;
      }
      MPToastUtils.showMessage('Recording file not found.');
      setState(() {
        _busy = false;
        _state = _MPQuickCaptureState.idle;
      });
      return;
    }
    final List<int> bytes = await file.readAsBytes();
    final String contentType = 'audio/aac';
    final String? recordUri = await MPAudioUploadService().uploadMPAudioBytes(
      bytes,
      contentType,
    );
    if (recordUri == null || recordUri.isEmpty) {
      if (mounted) {
        MPToastUtils.showMessage('Failed to upload audio.');
        setState(() {
          _busy = false;
          _state = _MPQuickCaptureState.idle;
        });
      }
      await _stopRecorder(deleteFile: true);
      return;
    }
    final MPAnalyzeMemoRecordResponse? response = await analyzeMemoRecord(
      MPAnalyzeMemoRecordRequest(
        recordUrl: recordUri,
        createAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    );
    await _stopRecorder(deleteFile: true);
    if (!mounted || _isClosing) {
      return;
    }
    if (response == null || response.baseResp.code != 0) {
      setState(() {
        _busy = false;
        _state = _MPQuickCaptureState.idle;
      });
      MPToastUtils.showMessage(
        response?.baseResp.message ??
            'Transcription failed. Please try again later.',
      );
      return;
    }
    final String memoText = response.originalText.trim();
    _isClosing = true;
    if (_sheetNavigator.mounted && _sheetNavigator.canPop()) {
      _sheetNavigator.pop();
    }
    if (!widget.hostContext.mounted) {
      return;
    }
    await _showAnalyzeConfirmDialog(
      originalText: memoText,
      structuredSuggestions: response.structuredSuggestions,
    );
  }

  Widget _buildBottomAction() {
    switch (_state) {
      case _MPQuickCaptureState.idle:
        return _circleActionButton(
          icon: Icons.mic_none_rounded,
          background: const Color(0xFFF6F8FF),
          iconColor: secondTextColor,
          onTap: _busy ? null : _startRecording,
        );
      case _MPQuickCaptureState.textReady:
        return _circleActionButton(
          icon: Icons.arrow_upward_rounded,
          background: _kPrimaryBlue,
          iconColor: Colors.white,
          onTap: _busy ? null : _submitText,
        );
      case _MPQuickCaptureState.recording:
        return Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _circleActionButton(
              icon: Icons.close_rounded,
              background: const Color(0xFFF2F2F7),
              iconColor: secondTextColor,
              onTap: _busy ? null : _cancelRecordingAndBackToIdle,
            ),
            const SizedBox(width: 12),
            _circleActionButton(
              icon: Icons.check_rounded,
              background: _kPrimaryBlue,
              iconColor: Colors.white,
              onTap: _busy ? null : _finishRecordingAndTranscribe,
            ),
          ],
        );
      case _MPQuickCaptureState.analyzingText:
      case _MPQuickCaptureState.transcribingVoice:
        return const SizedBox.shrink();
    }
  }

  Widget _circleActionButton({
    required IconData icon,
    required Color background,
    required Color iconColor,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildRecordingWave() {
    const List<double> base = <double>[
      24,
      20,
      28,
      18,
      22,
      26,
      17,
      23,
      29,
      21,
      25,
      19,
      27,
      20,
      24,
    ];
    return AnimatedBuilder(
      animation: _waveController!,
      builder: (BuildContext context, Widget? child) {
        final double t = _waveController!.value * 2 * math.pi;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(base.length, (int index) {
            final double dynamicHeight =
                (base[index] + math.sin(t + index * 0.52) * 3.0).clamp(14, 32);
            return Padding(
              padding: EdgeInsets.only(right: index == base.length - 1 ? 0 : 5),
              child: Container(
                width: 4,
                height: dynamicHeight,
                decoration: BoxDecoration(
                  color: _kPrimaryBlue,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildLoadingLabel(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const _MPQuickCaptureDots(),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: OmiFontSize.t7_16,
            color: secondTextColor,
            fontWeight: OmiFontWeight.regular,
          ),
        ),
      ],
    );
  }

  Widget _buildCenterContent() {
    if (_state == _MPQuickCaptureState.recording) {
      return _buildRecordingWave();
    }
    if (_state == _MPQuickCaptureState.analyzingText) {
      return SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                _textController.text,
                style: TextStyle(
                  fontSize: OmiFontSize.t8_17,
                  color: mainTextColor,
                  fontWeight: OmiFontWeight.regular,
                ),
              ),
            ),
            const Spacer(),
            Center(child: _buildLoadingLabel('Analyzing...')),
            const SizedBox(height: 14),
          ],
        ),
      );
    }
    if (_state == _MPQuickCaptureState.transcribingVoice) {
      return _buildLoadingLabel('Transcribing...');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        autofocus: false,
        enabled: !_busy,
        maxLines: null,
        minLines: 1,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Capture a thought, idea, or task...',
          hintStyle: TextStyle(
            fontSize: OmiFontSize.t8_17,
            color: secondTextColor.withValues(alpha: 0.85),
            fontWeight: OmiFontWeight.regular,
          ),
        ),
        style: TextStyle(
          fontSize: OmiFontSize.t8_17,
          color: mainTextColor,
          fontWeight: OmiFontWeight.regular,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final double safeBottom = mq.viewPadding.bottom;
    final double keyboardInset = mq.viewInsets.bottom;
    final bool isInputState = _state == _MPQuickCaptureState.idle ||
        _state == _MPQuickCaptureState.textReady;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, safeBottom),
              child: SizedBox(
                height: 380,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 8, 14),
                      child: Row(
                        children: <Widget>[
                          Text(
                            'Quick Capture',
                            style: TextStyle(
                              fontSize: OmiFontSize.t9_18,
                              color: mainTextColor,
                              fontWeight: OmiFontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _closeDialog,
                            icon: const Icon(Icons.close_rounded),
                            color: secondTextColor,
                          ),
                        ],
                      ),
                    ),
                    Container(height: 1, color: lineColor.withValues(alpha: 0.8)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: isInputState
                              ? Alignment.topLeft
                              : Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.only(top: isInputState ? 12 : 0),
                            child: _buildCenterContent(),
                          ),
                        ),
                      ),
                    ),
                    Container(height: 1, color: lineColor.withValues(alpha: 0.8)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                      child: _state == _MPQuickCaptureState.recording
                          ? _buildBottomAction()
                          : Align(
                              alignment: Alignment.centerRight,
                              child: _buildBottomAction(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MPQuickCaptureDots extends StatefulWidget {
  const _MPQuickCaptureDots();

  @override
  State<_MPQuickCaptureDots> createState() => _MPQuickCaptureDotsState();
}

class _MPQuickCaptureDotsState extends State<_MPQuickCaptureDots>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.stop();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller!,
      builder: (BuildContext context, Widget? child) {
        return Row(
          children: List<Widget>.generate(3, (int index) {
            final double t = (_controller!.value + index * 0.2) % 1.0;
            final double opacity = 0.25 + 0.75 * (1 - (t - 0.5).abs() * 2);
            return Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _MPQuickCaptureDialogState._kPrimaryBlue.withValues(
                    alpha: opacity,
                  ),
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
