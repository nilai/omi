import 'package:flutter/cupertino.dart';
import 'package:omi/business/shared/models/mp_business_models.dart';

class MPProjectDetailPage extends StatelessWidget {
  const MPProjectDetailPage({
    super.key,
    required this.project,
  });

  final MPProject project;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Project Detail'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(project.overview),
            ],
          ),
        ),
      ),
    );
  }
}
