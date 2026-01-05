// AI-generated START - 对话详情页面
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omi/backend/schema/mp/mp_data_model.dart';
import 'package:omi/pages/mp_custom_utils/mp_const_utils.dart';
import 'package:omi/pages/mp_memo_todo/todo/providers/todo_provider.dart';
import 'package:omi/pages/mp_memo_todo/todo/widgets/todo_task_card.dart';
import 'package:omi/pages/mp_memory/conversation_detail/providers/conversation_detail_provider.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/action_buttons_card.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/audio_player_card.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/conversation_header_card.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/meeting_summary_card.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/mp_message_card.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/mp_tags_card.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/participants_card.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/tab_selector_card.dart';
import 'package:omi/pages/mp_newsetting/home/widgets/mp_common_app_bar.dart';
import 'package:omi/pages/mp_popup/new_task_popup.dart';
import 'package:omi/services/mp_audio_download.dart';
import 'package:provider/provider.dart';

import '../../../backend/http/mp_api/mp_memory.dart';
import '../../../backend/schema/mp/mp_memory.dart';
import '../../../providers/mp_message_provider.dart';
import '../../../providers/sync_provider.dart';
import '../../../services/mp_home_refresh_event_service.dart';
import '../../../utils/alerts/mp_memory_export_dialog.dart';
import '../../../utils/alerts/mp_share_memory_dialog.dart';
import '../../../utils/mp_local_records_util.dart';
import '../../memories/mp_memory_transition_page.dart';
import '../../memories/widgets/mp_memory_add_tag_dialog.dart';
import '../../memories/widgets/mp_memory_convert_dialog.dart';
import '../../memories/widgets/mp_memory_update_name_dialog.dart';
import '../../mp_chat/mp_chat.dart';
import '../../mp_chat/mp_chat_helper.dart';
import '../../mp_custom_utils/mp_timestamp_utils.dart';
import '../../mp_custom_utils/mp_toast_utils.dart';
import '../../mp_popup/mp_record_detail_more_popup.dart';
import '../../mp_popup/speaker_naming_popup.dart';
import '../merge_memory/mp_merge_memory_page.dart';

/// 对话详情页面
/// 显示特定对话的详细消息记录
class ConversationDetailPage extends StatefulWidget {
  // AI-generated START - 构造函数
  const ConversationDetailPage({
    super.key,
    required this.memory,
  });
  // AI-generated END - 构造函数

  /// 记忆数据
  final MPMemoryStruct memory;

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

      // 从 MPMemoryStruct 初始化数据
      provider.initializeFromMemory(widget.memory);

