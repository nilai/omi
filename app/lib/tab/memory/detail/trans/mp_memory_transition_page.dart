import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../http/schema/mp_data_model.dart';
import '../../../../utils/omi_color_utils.dart';
import '../../../../utils/omi_font_utils.dart';
import '../memory/omi_memory_detail_page.dart';
import 'mp_memory_transition_cubit.dart';

/// 记忆总结过渡页（Cubit 版）。
class MPMemoryTransitionBlocPage extends StatelessWidget {
  const MPMemoryTransitionBlocPage({
    super.key,
    required this.memory,
  });

  final MPMemoryStruct memory;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPMemoryTransitionCubit>(
      create: (_) => MPMemoryTransitionCubit(memoryId: memory.id)..startPolling(),
      child: _MPMemoryTransitionView(memory: memory),
    );
  }
}

class _MPMemoryTransitionView extends StatefulWidget {
  const _MPMemoryTransitionView({required this.memory});

  final MPMemoryStruct memory;

  @override
  State<_MPMemoryTransitionView> createState() => _MPMemoryTransitionViewState();
}

class _MPMemoryTransitionViewState extends State<_MPMemoryTransitionView> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MPMemoryTransitionCubit, MPMemoryTransitionState>(
      listener: (BuildContext context, MPMemoryTransitionState state) {
        if (state.phase != MPMemoryTransitionPhase.completed) {
          return;
        }
        Future<void>.delayed(const Duration(milliseconds: 500), () {
          if (!context.mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => OmiMemoryDetailPage(memoryId: widget.memory.id),
            ),
          );
        });
      },
      builder: (BuildContext context, MPMemoryTransitionState state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('总结中'),
            backgroundColor: Colors.white,
            foregroundColor: mainTextColor,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildTimestamp(widget.memory.createAt),
                          const SizedBox(height: 24),
                          _buildSkeletonPlaceholder(),
                          const SizedBox(height: 48),
                          _buildGeneratingMessage(),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomGradient(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 时间戳格式：自动兼容秒/毫秒。
  ///
  /// @param {int} ts
  /// @returns {Widget}
  Widget _buildTimestamp(int ts) {
    final DateTime dt = ts > 10000000000
        ? DateTime.fromMillisecondsSinceEpoch(ts)
        : DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final String dateText = DateFormat('MMM d, y, h:mm a').format(dt);
    return Text(
      dateText,
      style: TextStyle(
        fontSize: OmiFontSize.t16_25,
        fontWeight: FontWeight.bold,
        color: mainTextColor,
      ),
    );
  }

  Widget _buildSkeletonPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 120,
          height: 16,
          decoration: BoxDecoration(
            color: lineColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        ...List<Widget>.generate(
          3,
          (int index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratingMessage() {
    return Center(
      child: Column(
        children: <Widget>[
          Text(
            '生成中',
            style: TextStyle(
              fontSize: OmiFontSize.t7_16,
              fontWeight: FontWeight.w500,
              color: mainTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '生成还需几分钟，离开页面不会影响进度。',
            style: TextStyle(
              fontSize: OmiFontSize.t5_14,
              color: secondTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const _MPAnimatedDotsText(
            baseText: '.',
            style: TextStyle(
              fontSize: 20,
              color: secondTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomGradient() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFF9FAFB),
            Color(0xFFE0F2FE),
          ],
        ),
      ),
    );
  }
}

class _MPAnimatedDotsText extends StatefulWidget {
  const _MPAnimatedDotsText({
    required this.baseText,
    required this.style,
  });

  final String baseText;
  final TextStyle style;

  @override
  State<_MPAnimatedDotsText> createState() => _MPAnimatedDotsTextState();
}

class _MPAnimatedDotsTextState extends State<_MPAnimatedDotsText> {
  static const int _maxDots = 3;
  static const Duration _tick = Duration(milliseconds: 500);

  late final Timer _timer;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      setState(() {
        _dotCount = (_dotCount + 1) % (_maxDots + 1);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String dots = List<String>.filled(_dotCount, widget.baseText).join();
    return Text(
      dots,
      style: widget.style,
    );
  }
}
