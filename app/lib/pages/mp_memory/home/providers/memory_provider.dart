// AI-generated START - 记忆中心状态管理Provider
import 'package:flutter/material.dart';
import 'package:omi/backend/http/mp_api/mp_speaker.dart';
import 'package:omi/backend/schema/mp/mp_speaker.dart';

/// 人物记忆数据模型
class CharacterMemoryItem {
  // AI-generated START - 构造函数
  const CharacterMemoryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.conversationCount,
    this.avatarUrl,
    this.avatarBackgroundColor,
    this.updatedAt,
  });
  // AI-generated END - 构造函数

  /// 记忆ID
  final String id;

  /// 人物姓名
  final String name;

  /// 记忆描述
  final String description;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime? updatedAt;

  /// 对话次数
  final int conversationCount;

  /// 头像URL
  final String? avatarUrl;

  /// 头像背景颜色
  final Color? avatarBackgroundColor;
}

/// 记忆中心状态管理Provider
/// 管理用户人物记忆数据
class MemoryProvider with ChangeNotifier {
  // AI-generated START - 人物记忆列表
  List<CharacterMemoryItem> _memories = [];
  // AI-generated END - _memories

  // AI-generated START - 是否正在加载
  bool _isLoading = false;
  // AI-generated END - _isLoading

  // AI-generated START - 是否正在获取更多数据
  bool _isFetching = false;
  // AI-generated END - _isFetching

  // AI-generated START - 是否还有更多数据
  bool _hasMore = true;
  // AI-generated END - _hasMore

  // AI-generated START - 错误信息
  String? _error;
  // AI-generated END - _error

  // AI-generated START - 搜索关键词
  String _searchQuery = '';
  // AI-generated END - _searchQuery

  // AI-generated START - 分页游标
  String _cursor = '';
  // AI-generated END - _cursor

  // AI-generated START - 获取人物记忆列表
  List<CharacterMemoryItem> get memories => _memories;
  // AI-generated END - memories

  // AI-generated START - 获取是否正在加载
  bool get isLoading => _isLoading;
  // AI-generated END - isLoading

  // AI-generated START - 获取是否正在获取更多数据
  bool get isFetching => _isFetching;
  // AI-generated END - isFetching

  // AI-generated START - 获取是否还有更多数据
  bool get hasMore => _hasMore;
  // AI-generated END - hasMore

  // AI-generated START - 获取错误信息
  String? get error => _error;
  // AI-generated END - error

  // AI-generated START - 获取搜索关键词
  String get searchQuery => _searchQuery;
  // AI-generated END - searchQuery

