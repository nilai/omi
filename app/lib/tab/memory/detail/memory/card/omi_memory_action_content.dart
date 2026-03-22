import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

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
    required this.title,
    required this.status,
  });

  final String title;

  final MPMemoryActionItemStatus status;
}

/// Actions 分段：标题 + **固定高度**可滑动列表（每条为圆角描边卡片 + 底部操作钮）
class MPMemoryActionContent extends StatelessWidget {
  /// {@template MPMemoryActionContent}
  /// - [items]：列表数据（示例为 3 条：1 条已创建 + 2 条待创建）
  /// - [height]：列表可视高度，默认 `300`，超出可滑动
  /// - [onCreateTodo]：仅 [MPMemoryActionItemStatus.pending] 的项会触发，参数为下标
  /// {@endtemplate}
  const MPMemoryActionContent({
    super.key,
    required this.items,
    this.height = 300,
    this.headerTitle = 'Possible follow-ups (suggested by AI)',
    this.padding,
    this.onCreateTodo,
  });

  final List<MPMemoryActionItemData> items;

  /// 列表区域高度（固定）
  final double height;

  /// 顶部说明标题
  final String headerTitle;

  final EdgeInsetsGeometry? padding;

  /// 点击「Create Todo」回调，`index` 对应 [items]
  final void Function(int index)? onCreateTodo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          headerTitle,
          style: OmiTextStyle.create(
            fontSize: OmiFontSize.t4_13,
            fontWeight: OmiFontWeight.medium,
            color: Colors.white.withValues(alpha: 0.72),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: ClipRect(
            child: ListView.builder(
              padding: padding ?? EdgeInsets.zero,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                final MPMemoryActionItemData item = items[index];
                final bool isLast = index == items.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: _MPMemoryActionCard(
                    data: item,
                    onCreateTodo: item.status == MPMemoryActionItemStatus.pending &&
                            onCreateTodo != null
                        ? () => onCreateTodo!(index)
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// 单条 follow-up 卡片（圆角 + 0.5 描边，子组件按圆角裁切）
class _MPMemoryActionCard extends StatelessWidget {
  const _MPMemoryActionCard({
    required this.data,
    this.onCreateTodo,
  });

  final MPMemoryActionItemData data;

  /// 仅 pending 时非空
  final VoidCallback? onCreateTodo;

  static const Color _kCreatedBtn = Color(0xFF4FA06B);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            data.title,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t4_13,
              fontWeight: OmiFontWeight.medium,
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          if (data.status == MPMemoryActionItemStatus.created)
            _MPActionPillButton(
              label: 'Todo Created',
              icon: Assets.omiMemoryDetailCheck,
              filledColor: _kCreatedBtn,
              onPressed: null,
            )
          else
            _MPActionPillButton(
              label: 'Create Todo',
              icon: Assets.omiPlus,
              filledColor: null,
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
    this.filledColor,
  });

  final String label;

  final String icon;

  final VoidCallback? onPressed;

  /// 非空为实心强调（Todo Created）；空为半透明底（Create Todo）
  final Color? filledColor;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: filledColor ??
            Colors.white.withValues(alpha: enabled ? 0.14 : 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          OmiImageLoader.localImg(
            icon,
            width: 18,
            height: 18,
            color: Colors.white.withValues(alpha: 0.95),
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t3_12,
              fontWeight: OmiFontWeight.medium,
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    if (!enabled) {
      return Align(
        alignment: Alignment.centerLeft,
        child: child,
      );
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

/// 与详情页示例一致的 3 条默认数据（1 已创建 + 2 待办）
List<MPMemoryActionItemData> mpMemoryActionSampleItems() {
  return const <MPMemoryActionItemData>[
    MPMemoryActionItemData(
      title: 'Review migration milestones with infrastructure team',
      status: MPMemoryActionItemStatus.created,
    ),
    MPMemoryActionItemData(
      title: 'Schedule authentication service testing session',
      status: MPMemoryActionItemStatus.pending,
    ),
    MPMemoryActionItemData(
      title: 'Document rollout risks and mitigation strategies',
      status: MPMemoryActionItemStatus.pending,
    ),
  ];
}
