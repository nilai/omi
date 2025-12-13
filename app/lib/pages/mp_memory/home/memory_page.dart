// AI-generated START - 记忆中心页面
import 'package:flutter/material.dart';
import 'package:omi/pages/mp_custom_utils/mp_timestamp_utils.dart';
import 'package:omi/pages/mp_custom_widgets/mp_three_state_widget.dart';
import 'package:omi/pages/mp_memory/home/providers/memory_provider.dart';
import 'package:omi/pages/mp_memory/home/widgets/add_character_memory_card.dart';
import 'package:omi/pages/mp_memory/home/widgets/memory_conversation_card.dart';
import 'package:omi/pages/mp_memory/memory_detail/memory_detail_page.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/mp_common_app_bar.dart';
import 'package:provider/provider.dart';

/// 记忆中心页面
/// 显示用户记忆列表和管理功能
class MemoryPage extends StatefulWidget {
  // AI-generated START - 构造函数
  const MemoryPage({
    super.key,
    this.title = '记忆仓库',
  });
  // AI-generated END - 构造函数

  /// 页面标题
  final String title;

  // AI-generated START - 创建状态
  @override
  State<MemoryPage> createState() => _MemoryPageState();
  // AI-generated END - 创建状态
}

class _MemoryPageState extends State<MemoryPage> {
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
    // AI-generated START - 初始化记忆数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 获取 MemoryProvider 实例，用于后续数据加载
      final provider = Provider.of<MemoryProvider>(context, listen: false);
      // 加载记忆数据
      provider.loadMemories();
    });
    // AI-generated END - 初始化记忆数据
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
    final provider = Provider.of<MemoryProvider>(context, listen: false);
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!provider.isFetching && provider.hasMore) {
        provider.loadMoreMemories();
      }
    }
  }
  // AI-generated END - _onScroll

  // AI-generated START - 下拉刷新方法
  Future<void> _onRefresh() async {
    final provider = Provider.of<MemoryProvider>(context, listen: false);
    await provider.loadMemories();
  }
  // AI-generated END - _onRefresh

  // AI-generated START - 构建方法
  @override
  Widget build(BuildContext context) {
    return Consumer<MemoryProvider>(
      builder: (context, memoryProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: MPCommonAppBar(
            title: widget.title,
          ),
          body: _buildBody(memoryProvider),
        );
      },
    );
  }
  // AI-generated END - 构建方法

  // AI-generated START - 构建页面主体
  Widget _buildBody(MemoryProvider provider) {
    // 加载中状态
    if (provider.isLoading && provider.memories.isEmpty) {
      return const MPThreeStateWidget(
        state: MPThreeStateType.loading,
      );
    }

    // 加载失败状态
    if (provider.error != null && provider.memories.isEmpty) {
      return MPThreeStateWidget(
        state: MPThreeStateType.error,
        errorMessage: provider.error,
        onRetry: () => provider.loadMemories(),
      );
    }

    return Column(
      children: [
        // AI-generated START - 记忆列表（带下拉刷新和上拉加载）
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: provider.memories.length + (provider.hasMore && provider.isFetching ? 1 : 0),
              itemBuilder: (context, index) {
                // 显示加载更多指示器
                if (index == provider.memories.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final memory = provider.memories[index];
                return MemoryConversationCard(
                  name: memory.name,
                  timestamp: MPTimestampUtils.timestampToRelativeDateString(memory.createdAt ?? 0),
                  description: memory.description ?? '',
                  conversationCount: memory.conversationCount,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemoryDetailPage(memoryId: memory.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        // AI-generated END - 记忆列表

        // AI-generated START - 新增人物记忆卡片
        AddCharacterMemoryCard(
          onTap: () {
            // TODO: 打开新增人物记忆页面
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('打开新增人物记忆')),
            );
          },
          description: '人物记忆与保存的人物声纹相关,您可以选择录制或者标记新的声纹',
        ),
        // AI-generated END - 新增人物记忆卡片

        const SizedBox(height: 16.0),
      ],
    );
  }

  // AI-generated END - _formatTimestamp
}
// AI-generated END - memory_page.dart
