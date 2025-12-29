import 'package:flutter/material.dart';

import '../../../../backend/http/mp_api/mp_memory.dart';
import '../../../../backend/schema/mp/mp_data_model.dart';
import '../../../../backend/schema/mp/mp_memory.dart';
import '../../../../pages/mp_home/provider/mp_page_provider.dart';

/// 合并记忆Provider
/// 管理合并记忆页面的状态和数据
class MPMergeMemoryProvider extends ChangeNotifier {
  /// 当前记忆ID（要合并到的目标记忆）
  final String currentMemoryId;

  /// 记忆列表
  List<MPMemoryItem> items = [];

  /// 选中的记忆ID集合
  Set<String> selectedMemoryIds = {};

  /// 是否正在加载
  bool loading = false;

  /// 构造函数
  /// @param currentMemoryId 当前记忆ID
  MPMergeMemoryProvider({
    required this.currentMemoryId,
  });

  /// 获取选中的记忆数量
  /// @returns 选中的记忆数量
  int get selectedCount => selectedMemoryIds.length;

  /// 是否有选中的记忆
  /// @returns 是否有选中的记忆
  bool get hasSelected => selectedMemoryIds.isNotEmpty;

  /// 刷新数据
  /// 获取所有记忆记录（不限制日期），不需要加载更多
  /// @returns 无返回值
  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    selectedMemoryIds.clear();

    // 获取所有记忆，使用大的 pageSize 一次性获取
    // 如果数据量很大，可以改为循环请求直到 hasMore 为 false
    final List<MPMemoryStruct> allMemories = [];
    String cursor = '';
    bool hasMoreData = true;

    while (hasMoreData) {
      final req = MPGetMemoryListRequest(
        pageSize: 100, // 每次获取100条
        cursor: cursor,
        date: '', // 传空字符串获取所有日期的记忆
      );
      final response = await getMemoryList(req);
      if (response != null) {
        allMemories.addAll(response.memorys);
        hasMoreData = response.hasMore;
        if (response.memorys.isNotEmpty) {
          cursor = response.memorys.last.id;
        } else {
          hasMoreData = false;
        }
      } else {
        hasMoreData = false;
      }
    }

    // 过滤掉当前记忆
    final filteredMemories = allMemories
        .where((memory) => memory.id != currentMemoryId)
        .toList();
    items = filteredMemories.map((memory) => memory.toMPMemoryItem()).toList();
    loading = false;
    notifyListeners();
  }

  /// 切换记忆的选中状态
  /// @param memoryId 记忆ID
  /// @returns 无返回值
  void toggleSelection(String memoryId) {
    if (selectedMemoryIds.contains(memoryId)) {
      selectedMemoryIds.remove(memoryId);
    } else {
      selectedMemoryIds.add(memoryId);
    }
    notifyListeners();
  }

  /// 检查记忆是否被选中
  /// @param memoryId 记忆ID
  /// @returns 是否被选中
  bool isSelected(String memoryId) {
    return selectedMemoryIds.contains(memoryId);
  }

  /// 获取选中的记忆列表
  /// @returns 选中的记忆列表
  List<MPMemoryItem> getSelectedMemories() {
    return items.where((item) => selectedMemoryIds.contains(item.memory.id)).toList();
  }
}

