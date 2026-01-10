import 'package:json_annotation/json_annotation.dart';

import 'mp_data_model.dart';

part 'mp_memory.g.dart';

// Get Memory List Request
@JsonSerializable()
class MPGetMemoryListRequest {
  @JsonKey(name: 'page_size')
  final int pageSize;

  @JsonKey(name: 'cursor')
  final String cursor;

  @JsonKey(name: 'day')
  final String? day; // 如2025-12-21

  MPGetMemoryListRequest({
    required this.pageSize,
    required this.cursor,
    this.day,
  });

  factory MPGetMemoryListRequest.fromJson(Map<String, dynamic> json) => _$MPGetMemoryListRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetMemoryListRequestToJson(this);
}

// Get Memory Days Request
@JsonSerializable()
class MPGetMemoryDaysRequest {
  @JsonKey(name: 'month')
  final String month; // 如2025-11、2025-01

  MPGetMemoryDaysRequest({
    required this.month,
  });

  factory MPGetMemoryDaysRequest.fromJson(Map<String, dynamic> json) => _$MPGetMemoryDaysRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetMemoryDaysRequestToJson(this);
}

// Get Memory Detail Request
@JsonSerializable()
class MPGetMemoryDetailRequest {
  @JsonKey(name: 'memory_id')
  final String memoryId;

  MPGetMemoryDetailRequest({
    required this.memoryId,
  });

  factory MPGetMemoryDetailRequest.fromJson(Map<String, dynamic> json) => _$MPGetMemoryDetailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetMemoryDetailRequestToJson(this);
}

// Get Insight List Request
@JsonSerializable()
class MPGetInsightListRequest {
  @JsonKey(name: 'page_size')
  final int pageSize;

  @JsonKey(name: 'cursor')
  final String cursor;

  MPGetInsightListRequest({
    required this.pageSize,
    required this.cursor,
  });

  factory MPGetInsightListRequest.fromJson(Map<String, dynamic> json) => _$MPGetInsightListRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetInsightListRequestToJson(this);
}

// Create Record Request
@JsonSerializable()
class MPCreateRecordRequest {
  @JsonKey(name: 'record_file')
  final String recordFile;

  @JsonKey(name: 'create_at')
  final int createAt;

  @JsonKey(name: 'duration')
  final int duration; // 单位是s

  @JsonKey(name: 'source')
  final String? source;

  MPCreateRecordRequest({
    required this.recordFile,
    required this.createAt,
    required this.duration,
    this.source,
  });

  factory MPCreateRecordRequest.fromJson(Map<String, dynamic> json) => _$MPCreateRecordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateRecordRequestToJson(this);
}

// Get Upload Record Url Request
@JsonSerializable()
class MPGetUploadRecordUrlRequest {
  @JsonKey(name: 'content_type')
  final String contentType;

  MPGetUploadRecordUrlRequest({
    required this.contentType,
  });

  factory MPGetUploadRecordUrlRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetUploadRecordUrlRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetUploadRecordUrlRequestToJson(this);
}

// Summary Record Request
@JsonSerializable()
class MPSummaryRecordRequest {
  @JsonKey(name: 'memory_id')
  final String memoryId;

  @JsonKey(name: 'record_url')
  final String recordUrl;

  @JsonKey(name: 'record_memo_at')
  final int recordMemoAt; // 针对开启录音情况下的memo创建，这里给到memo发生时录音具体时间点，相对时间，即录音的第几秒

  @JsonKey(name: 'template_id')
  final String? templateId; // 模板ID

  @JsonKey(name: 'is_regen')
  final bool isRegen;

  MPSummaryRecordRequest({
    required this.memoryId,
    required this.recordUrl,
    required this.recordMemoAt,
    this.templateId,
    this.isRegen = false,
  });

  factory MPSummaryRecordRequest.fromJson(Map<String, dynamic> json) => _$MPSummaryRecordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPSummaryRecordRequestToJson(this);
}

