import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:omi/common/mp_todo_manager.dart';
import 'package:omi/utils/mp_toast_utils.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_image_loader.dart';
import 'package:omi/utils/omi_textstyle.dart';

import '../generated/assets.dart';

/// 快捷添加 Todo 输入弹窗结果。
class OmiQuickAddTodoResult {
  const OmiQuickAddTodoResult({required this.text});

  final String text;
}

class OmiQuickInputPopupParams {
  const OmiQuickInputPopupParams({
    this.headerTitle = 'ADD TODO',
    this.hintText = 'What needs to be done?',
  });

  final String headerTitle;
  final String hintText;
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
  final TextEditingController _controller = TextEditingController();
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSubmitting = true);
    final bool ok = await MPTodoManager().createTodo(
      title: text,
      priority: 'normal',
      deadline: '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
    );
    if (!mounted) {
      return;
    }
    if (!ok) {
      setState(() => _isSubmitting = false);
      MPToastUtils.showMessage('创建失败');
      return;
    }
    Navigator.of(context).pop(OmiQuickAddTodoResult(text: text));
  }

  /// 开始语音录制（录音实现后续接入）。
  void _startRecording() {
    FocusScope.of(context).unfocus();
    setState(() => _isRecording = true);
    // TODO: 接入录音开始逻辑
  }

  /// 取消语音录制（录音实现后续接入）。
  void _cancelRecording() {
    setState(() => _isRecording = false);
    // TODO: 接入录音取消逻辑
  }

  /// 发送语音录制结果（录音转文本后续接入）。
  Future<void> _sendRecording() async {
    if (_isTranscribing) return;
    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });
    final String transcribed = await _transcribeRecording();
    if (!mounted) return;
    _controller.text = transcribed;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    setState(() {
      _isTranscribing = false;
    });
  }

  /// 语音转文本（占位实现，后续替换真实接口）。
  Future<String> _transcribeRecording() async {
    // TODO: 接入真实转写接口
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    return 'Need to confirm timeline with infra team';
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
                    icon: Assets.omiClose,
                    bgColor: const Color(0xFFF2F2F7),
                    iconColor: mainTextColor,
                    onTap: _cancelRecording,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: _RecordingWaveform()),
                  const SizedBox(width: 8),
                  _RoundIconButton(
                    icon: Assets.omiDetailMessage,
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
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: blueTextColor, width: 2),
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: widget.params.hintText,
                          hintStyle: OmiTextStyle.create(
                            fontSize: OmiFontSize.t6_15,
                            color: secondTextColor,
                          ),
                        ),
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t6_15,
                          color: mainTextColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RoundIconButton(
                    icon: Assets.omiAudio,
                    bgColor: const Color(0xFFF2F2F7),
                    iconColor: secondTextColor,
                    onTap: _startRecording,
                  ),
                  const SizedBox(width: 8),
                  _RoundIconButton(
                    icon: Assets.omiDetailMessage,
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
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.onTap,
  });

  final String icon;
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
            child: OmiImageLoader.localImg(
              icon,
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
