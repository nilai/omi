import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/common/mp_memory_notification.dart';
import 'package:memo_pin/common/mp_tristate_page.dart';
import 'package:memo_pin/tab/memory/detail/memo/omi_memo_detail_page.dart';
import 'package:memo_pin/tab/memory/detail/memory/omi_memory_detail_page.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';

import '../../../../audio/record/mp_audio_record_popup.dart';
import '../../../../generated/assets.dart';
import '../../../../http/schema/mp_data_model.dart';
import '../../detail/mp_memory_detail_helper.dart';
import 'card/mp_audio_recording_card.dart';
import 'card/mp_memo_group_card.dart';
import 'card/mp_memory_card.dart';
import 'omi_all_cubit.dart';

/// Memory「All」列表页（卡片列表 + 游标分页）
class OmiAllPage extends StatelessWidget {
  const OmiAllPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => OmiAllCubit()..initData(), child: const _OmiAllView());
  }
}

class _OmiAllView extends StatefulWidget {
  const _OmiAllView();

  @override
  State<_OmiAllView> createState() => _OmiAllViewState();
}

class _OmiAllViewState extends State<_OmiAllView> {
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<void>? _memoryListRefreshSub;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _memoryListRefreshSub = MPMemoryNotification.listenMemoryListRefresh(() {
      if (!mounted) {
        return;
      }
      context.read<OmiAllCubit>().load();
    });
  }

  @override
  void dispose() {
    _memoryListRefreshSub?.cancel();
    _memoryListRefreshSub = null;
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final ScrollPosition pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels < pos.maxScrollExtent - 200) return;

    final OmiAllCubit cubit = context.read<OmiAllCubit>();
    final OmiAllState state = cubit.state;
    if (state.phase != OmiAllPhase.loaded) return;
    if (state.isLoadingMore || !state.hasMore) return;

    cubit.loadMore();
  }

  Future<void> _onRefresh() async {
    await context.read<OmiAllCubit>().load();
  }

  /// 按 [MPMemoryEntry.kind] 区分跳转或埋点（示例：`[entry.id]` + `kind`）
  void _onMemoryEntryTap(BuildContext context, MPMemoryEntry entry) {
    switch (entry.type) {
      case MPMemoryType.onlyRecord:
        MPMemoryDetailPageHelper.navigateToDetailPage(
          context,
          entry.id,
          MPMemoryType.onlyRecord,
          title: entry.audioData?.primaryTimeLabel,
        );
        break;
      case MPMemoryType.summary:
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (BuildContext context) => OmiMemoDetailPage(memoryId: entry.id)));
        break;
      case MPMemoryType.memoryFeed:
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (BuildContext context) => OmiMemoryDetailPage(memoryId: entry.id)));
        break;
      case MPMemoryType.memoList:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OmiAllCubit, OmiAllState>(
      builder: (BuildContext context, OmiAllState state) {
        switch (state.phase) {
          case OmiAllPhase.loading:
            return const MPTristatePage(type: MPTristateType.loading);
          case OmiAllPhase.empty:
            return MPTristatePage(
              type: MPTristateType.empty,
              data: MPTristatePageData(
                icon: OmiImageLoader.localImg(
                  Assets.omiBrain,
                  width: 60,
                  height: 60,
                  color: blueTextColor,
                  fit: BoxFit.cover,
                ),
                title: 'No memories yet',
                description: 'Start recording to capture your first ideas and conversations.',
                buttonText: 'Start Recording',
                onButtonPressed: () async {
                  await showMPAudioRecordPopup(context);
                },
              ),
            );
          case OmiAllPhase.noNetwork:
            return MPTristatePage(
              type: MPTristateType.noNetwork,
              data: MPTristatePageData(
                title: 'Unable to load memories',
                onButtonPressed: () {
                  context.read<OmiAllCubit>().retry();
                },
              ),
            );
          case OmiAllPhase.error:
            return MPTristatePage(
              type: MPTristateType.error,
              data: MPTristatePageData(
                title: 'Unable to load memories',
                description: state.errorMessage ?? '请稍后重试',
                onButtonPressed: () {
                  context.read<OmiAllCubit>().retry();
                },
              ),
            );
          case OmiAllPhase.loaded:
            if (state.items.isEmpty) {
              return MPTristatePage(
                type: MPTristateType.empty,
                data: MPTristatePageData(
                  icon: OmiImageLoader.localImg(
                    Assets.omiBrain,
                    width: 60,
                    height: 60,
                    color: blueTextColor,
                    fit: BoxFit.cover,
                  ),
                  title: 'No memories yet',
                  description: 'Start recording to capture your first ideas and conversations.',
                  buttonText: 'Start Recording',
                  onButtonPressed: () async {
                    await showMPAudioRecordPopup(context);
                  },
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: state.items.length + (state.hasMore && state.isLoadingMore ? 1 : 0),
                itemBuilder: (BuildContext context, int index) {
                  if (index == state.items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    );
                  }
                  final MPMemoryEntry entry = state.items[index];
                  final Widget card = switch (entry.kind) {
                    MPMemoryEntryKind.conversation => MPMemoryCard(
                      variant: entry.variant!,
                      data: entry.data!,
                      onTap: () => _onMemoryEntryTap(context, entry),
                    ),
                    MPMemoryEntryKind.memoGroup => MPMemoGroupCard(
                      variant: entry.memoVariant!,
                      data: entry.memoData!,
                      onTap: () => _onMemoryEntryTap(context, entry),
                    ),
                    // 对应服务端 [MPMemoryType.onlyRecord]
                    MPMemoryEntryKind.audioRecording => MPAudioRecordingCard(
                      data: entry.audioData!,
                      memoryId: entry.id,
                      onTap: () => _onMemoryEntryTap(context, entry),
                    ),
                  };
                  return Padding(
                    padding: EdgeInsets.only(bottom: index < state.items.length - 1 ? 12 : 0),
                    child: card,
                  );
                },
              ),
            );
        }
      },
    );
  }
}
