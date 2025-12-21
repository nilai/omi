import 'package:flutter/material.dart';
import 'package:omi/pages/mp_chat/providers/mp_chat_people_memory_provider.dart';
import 'package:omi/pages/mp_custom_utils/mp_timestamp_utils.dart';
import 'package:omi/pages/mp_custom_widgets/mp_three_state_widget.dart';
import 'package:omi/pages/mp_memory/home/widgets/memory_conversation_card.dart';
import 'package:omi/pages/mp_memory/memory_detail/memory_detail_page.dart';
import 'package:provider/provider.dart';

import 'widgets/mp_chat_people_memory_card.dart';

/// People Memory 页面
/// 从屏幕右侧滑入的 dialog，显示人物记忆列表
class MPChatPeopleMemoryPage extends StatefulWidget {
  const MPChatPeopleMemoryPage({super.key});

  /// 显示 People Memory dialog 的静态方法
  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const MPChatPeopleMemoryPage(),
    );
  }

  @override
  State<MPChatPeopleMemoryPage> createState() => _MPChatPeopleMemoryPageState();
}

class _MPChatPeopleMemoryPageState extends State<MPChatPeopleMemoryPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // 从右侧开始
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // 启动动画
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _closeDialog() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MPChatPeopleMemoryProvider(),
      child: GestureDetector(
        onTap: () => _closeDialog(),
        child: Container(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {}, // 阻止点击事件冒泡
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      constraints: const BoxConstraints(maxWidth: 400),
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 24,
                            offset: const Offset(-6, 0),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 40,
                            offset: const Offset(-12, 0),
                          ),
                        ],
                      ),
                      child: _PeopleMemoryContent(
                        scrollController: _scrollController,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// People Memory 内容
class _PeopleMemoryContent extends StatefulWidget {
  const _PeopleMemoryContent({
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  State<_PeopleMemoryContent> createState() => _PeopleMemoryContentState();
}

class _PeopleMemoryContentState extends State<_PeopleMemoryContent> {
  @override
  void initState() {
    super.initState();
    // 添加滚动监听
    widget.scrollController.addListener(_onScroll);
    // 初始化数据加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<MPChatPeopleMemoryProvider>(context, listen: false);
      if (provider.memories.isEmpty && !provider.isLoading) {
        provider.loadMemories();
      }
    });
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final provider = Provider.of<MPChatPeopleMemoryProvider>(context, listen: false);
    if (widget.scrollController.position.pixels >= widget.scrollController.position.maxScrollExtent - 200) {
      if (!provider.isFetching && provider.hasMore) {
        provider.loadMoreMemories();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部 header（包含返回箭头和标题）
        _buildTopHeader(context),
        // 记忆列表
        Expanded(
          child: _buildMemoryList(context),
        ),
      ],
    );
  }

  /// 构建顶部 header
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // 返回箭头
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 标题
          const Text(
            'People Memory',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建记忆列表
  Widget _buildMemoryList(BuildContext context) {
    return Consumer<MPChatPeopleMemoryProvider>(
      builder: (context, provider, child) {
        // 加载中状态
        if (provider.isLoading && provider.memories.isEmpty) {
          return const Center(
            child: MPThreeStateWidget(
              state: MPThreeStateType.loading,
            ),
          );
        }

        // 加载失败状态
        if (provider.error != null && provider.memories.isEmpty) {
          return Center(
            child: MPThreeStateWidget(
              state: MPThreeStateType.error,
              errorMessage: provider.error,
              onRetry: () => provider.loadMemories(),
            ),
          );
        }

        // 空状态
        if (provider.memories.isEmpty) {
          return const Center(
            child: Text(
              '暂无人物记忆',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
            ),
          );
        }

        // 记忆列表
        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadMemories();
          },
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
              return MPChatPeopleMemoryCard(
                name: memory.name,
                timestamp: MPTimestampUtils.timestampToRelativeDateString(
                  memory.createdAt ?? 0,
                ),
                description: memory.description ?? '',
                avatarUrl: memory.avatarUrl,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MemoryDetailPage(
                        memoryId: memory.id,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
