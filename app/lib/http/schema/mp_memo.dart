import 'package:json_annotation/json_annotation.dart';

import 'mp_base.dart';

part 'mp_memo.g.dart';


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