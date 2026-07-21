import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/common/mp_memory_notification.dart';
import 'package:memo_pin/common/mp_route_observer.dart';
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
  const OmiAllPage({
    super.key,
    this.refreshListenable,
    this.onStartRecording,
  });

  /// 父级在「列表应从隐藏变为可见」或「底部切回 Memory 且仍为 All」时递增计数；此处触发与下拉刷新相同的 [RefreshIndicator] 流程。
  final ValueNotifier<int>? refreshListenable;

  final Future<void> Function()? onStartRecording;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OmiAllCubit()..initData(),
      child: _OmiAllView(
        refreshListenable: refreshListenable,
        onStartRecording: onStartRecording,
      ),
    );
  }
}

class _OmiAllView extends StatefulWidget {
  const _OmiAllView({
    this.refreshListenable,
    this.onStartRecording,
  });

  final ValueNotifier<int>? refreshListenable;

  final Future<void> Function()? onStartRecording;

  @override
  State<_OmiAllView> createState() => _OmiAllViewState();
}

class _OmiAllViewState extends State<_OmiAllView> with RouteAware {
  final ScrollController _scrollController = ScrollController();

  /// 与 [RefreshIndicator] 绑定，用于在 Tab 切回 / 自详情返回等场景**按「下拉刷新」同一路径**拉数（[OmiAllCubit.load]）。
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  StreamSubscription<void>? _memoryListRefreshSub;

  /// 在已展示可下拉列表时走 [RefreshIndicatorState.show]；否则（三态/空列表等）退化为直接 [OmiAllCubit.load]。
  void _requestRefreshAsPullDown() {
    if (!mounted) {
      return;
    }
    final OmiAllCubit cubit = context.read<OmiAllCubit>();
    final OmiAllState s = cubit.state;
    if (s.phase == OmiAllPhase.loaded && s.items.isNotEmpty) {
      final RefreshIndicatorState? ri = _refreshIndicatorKey.currentState;
      if (ri != null) {
        unawaited(ri.show());
        return;
      }
    }
    unawaited(
      cubit.load().whenComplete(_jumpListToTopSilently),
    );
  }

  /// 刷新后列表已更新时在下一帧滚回顶部，避免与本轮 layout 冲突；无 [ScrollPosition]（三态页等）则跳过。
  void _jumpListToTopSilently() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(0);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      mpRouteObserver.subscribe(this, route);
    }
  }

  /// 自列表页 push 的详情等全屏路由 pop 后，列表需重新拉取（底部 Tab / 顶部分段未变时此前不会触发刷新）。
  @override
  void didPopNext() {
    _requestRefreshAsPullDown();
  }

  @override
  void initState() {
    super.initState();
    widget.refreshListenable?.addListener(_requestRefreshAsPullDown);
    _scrollController.addListener(_onScroll);
    _memoryListRefreshSub = MPMemoryNotification.listenMemoryListRefresh(() {
      if (!mounted) {
        return;
      }
      _requestRefreshAsPullDown();
    });
  }

  @override
  void didUpdateWidget(_OmiAllView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshListenable != widget.refreshListenable) {
      oldWidget.refreshListenable?.removeListener(_requestRefreshAsPullDown);
      widget.refreshListenable?.addListener(_requestRefreshAsPullDown);
    }
  }

  @override
  void dispose() {
    mpRouteObserver.unsubscribe(this);
    widget.refreshListenable?.removeListener(_requestRefreshAsPullDown);
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

  /// Tab 切回触发 [OmiAllCubit.load] 后首屏往往不足一屏高度，[maxScrollExtent]==0 时 [_onScroll] 永远不会触发 [loadMore]。
  /// 在新帧检查：仍无可滚动区域且仍有下一页时自动拉取，直到能滚动或没有更多。
  void _schedulePrefetchUntilScrollable({int depth = 0}) {
    if (depth > 24) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final OmiAllCubit cubit = context.read<OmiAllCubit>();
      final OmiAllState state = cubit.state;
      if (state.phase != OmiAllPhase.loaded || !state.hasMore || state.isLoadingMore) {
        return;
      }
      if (!_scrollController.hasClients) {
        _schedulePrefetchUntilScrollable(depth: depth);
        return;
      }
      final ScrollPosition pos = _scrollController.position;
      if (pos.maxScrollExtent > 0) {
        return;
      }
      unawaited(
        cubit.loadMore().whenComplete(() {
          if (mounted) {
            _schedulePrefetchUntilScrollable(depth: depth + 1);
          }
        }),
      );
    });
  }

  Future<void> _onRefresh() async {
    await context.read<OmiAllCubit>().load();
    _jumpListToTopSilently();
  }

  Future<void> _startRecording() async {
    final Future<void> Function()? onStartRecording = widget.onStartRecording;
    if (onStartRecording != null) {
      await onStartRecording();
      return;
    }
    await showMPAudioRecordPopup(context);
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
    return BlocListener<OmiAllCubit, OmiAllState>(
      listenWhen: (OmiAllState previous, OmiAllState current) {
        if (current.phase != OmiAllPhase.loaded || !current.hasMore || current.isLoadingMore) {
          return false;
        }
        return previous.items != current.items ||
            previous.phase != current.phase ||
            previous.hasMore != current.hasMore ||
            previous.isLoadingMore != current.isLoadingMore;
      },
      listener: (BuildContext context, OmiAllState state) {
        _schedulePrefetchUntilScrollable();
      },
      child: BlocBuilder<OmiAllCubit, OmiAllState>(
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
                onButtonPressed: _startRecording,
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
                description: state.errorMessage ?? 'Please try again later.',
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
                  onButtonPressed: _startRecording,
                ),
              );
            }
            return RefreshIndicator(
              key: _refreshIndicatorKey,
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
    ),
    );
  }
}
