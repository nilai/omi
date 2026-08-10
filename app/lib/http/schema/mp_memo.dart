import 'package:json_annotation/json_annotation.dart';
import 'package:memo_pin/utils/mp_time_utils.dart';

import 'mp_base.dart';

part 'mp_memo.g.dart';

/// 解析 JSON 中的 `create_at`；缺失或非数字时得到 `0`，再由构造过程兜底为当前秒。
int _memoParseCreateAtForCtor(Object? raw) {
  if (raw is num) {
    return raw.toInt();
  }
  return 0;
}

int _memoNormalizeUnixSeconds(int value) {
  if (value <= 0) {
    return MPTimeUtils.nowUnixSeconds();
  }
  return value;
}

@JsonSerializable()
class MPCreateMemoWithTextRequest {
  @JsonKey(name: 'content')
  final String content;

  @JsonKey(name: 'memory_id')
  final String? memoryId;

  @JsonKey(name: 'create_at', fromJson: _memoParseCreateAtForCtor)
  final int createAt;

  MPCreateMemoWithTextRequest({
    required this.content,
    this.memoryId,
    required int createAt,
  }) : createAt = _memoNormalizeUnixSeconds(createAt);

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

  factory MPDeleteMemoRequest.fromJson(Map<String, dynamic> json) => _$MPDeleteMemoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPDeleteMemoRequestToJson(this);
}

@JsonSerializable()
class MPCreateMemoWithTextResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPCreateMemoWithTextResponse({
    required this.baseResp,
  });

  factory MPCreateMemoWithTextResponse.fromJson(Map<String, dynamic> json) =>
      _$MPCreateMemoWithTextResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateMemoWithTextResponseToJson(this);
}

// Delete Memo Response
@JsonSerializable()
class MPDeleteMemoResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPDeleteMemoResponse({
    required this.baseResp,
  });

  factory MPDeleteMemoResponse.fromJson(Map<String, dynamic> json) => _$MPDeleteMemoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPDeleteMemoResponseToJson(this);
}

/// 与后端 `AnalyzeMemoSuggestionType` 对齐。
enum MPAnalyzeMemoSuggestionType {
  @JsonValue(1)
  todo,

  @JsonValue(2)
  memo,
}

@JsonSerializable()
class MPAnalyzeMemoSuggestionStruct {
  @JsonKey(name: 'type')
  final MPAnalyzeMemoSuggestionType type;

  @JsonKey(name: 'content')
  final String content;

  @JsonKey(name: 'deadline')
  final int? deadline;

  @JsonKey(name: 'description')
  final String? description;

  MPAnalyzeMemoSuggestionStruct({
    required this.type,
    required this.content,
    this.deadline,
    this.description,
  });

  factory MPAnalyzeMemoSuggestionStruct.fromJson(Map<String, dynamic> json) =>
      _$MPAnalyzeMemoSuggestionStructFromJson(json);

  Map<String, dynamic> toJson() => _$MPAnalyzeMemoSuggestionStructToJson(this);
}

@JsonSerializable()
class MPAnalyzeMemoRecordRequest {
  @JsonKey(name: 'record_url')
  final String recordUrl;

  @JsonKey(name: 'create_at')
  final int createAt;

  MPAnalyzeMemoRecordRequest({
    required this.recordUrl,
    required this.createAt,
  });

  factory MPAnalyzeMemoRecordRequest.fromJson(Map<String, dynamic> json) =>
      _$MPAnalyzeMemoRecordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPAnalyzeMemoRecordRequestToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MPAnalyzeMemoRecordResponse {
  @JsonKey(name: 'original_text')
  final String originalText;

  @JsonKey(name: 'structured_suggestions')
  final List<MPAnalyzeMemoSuggestionStruct> structuredSuggestions;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPAnalyzeMemoRecordResponse({
    required this.originalText,
    required this.structuredSuggestions,
    required this.baseResp,
  });

  factory MPAnalyzeMemoRecordResponse.fromJson(Map<String, dynamic> json) =>
      _$MPAnalyzeMemoRecordResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPAnalyzeMemoRecordResponseToJson(this);
}

@JsonSerializable()
class MPAnalyzeMemoTextRequest {
  @JsonKey(name: 'content')
  final String content;

  @JsonKey(name: 'create_at')
  final int createAt;

  MPAnalyzeMemoTextRequest({
    required this.content,
    required this.createAt,
  });

  factory MPAnalyzeMemoTextRequest.fromJson(Map<String, dynamic> json) =>
      _$MPAnalyzeMemoTextRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPAnalyzeMemoTextRequestToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MPAnalyzeMemoTextResponse {
  @JsonKey(name: 'original_text')
  final String originalText;

  @JsonKey(name: 'structured_suggestions')
  final List<MPAnalyzeMemoSuggestionStruct> structuredSuggestions;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPAnalyzeMemoTextResponse({
    required this.originalText,
    required this.structuredSuggestions,
    required this.baseResp,
  });

  factory MPAnalyzeMemoTextResponse.fromJson(Map<String, dynamic> json) =>
      _$MPAnalyzeMemoTextResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPAnalyzeMemoTextResponseToJson(this);
}