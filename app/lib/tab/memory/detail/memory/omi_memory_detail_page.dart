import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:memo_pin/utils/mp_time_utils.dart';
import 'package:memo_pin/http/api/mp_chat.dart';
import 'package:memo_pin/http/api/mp_memo.dart';
import 'package:memo_pin/http/api/mp_memory.dart';
import 'package:memo_pin/http/schema/mp_chat.dart';
import 'package:memo_pin/http/schema/mp_memo.dart';
import 'package:memo_pin/http/schema/mp_memory.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';

import '../../../../common/mp_memory_share_dialog.dart';
import '../../../../generated/assets.dart';
import '../../../../main.dart';
import '../../../askai/mp_ask_ai_chat_page.dart';
import '../mp_detail_generate_resummary.dart';
import '../mp_detail_visibility_refresh.dart';
import 'card/mp_memory_detail_content_card.dart';
import 'card/mp_memory_detail_feed_section.dart';
import 'card/mp_memory_detail_bottom_bar.dart';
import 'omi_memory_detail_cubit.dart';

Future<void> _openMemoryAskAiChatForDetail(BuildContext context, String memoryId) async {
  final OmiMemoryDetailState s = context.read<OmiMemoryDetailCubit>().state;
  if (s.phase != OmiMemoryDetailPhase.loaded || s.data == null) {
    return;
  }
  final String aboutText =
      s.data!.navTitle.trim().isNotEmpty ? s.data!.navTitle : 'Memory';
  final MPGetLastConversationResponse? lastConversation = await getLastConversation(
    MPGetLastConversationRequest(conversationType: 1, paramId: memoryId),
  );
  final String conversationId = lastConversation?.conversationId ?? '';
  final BuildContext? targetContext = context.mounted ? context : MyApp.navigatorKey.currentContext;
  if (targetContext == null) {
    return;
  }
  // ignore: use_build_context_synchronously
  Navigator.of(targetContext).push(
    MaterialPageRoute<void>(
      builder: (_) => MPAskAIChatPage(
        aboutText: aboutText,
        suggestedQuestions: const <String>[],
        conversationId: conversationId,
        type: MPAskAIChatType.memory,
        chatTypeId: memoryId,
      ),
    ),
  );
}

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

class _OmiMemoryDetailView extends StatefulWidget {
  const _OmiMemoryDetailView({required this.memoryId});

  final String memoryId;

  @override
  State<_OmiMemoryDetailView> createState() => _OmiMemoryDetailViewState();
}

class _OmiMemoryDetailViewState extends State<_OmiMemoryDetailView> with WidgetsBindingObserver {
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
          final String navTitle = pageState.phase == OmiMemoryDetailPhase.loaded &&
                  pageState.data != null
              ? pageState.data!.navTitle
              : 'Memory';
          return Scaffold(
        backgroundColor: pageColor,
        appBar: PreferredSize(
          preferredSize: MPCustomNavBar.preferredSizeOf(context),
          child: MPCustomNavBar(
            title: navTitle,
            actions: <Widget>[
              GestureDetector(
                onTap: () async {
                  final MPShareSheetParams params = await MPShareOptionsManager.instance.getShareSheetParams(
                    memoryId: memoryId,
                  );

                  if (!context.mounted) return;
                  final MPShareSheetResult? result = await showMPShareSheet(
                    context,
                    params: params,
                    onShare: ({required String summaryOptionId, required Set<String> optionalOptionIds}) {
                      showMPShareExportSheet(context).then((MPShareExportKind? kind) async {
                        if (kind == null) return;
                        final List<int> optionIds =
                            <int>[int.parse(summaryOptionId)] +
                            optionalOptionIds.map((String id) => int.parse(id)).toList();
                        final MPShareMemoryV2Response? resp = await shareMemoryV2(
                          MPShareMemoryV2Request(memoryId: memoryId, optionIds: optionIds),
                        );
                        if (!context.mounted) return;
                        if (resp == null || resp.baseResp.code != 0) {
                          MPToastUtils.showMessage(resp?.baseResp.message ?? '');
                          return;
                        }
                        MPShareMemoryDialog.show(context: context, url: resp.shareUrl);
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
                    params: MPMemoryOptionsSheetParams(
                      manageProjectsCount: 1,
                      memoryId: memoryId,
                      showGenerateResummary: true,
                    ),
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
                        MPToastUtils.showMessage('Please wait until loading finishes.');
                        break;
                      }
                      MPMemoryUpdateNameDialog.show(
                        context: context,
                        memoryId: memoryId,
                        currentTitle: s.data!.title,
                        onSuccess: (String t) {
                          cubit.updateTitle(t);
                          MPMemoryNotification.notifyMemoryTitleUpdated(memoryId: memoryId, title: t);
                        },
                      );
                      break;
                    case MPMemoryOptionKind.modifyDate:
                      // TODO: Modify date
                      break;
                    case MPMemoryOptionKind.generateResummary:
                      await openMPDetailGenerateResummary(context);
                      break;
                    case MPMemoryOptionKind.delete:
                      // [MPMemoryOptionsSheetParams.memoryId] 非空时，确认与 deleteMemory 已在 Sheet 内完成。
                      MPMemoryNotification.notifyMemoryDeleted(memoryId);
                      Navigator.of(context).pop();
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
        body: _buildBody(context, memoryId, pageState),
        bottomNavigationBar: MPMemoryDetailBottomBar(
          onAddTodo: () async {
            final OmiQuickAddTodoResult? result = await showOmiQuickAddTodoPopup(context);
            if (result == null) return;
            if (!context.mounted) return;
            final String line = result.text.trim();
            if (line.isEmpty) return;
            final bool ok = await MPTodoManager().createTodo(title: line, memoryId: memoryId);
            if (!context.mounted) return;
            if (!ok) {
              return;
            }
            await context.read<OmiMemoryDetailCubit>().refresh();
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
              MPToastUtils.showMessage(resp?.baseResp.message ?? 'Couldn\'t create memo. Please try again later.');
              return;
            }
            await context.read<OmiMemoryDetailCubit>().refresh();
          },
          onAskAi: () => _openMemoryAskAiChatForDetail(context, memoryId),
        ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    String memoryId,
    OmiMemoryDetailState state,
  ) {
    switch (state.phase) {
      case OmiMemoryDetailPhase.loading:
        return const MPTristatePage(type: MPTristateType.loading);
      case OmiMemoryDetailPhase.error:
        return MPTristatePage(
          type: MPTristateType.error,
          data: MPTristatePageData(
            title: 'Unable to load memory detail',
            description: 'Please try again',
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
                      onSeekPlay: (Duration p) => context.read<OmiMemoryDetailCubit>().onSeekPlay(p),
                      onSeekWaveFraction: (double f) =>
                          context.read<OmiMemoryDetailCubit>().onSeekByWaveFraction(f),
                      isAudioPlaying: state.isAudioPlaying,
                    ),
                  ),
                  MPMemoryDetailFeedSection(
                    data: data,
                    onYouAskedTap: () => _openMemoryAskAiChatForDetail(context, memoryId),
                  ),
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
  }
}
