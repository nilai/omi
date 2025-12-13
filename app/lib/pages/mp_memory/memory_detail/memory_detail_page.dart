// AI-generated START - 记忆详情页面
import 'package:flutter/material.dart';
import 'package:omi/gen/assets.gen.dart';
import 'package:omi/pages/mp_custom_widgets/mp_three_state_widget.dart';
import 'package:omi/pages/mp_memory/conversation_detail/conversation_detail_page.dart';
import 'package:omi/pages/mp_memory/home/providers/memory_provider.dart';
import 'package:omi/pages/mp_memory/memory_detail/providers/memory_detail_provider.dart';
import 'package:omi/pages/mp_memory/memory_detail/widgets/character_info_card.dart';
import 'package:omi/pages/mp_memory/memory_detail/widgets/conversation_summary_card.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/mp_common_app_bar.dart';
import 'package:provider/provider.dart';

/// 记忆详情页面
/// 显示特定人物记忆的详细信息和对话记录
class MemoryDetailPage extends StatefulWidget {
  // AI-generated START - 构造函数
  const MemoryDetailPage({
    super.key,
    required this.memoryId,
    this.memoryItem,
  });
  // AI-generated END - 构造函数

  /// 记忆ID
  final String memoryId;

  /// 记忆项（可选，如果传入则直接使用，否则从Provider加载）
  final CharacterMemoryItem? memoryItem;

  // AI-generated START - 创建状态
  @override
  State<MemoryDetailPage> createState() => _MemoryDetailPageState();
  // AI-generated END - 创建状态
}

class _MemoryDetailPageState extends State<MemoryDetailPage> {
  // AI-generated START - 初始化方法
  @override
  void initState() {
    super.initState();
    // AI-generated START - 初始化记忆详情数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final detailProvider = Provider.of<MemoryDetailProvider>(context, listen: false);

      // 如果传入了memoryItem，直接设置
      if (widget.memoryItem != null) {
        detailProvider.setMemoryItem(widget.memoryItem);
      }

      // 加载对话记录
      detailProvider.loadMemoryDetail(widget.memoryId);
    });
    // AI-generated END - 初始化记忆详情数据
  }
  // AI-generated END - 初始化方法

  // AI-generated START - 构建方法
  @override
  Widget build(BuildContext context) {
    return Consumer<MemoryDetailProvider>(
      builder: (context, detailProvider, child) {
        final memoryItem = detailProvider.memoryItem;

        return Scaffold(
          appBar: MPCommonAppBar(
            title: memoryItem != null ? '与${memoryItem.name}的对话' : '记忆详情',
          ),
          body: _buildBody(detailProvider, memoryItem),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // TODO: 打开录音/对话功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('开始新对话')),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Assets.images.mpMemoryDetailAddMemory.image(
              width: 56.0,
              height: 56.0,
            ),
          ),
        );
      },
    );
  }
  // AI-generated END - 构建方法

  // AI-generated START - 构建页面主体
  Widget _buildBody(MemoryDetailProvider provider, CharacterMemoryItem? memoryItem) {
    if (provider.isLoading && provider.conversationSummaries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.error != null && provider.conversationSummaries.isEmpty) {
      return MPThreeStateWidget(
        state: MPThreeStateType.error,
        errorMessage: provider.error,
        onRetry: () => provider.loadMemoryDetail(widget.memoryId),
      );
    }

    return Column(
      children: [
        // AI-generated START - 人物信息卡片
        if (memoryItem != null)
          CharacterInfoCard(
            name: memoryItem.name,
            conversationCount: memoryItem.conversationCount,
            avatarUrl: memoryItem.avatarUrl,
          ),
        // AI-generated END - 人物信息卡片

        // AI-generated START - 对话摘要列表
        Expanded(
          child: provider.conversationSummaries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无对话记录',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: provider.conversationSummaries.length,
                  itemBuilder: (context, index) {
                    final summary = provider.conversationSummaries[index];
                    return ConversationSummaryCard(
                      title: summary.title,
                      summary: summary.summary,
                      date: summary.date,
                      durationSeconds: summary.durationSeconds,
                      participantCount: summary.participantCount,
                      onTap: () {
                        // AI-generated START - 导航到对话详情页面
                        final memory = provider.getMemoryById(summary.id);
                        if (memory != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ConversationDetailPage(
                                memory: memory,
                              ),
                            ),
                          );
                        }
                        // AI-generated END - 导航到对话详情页面
                      },
                    );
                  },
                ),
        ),
        // AI-generated END - 对话摘要列表
      ],
    );
  }
  // AI-generated END - _buildBody
}
// AI-generated END - memory_detail_page.dart
