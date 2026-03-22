import 'package:flutter/cupertino.dart';
import 'package:omi/business/shared/widgets/mp_feature_page_scaffold.dart';

class MPExpertChatPage extends StatelessWidget {
  const MPExpertChatPage({
    super.key,
    required this.expertName,
  });

  final String expertName;

  @override
  Widget build(BuildContext context) {
    return MPFeaturePageScaffold(
      title: '$expertName Expert',
      description: '对应 React 的 ExpertChatView，提供 $expertName 视角的会话。',
    );
  }
}
