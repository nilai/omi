import 'package:flutter/cupertino.dart';
import 'package:omi/business/insights/presentation/pages/mp_daily_insight_detail_page.dart';
import 'package:omi/business/insights/presentation/pages/mp_monthly_insight_detail_page.dart';
import 'package:omi/business/insights/presentation/pages/mp_pattern_insight_detail_page.dart';
import 'package:omi/business/insights/presentation/pages/mp_weekly_insight_detail_page.dart';
import 'package:omi/business/shared/state/mp_business_controller.dart';

class MPAllInsightsListPage extends StatelessWidget {
  const MPAllInsightsListPage({
    super.key,
    required this.controller,
  });

  final MPBusinessController controller;

  @override
  Widget build(BuildContext context) {
    final insights = controller.insights;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('All Insights'),
      ),
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: insights.length,
          itemBuilder: (context, index) {
            final item = insights[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CupertinoListTile(
                  title: Text(item.title),
                  subtitle: Text(item.summary),
                  trailing: Text(item.type),
                  onTap: () {
                    Widget page = const MPDailyInsightDetailPage();
                    if (item.type == 'weekly') {
                      page = const MPWeeklyInsightDetailPage();
                    } else if (item.type == 'monthly') {
                      page = const MPMonthlyInsightDetailPage();
                    } else if (item.type == 'pattern') {
                      page = const MPPatternInsightDetailPage();
                    }
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(builder: (_) => page),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
