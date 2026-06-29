import 'package:memo_pin/http/schema/mp_insight.dart';

import 'mp_data_model.dart';


/// 转录弹窗结构体（后端 `TranscriptionBannerStruct`）。
class MPTranscriptionBannerStruct {
  MPTranscriptionBannerStruct({
    required this.bannerId,
    required this.threshold,
    required this.currentMinutes,
    required this.showBanner,
    required this.bannerContent,
  });

  final int bannerId;
  final int threshold;
  final int currentMinutes;
  final bool showBanner;
  final String bannerContent;

  /// 是否展示首页转录提示卡片。
  bool get shouldShowBanner => showBanner && bannerContent.trim().isNotEmpty;

  /// 从 JSON 解析。
  factory MPTranscriptionBannerStruct.fromJson(Map<String, dynamic> json) {
    return MPTranscriptionBannerStruct(
      bannerId: (json['banner_id'] as num?)?.toInt() ?? 0,
      threshold: (json['threshold'] as num?)?.toInt() ?? 0,
      currentMinutes: (json['current_minutes'] as num?)?.toInt() ?? 0,
      showBanner: json['show_banner'] as bool? ?? false,
      bannerContent: json['banner_content'] as String? ?? '',
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'banner_id': bannerId,
        'threshold': threshold,
        'current_minutes': currentMinutes,
        'show_banner': showBanner,
        'banner_content': bannerContent,
      };
}

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
    required this.transcriptionBanner,
    required this.baseResp,
  });

  final List<MPTodoStruct> focusItems;
  final List<MPMemoryStruct> recentMemories;
  final MPHomeInsightOverviewStruct insightOverview;
  final MPTranscriptionBannerStruct transcriptionBanner;
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
    final Map<String, dynamic>? bannerMap =
        json['transcription_banner'] as Map<String, dynamic>?;

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
      transcriptionBanner: bannerMap != null
          ? MPTranscriptionBannerStruct.fromJson(bannerMap)
          : MPTranscriptionBannerStruct(
              bannerId: 0,
              threshold: 0,
              currentMinutes: 0,
              showBanner: false,
              bannerContent: '',
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
        'transcription_banner': transcriptionBanner.toJson(),
        'base_resp': baseResp.toJson(),
      };
}

/// 关闭转录弹窗请求（后端 `CloseTranscriptionBannerRequest`）。
class MPCloseTranscriptionBannerRequest {
  MPCloseTranscriptionBannerRequest({required this.bannerId});

  final int bannerId;

  /// 从 JSON 解析。
  factory MPCloseTranscriptionBannerRequest.fromJson(Map<String, dynamic> json) {
    return MPCloseTranscriptionBannerRequest(
      bannerId: (json['banner_id'] as num?)?.toInt() ?? 0,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'banner_id': bannerId,
      };
}

/// 关闭转录弹窗响应（后端 `CloseTranscriptionBannerResponse`）。
class MPCloseTranscriptionBannerResponse {
  MPCloseTranscriptionBannerResponse({required this.baseResp});

  final MPBaseResp baseResp;

  /// 从 JSON 解析。
  factory MPCloseTranscriptionBannerResponse.fromJson(Map<String, dynamic> json) {
    return MPCloseTranscriptionBannerResponse(
      baseResp: MPBaseResp.fromJson(
        json['base_resp'] as Map<String, dynamic>,
      ),
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'base_resp': baseResp.toJson(),
      };
}
