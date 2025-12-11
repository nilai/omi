// AI-generated START - 设置页面状态管理Provider
import 'package:flutter/material.dart';

/// 设置页面状态管理Provider
/// 管理用户资料数据
class SettingsProvider with ChangeNotifier {
  // AI-generated START - 是否正在加载
  final bool _isLoading = false;
  // AI-generated END - _isLoading

  // AI-generated START - 错误信息
  String? _error;
  // AI-generated END - _error

  // AI-generated START - 获取是否正在加载
  bool get isLoading => _isLoading;
  // AI-generated END - isLoading

  // AI-generated START - 获取错误信息
  String? get error => _error;
  // AI-generated END - error
}
// AI-generated END - settings_provider.dart
