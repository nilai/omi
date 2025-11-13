import 'package:json_annotation/json_annotation.dart';

part 'audio_record.g.dart';

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
