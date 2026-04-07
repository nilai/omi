import 'package:flutter/material.dart';
import 'package:omi/providers/mp_message_provider.dart';

import '../../backend/http/mp_api/mp_chat.dart';
import '../../backend/schema/mp/mp_chat.dart';

/// 快速问题工具类（单例）
/// 用于管理从服务端加载的快速问题列表
class MPQuickQuestionUtil {
  /// 单例实例
  static final MPQuickQuestionUtil _instance = MPQuickQuestionUtil._internal();

  /// 获取单例实例
  factory MPQuickQuestionUtil() {
    return _instance;
  }

  /// 私有构造函数
  MPQuickQuestionUtil._internal();

// 从记忆仓库进入的AI助理 key为 chat_with_speaker;
  // 从Memory进入的AI助理 key为chat_with_memory；直接进入AI 助理 key为 normal

  final String KEY_NORMAL = 'normal';
  final String KEY_CHAT_WITH_MEMORY = 'chat_with_memory';
  final String KEY_CHAT_WITH_SPEAKER = 'chat_with_speaker';

  /// 服务端返回的问题属性，类型为 Map<String, List<String>>，可为 null
  Map<String, Map<String, List<String?>>>? _questionsMap;

  ///
  List<String> _normalKeys = [];

  final List<String> _DEFAULT_NORMAL_QUESTIONS = ['今天我应该怎么做？', '我昨天做了什么？'];

  /// 从记忆仓库进入的AI助理 key为 chat_with_speaker;
  Map<String, List<String?>> _normalQuestions = {};

  /// 从Memory进入的AI助理 key为chat_with_memory；
  List<String> _chatWithMemoryQuestions = [];

  /// 直接进入AI 助理 key为 normal
  List<String> _chatWithSpeakerQuestions = [];

  // map<map<string, list<string>>> suggestion

  /// 是否正在加载
  bool _isLoading = false;

  Future<List<String>> getQuestionsByChatType(MPChatPageType type) async {
    if (_questionsMap == null) {
      await loadQuestionsFromServer();
    }
    switch (type) {
      case MPChatPageType.normal:
        return _normalKeys.isNotEmpty ? _normalKeys : _DEFAULT_NORMAL_QUESTIONS;
      case MPChatPageType.expert:
        return [];
      case MPChatPageType.memory:
        return _chatWithMemoryQuestions.isNotEmpty
            ? _chatWithMemoryQuestions
            : ['有哪些需要跟进的地方?', '和对方沟通的风险点是哪些?', '还有哪些没有解决的问题?', '下次会议需要准备什么材料?'];
      case MPChatPageType.template:
        return [];
      case MPChatPageType.speaker:
        return _chatWithSpeakerQuestions.isNotEmpty
            ? _chatWithSpeakerQuestions
            : ['帮我总结一下近半年我们的沟通情况', '我们讨论的最重要三个话题', '前几次讨论我们还有没有没解决的问题'];
    }
  }

  /// 根据 key 获取问题列表（异步版本）
  /// 返回值不能为 null
  /// 判断属性有没有值，有值从属性中取
  /// 属性为 null，先加载，再取值
  /// 取不到值，返回空 list
  /// @param {String} key - 问题的 key
  /// @returns {Future<List<String>>} 问题列表，如果不存在则返回空列表
  List<String> getQuestionsByKey(String key) {
    if (_DEFAULT_NORMAL_QUESTIONS.contains(key)) {
      return [];
    }
    if (_normalQuestions.containsKey(key)) {
      return _normalQuestions[key]?.cast<String>().toList() ?? [];
    }
    return [];
  }

  /// 加载服务端返回的问题属性
  /// @returns {Future<void>} 异步加载完成
  Future<void> loadQuestionsFromServer() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;

    try {
      final response = await getChatSuggestion(MPGetChatSuggestionRequest());

      if (response != null && response.baseResp.code == 0) {
        _questionsMap = response.suggestion;
        debugPrint('-----hj----- _questionsMap: $_questionsMap');
        _normalKeys = response.suggestion[KEY_NORMAL]?.keys.toList() ?? [];
        debugPrint('-----hj----- _normalKeys: $_normalKeys');
        _chatWithMemoryQuestions = response.suggestion[KEY_CHAT_WITH_MEMORY]?.keys.toList() ?? [];
        debugPrint('-----hj----- _chatWithMemoryQuestions: $_chatWithMemoryQuestions');
        _chatWithSpeakerQuestions = response.suggestion[KEY_CHAT_WITH_SPEAKER]?.keys.toList() ?? [];
        debugPrint('-----hj----- _chatWithSpeakerQuestions: $_chatWithSpeakerQuestions');
        _normalQuestions = response.suggestion[KEY_NORMAL] ?? {};
        debugPrint('-----hj----- _normalQuestions: $_normalQuestions');
      }
    } catch (e) {
      debugPrint('-----hj----- loadQuestionsFromServer error: $e');
      _questionsMap = null;
    } finally {
      _isLoading = false;
    }
  }

  /// 清空问题映射
  void clearQuestionsMap() {
    _questionsMap = null;
  }
}
