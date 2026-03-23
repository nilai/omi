import 'package:flutter/material.dart';

import 'package:omi/tab/memory/detail/memory/card/omi_memory_transcript_item.dart';

/// Transcript 分段内容：由多条 [MPMemoryTranscriptItem] 组成，**固定高度**内可滑动。
class MPMemoryTranscriptContent extends StatefulWidget {
  /// {@template MPMemoryTranscriptContent}
  /// - [height]：可视区域高度（逻辑像素），默认 `300`
  /// - [items]：列表数据；内容超出 [height] 时可上下滑动
  /// {@endtemplate}
  const MPMemoryTranscriptContent({
    super.key,
    required this.items,
    required this.playingIndex,
    required this.selectedIndex,
    required this.isPlaying,
    this.height = 300,
    this.scrollWithParent = false,
    this.useMemoStyle = false,
    this.padding,
    this.onItemEditTap,
    this.onItemPlayTap,
  });

  /// 每条 transcript 的数据
  final List<MPMemoryTranscriptItemData> items;
  final int? playingIndex;
  final int? selectedIndex;
  final bool isPlaying;

  /// 列表可视高度（固定）
  final double height;
  final bool scrollWithParent;
  final bool useMemoStyle;

  /// 外层内边距（默认左右与卡片对齐时可由父级控制，此处仅上下留 0）
  final EdgeInsetsGeometry? padding;

  /// 某条点击编辑，`index` 对应 [items] 下标
  final void Function(int index)? onItemEditTap;

  /// 某条点击播放/暂停，`index` 对应 [items] 下标
  final void Function(int index)? onItemPlayTap;

  @override
  State<MPMemoryTranscriptContent> createState() =>
      _MPMemoryTranscriptContentState();
}

class _MPMemoryTranscriptContentState extends State<MPMemoryTranscriptContent> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _itemKeys = <GlobalKey>[];

  @override
  void didUpdateWidget(covariant MPMemoryTranscriptContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex &&
        widget.selectedIndex != null &&
        widget.isPlaying) {
      _scrollToIndex(widget.selectedIndex!);
    }
  }

  void _scrollToIndex(int index) {
    if (widget.scrollWithParent) return;
    if (index < 0 || index >= _itemKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final BuildContext? target = _itemKeys[index].currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        alignment: 0.2,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_itemKeys.length != widget.items.length) {
      _itemKeys
        ..clear()
        ..addAll(
          List<GlobalKey>.generate(widget.items.length, (_) => GlobalKey()),
        );
    }
    final Widget listView = ListView.builder(
      controller: widget.scrollWithParent ? null : _scrollController,
      padding: widget.padding ?? EdgeInsets.zero,
      physics: widget.scrollWithParent
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
      shrinkWrap: widget.scrollWithParent,
      itemCount: widget.items.length,
      itemBuilder: (BuildContext context, int index) {
        return KeyedSubtree(
          key: _itemKeys[index],
          child: MPMemoryTranscriptItem(
            data: widget.items[index],
            isPlaying: widget.isPlaying && widget.playingIndex == index,
            isSelected: widget.selectedIndex == index,
            useMemoStyle: widget.useMemoStyle,
            onEditTap: widget.onItemEditTap == null
                ? null
                : () => widget.onItemEditTap!(index),
            onPlayTap: widget.onItemPlayTap == null
                ? null
                : () => widget.onItemPlayTap!(index),
          ),
        );
      },
    );
    if (widget.scrollWithParent) {
      return listView;
    }
    return SizedBox(
      height: widget.height,
      child: ClipRect(child: listView),
    );
  }
}
