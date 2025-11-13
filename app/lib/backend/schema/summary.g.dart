// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SummaryRequest _$SummaryRequestFromJson(Map<String, dynamic> json) =>
    SummaryRequest(
      audioRecordId: json['audio_record_id'] as String,
    );

Map<String, dynamic> _$SummaryRequestToJson(SummaryRequest instance) =>
    <String, dynamic>{
      'audio_record_id': instance.audioRecordId,
    };

SummaryResponse _$SummaryResponseFromJson(Map<String, dynamic> json) =>
    SummaryResponse(
      statusCode: (json['status_code'] as num).toInt(),
      statusMessage: json['status_message'] as String,
    );

Map<String, dynamic> _$SummaryResponseToJson(SummaryResponse instance) =>
    <String, dynamic>{
      'status_code': instance.statusCode,
      'status_message': instance.statusMessage,
    };

SummaryResult _$SummaryResultFromJson(Map<String, dynamic> json) =>
    SummaryResult(
      summaryStatus: json['summary_status'] as String,
    );

Map<String, dynamic> _$SummaryResultToJson(SummaryResult instance) =>
    <String, dynamic>{
      'summary_status': instance.summaryStatus,
    };