      // 加载默认标签的数据
      provider.loadDataForTab(_selectedTab);
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
          backgroundColor: MPConstUtils.backgroundColorGrey,
          appBar: MPCommonAppBar(
            title: '',
            showMoreButton: true,
            showShareButton: true,
            onMorePressed: () {
              _showMoreActionsDialog(context);
            },
            onSharePressed: () {
              MPShareMemoryDialog.show(context: context, memoryId: _memoryId);
            },
          ),
          body: _buildBody(provider),
        );
      },
    );
  }
  // AI-generated END - 构建方法

  // AI-generated START - 构建页面主体
  Widget _buildBody(ConversationDetailProvider provider) {
    return Column(
      children: [
        // AI-generated START - 可滚动内容区域
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // AI-generated START - 对话头部卡片
                ConversationHeaderCard(
                  title: provider.title ?? widget.memory.title,
                  summaryTime: provider.summaryTime ?? '',
                  onTapTitle: () async {
                    MPMemoryUpdateNameDialog.show(
                        context: context,
                        memoryId: _memoryId,
                        currentTitle: provider.title ?? widget.memory.title,
                        onSuccess: (title) {
                          provider.updateTitle(title);
                        });
                  },
                ),
                // AI-generated END - 对话头部卡片

                // AI-generated START - 参与人卡片
                if (provider.participants.isNotEmpty)
                  ParticipantsCard(
                    participants: provider.participants,
                  ),
                // AI-generated END - 参与人卡片

                // AI-generated START - 标签卡片
                MPTagsCard(
                  tags: provider.memory?.customLabels ?? [],
                  onAddTag: () {
                    _showAddTagDialog();
                  },
                ),
                // AI-generated END - 标签卡片

                // AI-generated START - 音频播放器卡片
                AudioPlayerCard(
                  title: '原始音频',
                  totalDurationSeconds: provider.duration ?? 0,
                  audioUrl: provider.recordFileUrl,
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
                    // 切换标签时加载对应的数据
                    final provider = Provider.of<ConversationDetailProvider>(context, listen: false);
                    provider.loadDataForTab(id);
                  },
                ),
                // AI-generated END - 标签选择器卡片

                // AI-generated START - 根据选中的标签显示内容
                _buildTabContent(_selectedTab),
                // AI-generated END - 根据选中的标签显示内容

                const SizedBox(height: 16.0),
              ],
            ),
          ),
        ),
        // AI-generated END - 可滚动内容区域

        // AI-generated START - 底部操作按钮（固定在底部）
        SafeArea(
          top: false,
          child: Container(
            color: MPConstUtils.backgroundColorGrey,
            padding: const EdgeInsets.only(top: 8.0),
            child: ActionButtonsCard(
              buttons: [
                ActionButton(
                  id: 'name_speaker',
                  label: '命名发言者',
                  icon: Icons.person_outline,
                  onTap: () {
                    final list = provider.summaryContent?.transcript ?? [];
                    if (list.isNotEmpty) {
                      SpeakerNamingPopup.show(
                        context: context,
                        items: list,
                        memeryId: _memoryId,
                        onfirm: () {
                          provider.reloadDetail();
                        },
                      );
                    } else {
                      MPToastUtils.showMessage('Transcript为空');
                    }
                  },
                ),
                ActionButton(
                  id: 'add_summary',
                  label: '追加总结',
                  icon: Icons.add_box_outlined,
                  onTap: () {
                    MPMergeMemoryPage.pushPage(
                        context: context,
                        memoryId: _memoryId,
                        onSuccess: () {
                          provider.reloadDetail();
                        });
                  },
                ),
                ActionButton(
                  id: 'ai_assistant',
                  label: 'AI助手',
                  icon: Icons.smart_toy,
                  onTap: () {
                    MPChatHelper.instance.memory = widget.memory;
                    MPChatPage.openChatPage(context,
                        chatId: _memoryId, title: widget.memory.title, type: MPChatPageType.memory);
                  },
                ),
              ],
            ),
          ),
        ),
        // AI-generated END - 底部操作按钮（固定在底部）
      ],
    );
  }
  // AI-generated END - _buildBody

  String get _memoryId {
    final provider = Provider.of<ConversationDetailProvider>(context, listen: false);
    return provider.memory?.id ?? widget.memory.id;
  }

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
    return Consumer<ConversationDetailProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // AI-generated START - 会议总结卡片
            MeetingSummaryCard(
              content: provider.summary ?? '暂无总结内容',
            ),
            // AI-generated END - 会议总结卡片
          ],
        );
      },
    );
  }
  // AI-generated END - _buildSummaryContent

  // AI-generated START - 构建思维导图内容
  Widget _buildMindMapContent() {
    return Consumer<ConversationDetailProvider>(
      builder: (context, provider, child) {
        // 优先使用 insightContent，如果没有则使用 aiExpertContent
        final content = provider.insightContent?.content ?? provider.aiExpertContent?.content;

        if (content == null || content.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: const Center(
              child: Text(
                '暂无思维导图内容',
                style: TextStyle(fontSize: 14.0, color: Color(0xFF1F2937), height: 1.5),
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 14.0,
              color: Color(0xFF1F2937),
              height: 1.5,
            ),
          ),
        );
      },
    );
  }
  // AI-generated END - _buildMindMapContent

  // AI-generated START - 构建转录内容
  Widget _buildTranscriptContent() {
    return Consumer<ConversationDetailProvider>(
      builder: (context, provider, child) {
        if (provider.transcripts.isEmpty) {
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
          children: provider.transcripts.map((message) {
            return _buildMessageItem(message);
          }).toList(),
        );
      },
    );
  }
  // AI-generated END - _buildTranscriptContent

  // AI-generated START - 构建待办列表内容
  Widget _buildTodoListContent() {
    return Consumer<ConversationDetailProvider>(
      builder: (context, provider, child) {
        final todos = provider.todos;

        if (todos.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: const Center(
              child: Text('暂无待办事项'),
            ),
          );
        }

        return Column(
          children: todos.map((todo) {
            // 格式化日期（从 ISO 8601 格式转换为 "Dec 16" 格式）
            String formattedDate = _formatTodoDate(todo.deadline);

            // 转换 priority 为 priorityTag 格式（首字母大写）
            print('122222todo.priority: ${todo.priority}');
            String? priorityTag;
            if (todo.priority.isNotEmpty) {
              if (todo.priority.length == 1) {
                priorityTag = todo.priority.toUpperCase();
              } else {
                priorityTag = todo.priority.substring(0, 1).toUpperCase() + todo.priority.substring(1).toLowerCase();
              }
            }

            return TodoTaskCard(
              id: todo.id,
              title: todo.title,
              description: todo.owner.name,
              date: formattedDate,
              priorityTag: priorityTag,
              status: todo.status,
              onTap: () {
                // 解析日期字符串（服务端返回的是 ISO 8601 格式，如 "2025-01-15"）
                DateTime? parsedDate;
                try {
                  if (todo.deadline.contains('-')) {
                    // 格式是 "YYYY-MM-DD"
                    parsedDate = DateTime.parse(todo.deadline);
                  } else {
                    // 格式是 "Dec 20"，需要转换为当前年份的日期
                    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    final parts = todo.deadline.split(' ');
                    if (parts.length == 2) {
                      final monthIndex = months.indexOf(parts[0]);
                      if (monthIndex != -1) {
                        final day = int.tryParse(parts[1]) ?? DateTime.now().day;
                        final now = DateTime.now();
                        parsedDate = DateTime(now.year, monthIndex + 1, day);
                      }
                    }
                  }
                } catch (e) {
                  debugPrint('解析日期失败: ${todo.deadline}, 错误: $e');
                  parsedDate = null;
                }

                // 解析优先级（服务端返回的 priority 可能是 "high", "normal", "low" 小写格式）
                TaskPriority? parsedPriority;
                if (todo.priority.isNotEmpty) {
                  try {
                    // 将服务端返回的 priority 转换为小写后匹配枚举
                    final priorityLower = todo.priority.toLowerCase();
                    parsedPriority = TaskPriority.values.firstWhere(
                      (e) => e.name.toLowerCase() == priorityLower,
                      orElse: () => TaskPriority.normal, // 如果找不到匹配项，使用默认值
                    );
                  } catch (e) {
                    debugPrint('解析优先级失败: ${todo.priority}, 错误: $e');
                    parsedPriority = TaskPriority.normal;
                  }
                } else {
                  parsedPriority = null;
                }

                final todoProvider = Provider.of<TodoProvider>(context, listen: false);

                NewTaskPopup.show(
                  context: context,
                  title: todo.title,
                  initialTitle: todo.title,
                  initialDueDate: parsedDate,
                  initialPriority: parsedPriority,
                  showMarkComplete: true, // 显示 Mark complete 复选框
                  showDeleteTask: true, // 显示删除任务按钮
                  isCompleted: todo.status == 2 ? true : false, // 初始完成状态
                  onDelete: () async {
                    await todoProvider.deleteTodo(todo.id);
                    // 刷新对话详情数据
                    final conversationProvider = Provider.of<ConversationDetailProvider>(context, listen: false);
                    if (conversationProvider.memory != null) {
                      conversationProvider.initializeFromMemory(conversationProvider.memory!);
                    }
                  },
                  onComplete: (isCompleted, title, dueDate, priority) async {
                    final now = DateTime.now();
                    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    final dateStr = dueDate != null
                        ? '${months[dueDate.month - 1]} ${dueDate.day}'
                        : '${months[now.month - 1]} ${now.day}';

                    final priorityTagStr = priority != null
                        ? (priority == TaskPriority.high
                            ? 'high'
                            : priority == TaskPriority.normal
                                ? 'normal'
                                : 'low')
                        : 'normal';
                    // 处理完成操作
                    await todoProvider.updateTodoWithRequest(
                        todoId: todo.id,
                        title: title,
                        priority: priorityTagStr,
                        deadline: dateStr,
                        isCompleted: isCompleted);
                    // 刷新对话详情数据
                    final conversationProvider = Provider.of<ConversationDetailProvider>(context, listen: false);
                    if (conversationProvider.memory != null) {
                      conversationProvider.initializeFromMemory(conversationProvider.memory!);
                    }
                  },
                );
              },
              onComplete: () async {
                final todoProvider = Provider.of<TodoProvider>(context, listen: false);
                await todoProvider.completeTodo(todo.id);
                // 刷新对话详情数据
                final conversationProvider = Provider.of<ConversationDetailProvider>(context, listen: false);
                if (conversationProvider.memory != null) {
                  conversationProvider.initializeFromMemory(conversationProvider.memory!);
                }
              },
              onDelete: () async {
                final todoProvider = Provider.of<TodoProvider>(context, listen: false);
                await todoProvider.deleteTodo(todo.id);
                // 刷新对话详情数据
                final conversationProvider = Provider.of<ConversationDetailProvider>(context, listen: false);
                if (conversationProvider.memory != null) {
                  conversationProvider.initializeFromMemory(conversationProvider.memory!);
                }
              },
            );
          }).toList(),
        );
      },
    );
  }
  // AI-generated END - _buildTodoListContent

  // AI-generated START - 构建消息项
  Widget _buildMessageItem(ConversationMessage message) {
    // 获取发送者姓名，如果没有则使用默认值
    final senderName = message.senderName ?? (message.type == MessageType.user ? '我' : 'AI助手');

    return MPMessageCard(
      message: MPMessageCardData(
        senderName: senderName,
        content: message.content,
        timestamp: message.time,
        avatarText: senderName.isNotEmpty ? senderName[0] : '?',
        avatarUrl: message.avatarUrl,
      ),
    );
  }
  // AI-generated END - _buildMessageItem

  // AI-generated START - 格式化待办日期
  /// 将 ISO 8601 格式的日期字符串转换为 "Dec 16" 格式
  String _formatTodoDate(String deadline) {
    try {
      // 尝试解析 ISO 8601 格式的日期字符串
      final date = DateTime.parse(deadline).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    } catch (e) {
      // 如果解析失败，返回原始字符串
      return deadline;
    }
  }
  // AI-generated END - _formatTodoDate

  void _showMoreActionsDialog(BuildContext context) {
    final actions = [
      MPRecordDetailMoreAction.addTag,
      MPRecordDetailMoreAction.export,
      MPRecordDetailMoreAction.copyTranscript,
      MPRecordDetailMoreAction.copySummary,
      MPRecordDetailMoreAction.regenerateSummary,
      MPRecordDetailMoreAction.deleteMemory,
    ];
    MPRecordDetailMorePopup.show(context: context, actions: actions).then((value) {
      if (value != null) {
        switch (value) {
          case MPRecordDetailMoreAction.addTag:
            _showAddTagDialog();
            break;
          case MPRecordDetailMoreAction.export:
            _showExportDialog();
            break;
          case MPRecordDetailMoreAction.copyTranscript:
            _copyTranscript();
            break;
          case MPRecordDetailMoreAction.copySummary:
            _copySummary();
            break;
          case MPRecordDetailMoreAction.regenerateSummary:
            _regenerateSummary();
            break;
          case MPRecordDetailMoreAction.deleteMemory:
            _deleteMemory();
            break;
        }
      }
    });
  }

  Future<void> _deleteMemory() async {
    final req = MPDeleteMemoryRequest(memoryId: _memoryId);
    final res = await deleteMemory(req);
    if (res != null && res.baseResp.code == 0) {
      MPHomeRefreshEventService().emitRefresh();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      MPToastUtils.showMessage(res?.baseResp.message ?? '删除失败');
    }
  }

  void _showAddTagDialog() {
    MPMemoryAddTagDialog.show(
        context: context,
        memoryId: _memoryId,
        onSuccess: (label) {
          final provider = Provider.of<ConversationDetailProvider>(context, listen: false);
          provider.reloadDetail();
        });
  }

  void _regenerateSummary() async {
    MPMemoryConvertDialog.show(context, memory: widget.memory, onGenerate: () {
      Future.delayed(const Duration(milliseconds: 500), () {
        MPHomeRefreshEventService().emitRefresh();
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MPMemoryTransitionPage(
              memory: widget.memory,
            ),
          ),
        );
      });
    });
  }

  void _copyTranscript() async {
    final provider = Provider.of<ConversationDetailProvider>(context, listen: false);
    final transcript = provider.transcripts;
    if (transcript.isNotEmpty) {
      String text = '';
      for (var message in transcript) {
        text += '${message.senderName}: ${message.content}\n';
      }
      if (text.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: text));
        MPToastUtils.showMessage('转录已复制到剪贴板');
      } else {
        MPToastUtils.showMessage('转录为空');
      }
    } else {
      MPToastUtils.showMessage('转录为空');
    }
  }

  void _copySummary() async {
    final provider = Provider.of<ConversationDetailProvider>(context, listen: false);
    final summary = provider.summary;
    if (summary != null) {
      await Clipboard.setData(ClipboardData(text: summary));
      MPToastUtils.showMessage('摘要已复制到剪贴板');
    } else {
      MPToastUtils.showMessage('摘要为空');
    }
  }

  void _showExportDialog() {
    MPMemoryExportDialog.show(
      context: context,
      onExportSelected: (exportType) {
        switch (exportType) {
          case MPMemoryExportType.audio:
            _exportAudio();
            break;
          case MPMemoryExportType.pdf:
            _exportPDF();
            break;
          case MPMemoryExportType.docx:
            _exportDOCX();
            break;
        }
      },
    );
  }

  void _exportAudio() async {
    final provider = Provider.of<ConversationDetailProvider>(context, listen: false);
    final localPath = await MPLocalRecordsUtil.instance.getLocalRecordPath(provider.recordFileUrl);
    if (localPath != null && localPath.isNotEmpty) {
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      await syncProvider.shareLocalAudioFile(localPath);
    } else {
      final result = await MPAudioDownloadService.instance.downloadAndSaveAudio(provider.recordFileUrl);
      if (result != null) {
        MPLocalRecordsUtil.instance.addLocalRecord(result.path,
            createAt: MPTimestampUtils.timestampNow,
            fileName: result.fileName,
            source: 'Mobile Phone',
            isRemoved: true);
        final syncProvider = Provider.of<SyncProvider>(context, listen: false);
        await syncProvider.shareLocalAudioFile(result.path);
      } else {
        MPToastUtils.showMessage('下载失败');
      }
    }
  }

  void _exportPDF() {
    // TODO: 实现 PDF 导出功能
    MPToastUtils.showFeatureComingSoon();
  }

  void _exportDOCX() {
    // TODO: 实现 DOCX 导出功能
    MPToastUtils.showFeatureComingSoon();
  }
}
// AI-generated END - conversation_detail_page.dart
