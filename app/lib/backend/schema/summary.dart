import 'package:json_annotation/json_annotation.dart';

part 'summary.g.dart';

@JsonSerializable()
class SummaryRequest {
  @JsonKey(name: 'audio_record_id')
  final String audioRecordId;

  SummaryRequest({
    required this.audioRecordId,
  });

  factory SummaryRequest.fromJson(Map<String, dynamic> json) =>
      _$SummaryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SummaryRequestToJson(this);
}

@JsonSerializable()
class SummaryResponse {
  @JsonKey(name: 'status_code')
  final int statusCode;

  @JsonKey(name: 'status_message')
  final String statusMessage;

  SummaryResponse({
    required this.statusCode,
    required this.statusMessage,
  });

  factory SummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$SummaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SummaryResponseToJson(this);
}

@JsonSerializable()
class SummaryResult {
  @JsonKey(name: 'summary_status')
  final String summaryStatus; // completed, running, fail

  SummaryResult({
    required this.summaryStatus,
  });

  factory SummaryResult.fromJson(Map<String, dynamic> json) =>
      _$SummaryResultFromJson(json);

  Map<String, dynamic> toJson() => _$SummaryResultToJson(this);

  bool get isCompleted => summaryStatus == 'completed';
  bool get isRunning => summaryStatus == 'running';
  bool get isFailed => summaryStatus == 'fail';
}
