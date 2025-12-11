// AI-generated START - 记忆详情状态管理Provider
import 'package:flutter/material.dart';
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
      // TODO: 从API或本地存储加载记忆详情和对话摘要
      // final memoryDetail = await memoryService.fetchMemoryDetail(memoryId);
      // final summaries = await memoryService.fetchConversationSummaries(memoryId);
      // _memoryItem = memoryDetail;
      // _conversationSummaries = summaries;
      await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络请求

      // AI-generated START - 默认测试数据
      _conversationSummaries = [
        const ConversationSummary(
          id: '1',
          title: '耳机与AI硬件市场需求与产品设计',
          summary: '讨论了AI硬件市场的需求分析和产品设计方案,确定了以用户体验为核心的差异化策略',
          date: '2025-07-22',
          durationSeconds: 2529, // 42分9秒
          participantCount: 4,
        ),
        const ConversationSummary(
          id: '2',
          title: '创业项目融资计划讨论',
          summary: '分享了市场调研数据和商业模式优化建议,探讨了融资策略和投资人沟通要点',
          date: '2025-07-20',
          durationSeconds: 2118, // 35分18秒
          participantCount: 3,
        ),
        const ConversationSummary(
          id: '3',
          title: '产品迭代方向交流',
          summary: '讨论了产品功能优先级,用户反馈分析,以及下一版本的核心改进方向',
          date: '2025-07-18',
          durationSeconds: 1722, // 28分42秒
          participantCount: 2,
        ),
        const ConversationSummary(
          id: '4',
          title: '团队协作与项目管理',
          summary: '交流了团队协作中遇到的问题,优化了项目管理流程,明确了各成员职责',
          date: '2025-07-15',
          durationSeconds: 1915, // 31分55秒
          participantCount: 5,
        ),
        const ConversationSummary(
          id: '5',
          title: '市场推广策略研讨',
          summary: '分析了目标用户群体,制定了市场推广计划,讨论了品牌定位和传播策略',
          date: '2025-07-12',
          durationSeconds: 1530, // 25分30秒
          participantCount: 3,
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
  // AI-generated END - loadMemoryDetail
}
// AI-generated END - memory_detail_provider.dart
