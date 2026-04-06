import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/common/mp_memory_options_sheet.dart';
import 'package:omi/common/mp_share_sheet.dart';
import 'package:omi/common/mp_custom_nav_bar.dart';
import 'package:omi/common/mp_tristate_page.dart';
import 'package:omi/common/omi_quick_add_todo_popup.dart';
import 'package:omi/common/mp_todo_manager.dart';
import 'package:omi/http/api/mp_memo.dart';
import 'package:omi/http/schema/mp_memo.dart';
import 'package:omi/tab/memory/detail/memo/omi_memo_detail_cubit.dart';
import 'package:omi/utils/mp_toast_utils.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_detail_content_card.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_detail_feed_section.dart';
import 'package:omi/tab/memory/detail/memory/card/mp_memory_detail_bottom_bar.dart';
import 'package:omi/tab/memory/detail/memory/omi_memory_detail_cubit.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_image_loader.dart';

import '../../../../generated/assets.dart';
import '../../../askai/mp_ask_ai_chat_page.dart';

/// Memo 详情页：与 Memory 详情共用 [OmiMemoryDetailState] / UI，由 [OmiMemoDetailCubit] 使用根级 `summary_memory` 映射数据。
/// 区别：
/// 1. 主卡片不带背景色；
/// 2. Segment 下内容与页面主滚动保持同一滚动容器。
class OmiMemoDetailPage extends StatelessWidget {
  const OmiMemoDetailPage({super.key, required this.memoryId});

  /// 与列表项 [MPMemoryEntry.id] 一致，用于详情接口。
  final String memoryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OmiMemoryDetailCubit>(
      create: (_) => OmiMemoDetailCubit(memoryId: memoryId)..initData(),
      child: const _OmiMemoDetailView(),
    );
  }
}

class _OmiMemoDetailView extends StatelessWidget {
  const _OmiMemoDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: PreferredSize(
        preferredSize: MPCustomNavBar.preferredSizeOf(context),
        child: MPCustomNavBar(
          title: 'Memo',
          actions: <Widget>[
            GestureDetector(
              onTap: () async {
                final MPShareSheetResult? result = await showMPShareSheet(
                  context,
                );
                if (result == null) return;
                // TODO: 根据 result.summaryOptionId 与 result.additionalContent 执行分享
              },
              child: OmiImageLoader.localImg(
                Assets.omiShare,
                width: 20,
                height: 20,
                color: blueTextColor,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () async {
                final MPMemoryOptionKind? kind = await showMPMemoryOptionsSheet(
                  context,
                  params: const MPMemoryOptionsSheetParams(),
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
              child: OmiImageLoader.localImg(
                Assets.omiMemoryDetialMore,
                width: 20,
                height: 20,
                color: blueTextColor,
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
                  title: 'Unable to load memo detail',
                  description: state.errorMessage ?? '请稍后重试',
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
                        showBackground: false,
                        segmentBodyScrollWithParent: true,
                        cardType: MPMemoryDetailCardType.memo,
                        onSegmentChanged: (MPMemoryDetailSegment s) {},
                        onPlayTap: () {
                          context.read<OmiMemoryDetailCubit>().onPlayTap();
                        },
                      ),
                    ),
                    MPMemoryDetailFeedSection(data: data),
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
            MPCreateMemoWithTextRequest(
              content: line,
              createAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            ),
          );
          if (!context.mounted) return;
          if (resp == null || resp.baseResp.code != 0) {
            MPToastUtils.showMessage(
              resp?.baseResp.message ?? '创建 Memo 失败，请稍后重试',
            );
            return;
          }
          context.read<OmiMemoryDetailCubit>().addMemoFromQuickInput(line);
        },
        onAskAi: () {
          final OmiMemoryDetailState s =
              context.read<OmiMemoryDetailCubit>().state;
          if (s.phase != OmiMemoryDetailPhase.loaded || s.data == null) {
            return;
          }
          final String aboutText = s.data!.title.trim().isEmpty
              ? 'Memo'
              : s.data!.title;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MPAskAIChatPage(
                aboutText: aboutText,
                suggestedQuestions: const <String>[],
              ),
            ),
          );
        },
      ),
    );
  }
}
