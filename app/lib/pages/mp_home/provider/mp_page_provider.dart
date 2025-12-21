import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../backend/http/mp_api/mp_memory.dart';
import '../../../backend/schema/mp/mp_memory.dart';
import '../../../backend/schema/mp/mp_data_model.dart';
import '../../mp_custom_utils/mp_timestamp_utils.dart';
import '../../mp_memory/conversation_detail/conversation_detail_page.dart';

class MPMemoryItem {
  MPMemoryItem({
    required this.dateText,
    required this.tagText,
    required this.tagColor,
    required this.headerText,
    required this.timeText,
    this.secondsText,
    this.description,
    required this.memory,
  });

  final String dateText;
  final String tagText;
  final Color tagColor;
  final String headerText;
  final String timeText;
  final String? secondsText;
  final String? description;
  final MPMemoryStruct memory;
}

/// MPMemoryStruct 扩展方法
/// 提供将 MPMemoryStruct 转换为 MPMemoryItem 的方法
extension MPMemoryStructExtension on MPMemoryStruct {
  /// 将 MPMemoryStruct 转换为 MPMemoryItem
  /// @returns 转换后的 MPMemoryItem 对象
  MPMemoryItem toMPMemoryItem() {
    final dateTime = MPTimestampUtils.timestampMsToDateTime(createAt);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = today.difference(date).inDays;

    // 生成 dateText
    String dateText;
    if (difference == 0) {
      dateText = '今天';
    } else if (difference == 1) {
      dateText = '昨天';
    } else {
      // 格式化为 MM-dd
      dateText = DateFormat('MM-dd').format(dateTime);
    }

    // 生成 timeText (yyyy-MM-dd HH:mm:ss)
    final timeText = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);

    // 生成 secondsText (从 duration 转换)
    final secondsText = duration > 0 ? '${duration}s' : null;

    // 根据 type 确定 tagColor
    Color tagColor;
    switch (type) {
      case MPMemoryType.summary:
        tagColor = const Color(0xFFF4B95A); // 任务提醒颜色
        break;
      case MPMemoryType.insight:
        tagColor = const Color(0xFF8D8D8D); // Daily Insight 颜色
        break;
      case MPMemoryType.onlyRecord:
        tagColor = const Color(0xFF3E78F7); //
        break;
      case MPMemoryType.aiExpert:
        tagColor = const Color(0xFF27AE60); // 绿色
        break;
    }

    return MPMemoryItem(
      dateText: dateText,
      tagText: label,
      tagColor: tagColor,
      headerText: title,
      timeText: timeText,
      secondsText: secondsText,
      description: content.isNotEmpty ? content : null,
      memory: this,
    );
  }
}

class MPHomePageProvider extends ChangeNotifier {
  String selectedDate = MPTimestampUtils.getCurrentDate();
  // int uploadedCount = 1;
  // int totalCount = 1;
  double uploadPercent = 10;
  int recordCount = 20;
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  final List<MPMemoryItem> items = [];
  String _cursor = '';

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    _cursor = '';
    final req = MPGetMemoryListRequest(pageSize: 20, cursor: _cursor, date: selectedDate);
    final response = await getMemoryList(req);
    if (response != null) {
      items.clear();
      items.addAll(response.memorys.map((memory) => memory.toMPMemoryItem()));
      hasMore = response.hasMore;
      _cursor = response.memorys.last.id;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasMore) return;
    loadingMore = true;
    notifyListeners();
    final req = MPGetMemoryListRequest(pageSize: 20, cursor: _cursor, date: selectedDate);
    final response = await getMemoryList(req);
    if (response != null) {
      items.addAll(response.memorys.map((memory) => memory.toMPMemoryItem()));
      hasMore = response.hasMore;
      _cursor = response.memorys.last.id;
    }
    loadingMore = false;
    notifyListeners();
  }

  void updateRecordCount(int value) {
    if (value < 0) return;
    recordCount = value;
    notifyListeners();
  }

  /// 将日期字符串（yyyy-MM-dd 或 yyyy-M-d）转换为 MMM d 格式
  ///
  /// [dateString] 日期字符串，例如：2025-12-8 或 2025-12-08
  /// @returns 格式化后的日期字符串，例如：Dec 8
  String formatDateToMonthDay(String dateString) {
    return MPTimestampUtils.dateStringToMonthDay(dateString);
  }

  void onLeftWidgetTap() {
    debugPrint('Left widget tapped');
  }

  void onSearchTap() {
    debugPrint('Search tapped');
  }

  void onCardMore(MPMemoryItem item) {
    debugPrint('More tapped for ${item.headerText}');
  }

  /// 分享卡片
  /// @param context 上下文
  /// @param item 记忆项
  void onCardShare(BuildContext context, MPMemoryItem item) {
    debugPrint('Share tapped for ${item.headerText}');
    // TODO: 实现分享功能
  }

  /// 删除卡片
  /// @param context 上下文
  /// @param item 记忆项
  void onCardDelete(BuildContext context, MPMemoryItem item) {
    debugPrint('Delete tapped for ${item.headerText}');
    // TODO: 实现删除功能
    // 可以显示确认对话框
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这条记录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // TODO: 执行删除操作
                // 删除后刷新列表
                refresh();
              },
              child: const Text(
                '删除',
                style: TextStyle(color: Color(0xFFFF0000)),
              ),
            ),
          ],
        );
      },
    );
  }

  void onCardViewDetail(BuildContext context, MPMemoryItem item) {
    debugPrint('View detail for ${item.headerText}');
    // ConversationDetailPage
    Navigator.push(context, MaterialPageRoute(builder: (context) => ConversationDetailPage(memory: item.memory)));
  }
}
