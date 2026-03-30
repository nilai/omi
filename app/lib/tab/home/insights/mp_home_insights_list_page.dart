import 'package:flutter/material.dart';
import 'package:omi/common/mp_custom_nav_bar.dart';
import 'package:omi/utils/mp_toast_utils.dart';
import 'package:omi/utils/omi_color_utils.dart';

/// Insights 列表入口（对齐 react `AllInsightsListPage`，本阶段仅占位导航）
class MPHomeInsightsListPage extends StatelessWidget {
  const MPHomeInsightsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: PreferredSize(
        preferredSize: MPCustomNavBar.preferredSizeOf(context),
        child: MPCustomNavBar(
          title: 'Insights',
          backgroundColor: pageColor,
          onBack: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: <Widget>[
          Text(
            'AI insights & summaries over time',
            style: TextStyle(fontSize: 15, color: secondTextColor),
          ),
          const SizedBox(height: 20),
          _InsightRow(
            title: 'Daily · Mar 30',
            subtitle: 'End-of-day reflection',
            onTap: () => MPToastUtils.showFeatureComingSoon(message: 'Daily insight 详情'),
          ),
          _InsightRow(
            title: 'Weekly · Mar 25',
            subtitle: 'Week of Mar 24–30',
            onTap: () => MPToastUtils.showFeatureComingSoon(message: 'Weekly insight 详情'),
          ),
          _InsightRow(
            title: 'Pattern insight',
            subtitle: 'Recurring themes from your memories',
            onTap: () => MPToastUtils.showFeatureComingSoon(message: 'Pattern insight 详情'),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: mainTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: secondTextColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
