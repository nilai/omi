import 'package:json_annotation/json_annotation.dart';

part 'mp_memo.g.dart';

// Get Memo List Request
@JsonSerializable()
class MPGetMemoListRequest {
  @JsonKey(name: 'page_size')
  final int pageSize;

  @JsonKey(name: 'cursor')
  final String cursor;

  MPGetMemoListRequest({
    required this.pageSize,
    required this.cursor,
  });

  factory MPGetMemoListRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetMemoListRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetMemoListRequestToJson(this);
}

// Get Memo Detail Request
@JsonSerializable()
class MPGetMemoDetailRequest {
  @JsonKey(name: 'memo_id')
  final String memoId;

  MPGetMemoDetailRequest({
    required this.memoId,
  });

  factory MPGetMemoDetailRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetMemoDetailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetMemoDetailRequestToJson(this);
}

// Create Memo With Record Request
@JsonSerializable()
class MPCreateMemoWithRecordRequest {
  @JsonKey(name: 'record_url')
  final String recordUrl; // 针对没开启录音情况下的memo创建

  @JsonKey(name: 'create_at')
  final int createAt;

  MPCreateMemoWithRecordRequest({
    required this.recordUrl,
    required this.createAt,
  });

  factory MPCreateMemoWithRecordRequest.fromJson(Map<String, dynamic> json) =>
      _$MPCreateMemoWithRecordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateMemoWithRecordRequestToJson(this);
}

// Create Memo With Text Request
@JsonSerializable()
class MPCreateMemoWithTextRequest {
  @JsonKey(name: 'content')
  final String content;

  @JsonKey(name: 'create_at')
  final int createAt;

  MPCreateMemoWithTextRequest({
    required this.content,
    required this.createAt,
  });

  factory MPCreateMemoWithTextRequest.fromJson(Map<String, dynamic> json) =>
      _$MPCreateMemoWithTextRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateMemoWithTextRequestToJson(this);
}

// Delete Memo Request
@JsonSerializable()
class MPDeleteMemoRequest {
  @JsonKey(name: 'memo_id')
  final String memoId;

  MPDeleteMemoRequest({
    required this.memoId,
  });

  factory MPDeleteMemoRequest.fromJson(Map<String, dynamic> json) =>
      _$MPDeleteMemoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPDeleteMemoRequestToJson(this);
}

