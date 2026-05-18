import 'mp_data_model.dart';

Map<String, dynamic> _mpAsMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map<String, dynamic>(
      (dynamic key, dynamic value) => MapEntry<String, dynamic>(
        key.toString(),
        value,
      ),
    );
  }
  return <String, dynamic>{};
}

List<dynamic> _mpAsList(dynamic value) {
  return value is List ? value : <dynamic>[];
}

String _mpAsString(dynamic value, {String defaultValue = ''}) {
  if (value == null) {
    return defaultValue;
  }
  if (value is String) {
    return value;
  }
  return value.toString();
}

String? _mpAsNullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  return _mpAsString(value);
}

int _mpAsInt(dynamic value, {int defaultValue = 0}) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? defaultValue;
  }
  return defaultValue;
}

bool _mpAsBool(dynamic value, {bool defaultValue = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final String normalized = value.toLowerCase().trim();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  return defaultValue;
}

/// 从 Insight 详情 JSON 元素解析 [MPTodoStruct]：支持纯字符串、`text`/`content`/`title`、`dead_line`/`deadline`、
/// `sub_title`（写入 [MPTodoStruct.reason]），以及完整 Todo JSON。
String _mpInsightTodoLineTitle(Map<String, dynamic> m) {
  final String fromText = _mpAsString(m['text']).trim();
  final String fromContent = _mpAsString(m['content']).trim();
  final String fromTitle = _mpAsString(m['title']).trim();
  if (fromText.isNotEmpty) {
    return fromText;
  }
  if (fromContent.isNotEmpty) {
    return fromContent;
  }
  return fromTitle;
}

MPTodoStruct? _mpInsightTodoFromDynamic(dynamic raw) {
  if (raw == null) {
    return null;
  }
  if (raw is String) {
    final String t = raw.trim();
    return t.isEmpty ? null : MPTodoStruct(title: t);
  }
  final Map<String, dynamic> m = _mpAsMap(raw);
  MPTodoStruct parsed = MPTodoStruct();
  if (m.isNotEmpty) {
    try {
      parsed = MPTodoStruct.fromJson(m);
    } catch (_) {
      parsed = MPTodoStruct();
    }
  }
  final String mergedLineTitle = _mpInsightTodoLineTitle(m);
  final String resolvedTitle =
      (parsed.title ?? '').trim().isNotEmpty ? parsed.title!.trim() : mergedLineTitle;
  if (resolvedTitle.isEmpty) {
    return null;
  }
  final int? mergedDeadline =
      parsed.deadline ?? mpNullableIntFromJson(m['dead_line']) ?? mpNullableIntFromJson(m['deadline']);
  final String? mergedReason = parsed.reason ?? _mpAsNullableString(m['sub_title']);
  return MPTodoStruct(
    id: parsed.id,
    title: resolvedTitle,
    owner: parsed.owner,
    priority: parsed.priority,
    deadline: mergedDeadline,
    status: parsed.status,
    reason: mergedReason,
    preCreateStatus: parsed.preCreateStatus,
    memoryId: parsed.memoryId,
    slot: parsed.slot,
    description: parsed.description,
    insightId: parsed.insightId,
  );
}

List<MPTodoStruct> _mpAsInsightTodoList(dynamic value) {
  return _mpAsList(value).map(_mpInsightTodoFromDynamic).whereType<MPTodoStruct>().toList();
}

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
      id: _mpAsString(json['id']),
      cycleType: _mpAsInt(
        json['cycle_type'],
        defaultValue: MPInsightCycleType.daily,
      ),
      title: _mpAsString(json['title']),
      subTitle: _mpAsString(json['sub_title']),
      createAt: _mpAsInt(json['create_at']),
      content: _mpAsString(json['content']),
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
      pageSize: _mpAsInt(json['page_size'], defaultValue: 20),
      cursor: _mpAsNullableString(json['cursor']),
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
    final List<MPInsightCardStruct> cards = _mpAsList(json['cards'])
        .map(
          (dynamic e) => MPInsightCardStruct.fromJson(_mpAsMap(e)),
        )
        .toList();

    return MPGetInsightFeedListResponse(
      cards: cards,
      hasMore: _mpAsBool(json['has_more']),
      baseResp: MPBaseResp.fromJson(
        _mpAsMap(json['base_resp']),
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
      insightId: _mpAsString(json['insight_id']),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'insight_id': insightId,
      };
}

/// 获取 Insight 建议问题请求（后端 `GetInsightSuggestionRequest`）。
class MPGetInsightSuggestionRequest {
  MPGetInsightSuggestionRequest({
    required this.insightId,
  });

  final String insightId;

  /// 从 JSON 解析。
  factory MPGetInsightSuggestionRequest.fromJson(Map<String, dynamic> json) {
    return MPGetInsightSuggestionRequest(
      insightId: _mpAsString(json['insight_id']),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'insight_id': insightId,
      };
}

/// 获取 Insight 建议问题响应（后端 `GetInsightSuggestionResponse`）。
class MPGetInsightSuggestionResponse {
  MPGetInsightSuggestionResponse({
    required this.insightType,
    required this.suggestion,
    required this.baseResp,
  });

  /// 取值见 [MPInsightCycleType]（DAILY / MONTHLY / PATTERN ...）。
  final int insightType;
  final List<String> suggestion;
  final MPBaseResp baseResp;

  /// 从 JSON 解析。
  factory MPGetInsightSuggestionResponse.fromJson(Map<String, dynamic> json) {
    return MPGetInsightSuggestionResponse(
      insightType: _mpAsInt(
        json['insight_type'],
        defaultValue: MPInsightCycleType.daily,
      ),
      suggestion: _mpAsList(json['suggestion'])
          .map((dynamic e) => _mpAsString(e))
          .where((String e) => e.isNotEmpty)
          .toList(),
      baseResp: MPBaseResp.fromJson(
        _mpAsMap(json['base_resp']),
      ),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'insight_type': insightType,
        'suggestion': suggestion,
        'base_resp': baseResp.toJson(),
      };
}

/// Insight 简易详情请求（后端 `GetInsightSimpleDetailRequest`）。
class MPGetInsightSimpleDetailRequest {
  MPGetInsightSimpleDetailRequest({
    required this.todoId,
  });

  final String todoId;

  /// 从 JSON 解析。
  factory MPGetInsightSimpleDetailRequest.fromJson(Map<String, dynamic> json) {
    return MPGetInsightSimpleDetailRequest(
      todoId: _mpAsString(json['todo_id']),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'todo_id': todoId,
      };
}

/// Insight 简易详情响应（后端 `GetInsightSimpleDetailResponse`）。
class MPGetInsightSimpleDetailResponse {
  MPGetInsightSimpleDetailResponse({
    required this.title,
    required this.label,
    required this.recordCreateAt,
    required this.type,
    required this.baseResp,
  });

  final String title;

  final String label;

  /// 与 [MPMemorySimpleInfoStruct.recordCreateAt] 一致：服务端可为秒或毫秒时间戳。
  final int recordCreateAt;

  /// 与后端 Insight / Memory 类型取值一致（`i32`）。
  final int type;

  final MPBaseResp baseResp;

  /// 从 JSON 解析。
  factory MPGetInsightSimpleDetailResponse.fromJson(Map<String, dynamic> json) {
    return MPGetInsightSimpleDetailResponse(
      title: _mpAsString(json['title']),
      label: _mpAsString(json['label']),
      recordCreateAt: _mpAsInt(json['record_create_at']),
      type: _mpAsInt(json['type']),
      baseResp: MPBaseResp.fromJson(
        _mpAsMap(json['base_resp']),
      ),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'label': label,
        'record_create_at': recordCreateAt,
        'type': type,
        'base_resp': baseResp.toJson(),
      };
}

/// 删除 Insight 请求（后端 `DeleteInsightRequest`）。
class MPDeleteInsightRequest {
  MPDeleteInsightRequest({
    required this.insightId,
  });

  final String insightId;

  /// 从 JSON 解析。
  factory MPDeleteInsightRequest.fromJson(Map<String, dynamic> json) {
    return MPDeleteInsightRequest(
      insightId: _mpAsString(json['insight_id']),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'insight_id': insightId,
      };
}

/// 删除 Insight 响应（后端 `DeleteInsightResponse`）。
class MPDeleteInsightResponse {
  MPDeleteInsightResponse({
    required this.baseResp,
  });

  final MPBaseResp baseResp;

  /// 从 JSON 解析。
  factory MPDeleteInsightResponse.fromJson(Map<String, dynamic> json) {
    return MPDeleteInsightResponse(
      baseResp: MPBaseResp.fromJson(
        _mpAsMap(json['base_resp']),
      ),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'base_resp': baseResp.toJson(),
      };
}

/// 分享 Insight 请求（后端 `ShareInsightRequest`）。
class MPShareInsightRequest {
  MPShareInsightRequest({
    required this.insightId,
  });

  final String insightId;

  /// 从 JSON 解析。
  factory MPShareInsightRequest.fromJson(Map<String, dynamic> json) {
    return MPShareInsightRequest(
      insightId: _mpAsString(json['insight_id']),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'insight_id': insightId,
      };
}

/// 分享 Insight 响应（后端 `ShareInsightResponse`）。
class MPShareInsightResponse {
  MPShareInsightResponse({
    required this.id,
    required this.shareCode,
    required this.shareUrl,
    required this.shortUrl,
    required this.expiresAt,
    required this.createAt,
    required this.baseResp,
  });

  final String id;
  final String shareCode;
  final String shareUrl;
  final String shortUrl;
  final int expiresAt;
  final int createAt;
  final MPBaseResp baseResp;

  /// 从 JSON 解析。
  factory MPShareInsightResponse.fromJson(Map<String, dynamic> json) {
    return MPShareInsightResponse(
      id: _mpAsString(json['id']),
      shareCode: _mpAsString(json['share_code']),
      shareUrl: _mpAsString(json['share_url']),
      shortUrl: _mpAsString(json['short_url']),
      expiresAt: _mpAsInt(json['expires_at']),
      createAt: _mpAsInt(json['create_at']),
      baseResp: MPBaseResp.fromJson(
        _mpAsMap(json['base_resp']),
      ),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'share_code': shareCode,
        'share_url': shareUrl,
        'short_url': shortUrl,
        'expires_at': expiresAt,
        'create_at': createAt,
        'base_resp': baseResp.toJson(),
      };
}

/// 首页聚合概览请求（后端 `GetHomeInsightOverviewRequest`）。
class MPGetHomeInsightOverviewRequest {
  MPGetHomeInsightOverviewRequest();

  /// 从 JSON 解析。
  factory MPGetHomeInsightOverviewRequest.fromJson(Map<String, dynamic> json) {
    return MPGetHomeInsightOverviewRequest();
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{};
}

/// 首页聚合概览结构（后端 `HomeInsightOverviewStruct`）。
class MPHomeInsightOverviewStruct {
  MPHomeInsightOverviewStruct({
    required this.title,
    required this.subTitle,
    required this.newInsightCount,
    required this.content,
  });

  final String title;
  final String subTitle;
  final int newInsightCount;
  final String content;

  /// 从 JSON 解析。
  factory MPHomeInsightOverviewStruct.fromJson(Map<String, dynamic> json) {
    return MPHomeInsightOverviewStruct(
      title: _mpAsString(json['title']),
      subTitle: _mpAsString(json['sub_title']),
      newInsightCount: _mpAsInt(json['new_insight_count']),
      content: _mpAsString(json['content']),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'sub_title': subTitle,
        'new_insight_count': newInsightCount,
        'content': content,
      };
}

/// 首页聚合概览响应（后端 `GetHomeInsightOverviewResponse`）。
class MPGetHomeInsightOverviewResponse {
  MPGetHomeInsightOverviewResponse({
    required this.insightOverview,
    required this.baseResp,
  });

  final MPHomeInsightOverviewStruct insightOverview;
  final MPBaseResp baseResp;

  /// 从 JSON 解析。
  factory MPGetHomeInsightOverviewResponse.fromJson(Map<String, dynamic> json) {
    return MPGetHomeInsightOverviewResponse(
      insightOverview: MPHomeInsightOverviewStruct.fromJson(
        _mpAsMap(json['insight_overview']),
      ),
      baseResp: MPBaseResp.fromJson(
        _mpAsMap(json['base_resp']),
      ),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'insight_overview': insightOverview.toJson(),
        'base_resp': baseResp.toJson(),
      };
}

/// Pattern Insight「Where This Appeared」列表项。
class MPPatternInsightAppearedItemStruct {
  MPPatternInsightAppearedItemStruct({
    required this.memoryId,
    required this.title,
    required this.subTitle,
    required this.createAt,
  });

  final String memoryId;
  final String title;
  final String subTitle;
  final int createAt;

  /// 从 JSON 解析。
  factory MPPatternInsightAppearedItemStruct.fromJson(Map<String, dynamic> json) {
    return MPPatternInsightAppearedItemStruct(
      memoryId: json['memory_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subTitle: json['sub_title'] as String? ?? '',
      createAt: (json['create_at'] as num?)?.toInt() ?? 0,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'memory_id': memoryId,
        'title': title,
        'sub_title': subTitle,
        'create_at': createAt,
      };
}

/// Pattern Insight「Pattern Detected」区块。
class MPPatternInsightDetectedStruct {
  MPPatternInsightDetectedStruct({
    required this.sectionTitle,
    required this.contentMd,
  });

  final String sectionTitle;
  final String contentMd;

  /// 从 JSON 解析。
  factory MPPatternInsightDetectedStruct.fromJson(Map<String, dynamic> json) {
    return MPPatternInsightDetectedStruct(
      sectionTitle: json['section_title'] as String? ?? '',
      contentMd: json['content_md'] as String? ?? '',
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'section_title': sectionTitle,
        'content_md': contentMd,
      };
}

/// Pattern 类型专属详情。
class MPPatternInsightDetailStruct {
  MPPatternInsightDetailStruct({
    required this.bannerTitle,
    required this.detected,
    required this.appearedItems,
    required this.whyThisMatters,
    required this.nextStep,
  });

  final String bannerTitle;
  final MPPatternInsightDetectedStruct detected;
  final List<MPPatternInsightAppearedItemStruct> appearedItems;
  final String whyThisMatters;
  final List<MPTodoStruct> nextStep;

  /// 从 JSON 解析。
  factory MPPatternInsightDetailStruct.fromJson(Map<String, dynamic> json) {
    final List<MPPatternInsightAppearedItemStruct> appearedItems =
        _mpAsList(json['appeared_items'])
            .map(
              (dynamic e) => MPPatternInsightAppearedItemStruct.fromJson(
                _mpAsMap(e),
              ),
            )
            .toList();

    final List<MPTodoStruct> nextStep = _mpAsInsightTodoList(json['next_step']);

    return MPPatternInsightDetailStruct(
      bannerTitle: _mpAsString(json['banner_title']),
      detected: MPPatternInsightDetectedStruct.fromJson(
        _mpAsMap(json['detected']),
      ),
      appearedItems: appearedItems,
      whyThisMatters: _mpAsString(json['why_this_matters']),
      nextStep: nextStep,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'banner_title': bannerTitle,
        'detected': detected.toJson(),
        'appeared_items': appearedItems
            .map((MPPatternInsightAppearedItemStruct e) => e.toJson())
            .toList(),
        'why_this_matters': whyThisMatters,
        'next_step': nextStep.map((MPTodoStruct e) => e.toJson()).toList(),
      };
}

/// Monthly Insight 分布条目。
class MPMonthlyInsightDistributionItemStruct {
  MPMonthlyInsightDistributionItemStruct({
    required this.name,
    required this.value,
    this.unit,
  });

  final String name;
  final int value;
  final String? unit;

  /// 从 JSON 解析。
  factory MPMonthlyInsightDistributionItemStruct.fromJson(Map<String, dynamic> json) {
    return MPMonthlyInsightDistributionItemStruct(
      name: json['name'] as String? ?? '',
      value: (json['value'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String?,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'value': value,
        if (unit != null) 'unit': unit,
      };
}

/// Monthly Insight 分布区块。
class MPMonthlyInsightDistributionSectionStruct {
  MPMonthlyInsightDistributionSectionStruct({
    required this.title,
    required this.items,
    this.summary,
  });

  final String title;
  final List<MPMonthlyInsightDistributionItemStruct> items;
  final String? summary;

  /// 从 JSON 解析。
  factory MPMonthlyInsightDistributionSectionStruct.fromJson(
    Map<String, dynamic> json,
  ) {
    final List<MPMonthlyInsightDistributionItemStruct> items = _mpAsList(json['items'])
        .map(
          (dynamic e) => MPMonthlyInsightDistributionItemStruct.fromJson(
            _mpAsMap(e),
          ),
        )
        .toList();

    return MPMonthlyInsightDistributionSectionStruct(
      title: _mpAsString(json['title']),
      items: items,
      summary: _mpAsNullableString(json['summary']),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'items': items
            .map((MPMonthlyInsightDistributionItemStruct e) => e.toJson())
            .toList(),
        if (summary != null) 'summary': summary,
      };
}

/// Monthly Insight「Long-running Open Threads」列表项。
class MPMonthlyInsightOpenThreadItemStruct {
  MPMonthlyInsightOpenThreadItemStruct({
    required this.content,
  });

  final String content;

  /// 从 JSON 解析。
  factory MPMonthlyInsightOpenThreadItemStruct.fromJson(Map<String, dynamic> json) {
    return MPMonthlyInsightOpenThreadItemStruct(
      content: json['content'] as String? ?? '',
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'content': content,
      };
}

/// Monthly Insight「Long-running Open Threads」区块。
class MPMonthlyInsightOpenThreadsSectionStruct {
  MPMonthlyInsightOpenThreadsSectionStruct({
    required this.title,
    required this.items,
    this.summary,
  });

  final String title;
  final List<MPMonthlyInsightOpenThreadItemStruct> items;
  final String? summary;

  /// 从 JSON 解析。
  factory MPMonthlyInsightOpenThreadsSectionStruct.fromJson(
    Map<String, dynamic> json,
  ) {
    final List<MPMonthlyInsightOpenThreadItemStruct> items = _mpAsList(json['items'])
        .map(
          (dynamic e) => MPMonthlyInsightOpenThreadItemStruct.fromJson(
            _mpAsMap(e),
          ),
        )
        .toList();

    return MPMonthlyInsightOpenThreadsSectionStruct(
      title: _mpAsString(json['title']),
      items: items,
      summary: _mpAsNullableString(json['summary']),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'items': items.map((MPMonthlyInsightOpenThreadItemStruct e) => e.toJson()).toList(),
        if (summary != null) 'summary': summary,
      };
}

/// Monthly Insight「Decisions That Cannot Slip Again」区块。
class MPMonthlyInsightDecisionsSectionStruct {
  MPMonthlyInsightDecisionsSectionStruct({
    required this.title,
    required this.intro,
    required this.items,
  });

  final String title;
  final String intro;
  final List<String> items;

  /// 从 JSON 解析。
  factory MPMonthlyInsightDecisionsSectionStruct.fromJson(Map<String, dynamic> json) {
    final List<String> items = _mpAsList(json['items'])
        .map((dynamic e) => _mpAsString(e))
        .where((String e) => e.isNotEmpty)
        .toList();

    return MPMonthlyInsightDecisionsSectionStruct(
      title: _mpAsString(json['title']),
      intro: _mpAsString(json['intro']),
      items: items,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'intro': intro,
        'items': items,
      };
}

/// Monthly Insight「Month Overview」区块。
class MPMonthlyInsightOverviewStruct {
  MPMonthlyInsightOverviewStruct({
    required this.title,
    required this.contentMd,
  });

  final String title;
  final String contentMd;

  /// 从 JSON 解析。
  factory MPMonthlyInsightOverviewStruct.fromJson(Map<String, dynamic> json) {
    return MPMonthlyInsightOverviewStruct(
      title: json['title'] as String? ?? '',
      contentMd: json['content_md'] as String? ?? '',
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'content_md': contentMd,
      };
}

/// Monthly 类型专属详情。
class MPMonthlyInsightDetailStruct {
  MPMonthlyInsightDetailStruct({
    required this.overview,
    required this.attentionDistribution,
    required this.keyPeople,
    required this.topicsResurfacing,
    required this.openThreads,
    required this.monthToMonthTrend,
    required this.decisions,
    required this.suggestedFocusNextMonth,
  });

  final MPMonthlyInsightOverviewStruct overview;
  final MPMonthlyInsightDistributionSectionStruct attentionDistribution;
  final MPMonthlyInsightDistributionSectionStruct keyPeople;
  final MPMonthlyInsightDistributionSectionStruct topicsResurfacing;
  final MPMonthlyInsightOpenThreadsSectionStruct openThreads;
  final List<String> monthToMonthTrend;
  final MPMonthlyInsightDecisionsSectionStruct decisions;
  final List<MPTodoStruct> suggestedFocusNextMonth;

  /// 从 JSON 解析。
  factory MPMonthlyInsightDetailStruct.fromJson(Map<String, dynamic> json) {
    final List<String> monthToMonthTrend = _mpAsList(json['month_to_month_trend'])
        .map((dynamic e) => _mpAsString(e))
        .where((String e) => e.isNotEmpty)
        .toList();

    final List<MPTodoStruct> suggestedFocusNextMonth = _mpAsInsightTodoList(json['suggested_focus_next_month']);

    return MPMonthlyInsightDetailStruct(
      overview: MPMonthlyInsightOverviewStruct.fromJson(
        _mpAsMap(json['overview']),
      ),
      attentionDistribution: MPMonthlyInsightDistributionSectionStruct.fromJson(
        _mpAsMap(json['attention_distribution']),
      ),
      keyPeople: MPMonthlyInsightDistributionSectionStruct.fromJson(
        _mpAsMap(json['key_people']),
      ),
      topicsResurfacing: MPMonthlyInsightDistributionSectionStruct.fromJson(
        _mpAsMap(json['topics_resurfacing']),
      ),
      openThreads: MPMonthlyInsightOpenThreadsSectionStruct.fromJson(
        _mpAsMap(json['open_threads']),
      ),
      monthToMonthTrend: monthToMonthTrend,
      decisions: MPMonthlyInsightDecisionsSectionStruct.fromJson(
        _mpAsMap(json['decisions']),
      ),
      suggestedFocusNextMonth: suggestedFocusNextMonth,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'overview': overview.toJson(),
        'attention_distribution': attentionDistribution.toJson(),
        'key_people': keyPeople.toJson(),
        'topics_resurfacing': topicsResurfacing.toJson(),
        'open_threads': openThreads.toJson(),
        'month_to_month_trend': monthToMonthTrend,
        'decisions': decisions.toJson(),
        'suggested_focus_next_month': suggestedFocusNextMonth.map((MPTodoStruct e) => e.toJson()).toList(),
      };
}

/// Daily Insight 通用文本条目。
class MPDailyInsightTextItemStruct {
  MPDailyInsightTextItemStruct({
    required this.content,
  });

  final String content;

  /// 从 JSON 解析。
  factory MPDailyInsightTextItemStruct.fromJson(Map<String, dynamic> json) {
    return MPDailyInsightTextItemStruct(
      content: json['content'] as String? ?? '',
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'content': content,
      };
}

/// Daily Insight「Today's narrative」区块。
class MPDailyInsightNarrativeSectionStruct {
  MPDailyInsightNarrativeSectionStruct({
    required this.content,
  });

  final String content;

  /// 从 JSON 解析。
  factory MPDailyInsightNarrativeSectionStruct.fromJson(Map<String, dynamic> json) {
    return MPDailyInsightNarrativeSectionStruct(
      content: json['content'] as String? ?? '',
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'content': content,
      };
}

/// Daily Insight 列表区块。
class MPDailyInsightListSectionStruct {
  MPDailyInsightListSectionStruct({
    required this.title,
    required this.items,
  });

  final String title;
  final List<MPDailyInsightTextItemStruct> items;

  /// 从 JSON 解析。
  factory MPDailyInsightListSectionStruct.fromJson(Map<String, dynamic> json) {
    final List<MPDailyInsightTextItemStruct> items = _mpAsList(json['items'])
        .map(
          (dynamic e) => MPDailyInsightTextItemStruct.fromJson(
            _mpAsMap(e),
          ),
        )
        .toList();

    return MPDailyInsightListSectionStruct(
      title: _mpAsString(json['title']),
      items: items,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'items': items.map((MPDailyInsightTextItemStruct e) => e.toJson()).toList(),
      };
}

/// Daily Insight「Patterns emerging」区块。
class MPDailyInsightPatternSectionStruct {
  MPDailyInsightPatternSectionStruct({
    required this.content,
  });

  final String content;

  /// 从 JSON 解析。
  factory MPDailyInsightPatternSectionStruct.fromJson(Map<String, dynamic> json) {
    return MPDailyInsightPatternSectionStruct(
      content: json['content'] as String? ?? '',
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'content': content,
      };
}

/// Daily 类型专属详情。
class MPDailyInsightDetailStruct {
  MPDailyInsightDetailStruct({
    required this.narrative,
    required this.decisionsMade,
    required this.openQuestions,
    required this.patternsEmerging,
    required this.ideasCaptured,
    required this.tomorrowFocus,
  });

  final MPDailyInsightNarrativeSectionStruct narrative;
  final MPDailyInsightListSectionStruct decisionsMade;
  final MPDailyInsightListSectionStruct openQuestions;
  final MPDailyInsightPatternSectionStruct patternsEmerging;
  final MPDailyInsightListSectionStruct ideasCaptured;
  final List<MPTodoStruct> tomorrowFocus;

  /// 从 JSON 解析。
  factory MPDailyInsightDetailStruct.fromJson(Map<String, dynamic> json) {
    final List<MPTodoStruct> tomorrowFocus = _mpAsInsightTodoList(json['tomorrow_focus']);

    return MPDailyInsightDetailStruct(
      narrative: MPDailyInsightNarrativeSectionStruct.fromJson(
        _mpAsMap(json['narrative']),
      ),
      decisionsMade: MPDailyInsightListSectionStruct.fromJson(
        _mpAsMap(json['decisions_made']),
      ),
      openQuestions: MPDailyInsightListSectionStruct.fromJson(
        _mpAsMap(json['open_questions']),
      ),
      patternsEmerging: MPDailyInsightPatternSectionStruct.fromJson(
        _mpAsMap(json['patterns_emerging']),
      ),
      ideasCaptured: MPDailyInsightListSectionStruct.fromJson(
        _mpAsMap(json['ideas_captured']),
      ),
      tomorrowFocus: tomorrowFocus,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'narrative': narrative.toJson(),
        'decisions_made': decisionsMade.toJson(),
        'open_questions': openQuestions.toJson(),
        'patterns_emerging': patternsEmerging.toJson(),
        'ideas_captured': ideasCaptured.toJson(),
        'tomorrow_focus': tomorrowFocus.map((MPTodoStruct e) => e.toJson()).toList(),
      };
}

/// Weekly Insight 顶部概览区块。
class MPWeeklyInsightHeaderSectionStruct {
  MPWeeklyInsightHeaderSectionStruct({
    required this.title,
    required this.subTitle,
    required this.summary,
  });

  final String title;
  final String subTitle;
  final String summary;

  /// 从 JSON 解析。
  factory MPWeeklyInsightHeaderSectionStruct.fromJson(Map<String, dynamic> json) {
    return MPWeeklyInsightHeaderSectionStruct(
      title: json['title'] as String? ?? '',
      subTitle: json['sub_title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'sub_title': subTitle,
        'summary': summary,
      };
}

/// Weekly Insight 指标卡片条目。
class MPWeeklyInsightMetricItemStruct {
  MPWeeklyInsightMetricItemStruct({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  /// 从 JSON 解析。
  factory MPWeeklyInsightMetricItemStruct.fromJson(Map<String, dynamic> json) {
    return MPWeeklyInsightMetricItemStruct(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toInt() ?? 0,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'label': label,
        'value': value,
      };
}

/// Weekly Insight「Week Summary」区块。
class MPWeeklyInsightSummarySectionStruct {
  MPWeeklyInsightSummarySectionStruct({
    required this.title,
    required this.focusAreas,
    required this.keyMetrics,
  });

  final String title;
  final String focusAreas;
  final List<MPWeeklyInsightMetricItemStruct> keyMetrics;

  /// 从 JSON 解析。
  factory MPWeeklyInsightSummarySectionStruct.fromJson(Map<String, dynamic> json) {
    final List<MPWeeklyInsightMetricItemStruct> keyMetrics = _mpAsList(json['key_metrics'])
        .map(
          (dynamic e) => MPWeeklyInsightMetricItemStruct.fromJson(
            _mpAsMap(e),
          ),
        )
        .toList();

    return MPWeeklyInsightSummarySectionStruct(
      title: _mpAsString(json['title']),
      focusAreas: _mpAsString(json['focus_areas']),
      keyMetrics: keyMetrics,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'focus_areas': focusAreas,
        'key_metrics': keyMetrics.map((MPWeeklyInsightMetricItemStruct e) => e.toJson()).toList(),
      };
}

/// Weekly Insight「Accomplishments」条目。
class MPWeeklyInsightAccomplishmentItemStruct {
  MPWeeklyInsightAccomplishmentItemStruct({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  /// 从 JSON 解析。
  factory MPWeeklyInsightAccomplishmentItemStruct.fromJson(Map<String, dynamic> json) {
    return MPWeeklyInsightAccomplishmentItemStruct(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'description': description,
      };
}

/// Weekly Insight「Challenges & Learnings」条目。
class MPWeeklyInsightChallengeItemStruct {
  MPWeeklyInsightChallengeItemStruct({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  /// 从 JSON 解析。
  factory MPWeeklyInsightChallengeItemStruct.fromJson(Map<String, dynamic> json) {
    return MPWeeklyInsightChallengeItemStruct(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'description': description,
      };
}

/// Weekly Insight「Pending Items」条目。
class MPWeeklyInsightPendingItemStruct {
  MPWeeklyInsightPendingItemStruct({
    required this.content,
  });

  final String content;

  /// 从 JSON 解析。
  factory MPWeeklyInsightPendingItemStruct.fromJson(Map<String, dynamic> json) {
    return MPWeeklyInsightPendingItemStruct(
      content: json['content'] as String? ?? '',
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'content': content,
      };
}

/// Weekly Insight「Expert Weekly Feedback」条目。
class MPWeeklyInsightExpertFeedbackItemStruct {
  MPWeeklyInsightExpertFeedbackItemStruct({
    required this.expertName,
    required this.feedback,
  });

  final String expertName;
  final String feedback;

  /// 从 JSON 解析。
  factory MPWeeklyInsightExpertFeedbackItemStruct.fromJson(Map<String, dynamic> json) {
    return MPWeeklyInsightExpertFeedbackItemStruct(
      expertName: json['expert_name'] as String? ?? '',
      feedback: json['feedback'] as String? ?? '',
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'expert_name': expertName,
        'feedback': feedback,
      };
}

/// Weekly 类型专属详情。
class MPWeeklyInsightDetailStruct {
  MPWeeklyInsightDetailStruct({
    required this.header,
    required this.weekSummary,
    required this.accomplishments,
    required this.challengesAndLearnings,
    required this.pendingItems,
    required this.nextWeekPriorities,
    required this.expertWeeklyFeedback,
  });

  final MPWeeklyInsightHeaderSectionStruct header;
  final MPWeeklyInsightSummarySectionStruct weekSummary;
  final List<MPWeeklyInsightAccomplishmentItemStruct> accomplishments;
  final List<MPWeeklyInsightChallengeItemStruct> challengesAndLearnings;
  final List<MPWeeklyInsightPendingItemStruct> pendingItems;
  final List<MPTodoStruct> nextWeekPriorities;
  final List<MPWeeklyInsightExpertFeedbackItemStruct> expertWeeklyFeedback;

  /// 从 JSON 解析。
  factory MPWeeklyInsightDetailStruct.fromJson(Map<String, dynamic> json) {
    final List<MPWeeklyInsightAccomplishmentItemStruct> accomplishments =
        _mpAsList(json['accomplishments'])
            .map(
              (dynamic e) => MPWeeklyInsightAccomplishmentItemStruct.fromJson(
                _mpAsMap(e),
              ),
            )
            .toList();

    final List<MPWeeklyInsightChallengeItemStruct> challengesAndLearnings =
        _mpAsList(json['challenges_and_learnings'])
            .map(
              (dynamic e) => MPWeeklyInsightChallengeItemStruct.fromJson(
                _mpAsMap(e),
              ),
            )
            .toList();

    final List<MPWeeklyInsightPendingItemStruct> pendingItems = _mpAsList(json['pending_items'])
        .map(
          (dynamic e) => MPWeeklyInsightPendingItemStruct.fromJson(
            _mpAsMap(e),
          ),
        )
        .toList();

    final List<MPTodoStruct> nextWeekPriorities = _mpAsInsightTodoList(json['next_week_priorities']);

    final List<MPWeeklyInsightExpertFeedbackItemStruct> expertWeeklyFeedback =
        _mpAsList(json['expert_weekly_feedback'])
            .map(
              (dynamic e) => MPWeeklyInsightExpertFeedbackItemStruct.fromJson(
                _mpAsMap(e),
              ),
            )
            .toList();

    return MPWeeklyInsightDetailStruct(
      header: MPWeeklyInsightHeaderSectionStruct.fromJson(
        _mpAsMap(json['header']),
      ),
      weekSummary: MPWeeklyInsightSummarySectionStruct.fromJson(
        _mpAsMap(json['week_summary']),
      ),
      accomplishments: accomplishments,
      challengesAndLearnings: challengesAndLearnings,
      pendingItems: pendingItems,
      nextWeekPriorities: nextWeekPriorities,
      expertWeeklyFeedback: expertWeeklyFeedback,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'header': header.toJson(),
        'week_summary': weekSummary.toJson(),
        'accomplishments':
            accomplishments.map((MPWeeklyInsightAccomplishmentItemStruct e) => e.toJson()).toList(),
        'challenges_and_learnings':
            challengesAndLearnings.map((MPWeeklyInsightChallengeItemStruct e) => e.toJson()).toList(),
        'pending_items': pendingItems.map((MPWeeklyInsightPendingItemStruct e) => e.toJson()).toList(),
        'next_week_priorities': nextWeekPriorities.map((MPTodoStruct e) => e.toJson()).toList(),
        'expert_weekly_feedback': expertWeeklyFeedback
            .map((MPWeeklyInsightExpertFeedbackItemStruct e) => e.toJson())
            .toList(),
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
    this.memoryId,
  });

  final MPInsightCardStruct basicInfo;
  final int insightType;

  /// `insight_type == PATTERN` 时返回。
  final MPPatternInsightDetailStruct? patternDetail;

  /// `insight_type == MONTHLY` 时返回。
  final MPMonthlyInsightDetailStruct? monthlyDetail;

  /// `insight_type == DAILY` 时返回。
  final MPDailyInsightDetailStruct? dailyDetail;

  /// `insight_type == WEEKLY` 时返回。
  final MPWeeklyInsightDetailStruct? weeklyDetail;

  final int? memoryId;

  /// 从 JSON 解析。
  factory MPInsightDetailStruct.fromJson(Map<String, dynamic> json) {
    return MPInsightDetailStruct(
      basicInfo: MPInsightCardStruct.fromJson(
        _mpAsMap(json['basic_info']),
      ),
      insightType: _mpAsInt(
        json['insight_type'],
        defaultValue: MPInsightCycleType.daily,
      ),
      patternDetail: json['pattern_detail'] == null
          ? null
          : MPPatternInsightDetailStruct.fromJson(
              _mpAsMap(json['pattern_detail']),
            ),
      monthlyDetail: json['monthly_detail'] == null
          ? null
          : MPMonthlyInsightDetailStruct.fromJson(
              _mpAsMap(json['monthly_detail']),
            ),
      dailyDetail: json['daily_detail'] == null
          ? null
          : MPDailyInsightDetailStruct.fromJson(
              _mpAsMap(json['daily_detail']),
            ),
      weeklyDetail: json['weekly_detail'] == null
          ? null
          : MPWeeklyInsightDetailStruct.fromJson(
              _mpAsMap(json['weekly_detail']),
            ),
      memoryId: _mpAsInt(json['memory_id']),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'basic_info': basicInfo.toJson(),
        'insight_type': insightType,
        if (patternDetail != null) 'pattern_detail': patternDetail!.toJson(),
        if (monthlyDetail != null) 'monthly_detail': monthlyDetail!.toJson(),
        if (dailyDetail != null) 'daily_detail': dailyDetail!.toJson(),
        if (weeklyDetail != null) 'weekly_detail': weeklyDetail!.toJson(),
        if (memoryId != null) 'memory_id': memoryId,
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
        _mpAsMap(json['insight_detail']),
      ),
      baseResp: MPBaseResp.fromJson(
        _mpAsMap(json['base_resp']),
      ),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'insight_detail': insightDetail.toJson(),
        'base_resp': baseResp.toJson(),
      };
}
