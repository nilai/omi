// AI-generated START - 对话详情状态管理Provider
import 'package:flutter/material.dart';
import 'package:omi/backend/schema/mp/mp_data_model.dart';
import 'package:omi/pages/mp_custom_utils/mp_timestamp_utils.dart';
import 'package:omi/pages/mp_memory/conversation_detail/widgets/participants_card.dart';

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

  // AI-generated START - 消息列表
  List<ConversationMessage> _messages = [];
  // AI-generated END - _messages

  // AI-generated START - 参与者列表
  List<Participant> _participants = [];
  // AI-generated END - _participants

  // AI-generated START - 获取对话ID
  String? get conversationId => _conversationId;
  // AI-generated END - conversationId

  // AI-generated START - 获取对话标题
  String? get title => _title;
  // AI-generated END - title

  // AI-generated START - 获取消息列表
  List<ConversationMessage> get messages => _messages;
  // AI-generated END - messages

  // AI-generated START - 获取参与者列表
  List<Participant> get participants => _participants;
  // AI-generated END - participants

  // AI-generated START - 设置对话信息
  void setConversationInfo(String conversationId, String? title) {
    _conversationId = conversationId;
    _title = title;
    notifyListeners();
  }
  // AI-generated END - setConversationInfo

  // AI-generated START - 初始化对话详情（从 MPMemoryStruct）
  void initializeFromMemory(MPMemoryStruct memory) {
    // 设置对话信息
    _conversationId = memory.id;
    _title = memory.title;

    // 从 summaryContent 中提取参与者
    if (memory.summaryContent != null) {
      _participants = memory.summaryContent!.participants.map((speaker) {
        return Participant(
          id: speaker.id,
          name: speaker.name,
        );
      }).toList();
    } else {
      _participants = [];
    }

    // 从 summaryContent 中提取转录消息
    if (memory.summaryContent != null && memory.summaryContent!.transcript.isNotEmpty) {
      _messages = memory.summaryContent!.transcript.map((transcript) {
        // 将时间字符串转换为 DateTime（这里简化处理，实际可能需要更复杂的解析）
        final createdAt = MPTimestampUtils.timestampToDateTime(memory.createAt);

        return ConversationMessage(
          id: transcript.id,
          content: transcript.content,
          createdAt: createdAt,
          type: MessageType.user, // 可以根据 speaker 判断类型
        );
      }).toList();
    } else {
      _messages = [];
    }

    notifyListeners();
  }
  // AI-generated END - initializeFromMemory

  // AI-generated START - 添加消息
  void addMessage(ConversationMessage message) {
    _messages.add(message);
    notifyListeners();
  }
  // AI-generated END - addMessage

  // AI-generated START - 删除消息
  void deleteMessage(String messageId) {
    _messages.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }
  // AI-generated END - deleteMessage

  // AI-generated START - 清空消息
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
  // AI-generated END - clearMessages

  // AI-generated START - 重置状态
  void reset() {
    _conversationId = null;
    _title = null;
    _messages.clear();
    _participants.clear();
    notifyListeners();
  }
  // AI-generated END - reset
}
// AI-generated END - conversation_detail_provider.dart
