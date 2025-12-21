import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../backend/http/mp_api/mp_memory.dart';
import '../../../backend/schema/mp/mp_memory.dart';
import '../../../backend/schema/mp/mp_data_model.dart';
import '../../mp_custom_utils/mp_timestamp_utils.dart';

class MPMemoryItem {
  MPMemoryItem({
    required this.dateText,
    required this.tagText,
    required this.tagColor,
    required this.headerText,
    required this.timeText,
    this.secondsText,
    this.description,
  });

  final String dateText;
  final String tagText;
  final Color tagColor;
  final String headerText;
  final String timeText;
  final String? secondsText;
  final String? description;
}

/// MPMemoryStruct 扩展方法
/// 提供将 MPMemoryStruct 转换为 MPMemoryItem 的方法
extension MPMemoryStructExtension on MPMemoryStruct {
  /// 将 MPMemoryStruct 转换为 MPMemoryItem
  /// @returns 转换后的 MPMemoryItem 对象
  MPMemoryItem toMPMemoryItem() {
    final dateTime = MPTimestampUtils.timestampToDateTime(createAt);
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


//  @JsonValue(1)
//   summary,

//   @JsonValue(2)
//   onlyRecord,

//   @JsonValue(3)
//   insight,

//   @JsonValue(4)
//   aiExpert,

    // 根据 type 确定 tagColor
    Color tagColor;
    switch (type) {
      case MPMemoryType.summary:
        tagColor = const Color(0xFFF4B95A); // 任务提醒颜色
        break;
      case MPMemoryType.onlyRecord:
        tagColor = const Color(0xFF8D8D8D); // 灰色
        break;
      case MPMemoryType.insight:
        tagColor = const Color(0xFF3E78F7); // Daily Insight 颜色
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

  void onCardViewDetail(MPMemoryItem item) {
    debugPrint('View detail for ${item.headerText}');
  }

  // List<MPMemoryItem> _generateMockItems({int start = 0}) {
  //   final base = [
  //     MPMemoryItem(
  //       dateText: '07-22',
  //       tagText: '任务提醒',
  //       tagColor: const Color(0xFFF4B95A),
  //       headerText: 'X头小鱼塘养殖🐟产品设计',
  //       timeText: '2023-07-22 14:42:10',
  //       secondsText: '11s',
  //       description: '产品经过了多次测试，确定了方向；系统自动生成产品文档并输出设计稿。',
  //     ),
  //     MPMemoryItem(
  //       dateText: '07-22',
  //       tagText: '待确认需求',
  //       tagColor: const Color(0xFFF57F17),
  //       headerText: '音视频会议里的 ToDo 话术要素补全',
  //       timeText: '2023-07-22 14:32:10',
  //       secondsText: '07s',
  //       description: '系统提取了会议中的遗漏信息，需确认关键要素并补全记录。',
  //     ),
  //     MPMemoryItem(
  //       dateText: '10-30',
  //       tagText: 'Daily Insight',
  //       tagColor: const Color(0xFF3E78F7),
  //       headerText: 'Daily Insight',
  //       timeText: '2023-09-30 09:30:20',
  //       secondsText: '10s',
  //       description: '今日重点回顾已生成，包含录音转写、摘要及关键行动项。',
  //     ),
  //     MPMemoryItem(
  //       dateText: '今天',
  //       tagText: '待确认需求',
  //       tagColor: const Color(0xFFEA4335),
  //       headerText: '工作会议纪要',
  //       timeText: '2023-10-30 08:30:00',
  //       description: '系统整理了会议要点和待办，涉及交付节奏、验收标准及风险。',
  //     ),
  //     MPMemoryItem(
  //       dateText: '某用户',
  //       tagText: '待确认需求',
  //       tagColor: const Color(0xFF27AE60),
  //       headerText: '收藏夹的需求澄清',
  //       timeText: '2023-10-29 20:00:00',
  //       secondsText: '10s',
  //       description: '需确定收藏夹的数据结构、同步逻辑以及跨端一致性方案。',
  //     ),
  //   ];

  //   return List.generate(5, (index) {
  //     final template = base[index % base.length];
  //     return MPMemoryItem(
  //       dateText: template.dateText,
  //       tagText: template.tagText,
  //       tagColor: template.tagColor,
  //       headerText: '${template.headerText} #${start + index + 1}',
  //       timeText: template.timeText,
  //       secondsText: template.secondsText,
  //       description: template.description,
  //     );
  //   });
  // }
}
