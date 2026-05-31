import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/common/mp_memory_options_sheet.dart';
import 'package:memo_pin/common/mp_memory_update_name_dialog.dart';
import 'package:memo_pin/common/mp_share_export_sheet.dart';
import 'package:memo_pin/common/mp_share_sheet.dart';
import 'package:memo_pin/common/mp_custom_nav_bar.dart';
import 'package:memo_pin/common/mp_tristate_page.dart';
import 'package:memo_pin/common/omi_quick_add_todo_popup.dart';
import 'package:memo_pin/common/mp_todo_manager.dart';
import 'package:memo_pin/common/mp_share_options_manager.dart';
import 'package:memo_pin/common/mp_memory_notification.dart';
import 'package:memo_pin/http/api/mp_memo.dart';
import 'package:memo_pin/http/api/mp_memory.dart';
import 'package:memo_pin/http/schema/mp_memo.dart';
import 'package:memo_pin/http/schema/mp_memory.dart';
import 'package:memo_pin/tab/memory/detail/memo/omi_memo_detail_cubit.dart';
import 'package:memo_pin/utils/mp_time_utils.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_detail_content_card.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_detail_bottom_bar.dart';
import 'package:memo_pin/tab/memory/detail/memory/card/mp_memory_summary_generating_panel.dart';
import 'package:memo_pin/tab/memory/detail/memory/omi_memory_detail_cubit.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';

import '../../../../common/mp_memory_share_dialog.dart';
import '../../../../generated/assets.dart';
import '../../../../http/api/mp_chat.dart';
import '../../../../http/schema/mp_chat.dart';
import '../../../../main.dart';
import '../../../askai/mp_ask_ai_chat_page.dart';
import '../mp_detail_visibility_refresh.dart';

/// Memo 详情页：与 Memory 详情共用 [OmiMemoryDetailState] / UI，由 [OmiMemoDetailCubit] 使用根级 `summary_memory` 映射数据。
/// 区别：
/// 1. 主卡片不带背景色；仅 Actions 分段内每条跟进卡片为白底；
/// 2. Segment 下内容与页面主滚动保持同一滚动容器；
/// 3. 不展示主卡片下方 Feed（Todo / Memo 等卡片）；底部 Add Todo / Add Memo 仅提交接口，不追加本地卡片。
class OmiMemoDetailPage extends StatelessWidget {
  const OmiMemoDetailPage({super.key, required this.memoryId});

  /// 与列表项 [MPMemoryEntry.id] 一致，用于详情接口。
  final String memoryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OmiMemoryDetailCubit>(
      create: (_) => OmiMemoDetailCubit(memoryId: memoryId)..initData(),
      child: _OmiMemoDetailView(memoryId: memoryId),
    );
  }
}

class _OmiMemoDetailView extends StatefulWidget {
  const _OmiMemoDetailView({required this.memoryId});

  final String memoryId;

  @override
  State<_OmiMemoDetailView> createState() => _OmiMemoDetailViewState();
}

