import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

enum MPTodoVoiceInputMode { text, recording, transcribing }

class MPTodoVoiceInputResult {
  const MPTodoVoiceInputResult({required this.text, required this.fromVoice});

  final String text;
  final bool fromVoice;
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
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  MPTodoVoiceInputMode _mode = MPTodoVoiceInputMode.text;
  bool _busy = false;

  late final AnimationController _waveCtrl;
  late final AnimationController _dotsCtrl;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
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
    _waveCtrl.dispose();
    _dotsCtrl.dispose();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _hasText => _controller.text.trim().isNotEmpty;

  double get _cornerRadius => widget.showOutline ? 12.0 : 16.0;

  void _submitTyped() {
    final String t = _controller.text.trim();
    if (t.isEmpty) return;
    widget.onSubmitted?.call(MPTodoVoiceInputResult(text: t, fromVoice: false));
  }

  Future<void> _startRecording() async {
    if (_busy) return;
    _focusNode.unfocus();
    setState(() {
      _mode = MPTodoVoiceInputMode.recording;
    });
    _waveCtrl.repeat();
  }

  void _cancelRecording() {
    _waveCtrl.stop();
    setState(() {
      _mode = MPTodoVoiceInputMode.text;
    });
  }

  Future<void> _confirmRecording() async {
    if (_busy) return;
    _waveCtrl.stop();
    setState(() {
      _mode = MPTodoVoiceInputMode.transcribing;
      _busy = true;
    });
    _dotsCtrl.repeat();

    await Future<void>.delayed(widget.transcribeDelay);
    if (!mounted) return;
    _dotsCtrl.stop();

    // TODO: 替换真实录音 + 转写接口
    final String transcribed =
        "Review the new product roadmap and prepare feedback for tomorrow's meeting";
    _controller.text = transcribed;
    widget.onChanged?.call(transcribed);

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
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(_bars, (int i) {
            final double h = _barHeight(i, p);
            final bool strong = i > _bars * 0.6;
            return Padding(
              padding: EdgeInsets.only(right: i == _bars - 1 ? 0 : 4),
              child: Container(
                width: 3,
                height: h,
                decoration: BoxDecoration(
                  color: strong
                      ? blueTextColor
                      : blueTextColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
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
