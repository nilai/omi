import 'dart:io';

import 'package:flutter/material.dart';
import 'package:omi/backend/schema/schema.dart';
import 'package:omi/services/audio_record_service.dart';

/// 录音上传状态管理
///
/// 负责管理录音上传的状态、进度和错误信息
class AudioRecordProvider extends ChangeNotifier {
  final AudioRecordService _audioRecordService = AudioRecordService();

  // 状态管理
  bool _isUploading = false;
  String? _errorMessage;
  int _currentStep = 0;
  int _totalSteps = 3;

  // 录音列表（预留，目前不实现加载功能）
  final List<AudioRecord> _audioRecords = [];

  // Getters
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  int get currentStep => _currentStep;
  int get totalSteps => _totalSteps;
  List<AudioRecord> get audioRecords => _audioRecords;

  /// 上传进度百分比 (0.0 - 1.0)
  double get uploadProgress {
    if (_totalSteps == 0) return 0.0;
    return _currentStep / _totalSteps;
  }

  /// 上传音频文件
  ///
  /// [audioFile] 要上传的音频文件
  ///
  /// 返回 true 表示上传成功，false 表示失败
  Future<bool> uploadAudio(File audioFile) async {
    // 重置状态
    _isUploading = true;
    _errorMessage = null;
    _currentStep = 0;
    notifyListeners();

    try {
      // 验证文件
      final isValid = await _audioRecordService.validateAudioFile(audioFile);
      if (!isValid) {
        _errorMessage = '音频文件无效或不支持该格式';
        _isUploading = false;
        notifyListeners();
        return false;
      }

      // 执行上传
      final audioRecord = await _audioRecordService.uploadAudioRecord(
        audioFile,
        onProgress: (current, total) {
          _currentStep = current;
          _totalSteps = total;
          notifyListeners();
        },
      );

      if (audioRecord != null && audioRecord.isSuccess) {
        // 上传成功
        _audioRecords.add(audioRecord);
        _currentStep = _totalSteps;
        _isUploading = false;
        notifyListeners();
        debugPrint('AudioRecordProvider: upload successful, ID: ${audioRecord.audioRecordId}');
        return true;
      } else {
        // 上传失败
        _errorMessage = audioRecord?.statusMessage ?? '上传失败，请重试';
        _isUploading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // 发生异常
      _errorMessage = '上传过程中发生错误: ${e.toString()}';
      _isUploading = false;
      notifyListeners();
      debugPrint('AudioRecordProvider: upload exception: $e');
      return false;
    }
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 重置上传状态
  void reset() {
    _isUploading = false;
    _errorMessage = null;
    _currentStep = 0;
    notifyListeners();
  }

  /// 获取最近上传的录音
  AudioRecord? get lastUploadedRecord {
    if (_audioRecords.isEmpty) return null;
    return _audioRecords.last;
  }

  /// 添加已上传的录音到列表
  ///
  /// 用于从其他来源添加录音记录（如从服务器加载）
  void addAudioRecord(AudioRecord record) {
    _audioRecords.add(record);
    notifyListeners();
  }

  /// 清空录音列表
  void clearAudioRecords() {
    _audioRecords.clear();
    notifyListeners();
  }

  // TODO: 未来可以实现的功能
  // Future<void> loadAudioRecords() async {
  //   // 从服务器加载录音列表
  // }
  //
  // Future<void> deleteAudioRecord(String recordId) async {
  //   // 删除指定的录音记录
  // }
}
