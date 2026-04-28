import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/common/mp_confirm_delete_dialog.dart';
import 'package:memo_pin/common/mp_memory_options_sheet.dart';
import 'package:memo_pin/common/mp_memory_update_name_dialog.dart';
import 'package:memo_pin/common/mp_share_export_sheet.dart';
import 'package:memo_pin/common/mp_share_sheet.dart';
import 'package:memo_pin/common/omi_quick_add_todo_popup.dart';
import 'package:memo_pin/common/mp_share_options_manager.dart';
import 'package:memo_pin/common/mp_todo_manager.dart';
import 'package:memo_pin/common/mp_tristate_page.dart';
import 'package:memo_pin/common/mp_custom_nav_bar.dart';
import 'package:memo_pin/common/mp_memory_notification.dart';
import 'package:memo_pin/http/api/mp_memo.dart';
import 'package:memo_pin/http/api/mp_memory.dart';
import 'package:memo_pin/http/schema/mp_memo.dart';
import 'package:memo_pin/http/schema/mp_memory.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';

import '../../../../common/mp_memory_share_dialog.dart';
import '../../../../generated/assets.dart';
import '../../../askai/mp_ask_ai_chat_page.dart';
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
      child: _OmiMemoryDetailView(memoryId: memoryId),
    );
  }
}

class _OmiMemoryDetailView extends StatelessWidget {
  const _OmiMemoryDetailView({required this.memoryId});

  final String memoryId;

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
                final MPShareSheetParams params =
                    await MPShareOptionsManager.instance.getShareSheetParams(
                  memoryId: memoryId,
                );

                if (!context.mounted) return;
                final MPShareSheetResult? result = await showMPShareSheet(
                  context,
                  params: params,
                  onShare: () {
                    showMPShareExportSheet(context).then((MPShareExportKind? kind) {
                      if (kind == null) return;
                      if (!context.mounted) return;
                      if (kind == MPShareExportKind.link) {
                        MPShareMemoryDialog.show(context: context, memoryId: memoryId);
                      } else {
                        MPToastUtils.showFeatureComingSoon();
                      }
                    });
                  },
                );
                if (result == null) return;
              },
              child: Container(
                child: OmiImageLoader.localImg(Assets.omiShare, width: 20, height: 20, color: blueTextColor),
              ),
            ),
            SizedBox(width: 16.0),
            GestureDetector(
              onTap: () async {
                final MPMemoryOptionKind? kind = await showMPMemoryOptionsSheet(
                  context,
                  params: MPMemoryOptionsSheetParams(manageProjectsCount: 1, memoryId: memoryId),
                );
                if (kind == null) return;
                if (!context.mounted) return;
                switch (kind) {
                  case MPMemoryOptionKind.manageProjects:
                    // TODO: Manage projects
                    break;
                  case MPMemoryOptionKind.editTitle:
                    final OmiMemoryDetailCubit cubit = context.read<OmiMemoryDetailCubit>();
                    final OmiMemoryDetailState s = cubit.state;
                    if (s.phase != OmiMemoryDetailPhase.loaded || s.data == null) {
                      MPToastUtils.showMessage('请等待加载完成');
                      break;
                    }
                    MPMemoryUpdateNameDialog.show(
                      context: context,
                      memoryId: memoryId,
                      currentTitle: s.data!.title,
                      onSuccess: (String t) {
                        cubit.updateTitle(t);
                        MPMemoryNotification.notifyMemoryTitleUpdated(
                          memoryId: memoryId,
                          title: t,
                        );
                      },
                    );
                    break;
                  case MPMemoryOptionKind.modifyDate:
                    // TODO: Modify date
                    break;
                  case MPMemoryOptionKind.delete:
                    final bool ok = await showMPConfirmDeleteDialog(
                    context,
                    params: const MPConfirmDeleteDialogParams(
                      title: 'Delete Memory',
                      messageLine1: 'Are you sure you want to delete this memory?',
                      messageLine2: 'This action cannot be undone.',
                      cancelText: 'No, Keep',
                      confirmText: 'Yes, Delete',
                    ),
                  );
                  if (!context.mounted) return;
                  if (!ok) return;

                  final MPDeleteMemoryResponse? resp = await deleteMemory(
                    MPDeleteMemoryRequest(memoryId: memoryId),
                  );
                  if (!context.mounted) return;
                  if (resp == null || resp.baseResp.code != 0) {
                    MPToastUtils.showMessage(
                      resp?.baseResp.message ?? '删除失败，请稍后重试',
                    );
                    return;
                  }

                  MPMemoryNotification.notifyMemoryDeleted(memoryId);
                  Navigator.of(context).pop();
                    break;
                }
              },
              child: Container(
                child: OmiImageLoader.localImg(Assets.omiMemoryDetialMore, width: 20, height: 20, color: blueTextColor),
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
                            useExternalPlaybackProgress: true,
                            onSegmentChanged: (MPMemoryDetailSegment s) {},
                            onPlayTap: () => context.read<OmiMemoryDetailCubit>().onPlayTap(),
                          ),
                        ),
                        MPMemoryDetailFeedSection(data: data),
                        if (state.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.only(top: 16, bottom: 8),
                            child: Center(
                              child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)),
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
          final OmiQuickAddTodoResult? result = await showOmiQuickAddTodoPopup(context);
          if (result == null) return;
          if (!context.mounted) return;
          final String line = result.text.trim();
          if (line.isEmpty) return;
          final bool ok = await MPTodoManager().createTodo(title: line);
          if (!context.mounted) return;
          if (!ok) {
            MPToastUtils.showMessage('创建 Todo 失败，请稍后重试');
            return;
          }
          context.read<OmiMemoryDetailCubit>().addTodoFromQuickInput(line);
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
          final String line = result.text.trim();
          if (line.isEmpty) return;
          if (!context.mounted) return;
          final MPCreateMemoWithTextResponse? resp = await createMemoWithText(
            MPCreateMemoWithTextRequest(content: line, createAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
          );
          if (!context.mounted) return;
          if (resp == null || resp.baseResp.code != 0) {
            MPToastUtils.showMessage(resp?.baseResp.message ?? '创建 Memo 失败，请稍后重试');
            return;
          }
          context.read<OmiMemoryDetailCubit>().addMemoFromQuickInput(line);
        },
        onAskAi: () {
          final OmiMemoryDetailState s = context.read<OmiMemoryDetailCubit>().state;
          if (s.phase != OmiMemoryDetailPhase.loaded || s.data == null) {
            return;
          }
          final String aboutText = s.data!.title.trim().isEmpty ? 'Memory' : s.data!.title;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MPAskAIChatPage(aboutText: aboutText, suggestedQuestions: const <String>[]),
            ),
          );
        },
      ),
    );
  }
}
