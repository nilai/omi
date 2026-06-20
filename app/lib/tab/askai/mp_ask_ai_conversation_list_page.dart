import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/tab/askai/mp_ask_ai_chat_page.dart';
import 'package:memo_pin/tab/askai/mp_ask_ai_conversation_list_cubit.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

class MPAskAIConversationListPage extends StatelessWidget {
  const MPAskAIConversationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPAskAIConversationListCubit>(
      create: (_) => MPAskAIConversationListCubit()..initData(),
      child: const _MPAskAIConversationListView(),
    );
  }
}

class _MPAskAIConversationListView extends StatefulWidget {
  const _MPAskAIConversationListView();

  @override
  State<_MPAskAIConversationListView> createState() =>
      _MPAskAIConversationListViewState();
}

class _MPAskAIConversationListViewState extends State<_MPAskAIConversationListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 距离底部约 200px 触发下一页（与项目其它游标分页一致）
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final ScrollPosition pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels < pos.maxScrollExtent - 200) return;

    final MPAskAIConversationListCubit cubit =
        context.read<MPAskAIConversationListCubit>();
    final MPAskAIConversationListState state = cubit.state;
    if (state.phase != MPAskAIConversationListPhase.loaded) return;
    if (state.isLoadingMore || !state.hasMore) return;

    cubit.loadMore();
  }

  Future<void> _onPullRefresh(BuildContext context) {
    return context
        .read<MPAskAIConversationListCubit>()
        .refresh(fromPullToRefresh: true);
  }

  void _openNewChatPage(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const MPAskAIChatPage(
          aboutText: 'General',
        ),
      ),
    );
  }

  void _onTapConversationItem(BuildContext context, MPAskAIConversationItem item) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MPAskAIChatPage(
          aboutText: item.title,
          conversationId: item.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.18),
      body: SafeArea(
        child: Row(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.68,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child:
                  BlocBuilder<MPAskAIConversationListCubit, MPAskAIConversationListState>(
                    builder:
                        (BuildContext context, MPAskAIConversationListState state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                            child: Row(
                              children: <Widget>[
                                InkWell(
                                  onTap: () => _openNewChatPage(context),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2F61DA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => MPToastUtils.showFeatureComingSoon(context: context),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 36,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF2F2F7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: <Widget>[
                                          const Icon(
                                            Icons.search_rounded,
                                            size: 18,
                                            color: secondTextColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Search',
                                            style: OmiTextStyle.create(
                                              color: secondTextColor,
                                              fontSize: OmiFontSize.t4_13,
                                              fontWeight: OmiFontWeight.regular,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: () => Navigator.of(context).maybePop(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                      color: secondTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                            child: Text(
                              'RECENT CONVERSATIONS',
                              style: OmiTextStyle.create(
                                color: secondTextColor.withValues(alpha: 0.7),
                                fontSize: OmiFontSize.t3_12,
                                fontWeight: OmiFontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildListByState(context, state),
                          ),
                        ],
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListByState(
    BuildContext context,
    MPAskAIConversationListState state,
  ) {
    switch (state.phase) {
      case MPAskAIConversationListPhase.loading:
        return const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case MPAskAIConversationListPhase.error:
        return RefreshIndicator(
          onRefresh: () => _onPullRefresh(context),
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            children: <Widget>[
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Center(
                  child: Text(
                    state.errorMessage ?? 'Load failed',
                    textAlign: TextAlign.center,
                    style: OmiTextStyle.create(
                      color: secondTextColor,
                      fontSize: OmiFontSize.t4_13,
                      fontWeight: OmiFontWeight.regular,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case MPAskAIConversationListPhase.loaded:
        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _onPullRefresh(context),
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              children: <Widget>[
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Text(
                      'No conversations yet',
                      style: OmiTextStyle.create(
                        color: secondTextColor,
                        fontSize: OmiFontSize.t4_13,
                        fontWeight: OmiFontWeight.regular,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => _onPullRefresh(context),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: state.items.length +
                (state.hasMore && state.isLoadingMore ? 1 : 0),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            itemBuilder: (BuildContext context, int index) {
              if (index == state.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final MPAskAIConversationItem item = state.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _onTapConversationItem(context, item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OmiTextStyle.create(
                          color: mainTextColor,
                          fontSize: OmiFontSize.t6_15,
                          fontWeight: OmiFontWeight.medium,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
    }
  }
}
