import 'package:flutter/cupertino.dart';
import 'package:omi/business/shared/widgets/mp_feature_page_scaffold.dart';

class MPMonthlyInsightDetailPage extends StatelessWidget {
  const MPMonthlyInsightDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MPFeaturePageScaffold(
      title: 'Monthly Insight Detail',
      description: '对应 React 的 MonthlyInsightDetail，展示月度总结与策略建议。',
    );
  }
}
