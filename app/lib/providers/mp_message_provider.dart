import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omi/backend/http/api/messages.dart';
import 'package:omi/backend/schema/message.dart';
import 'package:omi/utils/alerts/app_snackbar.dart';
import 'package:uuid/uuid.dart';

import '../backend/http/mp_api/mp_chat.dart';
import '../backend/schema/mp/mp_chat.dart';

// 聊天页面类型。不同类型调用url接口入参不同。
enum MPChatPageType {
  // 普通聊天
  normal,
  // 记忆总结
  memory,
  // 模板聊天
  template,
  // AI分析助手
  aiAssistant,
  // 专家模型
  expert,
}

class MPMessagePageModel {
  /// 聊天ID
  String chatId;

  /// 会话ID
  String conversationId;

  String title;

  MPChatPageType type;

  /// 消息列表
  List<ServerMessage> messages;

  MPMessagePageModel(
      {required this.chatId,
      required this.conversationId,
      required this.messages,
      this.title = '',
      this.type = MPChatPageType.normal});
}

/// MP消息提供者，负责管理聊天消息的发送、接收功能
/// 继承自 ChangeNotifier，用于状态管理和 UI 更新通知
class MPMessageProvider extends ChangeNotifier {
  /// 聊天ID
  String chatId = '';

  /// 聊天标题
  String title = '';

  /// 聊天页面类型
  MPChatPageType type = MPChatPageType.normal;

  MPMessageProvider({this.chatId = '', this.title = '', this.type = MPChatPageType.normal});

  /// 页面模型列表
  List<MPMessagePageModel> pageModels = [];

  MPMessagePageModel? curPageModel;

  /// 消息列表，按时间倒序排列（最新的在索引 0）
  List<ServerMessage> messages = [];

  /// 是否显示 AI 正在输入的指示器
  bool showTypingIndicator = false;

  /// 是否正在发送消息
  bool sendingMessage = false;

  /// 更新页面消息列表
  /// @param {String} conversationId - 会话ID
  /// 没有会话ID则清空消息列表，并通过chatId获取会话ID
  void updatePageMessages(String conversationId) async {
    messages = [];
    curPageModel = null;
    if (conversationId.isNotEmpty) {
      for (var element in pageModels) {
        if (element.conversationId == conversationId) {
          curPageModel = element;
          break;
        }
      }
      final req = MPGetConversationDetailRequest(conversationId: conversationId);
      final response = await getConversationDetail(req);
      if (response != null) {
        messages = response.contents
            .map((e) =>
                ServerMessage('', DateTime.now(), e.content, MessageSender.ai, MessageType.text, '', false, [], [], []))
            .toList();
        curPageModel?.messages = messages;
      }
      messages = curPageModel?.messages ?? [];
      notifyListeners();
      return;
    }

    curPageModel = null;

    final req = MPCreateConversationRequest(
      title: title,
      expertId: type == MPChatPageType.expert ? chatId : '',
      memoryId: type == MPChatPageType.memory ? chatId : '',
      templateId: type == MPChatPageType.template ? chatId : '',
      speakerId: type == MPChatPageType.aiAssistant ? chatId : '',
    );
    final response = await createConversation(req);
    if (response != null) {
      final model =
          MPMessagePageModel(chatId: chatId, conversationId: response.conversationId, messages: [], type: type);
      pageModels.add(model);
      curPageModel = model;
    }
    notifyListeners();
  }

  /// 设置是否正在发送消息的标志
  /// @param {bool} value - 是否正在发送消息
  void setSendingMessage(bool value) {
    sendingMessage = value;
    notifyListeners();
  }

  /// 设置是否显示输入指示器
  /// @param {bool} value - 是否显示输入指示器
  void setShowTypingIndicator(bool value) {
    showTypingIndicator = value;
    notifyListeners();
  }

  /// 添加一条服务器返回的消息到消息列表
  /// @param {ServerMessage} message - 要添加的消息对象
  /// 如果消息 ID 已存在则不会重复添加
  void addMessage(ServerMessage message) {
    if (messages.any((m) => m.id == message.id)) {
      return;
    }
    messages.insert(0, message);
    notifyListeners();
  }

  /// 在本地添加一条用户消息（发送前显示）
  /// @param {String} messageText - 消息文本内容
  /// @param {String?} appId - 关联的应用 ID
  /// 创建一条临时消息并插入到消息列表顶部
  void addMessageLocally(String messageText, {String? appId}) {
    var message = ServerMessage(
      const Uuid().v4(),
      DateTime.now(),
      messageText,
      MessageSender.human,
      MessageType.text,
      appId,
      false,
      [],
      [],
      [],
    );
    if (messages.any((m) => m.id == message.id)) {
      return;
    }
    messages.insert(0, message);
    notifyListeners();
  }

  /// 发送文本消息流到服务器
  /// @param {String} text - 要发送的消息文本
  /// 通过流式方式发送消息，实时接收并显示 AI 的回复
  /// 使用缓冲区机制优化 UI 更新频率（每 100ms 刷新一次）
  /// 处理思考过程、数据流、完成和错误等不同类型的消息块
  Future<void> sendMessageStreamToServer(String text, {String? appId}) async {
    setShowTypingIndicator(true);
    setSendingMessage(true);

    var message = ServerMessage.empty(appId: appId);
    messages.insert(0, message);
    notifyListeners();

    String textBuffer = '';
    Timer? timer;

    void flushBuffer() {
      if (textBuffer.isNotEmpty) {
        message.text += textBuffer;
        textBuffer = '';
        HapticFeedback.lightImpact();
        notifyListeners();
      }
    }

    try {
      await for (var chunk in sendMessageStreamServer(text, appId: appId)) {
        if (chunk.type == MessageChunkType.think) {
          flushBuffer();
          message.thinkings.add(chunk.text);
          notifyListeners();
          continue;
        }

        if (chunk.type == MessageChunkType.data) {
          textBuffer += chunk.text;
          timer ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
            flushBuffer();
          });
          continue;
        }

        timer?.cancel();
        timer = null;
        flushBuffer();

        if (chunk.type == MessageChunkType.done) {
          message = chunk.message!;
          messages[0] = message;
          notifyListeners();
          continue;
        }

        if (chunk.type == MessageChunkType.error) {
          message.text = chunk.text;
          notifyListeners();
          AppSnackbar.showSnackbarError('发送消息失败，请稍后重试');
          continue;
        }

        if (chunk.type == MessageChunkType.message) {
          messages.insert(1, chunk.message!);
          notifyListeners();
          continue;
        }
      }
    } catch (e) {
      debugPrint('发送消息错误: $e');
      message.text = ServerMessageChunk.failedMessage().text;
      notifyListeners();
      AppSnackbar.showSnackbarError('发送消息失败，请稍后重试');
    } finally {
      timer?.cancel();
      flushBuffer();
      setShowTypingIndicator(false);
      setSendingMessage(false);
    }
  }

  /// 从本地消息列表中移除指定 ID 的消息
  /// @param {String} id - 要移除的消息 ID
  void removeLocalMessage(String id) {
    messages.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  /// 清空消息列表
  void clearMessages() {
    messages.clear();
    notifyListeners();
  }
}
