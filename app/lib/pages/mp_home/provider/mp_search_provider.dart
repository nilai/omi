import 'package:flutter/material.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/http/mp_api/mp_memory.dart';
import 'package:omi/backend/schema/mp/mp_memory.dart';
import 'package:omi/pages/mp_home/provider/mp_page_provider.dart';
import 'package:omi/pages/mp_home/widgets/mp_delete_memory_dialog.dart';
import 'package:omi/utils/alerts/mp_share_memory_dialog.dart';
import 'package:omi/pages/mp_custom_utils/mp_toast_utils.dart';

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

  /// 搜索结果列表
  List<MPMemoryItem> _searchResults = [];

  /// 是否正在搜索
  bool _isSearching = false;

  /// 当前搜索关键词
  String _currentKeyword = '';

  /// 是否显示搜索结果
  bool _showResults = false;

  /// 获取最近搜索历史
  List<String> get recentSearches => _recentSearches;

  /// 获取热门搜索关键词
  List<String> get popularSearches => _popularSearches;

  /// 是否正在加载热门搜索
  bool get loadingPopularSearches => _loadingPopularSearches;

  /// 获取搜索结果列表
  List<MPMemoryItem> get searchResults => _searchResults;

  /// 是否正在搜索
  bool get isSearching => _isSearching;

  /// 当前搜索关键词
  String get currentKeyword => _currentKeyword;

  /// 是否显示搜索结果
  bool get showResults => _showResults;

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

  /// 执行搜索
  /// @param keyword 搜索关键词
  /// @returns 无返回值
  Future<void> search(String keyword) async {
    if (keyword.trim().isEmpty) {
      _showResults = false;
      _currentKeyword = '';
      notifyListeners();
      return;
    }

    _currentKeyword = keyword.trim();
    _isSearching = true;
    _showResults = true;
    notifyListeners();

    try {
      final req = MPSearchMemoryRequest(searchContent: _currentKeyword);
      final response = await searchMemory(req);

      if (response != null && response.baseResp.code == 0) {
        _searchResults = response.memorys.map((memory) => memory.toMPMemoryItem()).toList();
      } else {
        _searchResults = [];
      }
    } catch (e) {
      debugPrint('搜索失败: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// 清除搜索结果，返回输入状态
  /// @returns 无返回值
  void clearSearch() {
    _showResults = false;
    _currentKeyword = '';
    _searchResults = [];
    notifyListeners();
  }

  /// 分享卡片
  /// @param context 上下文
  /// @param item 记忆项
  void onCardShare(BuildContext context, MPMemoryItem item) {
    MPShareMemoryDialog.show(context: context, memoryId: item.memory.id);
  }

  /// 删除卡片
  /// @param context 上下文
  /// @param item 记忆项
  void onCardDelete(BuildContext context, MPMemoryItem item) {
    debugPrint('Delete tapped for ${item.headerText}');
    // 显示确认对话框
    MPDeleteMemoryDialog.show(
      context: context,
      onCancel: () {
        debugPrint('Delete cancelled');
      },
      onConfirm: () async {
        // 执行删除操作
        final req = MPDeleteMemoryRequest(memoryId: item.memory.id);
        final response = await deleteMemory(req);
        if (response != null) {
          if (response.baseResp.code == 0) {
            // 从搜索结果中移除该项
            _searchResults.removeWhere((element) => element.memory.id == item.memory.id);
            notifyListeners();
          } else {
            MPToastUtils.showMessage(response.baseResp.message);
          }
        }
      },
    );
  }
}
