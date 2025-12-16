// AI-generated START - 专家列表状态管理Provider
import 'package:flutter/material.dart';
import 'package:omi/backend/http/mp_api/mp_expert.dart';
import 'package:omi/backend/schema/mp/mp_expert.dart';
import 'package:omi/pages/mp_expert_feedback/home/widgets/mp_expert_card.dart';

/// 专家列表状态管理Provider
/// 管理专家列表数据、搜索、分类筛选和添加状态
class MPExpertProvider with ChangeNotifier {
  // AI-generated START - 专家列表
  List<MPExpertCardData> _experts = [];
  // AI-generated END - _experts

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

  // AI-generated START - 选中的分类索引
  int _selectedCategoryIndex = 0;
  // AI-generated END - _selectedCategoryIndex

  // AI-generated START - 已添加的专家ID集合
  final Set<String> _addedExpertIds = {};
  // AI-generated END - _addedExpertIds

  // AI-generated START - 分页游标
  String _cursor = '';
  // AI-generated END - _cursor

  // AI-generated START - 获取专家列表
  List<MPExpertCardData> get experts => _experts;
  // AI-generated END - experts

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

  // AI-generated START - 获取选中的分类索引
  int get selectedCategoryIndex => _selectedCategoryIndex;
  // AI-generated END - selectedCategoryIndex

  // AI-generated START - 获取已添加的专家ID集合
  Set<String> get addedExpertIds => _addedExpertIds;
  // AI-generated END - addedExpertIds

  // AI-generated START - 检查专家是否已添加
  bool isExpertAdded(String expertId) {
    return _addedExpertIds.contains(expertId);
  }
  // AI-generated END - isExpertAdded

  // AI-generated START - 获取过滤后的专家列表
  List<MPExpertCardData> get filteredExperts {
    var filtered = _experts;

    // 搜索过滤
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((expert) =>
              expert.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              expert.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // 分类过滤（这里可以根据实际需求实现）
    // if (_selectedCategoryIndex > 0) {
    //   filtered = filtered.where((expert) => expert.category == ...).toList();
    // }

    return filtered;
  }
  // AI-generated END - filteredExperts

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

  // AI-generated START - 设置选中的分类索引
  void setSelectedCategoryIndex(int index) {
    _selectedCategoryIndex = index;
    notifyListeners();
  }
  // AI-generated END - setSelectedCategoryIndex

  // AI-generated START - 加载专家列表
  Future<void> loadExperts() async {
    setLoading(true);
    setError(null);
    _hasMore = true; // 重置 hasMore 状态
    _cursor = ''; // 重置游标
    try {
      final request = MPGetExpertListRequest(
        pageSize: 20, // 每页加载20个专家
        cursor: _cursor,
      );
      final response = await getExpertList(request);

      if (response != null && response.experts.isNotEmpty) {
        // 将 API 返回的专家数据转换为 MPExpertCardData
        _experts = response.experts.map((expertMerge) {
          final expert = expertMerge.expert;
          return MPExpertCardData(
            id: expert.id,
            name: expert.name,
            description: expert.about ?? '',
            avatarUrl: (expert.avatar != null && expert.avatar!.isNotEmpty) ? expert.avatar : null,
            isHot: false, // 可以根据需要设置热门标识
            isAdded: expertMerge.isAdd,
          );
        }).toList();

        // 同步已添加状态
        _addedExpertIds.clear();
        for (var expert in _experts) {
          if (expert.isAdded) {
            _addedExpertIds.add(expert.id);
          }
        }

        // 根据 API 响应设置是否有更多数据
        _hasMore = response.hasMore;
      } else {
        _experts = [];
        _hasMore = false;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading experts: $e');
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
  // AI-generated END - loadExperts

  // AI-generated START - 加载更多专家
  Future<void> loadMoreExperts() async {
    if (_isFetching || !_hasMore) return;

    setFetching(true);

    try {
      // 使用当前游标加载下一页数据
      final request = MPGetExpertListRequest(
        pageSize: 20, // 每页加载20个专家
        cursor: _cursor,
      );
      final response = await getExpertList(request);

      if (response != null && response.experts.isNotEmpty) {
        // 将 API 返回的专家数据转换为 MPExpertCardData
        final moreExperts = response.experts.map((expertMerge) {
          final expert = expertMerge.expert;
          return MPExpertCardData(
            id: expert.id,
            name: expert.name,
            description: expert.about ?? '',
            avatarUrl: (expert.avatar != null && expert.avatar!.isNotEmpty) ? expert.avatar : null,
            isHot: false, // 可以根据需要设置热门标识
            isAdded: expertMerge.isAdd,
          );
        }).toList();

        _experts.addAll(moreExperts);

        // 同步已添加状态
        for (var expert in moreExperts) {
          if (expert.isAdded) {
            _addedExpertIds.add(expert.id);
          }
        }

        // 根据 API 响应设置是否有更多数据
        _hasMore = response.hasMore;
        // 更新游标（这里假设 API 返回的最后一个专家的 ID 作为下一个游标）
        // 如果 API 有返回 cursor，应该使用返回的 cursor
        if (moreExperts.isNotEmpty) {
          _cursor = moreExperts.last.id;
        }
      } else {
        _hasMore = false;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading more experts: $e');
    } finally {
      setFetching(false);
    }
  }
  // AI-generated END - loadMoreExperts

  // AI-generated START - 添加专家
  Future<void> addExpert(String expertId) async {
    if (_addedExpertIds.contains(expertId)) return;

    try {
      // TODO: 调用API添加专家
      await Future.delayed(const Duration(milliseconds: 300)); // 模拟网络请求

      _addedExpertIds.add(expertId);
      // 更新专家数据
      final index = _experts.indexWhere((e) => e.id == expertId);
      if (index != -1) {
        _experts[index] = MPExpertCardData(
          id: _experts[index].id,
          name: _experts[index].name,
          description: _experts[index].description,
          avatarUrl: _experts[index].avatarUrl,
          isHot: _experts[index].isHot,
          isAdded: true,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding expert: $e');
      rethrow;
    }
  }
  // AI-generated END - addExpert

  // AI-generated START - 移除专家
  Future<void> removeExpert(String expertId) async {
    if (!_addedExpertIds.contains(expertId)) return;

    try {
      // TODO: 调用API移除专家
      await Future.delayed(const Duration(milliseconds: 300)); // 模拟网络请求

      _addedExpertIds.remove(expertId);
      // 更新专家数据
      final index = _experts.indexWhere((e) => e.id == expertId);
      if (index != -1) {
        _experts[index] = MPExpertCardData(
          id: _experts[index].id,
          name: _experts[index].name,
          description: _experts[index].description,
          avatarUrl: _experts[index].avatarUrl,
          isHot: _experts[index].isHot,
          isAdded: false,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing expert: $e');
      rethrow;
    }
  }
  // AI-generated END - removeExpert

  // AI-generated START - 清空专家列表
  void clearExperts() {
    _experts.clear();
    _addedExpertIds.clear();
    notifyListeners();
  }
  // AI-generated END - clearExperts
}
// AI-generated END - mp_expert_provider.dart
