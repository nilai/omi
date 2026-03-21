import 'package:flutter/cupertino.dart';
import 'package:omi/business/shared/widgets/mp_feature_page_scaffold.dart';

class MPPatternInsightDetailPage extends StatelessWidget {
  const MPPatternInsightDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MPFeaturePageScaffold(
      title: 'Pattern Insight Detail',
      description: '对应 React 的 PatternInsightDetail，展示跨记忆模式和关联入口。',
    );
  }
}
