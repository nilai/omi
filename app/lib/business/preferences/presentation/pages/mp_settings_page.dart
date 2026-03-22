import 'package:flutter/cupertino.dart';
import 'package:omi/business/shared/widgets/mp_feature_page_scaffold.dart';

class MPSettingsPage extends StatelessWidget {
  const MPSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MPFeaturePageScaffold(
      title: 'Settings',
      description: '对应 React 的 SettingsPage，管理应用级设置。',
    );
  }
}
