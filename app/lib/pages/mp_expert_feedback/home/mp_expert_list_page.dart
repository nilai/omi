// AI-generated START - 专家列表页面
import 'package:flutter/material.dart';
import 'package:omi/pages/mp_custom_utils/mp_const_utils.dart';
import 'package:omi/pages/mp_custom_widgets/mp_three_state_widget.dart';
import 'package:omi/pages/mp_expert_feedback/home/providers/mp_expert_provider.dart';
import 'package:omi/pages/mp_expert_feedback/home/widgets/expert_category_tabs_card.dart';
import 'package:omi/pages/mp_expert_feedback/home/widgets/mp_create_expert_card.dart';
import 'package:omi/pages/mp_expert_feedback/home/widgets/mp_expert_card.dart';
import 'package:omi/pages/mp_expert_feedback/mp_add_export/mp_add_export_page.dart';
import 'package:omi/pages/mp_expert_feedback/widgets/search_experts_card.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/mp_common_app_bar.dart';
import 'package:provider/provider.dart';

/// 专家列表页面
/// 显示专家列表，支持搜索、分类筛选和添加专家
class MPExpertListPage extends StatefulWidget {
  // AI-generated START - 构造函数
  const MPExpertListPage({
    super.key,
    this.title = '专家反馈',
  });
  // AI-generated END - 构造函数

  /// 页面标题
  final String title;

  @override
  State<MPExpertListPage> createState() => _MPExpertListPageState();
}

class _MPExpertListPageState extends State<MPExpertListPage> {
  // AI-generated START - 滚动控制器
  final ScrollController _scrollController = ScrollController();
  // AI-generated END - _scrollController

  // AI-generated START - 初始化方法
  @override
  void initState() {
    super.initState();
    // AI-generated START - 添加滚动监听
    _scrollController.addListener(_onScroll);
    // AI-generated END - 添加滚动监听
    // AI-generated START - 初始化专家数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 获取 MPExpertProvider 实例，用于后续数据加载
      final provider = Provider.of<MPExpertProvider>(context, listen: false);
      // 加载专家数据
      provider.loadExperts();
    });
    // AI-generated END - 初始化专家数据
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
    final provider = Provider.of<MPExpertProvider>(context, listen: false);
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!provider.isFetching && provider.hasMore) {
        provider.loadMoreExperts();
      }
    }
  }
  // AI-generated END - _onScroll

  // AI-generated START - 下拉刷新方法
  Future<void> _onRefresh() async {
    final provider = Provider.of<MPExpertProvider>(context, listen: false);
    await provider.loadExperts();
  }
  // AI-generated END - _onRefresh

  // AI-generated START - 处理添加专家
  Future<void> _handleAddExpert(String expertId) async {
    final provider = Provider.of<MPExpertProvider>(context, listen: false);
    try {
      await provider.addExpert(expertId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已添加专家'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加失败: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  // AI-generated END - _handleAddExpert

  // AI-generated START - 构建方法
  @override
  Widget build(BuildContext context) {
    return Consumer<MPExpertProvider>(
      builder: (context, expertProvider, child) {
        return Scaffold(
          backgroundColor: MPConstUtils.backgroundColorGrey,
          appBar: MPCommonAppBar(
            title: widget.title,
          ),
          body: Column(
            children: [
              // AI-generated START - 搜索框
              MPExpertSearchCard(
                placeholder: '搜索AI专家...',
                onSearchChanged: (query) {
                  expertProvider.setSearchQuery(query);
                },
              ),
              // AI-generated END - 搜索框

              // AI-generated START - 分类标签栏
              ExpertCategoryTabsCard(
                categories: ExpertCategoryTabsCard.getDefaultCategories(),
                selectedIndex: expertProvider.selectedCategoryIndex,
                onCategoryChanged: (index) {
                  expertProvider.setSelectedCategoryIndex(index);
                },
              ),
              // AI-generated END - 分类标签栏

              // AI-generated START - 专家列表
              Expanded(
                child: _buildBody(expertProvider),
              ),
              // AI-generated END - 专家列表
              MPCreateExpertCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MPAddExportPage()),
                  );
                },
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        );
      },
    );
  }
  // AI-generated END - 构建方法

  // AI-generated START - 构建页面主体
  Widget _buildBody(MPExpertProvider provider) {
    if (provider.isLoading && provider.filteredExperts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.error != null && provider.filteredExperts.isEmpty) {
      return MPThreeStateWidget(
        state: MPThreeStateType.error,
        errorMessage: provider.error!,
        onRetry: () => provider.loadExperts(),
      );
    }

    if (provider.filteredExperts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              provider.searchQuery.isEmpty ? '暂无专家' : '未找到相关专家',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // AI-generated START - 专家列表（带下拉刷新和上拉加载）
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: provider.filteredExperts.length + (provider.hasMore && provider.isFetching ? 1 : 0),
        itemBuilder: (context, index) {
          // 显示加载更多指示器
          if (index == provider.filteredExperts.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          final expert = provider.filteredExperts[index];
          final isAdded = provider.isExpertAdded(expert.id);
          return MPExpertCard(
            expert: expert,
            onAddTap: isAdded ? null : () => _handleAddExpert(expert.id),
            onCardTap: () {
              // TODO: 导航到专家详情页面
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('查看专家详情: ${expert.name}'),
                ),
              );
            },
          );
        },
      ),
    );
    // AI-generated END - 专家列表
  }
  // AI-generated END - _buildBody
}
// AI-generated END - mp_expert_list_page.dart
