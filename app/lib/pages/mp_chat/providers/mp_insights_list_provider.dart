import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../backend/http/mp_api/mp_memory.dart';
import '../../../backend/schema/mp/mp_data_model.dart';
import '../../../backend/schema/mp/mp_memory.dart';
import '../../mp_custom_utils/mp_timestamp_utils.dart';
import '../mp_insight_model.dart';

/// Insights 列表 Provider
class MPInsightsListProvider extends ChangeNotifier {
  List<MPInsightModel> _insights = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _pageSize = 20;
  String _cursor = '';

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
    _cursor = '';
    final req = MPGetInsightListRequest(pageSize: _pageSize, cursor: _cursor);
    final response = await getInsightList(req);
    if (response == null) return;
    _insights = response.memorys.map((e) => e.toMPInsightModel()).toList();
    _hasMore = response.hasMore;
    _cursor = response.memorys.last.id;
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
    final req = MPGetInsightListRequest(pageSize: _pageSize, cursor: _cursor);
    final response = await getInsightList(req);
    if (response == null) return;
    _insights.addAll(response.memorys.map((e) => e.toMPInsightModel()).toList());
    _hasMore = response.hasMore;
    _cursor = response.memorys.last.id;
    _isLoadingMore = false;
    notifyListeners();
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
