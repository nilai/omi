import 'package:json_annotation/json_annotation.dart';

part 'mp_memory.g.dart';

// Get Memory List Request
@JsonSerializable()
class MPGetMemoryListRequest {
  @JsonKey(name: 'page_size')
  final int pageSize;

  @JsonKey(name: 'cursor')
  final String cursor;

  MPGetMemoryListRequest({
    required this.pageSize,
    required this.cursor,
  });

  factory MPGetMemoryListRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetMemoryListRequestFromJson(json);

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

  factory MPGetMemoryDaysRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetMemoryDaysRequestFromJson(json);

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

  factory MPGetMemoryDetailRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetMemoryDetailRequestFromJson(json);

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

  factory MPGetInsightListRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetInsightListRequestFromJson(json);

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

  MPCreateRecordRequest({
    required this.recordFile,
    required this.createAt,
    required this.duration,
  });

  factory MPCreateRecordRequest.fromJson(Map<String, dynamic> json) =>
      _$MPCreateRecordRequestFromJson(json);

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

  MPSummaryRecordRequest({
    required this.memoryId,
    required this.recordUrl,
    required this.recordMemoAt,
  });

  factory MPSummaryRecordRequest.fromJson(Map<String, dynamic> json) =>
      _$MPSummaryRecordRequestFromJson(json);

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

  factory MPShareMemoryRequest.fromJson(Map<String, dynamic> json) =>
      _$MPShareMemoryRequestFromJson(json);

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

  factory MPDeleteMemoryRequest.fromJson(Map<String, dynamic> json) =>
      _$MPDeleteMemoryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPDeleteMemoryRequestToJson(this);
}

