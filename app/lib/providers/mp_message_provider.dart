import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omi/backend/http/api/messages.dart';
import 'package:omi/backend/schema/bt_device/bt_device.dart';
import 'package:omi/backend/schema/message.dart';
import 'package:omi/utils/alerts/app_snackbar.dart';
import 'package:omi/utils/file.dart';
import 'package:uuid/uuid.dart';

class MPMessagePageModel {
  /// 聊天ID
  String chatId;
  /// 会话ID
  String conversationId;
  /// 消息列表
  List<ServerMessage> messages;

  MPMessagePageModel({required this.chatId, required this.conversationId, required this.messages});
}

/// MP消息提供者，负责管理聊天消息的发送、接收功能
/// 继承自 ChangeNotifier，用于状态管理和 UI 更新通知
class MPMessageProvider extends ChangeNotifier {

  String chatId = '';

  MPMessageProvider({required this.chatId});

  /// 页面模型列表
  List<MPMessagePageModel> pageModels = [];

  /// 消息列表，按时间倒序排列（最新的在索引 0）
  List<ServerMessage> messages = [];

  /// 是否显示 AI 正在输入的指示器
  bool showTypingIndicator = false;

  /// 是否正在发送消息
  bool sendingMessage = false;

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
  /// @param {String?} appId - 关联的应用 ID
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

  /// 发送语音消息流到服务器
  /// @param {List<List<int>>} audioBytes - 音频字节数据列表
  /// @param {Function?} onFirstChunkRecived} - 收到第一个数据块时的回调函数
  /// @param {BleAudioCodec?} codec - 音频编解码器，用于确定帧大小
  /// 将音频数据保存为临时文件后，通过流式方式发送到服务器
  /// 实时处理服务器返回的消息块（思考过程、数据、完成、错误等）
  Future<void> sendVoiceMessageStreamToServer(
    List<List<int>> audioBytes, {
    Function? onFirstChunkRecived,
    BleAudioCodec? codec,
  }) async {
    try {
      File file = await FileUtils.saveAudioBytesToTempFile(
        audioBytes,
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - (audioBytes.length / 100).ceil(),
        codec?.getFrameSize() ?? 160,
      );

      setShowTypingIndicator(true);
      setSendingMessage(true);
      var message = ServerMessage.empty();
      messages.insert(0, message);
      notifyListeners();

      bool firstChunkRecieved = false;
      await for (var chunk in sendVoiceMessageStreamServer([file])) {
        if (!firstChunkRecieved && [MessageChunkType.data, MessageChunkType.done].contains(chunk.type)) {
          firstChunkRecieved = true;
          if (onFirstChunkRecived != null) {
            onFirstChunkRecived();
          }
        }

        if (chunk.type == MessageChunkType.think) {
          message.thinkings.add(chunk.text);
          notifyListeners();
          continue;
        }

        if (chunk.type == MessageChunkType.data) {
          message.text += chunk.text;
          notifyListeners();
          continue;
        }

        if (chunk.type == MessageChunkType.done) {
          message = chunk.message!;
          messages[0] = message;
          notifyListeners();
          continue;
        }

        if (chunk.type == MessageChunkType.message) {
          messages.insert(1, chunk.message!);
          notifyListeners();
          continue;
        }

        if (chunk.type == MessageChunkType.error) {
          message.text = chunk.text;
          notifyListeners();
          AppSnackbar.showSnackbarError('发送语音消息失败，请稍后重试');
          continue;
        }
      }
    } catch (e) {
      debugPrint('发送语音消息错误: $e');
      AppSnackbar.showSnackbarError('发送语音消息失败，请稍后重试');
      var message = ServerMessage.empty();
      message.text = ServerMessageChunk.failedMessage().text;
      messages.insert(0, message);
      notifyListeners();
    } finally {
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