// Share Memory Request
@JsonSerializable()
class MPShareMemoryRequest {
  @JsonKey(name: 'memory_id')
  final String memoryId;

  MPShareMemoryRequest({
    required this.memoryId,
  });

  factory MPShareMemoryRequest.fromJson(Map<String, dynamic> json) => _$MPShareMemoryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPShareMemoryRequestToJson(this);
}

// Delete Memory Request
@JsonSerializable()
class MPDeleteMemoryRequest {
  @JsonKey(name: 'memory_id')
  final String memoryId;

  MPDeleteMemoryRequest({
    required this.memoryId,
  });

  factory MPDeleteMemoryRequest.fromJson(Map<String, dynamic> json) => _$MPDeleteMemoryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPDeleteMemoryRequestToJson(this);
}

// Get Summary Status Request
@JsonSerializable()
class MPGetSummaryStatusRequest {
  @JsonKey(name: 'memory_id')
  final String memoryId;

  MPGetSummaryStatusRequest({
    required this.memoryId,
  });

  factory MPGetSummaryStatusRequest.fromJson(Map<String, dynamic> json) => _$MPGetSummaryStatusRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetSummaryStatusRequestToJson(this);
}

// Search Memory Request
@JsonSerializable()
class MPSearchMemoryRequest {
  @JsonKey(name: 'search_content')
  final String searchContent;

  MPSearchMemoryRequest({
    required this.searchContent,
  });

  factory MPSearchMemoryRequest.fromJson(Map<String, dynamic> json) => _$MPSearchMemoryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPSearchMemoryRequestToJson(this);
}

// Get Summary List Request
@JsonSerializable()
class MPGetSummaryListRequest {
  @JsonKey(name: 'page_size')
  final int pageSize;

  @JsonKey(name: 'cursor')
  final String cursor;

  MPGetSummaryListRequest({
    required this.pageSize,
    required this.cursor,
  });

  factory MPGetSummaryListRequest.fromJson(Map<String, dynamic> json) => _$MPGetSummaryListRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetSummaryListRequestToJson(this);
}

// Append Memory Request
@JsonSerializable()
class MPAppendMemoryRequest {
  @JsonKey(name: 'memory_ids')
  final List<String> memoryIds;

  MPAppendMemoryRequest({
    required this.memoryIds,
  });

  factory MPAppendMemoryRequest.fromJson(Map<String, dynamic> json) => _$MPAppendMemoryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPAppendMemoryRequestToJson(this);
}

// ========== Response Classes ==========

// Get Memory List Response
@JsonSerializable()
class MPGetMemoryListResponse {
  @JsonKey(name: 'memorys')
  final List<MPMemoryStruct> memorys;

  @JsonKey(name: 'has_more')
  final bool hasMore;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  @JsonKey(name: 'memory_total')
  final int memoryTotal;

  MPGetMemoryListResponse({
    required this.memorys,
    required this.hasMore,
    required this.baseResp,
    required this.memoryTotal,
  });

  factory MPGetMemoryListResponse.fromJson(Map<String, dynamic> json) => _$MPGetMemoryListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetMemoryListResponseToJson(this);
}

// Get Memory Days Response
@JsonSerializable()
class MPGetMemoryDaysResponse {
  @JsonKey(name: 'days')
  final List<String> days; // 返回有记录的日期列表, [2025-11-10, 2025-11-11, 2025-11-15]

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetMemoryDaysResponse({
    required this.days,
    required this.baseResp,
  });

  factory MPGetMemoryDaysResponse.fromJson(Map<String, dynamic> json) => _$MPGetMemoryDaysResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetMemoryDaysResponseToJson(this);
}

// Get Memory Detail Response
@JsonSerializable()
class MPGetMemoryDetailResponse {
  @JsonKey(name: 'memory')
  final MPMemoryStruct memory;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetMemoryDetailResponse({
    required this.memory,
    required this.baseResp,
  });