class _OmiMemoDetailViewState extends State<_OmiMemoDetailView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (!mounted) {
        return;
      }
      context.read<OmiMemoryDetailCubit>().pauseAudioOnAppBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String memoryId = widget.memoryId;
    return MPDetailVisibilityRefresh(
      onRefresh: () => context.read<OmiMemoryDetailCubit>().refresh(),
      child: BlocBuilder<OmiMemoryDetailCubit, OmiMemoryDetailState>(
        builder: (BuildContext context, OmiMemoryDetailState pageState) {
          final bool hideBottomBar =
              pageState.phase == OmiMemoryDetailPhase.loaded &&
                  pageState.isSummaryGenerating;
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
                  onShare: ({
                    required String summaryOptionId,
                    required Set<String> optionalOptionIds,
                  }) {
                    showMPShareExportSheet(context).then((MPShareExportKind? kind) async{
                      if (kind == null) return;
                      if (!context.mounted) return;
                      if (kind == MPShareExportKind.link) {
                        final MPShareMemoryResponse? resp = await shareMemory(MPShareMemoryRequest(memoryId: memoryId));
                        if (!context.mounted) return;
                        MPShareMemoryDialog.show(context: context, url: resp?.shareUrl ?? '');
                      } else {
                        MPToastUtils.showFeatureComingSoon();
                      }
                    });
                  },
                );
                if (result == null) return;
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
                  params: MPMemoryOptionsSheetParams(memoryId: memoryId),
                );
                if (kind == null) return;
                if (!context.mounted) return;
                switch (kind) {
                  case MPMemoryOptionKind.manageProjects:
                    // TODO: Manage projects
                    break;
                  case MPMemoryOptionKind.editTitle:
                    final OmiMemoryDetailCubit cubit =
                        context.read<OmiMemoryDetailCubit>();
                    final OmiMemoryDetailState s = cubit.state;
                    if (s.phase != OmiMemoryDetailPhase.loaded ||
                        s.data == null) {
                      MPToastUtils.showMessage('Please wait until loading finishes.');
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
                    // [MPMemoryOptionsSheetParams.memoryId] 非空时，确认与 deleteMemory 已在 Sheet 内完成。
                    MPMemoryNotification.notifyMemoryDeleted(memoryId);
                    Navigator.of(context).pop();
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
      body: Builder(
        builder: (BuildContext context) {
          final OmiMemoryDetailState state = pageState;
          switch (state.phase) {
            case OmiMemoryDetailPhase.loading:
              return const MPTristatePage(type: MPTristateType.loading);
            case OmiMemoryDetailPhase.error:
              return MPTristatePage(
                type: MPTristateType.error,
                data: MPTristatePageData(
                  title: 'Unable to load memo detail',
                  description: 'Please try again later.',
                  onButtonPressed: () {
                    context.read<OmiMemoryDetailCubit>().retry();
                  },
                ),
              );
            case OmiMemoryDetailPhase.loaded:
              final MPMemoryDetailCardData data = state.data!;
              if (state.isSummaryGenerating) {
                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    child: MPSummaryGeneratingPanel(
                      headline: data.title.trim().isNotEmpty
                          ? data.title
                          : 'Memory',
                      metaLine: data.metaLine,
                    ),
                  ),
                );
              }
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
                        useExternalPlaybackProgress: true,
                        onSegmentChanged: (MPMemoryDetailSegment s) {},
                        onPlayTap: () =>
                            context.read<OmiMemoryDetailCubit>().onPlayTap(),
                        onSeekPlay: (Duration p) =>
                            context.read<OmiMemoryDetailCubit>().onSeekPlay(p),
                        onSeekWaveFraction: (double f) =>
                            context.read<OmiMemoryDetailCubit>().onSeekByWaveFraction(f),
                        isAudioPlaying: state.isAudioPlaying,
                      ),
                    ),
                  ],
                ),
              );
          }
        },
      ),
      bottomNavigationBar: hideBottomBar
          ? null
          : MPMemoryDetailBottomBar(
        onAddTodo: () async {
          final OmiQuickAddTodoResult? result = await showOmiQuickAddTodoPopup(
            context,
          );
          if (result == null) return;
          if (!context.mounted) return;
          final String line = result.text.trim();
          if (line.isEmpty) return;
          final bool ok = await MPTodoManager().createTodo(
            title: line,
            memoryId: memoryId,
          );
          if (!context.mounted) return;
          if (!ok) {
            MPToastUtils.showMessage('Couldn\'t create to-do. Please try again later.');
            return;
          }
          MPToastUtils.showMessage('To-do created.');
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
              memoryId: memoryId,
              createAt: MPTimeUtils.nowUnixSeconds(),
            ),
          );
          if (!context.mounted) return;
          if (resp == null || resp.baseResp.code != 0) {
            MPToastUtils.showMessage(
              resp?.baseResp.message ?? 'Couldn\'t create memo. Please try again later.',
            );
            return;
          }
          MPToastUtils.showMessage('Memo created.');
        },
        onAskAi: () async{
          final OmiMemoryDetailState s = context.read<OmiMemoryDetailCubit>().state;
          if (s.phase != OmiMemoryDetailPhase.loaded || s.data == null) {
            return;
          }
          final String aboutText = s.data!.title.trim().isEmpty ? 'Memo' : s.data!.title;
          final MPGetLastConversationResponse? lastConversation = await getLastConversation(MPGetLastConversationRequest(conversationType: 1, paramId: memoryId));
          final String conversationId = lastConversation?.conversationId ?? '';
          final BuildContext? targetContext = context.mounted ? context : MyApp.navigatorKey.currentContext;
          // ignore: use_build_context_synchronously
          Navigator.of(targetContext!).push(
            MaterialPageRoute<void>(
              builder: (_) => MPAskAIChatPage(aboutText: aboutText, suggestedQuestions: const <String>[], conversationId: conversationId, type: MPAskAIChatType.memory, chatTypeId: memoryId),
            ),
          );
        },
      ),
          );
        },
      ),
    );
  }
}
