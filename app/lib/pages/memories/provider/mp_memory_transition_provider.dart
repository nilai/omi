import 'dart:async';
import 'package:flutter/material.dart';
import '../../../providers/base_provider.dart';
import '../../../backend/http/mp_api/mp_memory.dart';
import '../../../backend/schema/mp/mp_memory.dart';

/// 记忆转换页面Provider
/// 负责管理记忆转换状态，定期轮询状态接口
///
/// 使用方式：
/// ```dart
/// final provider = MPMemoryTransitionProvider(
///   memoryId: 'memory_id_123',
/// );
/// provider.startPolling();
/// ```
class MPMemoryTransitionProvider extends BaseProvider {
  /// 记忆ID
  final String memoryId;

  /// 是否正在生成中
  bool _isGenerating = false;

  /// 是否已完成
  bool _isCompleted = false;

  /// 错误信息
  String? _errorMessage;

  /// 完成回调
  VoidCallback? completeCallback;

  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 5);

  MPMemoryTransitionProvider({
    required this.memoryId,
    this.completeCallback
  });

  /// 是否正在生成中
  bool get isGenerating => _isGenerating;

  /// 是否已完成
  bool get isCompleted => _isCompleted;

  /// 错误信息
  String? get errorMessage => _errorMessage;

  /// 开始轮询状态
  ///
  /// @returns {Future<void>} 无返回值
  Future<void> startPolling() async {
    // 停止之前的轮询
    stopPolling();

    // 设置为生成中状态
    _isGenerating = true;
    _isCompleted = false;
    _errorMessage = null;
    notifyListeners();

    // 立即执行一次检查
    await _checkStatus();

    // 开始定时轮询
    _pollingTimer = Timer.periodic(_pollingInterval, (_) async {
      await _checkStatus();
    });
  }

  /// 检查状态
  ///
  /// @returns {Future<void>} 无返回值
  /// @private
  Future<void> _checkStatus() async {
    try {
      final res = await getSummaryStatus(MPGetSummaryStatusRequest(memoryId: memoryId));

      if (res == null) {
        debugPrint('MPMemoryTransitionProvider: getSummaryStatus returned null');
        return;
      }

      if (res.baseResp.code != 0) {
        debugPrint('MPMemoryTransitionProvider: API error: ${res.baseResp.message}');
        return;
      }

      // 状态为 2 表示结束轮询
      if (res.status == 2) {
        _isGenerating = false;
        _isCompleted = true;
        stopPolling();
        notifyListeners();
        completeCallback?.call();
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
    _isGenerating = false;
    _isCompleted = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