  factory MPGetMemoryDetailResponse.fromJson(Map<String, dynamic> json) => _$MPGetMemoryDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetMemoryDetailResponseToJson(this);
}

// Get Insight List Response
@JsonSerializable()
class MPGetInsightListResponse {
  @JsonKey(name: 'memorys', defaultValue: [])
  final List<MPMemoryStruct> memorys;

  @JsonKey(name: 'has_more')
  final bool hasMore;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetInsightListResponse({
    required this.memorys,
    required this.hasMore,
    required this.baseResp,
  });

  factory MPGetInsightListResponse.fromJson(Map<String, dynamic> json) => _$MPGetInsightListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetInsightListResponseToJson(this);
}

// Create Record Response
@JsonSerializable()
class MPCreateRecordResponse {
  @JsonKey(name: 'memory_id')
  final String memoryId;

  @JsonKey(name: 'record_url')
  final String recordUrl;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPCreateRecordResponse({
    required this.baseResp,
    required this.memoryId,
    required this.recordUrl,
  });

  factory MPCreateRecordResponse.fromJson(Map<String, dynamic> json) => _$MPCreateRecordResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateRecordResponseToJson(this);
}

// Get Upload Record Url Response
@JsonSerializable()
class MPGetUploadRecordUrlResponse {
  @JsonKey(name: 'upload_url')
  final String uploadUrl;

  @JsonKey(name: 'uri')
  final String uri;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetUploadRecordUrlResponse({
    required this.uploadUrl,
    required this.uri,
    required this.baseResp,
  });

  factory MPGetUploadRecordUrlResponse.fromJson(Map<String, dynamic> json) =>
      _$MPGetUploadRecordUrlResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetUploadRecordUrlResponseToJson(this);
}

// Summary Record Response
@JsonSerializable()
class MPSummaryRecordResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPSummaryRecordResponse({
    required this.baseResp,
  });

  factory MPSummaryRecordResponse.fromJson(Map<String, dynamic> json) => _$MPSummaryRecordResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPSummaryRecordResponseToJson(this);
}

// Share Memory Response
@JsonSerializable()
class MPShareMemoryResponse {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'share_code')
  final String shareCode;

  @JsonKey(name: 'share_url')
  final String shareUrl;

  @JsonKey(name: 'short_url')
  final String shortUrl;

  @JsonKey(name: 'expires_at')
  final int expiresAt;

  @JsonKey(name: 'create_at')
  final int createAt;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPShareMemoryResponse({
    required this.id,
    required this.shareCode,
    required this.shareUrl,
    required this.shortUrl,
    required this.expiresAt,
    required this.createAt,
    required this.baseResp,
  });

  factory MPShareMemoryResponse.fromJson(Map<String, dynamic> json) => _$MPShareMemoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPShareMemoryResponseToJson(this);
}

// Update Memory Name Request
@JsonSerializable()
class MPUpdateMemoryNameRequest {
  @JsonKey(name: 'memory_id')
  final String memoryId;

  @JsonKey(name: 'title')
  final String title;

  MPUpdateMemoryNameRequest({
    required this.memoryId,
    required this.title,
  });

  factory MPUpdateMemoryNameRequest.fromJson(Map<String, dynamic> json) => _$MPUpdateMemoryNameRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPUpdateMemoryNameRequestToJson(this);
}

// Rename Memory Request
@JsonSerializable()
class MPRenameMemoryRequest {
  @JsonKey(name: 'memory_id')
  final String memoryId;

  @JsonKey(name: 'title')
  final String title;

  MPRenameMemoryRequest({
    required this.memoryId,
    required this.title,
  });

  factory MPRenameMemoryRequest.fromJson(Map<String, dynamic> json) => _$MPRenameMemoryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPRenameMemoryRequestToJson(this);
}

