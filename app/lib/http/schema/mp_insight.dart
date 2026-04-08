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

/// Insight 详情请求（后端 `GetInsightDetailRequest`）。
class MPGetInsightDetailRequest {
  MPGetInsightDetailRequest({
    required this.insightId,
  });

  final String insightId;

  /// 从 JSON 解析。
  factory MPGetInsightDetailRequest.fromJson(Map<String, dynamic> json) {
    return MPGetInsightDetailRequest(
      insightId: json['insight_id'] as String? ?? '',
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'insight_id': insightId,
      };
}

/// Insight 详情异构容器（后端 `InsightDetailStruct`）。
class MPInsightDetailStruct {
  MPInsightDetailStruct({
    required this.basicInfo,
    required this.insightType,
    this.patternDetail,
    this.monthlyDetail,
    this.dailyDetail,
    this.weeklyDetail,
  });

  final MPInsightCardStruct basicInfo;
  final int insightType;

  /// `insight_type == PATTERN` 时返回。
  final Map<String, dynamic>? patternDetail;

  /// `insight_type == MONTHLY` 时返回。
  final Map<String, dynamic>? monthlyDetail;

  /// `insight_type == DAILY` 时返回。
  final Map<String, dynamic>? dailyDetail;

  /// `insight_type == WEEKLY` 时返回。
  final Map<String, dynamic>? weeklyDetail;

  /// 从 JSON 解析。
  factory MPInsightDetailStruct.fromJson(Map<String, dynamic> json) {
    return MPInsightDetailStruct(
      basicInfo: MPInsightCardStruct.fromJson(
        json['basic_info'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      insightType: (json['insight_type'] as num?)?.toInt() ?? MPInsightCycleType.daily,
      patternDetail: json['pattern_detail'] as Map<String, dynamic>?,
      monthlyDetail: json['monthly_detail'] as Map<String, dynamic>?,
      dailyDetail: json['daily_detail'] as Map<String, dynamic>?,
      weeklyDetail: json['weekly_detail'] as Map<String, dynamic>?,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'basic_info': basicInfo.toJson(),
        'insight_type': insightType,
        if (patternDetail != null) 'pattern_detail': patternDetail,
        if (monthlyDetail != null) 'monthly_detail': monthlyDetail,
        if (dailyDetail != null) 'daily_detail': dailyDetail,
        if (weeklyDetail != null) 'weekly_detail': weeklyDetail,
      };
}

/// Insight 详情响应（后端 `GetInsightDetailResponse`）。
class MPGetInsightDetailResponse {
  MPGetInsightDetailResponse({
    required this.insightDetail,
    required this.baseResp,
  });

  final MPInsightDetailStruct insightDetail;
  final MPBaseResp baseResp;

  /// 从 JSON 解析。
  factory MPGetInsightDetailResponse.fromJson(Map<String, dynamic> json) {
    return MPGetInsightDetailResponse(
      insightDetail: MPInsightDetailStruct.fromJson(
        json['insight_detail'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      baseResp: MPBaseResp.fromJson(
        json['base_resp'] as Map<String, dynamic>,
      ),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'insight_detail': insightDetail.toJson(),
        'base_resp': baseResp.toJson(),
      };
}
