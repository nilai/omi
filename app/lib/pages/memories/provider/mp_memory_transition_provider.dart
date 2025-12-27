import 'dart:async';
import 'package:flutter/material.dart';
import '../../../providers/base_provider.dart';

/// 记忆转换状态枚举
enum MPMemoryTransitionStatus {
  /// 空闲状态
  idle,
  /// 生成中
  generating,
  /// 已完成
  completed,
  /// 失败
  failed,
}

/// 记忆转换页面Provider
/// 负责管理记忆转换状态，定期轮询状态接口
/// 
/// 使用方式：
/// ```dart
/// final provider = MPMemoryTransitionProvider(
///   statusGetter: () async {
///     // 调用API获取状态
///     final status = await getStatus();
///     return status == 'completed' ? MPMemoryTransitionStatus.completed : null;
///   },
/// );
/// provider.startPolling();
/// ```
class MPMemoryTransitionProvider extends BaseProvider {
  MPMemoryTransitionStatus _status = MPMemoryTransitionStatus.idle;
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 5);

  /// 状态获取函数，返回期望的状态（如 completed）表示完成
  /// 返回 null 表示继续轮询
  final Future<MPMemoryTransitionStatus?> Function()? _statusGetter;

  /// 期望的完成状态，默认为 completed
  final MPMemoryTransitionStatus _expectedStatus;

  /// 错误信息
  String? _errorMessage;

  MPMemoryTransitionProvider({
    Future<MPMemoryTransitionStatus?> Function()? statusGetter,
    MPMemoryTransitionStatus expectedStatus = MPMemoryTransitionStatus.completed,
  })  : _statusGetter = statusGetter,
        _expectedStatus = expectedStatus;

  /// 当前状态
  MPMemoryTransitionStatus get status => _status;

  /// 错误信息
  String? get errorMessage => _errorMessage;

  /// 是否正在生成中
  bool get isGenerating => _status == MPMemoryTransitionStatus.generating;

  /// 是否已完成
  bool get isCompleted => _status == MPMemoryTransitionStatus.completed;

  /// 是否失败
  bool get isFailed => _status == MPMemoryTransitionStatus.failed;

  /// 开始轮询状态
  /// 
  /// @param {Future<MPMemoryTransitionStatus?> Function()?} statusGetter - 状态获取函数，如果为null则使用初始化时传入的函数
  /// @returns {Future<void>} 无返回值
  Future<void> startPolling([Future<MPMemoryTransitionStatus?> Function()? statusGetter]) async {
    final getter = statusGetter ?? _statusGetter;
    if (getter == null) {
      debugPrint('MPMemoryTransitionProvider: statusGetter is null');
      return;
    }

    // 停止之前的轮询
    stopPolling();

    // 设置为生成中状态
    _status = MPMemoryTransitionStatus.generating;
    _errorMessage = null;
    notifyListeners();

    // 立即执行一次检查
    await _checkStatus(getter);

    // 开始定时轮询
    _pollingTimer = Timer.periodic(_pollingInterval, (_) async {
      await _checkStatus(getter);
    });
  }

  /// 检查状态
  /// 
  /// @param {Future<MPMemoryTransitionStatus?> Function()} statusGetter - 状态获取函数
  /// @returns {Future<void>} 无返回值
  /// @private
  Future<void> _checkStatus(Future<MPMemoryTransitionStatus?> Function() statusGetter) async {
    try {
      final result = await statusGetter();

      if (result == null) {
        // 返回null表示继续轮询，不更新状态
        return;
      }

      // 如果获取到期望的状态，表示完成
      if (result == _expectedStatus) {
        _status = MPMemoryTransitionStatus.completed;
        stopPolling();
        notifyListeners();
        return;
      }

      // 如果获取到失败状态
      if (result == MPMemoryTransitionStatus.failed) {
        _status = MPMemoryTransitionStatus.failed;
        _errorMessage = '生成失败';
        stopPolling();
        notifyListeners();
        return;
      }

      // 其他状态继续轮询，保持generating状态
    } catch (e) {
      debugPrint('MPMemoryTransitionProvider: Error checking status: $e');
      // 发生错误时不停止轮询，继续尝试
    }
  }

  /// 停止轮询
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// 重置状态
  void reset() {
    stopPolling();
    _status = MPMemoryTransitionStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

