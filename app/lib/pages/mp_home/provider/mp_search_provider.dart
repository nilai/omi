import 'package:flutter/material.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/http/mp_api/mp_memory.dart';

/// 搜索页面 Provider
/// 管理搜索页面的状态，包括最近搜索和热门搜索
class MPSearchProvider extends ChangeNotifier {
  /// 最近搜索历史列表（最多10条）
  List<String> _recentSearches = [];

  /// 热门搜索关键词列表
  List<String> _popularSearches = [];

  /// 是否正在加载热门搜索
  bool _loadingPopularSearches = false;

  /// 搜索历史存储的 key
  static const String _searchHistoryKey = 'mp_search_history';

  /// 获取最近搜索历史
  List<String> get recentSearches => _recentSearches;

  /// 获取热门搜索关键词
  List<String> get popularSearches => _popularSearches;

  /// 是否正在加载热门搜索
  bool get loadingPopularSearches => _loadingPopularSearches;

  MPSearchProvider() {
    _loadRecentSearches();
  }

  /// 从本地存储加载最近搜索历史
  /// @returns 无返回值
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = SharedPreferencesUtil();
      final history = prefs.getStringList(_searchHistoryKey) ?? [];
      _recentSearches = history.take(10).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('加载搜索历史失败: $e');
    }
  }

  /// 添加搜索关键词到历史记录
  /// @param keyword 搜索关键词
  /// @returns 无返回值
  Future<void> addSearchHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;

    try {
      final prefs = SharedPreferencesUtil();
      final history = prefs.getStringList(_searchHistoryKey) ?? [];

      // 移除重复的关键词
      history.remove(keyword.trim());

      // 将新关键词添加到最前面
      history.insert(0, keyword.trim());

      // 只保留最近10条
      final limitedHistory = history.take(10).toList();

      // 保存到本地
      await prefs.saveStringList(_searchHistoryKey, limitedHistory);

      // 更新本地状态
      _recentSearches = limitedHistory;
      notifyListeners();
    } catch (e) {
      debugPrint('保存搜索历史失败: $e');
    }
  }

  /// 清除搜索历史
  /// @returns 无返回值
  Future<void> clearSearchHistory() async {
    try {
      final prefs = SharedPreferencesUtil();
      await prefs.remove(_searchHistoryKey);
      _recentSearches = [];
      notifyListeners();
    } catch (e) {
      debugPrint('清除搜索历史失败: $e');
    }
  }

  /// 设置热门搜索关键词
  /// @param keywords 热门搜索关键词列表
  /// @returns 无返回值
  void setPopularSearches(List<String> keywords) {
    _popularSearches = keywords;
    _loadingPopularSearches = false;
    notifyListeners();
  }

  /// 设置加载状态
  /// @param loading 是否正在加载
  /// @returns 无返回值
  void setLoadingPopularSearches(bool loading) {
    _loadingPopularSearches = loading;
    notifyListeners();
  }

  /// 加载热门搜索关键词（从API获取）
  /// @returns 无返回值
  Future<void> loadPopularSearches() async {
    _loadingPopularSearches = true;
    notifyListeners();

    try {
      final response = await getPopularSearchKeywords();
      if (response != null && response.baseResp.code == 0) {
        _popularSearches = response.keywords;
      } else {
        // 如果API调用失败，使用默认数据
        _popularSearches = ['会议', '任务', '总结', '项目', '讨论'];
      }
      _loadingPopularSearches = false;
      notifyListeners();
    } catch (e) {
      debugPrint('加载热门搜索失败: $e');
      // 如果API调用失败，使用默认数据
      _popularSearches = ['会议', '任务', '总结', '项目', '讨论'];
      _loadingPopularSearches = false;
      notifyListeners();
    }
  }
}

