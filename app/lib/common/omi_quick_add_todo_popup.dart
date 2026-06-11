import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../audio/record/mp_audio_upload_service.dart';
import '../audio/record/mp_flutter_sound_recorder_safe.dart';
import '../audio/record/mp_global_recording_coordinator.dart';
import '../audio/record/mp_recording_background_support.dart';
import '../generated/assets.dart';
import '../http/api/mp_chat.dart';
import '../http/schema/mp_chat.dart';
import '../permission/omi_microphone_manager.dart';
import '../utils/mp_time_utils.dart';
import '../utils/mp_toast_utils.dart';

/// 快捷添加 Todo 输入弹窗结果。
class OmiQuickAddTodoResult {
  const OmiQuickAddTodoResult({
    required this.text,
    this.todoId,
  });

  final String text;

  /// 打开弹窗时传入的已有 todo id（更新场景）；纯新建为 `null`。
  final String? todoId;
}

class OmiQuickInputPopupParams {
  const OmiQuickInputPopupParams({
    this.headerTitle = 'ADD TODO',
    this.hintText = 'What needs to be done?',
    this.todoId,
  });

  final String headerTitle;
  final String hintText;

  /// 若已有服务端 todo id，提交时走 update；否则走 create。
  final String? todoId;
}

/// 打开底部「Add Todo」快捷输入弹窗。
Future<OmiQuickAddTodoResult?> showOmiQuickAddTodoPopup(
  BuildContext context, {
  OmiQuickInputPopupParams params = const OmiQuickInputPopupParams(),
}) {
  return showModalBottomSheet<OmiQuickAddTodoResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return _OmiQuickAddTodoSheet(params: params);
    },
  );
}

class _OmiQuickAddTodoSheet extends StatefulWidget {
  const _OmiQuickAddTodoSheet({required this.params});

  final OmiQuickInputPopupParams params;

  @override
  State<_OmiQuickAddTodoSheet> createState() => _OmiQuickAddTodoSheetState();
}

class _OmiQuickAddTodoSheetState extends State<_OmiQuickAddTodoSheet> {
  static const String _kRecordDirName = 'omi_quick_add_input_records';

  static const int _kMaxVisibleLines = 8;

  static const double _kTextLineHeight = 1.25;

  static final double _kTextFontSize = OmiFontSize.t6_15;

  static const double _kFieldContentPaddingVertical = 16;

  static const double _kInputVerticalPadding = 8;

  static const double _kSideButtonSize = 40;

  static double get _minTextFieldHeight =>
      _kTextFontSize * _kTextLineHeight + _kFieldContentPaddingVertical;

  static double get _minInputHeight =>
      math.max(_kSideButtonSize, _minTextFieldHeight) + _kInputVerticalPadding;

  /// 全局录音仲裁持有者标识。
  late final Object _recordingOwnerToken;

  /// 被其它入口抢占麦克风后的暂停态。
  bool _recordingExternallyPaused = false;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _textScrollController = ScrollController();
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isSubmitting = false;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderOpened = false;
  String? _recordPath;

  @override
  void initState() {
    super.initState();
    _recordingOwnerToken = Object();
    MPGlobalRecordingCoordinator.instance.register(
      _recordingOwnerToken,
      _onInterruptedByOtherOwner,
    );
  }

  @override
  void dispose() {
    unawaited(_stopRecorder(deleteFile: true));
    MPGlobalRecordingCoordinator.instance.unregister(_recordingOwnerToken);
    _controller.dispose();
    _focusNode.dispose();
    _textScrollController.dispose();
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
    if (deleteFile) {
      await MPAudioUploadService.deleteLocalRecordingArtifacts(_recordPath);
    }
    _recordPath = null;
    await MPRecordingBackgroundSupport.deactivateAfterRecording();
    MPGlobalRecordingCoordinator.instance
        .notifyRecordingSessionEnded(_recordingOwnerToken);
  }

  /// 其它场景独占录音：停止并关闭采集，释放麦克风给新入口。
  Future<void> _onInterruptedByOtherOwner() async {
    if (!_isRecording || !_recorderOpened) {
      return;
    }
    try {
      await _stopRecorder(deleteFile: true);
    } catch (_) {}
    if (!mounted) {
      return;
    }
    setState(() {
      _recordingExternallyPaused = false;
      _isRecording = false;
    });
    MPToastUtils.showMessage(
      'Voice recording stopped to allow another recording.',
    );
  }

