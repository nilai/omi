import 'package:flutter/material.dart';
import 'package:memo_pin/common/omi_add_todo_popup.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';

/// AI 建议 follow-up 单条状态
enum MPMemoryActionItemStatus {
  /// 可点击「Create Todo」
  pending,

  /// 已创建，按钮展示「Todo Created」，**不可点击**
  created,
}

/// 单条 follow-up 数据
class MPMemoryActionItemData {
  /// {@template MPMemoryActionItemData}
  /// [title]：任务描述文案
  /// [status]：[MPMemoryActionItemStatus.pending] 显示可点的 Create Todo；
  /// [MPMemoryActionItemStatus.created] 显示已完成态且不可点。
  /// {@endtemplate}
  const MPMemoryActionItemData({
    this.id,
    this.title,
    this.status,
    this.deadline,
    this.priority,

  });

  /// 与接口 [MPTodoStruct.id] 一致。
  final String? id;

  final String? title;

  final MPMemoryActionItemStatus? status;

  final int? deadline;

  final String? priority;

  MPMemoryActionItemData copyWith({
    String? id,
    String? title,
    MPMemoryActionItemStatus? status,
  }) {
    return MPMemoryActionItemData(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
    );
  }
}

/// Actions 分段：标题 + **固定高度**可滑动列表（每条为圆角描边卡片 + 底部操作钮）
class MPMemoryActionContent extends StatelessWidget {
  /// {@template MPMemoryActionContent}
  /// - [items]：列表数据（示例为 3 条：1 条已创建 + 2 条待创建）
  /// - [height]：列表可视高度，默认 `300`，超出可滑动
  /// - [onCreateTodo]：用户在 [showMPAddTodoPopup] 中点击 **Save** 后回调（带下标与表单结果）
  /// - [onActionContextTap]：弹窗内 CONTEXT 卡片点击（可选）
  /// {@endtemplate}
  const MPMemoryActionContent({
    super.key,
    required this.items,
    this.height = 300,
    this.scrollWithParent = false,
    this.useMemoStyle = false,
    this.headerTitle = 'Possible follow-ups (suggested by AI)',
    this.padding,
    this.onCreateTodo,
    this.onActionContextTap,
  });

  final List<MPMemoryActionItemData> items;

  /// 列表区域高度（固定）
  final double height;
  final bool scrollWithParent;
  final bool useMemoStyle;

  /// 顶部说明标题
  final String headerTitle;

  final EdgeInsetsGeometry? padding;

  /// 弹窗保存成功后的回调（可 `await` 调接口），`index` 对应 [items]
  final Future<void> Function(int index, MPAddTodoPopupResult result)?
  onCreateTodo;

  /// 弹窗内「From memory」区域点击
  final VoidCallback? onActionContextTap;

  @override
  Widget build(BuildContext context) {
    final List<Widget> actionCards = List<Widget>.generate(items.length, (
      int index,
    ) {
      final MPMemoryActionItemData item = items[index];
      final bool isLast = index == items.length - 1;
      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
        child: _MPMemoryActionCard(
          data: item,
          useMemoStyle: useMemoStyle,
          onCreateTodo: item.status == MPMemoryActionItemStatus.pending
              ? () => _openCreateTodoPopup(context, index: index, item: item)
              : null,
        ),
      );
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          headerTitle,
          style: OmiTextStyle.create(
            fontSize: OmiFontSize.t4_13,
            fontWeight: OmiFontWeight.medium,
            color: useMemoStyle
                ? const Color(0xFF8E8E93)
                : Colors.white.withValues(alpha: 0.72),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        if (scrollWithParent)
          Padding(
            padding: padding ?? EdgeInsets.zero,
            child: Column(children: actionCards),
          )
        else
          SizedBox(
            height: height,
            child: ClipRect(
              child: ListView(
                padding: padding ?? EdgeInsets.zero,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: actionCards,
              ),
            ),
          ),
      ],
    );
  }

  /// 打开 [showMPAddTodoPopup]，预填当前条 [MPMemoryActionItemData.title]
  Future<void> _openCreateTodoPopup(
    BuildContext context, {
    required int index,
    required MPMemoryActionItemData item,
  }) async {
    final MPAddTodoPopupResult? result = await showMPAddTodoPopup(
      context,
      params: MPAddTodoPopupParams(initialTitle: item.title ?? ''),
      onContextTap: onActionContextTap,
    );
    if (!context.mounted || result == null) {
      return;
    }
    if (onCreateTodo != null) {
      await onCreateTodo!(index, result);
    }
  }
}

/// 单条 follow-up 卡片（圆角 + 0.5 描边，子组件按圆角裁切）
class _MPMemoryActionCard extends StatelessWidget {
  const _MPMemoryActionCard({
    required this.data,
    required this.useMemoStyle,
    this.onCreateTodo,
  });

  final MPMemoryActionItemData data;
  final bool useMemoStyle;

  /// 仅 pending 时非空
  final VoidCallback? onCreateTodo;

  static const Color _kCreatedBtn = Color(0xFF4FA06B);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: useMemoStyle
            ? const Color(0xFFF5F5F7)
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: useMemoStyle
              ? const Color(0xFFE5E5EA)
              : Colors.white.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            data.title ?? '',
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t4_13,
              fontWeight: OmiFontWeight.medium,
              color: useMemoStyle
                  ? const Color(0xFF1C1C1E)
                  : Colors.white.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          if (data.status == MPMemoryActionItemStatus.created)
            _MPActionPillButton(
              label: 'Todo Created',
              icon: Assets.omiMemoryDetailCheck,
              filledColor: useMemoStyle ? null : _kCreatedBtn,
              useMemoStyle: useMemoStyle,
              onPressed: null,
            )
          else
            _MPActionPillButton(
              label: 'Create Todo',
              icon: Assets.omiPlus,
              filledColor: null,
              useMemoStyle: useMemoStyle,
              onPressed: onCreateTodo,
            ),
        ],
      ),
    );
  }
}

/// 底部药丸按钮：已完成态无点击；待办态可点
class _MPActionPillButton extends StatelessWidget {
  const _MPActionPillButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.useMemoStyle,
    this.filledColor,
  });

  final String label;

  final String icon;

  final VoidCallback? onPressed;
  final bool useMemoStyle;

  /// 非空为实心强调（Todo Created）；空为半透明底（Create Todo）
  final Color? filledColor;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            filledColor ??
            (useMemoStyle
                ? (enabled ? Colors.white : Colors.transparent)
                : Colors.white.withValues(alpha: enabled ? 0.14 : 0.1)),
        borderRadius: BorderRadius.circular(999),
        border: useMemoStyle && enabled
            ? Border.all(color: const Color(0xFFE5E5EA), width: 0.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          OmiImageLoader.localImg(
            icon,
            width: 18,
            height: 18,
            color: useMemoStyle
                ? const Color(0xFF6BBF8E)
                : Colors.white.withValues(alpha: 0.95),
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t3_12,
              fontWeight: OmiFontWeight.medium,
              color: useMemoStyle
                  ? const Color(0xFF6BBF8E)
                  : Colors.white.withValues(alpha: 0.95),
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    if (!enabled) {
      return Align(alignment: Alignment.centerLeft, child: child);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: child,
        ),
      ),
    );
  }
}

