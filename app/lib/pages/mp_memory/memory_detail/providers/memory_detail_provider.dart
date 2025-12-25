// AI-generated START - 记忆详情状态管理Provider
import 'package:flutter/material.dart';
import 'package:omi/backend/http/mp_api/mp_speaker.dart';
import 'package:omi/backend/schema/mp/mp_data_model.dart';
import 'package:omi/backend/schema/mp/mp_speaker.dart';
import 'package:omi/pages/mp_custom_utils/mp_timestamp_utils.dart';
import 'package:omi/pages/mp_memory/home/providers/memory_provider.dart';

/// 对话摘要数据模型
class ConversationSummary {
  // AI-generated START - 构造函数
  const ConversationSummary({
    required this.id,
    required this.title,
    required this.summary,
    required this.date,
    required this.durationSeconds,
    required this.participantCount,
  });
  // AI-generated END - 构造函数

  /// 摘要ID
  final String id;

  /// 对话标题
  final String title;

  /// 对话摘要
  final String summary;

  /// 对话日期（格式：YYYY-MM-DD）
  final String date;

  /// 对话时长（秒）
  final int durationSeconds;

  /// 参与人数
  final int participantCount;
}

/// 记忆详情状态管理Provider
/// 管理特定人物记忆的详细信息和对话记录
class MemoryDetailProvider with ChangeNotifier {
  // AI-generated START - 当前记忆项
  CharacterMemoryItem? _memoryItem;
  // AI-generated END - _memoryItem

  // AI-generated START - 对话摘要列表
  List<ConversationSummary> _conversationSummaries = [];
  // AI-generated END - _conversationSummaries

  // AI-generated START - 原始记忆数据列表
  List<MPMemoryStruct> _memories = [];
  // AI-generated END - _memories

  // AI-generated START - 是否正在加载
  bool _isLoading = false;
  // AI-generated END - _isLoading

  // AI-generated START - 错误信息
  String? _error;
  // AI-generated END - _error

  // AI-generated START - 获取当前记忆项
  CharacterMemoryItem? get memoryItem => _memoryItem;
  // AI-generated END - memoryItem

  // AI-generated START - 获取对话摘要列表
  List<ConversationSummary> get conversationSummaries => _conversationSummaries;
  // AI-generated END - conversationSummaries

  // AI-generated START - 根据ID获取记忆数据
  MPMemoryStruct? getMemoryById(String id) {
    try {
      return _memories.firstWhere((memory) => memory.id == id);
    } catch (e) {
      return null;
    }
  }
  // AI-generated END - getMemoryById

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

  // AI-generated START - 设置记忆项
  void setMemoryItem(CharacterMemoryItem? item) {
    _memoryItem = item;
    notifyListeners();
  }
  // AI-generated END - setMemoryItem

  // AI-generated START - 加载记忆详情和对话摘要
  Future<void> loadMemoryDetail(String memoryId) async {
    setLoading(true);
    setError(null);
    try {
      // 调用 getSpeakerDetail 接口
      final response = await getSpeakerDetail(
        MPGetSpeakerDetailRequest(
          speakerId: memoryId,
        ),
      );

      if (response != null && response.baseResp.code == 0) {
        // 将 speaker 信息转换为 CharacterMemoryItem
        final speaker = response.speaker;
        _memoryItem = CharacterMemoryItem(
          id: speaker.id,
          name: speaker.name,
          conversationCount: response.memoryTotal,
          avatarUrl: speaker.avatar.isNotEmpty ? speaker.avatar : null,
        );

        // 保存原始记忆数据
        _memories = response.memorys;

        // 将 memorys 列表转换为 ConversationSummary 列表
        _conversationSummaries = response.memorys.map((memory) {
          // 从 createAt 时间戳转换为日期字符串
          final dateStr = MPTimestampUtils.timestampToRelativeDateString(memory.createAt);

          // 获取参与人数（从 summaryContent 中获取，如果没有则默认为 0）
          int participantCount = 0;
          if (memory.summaryContent != null) {
            participantCount = memory.summaryContent!.participants.length;
          }

          // 获取摘要内容（优先使用 summaryContent.summary，否则使用 content）
          String summaryText = memory.content;
          // if (memory.summaryContent != null && memory.summaryContent!.summary.isNotEmpty) {
          //   summaryText = memory.summaryContent!.summary;
          // }

          print('memory.duration: ${memory.duration}');
          return ConversationSummary(
            id: memory.id,
            title: memory.title,
            summary: summaryText,
            date: dateStr,
            durationSeconds: memory.duration,
            participantCount: participantCount,
          );
        }).toList();

        notifyListeners();
      } else {
        debugPrint('Error loading memory detail: ${response?.baseResp.message ?? "Unknown error"}');
        setError(response?.baseResp.message ?? '加载失败');
      }
    } catch (e) {
      debugPrint('Error loading memory detail: $e');
      setError('加载失败: $e');
    } finally {
      setLoading(false);
    }
  }
  // AI-generated END - loadMemoryDetail
}
// AI-generated END - memory_detail_provider.dart
