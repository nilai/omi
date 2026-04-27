import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../utils/omi_color_utils.dart';
import '../../../../common/mp_custom_nav_bar.dart';
import '../memory/omi_memory_detail_page.dart';
import '../memory/card/mp_memory_summary_generating_panel.dart';
import 'mp_memory_transition_cubit.dart';

/// 记忆总结过渡页（Cubit 版）。
class MPMemoryTransitionBlocPage extends StatelessWidget {
  const MPMemoryTransitionBlocPage({
    super.key,
    required this.memoryId,
    required this.createAt,
  });

  final String memoryId;
  final int createAt;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPMemoryTransitionCubit>(
      create: (_) => MPMemoryTransitionCubit(memoryId: memoryId)..startPolling(),
      child: _MPMemoryTransitionView(
        memoryId: memoryId,
        createAt: createAt,
      ),
    );
  }
}

class _MPMemoryTransitionView extends StatefulWidget {
  const _MPMemoryTransitionView({
    required this.memoryId,
    required this.createAt,
  });

  final String memoryId;
  final int createAt;

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
              builder: (_) => OmiMemoryDetailPage(memoryId: widget.memoryId),
            ),
          );
        });
      },
      builder: (BuildContext context, MPMemoryTransitionState state) {
        return Scaffold(
          backgroundColor: pageColor,
          appBar: PreferredSize(
            preferredSize: MPCustomNavBar.preferredSizeOf(context),
            child: const MPCustomNavBar(title: 'Audio Memory'),
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              child: MPSummaryGeneratingPanel(
                headline: _headlineFromCreateAt(widget.createAt),
                metaLine: _metaLineFromCreateAt(widget.createAt),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _headlineFromCreateAt(int ts) {
  final DateTime dt = ts > 10000000000
      ? DateTime.fromMillisecondsSinceEpoch(ts)
      : DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  return DateFormat('MMM d, y, h:mm a').format(dt);
}

String _metaLineFromCreateAt(int ts) {
  final DateTime dt = ts > 10000000000
      ? DateTime.fromMillisecondsSinceEpoch(ts)
      : DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  final String longDate =
      '${DateFormat('MMMM d, y').format(dt)} at ${DateFormat('h:mm a').format(dt)}';
  return '$longDate  ·  MemoPin';
}
