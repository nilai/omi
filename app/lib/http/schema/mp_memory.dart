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