import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/common/mp_tristate_page.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_image_loader.dart';

import '../../../assets.dart';
import 'card/mp_memory_card.dart';
import 'mp_memory_cubit.dart';

/// Memory Tab：Cubit 管理状态；空/无网/错误用 [MPTristatePage]；列表用 [SingleChildScrollView]
class OmiMemoryPage extends StatelessWidget {
  const OmiMemoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MPMemoryCubit()..initData(),
      child: const _OmiMemoryView(),
    );
  }
}

class _OmiMemoryView extends StatelessWidget {
  const _OmiMemoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记忆'),
      ),
      body: BlocBuilder<MPMemoryCubit, MPMemoryState>(
        builder: (BuildContext context, MPMemoryState state) {
          switch (state.phase) {
            case MPMemoryPhase.loading:
              return const MPTristatePage(type: MPTristateType.loading);
            case MPMemoryPhase.empty:
              return MPTristatePage(
                type: MPTristateType.empty,
                data: MPTristatePageData(
                  icon: OmiImageLoader.localImg(Assets.omiBrain, width: 60, height: 60, color: blueTextColor, fit: BoxFit.cover),
                  title: 'No memories yet',
                  description: 'Start recording to capture your first ideas and conversations.',
                  buttonText: 'Start Recording',
                  onButtonPressed: () {
                    context.read<MPMemoryCubit>().retry();
                  },
                ),
              );
            case MPMemoryPhase.noNetwork:
              return MPTristatePage(
                type: MPTristateType.noNetwork,
                data: MPTristatePageData(
                  title: 'Unable to load memories',
                  onButtonPressed: () {
                    context.read<MPMemoryCubit>().retry();
                  },
                ),
              );
            case MPMemoryPhase.error:
              return MPTristatePage(
                type: MPTristateType.error,
                data: MPTristatePageData(
                  title: 'Unable to load memories',
                  description: state.errorMessage ?? '请稍后重试',
                  onButtonPressed: () {
                    context.read<MPMemoryCubit>().retry();
                  },
                ),
              );
            case MPMemoryPhase.loaded:
              return RefreshIndicator(
                onRefresh: () => context.read<MPMemoryCubit>().load(),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification n) {
                    final ScrollMetrics m = n.metrics;
                    // 内容不足一屏不误触；下拉刷新顶部 overscroll 不误触
                    if (m.maxScrollExtent <= 0) return false;
                    if (m.pixels < 0) return false;
                    if (m.pixels < m.maxScrollExtent - 120) return false;
                    context.read<MPMemoryCubit>().loadMore();
                    return false;
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      for (int i = 0; i < state.items.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        MPMemoryCard(
                          variant: state.items[i].variant,
                          data: state.items[i].data,
                          onTap: () {},
                        ),
                      ],
                      if (state.isLoadingMore) ...[
                        const SizedBox(height: 16),
                        const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ],
                      if (!state.hasMore && state.items.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            '没有更多了',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}