// Memory Add Tag Request
@JsonSerializable()
class MPMemoryAddTagRequest {
  @JsonKey(name: 'memory_id')
  final String memoryId;

  @JsonKey(name: 'label')
  final String label;

  MPMemoryAddTagRequest({
    required this.memoryId,
    required this.label,
  });

  factory MPMemoryAddTagRequest.fromJson(Map<String, dynamic> json) => _$MPMemoryAddTagRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPMemoryAddTagRequestToJson(this);
}

// Delete Memory Response
@JsonSerializable()
class MPDeleteMemoryResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPDeleteMemoryResponse({
    required this.baseResp,
  });

  factory MPDeleteMemoryResponse.fromJson(Map<String, dynamic> json) => _$MPDeleteMemoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPDeleteMemoryResponseToJson(this);
}

// Update Memory Name Response
@JsonSerializable()
class MPUpdateMemoryNameResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPUpdateMemoryNameResponse({
    required this.baseResp,
  });

  factory MPUpdateMemoryNameResponse.fromJson(Map<String, dynamic> json) => _$MPUpdateMemoryNameResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPUpdateMemoryNameResponseToJson(this);
}

// Rename Memory Response
@JsonSerializable()
class MPRenameMemoryResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPRenameMemoryResponse({
    required this.baseResp,
  });

  factory MPRenameMemoryResponse.fromJson(Map<String, dynamic> json) => _$MPRenameMemoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPRenameMemoryResponseToJson(this);
}

// Memory Add Tag Response
@JsonSerializable()
class MPMemoryAddTagResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPMemoryAddTagResponse({
    required this.baseResp,
  });

  factory MPMemoryAddTagResponse.fromJson(Map<String, dynamic> json) => _$MPMemoryAddTagResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPMemoryAddTagResponseToJson(this);
}

// Get Popular Search Keywords Response
@JsonSerializable()
class MPGetPopularSearchKeywordsResponse {
  @JsonKey(name: 'keywords')
  final List<String> keywords;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetPopularSearchKeywordsResponse({
    required this.keywords,
    required this.baseResp,
  });

  factory MPGetPopularSearchKeywordsResponse.fromJson(Map<String, dynamic> json) =>
      _$MPGetPopularSearchKeywordsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetPopularSearchKeywordsResponseToJson(this);
}

// Get Summary Status Response
@JsonSerializable()
class MPGetSummaryStatusResponse {
  @JsonKey(name: 'status')
  final int status;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetSummaryStatusResponse({
    required this.status,
    required this.baseResp,
  });

  factory MPGetSummaryStatusResponse.fromJson(Map<String, dynamic> json) => _$MPGetSummaryStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetSummaryStatusResponseToJson(this);
}

// Search Memory Response
@JsonSerializable()
class MPSearchMemoryResponse {
  @JsonKey(name: 'memorys')
  final List<MPMemoryStruct> memorys;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPSearchMemoryResponse({
    required this.memorys,
    required this.baseResp,
  });

  factory MPSearchMemoryResponse.fromJson(Map<String, dynamic> json) => _$MPSearchMemoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPSearchMemoryResponseToJson(this);
}

// Get Summary List Response
@JsonSerializable()
class MPGetSummaryListResponse {
  @JsonKey(name: 'summarys')
  final List<MPMemoryStruct> summarys;

  @JsonKey(name: 'has_more')
  final bool hasMore;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetSummaryListResponse({
    required this.summarys,
    required this.hasMore,
    required this.baseResp,
  });

  factory MPGetSummaryListResponse.fromJson(Map<String, dynamic> json) => _$MPGetSummaryListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetSummaryListResponseToJson(this);
}

// Append Memory Response
@JsonSerializable()
class MPAppendMemoryResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPAppendMemoryResponse({
    required this.baseResp,
  });

  factory MPAppendMemoryResponse.fromJson(Map<String, dynamic> json) => _$MPAppendMemoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPAppendMemoryResponseToJson(this);
}
