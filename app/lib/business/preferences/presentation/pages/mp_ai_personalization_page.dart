import 'package:flutter/cupertino.dart';
import 'package:omi/business/shared/widgets/mp_feature_page_scaffold.dart';

class MPAiPersonalizationPage extends StatelessWidget {
  const MPAiPersonalizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MPFeaturePageScaffold(
      title: 'AI Personalization',
      description: '对应 React 的 AIPersonalizationPage，管理偏好和行为定制。',
    );
  }
}
