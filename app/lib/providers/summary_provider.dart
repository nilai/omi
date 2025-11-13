import 'dart:async';
import 'package:flutter/material.dart';
import 'package:omi/backend/http/api/summary.dart';
import 'package:omi/backend/schema/summary.dart';
import 'package:omi/providers/base_provider.dart';

enum SummaryTaskStatus {
  idle,
  generating,
  polling,
  completed,
  failed,
  timeout,
}

class SummaryProvider extends BaseProvider {
  String? _currentAudioRecordId;
  SummaryTaskStatus _status = SummaryTaskStatus.idle;
  SummaryResult? _result;
  String? _errorMessage;
  Timer? _pollingTimer;
  int _pollingCount = 0;
  static const int _maxPollingCount = 60; // 5 seconds * 60 = 5 minutes
  static const Duration _pollingInterval = Duration(seconds: 5);

  // Getters
  SummaryTaskStatus get status => _status;
  SummaryResult? get result => _result;
  String? get errorMessage => _errorMessage;
  String? get currentAudioRecordId => _currentAudioRecordId;
  int get pollingCount => _pollingCount;
  int get maxPollingCount => _maxPollingCount;
  int get remainingSeconds => (_maxPollingCount - _pollingCount) * 5;

  /// Start a new summary task
  Future<bool> startSummaryTask(String audioRecordId) async {
    // Reset state
    _currentAudioRecordId = audioRecordId;
    _status = SummaryTaskStatus.generating;
    _result = null;
    _errorMessage = null;
    _pollingCount = 0;
    notifyListeners();

    try {
      // Step 1: Generate summary
      final response = await generateSummary(audioRecordId);

      if (response == null) {
        _status = SummaryTaskStatus.failed;
        _errorMessage = 'Failed to start summary task: No response';
        notifyListeners();
        return false;
      }

      if (response.statusCode != 0) {
        _status = SummaryTaskStatus.failed;
        _errorMessage = 'Failed to start summary task: ${response.statusMessage}';
        notifyListeners();
        return false;
      }

      // Step 2: Start polling for result
      _status = SummaryTaskStatus.polling;
      notifyListeners();
      _startPolling();

      return true;
    } catch (e) {
      _status = SummaryTaskStatus.failed;
      _errorMessage = 'Exception: $e';
      notifyListeners();
      return false;
    }
  }

  /// Start polling for summary result
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) async {
      await _checkSummaryStatus();
    });
  }

  /// Check summary status
  Future<void> _checkSummaryStatus() async {
    if (_currentAudioRecordId == null) {
      stopPolling();
      return;
    }

    _pollingCount++;
    notifyListeners();

    try {
      final result = await getSummaryResult(_currentAudioRecordId!);

      if (result == null) {
        debugPrint('Failed to get summary result');
        return;
      }

      _result = result;

      // Check if task is completed or failed
      if (result.isCompleted) {
        _status = SummaryTaskStatus.completed;
        stopPolling();
        notifyListeners();
        return;
      }

      if (result.isFailed) {
        _status = SummaryTaskStatus.failed;
        _errorMessage = 'Summary task failed';
        stopPolling();
        notifyListeners();
        return;
      }

      // Check if reached max polling count
      if (_pollingCount >= _maxPollingCount) {
        _status = SummaryTaskStatus.timeout;
        _errorMessage = 'Polling timeout after ${_maxPollingCount * 5} seconds';
        stopPolling();
        notifyListeners();
        return;
      }

      // Still running, continue polling
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking summary status: $e');
      _errorMessage = 'Error: $e';
      notifyListeners();
    }
  }

  /// Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    notifyListeners();
  }

  /// Reset to initial state
  void reset() {
    stopPolling();
    _currentAudioRecordId = null;
    _status = SummaryTaskStatus.idle;
    _result = null;
    _errorMessage = null;
    _pollingCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
