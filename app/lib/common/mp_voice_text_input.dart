import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

enum MPVoiceTextInputMode { text, recording, transcribing }

class MPVoiceTextInputResult {
  const MPVoiceTextInputResult({required this.text, required this.fromVoice});

  final String text;
  final bool fromVoice;
}

class MPVoiceTextInput extends StatefulWidget {
  const MPVoiceTextInput({
    super.key,
    this.hintText = 'Ask about your memories…',
    this.initialText = '',
    this.onSubmitted,
    this.onChanged,
    this.transcribeDelay = const Duration(milliseconds: 1400),
    this.focusNode,
    this.autofocus = false,
  });

  final String hintText;
  final String initialText;
  final ValueChanged<MPVoiceTextInputResult>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Duration transcribeDelay;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<MPVoiceTextInput> createState() => _MPVoiceTextInputState();
}

class _MPVoiceTextInputState extends State<MPVoiceTextInput>
    with TickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;

  MPVoiceTextInputMode _mode = MPVoiceTextInputMode.text;
  bool _sending = false;

  late final AnimationController _waveCtrl;
  late final AnimationController _dotsCtrl;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
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
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  bool get _hasText => _controller.text.trim().isNotEmpty;

  Future<void> _startRecording() async {
    if (_sending) return;
    setState(() {
      _mode = MPVoiceTextInputMode.recording;
    });
    _focusNode.unfocus();
    _waveCtrl.repeat();
  }

  void _cancelRecording() {
    _waveCtrl.stop();
    if (!mounted) return;
    setState(() {
      _mode = MPVoiceTextInputMode.text;
    });
  }

  Future<void> _sendRecording() async {
    if (_sending) return;
    _waveCtrl.stop();
    setState(() {
      _mode = MPVoiceTextInputMode.transcribing;
      _sending = true;
    });
    _dotsCtrl.repeat();

    // TODO: 替换为真实录音 + 转写接口
    await Future<void>.delayed(widget.transcribeDelay);

    if (!mounted) return;
    _dotsCtrl.stop();
    final String transcribed =
        'What patterns should I pay attention to this week?';
    _controller.text = transcribed;
    widget.onChanged?.call(transcribed);
    setState(() {
      _mode = MPVoiceTextInputMode.text;
      _sending = false;
    });
    _focusNode.requestFocus();
  }

  void _submitText() {
    final String t = _controller.text.trim();
    if (t.isEmpty) return;
    widget.onSubmitted?.call(MPVoiceTextInputResult(text: t, fromVoice: false));
    _controller.clear();
    widget.onChanged?.call('');
    if (mounted) {
      setState(() {});
    }
    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Widget _buildIconCircle({
    required Widget child,
    required VoidCallback? onTap,
    required Color bg,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildTextMode() {
    return Container(
      height: 48,
      padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAEAEE)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onChanged: (String value) {
                if (mounted) {
                  setState(() {});
                }
                widget.onChanged?.call(value);
              },
              onSubmitted: (_) => _submitText(),
              style: OmiTextStyle.create(
                fontSize: OmiFontSize.t6_15,
                fontWeight: OmiFontWeight.regular,
                color: mainTextColor,
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
          _buildIconCircle(
            bg: const Color(0xFFF2F2F7),
            onTap: _startRecording,
            child: const Icon(
              Icons.mic_none_rounded,
              size: 20,
              color: secondTextColor,
            ),
          ),
          const SizedBox(width: 8),
          _buildIconCircle(
            bg: _hasText ? const Color(0xFF2E5E49) : const Color(0xFFB9C6BF),
            onTap: _hasText ? _submitText : null,
            child: const Icon(
              Icons.send_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingMode() {
    return Row(
      children: <Widget>[
        _buildIconCircle(
          bg: Colors.white,
          onTap: _cancelRecording,
          child: const Icon(
            Icons.close_rounded,
            size: 20,
            color: mainTextColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8E8E9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  'Recording…',
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t5_14,
                    fontWeight: OmiFontWeight.medium,
                    color: secondTextColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _MPMiniWaveform(controller: _waveCtrl)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildIconCircle(
          bg: blueTextColor,
          onTap: _sendRecording,
          child: const Icon(
            Icons.arrow_upward_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTranscribingMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Transcribing…',
          style: OmiTextStyle.create(
            fontSize: OmiFontSize.t5_14,
            fontWeight: OmiFontWeight.medium,
            color: secondTextColor,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: <Widget>[
              _MPDots(controller: _dotsCtrl),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Transcribing…',
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t6_15,
                    fontWeight: OmiFontWeight.medium,
                    color: secondTextColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
      case MPVoiceTextInputMode.text:
        return _buildTextMode();
      case MPVoiceTextInputMode.recording:
        return _buildRecordingMode();
      case MPVoiceTextInputMode.transcribing:
        return _buildTranscribingMode();
    }
  }
}

class _MPMiniWaveform extends StatelessWidget {
  const _MPMiniWaveform({required this.controller});

  final Animation<double> controller;

  static const int _bars = 18;

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
                final bool strong = i > _bars * 0.65;
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

class _MPDots extends StatelessWidget {
  const _MPDots({required this.controller});

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
