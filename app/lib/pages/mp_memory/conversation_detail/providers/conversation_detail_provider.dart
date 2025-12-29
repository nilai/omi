// AI-generated START - 对话详情状态管理Provider
import 'package:flutter/material.dart';
import 'package:omi/backend/http/mp_api/mp_memory.dart';
import 'package:omi/backend/schema/mp/mp_data_model.dart';
import 'package:omi/backend/schema/mp/mp_memory.dart';
import 'package:omi/pages/mp_custom_utils/mp_timestamp_utils.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/participants_card.dart';

import '../../../../utils/mp_local_records_util.dart';

/// 对话消息数据模型
class ConversationMessage {
  // AI-generated START - 构造函数
  const ConversationMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    this.type = MessageType.user,
    this.audioUrl,
    this.duration,
    this.senderName,
    this.avatarUrl,
  });
  // AI-generated END - 构造函数

  /// 消息ID
  final String id;

  /// 消息内容
  final String content;

  /// 创建时间
  final DateTime createdAt;

  /// 消息类型
  final MessageType type;

  /// 音频URL（可选）
  final String? audioUrl;

  /// 音频时长（秒，可选）
  final int? duration;

  /// 发送者姓名（可选）
  final String? senderName;

  /// 头像URL（可选）
  final String? avatarUrl;
}

/// 消息类型枚举
enum MessageType {
  // AI-generated START - 用户消息
  user,
  // AI-generated END - user

  // AI-generated START - AI回复
  ai,
  // AI-generated END - ai
}

/// 对话详情状态管理Provider
/// 管理特定对话的详细消息记录
class ConversationDetailProvider with ChangeNotifier {
  // AI-generated START - 对话ID
  String? _conversationId;
  // AI-generated END - _conversationId

  // AI-generated START - 对话标题
  String? _title;
  // AI-generated END - _title
  // AI-generated START - 对话时长
  int? _duration;
  // AI-generated END - _duration
  // AI-generated START - 摘要时间
  String? _summaryTime;
  // AI-generated END - _summaryTime
  // AI-generated START - 获取摘要时间
  String? get summaryTime => _summaryTime;
  // AI-generated END - summaryTime

  String? _summary;

  // AI-generated START - 消息列表
  List<ConversationMessage> _transcripts = [];
  // AI-generated END - _messages

  // AI-generated START - 参与者列表
  final List<Participant> _participants = [];
  // AI-generated END - _participants

  // AI-generated START - 获取对话ID
  String? get conversationId => _conversationId;
  // AI-generated END - conversationId

  // AI-generated START - 获取对话标题
  String? get title => _title;
  // AI-generated END - title

  // AI-generated START - 获取对话时长
  int? get duration => _duration;
  // AI-generated END - duration

  // AI-generated START - 获取消息列表
  List<ConversationMessage> get transcripts => _transcripts;
  // AI-generated END - messages

  // AI-generated START - 获取参与者列表
  List<Participant> get participants => _participants;
  // AI-generated END - participants

  // AI-generated START - 原始记忆数据
  MPMemoryStruct? _memory;
  // AI-generated END - _memory

  // AI-generated START - 获取原始记忆数据
  MPMemoryStruct? get memory => _memory;
  // AI-generated END - memory

  // AI-generated START - 获取摘要内容
  String? get summary => _summary;
  // AI-generated END - summary

  // AI-generated START - 搜索关键词
  String _searchQuery = '';
  // AI-generated END - _searchQuery

  // AI-generated START - 获取搜索关键词
  String get searchQuery => _searchQuery;
  // AI-generated END - searchQuery

  MPSummaryMemoryStruct? get summaryContent => _memory?.summaryContent;

  // AI-generated START - 设置搜索关键词
  void setSearchQuery(String query) {
    _searchQuery = query;
    // 搜索功能暂时不实现
    notifyListeners();
  }
  // AI-generated END - setSearchQuery

  // AI-generated START - 获取待办列表
  List<MPTodoStruct> get todos {
    if (_memory?.summaryContent?.todos != null) {
      return _memory!.summaryContent!.todos;
    }
    return [];
  }
  // AI-generated END - todos

  // AI-generated START - 获取仅录音内容
  MPOnlyRecordMemoryStruct? get onlyRecordContent => _memory?.onlyRecordContent;
  // AI-generated END - onlyRecordContent

