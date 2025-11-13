// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AudioRecord _$AudioRecordFromJson(Map<String, dynamic> json) => AudioRecord(
      audioRecordId: json['audio_record_id'] as String,
      audioUri: json['audio_uri'] as String,
      recordTs: (json['record_ts'] as num).toInt(),
      statusCode: (json['status_code'] as num).toInt(),
      statusMessage: json['status_message'] as String,
    );

Map<String, dynamic> _$AudioRecordToJson(AudioRecord instance) =>
    <String, dynamic>{
      'audio_record_id': instance.audioRecordId,
      'audio_uri': instance.audioUri,
      'record_ts': instance.recordTs,
      'status_code': instance.statusCode,
      'status_message': instance.statusMessage,
    };
