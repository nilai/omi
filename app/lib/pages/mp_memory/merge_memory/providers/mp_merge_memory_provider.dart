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

    final req = MPGetSummaryListRequest(
      pageSize: 1000, // 每次获取100条
      cursor: '',
    );
    final response = await getSummaryList(req);
    if (response != null) {
      allMemories.addAll(response.summarys);
    }

    // 过滤掉当前记忆
    final filteredMemories = allMemories.where((memory) => memory.id != currentMemoryId).toList();
    items = filteredMemories.map((memory) => memory.toMPMemoryItem()).toList();
    if (items.isEmpty) {
      loading = false;
      // 创建测试数据（仅开发调试用）
      void createTestData() {
        items = List.generate(5, (index) {
          final id = 'test_memory_$index';
          return MPMemoryItem(
            dateText: '2024-06-0${index + 1}',
            tagText: '标签$index',
            tagColor: const Color(0xFF306CFF),
            headerText: '记忆标题$index',
            timeText: '12:0${index}0',
            secondsText: '${10 + index * 5}秒',
            description: '这是第$index条测试记忆摘要内容，仅作演示。',
            memory: MPMemoryStruct(
              id: id,
              createAt: DateTime.now().millisecondsSinceEpoch - index * 86400000,
              // 假设其它字段为必需，但不重要时可填测试数据或空
              content: '测试摘要$index',
              title: '记忆标题$index',
              type: MPMemoryType.summary,
              label: '标签$index',
              duration: 10 + index * 5,
              // 可根据定义添加更多字段
            ),
            createAt: DateTime.now().millisecondsSinceEpoch - index * 86400000,
          );
        });
        loading = false;
        notifyListeners();
      }

      createTestData();
      loading = false;
      notifyListeners();

      return;
    }
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
