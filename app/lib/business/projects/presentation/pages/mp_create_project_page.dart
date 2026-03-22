import 'package:flutter/cupertino.dart';
import 'package:omi/business/shared/widgets/mp_feature_page_scaffold.dart';

class MPCreateProjectPage extends StatelessWidget {
  const MPCreateProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MPFeaturePageScaffold(
      title: 'Create Project',
      description: '对应 React 的 CreateProjectWithMemoriesModal / CreateProjectModal。',
    );
  }
}
