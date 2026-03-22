import 'package:flutter/cupertino.dart';
import 'package:omi/business/shared/widgets/mp_feature_page_scaffold.dart';

class MPVoiceprintRecognitionPage extends StatelessWidget {
  const MPVoiceprintRecognitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MPFeaturePageScaffold(
      title: 'Voiceprint Recognition',
      description: '对应 React 的 VoiceprintRecognitionPage，管理声纹注册和识别策略。',
    );
  }
}