  // AI-generated START - 获取过滤后的人物记忆列表
  List<CharacterMemoryItem> get filteredMemories {
    if (_searchQuery.isEmpty) {
      return _memories;
    }
    return _memories.where((memory) {
      return memory.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          memory.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }
  // AI-generated END - filteredMemories

  // AI-generated START - 设置加载状态
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  // AI-generated END - setLoading

  // AI-generated START - 设置获取状态
  void setFetching(bool fetching) {
    _isFetching = fetching;
    notifyListeners();
  }
  // AI-generated END - setFetching

  // AI-generated START - 设置错误信息
  void setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
  // AI-generated END - setError

  // AI-generated START - 设置搜索关键词
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  // AI-generated END - setSearchQuery

  // AI-generated START - 加载人物记忆列表
  Future<void> loadMemories() async {
    setLoading(true);
    setError(null);
    _hasMore = true; // 重置 hasMore 状态
    _cursor = ''; // 重置 cursor
    try {
      // TODO: 从API或本地存储加载记忆数据
      // final memories = await memoryService.fetchMemories();
      // _memories = memories;
      await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络请求
      // AI-generated START - 默认测试数据
      final now = DateTime.now();
      _memories = [
        CharacterMemoryItem(
          id: '1',
          name: '叶成功',
          description: '讨论了创业项目的融资计划,分享了市场调研数据和商业模式优化建议',
          createdAt: now.subtract(const Duration(days: 2)),
          conversationCount: 5,
          avatarBackgroundColor: Colors.amber,
        ),
        CharacterMemoryItem(
          id: '2',
          name: '叶天命',
          description: '聊了关于职业发展的规划,探讨了技术转型和个人成长路径',
          createdAt: now.subtract(const Duration(days: 5)),
          conversationCount: 4,
          avatarBackgroundColor: Colors.grey.shade300,
        ),
        CharacterMemoryItem(
          id: '3',
          name: '叶无敌',
          description: '交流了健身计划和生活方式改变,分享了运动心得和饮食建议',
          createdAt: now.subtract(const Duration(days: 7)),
          conversationCount: 6,
          avatarBackgroundColor: Colors.grey.shade400,
        ),
        CharacterMemoryItem(
          id: '4',
          name: '叶疯狂',
          description: '讨论了旅行计划和冒险经历,分享了各地美食和文化体验',
          createdAt: now.subtract(const Duration(days: 7)),
          conversationCount: 5,
          avatarBackgroundColor: Colors.grey.shade300,
        ),
        CharacterMemoryItem(
          id: '5',
          name: '叶智慧',
          description: '探讨了读书心得和知识管理方法,交流了学习技巧和思维模式',
          createdAt: now.subtract(const Duration(days: 14)),
          conversationCount: 3,
          avatarBackgroundColor: Colors.grey.shade300,
        ),
        CharacterMemoryItem(
          id: '6',
          name: '叶勇敢',
          description: '聊了关于挑战自我的经历,分享了克服困难的方法和心态调整',
          createdAt: now.subtract(const Duration(days: 14)),
          conversationCount: 3,
          avatarBackgroundColor: Colors.grey.shade400,
        ),
      ];
      // AI-generated END - 默认测试数据
      // 模拟：如果数据少于某个数量，则认为没有更多数据
      _hasMore = _memories.length >= 6; // 这里可以根据实际API响应调整
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
  // AI-generated END - loadMemories

  // AI-generated START - 加载更多人物记忆
  Future<void> loadMoreMemories() async {
    if (_isFetching || !_hasMore) return;

    setFetching(true);

    try {
      // 调用 getSpeakerListWithDetail 接口
      final response = await getSpeakerListWithDetail(
        MPGetSpeakerListWithDetailRequest(
          pageSize: 20,
          cursor: _cursor,
        ),
      );

      if (response != null && response.baseResp.code == 0) {
        // 将 API 响应转换为 CharacterMemoryItem
        final newMemories = response.speakers.map((speakerWithDetail) {
          final speaker = speakerWithDetail.speaker;
          return CharacterMemoryItem(
            id: speaker.id,
            name: speaker.name,
            description: speakerWithDetail.summary,
            createdAt: DateTime.now(), // API 可能没有返回创建时间，使用当前时间
            conversationCount: 0, // API 可能没有返回对话次数，使用默认值
            avatarUrl: speaker.avatar.isNotEmpty ? speaker.avatar : null,
            avatarBackgroundColor: _getColorFromString(speaker.id),
          );
        }).toList();

        _memories.addAll(newMemories);
        _hasMore = response.hasMore;

        // 更新 cursor（如果 API 返回了新的 cursor，需要从响应中获取）
        // 这里假设使用最后一个 speaker 的 id 作为 cursor
        if (newMemories.isNotEmpty) {
          _cursor = newMemories.last.id;
        }

        notifyListeners();
      } else {
        debugPrint('Error loading more memories: ${response?.baseResp.message ?? "Unknown error"}');
        setError(response?.baseResp.message ?? '加载失败');
      }
    } catch (e) {
      debugPrint('Error loading more memories: $e');
      setError('加载失败: $e');
    } finally {
      setFetching(false);
    }
  }
  // AI-generated END - loadMoreMemories

  // AI-generated START - 根据字符串生成颜色
  /// 根据字符串生成颜色，用于头像背景
  Color _getColorFromString(String str) {
    final colors = [
      Colors.amber,
      Colors.grey.shade300,
      Colors.grey.shade400,
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.purple.shade100,
    ];
    final index = str.hashCode % colors.length;
    return colors[index.abs()];
  }
  // AI-generated END - _getColorFromString

  // AI-generated START - 添加人物记忆
  void addMemory(CharacterMemoryItem memory) {
    _memories.insert(0, memory);
    notifyListeners();
  }
  // AI-generated END - addMemory

  // AI-generated START - 更新人物记忆
  void updateMemory(String id, CharacterMemoryItem updatedMemory) {
    final index = _memories.indexWhere((m) => m.id == id);
    if (index != -1) {
      _memories[index] = updatedMemory;
      notifyListeners();
    }
  }
  // AI-generated END - updateMemory

  // AI-generated START - 删除记忆
  void deleteMemory(String id) {
    _memories.removeWhere((m) => m.id == id);
    notifyListeners();
  }
  // AI-generated END - deleteMemory

  // AI-generated START - 清空记忆列表
  void clearMemories() {
    _memories.clear();
    notifyListeners();
  }
  // AI-generated END - clearMemories
}
// AI-generated END - memory_provider.dart
