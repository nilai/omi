import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

/// 单条 Project 卡片数据（标题 + 更新摘要 + 最近活动）
class MPProjectCardData {
  const MPProjectCardData({
    required this.title,
    required this.updatedPhrase,
    required this.memoryCount,
    required this.lastActivityDetail,
  });

  /// 项目名，如 `API Migration`
  final String title;

  /// 更新时间的口语片段，拼入 `Updated …`（如 `today`、`yesterday`）
  final String updatedPhrase;

  final int memoryCount;

  /// `Last activity ·` 后的说明文案，如 `Timeline discussion`
  final String lastActivityDetail;

  /// `Updated today · 3 memories`
  String get updateMetaLine {
    final String unit = memoryCount == 1 ? 'memory' : 'memories';
    return 'Updated $updatedPhrase · $memoryCount $unit';
  }

  /// `Last activity · Timeline discussion`
  String get lastActivityLine => 'Last activity · $lastActivityDetail';
}

/// 卡片描边（浅灰，与 People 卡片风格一致）
const Color _kCardBorder = Color(0xFFF0F0EE);

/// Projects 列表单项：白底圆角、三行左对齐文案
class MPProjectCard extends StatelessWidget {
  const MPProjectCard({
    super.key,
    required this.data,
    this.onTap,
  });

  final MPProjectCardData data;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _kCardBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t7_16,
                    fontWeight: OmiFontWeight.medium,
                    color: mainTextColor,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.updateMetaLine,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t4_13,
                    fontWeight: OmiFontWeight.regular,
                    color: secondTextColor,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.lastActivityLine,
                  style: OmiTextStyle.create(
                    fontSize: OmiFontSize.t4_13,
                    fontWeight: OmiFontWeight.regular,
                    color: secondTextColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
