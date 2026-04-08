import 'package:json_annotation/json_annotation.dart';

import 'mp_data_model.dart';

part 'mp_memory.g.dart';

// Get Memory List Request
@JsonSerializable()
class MPGetMemoryV2ListRequest {
  @JsonKey(name: 'page_size')
  final int pageSize;

  @JsonKey(name: 'cursor')
  final String cursor;

  @JsonKey(name: 'day')
  final String? day; // 如2025-12-21

  MPGetMemoryV2ListRequest({
    required this.pageSize,
    required this.cursor,
    this.day,
  });

  factory MPGetMemoryV2ListRequest.fromJson(Map<String, dynamic> json) => _$MPGetMemoryV2ListRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetMemoryV2ListRequestToJson(this);
}

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


@JsonSerializable()
class MPGetMemoryV2DetailRequest {
 
  @JsonKey(name: 'memory_id')
  final String memoryId;

  MPGetMemoryV2DetailRequest({
    required this.memoryId,
  });

  factory MPGetMemoryV2DetailRequest.fromJson(Map<String, dynamic> json) => _$MPGetMemoryV2DetailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetMemoryV2DetailRequestToJson(this);
}


@JsonSerializable()
class MPGetMemoryV2DetailResponse {
  @JsonKey(name: 'memory_detail')
  final MPMemoryStruct memoryDetail;

  MPGetMemoryV2DetailResponse({
    required this.memoryDetail,
  });

  factory MPGetMemoryV2DetailResponse.fromJson(Map<String, dynamic> json) => _$MPGetMemoryV2DetailResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MPGetMemoryV2DetailResponseToJson(this);
}


@JsonSerializable()
class MPGetMemoryFeedRequest {
  @JsonKey(name: 'memory_id')
  final String memoryId;

  @JsonKey(name: 'page_size')
  final int? pageSize;

  @JsonKey(name: 'cursor')
  final String cursor;

  MPGetMemoryFeedRequest({
    required this.memoryId,
    this.pageSize,
    required this.cursor,
  });

  factory MPGetMemoryFeedRequest.fromJson(Map<String, dynamic> json) => _$MPGetMemoryFeedRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetMemoryFeedRequestToJson(this);
}

@JsonSerializable()
class MPGetMemoryFeedResponse {
  @JsonKey(name: 'feeds')
  final List<MPFeedCardStruct>? feeds;

  @JsonKey(name: 'has_more')
  final bool? hasMore;


  MPGetMemoryFeedResponse({
    this.feeds,
    this.hasMore,
  });

  factory MPGetMemoryFeedResponse.fromJson(Map<String, dynamic> json) => _$MPGetMemoryFeedResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MPGetMemoryFeedResponseToJson(this);
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

/// 预签名URL响应模型
/// 用于获取S3上传的预签名URL
@JsonSerializable()
class PresignedUrlResponse {
  /// S3预签名上传URL
  @JsonKey(name: 'upload_url')
  final String uploadUrl;

  /// 文件在S3中的路径
  @JsonKey(name: 'uri')
  final String uri;

  PresignedUrlResponse({
    required this.uploadUrl,
    required this.uri,
  });

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) =>
      _$PresignedUrlResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PresignedUrlResponseToJson(this);

  @override
  String toString() {
    return 'PresignedUrlResponse(uploadUrl: $uploadUrl, uri: $uri)';
  }
}

/// 录音记录模型
/// 表示一条音频录音的记录信息
@JsonSerializable()
class AudioRecord {
  /// 录音记录ID
  @JsonKey(name: 'audio_record_id')
  final String audioRecordId;

  /// 音频文件URI（S3路径）
  @JsonKey(name: 'audio_uri')
  final String audioUri;

  /// 录音发生时间的时间戳（秒）
  @JsonKey(name: 'record_ts')
  final int recordTs;

  /// 状态码 (0表示成功)
  @JsonKey(name: 'status_code')
  final int statusCode;

  /// 状态消息
  @JsonKey(name: 'status_message')
  final String statusMessage;

  AudioRecord({
    required this.audioRecordId,
    required this.audioUri,
    required this.recordTs,
    required this.statusCode,
    required this.statusMessage,
  });

  factory AudioRecord.fromJson(Map<String, dynamic> json) =>
      _$AudioRecordFromJson(json);

  Map<String, dynamic> toJson() => _$AudioRecordToJson(this);

  /// 是否创建成功
  bool get isSuccess => statusCode == 0;

  /// 获取录音时间（DateTime格式）
  DateTime get recordTime =>
      DateTime.fromMillisecondsSinceEpoch(recordTs * 1000);

  @override
  String toString() {
    return 'AudioRecord(audioRecordId: $audioRecordId, audioUri: $audioUri, recordTs: $recordTs, statusCode: $statusCode, statusMessage: $statusMessage)';
  }
}