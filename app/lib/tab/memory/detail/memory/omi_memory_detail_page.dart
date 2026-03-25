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
import 'card/mp_memory_insight_card.dart';
import 'card/mp_memory_todos_created_card.dart';
import 'card/mp_memory_my_memos_card.dart';
import 'card/mp_memory_you_asked_card.dart';
import 'card/mp_memory_resummary_card.dart';
import 'card/mp_memory_detail_bottom_bar.dart';
import 'omi_memory_detail_cubit.dart';

/// Memory 详情页（顶部 [MPCustomNavBar]：返回 + 标题 + 分享 / 更多）
class OmiMemoryDetailPage extends StatelessWidget {
  const OmiMemoryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OmiMemoryDetailCubit()..initData(),
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
              return SingleChildScrollView(
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
                          // TODO: 播放
                        },
                      ),
                    ),
                    for (final MPMemoryInsightItemData item
                        in data.insightItems)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MPMemoryInsightCard(
                          data: item,
                          onReadMore: () {
                            // TODO: Insight 全文 / 展开
                          },
                          onAddFollowUpTodo: () {
                            // TODO: 创建 follow-up todo
                          },
                        ),
                      ),
                    if (data.todosCreated != null &&
                        data.todosCreated!.items.isNotEmpty) ...<Widget>[
                      if (data.insightItems.isEmpty) const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MPMemoryTodosCreatedCard(
                          data: data.todosCreated!,
                        ),
                      ),
                    ],
                    if (data.myMemos != null &&
                        data.myMemos!.lines.isNotEmpty) ...<Widget>[
                      if (data.insightItems.isEmpty &&
                          (data.todosCreated == null ||
                              data.todosCreated!.items.isEmpty))
                        const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MPMemoryMyMemosCard(data: data.myMemos!),
                      ),
                    ],
                    if (data.youAsked != null) ...<Widget>[
                      if (data.insightItems.isEmpty &&
                          (data.todosCreated == null ||
                              data.todosCreated!.items.isEmpty) &&
                          (data.myMemos == null || data.myMemos!.lines.isEmpty))
                        const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MPMemoryYouAskedCard(data: data.youAsked!),
                      ),
                    ],
                    if (data.resummaryItems.isNotEmpty) ...<Widget>[
                      if (data.insightItems.isEmpty &&
                          (data.todosCreated == null ||
                              data.todosCreated!.items.isEmpty) &&
                          (data.myMemos == null ||
                              data.myMemos!.lines.isEmpty) &&
                          data.youAsked == null)
                        const SizedBox(height: 12),
                      for (final MPMemoryResummaryCardData item
                          in data.resummaryItems)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MPMemoryResummaryCard(
                            data: item,
                            onExpansionChanged: (bool expanded) {
                              // TODO: 埋点 / 同步展开状态
                            },
                          ),
                        ),
                    ],
                  ],
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
