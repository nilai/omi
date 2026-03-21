import 'package:flutter/cupertino.dart';
import 'package:omi/business/shared/widgets/mp_feature_page_scaffold.dart';

class MPDailyInsightDetailPage extends StatelessWidget {
  const MPDailyInsightDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MPFeaturePageScaffold(
      title: 'Daily Insight Detail',
      description: '对应 React 的 DailyInsightDetail，展示日级洞察与行动建议。',
    );
  }
}
