// AI-generated START - 对话详情页面
import 'package:flutter/material.dart';
import 'package:omi/pages/mp_memory/conversation_detail/providers/conversation_detail_provider.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/action_buttons_card.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/audio_player_card.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/conversation_header_card.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/key_content_card.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/meeting_summary_card.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/participants_card.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/tab_selector_card.dart';
import 'package:provider/provider.dart';

/// 对话详情页面
/// 显示特定对话的详细消息记录
class ConversationDetailPage extends StatefulWidget {
  // AI-generated START - 构造函数
  const ConversationDetailPage({
    super.key,
    required this.conversationId,
    this.title,
  });
  // AI-generated END - 构造函数

  /// 对话ID
  final String conversationId;

  /// 对话标题（可选）
  final String? title;

  // AI-generated START - 创建状态
  @override
  State<ConversationDetailPage> createState() => _ConversationDetailPageState();
  // AI-generated END - 创建状态
}

class _ConversationDetailPageState extends State<ConversationDetailPage> {
  // AI-generated START - 当前选中的标签
  String _selectedTab = 'summary';
  // AI-generated END - _selectedTab

  // AI-generated START - 初始化方法
  @override
  void initState() {
    super.initState();
    // AI-generated START - 初始化对话详情数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<ConversationDetailProvider>(context, listen: false);

      // 如果传入了title，直接设置
      if (widget.title != null) {
        provider.setConversationInfo(widget.conversationId, widget.title);
      }

      // 加载对话详情
      provider.loadConversationDetail(widget.conversationId);
    });
    // AI-generated END - 初始化对话详情数据
  }
  // AI-generated END - 初始化方法

  // AI-generated START - 构建方法
  @override
  Widget build(BuildContext context) {
    return Consumer<ConversationDetailProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: 实现分享功能
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('分享')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // TODO: 实现更多选项
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('更多选项')),
                  );
                },
              ),
            ],
          ),
          body: _buildBody(provider),
        );
      },
    );
  }
  // AI-generated END - 构建方法

  // AI-generated START - 构建页面主体
  Widget _buildBody(ConversationDetailProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.error != null) {
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
              onPressed: () => provider.loadConversationDetail(widget.conversationId),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // AI-generated START - 对话头部卡片
          ConversationHeaderCard(
            title: provider.title ?? widget.title ?? '对话详情',
            summaryTime: '2025-07-22 15:21:54',
          ),
          // AI-generated END - 对话头部卡片

          // AI-generated START - 参与人卡片
          if (provider.participants.isNotEmpty)
            ParticipantsCard(
              participants: provider.participants,
            ),
          // AI-generated END - 参与人卡片

          // AI-generated START - 音频播放器卡片
          const AudioPlayerCard(
            title: '原始音频',
            totalDurationSeconds: 2529, // 42分9秒
          ),
          // AI-generated END - 音频播放器卡片

          // AI-generated START - 标签选择器卡片
          TabSelectorCard(
            options: const [
              TabOption(
                id: 'summary',
                label: 'Summary',
                icon: Icons.description,
              ),
              TabOption(
                id: 'mindmap',
                label: 'MindMap',
                icon: Icons.account_tree,
              ),
              TabOption(
                id: 'transcript',
                label: 'Transcript',
                icon: Icons.chat_bubble_outline,
              ),
              TabOption(
                id: 'todolist',
                label: 'TodoList',
                icon: Icons.check_box,
              ),
            ],
            selectedId: _selectedTab,
            onTabSelected: (id) {
              setState(() {
                _selectedTab = id;
              });
            },
          ),
          // AI-generated END - 标签选择器卡片

          // AI-generated START - 根据选中的标签显示内容
          _buildTabContent(_selectedTab),
          // AI-generated END - 根据选中的标签显示内容

          // AI-generated START - 底部操作按钮
          ActionButtonsCard(
            buttons: [
              ActionButton(
                id: 'name_speaker',
                label: '命名发言者',
                icon: Icons.person_outline,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('命名发言者')),
                  );
                },
              ),
              ActionButton(
                id: 'add_summary',
                label: '追加总结',
                icon: Icons.add_box_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('追加总结')),
                  );
                },
              ),
              ActionButton(
                id: 'ai_assistant',
                label: 'AI助手',
                icon: Icons.smart_toy,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AI助手')),
                  );
                },
              ),
            ],
          ),
          // AI-generated END - 底部操作按钮

          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
  // AI-generated END - _buildBody

  // AI-generated START - 构建标签内容
  Widget _buildTabContent(String tabId) {
    switch (tabId) {
      case 'summary':
        return _buildSummaryContent();
      case 'mindmap':
        return _buildMindMapContent();
      case 'transcript':
        return _buildTranscriptContent();
      case 'todolist':
        return _buildTodoListContent();
      default:
        return _buildSummaryContent();
    }
  }
  // AI-generated END - _buildTabContent

  // AI-generated START - 构建摘要内容
  Widget _buildSummaryContent() {
    return Column(
      children: [
        // AI-generated START - 重点内容卡片
        KeyContentCard(
          items: const [
            KeyContentItem(
              id: '1',
              time: '15:32',
              isFavorite: true,
              highlightQuote: '用户体验是我们最大的差异化优势,必须做到极致',
              analysis: '这是会议的核心洞察,体现了产品策略的重要转变',
              tags: [
                '用户体验设计原则',
                'AI硬件交互标准',
              ],
            ),
            KeyContentItem(
              id: '2',
              time: '28:45',
              isFavorite: true,
              highlightQuote: '技术门槛很高,但这也是我们的护城河',
              analysis: '识别了技术壁垒作为竞争优势的战略价值',
              tags: [
                'AI芯片技术发展',
                '语音识别算法优化',
              ],
            ),
          ],
          onFavoriteChanged: (id) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('收藏状态变化: $id')),
            );
          },
          onTagTap: (tag) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('标签点击: $tag')),
            );
          },
        ),
        // AI-generated END - 重点内容卡片

        // AI-generated START - 会议总结卡片
        const MeetingSummaryCard(
          content:
              '本次会议重点讨论了AI硬件市场的需求分析和产品设计方案。团队确定了以用户体验为核心的差异化策略,强调技术门槛作为竞争壁垒的重要性。会议涉及了目标用户画像、产品功能规格、技术实现路径以及商业模式等关键议题。最终形成了清晰的产品开发路线图和下一步行动计划。',
        ),
        // AI-generated END - 会议总结卡片
      ],
    );
  }
  // AI-generated END - _buildSummaryContent

  // AI-generated START - 构建思维导图内容
  Widget _buildMindMapContent() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: const Center(
        child: Text('思维导图内容'),
      ),
    );
  }
  // AI-generated END - _buildMindMapContent

  // AI-generated START - 构建转录内容
  Widget _buildTranscriptContent() {
    return Consumer<ConversationDetailProvider>(
      builder: (context, provider, child) {
        if (provider.messages.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: const Center(
              child: Text('暂无转录内容'),
            ),
          );
        }

        return Column(
          children: provider.messages.map((message) {
            return _buildMessageItem(message);
          }).toList(),
        );
      },
    );
  }
  // AI-generated END - _buildTranscriptContent

  // AI-generated START - 构建待办列表内容
  Widget _buildTodoListContent() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: const Center(
        child: Text('待办列表内容'),
      ),
    );
  }
  // AI-generated END - _buildTodoListContent

  // AI-generated START - 构建消息项
  Widget _buildMessageItem(ConversationMessage message) {
    final isUser = message.type == MessageType.user;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI-generated START - AI头像
            CircleAvatar(
              radius: 20.0,
              backgroundColor: Colors.purple.shade100,
              child: Icon(
                Icons.smart_toy,
                size: 24.0,
                color: Colors.purple.shade700,
              ),
            ),
            const SizedBox(width: 12.0),
          ],

          // AI-generated START - 消息内容
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                      ),
                      if (message.audioUrl != null) ...[
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            Icon(
                              Icons.volume_up,
                              size: 16.0,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              message.duration != null ? _formatDuration(message.duration!) : '音频',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 11.0,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // AI-generated END - 消息内容

          if (isUser) ...[
            const SizedBox(width: 12.0),
            // AI-generated START - 用户头像
            CircleAvatar(
              radius: 20.0,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.person,
                size: 24.0,
                color: Colors.blue.shade700,
              ),
            ),
            // AI-generated END - 用户头像
          ],
        ],
      ),
    );
  }
  // AI-generated END - _buildMessageItem

  // AI-generated START - 格式化时间
  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
  // AI-generated END - _formatTime

  // AI-generated START - 格式化时长
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0 && remainingSeconds > 0) {
      return '$minutes分$remainingSeconds秒';
    } else if (minutes > 0) {
      return '$minutes分钟';
    } else {
      return '$remainingSeconds秒';
    }
  }
  // AI-generated END - _formatDuration
}
// AI-generated END - conversation_detail_page.dart
