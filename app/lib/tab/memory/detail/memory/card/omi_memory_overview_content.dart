import 'package:flutter/material.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

/// Memory 详情 **Overview** 分段内容（固定高度区域，可后续替换为摘要等）
class MPMemoryOverviewContent extends StatelessWidget {
  const MPMemoryOverviewContent({
    super.key,
    required this.content,
    this.height = 300,
  });

  final String content;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRect(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              content,
              style: OmiTextStyle.create(
                fontSize: OmiFontSize.t4_13,
                fontWeight: OmiFontWeight.regular,
                color: Colors.white.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
