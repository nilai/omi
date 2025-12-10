// AI-generated START - 记忆中心页面
import 'package:flutter/material.dart';
import 'package:omi/pages/memory/home/providers/memory_provider.dart';
import 'package:omi/pages/memory/home/widgets/add_character_memory_card.dart';
import 'package:omi/pages/memory/home/widgets/memory_conversation_card.dart';
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
  // AI-generated START - 初始化方法
  @override
  void initState() {
    super.initState();
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

  // AI-generated START - 构建方法
  @override
  Widget build(BuildContext context) {
    return Consumer<MemoryProvider>(
      builder: (context, memoryProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: _buildBody(memoryProvider),
        );
      },
    );
  }
  // AI-generated END - 构建方法

  // AI-generated START - 构建页面主体
  Widget _buildBody(MemoryProvider provider) {
    if (provider.isLoading && provider.memories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.error != null && provider.memories.isEmpty) {
      return Center(
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
              onPressed: () => provider.loadMemories(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (provider.filteredMemories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.memory_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              provider.searchQuery.isEmpty ? '暂无记忆' : '未找到相关记忆',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // AI-generated START - 记忆列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: provider.filteredMemories.length,
            itemBuilder: (context, index) {
              final memory = provider.filteredMemories[index];
              return MemoryConversationCard(
                name: memory.name,
                timestamp: _formatTimestamp(memory.createdAt),
                description: memory.description,
                conversationCount: memory.conversationCount,
                avatarBackgroundColor: memory.avatarBackgroundColor,
                avatarBadge: const Icon(
                  Icons.volume_up,
                  color: Colors.white,
                  size: 12.0,
                ),
                onTap: () {
                  // TODO: 导航到记忆详情页面
                },
              );
            },
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
  // AI-generated END - _buildBody

  // AI-generated START - 格式化时间戳
  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '今天';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 14) {
      return '1周前';
    } else if (difference.inDays < 21) {
      return '2周前';
    } else if (difference.inDays < 30) {
      return '3周前';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks周前';
    }
  }
  // AI-generated END - _formatTimestamp
}
// AI-generated END - memory_page.dart
