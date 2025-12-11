// AI-generated START - 设置页面状态管理Provider
import 'package:flutter/material.dart';
import 'package:omi/backend/http/mp_api/mp_speaker.dart';
import 'package:omi/backend/schema/mp/mp_speaker.dart';

/// 设置页面状态管理Provider
/// 管理用户资料数据和 speaker 列表
class SettingsProvider with ChangeNotifier {
  // AI-generated START - 是否正在加载
  final bool _isLoading = false;
  // AI-generated END - _isLoading

  // AI-generated START - 错误信息
  String? _error;
  // AI-generated END - _error

  // AI-generated START - Speaker 头像列表
  List<String> _friendAvatars = [];
  // AI-generated END - _friendAvatars

  // AI-generated START - 是否正在加载 speaker 列表
  bool _isLoadingSpeakers = false;
  // AI-generated END - _isLoadingSpeakers

  // AI-generated START - 获取是否正在加载
  bool get isLoading => _isLoading;
  // AI-generated END - isLoading

  // AI-generated START - 获取错误信息
  String? get error => _error;
  // AI-generated END - error

  // AI-generated START - 获取 friend avatars
  List<String> get friendAvatars => _friendAvatars;
  // AI-generated END - friendAvatars

  // AI-generated START - 获取是否正在加载 speaker 列表
  bool get isLoadingSpeakers => _isLoadingSpeakers;
  // AI-generated END - isLoadingSpeakers

  // AI-generated START - 从接口加载 speaker 列表
  Future<void> loadSpeakerList() async {
    if (_isLoadingSpeakers) return;

    _isLoadingSpeakers = true;
    notifyListeners();

    try {
      final request = MPGetSpeakerListRequest(
        pageSize: 10, // 获取前10个 speaker
        cursor: '', // 从第一页开始
      );
      final response = await getSpeakerList(request);

      if (response != null && response.speakers.isNotEmpty) {
        // 提取所有 speaker 的 avatar URL
        _friendAvatars =
            response.speakers.where((speaker) => speaker.avatar.isNotEmpty).map((speaker) => speaker.avatar).toList();
      }
    } catch (e) {
      debugPrint('Failed to load speaker list: $e');
      _error = 'Failed to load speaker list: $e';
    } finally {
      _isLoadingSpeakers = false;
      notifyListeners();
    }
  }
  // AI-generated END - 从接口加载 speaker 列表
}
// AI-generated END - settings_provider.dart
