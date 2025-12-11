// AI-generated START - 对话详情状态管理Provider
import 'package:flutter/material.dart';
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

  // AI-generated START - 是否正在加载
  bool _isLoading = false;
  // AI-generated END - _isLoading

  // AI-generated START - 错误信息
  String? _error;
  // AI-generated END - _error

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

  // AI-generated START - 获取是否正在加载
  bool get isLoading => _isLoading;
  // AI-generated END - isLoading

  // AI-generated START - 获取错误信息
  String? get error => _error;
  // AI-generated END - error

  // AI-generated START - 设置加载状态
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  // AI-generated END - setLoading

  // AI-generated START - 设置错误信息
  void setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
  // AI-generated END - setError

  // AI-generated START - 设置对话信息
  void setConversationInfo(String conversationId, String? title) {
    _conversationId = conversationId;
    _title = title;
    notifyListeners();
  }
  // AI-generated END - setConversationInfo

  // AI-generated START - 加载对话详情
  Future<void> loadConversationDetail(String conversationId) async {
    setLoading(true);
    setError(null);
    try {
      // TODO: 从API或本地存储加载对话详情
      // final conversationDetail = await conversationService.fetchConversationDetail(conversationId);
      // _conversationId = conversationId;
      // _title = conversationDetail.title;
      // _messages = conversationDetail.messages;
      await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络请求

      // AI-generated START - 默认测试数据
      _conversationId = conversationId;

      // AI-generated START - 加载参与者数据
      _participants = const [
        Participant(
          id: '1',
          name: '叶志伟',
          avatarBackgroundColor: Colors.grey,
        ),
        Participant(
          id: '2',
          name: '叶天命',
          avatarBackgroundColor: Colors.grey,
        ),
        Participant(
          id: '3',
          name: '叶成功',
          avatarBackgroundColor: Colors.amber,
        ),
      ];
      // AI-generated END - 加载参与者数据

      final now = DateTime.now();
      _messages = [
        ConversationMessage(
          id: '1',
          content: '讨论了AI硬件市场的需求分析和产品设计方案,确定了以用户体验为核心的差异化策略。我们需要重点关注用户痛点和市场空白。',
          createdAt: now.subtract(const Duration(minutes: 42)),
          type: MessageType.user,
        ),
        ConversationMessage(
          id: '2',
          content: '根据市场调研数据，AI硬件市场正在快速增长。建议从以下几个方面入手：1. 用户体验优化 2. 价格策略 3. 渠道拓展 4. 品牌建设。',
          createdAt: now.subtract(const Duration(minutes: 40)),
          type: MessageType.ai,
        ),
        ConversationMessage(
          id: '3',
          content: '关于产品设计，我认为应该采用模块化设计，让用户可以根据需求自由组合功能。这样既能满足不同用户的需求，又能降低生产成本。',
          createdAt: now.subtract(const Duration(minutes: 38)),
          type: MessageType.user,
        ),
        ConversationMessage(
          id: '4',
          content: '模块化设计是个很好的想法。同时建议加入AI语音助手功能，提升产品的智能化水平。可以考虑与现有的语音识别技术结合。',
          createdAt: now.subtract(const Duration(minutes: 36)),
          type: MessageType.ai,
        ),
        ConversationMessage(
          id: '5',
          content: '市场推广方面，我们可以先在小众市场测试，收集用户反馈后再大规模推广。这样可以降低风险，提高成功率。',
          createdAt: now.subtract(const Duration(minutes: 34)),
          type: MessageType.user,
        ),
        ConversationMessage(
          id: '6',
          content: '同意这个策略。建议选择对新技术接受度高的用户群体作为初期目标，比如科技爱好者和早期采用者。同时建立用户社区，促进口碑传播。',
          createdAt: now.subtract(const Duration(minutes: 32)),
          type: MessageType.ai,
        ),
      ];
      // AI-generated END - 默认测试数据

      notifyListeners();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
  // AI-generated END - loadConversationDetail

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
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
  // AI-generated END - reset
}
// AI-generated END - conversation_detail_provider.dart
