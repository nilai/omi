import 'package:memo_pin/http/schema/mp_insight.dart';

import 'mp_data_model.dart';


/// 获取首页聚合数据请求（后端 `GetHomeOverviewRequest`，当前无字段）。
class MPGetHomeOverviewRequest {
  MPGetHomeOverviewRequest();

  /// 从 JSON 解析。
  factory MPGetHomeOverviewRequest.fromJson(Map<String, dynamic> json) {
    return MPGetHomeOverviewRequest();
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{};
}

/// 获取首页聚合数据响应（后端 `GetHomeOverviewResponse`）。
class MPGetHomeOverviewResponse {
  MPGetHomeOverviewResponse({
    required this.focusItems,
    required this.recentMemories,
    required this.insightOverview,
    required this.baseResp,
  });

  final List<MPTodoStruct> focusItems;
  final List<MPMemoryStruct> recentMemories;
  final MPHomeInsightOverviewStruct insightOverview;
  final MPBaseResp baseResp;

  /// 从 JSON 解析。
  factory MPGetHomeOverviewResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? focusRaw = json['focus_items'] as List<dynamic>?;
    final List<MPTodoStruct> focus = focusRaw
            ?.map((dynamic e) => MPTodoStruct.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <MPTodoStruct>[];

    final List<dynamic>? recentRaw = json['recent_memories'] as List<dynamic>?;
    final List<MPMemoryStruct> recent = recentRaw
            ?.map((dynamic e) => MPMemoryStruct.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <MPMemoryStruct>[];

    final Map<String, dynamic>? overviewMap =
        json['insight_overview'] as Map<String, dynamic>?;

    return MPGetHomeOverviewResponse(
      focusItems: focus,
      recentMemories: recent,
      insightOverview: overviewMap != null
          ? MPHomeInsightOverviewStruct.fromJson(overviewMap)
          : MPHomeInsightOverviewStruct(
              title: '',
              subTitle: '',
              newInsightCount: 0,
              content: '',
            ),
      baseResp: MPBaseResp.fromJson(
        json['base_resp'] as Map<String, dynamic>,
      ),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'focus_items': focusItems.map((MPTodoStruct e) => e.toJson()).toList(),
        'recent_memories':
            recentMemories.map((MPMemoryStruct e) => e.toJson()).toList(),
        'insight_overview': insightOverview.toJson(),
        'base_resp': baseResp.toJson(),
      };
}
