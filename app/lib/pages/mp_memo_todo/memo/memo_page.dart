// AI-generated START - Memo 页面
import 'package:flutter/material.dart';
import 'package:omi/pages/mp_memo_todo/home/widgets/search_tasks_card.dart';
import 'package:omi/pages/mp_memo_todo/memo/providers/memo_provider.dart';
import 'package:omi/pages/mp_memo_todo/memo/widgets/memo_task_card.dart';
import 'package:omi/pages/mp_popup/inspiration_detail_popup.dart';
import 'package:provider/provider.dart';

/// Memo 页面
/// 显示 Memo 任务列表，支持搜索、下拉刷新和上拉加载
class MemoPage extends StatefulWidget {
  // AI-generated START - 构造函数
  const MemoPage({
    super.key,
    this.title = 'Memo',
  });
  // AI-generated END - 构造函数

  /// 页面标题
  final String title;

  // AI-generated START - 创建状态
  @override
  State<MemoPage> createState() => _MemoPageState();
  // AI-generated END - 创建状态
}

class _MemoPageState extends State<MemoPage> {
  // AI-generated START - 滚动控制器
  final ScrollController _scrollController = ScrollController();
  // AI-generated END - _scrollController

  // AI-generated START - 当前活动的卡片ID（用于控制只有一个卡片处于滑动状态）
  String? _activeCardId;
  // AI-generated END - _activeCardId

  // AI-generated START - 初始化方法
  @override
  void initState() {
    super.initState();
    // AI-generated START - 添加滚动监听
    _scrollController.addListener(_onScroll);
    // AI-generated END - 添加滚动监听
    // AI-generated START - 初始化 Memo 数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 获取 MemoProvider 实例，用于后续数据加载
      final provider = Provider.of<MemoProvider>(context, listen: false);
      // 加载 Memo 数据
      provider.loadMemos();
    });
    // AI-generated END - 初始化 Memo 数据
  }
  // AI-generated END - 初始化方法

  // AI-generated START - 清理资源
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  // AI-generated END - 清理资源

  // AI-generated START - 滚动监听方法
  void _onScroll() {
    final provider = Provider.of<MemoProvider>(context, listen: false);
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!provider.isFetching && provider.hasMore) {
        provider.loadMoreMemos();
      }
    }
  }
  // AI-generated END - _onScroll

  // AI-generated START - 下拉刷新方法
  Future<void> _onRefresh() async {
    final provider = Provider.of<MemoProvider>(context, listen: false);
    await provider.loadMemos();
  }
  // AI-generated END - _onRefresh

  // AI-generated START - 公共刷新方法（供父页面调用）
  Future<void> refresh() async {
    await _onRefresh();
  }
  // AI-generated END - refresh

  // AI-generated START - 滚动到顶部
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }
  // AI-generated END - scrollToTop

  // AI-generated START - 重置活动卡片（用于切换类型时还原左滑状态）
  void resetActiveCard() {
    if (_activeCardId != null) {
      setState(() {
        _activeCardId = null;
      });
    }
  }
  // AI-generated END - resetActiveCard

  // AI-generated START - 构建方法
  @override
  Widget build(BuildContext context) {
    return Consumer<MemoProvider>(
      builder: (context, memoProvider, child) {
        return Column(
          children: [
            // AI-generated START - 固定的搜索条
            SearchTasksCard(
              placeholder: 'Search ${memoProvider.totalCount} Memories',
              onSearchChanged: (query) {
                // 搜索功能暂时不实现
                memoProvider.setSearchQuery(query);
              },
            ),
            // AI-generated END - 固定的搜索条

            // AI-generated START - 可滚动的列表内容
            Expanded(
              child: _buildBody(memoProvider),
            ),
            // AI-generated END - 可滚动的列表内容
          ],
        );
      },
    );
  }
  // AI-generated END - 构建方法

  // AI-generated START - 构建页面主体
  Widget _buildBody(MemoProvider provider) {
    if (provider.isLoading && provider.memos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.error != null && provider.memos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200, // 确保有足够的高度支持下拉
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadMemos(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (provider.filteredMemos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200, // 确保有足够的高度支持下拉
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.searchQuery.isEmpty ? '暂无Memo' : '未找到相关Memo',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // AI-generated START - Memo 列表（带下拉刷新和上拉加载）
    return RefreshIndicator(
      color: const Color(0xFF306CFF),
      backgroundColor: Colors.white,
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(), // 即使内容不足一屏也可以滚动和下拉刷新
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: provider.filteredMemos.length + (provider.hasMore && provider.isFetching ? 1 : 0),
        itemBuilder: (context, index) {
          // 显示加载更多指示器
          if (index == provider.filteredMemos.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          final memo = provider.filteredMemos[index];
          return MemoTaskCard(
            id: memo.id,
            title: memo.title,
            description: memo.description,
            date: memo.date,
            tags: memo.tags,
            activeCardId: _activeCardId,
            onSwipeStart: (cardId) {
              // 当新的卡片开始滑动时，更新活动卡片ID
              setState(() {
                _activeCardId = cardId;
              });
            },
            onTap: () {
              // 清除活动卡片ID
              setState(() {
                _activeCardId = null;
              });
              InspirationDetailPopup.show(
                context: context,
                title: memo.title,
                content: memo.description,
                dateTime: memo.date,
                tags: memo.tags,
                onSave: (content) {
                  provider.updateMemoWithText(memoId: memo.id, content: content);
                },
              );
            },
            onDelete: () async {
              await provider.deleteMemo(memo.id);
              // 清除活动卡片ID
              setState(() {
                _activeCardId = null;
              });
            },
          );
        },
      ),
    );
    // AI-generated END - Memo 列表
  }
  // AI-generated END - _buildBody
}
// AI-generated END - memo_page.dart
