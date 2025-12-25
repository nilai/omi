// AI-generated START - 录音详情更多操作弹窗组件
import 'package:flutter/material.dart';

/// 更多操作选项枚举
enum MPRecordDetailMoreAction {
  /// 重命名记忆
  renameMemory,

  /// 添加标签
  addTag,

  /// 导出
  export,

  /// 复制转录
  copyTranscript,

  /// 复制摘要
  copySummary,

  /// 重新生成摘要
  regenerateSummary,

  /// 删除记忆
  deleteMemory,
}

/// 更多操作选项枚举扩展
extension MPRecordDetailMoreActionExtension on MPRecordDetailMoreAction {
  /// 获取选项标题（英文）
  String get title {
    switch (this) {
      case MPRecordDetailMoreAction.renameMemory:
        return 'Rename Memory';
      case MPRecordDetailMoreAction.addTag:
        return 'Add Tag';
      case MPRecordDetailMoreAction.export:
        return 'Export';
      case MPRecordDetailMoreAction.copyTranscript:
        return 'Copy Transcript';
      case MPRecordDetailMoreAction.copySummary:
        return 'Copy Summary';
      case MPRecordDetailMoreAction.regenerateSummary:
        return 'Regenerate Summary';
      case MPRecordDetailMoreAction.deleteMemory:
        return 'Delete Memory';
    }
  }

  /// 获取选项图标
  IconData get icon {
    switch (this) {
      case MPRecordDetailMoreAction.renameMemory:
        return Icons.edit_outlined;
      case MPRecordDetailMoreAction.addTag:
        return Icons.label_outline;
      case MPRecordDetailMoreAction.export:
        return Icons.download_outlined;
      case MPRecordDetailMoreAction.copyTranscript:
        return Icons.content_copy_outlined;
      case MPRecordDetailMoreAction.copySummary:
        return Icons.description_outlined;
      case MPRecordDetailMoreAction.regenerateSummary:
        return Icons.refresh_outlined;
      case MPRecordDetailMoreAction.deleteMemory:
        return Icons.delete_outline;
    }
  }

  /// 获取图标颜色
  Color get iconColor {
    switch (this) {
      case MPRecordDetailMoreAction.renameMemory:
        return const Color(0xFF3B82F6); // 蓝色
      case MPRecordDetailMoreAction.addTag:
        return const Color(0xFF9333EA); // 紫色
      case MPRecordDetailMoreAction.export:
        return const Color(0xFF9333EA); // 紫色
      case MPRecordDetailMoreAction.copyTranscript:
        return const Color(0xFF10B981); // 绿色
      case MPRecordDetailMoreAction.copySummary:
        return const Color(0xFF10B981); // 绿色
      case MPRecordDetailMoreAction.regenerateSummary:
        return const Color(0xFFF97316); // 橙色
      case MPRecordDetailMoreAction.deleteMemory:
        return const Color(0xFFEF4444); // 红色
    }
  }
}

/// 录音详情更多操作弹窗组件
class MPRecordDetailMorePopup extends StatelessWidget {
  /// 构造函数
  const MPRecordDetailMorePopup({
    super.key,
    required this.title,
    required this.actions,
    this.onActionSelected,
  });

  /// 弹窗标题
  final String title;

  /// 需要显示的操作选项列表
  final List<MPRecordDetailMoreAction> actions;

  /// 操作选项选中回调
  final ValueChanged<MPRecordDetailMoreAction>? onActionSelected;

  /// 显示弹窗
  static Future<MPRecordDetailMoreAction?> show({
    required BuildContext context,
    String title = 'More Actions',
    required List<MPRecordDetailMoreAction> actions,
    ValueChanged<MPRecordDetailMoreAction>? onActionSelected,
  }) {
    return showModalBottomSheet<MPRecordDetailMoreAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return MPRecordDetailMorePopup(
          title: title,
          actions: actions,
          onActionSelected: onActionSelected,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.9;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AI-generated START - 顶部标题栏
          _buildHeader(context),
          // AI-generated END - 顶部标题栏

          // AI-generated START - 操作选项列表
          Flexible(
            child: _buildActionList(),
          ),
          // AI-generated END - 操作选项列表
        ],
      ),
    );
  }

  /// 构建顶部标题栏
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // AI-generated START - 标题
          Text(
            title,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          // AI-generated END - 标题

          // AI-generated START - 关闭按钮
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            color: const Color(0xFF6B7280),
            iconSize: 24.0,
          ),
          // AI-generated END - 关闭按钮
        ],
      ),
    );
  }

  /// 构建操作选项列表
  Widget _buildActionList() {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionItem(context, action);
      },
    );
  }

  /// 构建单个操作选项项
  Widget _buildActionItem(BuildContext context, MPRecordDetailMoreAction action) {
    return InkWell(
      onTap: () {
        onActionSelected?.call(action);
        // 关闭弹窗并返回选中的操作
        Navigator.of(context).pop(action);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), // 浅灰色背景
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            // AI-generated START - 图标（白色圆形背景）
            Container(
              width: 40.0,
              height: 40.0,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                action.icon,
                color: action.iconColor,
                size: 20.0,
              ),
            ),
            // AI-generated END - 图标

            // AI-generated START - 标题
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                action.title,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF212121),
                ),
              ),
            ),
            // AI-generated END - 标题
          ],
        ),
      ),
    );
  }
}
// AI-generated END - mp_record_detail_more_popup.dart
