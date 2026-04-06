import 'mp_data_model.dart';

/// 与后端 [InsightType] / `cycle_type` 取值一致。
abstract final class MPInsightCycleType {
  MPInsightCycleType._();

  static const int daily = 1;
  static const int weekly = 2;
  static const int monthly = 3;
  static const int pattern = 4;
}

/// Insight 信息流卡片（后端 `InsightCardStruct`）。
class MPInsightCardStruct {
  MPInsightCardStruct({
    required this.id,
    required this.cycleType,
    required this.title,
    required this.subTitle,
    required this.createAt,
    required this.content,
  });

  final String id;

  /// 周期类型：见 [MPInsightCycleType]。
  final int cycleType;

  final String title;
  final String subTitle;
  final int createAt;

  /// Markdown 正文。
  final String content;

  /// 从 JSON 解析。
  factory MPInsightCardStruct.fromJson(Map<String, dynamic> json) {
    return MPInsightCardStruct(
      id: json['id'] as String? ?? '',
      cycleType: (json['cycle_type'] as num?)?.toInt() ?? MPInsightCycleType.daily,
      title: json['title'] as String? ?? '',
      subTitle: json['sub_title'] as String? ?? '',
      createAt: (json['create_at'] as num?)?.toInt() ?? 0,
      content: json['content'] as String? ?? '',
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'cycle_type': cycleType,
        'title': title,
        'sub_title': subTitle,
        'create_at': createAt,
        'content': content,
      };
}

/// Insight 信息流列表请求（后端 `GetInsightFeedListRequest`）。
class MPGetInsightFeedListRequest {
  MPGetInsightFeedListRequest({
    required this.pageSize,
    this.cursor,
  });

  final int pageSize;
  final String? cursor;

  /// 从 JSON 解析。
  factory MPGetInsightFeedListRequest.fromJson(Map<String, dynamic> json) {
    return MPGetInsightFeedListRequest(
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      cursor: json['cursor'] as String?,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'page_size': pageSize,
        if (cursor != null && cursor!.isNotEmpty) 'cursor': cursor,
      };
}

/// Insight 信息流列表响应（后端 `GetInsightFeedListResponse`）。
class MPGetInsightFeedListResponse {
  MPGetInsightFeedListResponse({
    required this.cards,
    required this.hasMore,
    required this.baseResp,
  });

  final List<MPInsightCardStruct> cards;
  final bool hasMore;
  final MPBaseResp baseResp;

  /// 从 JSON 解析。
  factory MPGetInsightFeedListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? raw = json['cards'] as List<dynamic>?;
    final List<MPInsightCardStruct> cards = raw
            ?.map(
              (dynamic e) =>
                  MPInsightCardStruct.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        <MPInsightCardStruct>[];

    return MPGetInsightFeedListResponse(
      cards: cards,
      hasMore: json['has_more'] as bool? ?? false,
      baseResp: MPBaseResp.fromJson(
        json['base_resp'] as Map<String, dynamic>,
      ),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'cards': cards.map((MPInsightCardStruct e) => e.toJson()).toList(),
        'has_more': hasMore,
        'base_resp': baseResp.toJson(),
      };
}
