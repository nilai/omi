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