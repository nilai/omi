import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/common/mp_memory_options_sheet.dart';
import 'package:omi/common/mp_share_sheet.dart';
import 'package:omi/common/omi_quick_add_todo_popup.dart';
import 'package:omi/common/mp_tristate_page.dart';
import 'package:omi/common/mp_custom_nav_bar.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_image_loader.dart';

import '../../../../generated/assets.dart';
import 'card/mp_memory_detail_content_card.dart';
import 'card/mp_memory_detail_feed_section.dart';
import 'card/mp_memory_detail_bottom_bar.dart';
import 'omi_memory_detail_cubit.dart';

/// Memory 详情页（顶部 [MPCustomNavBar]：返回 + 标题 + 分享 / 更多）
class OmiMemoryDetailPage extends StatelessWidget {
  const OmiMemoryDetailPage({super.key, required this.memoryId});

  /// 列表页传入的 memory id，用于拉取详情。
  final String memoryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OmiMemoryDetailCubit>(
      create: (_) => OmiMemoryDetailCubit(memoryId: memoryId)..initData(),
      child: const _OmiMemoryDetailView(),
    );
  }
}

class _OmiMemoryDetailView extends StatelessWidget {
  const _OmiMemoryDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: PreferredSize(
        preferredSize: MPCustomNavBar.preferredSizeOf(context),
        child: MPCustomNavBar(
          title: 'Memory',
          actions: <Widget>[
            GestureDetector(
              onTap: () async {
                final MPShareSheetResult? result = await showMPShareSheet(
                  context,
                );
                if (result == null) return;
                // TODO: 根据 result.summaryOptionId 与 result.additionalContent 执行分享
              },
              child: Container(
                child: OmiImageLoader.localImg(
                  Assets.omiShare,
                  width: 20,
                  height: 20,
                  color: blueTextColor,
                ),
              ),
            ),
            SizedBox(width: 16.0),
            GestureDetector(
              onTap: () async {
                final MPMemoryOptionKind? kind = await showMPMemoryOptionsSheet(
                  context,
                  params: const MPMemoryOptionsSheetParams(
                    manageProjectsCount: 1,
                  ),
                );
                if (kind == null) return;
                switch (kind) {
                  case MPMemoryOptionKind.manageProjects:
                    // TODO: Manage projects
                    break;
                  case MPMemoryOptionKind.editTitle:
                    // TODO: Edit title
                    break;
                  case MPMemoryOptionKind.modifyDate:
                    // TODO: Modify date
                    break;
                  case MPMemoryOptionKind.delete:
                    // TODO: Delete
                    break;
                }
              },
              child: Container(
                child: OmiImageLoader.localImg(
                  Assets.omiMemoryDetialMore,
                  width: 20,
                  height: 20,
                  color: blueTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<OmiMemoryDetailCubit, OmiMemoryDetailState>(
        builder: (BuildContext context, OmiMemoryDetailState state) {
          switch (state.phase) {
            case OmiMemoryDetailPhase.loading:
              return const MPTristatePage(type: MPTristateType.loading);
            case OmiMemoryDetailPhase.error:
              return MPTristatePage(
                type: MPTristateType.error,
                data: MPTristatePageData(
                  title: 'Unable to load memory detail',
                  description: state.errorMessage ?? 'Please try again',
                  onButtonPressed: () {
                    context.read<OmiMemoryDetailCubit>().retry();
                  },
                ),
              );
            case OmiMemoryDetailPhase.loaded:
              final MPMemoryDetailCardData data = state.data!;
              return RefreshIndicator(
                onRefresh: () => context.read<OmiMemoryDetailCubit>().refresh(),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification n) {
                    if (n.metrics.axis != Axis.vertical) {
                      return false;
                    }
                    if (n is! ScrollUpdateNotification) {
                      return false;
                    }
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 160) {
                      context.read<OmiMemoryDetailCubit>().loadMoreFeeds();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MPMemoryDetailContentCard(
                            data: data,
                            onSegmentChanged: (MPMemoryDetailSegment s) {},
                            onPlayTap: () {
                              context.read<OmiMemoryDetailCubit>().onPlayTap();
                            },
                          ),
                        ),
                        MPMemoryDetailFeedSection(data: data),
                        if (state.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.only(top: 16, bottom: 8),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
          }
        },
      ),
      bottomNavigationBar: MPMemoryDetailBottomBar(
        onAddTodo: () async {
          final OmiQuickAddTodoResult? result = await showOmiQuickAddTodoPopup(
            context,
          );
          if (result == null) return;
          context.read<OmiMemoryDetailCubit>().addTodoFromQuickInput(
            result.text,
          );
        },
        onAddMemo: () async {
          final OmiQuickAddTodoResult? result = await showOmiQuickAddTodoPopup(
            context,
            params: const OmiQuickInputPopupParams(
              headerTitle: 'ADD MEMO',
              hintText: 'What would you like to remember?',
            ),
          );
          if (result == null) return;
          context.read<OmiMemoryDetailCubit>().addMemoFromQuickInput(
            result.text,
          );
        },
        onAskAi: () {
          // TODO: Ask AI
        },
      ),
    );
  }
}