  Future<void> _resumeRecordingAfterExternalPause() async {
    if (!_recordingExternallyPaused || _isTranscribing || _isSubmitting) {
      return;
    }
    try {
      await MPGlobalRecordingCoordinator.instance
          .beforeLocalRecordingStarts(_recordingOwnerToken);
      final bool resumed = await MPFlutterSoundRecorderSafe.resumeIfPaused(
        _recorder,
        recorderOpened: _recorderOpened,
      );
      if (!mounted) {
        return;
      }
      if (!resumed) {
        MPToastUtils.showMessage(
          'Couldn\'t resume recording. Stop and start again if the issue persists.',
        );
        if (mounted) {
          setState(() => _recordingExternallyPaused = false);
        }
        return;
      }
      setState(() => _recordingExternallyPaused = false);
    } catch (e) {
      if (mounted) {
        MPToastUtils.showMessage('Failed to resume recording: $e');
        setState(() => _recordingExternallyPaused = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSubmitting = true);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(
      OmiQuickAddTodoResult(text: text, todoId: widget.params.todoId),
    );
  }

  Future<void> _startRecording() async {
    if (_isSubmitting || _isTranscribing || _isRecording) {
      return;
    }
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();
    try {
      final bool hasPermission =
          await OmiMicrophoneManager.ensureMicrophonePermission();
      if (!hasPermission) {
        return;
      }
      await MPGlobalRecordingCoordinator.instance
          .beforeLocalRecordingStarts(_recordingOwnerToken);
      await MPRecordingBackgroundSupport.activateForRecording();
      final String dir = await _ensureRecordDirectory();
      final String path = p.join(
        dir,
        'omi_quick_add_${MPTimeUtils.nowUnixMilliseconds()}.aac',
      );
      await MPRecordingBackgroundSupport.openRecorderSafely(_recorder);
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
        _recordingExternallyPaused = false;
        _isRecording = true;
      });
    } catch (e) {
      await _stopRecorder(deleteFile: true);
      if (mounted) {
        MPToastUtils.showMessage('Failed to start recording: $e');
      }
    }
  }

  Future<void> _cancelRecording() async {
    await _stopRecorder(deleteFile: true);
    if (!mounted) {
      return;
    }
    setState(() {
      _recordingExternallyPaused = false;
      _isRecording = false;
    });
  }

