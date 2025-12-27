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

  /// 服务端返回的问题属性，类型为 Map<String, List<String>>，可为 null
  Map<String, List<String>>? _questionsMap;

  /// 是否正在加载
  bool _isLoading = false;

  /// 获取服务端返回的问题属性
  Map<String, List<String>>? get questionsMap => _questionsMap;

  List<String> getQuestionsByChatType(MPChatPageType type) {
    switch (type) {
      case MPChatPageType.normal:
        return [];
      case MPChatPageType.expert:
        return [];
      case MPChatPageType.memory:
        return [
          '有哪些需要跟进的地方?',
          '和对方沟通的风险点是哪些?',
          '还有哪些没有解决的问题?',
          '下次会议需要准备什么材料?',
        ];
      case MPChatPageType.template:
        return [];
      case MPChatPageType.speaker:
        return [
          '帮我总结一下近半年我们的沟通情况',
          '我们讨论的最重要三个话题',
          '前几次讨论我们还有没有没解决的问题',
        ];
    }
  }

  /// 根据 key 获取问题列表（异步版本）
  /// 返回值不能为 null
  /// 判断属性有没有值，有值从属性中取
  /// 属性为 null，先加载，再取值
  /// 取不到值，返回空 list
  /// @param {String} key - 问题的 key
  /// @returns {Future<List<String>>} 问题列表，如果不存在则返回空列表
  Future<List<String>> getQuestionsByKey(String key) async {
    // 判断属性有没有值，有值从属性中取
    if (_questionsMap != null && _questionsMap!.containsKey(key)) {
      final questions = _questionsMap![key];
      if (questions != null && questions.isNotEmpty) {
        return questions;
      }
    }

    // 属性为 null，先加载，再取值
    if (_questionsMap == null && !_isLoading) {
      await loadQuestionsFromServer();
      // 加载后再次尝试获取
      if (_questionsMap != null && _questionsMap!.containsKey(key)) {
        final questions = _questionsMap![key];
        if (questions != null && questions.isNotEmpty) {
          return questions;
        }
      }
    }

    // 取不到值，返回空 list
    return [];
  }

  /// 获取所有 keys（异步版本）
  /// 返回值不能为 null
  /// 判断属性有没有值，有值从属性中取
  /// 属性为 null，先加载，再取值
  /// 取不到值，返回空 list
  /// @returns {Future<List<String>>} 所有 keys 列表，如果不存在则返回空列表
  Future<List<String>> getAllKeys() async {
    // 判断属性有没有值，有值从属性中取
    if (_questionsMap != null && _questionsMap!.isNotEmpty) {
      debugPrint('-----hj----- getAllKeys success: ${_questionsMap!.keys.toList().toString()}');
      return _questionsMap!.keys.toList();
    }

    // 属性为 null，先加载，再取值
    if (_questionsMap == null && !_isLoading) {
      await loadQuestionsFromServer();
      // 加载后再次尝试获取
      if (_questionsMap != null && _questionsMap!.isNotEmpty) {
        debugPrint('-----hj----- getAllKeys success: ${_questionsMap!.keys.toList().toString()}');
        return _questionsMap!.keys.toList();
      }
    }
    debugPrint('-----hj----- getAllKeys error: ${_questionsMap?.keys.toList().toString()}');
    // 取不到值，返回空 list
    return [];
  }

  /// 根据 key 获取问题列表（同步版本）
  /// 如果数据已加载，直接返回；否则返回空列表
  /// @param {String} key - 问题的 key
  /// @returns {List<String>} 问题列表，如果不存在则返回空列表
  List<String> getQuestionsByKeySync(String key) {
    // 判断属性有没有值，有值从属性中取
    if (_questionsMap != null && _questionsMap!.containsKey(key)) {
      final questions = _questionsMap![key];
      if (questions != null && questions.isNotEmpty) {
        return questions;
      }
    }

    // 取不到值，返回空 list
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
        final questionsData = response.suggestion;
        _questionsMap = questionsData;
      }
    } catch (e) {
      debugPrint('-----hj----- loadQuestionsFromServer error: $e');
      _questionsMap = null;
    } finally {
      _isLoading = false;
    }
  }

  /// 手动设置问题映射（用于测试或本地数据）
  /// @param {Map<String, List<String>>?} questionsMap - 问题映射
  void setQuestionsMap(Map<String, List<String>>? questionsMap) {
    _questionsMap = questionsMap;
  }

  /// 清空问题映射
  void clearQuestionsMap() {
    _questionsMap = null;
  }
}
