import 'package:flutter/material.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

/// Memory 详情 **Overview** 分段内容（固定高度区域，可后续替换为摘要等）
class MPMemoryOverviewContent extends StatelessWidget {
  const MPMemoryOverviewContent({
    super.key,
    required this.content,
    this.height = 300,
    this.scrollWithParent = false,
    this.useMemoStyle = false,
  });

  final String content;
  final double height;
  final bool scrollWithParent;
  final bool useMemoStyle;

  @override
  Widget build(BuildContext context) {
    final Widget contentView = Align(
      alignment: Alignment.topLeft,
      child: Text(
        content,
        style: OmiTextStyle.create(
          fontSize: OmiFontSize.t4_13,
          fontWeight: OmiFontWeight.regular,
          color: useMemoStyle
              ? const Color(0xFF2C2C2E)
              : Colors.white.withValues(alpha: 0.75),
          height: 1.4,
        ),
      ),
    );
    if (scrollWithParent) {
      return contentView;
    }
    return SizedBox(
      height: height,
      child: ClipRect(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: contentView,
        ),
      ),
    );
  }
}
