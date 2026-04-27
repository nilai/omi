import 'package:flutter/material.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../../../generated/assets.dart';
import '../../../../../utils/omi_image_loader.dart';

/// Memo / Memory / Audio 详情页内展示的「AI 生成摘要中」内容区（不含 AppBar）。
class MPSummaryGeneratingPanel extends StatelessWidget {
  const MPSummaryGeneratingPanel({
    super.key,
    required this.headline,
    this.metaLine = '',
  });

  final String headline;
  final String metaLine;

  @override
  Widget build(BuildContext context) {
    final String h = headline.trim().isNotEmpty ? headline.trim() : 'Audio Memory';
    final String meta = metaLine.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            h,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t11_20,
              fontWeight: OmiFontWeight.bold,
              color: mainTextColor,
              height: 1.2,
            ),
          ),
          if (meta.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: OmiImageLoader.localImg(
                    Assets.omiAudio,
                    width: 14,
                    height: 14,
                    color: secondTextColor,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    meta,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: OmiTextStyle.create(
                      fontSize: OmiFontSize.t4_13,
                      fontWeight: OmiFontWeight.regular,
                      color: secondTextColor,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 36),
          Center(
            child: SizedBox(
              width: 132,
              height: 132,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDDEBFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(
                    width: 128,
                    height: 128,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: blueTextColor,
                    ),
                  ),
                  OmiImageLoader.localImg(
                    Assets.omiSparkles,
                    width: 40,
                    height: 40,
                    color: blueTextColor,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'AI is working on it',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t8_17,
              fontWeight: OmiFontWeight.bold,
              color: mainTextColor,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing your recording and generating insights...',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t4_13,
              fontWeight: OmiFontWeight.regular,
              color: secondTextColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _MPSummaryGeneratingStepRow(
            icon: OmiImageLoader.localImg(
              Assets.omiAudio,
              width: 20,
              height: 20,
              color: blueTextColor,
              fit: BoxFit.contain,
            ),
            title: 'Transcribing audio',
          ),
          const SizedBox(height: 18),
          _MPSummaryGeneratingStepRow(
            icon: OmiImageLoader.localImg(
              Assets.omiBrain,
              width: 20,
              height: 20,
              color: blueTextColor,
              fit: BoxFit.contain,
            ),
            title: 'Understanding context',
          ),
          const SizedBox(height: 18),
          _MPSummaryGeneratingStepRow(
            icon: OmiImageLoader.localImg(
              Assets.omiSparkles,
              width: 20,
              height: 20,
              color: blueTextColor,
              fit: BoxFit.contain,
            ),
            title: 'Generating insights',
          ),
          const SizedBox(height: 18),
          _MPSummaryGeneratingStepRow(
            icon: OmiImageLoader.localImg(
              Assets.omiBookText,
              width: 20,
              height: 20,
              color: blueTextColor,
              fit: BoxFit.contain,
            ),
            title: 'Organizing summary',
          ),
          const SizedBox(height: 36),
          Text(
            'This usually takes 30 seconds – 2 minutes',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t3_12,
              fontWeight: OmiFontWeight.regular,
              color: secondTextColor.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _MPSummaryGeneratingStepRow extends StatelessWidget {
  const _MPSummaryGeneratingStepRow({
    required this.icon,
    required this.title,
  });

  final Widget icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: blueTextColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: icon,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t5_14,
              fontWeight: OmiFontWeight.medium,
              color: mainTextColor,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
