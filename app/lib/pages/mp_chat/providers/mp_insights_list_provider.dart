import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../backend/schema/mp/mp_data_model.dart';
import '../../mp_custom_utils/mp_timestamp_utils.dart';
import '../mp_insight_model.dart';

/// Insights 列表 Provider
class MPInsightsListProvider extends ChangeNotifier {
  List<MPInsightModel> _insights = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _pageSize = 10;

  List<MPInsightModel> get insights => _insights;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  MPInsightsListProvider() {
    // 初始化时加载数据
    loadInsights();
  }

  /// 加载 Insights 数据
  Future<void> loadInsights() async {
    if (_isLoading) return;

    _isLoading = true;
    _hasMore = true;
    notifyListeners();

    // 模拟网络请求延迟
    await Future.delayed(const Duration(milliseconds: 500));

    _insights = _generateMockInsights(start: 0, count: _pageSize);

    _isLoading = false;
    notifyListeners();
  }

  /// 下拉刷新
  Future<void> refresh() async {
    await loadInsights();
  }

  /// 上拉加载更多
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    // 模拟网络请求延迟
    await Future.delayed(const Duration(milliseconds: 500));

    final moreInsights = _generateMockInsights(
      start: _insights.length,
      count: _pageSize,
    );

    if (moreInsights.isEmpty) {
      _hasMore = false;
    } else {
      _insights.addAll(moreInsights);

      // 模拟数据加载完毕（当数据超过50条时）
      if (_insights.length >= 50) {
        _hasMore = false;
      }
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// 生成假数据
  List<MPInsightModel> _generateMockInsights({required int start, required int count}) {
    final List<MPInsightModel> insights = [];

    // 如果已经超过50条，返回空列表
    if (start >= 50) {
      return insights;
    }

    final now = DateTime.now();
    int insightIndex = start;

    for (int i = 0; i < count && insightIndex < 50; i++) {
      final date = now.subtract(Duration(days: insightIndex));

      MPInsightType type;
      String title;
      String timeText;
      String period;

      // 根据索引决定类型
      if (insightIndex % 7 == 0 && insightIndex > 0) {
        // 每周洞察
        type = MPInsightType.weekly;
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        title = '${_formatMonthDay(weekStart)} - ${_formatMonthDay(weekEnd)} Weekly Insight';
        timeText = '${weekStart.year}年${weekStart.month}月第${_getWeekOfMonth(weekStart)}周';
        period = timeText;
      } else if (insightIndex % 30 == 0 && insightIndex > 0) {
        // 每月洞察
        type = MPInsightType.monthly;
        title = '${_formatMonth(date)} Monthly Insight';
        timeText = '${date.year}年${date.month}月';
        period = timeText;
      } else {
        // 每日洞察
        type = MPInsightType.daily;
        title = '${_formatMonthDay(date)} Daily Insight';
        timeText =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} 00:00:00';
        period = '';
      }

      // 创建模拟的 MPMemoryStruct
      final memory = MPMemoryStruct(
        id: 'insight_memory_$insightIndex',
        createAt: date.millisecondsSinceEpoch,
        title: title,
        type: MPMemoryType.insight,
        label: period.isNotEmpty ? period : 'Insight',
        content: _generateDescription(type),
        duration: 0,
        insightContent: MPInsightMemoryStruct(content: _generateDescription(type)),
      );

      // 使用扩展方法将 MPMemoryStruct 转换为 MPInsightModel
      insights.add(memory.toMPInsightModel());

      insightIndex++;
    }

    return insights;
  }

  String _formatMonthDay(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatMonth(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  int _getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final firstMonday = firstDayOfMonth.add(Duration(days: (8 - firstDayOfMonth.weekday) % 7));
    if (date.isBefore(firstMonday)) {
      return 1;
    }
    final weekNumber = ((date.difference(firstMonday).inDays) / 7).floor() + 2;
    return weekNumber;
  }

  String _generateDescription(MPInsightType type) {
    switch (type) {
      case MPInsightType.daily:
        return 'Today, 5 meetings and 3 important conversations were recorded, mainly focusing on product strategy planning and technical solution discussions. The team reached a consensus on resource allocation and design challenges, and determined the next action plan.';
      case MPInsightType.weekly:
        return 'This week, the team made significant progress in product development and market expansion. Completed the development of core functional modules, launched the market promotion plan, and established multiple strategic partnerships.';
      case MPInsightType.monthly:
        return 'October is a season of harvest. The team achieved breakthrough progress in multiple dimensions such as product R&D, market expansion, and team building. Completed several important milestones, laying a solid foundation for the next phase of development.';
    }
  }
}

/// MPMemoryStruct 扩展方法
/// 提供将 MPMemoryStruct 转换为 MPInsightModel 的方法
extension MPMemoryStructToInsightExtension on MPMemoryStruct {
  /// 将 MPMemoryStruct 转换为 MPInsightModel
  /// @returns 转换后的 MPInsightModel 对象
  MPInsightModel toMPInsightModel() {
    // 将时间戳转换为 DateTime
    final dateTime = MPTimestampUtils.timestampMsToDateTime(createAt);

    // 生成 timeText (yyyy-MM-dd HH:mm:ss)
    final timeText = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);

    // 根据 label 或 title 推断 Insight 类型，默认为 daily
    MPInsightType insightType = MPInsightType.daily;
    String period = '';

    // 尝试从 label 推断类型
    final labelLower = label.toLowerCase();
    if (labelLower.contains('weekly') || labelLower.contains('周')) {
      insightType = MPInsightType.weekly;
      period = label;
    } else if (labelLower.contains('monthly') || labelLower.contains('月')) {
      insightType = MPInsightType.monthly;
      period = label;
    } else {
      // 默认为 daily
      insightType = MPInsightType.daily;
      period = '';
    }

    // 获取描述内容，优先使用 insightContent，否则使用 content
    final description = insightContent?.content ?? content;

    return MPInsightModel(
      id: id,
      type: insightType,
      title: title,
      timeText: timeText,
      period: period,
      description: description,
      timestamp: dateTime,
    );
  }
}
