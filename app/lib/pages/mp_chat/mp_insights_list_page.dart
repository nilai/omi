import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/mp_insights_list_provider.dart';
import 'widgets/mp_insight_card.dart';

/// Insights 列表页面
class MPInsightsListPage extends StatefulWidget {
  const MPInsightsListPage({super.key});

  @override
  State<MPInsightsListPage> createState() => _MPInsightsListPageState();
}

class _MPInsightsListPageState extends State<MPInsightsListPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听，实现上拉加载更多
  void _onScroll() {
    final provider = context.read<MPInsightsListProvider>();
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !provider.isLoadingMore &&
        provider.hasMore) {
      provider.loadMore();
    }
  }

  /// 下拉刷新
  Future<void> _onRefresh() async {
    final provider = context.read<MPInsightsListProvider>();
    await provider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MPInsightsListProvider(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF1F2937),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text(
            'Insights',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          centerTitle: true,
        ),
        body: Consumer<MPInsightsListProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.insights.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (provider.insights.isEmpty) {
              return const Center(
                child: Text(
                  '暂无数据',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: const Color(0xFF306CFF),
              backgroundColor: Colors.white,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: provider.insights.length + (provider.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  // 加载更多指示器
                  if (index >= provider.insights.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF306CFF),
                          ),
                        ),
                      ),
                    );
                  }

                  final insight = provider.insights[index];
                  return MPInsightCard(
                    insight: insight,
                    onTap: () {
                      // 卡片点击事件
                      debugPrint('Card tapped: ${insight.id}');
                    },
                    onViewDetailTap: () {
                      // 查看详情点击事件
                      debugPrint('View detail tapped: ${insight.id}');
                      // Navigator.of(context).push(
                      //   MaterialPageRoute(
                      //     builder: (context) => ConversationDetailPage(
                      //       memoryId: insight.id,
                      //     ),
                      //   ),
                      // );
                    },
                    onMenuTap: () {
                      // 菜单点击事件
                      debugPrint('Menu tapped: ${insight.id}');
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
