import 'package:flutter/material.dart';
import 'package:memo_pin/http/schema/mp_data_model.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_font_utils.dart';
import '../../../../../utils/omi_textstyle.dart';
import '../../../detail/memory/mp_memo_detail_sheet.dart';

/// Memos 分组卡片展示形态（对应设计稿）
enum MPMemoGroupCardVariant {
  /// 仅 1 条：标题区 `1 item`，正文一条可省略号
  single,

  /// 列表展示（当条目 > 3 时自动折叠）
  listFull,
}

/// Memos 分组卡片数据
class MPMemoGroupCardData {
  const MPMemoGroupCardData({
    required this.title,
    required this.items,
    this.itemMuted,
    this.subtitle,
  });

  /// 分类名，如 `Memos`
  final String title;


  /// 备忘条目（完整列表；折叠时由组件截取前 N 条）
  final List<MPMemoStruct> items;

  /// 与 [items] 等长；`true` 表示该行用灰色弱化（如已读）
  final List<bool>? itemMuted;

  /// 标题行右侧文案（与「N items」同一位置）；为 `null` 或空串时用默认的 `1 item` / `n items`。
  final String? subtitle;
}

/// 设计色
const Color _kMemoBody = Color(0xFF1A1A1A);
const Color _kMemoMuted = Color(0xFF9E9E9E);
const Color _kMemoBorder = Color(0xFFE8E8E6);

/// Memos 分组卡片：标题行（图标 + Memos · 日期 + N items）+ 列表 + 可选展开底栏
class MPMemoGroupCard extends StatefulWidget {
  const MPMemoGroupCard({
    super.key,
    required this.variant,
    required this.data,
    this.onTap,
    this.onExpandChanged,
  });

  final MPMemoGroupCardVariant variant;
  final MPMemoGroupCardData data;
  final VoidCallback? onTap;

  /// 折叠展开切换时回调（可选）
  final ValueChanged<bool>? onExpandChanged;

  @override
  State<MPMemoGroupCard> createState() => _MPMemoGroupCardState();
}

class _MPMemoGroupCardState extends State<MPMemoGroupCard> {
  static const int _kCollapsedPreviewCount = 3;

  bool _expanded = false;

  int get _total => widget.data.items.length;

  String get _headerCountLabel {
    final String? sub = widget.data.subtitle?.trim();
    if (sub != null && sub.isNotEmpty) {
      return sub;
    }
    return '';
  }

  bool get _needsCollapse => _total > _kCollapsedPreviewCount;

  int get _visibleCount {
    if (widget.variant == MPMemoGroupCardVariant.single ||
        widget.variant == MPMemoGroupCardVariant.listFull) {
      return _total;
    }
    if (!_needsCollapse) return _total;
    if (_expanded) return _total;
    return _kCollapsedPreviewCount.clamp(0, _total);
  }

  int get _moreCount => (_total - _kCollapsedPreviewCount).clamp(0, _total);

  void _openMemoDetailSheet(BuildContext context, MPMemoStruct memo) {
 
    showMPMemoDetailSheet(
      context,
      variant: MPMemoDetailSheetVariant.manual,
      memoId: memo.id.trim().isEmpty ? null : memo.id,
      manualMemoText: memo.content,
      linkedMemoryText: memo.title,
      onAnalyze: (String memoText) async {
        // TODO: 替换真实 analyze 接口
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final String first = memoText.trim();
        return <String>[first];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final MPMemoGroupCardData d = widget.data;
    final bool showFooter = _needsCollapse;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kMemoBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderRow(
            title: d.title,
            countLabel: _headerCountLabel,
          ),
          const SizedBox(height: 12),
          ...List<Widget>.generate(_visibleCount, (int i) {
            final bool muted = d.itemMuted != null &&
                i < d.itemMuted!.length &&
                d.itemMuted![i];
            final MPMemoStruct memo = d.items[i];
            return Padding(
              padding: EdgeInsets.only(
                bottom: i < _visibleCount - 1 ? 8 : 8,
              ),
              child: _BulletLine(
                text: memo.title.trim().isNotEmpty
                    ? memo.title.trim()
                    : memo.content.trim(),
                maxLines: widget.variant == MPMemoGroupCardVariant.single
                    ? 1
                    : null,
                muted: muted,
                onTap: () => _openMemoDetailSheet(context, memo),
              ),
            );
          }),
          if (showFooter) ...[
            const SizedBox(height: 4),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 8),
            _ExpandFooter(
              expanded: _expanded,
              moreCount: _moreCount,
              onToggle: () {
                setState(() {
                  _expanded = !_expanded;
                });
                widget.onExpandChanged?.call(_expanded);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.title, required this.countLabel});

  final String title;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: OmiImageLoader.localImg(
            Assets.omiBookText,
            width: 18,
            height: 18,
            color: orangeTextColor,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            style: OmiTextStyle.create(
              fontSize: 16,
              fontWeight: OmiFontWeight.medium,
              color: mainTextColor,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          countLabel,
          style: OmiTextStyle.create(fontSize: 13, color: secondTextColor),
        ),
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({
    required this.text,
    this.maxLines,
    this.muted = false,
    this.onTap,
  });

  final String text;
  final int? maxLines;
  final bool muted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: muted ? _kMemoMuted : _kMemoBody,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            softWrap: maxLines != 1,
            overflow: maxLines == 1
                ? TextOverflow.ellipsis
                : TextOverflow.visible,
            style: OmiTextStyle.create(
              fontSize: 13,
              height: 1.35,
              color: muted ? _kMemoMuted : _kMemoBody,
              fontWeight: OmiFontWeight.medium,
            ),
          ),
        ),
      ],
    );

    if (onTap == null) {
      return row;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: row,
        ),
      ),
    );
  }
}

class _ExpandFooter extends StatelessWidget {
  const _ExpandFooter({
    required this.expanded,
    required this.moreCount,
    required this.onToggle,
  });

  final bool expanded;
  final int moreCount;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            OmiImageLoader.localImg(
              expanded ? Assets.omiArrowUp : Assets.omiArrowDown,
              color: blueTextColor,
              width: 14,
              height: 14,
            ),
            const SizedBox(width: 4),
            Text(
              expanded ? 'Show less' : '+ $moreCount more',
              style: OmiTextStyle.create(
                fontSize: 13,
                fontWeight: OmiFontWeight.medium,
                color: blueTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
