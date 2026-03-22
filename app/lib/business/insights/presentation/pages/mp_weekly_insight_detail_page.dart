import 'package:flutter/cupertino.dart';
import 'package:omi/business/shared/widgets/mp_feature_page_scaffold.dart';

class MPWeeklyInsightDetailPage extends StatelessWidget {
  const MPWeeklyInsightDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MPFeaturePageScaffold(
      title: 'Weekly Insight Detail',
      description: '对应 React 的 WeeklyInsightDetail，展示周级趋势与任务建议。',
    );
  }
}
