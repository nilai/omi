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

class _MPAskAIConversationListViewState
    extends State<_MPAskAIConversationListView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final double threshold = _scrollController.position.maxScrollExtent - 120;
    if (_scrollController.position.pixels >= threshold) {
      context.read<MPAskAIConversationListCubit>().loadMore();
    }
  }

  void _showComingSoon() {
    MPToastUtils.showFeatureComingSoon(context: context);
  }

  void _onTapConversationItem(MPAskAIConversationItem item) {
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
                                  onTap: _showComingSoon,
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
                                    onTap: _showComingSoon,
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
                            child: _buildListByState(state),
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

  Widget _buildListByState(MPAskAIConversationListState state) {
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
        return Center(
          child: Text(
            state.errorMessage ?? 'Load failed',
            style: OmiTextStyle.create(
              color: secondTextColor,
              fontSize: OmiFontSize.t4_13,
              fontWeight: OmiFontWeight.regular,
            ),
          ),
        );
      case MPAskAIConversationListPhase.loaded:
        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => context.read<MPAskAIConversationListCubit>().refresh(),
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
          onRefresh: () => context.read<MPAskAIConversationListCubit>().refresh(),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            itemBuilder: (BuildContext context, int index) {
              if (index >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
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
                    onTap: () => _onTapConversationItem(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        item.title,
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
