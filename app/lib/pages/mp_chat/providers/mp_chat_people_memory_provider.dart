import 'package:flutter/material.dart';
import 'package:omi/backend/http/mp_api/mp_speaker.dart';
import 'package:omi/backend/schema/mp/mp_speaker.dart';

/// 人物记忆数据模型
class MPChatPeopleMemoryItem {
  const MPChatPeopleMemoryItem({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
    required this.conversationCount,
    this.avatarUrl,
    this.updatedAt,
  });

  /// 记忆ID
  final String id;

  /// 人物姓名
  final String name;

  /// 记忆描述
  final String? description;

  /// 创建时间
  final int? createdAt;

  /// 更新时间
  final int? updatedAt;

  /// 对话次数
  final int conversationCount;

  /// 头像URL
  final String? avatarUrl;
}

/// Chat People Memory 页面状态管理Provider
/// 管理聊天页面中人物记忆数据
class MPChatPeopleMemoryProvider with ChangeNotifier {
  /// 人物记忆列表
  List<MPChatPeopleMemoryItem> _memories = [];

  /// 是否正在加载
  bool _isLoading = false;

  /// 是否正在获取更多数据
  bool _isFetching = false;

  /// 是否还有更多数据
  bool _hasMore = true;

  /// 错误信息
  String? _error;

  /// 分页游标
  String _cursor = '';

  /// 获取人物记忆列表
  List<MPChatPeopleMemoryItem> get memories => _memories;

  /// 获取是否正在加载
  bool get isLoading => _isLoading;

  /// 获取是否正在获取更多数据
  bool get isFetching => _isFetching;

  /// 获取是否还有更多数据
  bool get hasMore => _hasMore;

  /// 获取错误信息
  String? get error => _error;

  /// 设置加载状态
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置获取状态
  void setFetching(bool fetching) {
    _isFetching = fetching;
    notifyListeners();
  }

  /// 设置错误信息
  void setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  /// 加载人物记忆列表
  Future<void> loadMemories() async {
    setLoading(true);
    setError(null);
    _hasMore = true; // 重置 hasMore 状态
    _cursor = ''; // 重置 cursor
    try {
      // 调用 getSpeakerListWithDetail 接口
      final response = await getSpeakerListWithDetail(
        MPGetSpeakerListWithDetailRequest(
          pageSize: 20,
          cursor: _cursor,
        ),
      );

      if (response != null && response.baseResp.code == 0) {
        // 将 API 响应转换为 MPChatPeopleMemoryItem
        _memories = response.speakers.map((speakerWithDetail) {
          final speaker = speakerWithDetail.speaker;
          return MPChatPeopleMemoryItem(
            id: speaker.id,
            name: speaker.name,
            description: speakerWithDetail.summary,
            createdAt: speakerWithDetail.last_memory_at,
            conversationCount: speakerWithDetail.memory_total,
            avatarUrl: speaker.avatar.isNotEmpty ? speaker.avatar : null,
          );
        }).toList();

        _hasMore = response.hasMore;

        // 更新 cursor（如果 API 返回了新的 cursor，需要从响应中获取）
        // 这里假设使用最后一个 speaker 的 id 作为 cursor
        if (_memories.isNotEmpty) {
          _cursor = _memories.last.id;
        }

        notifyListeners();
      } else {
        debugPrint('Error loading memories: ${response?.baseResp.message ?? "Unknown error"}');
        setError(response?.baseResp.message ?? '加载失败');
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  /// 加载更多人物记忆
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
        // 将 API 响应转换为 MPChatPeopleMemoryItem
        final newMemories = response.speakers.map((speakerWithDetail) {
          final speaker = speakerWithDetail.speaker;
          return MPChatPeopleMemoryItem(
            id: speaker.id,
            name: speaker.name,
            description: speakerWithDetail.summary,
            createdAt: speakerWithDetail.last_memory_at,
            conversationCount: speakerWithDetail.memory_total,
            avatarUrl: speaker.avatar.isNotEmpty ? speaker.avatar : null,
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

  /// 清空记忆列表
  void clearMemories() {
    _memories.clear();
    notifyListeners();
  }
}