  // AI-generated START - 获取洞察内容
  MPInsightMemoryStruct? get insightContent => _memory?.insightContent;
  // AI-generated END - insightContent

  // AI-generated START - 获取AI专家内容
  MPAiExpertMemoryStruct? get aiExpertContent => _memory?.aiExpertContent;
  // AI-generated END - aiExpertContent

  // AI-generated START - 获取录音文件URL
  Future<String>? get recordFileUrl async {
    String recordFile = '';
    if (memory?.onlyRecordContent != null) {
      recordFile = memory?.onlyRecordContent!.recordFile ?? '';
    } else if (memory?.summaryContent != null) {
      recordFile = memory?.summaryContent!.recordUrl ?? '';
    }
    final localPath = await MPLocalRecordsUtil.instance.getLocalRecordPath(recordFile);
    return localPath;
  }
  // AI-generated END - recordFileUrl

  void updateTitle(String title) {
    _title = title;
    notifyListeners();
  }

  // AI-generated START - 根据标签ID加载对应的数据
  void loadDataForTab(String tabId) {
    notifyListeners();
  }
  // AI-generated END - loadDataForTab

  // AI-generated START - 设置对话信息
  void setConversationInfo(String conversationId, String? title) {
    _conversationId = conversationId;
    _title = title;
    notifyListeners();
  }
  // AI-generated END - setConversationInfo

  // AI-generated START - 初始化对话详情（从 MPMemoryStruct）
  void initializeFromMemory(MPMemoryStruct memory) {
    // 保存原始记忆数据
    _memory = memory;

    // 设置对话信息
    _conversationId = memory.id;
    _title = memory.title;
    _duration = memory.duration;
    _summaryTime = MPTimestampUtils.timestampToRelativeDateString(memory.createAt);

    _summary = memory.summaryContent?.summary;

    // 如果 memory 数据不完整，调用接口获取详情
    _loadMemoryDetail(memory.id);

    notifyListeners();
  }

  void reloadDetail() {
    _loadMemoryDetail(memory?.id ?? '');
  }

  // AI-generated START - 加载记忆详情
  Future<void> _loadMemoryDetail(String memoryId) async {
    try {
      final response = await getMemoryDetail(
        MPGetMemoryDetailRequest(memoryId: memoryId),
      );

      if (response != null && response.baseResp.code == 0) {
        // 更新记忆数据
        _memory = response.memory;

        // 更新对话信息
        _conversationId = response.memory.id;
        _title = response.memory.title;
        _duration = response.memory.duration;
        _summaryTime = MPTimestampUtils.timestampToRelativeDateString(response.memory.createAt);

        // 更新摘要
        _summary = response.memory.summaryContent?.summary;
        _loadTranscriptData(response.memory);
        notifyListeners();
      } else {
        debugPrint('获取记忆详情失败: ${response?.baseResp.message ?? '未知错误'}');
      }
    } catch (e) {
      debugPrint('调用 getMemoryDetail 接口失败: $e');
    }
  }
  // AI-generated END - _loadMemoryDetail

  // AI-generated START - 加载转录数据
  void _loadTranscriptData(MPMemoryStruct memory) {
    debugPrint('------hj------ _loadTranscriptData: ${memory.summaryContent?.toJson()}');
    // 从 summaryContent 中提取转录消息
    final list = memory.summaryContent?.transcript ?? [];
    if (list.isNotEmpty) {
      _transcripts = list.map((transcript) {
        // 将时间字符串转换为 DateTime（这里简化处理，实际可能需要更复杂的解析）
        final createdAt = MPTimestampUtils.timestampToDateTime(memory.createAt);

        // 根据 speaker 判断消息类型（如果是用户自己的声音，则为 user，否则为 ai）
        final messageType = transcript.speaker.myselfVoice == true ? MessageType.user : MessageType.ai;

        return ConversationMessage(
          id: transcript.id,
          content: transcript.content,
          createdAt: createdAt,
          type: messageType,
          duration: _duration,
          senderName: transcript.speaker.name,
          avatarUrl: transcript.speaker.avatar.isNotEmpty ? transcript.speaker.avatar : null,
        );
      }).toList();
    } else {
      // 生成假数据
      _transcripts = [];
    }
  }
  // AI-generated END - _loadTranscriptData
  // AI-generated END - initializeFromMemory
}
// AI-generated END - conversation_detail_provider.dart
