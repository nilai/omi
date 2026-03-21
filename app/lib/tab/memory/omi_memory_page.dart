import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/common/mp_tristate_page.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_image_loader.dart';

import '../../assets.dart';
import 'mp_memory_cubit.dart';

/// Memory Tab：Cubit 管理状态；空/无网/错误用 [MPTristatePage]；列表用 [SingleChildScrollView]
class OmiMemoryPage extends StatelessWidget {
  const OmiMemoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MPMemoryCubit()..load(),
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
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: state.items
                        .map(
                          (String text) => ListTile(
                            title: Text(text),
                            subtitle: const Text('示例副标题'),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}
