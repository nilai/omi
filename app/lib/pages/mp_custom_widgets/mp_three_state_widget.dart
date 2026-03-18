// AI-generated START - 三态图组件
import 'package:flutter/material.dart';
import 'package:omi/pages/mp_custom_widgets/mp_skeleton_widget.dart';

/// 三态图状态枚举
enum MPThreeStateType {
  /// 加载中
  loading,
  /// 加载失败
  error,
  /// 空状态
  empty,
}

/// 三态图组件
/// 包含加载中、加载失败、空状态三种状态
class MPThreeStateWidget extends StatelessWidget {
  /// 状态类型
  final MPThreeStateType state;

  /// 错误信息（仅在 error 状态时使用）
  final String? errorMessage;

  /// 重试回调（仅在 error 状态时使用）
  final VoidCallback? onRetry;

  /// 空状态图标
  final IconData? emptyIcon;

  /// 空状态文本
  final String? emptyText;

  const MPThreeStateWidget({
    super.key,
    required this.state,
    this.errorMessage,
    this.onRetry,
    this.emptyIcon,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case MPThreeStateType.loading:
        return _buildLoadingState();
      case MPThreeStateType.error:
        return _buildErrorState();
      case MPThreeStateType.empty:
        return _buildEmptyState();
    }
  }

  /// 构建加载中状态
  Widget _buildLoadingState() {
    return Center(
      child: MPSkeletonList(
        itemCount: 3,
        itemHeight: 100.0,
        spacing: 12.0,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
      ),
    );
  }

  /// 构建加载失败状态
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? '加载失败',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('重试'),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            emptyIcon ?? Icons.memory_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            emptyText ?? '暂无数据',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
// AI-generated END - mp_three_state_widget.dart