  Future<void> _sendRecording() async {
    if (_isTranscribing) return;
    _recordingExternallyPaused = false;
    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });
    final String? transcribed = await _transcribeRecording();
    if (!mounted) return;
    if (transcribed != null && transcribed.trim().isNotEmpty) {
      _controller.text = transcribed.trim();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      setState(() {});
      _focusNode.requestFocus();
    }
    if (mounted) {
      setState(() {
        _isTranscribing = false;
      });
    }
  }

  /// 语音转文本：录音文件上传后调 `transcript`。
  Future<String?> _transcribeRecording() async {
    String? filePath = _recordPath;
    if (filePath == null || filePath.isEmpty) {
      MPToastUtils.showMessage('Invalid recording file.');
      await _stopRecorder(deleteFile: true);
      return null;
    }
    try {
      if (_recorderOpened) {
        filePath = await _recorder.stopRecorder() ?? filePath;
        await _recorder.closeRecorder();
        _recorderOpened = false;
      }
      await MPRecordingBackgroundSupport.deactivateAfterRecording();
    } catch (e) {
      MPToastUtils.showMessage('Failed to stop recording: $e');
      await _stopRecorder(deleteFile: true);
      return null;
    }

    if (filePath.isEmpty) {
      await _stopRecorder(deleteFile: true);
      return null;
    }
    final File file = File(filePath);
    if (!await file.exists()) {
      MPToastUtils.showMessage('Recording file not found.');
      await _stopRecorder(deleteFile: true);
      return null;
    }

    final String? recordUri = await MPAudioUploadService().uploadMPAudio(file);
    if (recordUri == null || recordUri.isEmpty) {
      MPToastUtils.showMessage('Failed to upload audio.');
      await _stopRecorder(deleteFile: true);
      return null;
    }

    final MPTranscriptResponse? transcriptResp = await transcript(
      MPTranscriptRequest(audioUrl: recordUri),
    );
    await _stopRecorder(deleteFile: true);

    if (transcriptResp == null || transcriptResp.baseResp.code != 0) {
      final String msg = transcriptResp?.baseResp.message.isNotEmpty == true
          ? transcriptResp!.baseResp.message
          : 'Voice-to-text failed.';
      MPToastUtils.showMessage(msg);
      return null;
    }

    final String text = transcriptResp.content.trim();
    if (text.isEmpty) {
      MPToastUtils.showMessage('No speech recognized.');
      return null;
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final double kb = MediaQuery.viewInsetsOf(context).bottom;
    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final bool canSubmit = _controller.text.trim().isNotEmpty;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: kb),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + safeBottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  widget.params.headerTitle,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t4_13,
                    fontWeight: OmiFontWeight.bold,
                    color: secondTextColor,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      'Cancel',
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t6_15,
                        fontWeight: OmiFontWeight.medium,
                        color: redColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isTranscribing)
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    const _TranscribingDots(),
                    const SizedBox(width: 10),
                    Text(
                      'Transcribing...',
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t7_16,
                        fontWeight: OmiFontWeight.regular,
                        color: secondTextColor,
                      ),
                    ),
                  ],
                ),
              )
            else if (_isRecording)
              Row(
                children: <Widget>[
                  _RoundIconButton(
                    assetIcon: Assets.omiClose,
                    bgColor: const Color(0xFFF2F2F7),
                    iconColor: mainTextColor,
                    onTap: () => _cancelRecording(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _recordingExternallyPaused
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _resumeRecordingAfterExternalPause,
                            child: Container(
                              height: 46,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'Paused — tap to resume',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: OmiTextStyle.create(
                                  fontSize: OmiFontSize.t6_15,
                                  fontWeight: OmiFontWeight.medium,
                                  color: secondTextColor,
                                ),
                              ),
                            ),
                          )
                        : const _RecordingWaveform(),
                  ),
                  const SizedBox(width: 8),
                  _RoundIconButton(
                    iconData: Icons.send_rounded,
                    bgColor: blueTextColor,
                    iconColor: Colors.white,
                    onTap: () {
                      _sendRecording();
                    },
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(minHeight: _minInputHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: blueTextColor, width: 2),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        scrollController: _textScrollController,
                        autofocus: true,
                        minLines: 1,
                        maxLines: _kMaxVisibleLines,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        scrollPhysics: const ClampingScrollPhysics(),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: InputBorder.none,
                          hintText: widget.params.hintText,
                          hintStyle: OmiTextStyle.create(
                            fontSize: OmiFontSize.t6_15,
                            color: secondTextColor,
                            height: _kTextLineHeight,
                          ),
                        ),
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t6_15,
                          color: mainTextColor,
                          height: _kTextLineHeight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RoundIconButton(
                    assetIcon: Assets.omiAudio,
                    bgColor: const Color(0xFFF2F2F7),
                    iconColor: secondTextColor,
                    onTap: _startRecording,
                  ),
                  const SizedBox(width: 8),
                  _RoundIconButton(
                    iconData: Icons.send_rounded,
                    bgColor: canSubmit
                        ? blueTextColor
                        : const Color(0xFFDCEAFF),
                    iconColor: Colors.white,
                    onTap: canSubmit ? _submit : null,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RecordingWaveform extends StatefulWidget {
  const _RecordingWaveform();

  @override
  State<_RecordingWaveform> createState() => _RecordingWaveformState();
}

class _RecordingWaveformState extends State<_RecordingWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const List<double> _baseHeights = <double>[
    22,
    18,
    24,
    20,
    23,
    15,
    19,
    14,
    21,
    16,
    20,
    15,
    18,
    14,
    19,
    16,
    13,
    17,
    15,
    19,
    14,
    20,
    16,
    22,
  ];

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
    _controller.dispose();
    super.dispose();
  }

  double _barHeight(int index) {
    final double t = _controller.value * 2 * math.pi;
    final double phase = index * 0.35;
    final double wobble = math.sin(t + phase) * 1.8;
    final double base = _baseHeights[index % _baseHeights.length];
    return (base + wobble).clamp(12, 26);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EAEA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(_baseHeights.length, (int index) {
              final Color c = index.isEven
                  ? blueTextColor
                  : blueTextColor.withValues(alpha: 0.55);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.8),
                child: Container(
                  width: 4.2,
                  height: _barHeight(index),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _TranscribingDots extends StatefulWidget {
  const _TranscribingDots();

  @override
  State<_TranscribingDots> createState() => _TranscribingDotsState();
}

class _TranscribingDotsState extends State<_TranscribingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Row(
          children: List<Widget>.generate(3, (int index) {
            final double t = (_controller.value + index * 0.2) % 1.0;
            final double opacity = 0.3 + 0.7 * (1 - (t - 0.5).abs() * 2);
            return Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 4),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: blueTextColor.withValues(alpha: opacity),
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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    this.assetIcon,
    this.iconData,
    required this.bgColor,
    required this.iconColor,
    this.onTap,
  }) : assert(
          (assetIcon != null) != (iconData != null),
          'Provide exactly one of assetIcon or iconData',
        );

  final String? assetIcon;
  final IconData? iconData;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: iconData != null
                ? Icon(
                    iconData,
                    size: 18,
                    color: iconColor,
                  )
                : OmiImageLoader.localImg(
                    assetIcon!,
                    width: 18,
                    height: 18,
                    color: iconColor,
                  ),
          ),
        ),
      ),
    );
  }
}
