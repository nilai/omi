import 'package:flutter/cupertino.dart';
import 'package:omi/business/shared/widgets/mp_feature_page_scaffold.dart';

class MPPersonDetailPage extends StatelessWidget {
  const MPPersonDetailPage({
    super.key,
    required this.name,
  });

  final String name;

  @override
  Widget build(BuildContext context) {
    return MPFeaturePageScaffold(
      title: 'Person Detail',
      description: '对应 React 的 PersonDetail: $name 的沟通轨迹、相关记忆与任务。',
    );
  }
}
